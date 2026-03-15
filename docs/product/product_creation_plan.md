# MedCare: Unified Product Creation Plan

This document synthesizes the [PRD](file:///Users/modi/.gemini/antigravity/brain/5704d3f7-5d11-421c-bf15-e327bd036062/prd_medcare.md), [TRD](file:///Users/modi/.gemini/antigravity/brain/5704d3f7-5d11-421c-bf15-e327bd036062/trd_medcare.md), [HLD](file:///Users/modi/.gemini/antigravity/brain/5704d3f7-5d11-421c-bf15-e327bd036062/hld_medcare.md), and [LLD](file:///Users/modi/.gemini/antigravity/brain/5704d3f7-5d11-421c-bf15-e327bd036062/lld_medcare.md) into a single, clean execution roadmap. It identifies gaps, resolves ambiguities, and lays out a sprint-by-sprint path from zero to App Store submission.

---

## 1. Cross-Document Audit

Before building, I reviewed all four documents for consistency. Here is a summary of findings and resolutions.

| Area | Finding | Resolution |
|---|---|---|
| **Database schema** | LLD updated with `episode_images` table for dual-capture (prescription + medicine photos) | ✅ Resolved |
| **Episode fields** | LLD `episodes` table updated with `source`, `doctor_name`, `follow_up_date` columns | ✅ Resolved |
| **Medicine fields** | LLD `medicines` table updated with `generic_name`, `manufacturer`, `expiry_date`, `mrp`, `packaging_image_id` for packaging extraction | ✅ Resolved |
| **API naming** | All docs standardized: `POST /episodes/:id/upload` triggers extraction with dual-capture payload | ✅ Consistent |
| **Confirmation API** | All docs agree on `POST /episodes/:id/confirm` as the HITL gate | ✅ Consistent |
| **Dual-capture flow** | PRD, HLD, LLD, TRD all describe dual-capture (prescription + medicine photos) as core flow | ✅ Consistent |
| **Offline support** | PRD & TRD both require offline dose logging; LLD describes SwiftData cache | ✅ Consistent |
| **Token lifecycle** | TRD specifies 15m access / 30d refresh; LLD will inherit TRD spec | ✅ Consistent |
| **India market** | All docs updated: English-only, India-first, DPDP Act compliance, INR pricing | ✅ Consistent |

> [!IMPORTANT]
> LLD still needs `tasks` and `symptom_logs` tables added in Sprint 2 migration. The `episode_images` table is new and must be included in `002_episodes_medicines.sql`.

---

## 2. Document Relationship Map

```mermaid
graph LR
    PRD["PRD<br/>What to Build"] --> HLD["HLD<br/>How It Fits Together"]
    PRD --> TRD["TRD<br/>Tech Constraints"]
    HLD --> LLD["LLD<br/>Exact Blueprints"]
    TRD --> LLD
    LLD --> Code["Sprint Execution"]
    HLD --> Code
```

- **PRD** answers *what* and *why* (features, personas, monetization).
- **TRD** answers *with what* (stack, security, compliance constraints).
- **HLD** answers *how it connects* (system architecture, data flows).
- **LLD** answers *how to build it* (schemas, API contracts, Swift components).

---

## 3. Phased Sprint Plan (12 Weeks to v1 Launch)

### Phase A: Foundation (Weeks 1-3)

#### Sprint 1 — Project Scaffolding & Design System
| Item | Details |
|---|---|
| **iOS** | Create Xcode project (SwiftUI, iOS 16+). Set up folder structure: `/Models`, `/Views`, `/ViewModels`, `/Repositories`, `/Services`. |
| **Backend** | Initialize Node.js + Express project. Configure ESLint, Prettier, Docker Compose for local dev (Postgres + Redis). |
| **Database** | Write migration `001_initial_schema.sql`: `users`, `profiles` tables per LLD. |
| **Design** | Implement the design system in SwiftUI: color tokens (`#0A7E8C`, `#FF6B6B`, `#F7F9FC`), typography (Inter font), spacing scale. |
| **Infra** | Set up GitHub repo, CI/CD with GitHub Actions, Fastlane for TestFlight. |
| ✅ **Done when** | Empty app compiles, backend serves `/health`, database migrates cleanly. |

#### Sprint 2 — Auth & Core Data Layer
| Item | Details |
|---|---|
| **Auth** | Implement OTP flow: `POST /auth/send-otp`, `POST /auth/verify-otp`. Integrate MSG91 (primary, India) with Twilio fallback. JWT access (15m) + refresh (30d) tokens per TRD. Phone number entry pre-fills +91. |
| **iOS Auth** | Build `SplashView`, `PhoneEntryView` (+91 default), `OTPVerificationView`. Store JWT in Keychain. |
| **Database** | Migration `002_episodes_medicines.sql`: `episodes` (with `source`, `doctor_name`, `follow_up_date`), `episode_images` (new — for prescription + medicine photos), `medicines` (with `generic_name`, `manufacturer`, `expiry_date`, `mrp`, `packaging_image_id`), `dose_logs`, `tasks`, `symptom_logs`. |
| **Profile** | `POST /profiles`, `GET /profiles`. iOS `ProfileSetupView` with name, age, gender. |
| ✅ **Done when** | User can sign up via OTP, create a profile, and see an empty Home Screen. |

#### Sprint 3 — Home Dashboard & Episode Shell
| Item | Details |
|---|---|
| **iOS** | Build `HomeView` with two CTAs per Stitch mockup. Bottom tab bar (Home, Episodes, Records, Profile). |
| **Episodes API** | `GET /episodes`, `POST /episodes` (manual creation), `GET /episodes/:id`. |
| **iOS Episodes** | `EpisodeListView`, `EpisodeDetailView` with 4-tab skeleton (Plan, Reminders, Symptoms, History). |
| ✅ **Done when** | User can manually create an episode titled "Fever" and see it on the home screen. |

---

### Phase B: The "Magic" Loop (Weeks 4-6)

#### Sprint 4 — Dual-Capture Upload & S3
| Item | Details |
|---|---|
| **Backend** | `GET /episodes/:id/upload-urls?count=N` returns multiple pre-signed S3 PUT URLs. Configure S3 bucket with SSE-S3 encryption, private ACLs, and `aws:SecureTransport` policy per TRD. Create `episode_images` records on upload completion. |
| **iOS — Prescription Capture** | Build `PrescriptionCaptureView`: Camera, Gallery picker, PDF import for the doctor's prescription. |
| **iOS — Medicine Scan** | Build `MedicineScanView`: Dedicated screen prompting user to photograph each medicine box/strip/bottle they purchased. Shows guide image. Grid layout with "+" button (1-10 photos). "I don't have medicines yet" skip option with lower confidence warning. |
| **iOS — Upload** | `ImageUploadRepository` compresses images (target < 500KB) and uploads to S3 via pre-signed URLs with progressive upload + resume for unreliable Indian networks. `UploadProgressView` shows per-image progress. |
| ✅ **Done when** | User can photograph a prescription + medicine boxes, all images appear encrypted in S3 with correct `image_type` metadata. |

#### Sprint 5 — Dual-Capture AI Extraction Pipeline (GPT-4V + Stitch)
| Item | Details |
|---|---|
| **Backend — Medicine Extraction** | `POST /episodes/:id/upload` with `{ prescriptionKeys, medicinePhotoKeys }`. GPT-4V extracts from medicine packaging photos (primary): brand name, generic name, strength, manufacturer, MRP, expiry. High confidence (printed text). |
| **Backend — Prescription Extraction** | GPT-4V extracts from prescription photo (context): doctor name, frequency, duration, timing instructions. Variable confidence (handwritten). |
| **Backend — Cross-Reference** | Merge both extractions. Match prescription line items to medicine packaging. Per-field `sourceBreakdown` and `confidenceScore`. Flag `unmatchedPrescriptionItems`. Pipe through Stitch MCP for pharma DB validation. |
| **Safety** | The API must **never** write to `medicines` table at this step. This is a hard architectural constraint. |
| **iOS** | Build `ConfirmationView`: all uploaded images + extracted cards with source badges ("From packaging" / "From prescription"). Amber warning on fields with `confidenceScore < 0.70`. "Needs Your Input" section for unmatched items. Medicine photo thumbnails on each card. |
| ✅ **Done when** | User uploads prescription + medicine photos, sees cross-referenced extraction with source attribution and confidence indicators. |

#### Sprint 6 — Confirmation & Plan Activation
| Item | Details |
|---|---|
| **Backend** | `POST /episodes/:id/confirm` accepts the user-curated `confirmedMedicines[]` array with `doctorName`. Creates `Medicine` rows (with `generic_name`, `manufacturer`, `expiry_date`, `mrp`, `packaging_image_id`), generates 30-day `DoseLog` projections, creates `Task` rows from extracted non-medicine items. |
| **iOS** | `ConfirmationViewModel` validates all medicines are explicitly confirmed (including any manually added from unmatched items). Enable CTA only when complete. Navigate to `EpisodeDetailView` (Plan tab) on success. |
| **Disclaimer** | Medical disclaimer text visible on Confirmation screen per PRD Section 6. |
| ✅ **Done when** | Full "Prescription + Medicine Photos → Extract → Cross-Reference → Confirm → Plan Created" loop works end-to-end. |

---

### Phase C: Adherence Engine (Weeks 7-9)

#### Sprint 7 — Reminders & Push Notifications
| Item | Details |
|---|---|
| **Backend** | On plan confirmation, schedule BullMQ/Redis jobs for each `DoseLog`. Jobs fire FCM push 5 minutes before `scheduled_at`. Payload includes medicine name, dose, and action buttons (Taken, Snooze, Skip). |
| **iOS** | Register for FCM. Handle actionable notifications. Build `RemindersTabView` showing today's timeline. |
| ✅ **Done when** | User receives a push notification at the correct time and can tap "Taken" from the lock screen. |

#### Sprint 8 — Dose Logging & Offline Sync
| Item | Details |
|---|---|
| **Backend** | `POST /doses/:id/log` accepts `{ status: "taken" | "skipped" | "out_of_stock" }`. |
| **iOS** | `DoseLogRepository` writes to local SwiftData first, then syncs to backend. `OfflineSyncManager` queues failed requests and retries on connectivity restoration. |
| **Adherence API** | `GET /episodes/:id/adherence` returns `{ adherencePercent, takenCount, skippedCount, totalScheduled }`. |
| ✅ **Done when** | User can log doses offline; data syncs when back online. Adherence % is accurate. |

#### Sprint 9 — Symptoms & History
| Item | Details |
|---|---|
| **Backend** | `POST /symptoms` logs daily check-in. `GET /episodes/:id/history` returns adherence + symptom timeline. |
| **iOS** | `SymptomsTabView` with daily check-in card, severity slider (1-5), free text. `HistoryTabView` with adherence chart and exportable PDF. |
| ✅ **Done when** | User can log symptoms, view adherence trends, and export a PDF report. |

---

### Phase D: Polish & Launch (Weeks 10-12)

#### Sprint 10 — Multi-Profile & Monetization
| Item | Details |
|---|---|
| **Profiles** | Profile switcher on Home screen. CRUD for family profiles. Backend enforces Free tier limits (1 profile, 1 episode, no AI upload). |
| **Paywall** | Contextual upgrade prompts per PRD. Integrate RevenueCat or StoreKit 2 for subscription management. |
| ✅ **Done when** | Free user hits limit → sees upgrade prompt. Pro user has full access. |

#### Sprint 11 — Security Hardening & Compliance
| Item | Details |
|---|---|
| **SSL Pinning** | Implement certificate pinning in the iOS networking layer per TRD. |
| **Data Deletion** | `DELETE /user` cascading delete of all data + S3 objects per DPDP Act. |
| **Analytics** | Integrate Mixpanel/Amplitude with PII scrubbing at the gateway layer per TRD. |
| ✅ **Done when** | Penetration test passes. User can delete account and all data is purged. |

#### Sprint 12 — QA, Beta & App Store Submission
| Item | Details |
|---|---|
| **QA** | Full regression testing across all flows. Edge cases: expired JWT, no internet, massive prescription (10 pages), low-confidence on every field. |
| **Beta** | TestFlight distribution to 20-50 beta testers. Collect feedback via in-app form. |
| **Submission** | App Store review prep: privacy nutrition labels, medical disclaimer, screenshots. |
| ✅ **Done when** | App is live on the App Store. |

---

## 4. Dependency Graph

```mermaid
graph TD
    S1[Sprint 1: Scaffolding] --> S2[Sprint 2: Auth & Data]
    S2 --> S3[Sprint 3: Home & Episodes]
    S3 --> S4[Sprint 4: Dual-Capture & S3]
    S4 --> S5[Sprint 5: Dual-Capture AI Extraction]
    S5 --> S6[Sprint 6: Confirmation]
    S6 --> S7[Sprint 7: Reminders]
    S7 --> S8[Sprint 8: Dose Logging]
    S8 --> S9[Sprint 9: Symptoms]
    S3 --> S10[Sprint 10: Profiles & Paywall]
    S9 --> S11[Sprint 11: Security]
    S10 --> S12[Sprint 12: Launch]
    S11 --> S12

    style S5 fill:#FF6B6B,color:#fff
    style S6 fill:#FF6B6B,color:#fff
```

> [!TIP]
> **Critical Path** (highlighted in red): Sprints 5 and 6 (AI Extraction + Confirmation) are the highest-risk, highest-value sprints. They contain the core "magic" of the product and the critical safety gate. Allocate extra time and testing here.

---

## 5. Risk Register

| # | Risk | Impact | Mitigation |
|---|---|---|---|
| 1 | GPT-4V hallucinating wrong medicine names | **Critical** — Patient safety | Dual-capture cross-reference (packaging is primary source) + Stitch MCP pharma DB validation + mandatory user confirmation (HITL) |
| 2 | Handwritten prescriptions unreadable by OCR | **Mitigated** — No longer primary source | Medicine packaging photos are the primary extraction source (printed text). Prescription is used only for context (frequency, duration). Unmatched items prompt manual entry. |
| 3 | Push notification delivery unreliable on Indian Android OEMs | High — Core value broken | Use FCM high-priority channel. Local iOS `UNNotificationRequest` as fallback. Consider WhatsApp reminders in v2. |
| 4 | App Store rejection for medical claims | Medium — Launch delay | Strict disclaimer language. AI is "extraction only", never "diagnosis". |
| 5 | S3 upload fails on slow Indian networks (2G/3G) | Medium — UX friction | Image compression (< 500KB), progressive upload with resume, 15-minute URL expiry, retry logic in `ImageUploadRepository`. |
| 6 | User doesn't photograph all medicines | Medium — Incomplete care plan | Show clear count ("3 medicines on prescription, 2 photographed"). Prompt for missing ones. Allow manual entry for the rest. |
| 7 | Cross-reference fails to match prescription to packaging | Low — Extra manual work | Fuzzy matching on medicine names. Unmatched items shown in "Needs Your Input" section with manual entry form. |

---

## 6. Success Metrics (v1 Launch)

| Metric | Target | Measured By |
|---|---|---|
| Onboarding completion rate | > 80% | Analytics funnel |
| AI extraction accuracy (post-Stitch) | > 90% field-level | Backend logging |
| Daily reminder response rate | > 60% | DoseLog status != pending |
| 7-day retention | > 40% | Analytics cohort |
| Pro conversion (Month 3) | > 5% of MAU | RevenueCat dashboard |
| App crash rate | < 1% | Firebase Crashlytics |
