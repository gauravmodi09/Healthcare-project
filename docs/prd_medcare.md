# MedCare: Product Requirements Document (PRD)

## 1. Product Vision & Strategy
**Vision Statement:** To create a unified, smart health companion app that empowers users to effortlessly follow through on medical advice—whether received from an external doctor, a hospital discharge, or an in-app teleconsultation.

The core value proposition of MedCare is transforming physical, unstructured medical documents (prescriptions, discharge summaries) into structured, actionable, and trackable care plans with automated, reliable reminders.

**Target Market:** India-first. English-only interface.

**India Market Insight:** Indian prescriptions are predominantly handwritten, often illegible, and mix English with Latin abbreviations (e.g., "Tab. Crocin 1 BD × 5/7 PC"). Rather than relying solely on prescription OCR, MedCare's core innovation is a **dual-capture approach**: users photograph both the prescription (for context like doctor name, diagnosis, frequency) AND the physical medicine boxes/strips they purchased (for accurate drug names, dosages, manufacturer details, and expiry dates). Medicine packaging in India carries standardized printed text mandated by CDSCO, making it far more reliable for AI extraction than handwritten prescriptions.

## 2. Target Audience & Personas
MedCare targets users who actively manage their own health or act as primary caregivers for family members.

*   **The Busy Professional (Aged 25-45):** Needs quick, frictionless ways to track short-term acute illnesses (e.g., Fever, Cough) without manual data entry. Values speed and the "magic" of AI extraction.
*   **The Caregiver (Aged 35-55):** Manages medications and appointments for elderly parents or children. Values multi-profile support, shared dashboards, and adherence tracking.
*   **The Chronic Patient (Aged 40+):** Manages conditions like diabetes or hypertension requiring long-term medication adherence. Values refill prediction, symptom trending, and historical health records.
*   **The Post-Discharge Patient:** Requires highly structured recovery plans involving medications, physiotherapy tasks, and follow-up lab tests.

## 3. Product Roadmap & Phasing

### Phase 1: Core Foundation (Months 1-3) *[CURRENT FOCUS]*
*   **Objective:** Establish the core "Upload to Care Plan" loop.
*   **Key Features:** User authentication (OTP), multi-profile management, prescription upload via Camera/Gallery, AI-driven OCR extraction using GPT-4 Vision, human-in-the-loop confirmation screen, scheduled reminders, dose logging, and manual symptom tracking.

### Phase 2: Wearable Integration (Months 4-6)
*   **Objective:** Introduce passive health tracking.
*   **Key Features:** Integration with Apple HealthKit (iOS) and Health Connect (Android) to sync resting heart rate, SpO2, sleep, and steps. Correlate adherence data (e.g., missed blood pressure meds) with passive symptom trends.

### Phase 3: Telemedicine (Months 7-12)
*   **Objective:** Close the loop by offering in-app medical consultations.
*   **Key Features:** Video/Chat consultations with verified RMP (Registered Medical Practitioners), direct generation of care plans by doctors, and integrated payment rails.

## 4. User Journeys & Core Flows (Phase 1)

### 4.1 Onboarding Flow (Target: < 60 seconds)
1.  **Splash Screen:** Branding ("Your care plan, always with you").
2.  **Auth:** Phone number entry -> OTP verification.
3.  **Profile Setup:** Name, age, gender. (Medical history is lazily collected later to reduce drop-off).
4.  **Permissions:** Push notification request (critical for the app's core value).
5.  **Home Dashboard:** User is presented with two primary "Doors": **Consult a Doctor** (Phase 3 placeholder) and **Upload Prescription** (Phase 1 active).

### 4.2 The Core "Magic" Loop (Dual-Capture Upload -> Plan)
1.  **Capture — Step 1 (Prescription):** User taps "Upload Prescription". Options: Camera, Gallery, PDF. This captures the doctor's prescription for context — doctor name, diagnosis, frequency instructions, duration.
2.  **Capture — Step 2 (Medicine Photos — Mandatory):** After uploading the prescription, the app prompts the user to photograph each medicine box/strip/bottle they purchased from the pharmacy. This is the **primary source of truth** for accurate medicine names, strengths, dosages, manufacturer, and expiry dates. The user can add multiple medicine photos.
    *   *Why this works in India:* All medicines sold in India carry standardized printed labels (brand name, generic name, composition, dosage, MRP, expiry, batch number) mandated by the Drugs and Cosmetics Act. This printed text is far more reliable for AI extraction than handwritten prescriptions.
    *   *UX:* The app guides the user with a simple "Scan your medicines" screen showing an example photo of a medicine strip. Users can add 1-10 medicine photos. A "Skip" option exists for users who don't have the medicines yet (falls back to prescription-only extraction with lower confidence).
3.  **AI Extraction (Cross-Reference):** The backend sends ALL images (prescription + medicine photos) to GPT-4 Vision. The AI:
    *   Extracts medicine names, strengths, and manufacturer from the **medicine packaging photos** (high confidence).
    *   Extracts frequency, duration, timing instructions, and doctor details from the **prescription photo** (moderate confidence).
    *   Cross-references both sources — matching medicines on the prescription to the physical packaging to build a complete, validated record.
    *   Assigns per-field confidence scores. Fields sourced from printed packaging get higher scores than those from handwritten text.
4.  **Safety Confirmation (Critical):** The user is presented with a view of all uploaded images alongside the extracted data.
    *   *Rule:* Any field flagged with "Low Confidence" by the AI is highlighted with an amber warning.
    *   *Rule:* The user *must* explicitly tap 'Confirm' to approve the plan.
    *   *Rule:* Fields extracted from medicine photos show a "Verified from packaging" badge for user trust.
5.  **Plan Activation:** The system generates the schedule. The user lands on the Episode Detail Screen.

### 4.3 Episode Management (The 4-Tab Interface)
An "Episode" is a container for a specific illness or condition (e.g., "Fever & Cough", "Diabetes").
1.  **Plan Tab:** View/Edit medicines, non-medicine tasks (wound care, lab tests), and follow-up appointment dates.
2.  **Reminders Tab:** A chronological timeline of today's scheduled doses. Actions: Mark Taken, Snooze, Skip, Out of Stock.
3.  **Symptoms Tab:** Daily check-in cards for subjective symptoms, severity sliders, and free-text notes.
4.  **History Tab:** Adherence percentages, historical logs, and PDF report generation for doctor visits.

## 5. Monetization Strategy (Freemium Model)

### 5.1 Free Tier (Entry Level)
*   Limits: 1 active episode, 1 profile (self only), completely manual data entry (No AI Upload), 7-day history retention.
*   Goal: Allow users to experience the reminder engine and UI for an acute illness.

### 5.2 Pro Tier (Subscription)
*   Limits: Unlimited episodes, up to 5 family profiles, full AI Photo/PDF extraction, refill prediction, symptom trend charts, infinite history retention.
*   Enforcement: Hard blocks on the backend when upload limits are reached, seamlessly triggering a contextual upgrade prompt (e.g., "Upgrade to Pro to let AI read this prescription").

### 5.3 Teleconsult Mode (Phase 3 Transactional)
*   Per-consult fee. The platform takes a 20-30% margin on the RMP's consultation rate.

## 6. Non-Functional Requirements & Safety
*   **AI Boundary:** The AI must only be used as a parsing utility, never as a diagnostic tool.
*   **Medical Disclaimer:** "Please verify all details with your doctor's prescription. This app does not provide medical advice." must be highly visible during the confirmation step.
*   **Offline Functionality:** Scheduled reminders must still trigger, and users must be able to log doses locally if the internet connection drops, syncing to the backend when restored.

## 7. India Market Considerations

### 7.1 Why Medicine Photos Change Everything
Indian prescriptions are notoriously difficult to parse:
- 80%+ are handwritten on plain paper or pre-printed letterheads
- Doctors mix English, Hindi, and Latin abbreviations freely
- Same molecule is sold under 50+ brand names (Paracetamol = Crocin = Dolo = Calpol)

Medicine packaging, however, is **standardized by CDSCO regulations**:
- Brand name, generic/salt composition, strength, dosage form — all printed clearly
- Manufacturer name, batch number, MRP, expiry date — always present
- This makes medicine box/strip photos the ideal primary input for AI extraction

### 7.2 Dual-Capture Value Proposition
| Source | What It Provides | Confidence |
|--------|-----------------|------------|
| **Medicine packaging photo** | Drug name, generic name, strength, manufacturer, expiry, MRP | **High** (printed text) |
| **Prescription photo** | Doctor name, diagnosis, frequency (BD/TDS), duration, timing (before/after food) | **Moderate** (handwritten) |
| **Cross-reference** | Complete care plan: right drug + right dose + right schedule | **Highest** (validated) |

### 7.3 Indian Pharmacy Workflow Alignment
The dual-capture flow aligns naturally with how Indians buy medicines:
1. Visit doctor → get prescription (handwritten)
2. Go to pharmacy → buy medicines (printed packaging)
3. Come home → open MedCare → scan both → get care plan

The app captures the user at the moment they have **both artifacts in hand** — right after the pharmacy visit.

### 7.4 Additional India-Specific Features (v1)
- **OTP via MSG91** (primary) with Twilio fallback — MSG91 has better deliverability and lower cost for Indian numbers
- **+91 pre-filled** on phone number entry
- **Pricing in INR** — ₹29-49/month Pro tier
- **Low-bandwidth optimization** — compress images before upload, progressive upload with resume
- **DPDP Act 2023 compliance** — consent flows, right to erasure, data minimization

### 7.5 Future India Enhancements (v2+)
- **ABHA (Ayushman Bharat Health Account)** integration for national health ID linking
- **UPI payments** via Razorpay for teleconsult (Phase 3)
- **Generic medicine suggestions** — flag cheaper Jan Aushadhi alternatives
- **WhatsApp dose reminders** — critical for Android users where OEM battery optimization kills push notifications
- **Caregiver remote access** — son in Bangalore managing parents' medicines in hometown
- **Drug interaction warnings** across episodes from different doctors
