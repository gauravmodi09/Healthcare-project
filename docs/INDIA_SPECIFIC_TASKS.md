# MedCare — India-Specific Differentiators: Detailed Task Breakdown
**Date:** 2026-03-21

---

## 1. ABDM / ABHA Integration (22 tasks)

### 1.1 Sandbox Setup & Registration
- [ ] **ABDM-001** Register on sandbox.abdm.gov.in, obtain sandbox client ID + secret
- [ ] **ABDM-002** Set up ABDM gateway callback URLs in backend
- [ ] **ABDM-003** Register as Health Information Provider (HIP) with test HIP ID
- [ ] **ABDM-004** Register as Health Information User (HIU) with test HIU ID

### 1.2 Milestone 1 — ABHA ID (Patient Health ID)
- [ ] **ABDM-005** ABHA creation via Aadhaar OTP flow (generateOtp → verifyOtp → createHealthId)
- [ ] **ABDM-006** ABHA creation via mobile number flow (alternative)
- [ ] **ABDM-007** ABHA address creation (user@abdm format)
- [ ] **ABDM-008** ABHA verification + linking to MedCare patient profile
- [ ] **ABDM-009** Store ABHA number securely (encrypted at rest)
- [ ] **ABDM-010** Patient UI — "Link ABHA ID" flow in Profile settings with Aadhaar/mobile OTP

### 1.3 Milestone 2 — Health Information Provider (Share Records)
- [ ] **ABDM-011** Care context creation — link episodes/consultations as care contexts
- [ ] **ABDM-012** FHIR bundle generation — Prescription records (MedicationRequest + Patient + Practitioner)
- [ ] **ABDM-013** FHIR bundle generation — Diagnostic Reports (DiagnosticReport + Observation)
- [ ] **ABDM-014** FHIR bundle generation — Wellness Records (vitals, body measurements)
- [ ] **ABDM-015** FHIR bundle generation — Health Documents (uploaded PDFs, images)
- [ ] **ABDM-016** Share records to ABHA PHR app via HIP callback APIs

### 1.4 Milestone 3 — Health Information User (Fetch Records)
- [ ] **ABDM-017** Consent request initiation — request patient's health records from other providers
- [ ] **ABDM-018** Consent artifact management — track granted/denied/expired consents
- [ ] **ABDM-019** Health data fetch — receive encrypted FHIR bundles, decrypt, parse, display
- [ ] **ABDM-020** Patient UI — "Import Health Records" screen showing available records from other hospitals

### 1.5 Production Certification
- [ ] **ABDM-021** WASA (Web Application Security Audit) — engage CERT-IN empaneled auditor
- [ ] **ABDM-022** NHA production approval — submit audit reports, get production credentials

---

## 2. DPDPA 2023 Compliance (15 tasks)

### 2.1 Consent Framework
- [ ] **DPDPA-001** Consent collection UI — granular, purpose-specific consent at registration
- [ ] **DPDPA-002** Consent purposes — define all data processing purposes (health tracking, doctor sharing, analytics, notifications)
- [ ] **DPDPA-003** Consent withdrawal — one-tap withdrawal flow, as easy as giving consent
- [ ] **DPDPA-004** Consent audit trail — log all consent events (granted, withdrawn, modified) with timestamps
- [ ] **DPDPA-005** Re-consent flow — prompt when processing purposes change

### 2.2 Data Protection
- [ ] **DPDPA-006** Data localization — host ALL data on Indian servers (AWS Mumbai ap-south-1)
- [ ] **DPDPA-007** Encryption at rest — AES-256 for all health data in PostgreSQL + S3
- [ ] **DPDPA-008** Encryption in transit — TLS 1.3 for all API calls
- [ ] **DPDPA-009** Data minimization — collect only necessary data, no over-collection
- [ ] **DPDPA-010** Access logging — audit log for all health data access (who, what, when)

### 2.3 User Rights
- [ ] **DPDPA-011** Right to erasure — "Delete My Data" flow with cascading deletion across DB + backups + third-party
- [ ] **DPDPA-012** Data portability — export all health data as JSON/CSV on user request
- [ ] **DPDPA-013** Grievance redressal — in-app support channel for data privacy complaints

### 2.4 Breach & Compliance
- [ ] **DPDPA-014** Breach notification system — alert Data Protection Board within 72 hours + notify users
- [ ] **DPDPA-015** Children's data — age gate + verifiable parental consent for under-18 profiles

---

## 3. UPI Payment Integration (12 tasks)

### 3.1 Razorpay SDK Setup
- [ ] **UPI-001** Razorpay account registration + business verification
- [ ] **UPI-002** Razorpay iOS SDK integration (SPM/CocoaPod)
- [ ] **UPI-003** Payment backend — create orders, verify payments, handle webhooks
- [ ] **UPI-004** UPI Intent flow — show installed UPI apps (PhonePe, GPay, Paytm, CRED)

### 3.2 Subscription Billing
- [ ] **UPI-005** Create subscription plans via Razorpay API (Free/Pro/Premium + Doctor Solo/Clinic/Hospital)
- [ ] **UPI-006** UPI Autopay mandate — INR 1 authorization flow
- [ ] **UPI-007** Recurring billing — auto-debit on cycle with smart retries
- [ ] **UPI-008** Subscription management UI — upgrade/downgrade/cancel
- [ ] **UPI-009** Grace period + dunning — handle failed payments gracefully

### 3.3 In-Clinic Payments
- [ ] **UPI-010** Dynamic QR code generation for doctor consultation fees
- [ ] **UPI-011** Payment receipt generation — PDF with GST details
- [ ] **UPI-012** Refund handling via Razorpay Refund API

---

## 4. Telemedicine Compliance (10 tasks)

### 4.1 Doctor Verification
- [ ] **TELE-001** NMC/State Medical Council registration number verification API integration
- [ ] **TELE-002** Doctor credential display — registration number, qualification on profile
- [ ] **TELE-003** Drug scheduling engine — classify drugs as List A/B/C per telemedicine guidelines

### 4.2 Consultation Compliance
- [ ] **TELE-004** Patient consent capture — implied (patient-initiated) vs explicit (doctor-initiated) with logging
- [ ] **TELE-005** Video/audio recording consent — separate explicit consent if recording enabled
- [ ] **TELE-006** NMC-compliant e-prescription format — registration number, digital signature, drug schedule validation
- [ ] **TELE-007** Schedule X/NDPS drug block — prevent prescribing prohibited substances via teleconsult

### 4.3 Record & Safety
- [ ] **TELE-008** Consultation record storage — 3-year minimum retention with audit trail
- [ ] **TELE-009** Emergency referral mechanism — "Refer to in-person care" button during teleconsult
- [ ] **TELE-010** Cross-state practice support — allow consultations across all Indian states

---

## 5. Indian Wearable Ecosystem Integration (18 tasks)

### 5.1 Apple HealthKit (iOS Priority)
- [ ] **WEAR-001** HealthKit authorization — request read access for HR, SpO2, steps, sleep, workouts, ECG
- [ ] **WEAR-002** Background delivery setup — auto-import new samples in background
- [ ] **WEAR-003** Apple Watch data — ECG, wrist temperature, respiratory rate
- [ ] **WEAR-004** Vitals dashboard display — HealthKit data with source attribution
- [ ] **WEAR-005** Write to HealthKit — push medication logs, symptom entries back

### 5.2 Budget Wearable Support (via Health Connect / Terra)
- [ ] **WEAR-006** Terra API integration — connect 400+ wearables via single API
- [ ] **WEAR-007** Noise Health API direct integration — HR, sleep, steps, SpO2, stress
- [ ] **WEAR-008** Health Connect bridge — read data written by boAt, Fire-Boltt, Amazfit companion apps
- [ ] **WEAR-009** Data normalization layer — standardize HR/SpO2/sleep/steps across all sources
- [ ] **WEAR-010** Source management UI — "Connected Devices" screen showing all linked wearables

### 5.3 CGM (Continuous Glucose Monitor) Integration
- [ ] **WEAR-011** FreeStyle Libre integration via LibreView API / Terra API
- [ ] **WEAR-012** Glucose data display — real-time readings, daily pattern, time-in-range
- [ ] **WEAR-013** Glucose trend charts — 24-hour, 7-day, 30-day, 90-day AGP report
- [ ] **WEAR-014** Glucose alerts — hypo/hyper threshold notifications
- [ ] **WEAR-015** Glucose-medication correlation — "Your glucose drops 15% after Glycomet"

### 5.4 BP Monitor Integration
- [ ] **WEAR-016** Omron BP monitor — HealthKit integration (Omron Connect writes to HealthKit)
- [ ] **WEAR-017** Manual BP entry with clinical formatting (systolic/diastolic/pulse)
- [ ] **WEAR-018** BP trend charts with hypertension staging (Normal/Elevated/Stage 1/Stage 2/Crisis)

---

## 6. WhatsApp-Replacement Doctor Communication (8 tasks)

### 6.1 Structured Messaging (Replace WhatsApp)
- [ ] **MSG-001** Async message threads — organized by patient, topic, date
- [ ] **MSG-002** Message types — text, photo, document, voice note, lab result attachment
- [ ] **MSG-003** Response SLA indicator — "Doctor typically responds within 4 hours"
- [ ] **MSG-004** Doctor boundary settings — available hours, auto-reply for off-hours
- [ ] **MSG-005** Quick reply templates for doctors — "Continue current medication", "Please come for checkup"
- [ ] **MSG-006** Read receipts + delivery status

### 6.2 Communication Boundaries
- [ ] **MSG-007** Rate limiting — patients can send max 5 messages/day (prevent spam)
- [ ] **MSG-008** Emergency escalation — "Mark as Urgent" flag that bypasses off-hours

---

## 7. Walk-In Queue Management (6 tasks — India-Specific)

Most Indian clinics don't do appointments — patients walk in and wait.

- [ ] **QUEUE-001** Walk-in registration — receptionist adds patient to today's queue
- [ ] **QUEUE-002** Queue display — patient sees their position + estimated wait time
- [ ] **QUEUE-003** Real-time queue updates — position changes as patients are seen
- [ ] **QUEUE-004** "Your Turn" push notification — alert when 2 patients ahead
- [ ] **QUEUE-005** Queue analytics for doctors — avg wait time, peak hours
- [ ] **QUEUE-006** Mixed mode — support both appointment + walk-in in same day

---

## 8. Ayushman Bharat (PMJAY) Integration (5 tasks)

Government insurance covering 500M+ Indians for hospitalization.

- [ ] **PMJAY-001** PMJAY eligibility check — verify if patient is covered via API
- [ ] **PMJAY-002** Pre-authorization submission — submit treatment request to TPA
- [ ] **PMJAY-003** Claim submission — post-treatment claim with required documents
- [ ] **PMJAY-004** Claim status tracking — real-time status updates
- [ ] **PMJAY-005** Patient UI — "Check Ayushman Bharat eligibility" in Profile

---

## 9. Indian Drug Database Enhancement (7 tasks)

- [ ] **DRUG-001** Expand IndianDrugDatabase from 32 to 500+ common Indian medicines
- [ ] **DRUG-002** Jan Aushadhi price database — complete catalog from janaushadhi.gov.in
- [ ] **DRUG-003** Generic equivalent mapping — brand → molecule → all equivalent brands
- [ ] **DRUG-004** Drug schedule classification — List A/B/C per telemedicine guidelines
- [ ] **DRUG-005** Drug-food interaction database — Indian foods (dahi, amla, haldi, methi)
- [ ] **DRUG-006** Ayurvedic medicine database — 200+ common Ayurvedic preparations
- [ ] **DRUG-007** Drug price comparison — MRP vs online pharmacy vs Jan Aushadhi

---

## 10. Regional Language Deep Support (8 tasks)

- [ ] **LANG-001** Full UI localization framework — all strings externalized
- [ ] **LANG-002** Hindi UI translation — all labels, buttons, messages
- [ ] **LANG-003** Tamil UI translation
- [ ] **LANG-004** Telugu UI translation
- [ ] **LANG-005** Marathi UI translation
- [ ] **LANG-006** Bengali UI translation
- [ ] **LANG-007** Kannada + Malayalam + Gujarati UI translations
- [ ] **LANG-008** RTL/script-specific layout testing — ensure no text truncation in regional scripts

---

## Task Count Summary

| Area | Tasks |
|------|-------|
| ABDM/ABHA Integration | 22 |
| DPDPA Compliance | 15 |
| UPI Payments | 12 |
| Telemedicine Compliance | 10 |
| Wearable Integration | 18 |
| Doctor Messaging | 8 |
| Walk-In Queue | 6 |
| Ayushman Bharat | 5 |
| Indian Drug Database | 7 |
| Regional Languages | 8 |
| **Total India-Specific** | **111** |

Combined with Platform Plan: **186 + 111 = 297 total tasks**

---

## Implementation Priority (India-Specific)

### Month 1-2: Foundation
- DPDPA consent framework (DPDPA-001 to DPDPA-010)
- Data localization on AWS Mumbai
- Apple HealthKit integration (WEAR-001 to WEAR-005)
- UPI payment setup (UPI-001 to UPI-004)

### Month 2-3: Core India Features
- ABDM sandbox M1 — ABHA ID creation (ABDM-001 to ABDM-010)
- Telemedicine compliance (TELE-001 to TELE-007)
- Doctor messaging — WhatsApp replacement (MSG-001 to MSG-008)
- Indian drug database expansion (DRUG-001 to DRUG-003)

### Month 3-5: Advanced Integration
- ABDM M2/M3 — share/fetch health records (ABDM-011 to ABDM-020)
- Wearable integrations — Noise API, CGM, BP monitors (WEAR-006 to WEAR-018)
- Walk-in queue management (QUEUE-001 to QUEUE-006)
- UPI subscriptions + in-clinic payments (UPI-005 to UPI-012)

### Month 5-7: Certification & Scale
- ABDM production certification (ABDM-021 to ABDM-022)
- Ayushman Bharat integration (PMJAY-001 to PMJAY-005)
- Full regional language support (LANG-001 to LANG-008)
- DPDPA audit + compliance review (DPDPA-014 to DPDPA-015)
