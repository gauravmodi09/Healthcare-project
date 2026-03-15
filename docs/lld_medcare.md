# MedCare: Low-Level Design (LLD)

## 1. Introduction
This Low-Level Design (LLD) document provides the exact technical specifications required to build the MedCare MVP (v1). It is intended for software engineers to use as a direct blueprint for implementation.

## 2. Database Schema (PostgreSQL)

### 2.1 Core Tables
The database design normalizes data specifically around the `User` -> `Profile` -> `Episode` hierarchy.

**Table: `users`**
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_number VARCHAR(15) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    subscription_tier VARCHAR(10) DEFAULT 'free',
    subscription_expiry TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Table: `profiles`**
```sql
CREATE TABLE profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    relation VARCHAR(50), -- 'self', 'parent', 'child'
    age INTEGER,
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Table: `episodes`**
```sql
CREATE TABLE episodes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL, -- 'acute', 'chronic', 'post_discharge'
    source VARCHAR(50) NOT NULL DEFAULT 'uploaded_prescription', -- 'uploaded_prescription', 'uploaded_discharge', 'manual', 'teleconsult'
    status VARCHAR(50) DEFAULT 'active',
    start_date DATE NOT NULL,
    end_date DATE,
    follow_up_date DATE,
    doctor_name VARCHAR(255),
    original_doc_s3_key VARCHAR(512), -- prescription image S3 key
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Table: `episode_images`**
Stores all uploaded images per episode — both prescriptions and medicine packaging photos.
```sql
CREATE TABLE episode_images (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    episode_id UUID REFERENCES episodes(id) ON DELETE CASCADE,
    s3_key VARCHAR(512) NOT NULL,
    image_type VARCHAR(50) NOT NULL, -- 'prescription', 'medicine_photo'
    original_filename VARCHAR(255),
    file_size_bytes INTEGER,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_episode_images_episode_id ON episode_images(episode_id);
```

**Table: `medicines`**
```sql
CREATE TABLE medicines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    episode_id UUID REFERENCES episodes(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL, -- brand name as printed on packaging (e.g., "Crocin 500mg")
    generic_name VARCHAR(255), -- salt/composition extracted from packaging (e.g., "Paracetamol 500mg")
    manufacturer VARCHAR(255), -- extracted from medicine packaging
    dose_amount VARCHAR(100) NOT NULL, -- e.g., "1 tablet", "5ml"
    frequency VARCHAR(50) NOT NULL, -- 'once_daily', 'twice_daily', 'thrice_daily', etc.
    timing_instructions TEXT, -- e.g., "After food", extracted from prescription
    start_date DATE NOT NULL,
    end_date DATE,
    expiry_date DATE, -- extracted from medicine packaging
    mrp DECIMAL(10, 2), -- MRP in INR, extracted from packaging
    source VARCHAR(50) NOT NULL, -- 'extracted_packaging', 'extracted_prescription', 'cross_referenced', 'manual'
    confidence_score DECIMAL(3, 2), -- 0.00 to 1.00 (packaging-sourced fields score higher)
    packaging_image_id UUID REFERENCES episode_images(id), -- links to the specific medicine photo
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Table: `dose_logs`**
```sql
CREATE INDEX idx_dose_logs_scheduled_at ON dose_logs(scheduled_at);

CREATE TABLE dose_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    medicine_id UUID REFERENCES medicines(id) ON DELETE CASCADE,
    scheduled_at TIMESTAMP NOT NULL,
    status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'taken', 'skipped', 'out_of_stock'
    logged_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## 3. Backend API Specifications (REST)

### 3.1 Authentication
- **`POST /auth/send-otp`**
  - **Body**: `{ "phoneNumber": "+919876543210" }`
  - **Response**: `200 OK`
- **`POST /auth/verify-otp`**
  - **Body**: `{ "phoneNumber": "+919876543210", "code": "123456" }`
  - **Response**: `{ "token": "jwt_string", "user": { ... } }`

### 3.2 Image Upload
- **`GET /episodes/:id/upload-urls`**
  - **Query**: `?count=4` (number of pre-signed URLs needed)
  - **Response**: `{ "urls": [{ "s3Key": "uploads/uuid1.jpg", "presignedUrl": "https://...", "expiresIn": 900 }] }`

### 3.3 Dual-Capture Extraction Pipeline
- **`POST /episodes/:id/upload`**
  - **Body**:
    ```json
    {
      "prescriptionKeys": ["uploads/uuid1.jpg"],
      "medicinePhotoKeys": ["uploads/uuid2.jpg", "uploads/uuid3.jpg", "uploads/uuid4.jpg"]
    }
    ```
  - **Processing Logic**:
    1. Backend fetches all images from S3.
    2. **Medicine packaging extraction** (primary): GPT-4 Vision extracts brand name, generic/salt name, strength, manufacturer, MRP, expiry from each medicine photo. High confidence (printed text).
    3. **Prescription extraction** (context): GPT-4 Vision extracts doctor name, frequency, duration, timing instructions from the prescription. Moderate confidence (handwritten text).
    4. **Cross-reference merge**: Backend matches prescription line items to medicine packaging photos. Builds unified medicine records with per-field confidence scores and source attribution.
    5. Backend pipes merged output through **Stitch MCP Server** for pharma database validation.
  - **Response**:
    ```json
    {
      "doctorName": "Dr. Sharma",
      "extractedMedicines": [
        {
          "tempId": "uuid_string",
          "name": "Azithromycin 500mg",
          "genericName": "Azithromycin",
          "manufacturer": "Cipla Ltd",
          "expiryDate": "2027-03",
          "mrp": 120.00,
          "frequency": "twice_daily",
          "duration": "5 days",
          "timingInstructions": "After food",
          "confidenceScore": 0.92,
          "sourceBreakdown": {
            "name": "packaging",
            "genericName": "packaging",
            "frequency": "prescription",
            "timingInstructions": "prescription"
          },
          "matchedPackagingImageKey": "uploads/uuid2.jpg"
        }
      ],
      "unmatchedPrescriptionItems": [
        {
          "rawText": "Tab. ??? 1 BD x 7",
          "confidenceScore": 0.25,
          "note": "Could not match to any medicine photo. Please add manually."
        }
      ]
    }
    ```
  - **Note**: `unmatchedPrescriptionItems` captures prescription entries that couldn't be matched to any medicine photo — prompting the user to either photograph the missing medicine or enter it manually.

- **`POST /episodes/:id/confirm`**
  - **Body**: `{ "confirmedMedicines": [ ... ], "doctorName": "Dr. Sharma" }`
  - **Processing Logic**: Writes the explicitly curated `Medicine` array to the `medicines` table, links `packaging_image_id`, and generates the 30-day projection of `dose_logs`.
  - **Response**: `201 Created`

## 4. Frontend Architecture (iOS - SwiftUI)

### 4.1 Design Pattern (MVVM)
The iOS app will strictly follow the Model-View-ViewModel (MVVM) pattern to segregate UI rendering from business logic and state management.

### 4.2 Core Components
- **Models**: Native Swift `Codable` structs mapping exactly to the backend JSON responses (e.g., `Episode`, `Medicine`, `DoseLog`, `EpisodeImage`).
- **Repositories**: Encapsulated network managers.
  - `EpisodeRepository.swift`: Handles `upload()` and `confirm()` tasks. Implements a retry-mechanism for poor network conditions.
  - `ImageUploadRepository.swift`: Manages pre-signed URL acquisition, image compression (target < 500KB), and progressive upload with resume capability for unreliable Indian networks.
- **ViewModels**: `ObservableObject` classes publishing state (`@Published var state: ViewState`).
  - `CaptureViewModel.swift`: Manages the dual-capture flow — tracks prescription photo (1) and medicine photos (1-10). Validates at least one medicine photo is added before proceeding.
  - `ConfirmationViewModel.swift`: Responsible for displaying source attribution per field (packaging vs prescription), tracking the amber 'Low Confidence' badges, handling `unmatchedPrescriptionItems` (prompting manual entry), and validating that *every* single medicine is marked "Confirmed" before enabling the final CTA.

### 4.3 Key UI/UX Implementations

#### Dual-Capture Flow (New Core Screen)
- **`PrescriptionCaptureView`**: Camera/Gallery/PDF picker for the prescription. Single image.
- **`MedicineScanView`**: Dedicated screen after prescription capture. Shows a guide image of a medicine strip/box with text "Now photograph each medicine you bought". Grid of captured medicine photos with "+" button to add more. Minimum 1 photo required (unless user taps "I don't have medicines yet" which falls back to prescription-only mode with lower confidence warning).
- **`UploadProgressView`**: Shows upload progress for all images. Handles resume on network interruption.

#### Confirmation Screen Enhancements
- **Source Attribution Badges**: Fields extracted from medicine packaging display a green `"✓ From packaging"` badge. Fields from prescription display `"From prescription"` in grey. This builds user trust in the extraction quality.
- **The "Amber Warning" System**: Extracted fields with a `confidenceScore < 0.7` will be bound to a SwiftUI `AlertModifier`. The field's background color will shift to `.orange.opacity(0.1)` and an explicit `Image(systemName: "exclamationmark.triangle.fill")` will overlay the text box, forcing the user to tap and expand the context.
- **Unmatched Items Section**: If the AI found prescription entries that don't match any medicine photo, they appear in a separate "Needs Your Input" section with a manual entry form.
- **Medicine Photo Preview**: Each extracted medicine card shows a thumbnail of the packaging photo it was sourced from, so the user can visually verify.

#### Offline Resilience
- The app will utilize SwiftData (or CoreData) as a local cache. The `RemindersTabView` logic will query the local SwiftData `DoseLog` models, allowing a user to mark a dose as `.taken` while entirely offline. An `OfflineSyncManager` background task will queue the `POST /doses/:id/log` request for when internet is restored.

## 5. Third-Party Integrations
- **Identity via OTP**: Twilio (Global) / MSG91 (India).
- **Blob Storage**: AWS S3. Uses `STS:GetFederationToken` to issue limited-time pre-signed URLs directly to the iOS app for upload.
- **Push Notifications**: Firebase Cloud Messaging (FCM). An AWS EventBridge scheduled rule or Redis BullMQ will trigger the backend to fire `.taken` / `.snooze` / `.skip` actionable notifications precisely 5 minutes before scheduled dose times. 
- **AI / Tooling**: GPT-4o-Vision (Extraction) + Stitch MCP (Database Cross-Referencing).
