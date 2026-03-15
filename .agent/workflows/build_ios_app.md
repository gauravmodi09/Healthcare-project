---
description: Complete depth workflow for building the MedCare iOS SwiftUI App (v1)
---

# MedCare iOS App — Complete Development Workflow

> **Product:** MedCare — Smart Health Companion App
> **Platform:** iOS (SwiftUI, minimum iOS 16+)
> **Architecture:** MVVM + Repository Pattern
> **Backend:** REST API (Node.js/Express or Python/FastAPI) + PostgreSQL + **Stitch MCP Server (Integration Middleware)**
> **v1 Scope:** Prescription upload → AI extraction → care plan → reminders + tracking. No teleconsult.

---

## Phase 1: Xcode Project Setup & Architecture Foundation

### 1.1 Create Xcode Project
// turbo
1. Create a new Xcode SwiftUI project named `MedCare` with the bundle identifier `com.medcare.app`.
2. Set deployment target to **iOS 16.0** minimum.
3. Enable Push Notification and Background Modes capabilities from the Signing & Capabilities tab.

### 1.2 Establish Folder Structure
Create the following folder hierarchy inside the project:

```
MedCare/
├── App/
│   ├── MedCareApp.swift          # @main entry point, environment setup
│   └── AppDelegate.swift         # Push notification registration
├── Core/
│   ├── Design/
│   │   ├── Theme.swift           # Colors, gradients, shadows
│   │   ├── Typography.swift      # Font definitions (use SF Pro or custom)
│   │   └── Components/           # Reusable UI components (MCButton, MCCard, MCBadge)
│   ├── Networking/
│   │   ├── APIClient.swift       # URLSession-based REST client with JWT handling
│   │   ├── APIEndpoints.swift    # All endpoint definitions as static constants
│   │   ├── APIError.swift        # Typed error handling
│   │   └── TokenManager.swift    # Keychain JWT storage & refresh
│   ├── Persistence/
│   │   ├── MedCareModel.xcdatamodeld  # CoreData schema (or SwiftData @Model files)
│   │   ├── PersistenceController.swift
│   │   └── OfflineSyncManager.swift   # Queue offline actions for retry
│   └── Extensions/               # Date+, String+, View+ helpers
├── Features/
│   ├── Onboarding/
│   │   ├── Views/
│   │   │   ├── SplashView.swift
│   │   │   ├── OTPLoginView.swift
│   │   │   └── ProfileSetupView.swift
│   │   └── ViewModels/
│   │       ├── OTPLoginViewModel.swift
│   │       └── ProfileSetupViewModel.swift
│   ├── Home/
│   │   ├── Views/
│   │   │   ├── HomeView.swift            # Two-door CTA layout
│   │   │   └── ProfileSwitcherView.swift # Family profile selector
│   │   └── ViewModels/
│   │       └── HomeViewModel.swift
│   ├── PrescriptionUpload/
│   │   ├── Views/
│   │   │   ├── CaptureMethodView.swift        # Camera / Gallery / PDF picker
│   │   │   ├── UploadProgressView.swift       # Upload + extraction loading state
│   │   │   ├── ConfirmationView.swift         # Side-by-side: image + editable cards
│   │   │   └── MedicineEditCard.swift         # Single medicine editable card
│   │   └── ViewModels/
│   │       ├── UploadViewModel.swift
│   │       └── ConfirmationViewModel.swift
│   ├── Episode/
│   │   ├── Views/
│   │   │   ├── EpisodeDetailView.swift        # Tab container
│   │   │   ├── PlanTabView.swift              # Medicines + tasks + follow-up
│   │   │   ├── RemindersTabView.swift         # Daily dose timeline
│   │   │   ├── SymptomsTabView.swift          # Check-in + log
│   │   │   └── HistoryTabView.swift           # Adherence charts + export
│   │   └── ViewModels/
│   │       ├── EpisodeDetailViewModel.swift
│   │       └── AdherenceViewModel.swift
│   ├── Reminders/
│   │   ├── NotificationManager.swift          # UNUserNotificationCenter setup
│   │   └── ReminderScheduler.swift            # Generate local notifications from plan
│   ├── Subscription/
│   │   ├── Views/
│   │   │   ├── PaywallView.swift              # Upgrade prompt (contextual)
│   │   │   └── ManageSubscriptionView.swift
│   │   └── ViewModels/
│   │       └── SubscriptionViewModel.swift
│   └── Settings/
│       ├── Views/
│       │   ├── SettingsView.swift
│       │   └── DeleteAccountView.swift
│       └── ViewModels/
│           └── SettingsViewModel.swift
├── Models/
│   ├── User.swift
│   ├── Profile.swift
│   ├── Episode.swift
│   ├── Medicine.swift
│   ├── DoseLog.swift
│   ├── Task.swift
│   ├── SymptomLog.swift
│   └── WearableReading.swift       # Defined now for v2 schema readiness
├── Repositories/
│   ├── AuthRepository.swift
│   ├── EpisodeRepository.swift
│   ├── MedicineRepository.swift
│   └── ProfileRepository.swift
└── Resources/
    ├── Assets.xcassets
    ├── Localizable.strings
    └── Info.plist
```

### 1.3 Design System Setup
1. Define a `Theme.swift` with a premium colour palette. Example direction:
   - **Primary:** Deep teal/medical blue gradient (`#0A7E8C` → `#3EC6C8`)
   - **Accent:** Warm coral for CTAs (`#FF6B6B`)
   - **Background:** Off-white `#F7F9FC` (light mode), deep charcoal `#1A1D29` (dark mode)
   - **Card surfaces:** White `#FFFFFF` with soft 4pt shadow (light), `#242838` (dark)
   - **Amber warning:** `#F5A623` for low-confidence AI fields
2. Define typography using **SF Pro** (system) or import **Inter** from Google Fonts:
   - Display: 28pt Bold
   - Title: 22pt Semibold
   - Body: 16pt Regular
   - Caption: 13pt Regular, secondary colour
3. Build core reusable components:
   - `MCButton` — Primary CTA with gradient fill, haptic feedback on tap, subtle scale animation
   - `MCCard` — Rounded card with shadow, supports leading icon + trailing badge
   - `MCBadge` — Status pill (e.g. "Active", "Completed", "Needs Attention")
   - `MCTextField` — Styled text input with floating label and validation state
   - `MCBottomSheet` — Modal half-sheet for quick actions

---

## Phase 2: Data Models — Exact Schema from PRD

> **Key principle:** Define the schema to support acute (episode-based) AND chronic (ongoing) use cases from day one. Include WearableReading to avoid future rework.

### 2.1 Swift Model Definitions

Every model should be `Codable`, `Identifiable`, and map 1:1 to the backend entities. Use `UUID` for all IDs.

```swift
// --- User ---
struct User: Codable, Identifiable {
    let id: UUID                    // user_id
    let phoneNumber: String
    var name: String
    let createdAt: Date
    var subscriptionTier: SubscriptionTier   // .free | .pro
    var subscriptionExpiry: Date?
}

enum SubscriptionTier: String, Codable {
    case free, pro
}

// --- Profile ---
struct Profile: Codable, Identifiable {
    let id: UUID                    // profile_id
    let userId: UUID
    var name: String                // e.g. "Mum"
    var relation: Relation?         // .self | .parent | .child | .spouse | .other
    var age: Int?
    var knownConditions: [String]?  // ["diabetes", "hypertension"]
    var isDefault: Bool
}

enum Relation: String, Codable {
    case `self`, parent, child, spouse, other
}

// --- Episode ---
struct Episode: Codable, Identifiable {
    let id: UUID                    // episode_id
    let profileId: UUID
    var title: String               // e.g. "Fever & Cough", "Diabetes"
    var type: EpisodeType           // .acute | .chronic | .postDischarge
    var source: EpisodeSource       // .uploadedPrescription | .uploadedDischarge | .manual | .teleconsult
    let startDate: Date
    var endDate: Date?              // nil = still active
    var followUpDate: Date?
    var status: EpisodeStatus       // .active | .completed | .paused
    var doctorName: String?
    var originalDocUrl: String?     // S3 URL
    let createdAt: Date
}

// --- Medicine ---
struct Medicine: Codable, Identifiable {
    let id: UUID                    // medicine_id
    let episodeId: UUID
    var name: String                // e.g. "Azithromycin 500mg"
    var doseAmount: String          // e.g. "1 tablet", "5ml"
    var frequency: DoseFrequency    // .onceDaily | .twiceDaily | .thriceDaily | .everyXHours | .asNeeded
    var timingInstructions: String? // e.g. "After food"
    let startDate: Date
    var endDate: Date?              // nil = ongoing (chronic)
    var isChronic: Bool
    var refillReminderDays: Int?    // default: 7
    var stockCount: Int?
    var source: MedicineSource      // .extracted | .manual
    var confidenceScore: Double?    // 0.0–1.0 from AI
}

// --- DoseLog ---
// Source of truth for adherence tracking. One record per scheduled dose.
struct DoseLog: Codable, Identifiable {
    let id: UUID                    // dose_id
    let medicineId: UUID
    let scheduledAt: Date
    var status: DoseStatus          // .pending | .taken | .skipped | .outOfStock
    var loggedAt: Date?
    var notes: String?
    var wearableHrAtTime: Int?      // v2+
}

// --- Task ---
// Non-medicine care plan items: lab tests, physio, wound care, lifestyle, follow-ups.
struct CareTask: Codable, Identifiable {
    let id: UUID                    // task_id
    let episodeId: UUID
    var type: TaskType              // .test | .exercise | .woundCare | .lifestyle | .followup | .other
    var title: String               // e.g. "HbA1c blood test"
    var description: String?
    var dueDate: Date?
    var recurrence: Recurrence?     // .none | .daily | .weekly
    var status: TaskStatus          // .pending | .done | .snoozed
    var completedAt: Date?
}

// --- SymptomLog ---
struct SymptomLog: Codable, Identifiable {
    let id: UUID                    // log_id
    let episodeId: UUID
    let loggedAt: Date
    var symptoms: [String]          // ["fever", "headache"]
    var severity: Int?              // 1–5
    var temperature: Double?
    var notes: String?
    var source: SymptomSource       // .manual | .wearable
}
```

### 2.2 Local Persistence (CoreData or SwiftData)
- Mirror the above models into your CoreData `.xcdatamodeld` or SwiftData `@Model` classes.
- Use a `PersistenceController` singleton for managed object context access.
- **Offline strategy:** Cache all `GET` responses locally. Queue `POST`/`PATCH` actions when offline and replay on reconnect via `OfflineSyncManager`.

---

## Phase 3: Networking Layer — API Contracts

### 3.1 API Client Setup
Build a clean `APIClient` wrapping `URLSession` with:
- Automatic JWT token injection from Keychain via `TokenManager`.
- Token refresh on 401 using `POST /auth/refresh`.
- Global error mapping to typed `APIError` enum (`.unauthorized`, `.rateLimited`, `.serverError`, `.decodingFailed`).
- Response decoding using `JSONDecoder` with `.convertFromSnakeCase` key strategy.

### 3.2 Endpoint Definitions
Map every endpoint from the PRD as static methods or constants:

| Method | Endpoint | iOS Usage |
|--------|----------|-----------|
| `POST` | `/auth/send-otp` | Send OTP during login |
| `POST` | `/auth/verify-otp` | Verify OTP → receive JWT |
| `POST` | `/auth/refresh` | Silent token refresh |
| `GET` | `/episodes` | Home screen episode list |
| `POST` | `/episodes` | Create episode manually |
| `GET` | `/episodes/:id` | Episode detail (medicines + tasks) |
| `PATCH` | `/episodes/:id` | Update status or follow-up |
| `POST` | `/episodes/:id/upload` | Upload multiple images (prescription + medicine photos) → AI extraction |
| `POST` | `/episodes/:id/confirm` | Confirm AI-extracted medicines (creates records) |
| `GET` | `/episodes/:id/adherence` | Adherence % for History tab |
| `POST` | `/medicines` | Add medicine manually |
| `PATCH` | `/medicines/:id` | Edit dose, timing, end date |
| `DELETE` | `/medicines/:id` | Remove medicine |
| `GET` | `/medicines/:id/doses` | Upcoming + past doses |
| `POST` | `/doses/:id/log` | Log dose: taken / skipped / out_of_stock |

### 3.3 S3 Pre-Signed Upload Flow
1. App requests a pre-signed upload URL from the backend.
2. App uploads the image/PDF directly to S3 using the pre-signed URL (avoids sending large files through the API).
3. App calls `POST /episodes/:id/upload` with the resulting S3 key.
4. Backend triggers the GPT-4 Vision extraction pipeline.

---

## Phase 4: Onboarding Flow (Must Complete in Under 60 Seconds)

> **Design rule from PRD:** Do NOT ask for health history upfront — this creates friction. Collect it lazily as users create episodes.

### 4.1 Splash Screen
- App logo + tagline: **"Your care plan, always with you"**
- Show for 1.5–2 seconds with a fade-in animation.
- Check for existing JWT → if valid, skip to Home. If expired, attempt silent refresh. If no token, go to Login.

### 4.2 OTP Login Screen (`OTPLoginView`)
- Single text field for phone number with `+91` country code pre-filled (Indian market).
- "Send OTP" CTA calls `POST /auth/send-otp`.
- OTP entry: 6-digit code with auto-focus moving between fields.
- "Verify" calls `POST /auth/verify-otp` → stores JWT in Keychain.

### 4.3 Profile Setup (`ProfileSetupView`)
- Fields: Name (required), Age (optional), Gender (optional), Known Conditions (optional multi-select chips like "Diabetes", "Hypertension", "Thyroid", "None").
- "Get Started" CTA → creates the default `Profile` with `isDefault: true` and `relation: .self`.
- Immediately followed by a **notification permission prompt** (use `UNUserNotificationCenter.requestAuthorization`) — essential for the reminder system.

### 4.4 Home Screen (`HomeView`)
- Two large, visually distinct cards/buttons:
  - **Door A:** "Consult a Doctor" — Visually present but tapped shows a "Coming Soon" sheet (Phase 2).
  - **Door B:** "Upload Prescription / Discharge" — Primary v1 action, highlighted with accent colour.
- Below the CTAs: list of active episodes (if any) with status badges.
- Profile switcher in the nav bar for family members.

---

## Phase 5: Core Feature — Prescription Upload & AI Extraction

> ⚠️ **CRITICAL SAFETY RULE (from PRD):** NEVER auto-confirm extracted data. NEVER auto-create Medicine records from AI output. The confirmation step is a HARD REQUIREMENT, not optional UX. Build it as a separate API call (`POST /episodes/:id/confirm`) so it is impossible to bypass.

### 5.1 Step 1 — Capture (`CaptureMethodView`)
- Present three options in a clean action sheet or bottom sheet:
  - 📷 **Camera** — Use `UIImagePickerController` or custom `AVCaptureSession` for live capture
  - 🖼️ **Gallery** — Use `PhotosPicker` (iOS 16+)
  - 📄 **PDF Upload** — Use `UIDocumentPickerViewController` with `uniformTypeIdentifiers: [.pdf]`
- Support **multiple uploads**. After uploading the core prescription, actively prompt the user: *"Add photos of your medicines to help the AI read the doctor's handwriting."*
- Show a thumbnail strip that allows adding/removing pages and photos.

### 5.2 Step 2 — Upload & AI Extraction (`UploadProgressView`)
- Upload the image(s) to S3 via pre-signed URL.
- Call `POST /episodes/:id/upload` with the S3 keys (array).
- Show a loading animation while extraction runs. Use skeleton/shimmer cards to preview expected layout.
- Backend extraction & Stitch MCP validation pipeline:
  1. All images sent to GPT-4 Vision (or Google Document AI).
  2. Prompt instructs AI to explicitly **cross-reference** the messy handwriting on the prescription against the clear text on the medicine photos to improve extraction accuracy.
  3. AI response: `{ medicines: [...], tasks: [...], doctor: "", date: "", follow_up: "" }`.
  4. **Stitch Validation:** Backend passes the extracted JSON query through the local **Stitch MCP Server** to validate medicine names/dosages against official pharmaceutical databases and to sync the record to connected EMR/EHR systems.
  5. Backend stores raw AI response and returns validated, structured data to the app.

### 5.3 Step 3 — User Confirmation Screen (`ConfirmationView`)
This is the most safety-critical screen in the app. Build it with extreme care.

- **Layout:** Side-by-side scroll — original prescription image on the left (or top on phone), extracted data cards on the right (or bottom).
- **Each medicine card (`MedicineEditCard`) shows:**
  - Name, dose amount, frequency, duration — all **inline-editable**.
  - Timing instructions (e.g. "After food").
  - Confidence indicator: green checkmark if confidence ≥ 0.7, **amber warning icon** if below 0.7.
- **Low-confidence fields:** Highlighted with amber background + warning text: "Please verify this field".
- **"Add medicine manually" button** always visible at the bottom of the medicine list.
- **Disclaimer banner** (required by PRD): _"Please verify all details with your doctor's prescription. This app does not provide medical advice."_
- **CTA:** "Confirm and Create Plan" — calls `POST /episodes/:id/confirm` with the user-confirmed data.

### 5.4 Step 4 — Plan Created
- Episode created with all confirmed medicines and tasks.
- Navigate to `EpisodeDetailView` with the Plan tab active.
- If notification permission not yet granted, prompt again.
- Show onboarding tooltip: _"Your first reminder is set — here is what to expect."_

---

## Phase 6: Episode Management — The 4-Tab Dashboard

### 6.1 Episode Detail Container (`EpisodeDetailView`)
- Custom `TabView` or segmented control with 4 tabs: **Plan | Reminders | Symptoms | History**.
- Episode header: title, status badge, doctor name, date range.

### 6.2 Plan Tab (`PlanTabView`)
- **Medicines section:** List of all medicines with dose, frequency, timing, duration. Each tappable to edit. Swipe-to-delete supported.
- **Tasks section:** Non-medicine items (lab tests, physio, wound care, lifestyle instructions, follow-up dates). Types: `test | exercise | wound_care | lifestyle | followup | other`.
  - Each task shows title, description, due date, recurrence, status.
  - Tap to mark done, long-press to snooze.
- **Follow-up date:** Highlighted card if a follow-up is set. Countdown badge showing days until follow-up.
- **"Add manually" FAB** for adding medicines or tasks by hand.

### 6.3 Reminders Tab (`RemindersTabView`)
- **Daily timeline view:** Vertical timeline showing all doses for today and upcoming days.
- Each dose shows: medicine name, dose amount, timing instruction, scheduled time.
- **Quick actions per dose:** Taken ✅ | Skipped ⏭️ | Snooze 30 min ⏳ | Out of Stock 🚫.
- Actions call `POST /doses/:id/log` with the corresponding status.
- **Missed doses** (no response in 2 hours): Remain as `pending`, shown with a "missed" visual indicator.

### 6.4 Symptoms Tab (`SymptomsTabView`)
- **Daily check-in card:** "How are you feeling today?" with symptom chips (fever, headache, nausea, fatigue, pain, etc.).
- Severity rating: 1–5 scale (emoji or slider).
- Optional temperature entry (manual).
- Free text notes field.
- Below the check-in: scrollable **symptom log history** showing past entries with dates.
- Trend charts are a v2+ feature — show placeholder "Trends coming soon with wearable integration".

### 6.5 History Tab (`HistoryTabView`)
- **Adherence percentage** displayed prominently:
  - Formula: `(doses taken) / (total scheduled doses in period) × 100`
  - Show per-medicine breakdown.
  - Periods: 7 days, 30 days, full course.
  - `out_of_stock` doses counted **separately** — not as skipped, not as taken.
  - Chronic medicines: rolling 30-day adherence.
  - Acute medicines: full-course adherence on completion.
- **Visual charts:** Bar chart or ring chart showing daily adherence.
- **Export report button:** Generate a PDF summary (medicines, adherence, symptoms) and share via `UIActivityViewController`.

---

## Phase 7: Family / Caregiver Profiles

### 7.1 Multi-Profile Support
- One account supports up to **5 profiles** (Pro tier): e.g. Self, Mum, Dad, Child.
- Each profile has its own episodes, medicines, and reminders.
- Profile switcher in the navigation bar on Home and Episode screens.

### 7.2 Caregiver Dashboard
- Single dashboard view showing **all profiles' today schedule** at a glance.
- Caregiver can mark doses taken on behalf of any family member.
- All push notifications go to the account owner's device for all profiles.

### 7.3 v1 Scope Constraint
All profiles are **local to one device/account**. Multi-device shared caregiving is a v2 feature.

---

## Phase 8: Notification & Reminder Engine

### 8.1 Local Notification Setup
- Use `UNUserNotificationCenter` with `UNMutableNotificationContent`.
- Register notification categories with action buttons:
  - **"Taken"** — Logs dose as `.taken`
  - **"Snooze 30 mins"** — Reschedules notification
  - **"Skip"** — Logs dose as `.skipped`
- Generate local notifications from the confirmed medicine schedule (times derived from `frequency` and `timing_instructions`).

### 8.2 FCM Integration (Server-Driven)
- Register device token with backend on login.
- Backend generates reminder schedules server-side when medicines are confirmed.
- Uses Bull queue + Redis (or AWS EventBridge) to fire FCM notifications at the exact scheduled times.
- Rich notification payload: medicine name, dose amount, episode title.
- User response to the notification calls `POST /doses/:id/log` via the app delegate or notification service extension.

### 8.3 Refill Prediction (Pro Feature)
- **Formula:** `days_remaining = stock_count / doses_per_day`
- If `days_remaining <= refill_reminder_days` (default: 7) → push notification: _"Time to refill [Medicine Name]"_.
- User can update `stock_count` manually or mark "refilled" from the reminder.
- Chronic medicines without stock tracking: generate monthly refill reminders automatically.

---

## Phase 9: Subscription & Monetisation

### 9.1 Tier Definitions

| Feature | Free | Pro (₹29–49/mo) |
|---------|------|------------------|
| Active episodes | 1 only | Unlimited |
| Profiles | Self only | Up to 5 (family) |
| Prescription upload | ❌ Manual entry only | ✅ Photo/PDF + AI extraction |
| Reminders | Basic | Full (refill prediction) |
| History | 7 days | Full history + PDF export |
| Symptom trends | ❌ | ✅ Charts (v2+) |
| Wearable sync | ❌ | ✅ (v2) |

### 9.2 Tier Enforcement Logic
> **PRD Mandate:** Enforce on BACKEND, not just frontend. The app should gracefully handle 403 responses.

- **Episode count:** If Free user has 1 active episode → block creation, show `PaywallView`.
- **Profile count:** If Free user adds 2nd profile → show `PaywallView`.
- **Upload:** If Free user tries photo/PDF upload → show `PaywallView`.
- **Grace period:** NEVER delete user data on downgrade. Only restrict new actions.

### 9.3 Upgrade Prompt Strategy
- Trigger prompts **contextually** when the user hits a specific limit — NOT as an interstitial on app open.
- Name the exact feature the user tried to access.
- Offer a **7-day free trial** for Pro to reduce friction.
- Use StoreKit 2 for in-app purchase integration.

---

## Phase 10: Safety, Compliance & Data Privacy

### 10.1 AI Role Boundaries (Non-Negotiable)
- AI is used **ONLY** for extraction and organisation of existing prescriptions.
- AI is **NEVER** used for diagnosis or prescribing.
- App UI must **NEVER** phrase AI output as a recommendation or medical advice.
- Disclaimer on confirmation screen: _"Please verify all details with your doctor's prescription. This app does not provide medical advice."_

### 10.2 Data Privacy & Encryption
- All health data encrypted **at rest** (AES-256) and **in transit** (TLS 1.3).
- **Stitch MCP Security:** All communication with the Stitch MCP server must run over secure channels (HTTPS/WSS) to ensure external API data pipelines are compliant.
- Prescription images in a **private S3 bucket** with access logging enabled.
- User data **never shared** with third parties for advertising.
- **DPDP Act (India, 2023) compliance:** Privacy policy and consent flows required.
- **Right to data deletion:** User can delete their account and ALL associated data from Settings. Backend must cascade-delete across all tables.

### 10.3 App Store Compliance
- Health-related app guidelines: clearly state the app does not provide medical advice in the App Store description.
- Request only necessary permissions (Camera, Photo Library, Notifications).
- Provide a privacy nutrition label on App Store Connect.

---

## Phase 11: Polish, Testing & Launch Prep

### 11.1 Animations & Micro-Interactions
- Tab transitions: smooth cross-fade.
- Card interactions: scale-down on press (0.97), spring back on release.
- Dose logged: checkmark animation with haptic feedback.
- Pull-to-refresh with custom loading indicator.
- Skeleton/shimmer loading states for all data-fetching views.

### 11.2 Offline Resilience
- Cache all `GET` responses in CoreData/SwiftData.
- Queue `POST`/`PATCH` operations when offline.
- Show a subtle offline banner when connectivity is lost.
- Replay queued actions on reconnect with conflict resolution.

### 11.3 Testing Strategy
- **Unit tests:** ViewModels, Repositories, adherence calculation, refill prediction logic.
- **UI tests:** Onboarding flow, prescription upload flow, dose logging.
- **Device testing:** iPhone SE (small), iPhone 15 (standard), iPhone 15 Pro Max (large), iPad (if supported).
- Verify push notifications on physical devices (simulators don't support push).

### 11.4 App Store Submission Checklist
- [ ] App icon (1024×1024) and screenshots for all required device sizes.
- [ ] Privacy policy URL hosted and linked.
- [ ] App Store description with medical disclaimer.
- [ ] TestFlight beta testing completed.
- [ ] Crash-free rate validated via Xcode Organizer.

---

## Phase Roadmap Summary

| Phase | Timeline | Deliverable |
|-------|----------|-------------|
| **v1 — Core** | Month 1–3 | Upload → AI extraction → care plan → reminders + tracking |
| **v2 — Wearables** | Month 4–6 | Apple HealthKit integration, passive symptom tracking, adherence trends |
| **v3 — Teleconsult** | Month 7–12 | In-app doctor consultations, RMP verification, payment rails |
