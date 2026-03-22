# Guava Health vs MedCare — Feature Comparison & Gap Analysis

> Scanned from guavahealth.com on 2026-03-21 (logged-in user session + online research)
> Platform: Web, iOS, Android — Available in 14 languages
> Standards: HL7 FHIR, C-CDA, OAuth 2.0, TEFCA, JSON over REST
> HIPAA Compliant — Never sells user data

---

## 1. NAVIGATION & INFORMATION ARCHITECTURE

### Guava Health (6 main tabs)
| Tab | Purpose |
|-----|---------|
| Today | Daily health snapshot — timeline view (12am–11:59pm) with customizable tracking modules |
| Insights | AI-powered correlations between health factors |
| Profile | Comprehensive medical profile with 10 sub-sections |
| Biomarkers | Lab results organized by organ/body system |
| Records | Medical records timeline with category filtering |
| Sources | Data integrations — health systems, devices, apps, file uploads |

### MedCare (Current)
- Home Dashboard with Two-Door CTA
- Episode Management (Plan/Reminders/Symptoms)
- Adherence History
- Family Profiles

**GAP**: MedCare lacks dedicated Biomarkers, Records, Sources, and Insights sections.

---

## 2. DAILY TRACKING ("Today" Tab)

### Guava Health — Trackable Categories

**Basic Mode (6 bundles):**
1. Symptoms
2. Meds & Supplements
3. Cycle & Pregnancy
4. Mood & Energy
5. Blood Pressure
6. Food & Drink

**Advanced Mode (22+ individual trackers):**

| Category | Trackers |
|----------|----------|
| Symptoms & Meds | Med Usage, Symptoms |
| Mood & Energy | Mood, Energy |
| Reproductive Health | Menstrual Cycle / Pregnancy, Sexual Activity |
| Vitals & Measurements | Blood Pressure, Weight, Body Temperature, Heart Rate, Glucose |
| Food & Drink | Caffeine, Food, Water, Alcohol |
| Activity & Events | Bowel Movement, Activity, Urination, Journal |
| Other Types | Blood Oxygen (SpO2), VO2 Max, Peak Flow, Sauna, Grip Strength |

**Key UX Features:**
- 24-hour timeline bar (12am–11:59pm) with visual progress
- Day navigation (prev/next arrows)
- Basic/Advanced toggle for user complexity preference
- Customizable focus selection (choose what to track)

### MedCare (Current)
- Symptom Tracking with daily check-in
- Smart Reminders (Taken/Skip/Snooze)
- Med Usage tracking via reminders

**GAP — Features to Add:**
- [ ] Mood & Energy tracking
- [ ] Vitals tracking (BP, Heart Rate, Weight, Temperature, Glucose, SpO2)
- [ ] Food & Drink logging (Water, Caffeine, Alcohol, Food)
- [ ] Activity tracking
- [ ] Journal / free-text daily notes
- [ ] Menstrual Cycle / Pregnancy tracking
- [ ] Bowel Movement / Urination tracking
- [ ] Customizable tracking focus (Basic/Advanced toggle)
- [ ] 24-hour timeline visualization
- [ ] Day-by-day navigation

---

## 3. AI INSIGHTS & CORRELATIONS

### Guava Health
- **Auto-discovered correlations** between health factors
  - Example: "Anxiety ↓35% with Sertraline"
  - Example: "Mood ↑16% with Yoga"
  - Example: "Headaches ↑19% with Air Pressure"
  - Example: "Deep Sleep ↓4% with Humidity"
  - Example: "Heart Rate ↑8% with Caffeine"
- User can **run their own correlations** or let Guava find them
- Correlates meds, food, activities, weather, and symptoms
- Visual card-based UI with percentage changes

### MedCare (Current)
- Insights Dashboard (basic)
- Adherence History with charts
- Drug Interaction Checker (different purpose)

**GAP — Features to Add:**
- [ ] AI-powered health correlation engine
- [ ] Symptom-to-medication correlation analysis
- [ ] Lifestyle-to-health impact analysis
- [ ] Weather/environmental factor correlation
- [ ] User-initiated custom correlation queries
- [ ] Visual correlation cards with percentage changes

---

## 4. MEDICAL PROFILE

### Guava Health — 10 Profile Sections

| Section | Details |
|---------|---------|
| Basic Info | Name, Birth Date, Sex, Height, Blood Type |
| Biomarkers | Organ-system health scores (Heart, Kidney, Liver, Metabolic, Blood, Immune, Electrolytes) |
| Medications & Supplements | Active meds list, import from providers, "New Med" + "Reminders" buttons |
| Conditions & Injuries | Add Condition, Add Injury, import from providers |
| Allergies & Intolerances | Add Allergy, import via providers or test result upload |
| Vaccinations | Add Vaccination, import from providers |
| Events | Upcoming Appointments, Other Events, Add Appointment |
| Genetics | Family History tracking |
| Care Providers | Provider list, import from patient portals |
| Lifestyle | Lifestyle habits tracking |

**Additional Profile Features:**
- Health Score system (Prevention / Monitoring / Action — completion tracking)
- Insurance information
- Profile sharing (Share Profile button)

### MedCare (Current)
- Profile Setup (basic — name, phone)
- Family Profiles (up to 5 members)
- Episode-based medication management

**GAP — Features to Add:**
- [ ] Comprehensive medical profile (DOB, Sex, Height, Blood Type)
- [ ] Conditions & Injuries tracking
- [ ] Allergies & Intolerances
- [ ] Vaccination records
- [ ] Appointment scheduling / calendar
- [ ] Genetics / Family medical history
- [ ] Care Providers directory
- [ ] Lifestyle habits section
- [ ] Insurance information
- [ ] Health Score / Completeness tracking (Prevention/Monitoring/Action)
- [ ] Profile sharing with doctors/family

---

## 5. BIOMARKERS & LAB RESULTS

### Guava Health — Body System Panels

| Body System | Biomarkers Tracked |
|------------|-------------------|
| Heart Health | Total Cholesterol, HDL, LDL, Triglycerides, Blood Pressure |
| Kidney Function | eGFR, BUN, Creatinine, etc. |
| Liver & Pancreas | AST, ALT, ALP, Bilirubin, Albumin, Amylase, Lipase |
| Metabolic Health | Glucose, Fasting Glucose, HbA1c, etc. |
| Blood | Hemoglobin, Hematocrit, Platelet Count |
| Immune Regulation | WBC Count, C-Reactive Protein, ESR |
| Electrolytes | Sodium, Potassium, Chloride, etc. |

**Key Features:**
- Trends view (historical data over time)
- Reports view
- Charts visualization
- Export functionality (download/share)
- Add Results manually
- Search biomarkers
- "Out of Range" filter toggle
- Body Systems filter dropdown
- Latest Result vs Previous comparison

### MedCare (Current)
- No biomarker/lab result tracking

**GAP — Features to Add:**
- [ ] Lab result entry & storage (manual + import)
- [ ] Body system panel organization
- [ ] Historical trend charts for each biomarker
- [ ] Out-of-range flagging with visual indicators
- [ ] Lab report PDF upload & parsing
- [ ] Export lab data

---

## 6. MEDICAL RECORDS

### Guava Health — Record Categories
| Category | Examples |
|----------|---------|
| Vital Signs | BP, Heart Rate, Temperature readings |
| Lab Tests | Blood work, urine tests |
| Social History | Smoking, alcohol, exercise |
| Vaccinations | COVID, Flu, childhood vaccines |
| Insurance | Plans, coverage details |
| Procedures | Surgeries, biopsies |
| Medications | Prescription history |
| Conditions | Diagnoses |
| Imaging | X-rays, MRIs, CT scans |
| Documents | Doctor notes, referrals |
| Encounters | Office visits, ER visits |

**Key Features:**
- Records timeline (chronological view)
- Source filtering (Uploaded Files, Data Entry)
- Category-based filtering (11 categories)
- Search functionality
- "Prepare for Visit" — doctor visit preparation tool
- Connect Providers (auto-import)
- Upload Records (manual)

### MedCare (Current)
- Prescription photo upload
- Episode-based record keeping

**GAP — Features to Add:**
- [ ] Comprehensive medical records vault
- [ ] Records timeline view
- [ ] Category-based filtering
- [ ] Imaging records storage
- [ ] Procedure history
- [ ] Encounter/visit history
- [ ] "Prepare for Visit" feature
- [ ] Document storage (notes, referrals)

---

## 7. DATA SOURCES & INTEGRATIONS

### Guava Health

**Health Systems (EHR/Patient Portals):**
- Connect to hospital/clinic patient portals
- Auto-import lab tests, meds, doctor notes, conditions, allergies
- Privacy-first (one-way data pull, no sharing back)

**Devices & Apps (17+ direct integrations):**
| Wearables | Health Devices | Fitness Apps |
|-----------|---------------|-------------|
| Fitbit | Omron (BP) | Strava |
| Garmin | Dexcom (CGM) | Google Fit |
| Oura | FreeStyle Libre (CGM) | Apple Health |
| WHOOP | iHealth | Health Connect |
| Polar | Sleep Number | |
| Suunto | | |
| Withings | | |
| Ultrahuman | | |

**Secondary integrations via Apple Health / Health Connect / Google Fit:**
- Apple Watch, Samsung, Flo, Clue, P Tracker, and more

**File Uploads:**
- Manual document/lab result upload

**Data Imports:**
- Bulk data import capability

### MedCare (Current)
- Camera-based prescription capture
- No device/app integrations
- No EHR/patient portal connections

**GAP — Features to Add:**
- [ ] Apple Health / HealthKit integration (critical for iOS)
- [ ] Google Fit / Health Connect integration
- [ ] Wearable device integrations (Fitbit, Garmin, Oura at minimum)
- [ ] CGM device support (Dexcom, FreeStyle Libre) — India relevance
- [ ] BP monitor integration (Omron)
- [ ] Lab report upload with AI extraction
- [ ] Bulk data import

---

## 8. EMERGENCY & SAFETY FEATURES

### Guava Health
- **Emergency Card** — physical wallet card with QR code
  - Medical staff scan for critical info (meds, emergency contacts)
  - Customizable information display
  - $19 standalone or included with Premium
- **Guava Tags** — NFC/QR wearable tags for emergency access
- **Share Profile** — share health data with doctors/family

### MedCare (Current)
- Safety-First Confirmation screen (for med verification)
- Medical disclaimer
- Drug Interaction Checker

**GAP — Features to Add:**
- [ ] Emergency medical ID card (digital, shareable via QR)
- [ ] Emergency contacts with quick-access
- [ ] Shareable health summary for doctors
- [ ] NFC tag support for emergency info

---

## 9. REMINDERS & NOTIFICATIONS

### Guava Health
- Medication reminders
- Notification types: New Records, New Insights, Source Expired, Health Summary
- Configurable in Settings

### MedCare (Current)
- Smart Reminders with Taken/Skip/Snooze
- Actionable notifications
- Smart Scheduling Engine (learns user routine)

**STATUS**: MedCare is **ahead** on smart reminder UX. Guava has more notification types.

**GAP — Features to Add:**
- [ ] Health summary notifications (weekly/monthly)
- [ ] New insights notifications
- [ ] Source expiration alerts
- [ ] Appointment reminders

---

## 10. ACCOUNT & SETTINGS

### Guava Health
- Email/Password management
- 2-Step Verification (2FA)
- Customizable Units (metric/imperial, Fahrenheit/Celsius, mg/dL vs mmol/L)
- Time Format (12h/24h)
- First Day of Week
- Language support (Beta)
- Dark Mode (Auto/On/Off)
- Notifications configuration
- Delete Account
- Referral program ("Refer a friend")

### MedCare (Current)
- Phone-based auth (+91 India)
- Basic profile settings

**GAP — Features to Add:**
- [ ] 2-Factor Authentication
- [ ] Unit customization (metric/imperial)
- [ ] Language selection
- [ ] Dark Mode toggle
- [ ] Notification preferences
- [ ] Referral program
- [ ] Account deletion

---

## 11. BUSINESS & PLATFORM FEATURES

### Guava Health
- **Plans & Pricing** — freemium model with Premium tier
- **For Providers** — Provider Dashboard
- **API / Health Wallet** — developer/B2B API
- **Corporate Wellness** — enterprise offering
- **Ambassador Program** — community growth
- **Community Insights Hub** — crowdsourced health insights
- **Health Resources** — educational content
- **Visit Prep** — pre-appointment preparation tool

### MedCare (Current)
- None of these

**GAP — Features to Consider:**
- [ ] Premium/subscription model
- [ ] Provider-facing dashboard (doctors can view patient data)
- [ ] Health education content section
- [ ] Visit preparation tool (summarize meds, symptoms, questions)
- [ ] Community insights (anonymized aggregate data)

---

## 12. PRIORITY FEATURE RANKING FOR MEDCARE

### Tier 1 — Must-Have (High Impact, Core Parity)
1. **Vitals Tracking** (BP, Heart Rate, Weight, Temperature, Glucose) — daily tracking
2. **Biomarkers/Lab Results** — upload, view, trend analysis
3. **Apple HealthKit Integration** — critical for iOS app
4. **Comprehensive Medical Profile** (conditions, allergies, vaccinations)
5. **AI Health Insights/Correlations** — huge differentiator
6. **Medical Records Vault** — store documents, imaging, encounters

### Tier 2 — Should-Have (Competitive Parity)
7. **Emergency Medical ID** — QR code shareable card
8. **Mood & Energy Tracking** — daily wellness
9. **Food & Water Logging** — lifestyle tracking
10. **Appointment Management** — schedule, reminders
11. **Share Profile with Doctors** — visit prep + sharing
12. **Lab Report Upload with AI Parsing** — extends existing OCR capability

### Tier 3 — Nice-to-Have (Growth & Monetization)
13. **Wearable Integrations** (Fitbit, Garmin, Oura)
14. **Premium Subscription Model** — monetization
15. **Referral Program** — growth
16. **Health Resources / Education** — content
17. **Family Medical History / Genetics**
18. **Provider Dashboard** (B2B)
19. **Corporate Wellness** (B2B)

---

## 13. FEATURES WHERE MEDCARE IS ALREADY AHEAD

| Feature | MedCare Advantage |
|---------|------------------|
| Prescription OCR | Dual-capture (prescription + packaging) with GPT-4V — Guava has no camera-based extraction |
| Indian Medicine Database | Proprietary Indian pharma DB — Guava is US-focused |
| Regional Languages | 22+ Indian scripts with code-mixing — Guava has basic i18n only |
| Smart Scheduling | Learns user routine — Guava has basic reminders |
| Drug Interaction Checker | Real-time interaction alerts — Guava doesn't have this |
| Medicine Expiry Tracker | Expiry date tracking — unique to MedCare |
| Confidence Scoring | AI extraction confidence with HITL gate — safety-first approach |
| Offline-First | NWPathMonitor sync queue — Guava is web-first |
| Family Profiles | Multi-member household management — Guava is single-user |

---

## 14. SUMMARY

| Dimension | Guava | MedCare | Winner |
|-----------|-------|---------|--------|
| Daily Tracking Breadth | 22+ trackers | 3 trackers | Guava |
| AI Insights | Correlation engine | Basic dashboard | Guava |
| Medical Profile Depth | 10 sections | 2 sections | Guava |
| Biomarkers/Lab Results | Full panel tracking | None | Guava |
| Medical Records | 11 categories, timeline | Prescription photos | Guava |
| Device Integrations | 17+ devices | None | Guava |
| Medication Management | Basic | Smart (OCR, interactions, expiry, scheduling) | MedCare |
| India Localization | None | Deep (language, pharma DB, +91) | MedCare |
| Offline Support | None | Full offline-first | MedCare |
| Family Management | Single user | Up to 5 profiles | MedCare |
| Safety Features | Emergency card | HITL gate, interaction checker | Tie |
| Monetization | Premium tier, B2B | None yet | Guava |

---

## 15. ADDITIONAL FEATURES DISCOVERED VIA ONLINE RESEARCH

### 15.1 Guava AI Assistant (Voice + NLP)
- **Natural language queries** — ask questions about your health data
- **Voice logging** — log entries using voice commands
- **AI-powered answers** — get responses about your health patterns
- **GAP for MedCare**: No conversational AI assistant yet

### 15.2 Symptom Body Heat Map
- Visual **body map** showing where symptoms are located
- Tap body icon when logging a symptom to record location
- Heat map aggregation shows symptom frequency by body area
- See which symptoms commonly co-occur
- Severity and frequency visualization
- **GAP for MedCare**: Current symptom tracking has no body location mapping

### 15.3 Advanced Medication Features
- **Pill Supply Tracking** — specify current pill count
- **Refill Alerts** — automated reminder when supply runs low
- **Medication Supply History** — log of refills and adjustments
- **One-tap recurring med check-off** — schedule view with easy marking
- **Medication Schedule View** — see upcoming meds
- **Auto-import prescriptions** from connected patient portals
- **Medisafe data import** — migrate from competitor app
- **GAP for MedCare**: Has reminders but lacks pill count, refill alerts, supply history

### 15.4 Visit Preparation Tool (Detailed)
- Create **custom summaries** of medical history for doctor visits
- Include symptoms, meds, conditions in the summary
- Add **questions** to ask the doctor
- Add **requests** and **assessments** for the appointment
- Shareable format for providers
- **GAP for MedCare**: No visit prep feature

### 15.5 Guava Tags (NFC Hardware)
- **NFC-enabled stickers** you place on physical objects
- Stick on: medication bottles, coffee makers, water bottles, gym equipment
- **Tap phone to log** — tap tag to quickly log health data
- Works with **background NFC** (same as tap-to-pay)
- No Guava Premium required
- **GAP for MedCare**: Innovative hardware companion — consider for future

### 15.6 File Upload & AI Processing
- Upload **CCDA/XML files** from patient portals that don't connect directly
- Upload **DICOM files** (X-rays, MRIs, CT scans) — drag and drop
- Upload **PDFs and images** of medical documents
- **AI digitization** — extracts and organizes data into searchable format
- **GAP for MedCare**: Has prescription OCR but not general medical document AI parsing

### 15.7 Data Export
- Download **.csv file** of all manually logged entries
- Export from Settings
- Useful for complex data analysis or sharing with researchers
- Biomarkers Export (charts + data)
- **GAP for MedCare**: Has PDF adherence export but no CSV data export

### 15.8 Provider Dashboard (B2B — Detailed)
- **Free tool** for providers/coaches
- Invite patients to Guava
- View **consented, shared patient information**
- Consolidates EHR, wearable, lab, and self-reported data
- **Key Metrics overview** — fatigue, sleep, HRV, activity trends
- Spot patterns, identify intervention opportunities
- **Remote Patient Monitoring (RPM)** for concierge & DPC physicians
- Stay connected between visits
- Quick appointment prep
- **GAP for MedCare**: No provider-facing features yet

### 15.9 Community Insights Hub
- **Crowdsourced health correlations** — anonymized aggregate data
- Explore patterns across the user community
- See which symptoms commonly co-occur across population
- Public health insights from aggregated data
- **GAP for MedCare**: No community data features

### 15.10 Interoperability Standards
- **HL7 FHIR** — standard health data format
- **C-CDA** — clinical document architecture
- **OAuth 2.0** — secure authorization
- **TEFCA** — Trusted Exchange Framework
- **JSON over REST** — modern API
- Connected to **50,000+ US providers**
- **SMART on FHIR** app — listed in VA Mobile and SMART App Gallery
- **GAP for MedCare**: Currently no health data interoperability standards

### 15.11 Platform & Localization
- Available on **Web, iOS, Android** — full cross-platform
- **14 languages** supported
- **VA (Veterans Affairs) approved** — listed on VA Mobile
- **HIPAA compliant**
- **GAP for MedCare**: iOS only, 22+ Indian scripts but no international i18n

### 15.12 Reproductive Health (Detailed)
- **Free period tracker** and pregnancy app
- **Period predictions** based on logged data
- **Ovulation predictions**
- **Fertility reminders**
- Cycle-symptom-mood correlation trends
- **GAP for MedCare**: No reproductive health features

### 15.13 Chronic Illness Management Focus
- Specifically positioned for **chronic illness** management
- Designed for conditions like: autoimmune diseases, migraines, IBS, PCOS, diabetes
- Helps evaluate treatment effectiveness over time
- Environmental/weather trigger correlation
- **GAP for MedCare**: Currently focused on medication adherence, not chronic disease management

---

## 16. DEEP-DIVE: PROFILE SECTION (Form-Level Detail)

> Captured by clicking into every form/sub-section in the live webapp

### 16.1 Basic Info Card
| Field | Type | Notes |
|-------|------|-------|
| Name | Text | Editable with pencil icon |
| Birth Date | Date picker | "+ Add Birth Date" |
| Sex | Selector | "+ Add Sex" |
| Height | Number | "+ Add Height" |
| Blood Type | Selector | "+ Add Blood Type" |
| Insurance | Freetext | "+ Add Insurance" |

### 16.2 Preventive Health Score System
A **gamified health completeness score** with 3 categories:

**Prevention Checklist (4 items):**
- Medical checkup (last 2 years)
- Hepatitis C test (once)
- Cholesterol test (last 4 years)
- Glucose test (last 3 years)

**Monitoring Checklist (7 items):**
- Active provider connection
- Blood pressure (last 30 days)
- Weight (last 30 days)
- Resting heart rate (last 3 days)
- Sleep (last 3 days)
- Steps (last 3 days)
- Glucose (last 24 hours)
- Home radon (last 2 years)

**Action Checklist:**
- Sleep 7+ hours daily (last 7 days)
- Take 8,000 steps daily (last 7 days)
- Minimize processed meat
- Keep home radon below 2

**Key details:**
- Score is **personalized by age and sex**
- Factors are dismissible (X button on each)
- Each factor links to detailed info
- Score updates automatically as user adds data
- **"New factors and personal insights will be added over time"**

### 16.3 Add Medication Form
| Field | Type | Required |
|-------|------|----------|
| Medication or Supplement Name | Text (autocomplete) | Yes |
| Dosage & Timing | Freetext ("125 mcg daily with breakfast") | No |
| Photos | Camera/upload | No |
| Start Date | Date picker | No |
| End Date | Date picker | No |
| "I'm no longer taking this" | Checkbox | No |
| Notes | Freetext | No |

### 16.4 Add Condition Form
| Field | Type | Required |
|-------|------|----------|
| Condition | Text (autocomplete, e.g. "Type II Diabetes") | Yes |
| Onset Date | Date picker | No |
| End Date | Date picker | No |
| "I no longer have this condition" | Checkbox | No |
| Notes | Freetext | No |

### 16.5 Add Allergy Form (Most Detailed)
| Field | Type | Options |
|-------|------|---------|
| Substance | Text | Freetext |
| Type | Toggle | **Allergy** / **Intolerance** |
| Life-threatening | Checkbox | "e.g. Anaphylaxis" |
| Estimated Severity | Chip selector | **Low / Moderate / High / Very High** |
| Category | Chip selector | **Drug / Food / Environment-Animal / Other** |
| Notes | Freetext | — |

### 16.6 Add Vaccination Form
| Field | Type | Notes |
|-------|------|-------|
| Vaccination Name | Text (autocomplete) | Placeholder: "DTaP-IPV, Pfizer COVID-19 Vaccine..." |
| Protects Against | Search picker | "Add Vaccine Group..." |
| Date Administered | Date picker | "Set Date" |
| Notes | Freetext | — |

### 16.7 Add Appointment Form
| Field | Type | Notes |
|-------|------|-------|
| Date/Time | Date + Time pickers | Side by side |
| Provider | Search picker | Links to care providers list |
| Title | Text | Optional |
| Location | Text | Optional |
| Tags | Tag input | Optional categorization |
| Notes | Freetext | Optional |
| *Disclaimer* | *Info text* | *"for tracking and preparation purposes only"* |

### 16.8 Add Family History (Genetics) Form
| Field | Type | Options |
|-------|------|---------|
| Condition | Text | Freetext (e.g. diabetes, heart disease) |
| Relatives Affected | Multi-select chips | **Mother / Father / Sibling / Grandparent / Aunt / Uncle / Child / Cousin / Other** |
| Notes | Freetext | — |

### 16.9 New Provider Form
| Field | Type | Required |
|-------|------|----------|
| Name | Text ("Jane Smith, MD") | Yes |
| Specialty | Text | No |
| Phone Number | Phone | No |
| Fax Number | Phone | No |
| Email Address | Email | No |
| Website | URL | No |
| Location | Text | No |
| First Seen Date | Date picker | No |
| "I'm no longer seeing this provider" | Checkbox | No |
| Notes | Freetext | No |

### 16.10 Add Lifestyle Habit Form
| Field | Type | Options |
|-------|------|---------|
| Habit Type | Dropdown | **Drinking Caffeine, Drinking Alcohol, Smoking Tobacco, Other Substance Use, Eating Processed Meat, Sauna, Massage, Meditation, Exercise, Brushing Teeth, Flossing Teeth, Other** |
| Status | Chip selector | **Never / Former / Some Days / Daily** |
| Start Date | Date picker | — |
| End Date (if not current) | Date picker | — |
| Notes | Freetext | — |

---

## 17. DEEP-DIVE: RECORDS SECTION (Feature-Level Detail)

### 17.1 Records Page Layout
- **Search bar** with placeholder "e.g. Blood Test, Cholesterol"
- **Filter icon** (advanced filters)
- **"Prepare for Visit"** CTA button (top-right, green, prominent)
- **Left sidebar filters:**
  - SOURCE: Uploaded Files, Data Entry (checkboxes)
  - CATEGORY: 11 categories with colored icons (checkboxes)
- **Main area**: Timeline view of records (chronological)

### 17.2 Record Categories (11 total)
| # | Category | Icon Color | What It Contains |
|---|----------|-----------|-----------------|
| 1 | Vital Signs | Red | BP, Heart Rate, Temperature readings |
| 2 | Lab Tests | Red/Orange | Blood work, urine tests, panels |
| 3 | Social History | Blue | Smoking, alcohol, exercise habits |
| 4 | Vaccinations | Yellow | COVID, Flu, childhood vaccines |
| 5 | Insurance | Green | Plans, coverage details |
| 6 | Procedures | Pink | Surgeries, biopsies, procedures |
| 7 | Medications | Blue | Prescription history |
| 8 | Conditions | Orange | Diagnoses, chronic conditions |
| 9 | Imaging | Teal | X-rays, MRIs, CT scans (DICOM) |
| 10 | Documents | Green | Doctor notes, referrals, letters |
| 11 | Encounters | Purple | Office visits, ER visits, telehealth |

### 17.3 Upload Records Flow
**Supported file types:**
| Format | Description | Use Case |
|--------|-------------|----------|
| PDF | Labs, Visit Notes, any document | Most common upload |
| Photos/Images/Videos | Document photos, wound photos | Mobile capture |
| DICOM | X-rays, MRIs, CT scans | Imaging from CDs |
| CCDA (XML) | Clinical Document Architecture | EHR exports |

**Upload UX:**
- Drag & drop zone with visual indicator
- "Select a file to upload" text
- AI auto-digitization — extracts values (e.g. "LDL Cholesterol 147 mg/dL — Borderline High")
- Uploaded docs can be **edited** (pencil icon): change date, name, add notes, correct results

### 17.4 Radiology / Imaging Records
- Auto-detects X-rays, MRIs, and DICOM files on upload
- **View** radiology images across multiple devices
- **Download** imaging files
- **Share** with providers
- Eliminates need for CDs and physical media
- "In your pocket, wherever you go"

### 17.5 Visit Preparation Tool (Detailed Flow)

**Step 1 — Choose Visit Type (6 templates):**
| Template | Purpose |
|----------|---------|
| New Symptoms | Reporting new health issues to doctor |
| Annual Visit | Routine checkup preparation |
| Follow-up Visit | Continuing care from previous visit |
| New Specialist | First visit with a specialist |
| Other | Custom visit type |
| Auto Prep | AI automatically generates the summary |

**Step 2 — Add Symptoms (for New Symptoms type):**
- Searchable symptom picker
- Guidance: "Providers recommend selecting no more than 3 symptoms"
- Auto-syncs from tracked symptoms

**Step 3 — Compile Summary:**
- Auto-pulls medications, conditions, allergies from profile
- Add custom questions for the doctor
- Add requests and assessments

**Step 4 — Share/Export:**
- **Download** summary as document
- **Send** via email to provider
- **Print** for in-person visits
- Follow-up visit carry-over (picks up from previous visit)

**Key UX:** Save/Finish buttons, multi-step wizard, "Not saved yet" state

### 17.6 Share Profile Feature (Detailed)

**Sharing Methods:**
- **Send email** — enter recipient email
- **Copy link** — shareable URL

**Permission Levels:**
| Role | Access |
|------|--------|
| Manager | Full access, can edit profile |
| Viewer | Can see entire profile except some data types |

**Expiration Options:**
| Option | Duration |
|--------|----------|
| No Expiration | Permanent access |
| 1 Hour | Quick share for appointment |
| 4 Hours | Extended appointment |
| 24 Hours | Day-long access |
| 7 Days | Week-long access |

**Security Methods:**
| Method | How It Works |
|--------|-------------|
| Birth Date | Recipient must enter patient's birth date |
| 6-Digit Code | System generates code (e.g. 771199), recipient must enter it |
| None | No verification required |

**Granular Permissions:**
- "+ Permissions for extra types" — choose exactly which data types to share
- Access management list showing all people with access and their roles

---

## 18. REVISED PRIORITY FEATURES FOR MEDCARE (Post-Deep-Dive)

> Updated with Profile & Records deep-dive intelligence

### Tier 1 — Critical (Immediate Competitive Parity)
| # | Feature | Impact | Effort |
|---|---------|--------|--------|
| 1 | **Vitals Tracking Dashboard** (BP, HR, Weight, Temp, Glucose, SpO2) | High | Medium |
| 2 | **Apple HealthKit Integration** | High | Medium |
| 3 | **AI Health Insights/Correlation Engine** | Very High | High |
| 4 | **Comprehensive Medical Profile** (conditions, allergies, vaccines, blood type) | High | Medium |
| 5 | **Lab Results / Biomarkers** (upload, view trends, out-of-range flagging) | High | High |
| 6 | **Medical Document Upload + AI Parsing** (extends existing OCR) | High | Medium |

### Tier 2 — Important (User Retention & Engagement)
| # | Feature | Impact | Effort |
|---|---------|--------|--------|
| 7 | **Visit Preparation Tool** (summarize health for doctor visits) | High | Low |
| 8 | **Symptom Body Heat Map** | Medium | Medium |
| 9 | **Mood & Energy Tracking** | Medium | Low |
| 10 | **Pill Supply + Refill Alerts** | Medium | Low |
| 11 | **Emergency Medical ID** (QR code card) | Medium | Low |
| 12 | **Food, Water & Lifestyle Logging** | Medium | Medium |
| 13 | **Appointment Calendar** | Medium | Medium |
| 14 | **AI Health Assistant** (voice + NLP queries) | Very High | High |

### Tier 3 — Growth & Monetization
| # | Feature | Impact | Effort |
|---|---------|--------|--------|
| 15 | **Premium Subscription Model** | High (revenue) | Medium |
| 16 | **Provider Dashboard** (B2B) | High (revenue) | High |
| 17 | **Data Export** (CSV download) | Low | Low |
| 18 | **Wearable Integrations** (Fitbit, Garmin, Oura) | Medium | High |
| 19 | **Referral Program** | Medium (growth) | Low |
| 20 | **Community Insights Hub** | Medium | High |
| 21 | **NFC Tags** for quick logging | Low | High |
| 22 | **Reproductive Health** (period/fertility tracking) | Medium | Medium |
| 23 | **Health Resources / Education Content** | Low | Low |

---

## 19. SOURCES

- [Guava Health App - App Store](https://apps.apple.com/us/app/guava-health-tracker/id1622255863)
- [Guava Health App - Google Play](https://play.google.com/store/apps/details?id=com.guavahealth.app&hl=en_US)
- [Guava Health Official Site](https://guavahealth.com/)
- [Guava Tags](https://guavahealth.com/guava-tags)
- [Guava API](https://guavahealth.com/api)
- [Provider Dashboard FAQ](https://guavahealth.com/provider-dashboard-faq)
- [The Ultimate Guide to Using Guava](https://guavahealth.com/article/guava-ultimate-guide)
- [Guava Health - VA Mobile](https://mobile.va.gov/app/guava-health-tracker)
- [Guava Health - SMART App Gallery](https://apps.smarthealthit.org/app/guava)
- [Plans & Pricing](https://guavahealth.com/plans)
- [Supported Apps & Health Systems](https://guavahealth.com/supported-apps)
- [Getting Your Records into Guava](https://guavahealth.com/article/getting-your-records-into-guava)
- [Medication Tracker App for Real Life](https://guavahealth.com/article/medication-tracker-app-for-real-life)
- [Key Metrics in the Provider Dashboard](https://guavahealth.com/article/key-metrics-in-provider-dashboard)
- [Manage Your Radiology Images](https://guavahealth.com/radiology-records)
- [Guava Health Sharing](https://guavahealth.com/sharing)
- [Visit Prep](https://guavahealth.com/visit-prep)
