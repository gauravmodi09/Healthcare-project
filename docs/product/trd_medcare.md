# MedCare: Technical Requirements Document (TRD)

## 1. Introduction & Scope
The Technical Requirements Document (TRD) acts as the engineering contract for the MedCare application. It outlines the specific technology stack, platform constraints, integration points, system performance targets, and regulatory standards required to develop, deploy, and scale the application.

**Target Market:** India-first, English-only interface. Optimized for Indian network conditions, prescription formats, and regulatory requirements.

## 2. Technology Stack

### 2.1 Frontend Platforms
*   **iOS (v1 Primary):** SwiftUI, targeted at iOS 16.0 minimum. 
*   **Android (v1 Fast Follow):** Jetpack Compose, targeted at API level 26 minimum.
*   **Local Persistence:** SwiftData (iOS) / Room (Android) for caching the `DoseLog` and `Medicine` entities, ensuring the offline reminder engine works seamlessly even in low-connectivity environments.

### 2.2 Backend & Infrastructure
*   **API Layer:** Node.js (v24 LTS) with Express.js OR Python 3.11+ with FastAPI. The architecture requires high I/O throughput for handling concurrent JWT verification and image proxying, making Node.js the preferred approach.
*   **Database:** PostgreSQL 15+. Relational data integrity is critical for healthcare schemas. Requires UUID auto-generation.
*   **Object Storage:** AWS S3 (Standard Storage class) with forced Server-Side Encryption (SSE-S3). Prescriptions will eventually be lifecycle-tiered to Glacier if history limits are hit on Free-tier accounts.
*   **Background Jobs:** Redis + BullMQ (Node) or Celery (Python) for precise, scheduled push notification dispatching via FCM.
*   **AI Integrations:** OpenAI GPT-4 Vision (via standard REST) and **Google Stitch MCP** (`@_davideast/stitch-mcp`) acting as the validation middleware layer against medical registries.

## 3. System Architecture & Constraints

### 3.1 The Dual-Capture AI Extraction Pipeline
The core value feature uses a **dual-capture approach** optimized for Indian prescriptions: users photograph both the handwritten prescription AND the physical medicine packaging they purchased. This must strictly enforce a **Human-In-The-Loop (HITL)** constraint at the database layer.

**Why Dual-Capture for India:**
- Indian prescriptions are 80%+ handwritten, mixing English, Hindi, and Latin abbreviations — difficult for OCR
- Medicine packaging in India carries standardized printed text (brand name, generic name, composition, strength, MRP, expiry) mandated by CDSCO under the Drugs and Cosmetics Act — highly reliable for AI extraction
- Cross-referencing both sources produces significantly higher accuracy than either source alone

**Pipeline Steps:**

1.  **Image Upload:** The mobile client requests multiple AWS S3 Pre-Signed URLs via `GET /episodes/:id/upload-urls?count=N`. Images are compressed client-side (target < 500KB each) before upload for Indian network conditions.
2.  **AI Invocation:** The mobile client calls `POST /episodes/:id/upload { prescriptionKeys: [...], medicinePhotoKeys: [...] }`.
3.  **Processing — Medicine Photos (Primary):** GPT-4V extracts brand name, generic/salt composition, strength, dosage form, manufacturer, MRP (INR), expiry date from printed packaging. High confidence.
4.  **Processing — Prescription (Context):** GPT-4V extracts doctor name, frequency, duration, timing instructions from handwritten text. Variable confidence.
5.  **Cross-Reference Merge:** Backend matches prescription line items to medicine packaging. Builds unified records with per-field source attribution and confidence scores. Unmatched prescription items flagged for manual input.
6.  **Middleware Verification:** The backend runs the merged JSON against the Google Stitch MCP server. Stitch fuzzy-matches against Indian pharmaceutical databases to correct spelling (e.g., "Azithromycin 500mh" -> "Azithromycin 500mg").
7.  **Return State:** The API returns a transient JSON array with `sourceBreakdown` per field and `unmatchedPrescriptionItems`. It does *not* persist to the `medicines` table yet.
8.  **Explicit Confirmation:** The user UI displays fields with source badges ("From packaging" / "From prescription"), flagging `confidence_score < 0.70` in amber. Only upon `POST /episodes/:id/confirm` are records materialized in PostgreSQL and scheduled in Redis.

**Performance Targets:**
- Image compression + upload: p95 < 10s per image on 3G
- GPT-4V extraction (all images): p95 < 12s
- Stitch MCP validation: p95 < 2s
- Total pipeline (upload to response): p95 < 20s

## 4. Security & Compliance Requirements

### 4.1 Data Encryption
*   **In Transit:** Strict TLS 1.3 enforcement on all API endpoints. The mobile app must employ SSL pinning for the Core API domains to prevent Man-in-the-Middle (MITM) attacks.
*   **At Rest:** 
    *   PostgreSQL volume must be AES-256 encrypted. 
    *   AWS S3 Object Storage requires bucket policies denying any unencrypted HTTP traffic (`aws:SecureTransport`) and mandating SSE.

### 4.2 Regulatory Standards (DPDP Act / HIPAA Equivalency)
*   **Data Minimization:** Health history is not collected during onboarding. It is strictly tied to explicit user-created `Profile` and `Episode` objects.
*   **Right to Erasure:** The backend must expose a `DELETE /user` endpoint that performs a hard, cascading delete of all user profiles, episodes, dose logs, and uniquely identifiable S3 image keys.
*   **Anonymization Layer:** Before any internal analytics (Mixpanel/Amplitude) evaluate usage trends, PII (Names, Phone Numbers) and PHI (Specific Medicine Names) must be scrubbed at the gateway layer.

### 4.3 App Authentication
*   **Identity Service:** Firebase Authentication or a unified custom flow via Twilio OTP.
*   **Token Lifecycle:** Short-lived JWT Access Tokens (15m elapsed) and rotating Refresh Tokens (30d elapsed) stored securely in the iOS Keychain (using `SecItemAdd`) and Android EncryptedSharedPreferences.

## 5. Deployment & Telemetry Strategy
*   **CI/CD Pipeline:** GitHub Actions triggering Fastlane for automated TestFlight (iOS) distribution and Play Store (Android) internal track releases.
*   **Hosting:** Dockerized backend services orchestrated on AWS ECS (Fargate) or GCP Cloud Run for zero-downtime serverless scaling.
*   **Observability:** DataDog or AWS CloudWatch APM to monitor the latency specifically on the `POST /episodes/:id/extract` endpoint (target: p95 < 8.0s for the GPT-4V round trip).
