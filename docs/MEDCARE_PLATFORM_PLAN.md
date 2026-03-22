# MedCare Platform — Doctor-Patient-Hospital Ecosystem
**Date:** 2026-03-21 | **Version:** 1.0

## Vision
Transform MedCare from a patient-only medication tracker into a **doctor-patient-hospital platform** where:
- **Doctors/Hospitals** recommend the app to patients
- **Patients** capture everything — medicines, vitals, wearables, records
- **Doctors** monitor patients remotely, get AI-generated reports, communicate async
- **Smart alerts** flag concerning trends to doctors automatically

## Three Personas

### Patient (iOS App — existing, enhance)
- Track medications, vitals, symptoms, mood, food, activity
- Wearable integration (Apple Watch, HealthKit, Health Connect)
- Share health profile with doctors via QR/link
- Message doctor, schedule appointments
- Emergency medical ID
- Pre-visit preparation reports

### Doctor (iOS App + Web Dashboard)
- Patient panel with traffic-light status (green/yellow/red)
- RPM dashboard — vital trends, adherence, alerts
- Digital prescriptions (NMC-compliant)
- In-app async messaging (bounded, not WhatsApp-style)
- Video/audio consultations
- AI-generated patient summaries
- Appointment management
- Lab result review

### Hospital/Clinic Admin (Web Dashboard)
- Multi-doctor management with role hierarchy
- Patient assignment and transfer
- Revenue analytics, doctor utilization
- ABDM/ABHA compliance management
- Billing with UPI/insurance integration

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                    FRONTEND                          │
├──────────────┬──────────────┬───────────────────────┤
│ Patient App  │ Doctor App   │ Hospital Dashboard    │
│ (iOS Swift)  │ (iOS Swift)  │ (Next.js Web)         │
│ - existing   │ - new        │ - new                 │
└──────┬───────┴──────┬───────┴───────────┬───────────┘
       │              │                   │
       ▼              ▼                   ▼
┌─────────────────────────────────────────────────────┐
│                   BACKEND (API)                      │
│              Node.js / FastAPI + PostgreSQL           │
├─────────────────────────────────────────────────────┤
│ Auth │ Messaging │ Vitals │ Rx │ Appointments │ RPM │
│ ABDM │ Notifications │ Analytics │ Video │ Billing  │
└──────────────────────┬──────────────────────────────┘
                       │
       ┌───────────────┼───────────────┐
       ▼               ▼               ▼
   PostgreSQL      Redis/Queue      S3/Storage
   (primary DB)    (realtime)       (documents)
```

---

## PHASE 1: Backend Foundation (Weeks 1-4)

### 1.1 Core API Setup
- [ ] **BE-001** Project setup — Node.js/Express or FastAPI, TypeScript
- [ ] **BE-002** PostgreSQL schema design — users, profiles, doctors, hospitals, appointments, messages, vitals, prescriptions
- [ ] **BE-003** Authentication — JWT + refresh tokens, OTP for patients (+91), email+password for doctors
- [ ] **BE-004** Role-based access control (RBAC) — Patient, Doctor, Nurse, Admin, SuperAdmin
- [ ] **BE-005** API documentation — OpenAPI/Swagger
- [ ] **BE-006** Error handling, logging, rate limiting middleware
- [ ] **BE-007** File upload service — S3/Cloudflare R2 for documents, images, reports
- [ ] **BE-008** Environment config — dev, staging, production

### 1.2 User Management
- [ ] **BE-009** Patient registration + OTP verification (+91)
- [ ] **BE-010** Doctor registration + medical license verification flow
- [ ] **BE-011** Hospital/clinic registration + admin setup
- [ ] **BE-012** Doctor-patient linking (invite via code/QR/link)
- [ ] **BE-013** Family profile management (patient can manage up to 6 members)
- [ ] **BE-014** ABHA ID integration — create, link, verify health ID
- [ ] **BE-015** Profile sharing with permission levels (viewer/manager) + expiry

### 1.3 Data Models
- [ ] **BE-016** Medications — brand, generic, dosage, frequency, timing, refill tracking
- [ ] **BE-017** Dose logs — scheduled, taken, missed, snoozed with timestamps
- [ ] **BE-018** Vitals — BP, HR, SpO2, weight, temperature, glucose, HbA1c
- [ ] **BE-019** Symptoms — body location, severity, duration, triggers
- [ ] **BE-020** Lab results/Biomarkers — values, ranges, trends, body system panels
- [ ] **BE-021** Medical records — documents, imaging, prescriptions, encounters
- [ ] **BE-022** Appointments — scheduling, status, notes, follow-ups
- [ ] **BE-023** Messages — async threads, read receipts, attachments
- [ ] **BE-024** Prescriptions — digital Rx with NMC compliance fields
- [ ] **BE-025** Achievements/Streaks — gamification state
- [ ] **BE-026** Custom reminders — title, time, repeat, profile-linked
- [ ] **BE-027** Care tasks — follow-ups, lab tests, lifestyle tasks

---

## PHASE 2: Patient App Enhancement (Weeks 2-6)

### 2.1 Vitals Tracking Dashboard
- [ ] **PA-001** Vitals entry UI — BP (systolic/diastolic), heart rate, SpO2, weight, temperature, glucose
- [ ] **PA-002** Manual entry with date/time picker
- [ ] **PA-003** Trend charts per vital (7d, 30d, 90d, 1y)
- [ ] **PA-004** Out-of-range flagging with color indicators
- [ ] **PA-005** Quick-log shortcuts on Home screen
- [ ] **PA-006** Vitals history list with search/filter

### 2.2 Apple HealthKit Integration
- [ ] **PA-007** HealthKit authorization flow — request read permissions
- [ ] **PA-008** Background delivery — auto-import HR, SpO2, steps, sleep, workouts
- [ ] **PA-009** Apple Watch data sync — ECG, temperature, respiratory rate
- [ ] **PA-010** Sync indicators — show last sync time, data freshness
- [ ] **PA-011** HealthKit data display in vitals dashboard
- [ ] **PA-012** Write back to HealthKit — medications, symptoms logged in MedCare

### 2.3 Biomarkers & Lab Results
- [ ] **PA-013** Lab result entry — manual input with body system panels
- [ ] **PA-014** Body system organization (Heart, Kidney, Liver, Metabolic, Blood, Immune, Electrolytes)
- [ ] **PA-015** Historical trend charts per biomarker
- [ ] **PA-016** Out-of-range highlighting with normal ranges
- [ ] **PA-017** Lab report PDF upload + AI extraction
- [ ] **PA-018** Lab report photo capture + OCR parsing
- [ ] **PA-019** Compare latest vs previous results
- [ ] **PA-020** Export lab data (PDF, CSV)

### 2.4 Comprehensive Medical Profile
- [ ] **PA-021** Conditions & injuries — add, track onset/end dates
- [ ] **PA-022** Allergies & intolerances — type, severity, category (drug/food/environment)
- [ ] **PA-023** Vaccination records — name, date, protects against
- [ ] **PA-024** Family medical history (genetics) — condition + affected relatives
- [ ] **PA-025** Care providers directory — doctor name, specialty, contact, notes
- [ ] **PA-026** Insurance information — policy, provider, coverage
- [ ] **PA-027** Lifestyle habits — smoking, alcohol, exercise, diet status
- [ ] **PA-028** Health score — prevention/monitoring/action completeness tracking

### 2.5 Medical Records Vault
- [ ] **PA-029** Records timeline view — chronological with category filtering
- [ ] **PA-030** 11 record categories (vitals, labs, social history, vaccinations, insurance, procedures, medications, conditions, imaging, documents, encounters)
- [ ] **PA-031** Document upload (PDF, photos, DICOM)
- [ ] **PA-032** AI auto-digitization of uploaded documents
- [ ] **PA-033** Search across all records
- [ ] **PA-034** Source filtering (uploaded vs synced vs manual)

### 2.6 Doctor Communication
- [ ] **PA-035** Doctor list — my doctors with online status
- [ ] **PA-036** Async messaging — text + photo + document attachments
- [ ] **PA-037** Message threading per topic/episode
- [ ] **PA-038** Video/audio call request + scheduling
- [ ] **PA-039** Video call UI (WebRTC or Agora SDK)
- [ ] **PA-040** Call history with notes
- [ ] **PA-041** Prescription receipt — view digital Rx from doctor

### 2.7 Appointment Management
- [ ] **PA-042** Book appointment with doctor — date/time picker
- [ ] **PA-043** Appointment types — in-person, video, audio
- [ ] **PA-044** Pre-visit preparation wizard (symptoms, questions, summary)
- [ ] **PA-045** Appointment reminders (1 day, 1 hour before)
- [ ] **PA-046** Check-in flow for in-person visits
- [ ] **PA-047** Post-visit summary + follow-up scheduling

### 2.8 Emergency & Safety
- [ ] **PA-048** Emergency medical ID — QR code with critical info
- [ ] **PA-049** Emergency contacts — quick-dial from lock screen widget
- [ ] **PA-050** Shareable health summary link — with permission levels + expiry
- [ ] **PA-051** Emergency SOS integration (112 India)

### 2.9 Enhanced Daily Tracking
- [ ] **PA-052** Food & water logging — meals, calories estimate, water intake
- [ ] **PA-053** Activity tracking — steps, exercise, sedentary time
- [ ] **PA-054** Sleep tracking — duration, quality (manual + HealthKit)
- [ ] **PA-055** 24-hour timeline visualization (Guava-style)
- [ ] **PA-056** Basic/Advanced tracking mode toggle
- [ ] **PA-057** Customizable tracking focus — choose what to track

### 2.10 AI Correlation Engine
- [ ] **PA-058** Auto-discover correlations between health factors
- [ ] **PA-059** Symptom-medication correlation analysis
- [ ] **PA-060** Lifestyle-health impact analysis (sleep vs mood, exercise vs energy)
- [ ] **PA-061** Weather/environmental trigger correlation
- [ ] **PA-062** Visual correlation cards with percentage changes
- [ ] **PA-063** User-initiated custom correlation queries

### 2.11 Data Sync & Cloud
- [ ] **PA-064** Cloud sync — all local data syncs to backend
- [ ] **PA-065** Offline-first with sync queue — works without internet
- [ ] **PA-066** Conflict resolution for concurrent edits
- [ ] **PA-067** Data export (CSV, PDF)
- [ ] **PA-068** Account data deletion (DPDPA compliance)

---

## PHASE 3: Doctor App (Weeks 4-8)

### 3.1 Doctor Onboarding
- [ ] **DA-001** Registration — name, specialty, medical council registration number
- [ ] **DA-002** License verification flow — upload certificate, admin review
- [ ] **DA-003** Clinic/hospital linking — join existing or create new
- [ ] **DA-004** Profile setup — photo, qualifications, consultation fees, availability

### 3.2 Patient Dashboard
- [ ] **DA-005** Patient list — all linked patients with search/filter
- [ ] **DA-006** Traffic-light status per patient (green=stable, yellow=needs attention, red=urgent)
- [ ] **DA-007** Patient detail view — vitals, medications, symptoms, adherence at a glance
- [ ] **DA-008** Vital trend charts per patient — BP, glucose, weight, HR over time
- [ ] **DA-009** Medication adherence percentage per patient
- [ ] **DA-010** Alert panel — patients with concerning trends
- [ ] **DA-011** Quick filters — by condition, alert status, last visit date

### 3.3 Remote Patient Monitoring (RPM)
- [ ] **DA-012** Set vital thresholds per patient (e.g., BP > 160/100 = alert)
- [ ] **DA-013** Automated alerts when thresholds breached
- [ ] **DA-014** RPM dashboard — real-time vital feeds from wearables
- [ ] **DA-015** Exception report — patients who missed vitals logging
- [ ] **DA-016** Weekly patient panel summary (AI-generated)

### 3.4 Messaging & Communication
- [ ] **DA-017** Patient message inbox — organized by patient
- [ ] **DA-018** Async messaging with response SLA indicator
- [ ] **DA-019** Quick reply templates — "Continue current medication", "Come for check-up"
- [ ] **DA-020** Video/audio call — initiate or accept from patient
- [ ] **DA-021** Consultation notes — attach to patient record after call
- [ ] **DA-022** Boundary settings — available hours, auto-reply for off-hours

### 3.5 Digital Prescriptions
- [ ] **DA-023** E-prescription builder — drug search, dosage, frequency, duration, instructions
- [ ] **DA-024** Indian drug database integration — brand + generic names
- [ ] **DA-025** Drug interaction check before prescribing
- [ ] **DA-026** NMC-compliant Rx format — registration number, digital signature
- [ ] **DA-027** Send Rx to patient — auto-adds to patient's medication list
- [ ] **DA-028** Prescription history per patient
- [ ] **DA-029** Refill authorization flow

### 3.6 Appointment Management
- [ ] **DA-030** Calendar view — daily/weekly schedule
- [ ] **DA-031** Appointment slots configuration — working hours, slot duration, breaks
- [ ] **DA-032** Walk-in queue management (India-specific)
- [ ] **DA-033** Patient check-in notifications
- [ ] **DA-034** Pre-visit patient summary (AI-generated from vitals + adherence since last visit)
- [ ] **DA-035** Post-visit documentation — diagnosis, treatment plan, follow-up

### 3.7 Lab Result Review
- [ ] **DA-036** View patient lab results with trends
- [ ] **DA-037** Flag abnormal results
- [ ] **DA-038** Add doctor notes to lab results
- [ ] **DA-039** Order lab tests — integrate with diagnostic labs (future)

### 3.8 AI-Powered Features
- [ ] **DA-040** AI patient summary — auto-generated report before each visit
- [ ] **DA-041** Treatment effectiveness analysis — adherence + symptom improvement correlation
- [ ] **DA-042** Predictive alerts — "Patient X likely to miss doses next week based on pattern"
- [ ] **DA-043** Clinical decision support — drug interaction warnings, guideline reminders

---

## PHASE 4: Hospital Dashboard (Weeks 6-10)

### 4.1 Admin Setup
- [ ] **HA-001** Hospital/clinic registration — name, address, type, specialties
- [ ] **HA-002** Department management — create departments, assign doctors
- [ ] **HA-003** Role management — Admin, Doctor, Nurse, Receptionist, Billing
- [ ] **HA-004** Doctor invitation and onboarding flow
- [ ] **HA-005** Staff management — add/remove, set permissions

### 4.2 Patient Management
- [ ] **HA-006** Central patient registry — all patients across doctors
- [ ] **HA-007** Patient assignment to doctors
- [ ] **HA-008** Patient transfer between doctors with history
- [ ] **HA-009** Patient search — by name, phone, ABHA ID, condition

### 4.3 Analytics Dashboard
- [ ] **HA-010** Revenue analytics — daily/weekly/monthly, by doctor, by department
- [ ] **HA-011** Patient analytics — new vs returning, condition distribution, age demographics
- [ ] **HA-012** Doctor utilization — appointments per doctor, avg consultation time
- [ ] **HA-013** Adherence analytics — aggregate patient adherence rates
- [ ] **HA-014** No-show rates and follow-up compliance

### 4.4 Billing & Finance
- [ ] **HA-015** Consultation billing — UPI QR, card, cash tracking
- [ ] **HA-016** Insurance TPA integration — Star Health, ICICI Lombard, etc.
- [ ] **HA-017** Ayushman Bharat (PMJAY) claim submission
- [ ] **HA-018** GST-compliant invoice generation
- [ ] **HA-019** Revenue reports and reconciliation

### 4.5 Compliance
- [ ] **HA-020** ABDM integration — Health Facility Registry
- [ ] **HA-021** ABHA ID verification for patients
- [ ] **HA-022** DPDPA compliance — consent management, data retention policies
- [ ] **HA-023** Audit logs — all data access logged
- [ ] **HA-024** Data backup and disaster recovery

---

## PHASE 5: Infrastructure & DevOps (Parallel)

- [ ] **INF-001** Cloud setup — AWS/GCP India region (Mumbai ap-south-1)
- [ ] **INF-002** Database — PostgreSQL RDS with read replicas
- [ ] **INF-003** Redis — for sessions, caching, real-time features
- [ ] **INF-004** Message queue — for async tasks (notifications, reports, AI processing)
- [ ] **INF-005** CDN — CloudFront/Cloudflare for static assets and documents
- [ ] **INF-006** CI/CD pipeline — GitHub Actions for backend + Xcode Cloud for iOS
- [ ] **INF-007** Monitoring — Datadog/Grafana for API health, error rates
- [ ] **INF-008** APNs setup — push notifications for iOS
- [ ] **INF-009** FCM setup — push notifications for Android (future)
- [ ] **INF-010** WebRTC/Agora — video calling infrastructure
- [ ] **INF-011** SSL/TLS — all traffic encrypted
- [ ] **INF-012** WAF — Web Application Firewall for API protection
- [ ] **INF-013** Data encryption at rest — AES-256 for health data
- [ ] **INF-014** HIPAA/DPDPA security assessment

---

## PHASE 6: Growth & Monetization (Weeks 8-12)

- [ ] **GR-001** Subscription tiers — Free / Pro (₹599/yr) / Premium (₹999/yr) for patients
- [ ] **GR-002** Doctor SaaS pricing — Solo (₹2K/mo) / Clinic (₹8K/mo) / Hospital (₹30K/mo)
- [ ] **GR-003** In-app purchase integration (StoreKit 2)
- [ ] **GR-004** Lab test booking — affiliate integration with Healthians/Thyrocare
- [ ] **GR-005** Pharmacy referrals — 1mg/PharmEasy affiliate links
- [ ] **GR-006** Insurance partnership program
- [ ] **GR-007** Referral program — patient invites patient/doctor
- [ ] **GR-008** Corporate wellness program — B2B packaging
- [ ] **GR-009** App Store optimization — screenshots, description, keywords
- [ ] **GR-010** Landing page update for platform positioning

---

## Task Count Summary

| Phase | Area | Tasks |
|-------|------|-------|
| Phase 1 | Backend Foundation | 27 |
| Phase 2 | Patient App Enhancement | 68 |
| Phase 3 | Doctor App | 43 |
| Phase 4 | Hospital Dashboard | 24 |
| Phase 5 | Infrastructure | 14 |
| Phase 6 | Growth & Monetization | 10 |
| **Total** | | **186 tasks** |

---

## MVP Scope (First 4 Weeks — 40 tasks)
Focus on the minimum viable doctor-patient loop:

**Backend:** Auth, patient-doctor linking, vitals storage, messaging, prescriptions (BE-001 to BE-006, BE-009 to BE-012, BE-016 to BE-019, BE-022 to BE-023)

**Patient App:** Vitals dashboard, HealthKit, doctor messaging, appointment booking (PA-001 to PA-008, PA-035 to PA-039, PA-042 to PA-043)

**Doctor App:** Patient dashboard, vital trends, messaging, e-prescriptions, appointments (DA-001 to DA-005, DA-007 to DA-009, DA-017 to DA-018, DA-023 to DA-027, DA-030 to DA-031)

**Infra:** Cloud setup, database, push notifications (INF-001 to INF-003, INF-008)
