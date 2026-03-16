# MedCare Product Plan & Roadmap

> Last Updated: March 16, 2026
> Platform: iOS (SwiftUI + SwiftData) | Target: iOS 17+

---

## Current State Assessment

### What's Built & Working
| Feature | Status | Quality |
|---------|--------|---------|
| Phone OTP Login | Working | Mock OTP (any 6 digits) |
| Home Dashboard | Working | Rich cards, dose summary, episodes |
| Dose Reminders | Working | Local push + Dynamic Island |
| AI Health Chat | Working | Groq LLM + mock fallback |
| Episode Management | Working | 4-tab detail view |
| Symptom Logging | Working | Feeling + severity + vitals |
| Document Management | Working | Upload, view, organize by type |
| Family Profiles | Working | Up to 5 members with demographics |
| History & Analytics | Working | Charts, time ranges, PDF export |
| Smart Nudges | Working | Missed dose, adherence, course end |
| Design System | Working | Colors, typography, components |
| Live Activities | Working | Dynamic Island for dose reminders |

### What's Placeholder / Skeleton
| Feature | Status | What's Missing |
|---------|--------|----------------|
| Prescription Extraction | Mock | Real OCR/Vision API |
| Consult Doctor | Disabled | Telehealth integration |
| Drug Interactions | Skeleton | Real drug database |
| Medicine Expiry | Skeleton | Barcode scanning, alerts |
| Offline Sync | Skeleton | Backend API needed |
| Regional Languages | Skeleton | Translation layer |
| Smart Scheduling | Skeleton | ML model for routine learning |
| Analytics Service | Skeleton | Event tracking pipeline |

---

## Phase 3: Core Experience Polish (2-3 weeks)

### 3.1 Onboarding & First-Time Experience
- [ ] **Welcome carousel** (3 slides: Track Medicines, AI Health Chat, Family Care)
- [ ] **Guided tour overlay** on first Home Dashboard visit (highlight key areas)
- [ ] **Quick-add flow** for users with no prescriptions yet (manually add a medicine in 30 seconds)
- [ ] **Permission primer screens** before requesting notifications, camera, health permissions
- [ ] **Skip-to-demo mode** letting users explore with demo data before signing up

### 3.2 AI Chat Improvements
- [ ] **Conversation memory** - persist chat history across sessions (currently clears)
- [ ] **Multi-turn context** - AI remembers what you discussed 5 messages ago
- [ ] **Structured health responses** with sections (Cause, What to Do, When to See Doctor)
- [ ] **Medicine-aware responses** - when user asks about a side effect, check against their active medicines
- [ ] **Proactive health tips** - AI initiates conversation based on time of day ("Good morning! Time for your Thyronorm")
- [ ] **Voice input** - speech-to-text using iOS Speech framework for hands-free chat
- [ ] **Quick reply chips** - suggested follow-up questions after each AI response
- [ ] **Share chat** - export conversation as PDF for showing to doctor
- [ ] **Multilingual chat** - Hindi + English code-mixing support in AI responses
- [ ] **Image analysis in chat** - send a photo of a rash/wound and get AI assessment

### 3.3 Reminder Experience Enhancement
- [ ] **Smart snooze** - learn preferred snooze duration per user (5/10/15/30 min)
- [ ] **Meal-aware reminders** - "Take after breakfast" adapts to user's actual meal times
- [ ] **Location-based reminders** - remind when user arrives home (for medicines kept at home)
- [ ] **Buddy system** - notify a family member if dose is missed for 2+ hours
- [ ] **Streak tracking** - "You've taken medicines on time for 7 days!" celebrations
- [ ] **Visual dose calendar** - monthly view with color-coded adherence (green/yellow/red)
- [ ] **Dose rescheduling** - drag a missed dose to a new time instead of just skip
- [ ] **Refill reminders** - alert 5 days before medicine stock runs out
- [ ] **Critical dose warnings** - extra aggressive alerts for blood thinners, insulin, etc.

### 3.4 Dynamic Island & Notifications Polish
- [ ] **Expanded Dynamic Island** - show next 2-3 upcoming doses, not just one
- [ ] **Progress ring** on Dynamic Island showing daily adherence %
- [ ] **Haptic feedback** on Dynamic Island interactions
- [ ] **Rich notifications** with medicine image thumbnail
- [ ] **Notification grouping** - batch multiple due doses into single notification
- [ ] **Siri Shortcuts** - "Hey Siri, mark my morning medicines as taken"
- [ ] **Apple Watch complication** - glanceable next dose on watch face

---

## Phase 4: Intelligence Layer (3-4 weeks)

### 4.1 Real Prescription Extraction (OCR)
- [ ] **Integrate Apple Vision framework** for on-device text extraction
- [ ] **Medicine name fuzzy matching** against Indian drug database (1mg/PharmEasy data)
- [ ] **Handwriting recognition** for handwritten prescriptions (common in India)
- [ ] **Multi-page prescription support** - stitch multiple photos into one prescription
- [ ] **Auto-detect prescription vs lab report vs bill** from photo
- [ ] **Confidence-based review flow** - only ask user to verify low-confidence fields (<70%)
- [ ] **Prescription history** - show all uploaded prescriptions with extracted data
- [ ] **Doctor info extraction** - auto-fill doctor name, hospital, registration number
- [ ] **Smart medicine matching** - suggest existing medicine if duplicate detected

### 4.2 Drug Intelligence
- [ ] **Drug interaction checker** using real database (DrugBank/OpenFDA)
- [ ] **Food interaction alerts** (e.g., "Don't take Ciprofloxacin with milk")
- [ ] **Duplicate therapy detection** - flag if two medicines serve same purpose
- [ ] **Side effect tracker** - correlate logged symptoms with medicine side effects
- [ ] **Medicine info cards** - tap any medicine to see uses, side effects, alternatives
- [ ] **Generic alternative suggestions** - show cheaper generic options
- [ ] **Pregnancy/lactation warnings** - flag unsafe medicines for relevant profiles

### 4.3 Health Insights & Predictions
- [ ] **Adherence prediction** - ML model predicting likelihood of missed dose (notify preemptively)
- [ ] **Symptom trend analysis** - "Your headaches are getting less frequent over 2 weeks"
- [ ] **Recovery trajectory** - visual progress curve compared to typical recovery
- [ ] **Health score** - composite score from adherence + symptoms + vitals (0-100)
- [ ] **Weekly health summary** - automated report every Sunday
- [ ] **Anomaly detection** - flag unusual patterns (sudden weight change, BP spike)
- [ ] **Correlation engine** - "You report nausea on days you take Medicine X with empty stomach"

---

## Phase 5: Connected Care (4-6 weeks)

### 5.1 Backend & Cloud Sync
- [ ] **Design REST API** (FastAPI/Node.js) with authentication
- [ ] **Cloud database** (PostgreSQL/Supabase) for user data sync
- [ ] **Real-time sync** across multiple devices (iCloud or custom WebSocket)
- [ ] **Offline-first architecture** - full functionality without internet, sync when available
- [ ] **Data encryption** at rest and in transit (AES-256, TLS 1.3)
- [ ] **HIPAA-compliant storage** for medical data
- [ ] **Backup & restore** - export all data as encrypted file
- [ ] **Account deletion** - complete data wipe per GDPR/IT Act requirements

### 5.2 Family Care Features
- [ ] **Caregiver dashboard** - one screen to see all family members' adherence
- [ ] **Role-based access** - caregiver vs self-manager permissions
- [ ] **Shared medicine cabinet** - family members can see each other's medicines
- [ ] **Caregiver alerts** - push notification to caregiver on missed dose
- [ ] **Elder care mode** - large text, simplified UI, limited navigation
- [ ] **Child care mode** - gamified with rewards and fun animations
- [ ] **Emergency info card** - shareable card with medicines, allergies, blood group, emergency contacts

### 5.3 Doctor Connection
- [ ] **Doctor profile linking** - save doctor details with contact info
- [ ] **Appointment reminders** - track follow-up dates from prescriptions
- [ ] **Treatment summary export** - one-tap report for doctor visit (adherence, symptoms, vitals)
- [ ] **Teleconsult integration** - video call via Practo/1mg API
- [ ] **Prescription request** - message doctor for refill
- [ ] **Lab report sharing** - send reports directly to doctor via WhatsApp/email

### 5.4 Pharmacy Integration
- [ ] **Medicine ordering** - order refills from 1mg/PharmEasy/Netmeds
- [ ] **Price comparison** - compare medicine prices across pharmacies
- [ ] **Auto-refill** - schedule recurring medicine orders
- [ ] **Nearby pharmacy finder** - MapKit integration for local stores
- [ ] **Medicine availability check** - is your medicine in stock?
- [ ] **Delivery tracking** - track medicine order status

---

## Phase 6: Engagement & Retention (2-3 weeks)

### 6.1 Gamification
- [ ] **Adherence streaks** with visual flame/trophy badges
- [ ] **Daily health missions** ("Log your symptoms today", "Take all doses on time")
- [ ] **Achievement system** (First Week Champion, Month of Consistency, Family Health Hero)
- [ ] **Progress animations** - satisfying animations when marking dose as taken
- [ ] **Weekly challenges** - "Can you hit 100% adherence this week?"
- [ ] **Health coins** - earn virtual currency for adherence, redeem for pharmacy discounts

### 6.2 Content & Education
- [ ] **Medicine education cards** - "Did you know?" facts about your medicines
- [ ] **Health articles** - curated content based on user's conditions
- [ ] **Video guides** - "How to use an inhaler correctly"
- [ ] **Condition-specific tips** - diabetes management, post-surgery care, etc.
- [ ] **Seasonal health alerts** - dengue season, flu season, pollution alerts
- [ ] **Nutrition tips** - food suggestions based on medicines (iron-rich foods with iron supplements)

### 6.3 Social & Community
- [ ] **Anonymous health community** - ask questions, share experiences
- [ ] **Condition groups** - diabetes support, CABG recovery group
- [ ] **Expert Q&A sessions** - weekly live sessions with doctors
- [ ] **Success stories** - user recovery journey sharing

---

## Phase 7: Platform Expansion (6-8 weeks)

### 7.1 Apple Ecosystem
- [ ] **Apple Watch app** - dose reminders, quick take/skip, vitals logging
- [ ] **iPad app** - optimized layout with sidebar navigation
- [ ] **macOS app** (Catalyst) - manage family health from Mac
- [ ] **HealthKit integration** - sync vitals (heart rate, steps, sleep) from Apple Health
- [ ] **Apple Home integration** - flash smart lights for medicine reminders

### 7.2 Widget Suite
- [ ] **Home screen widget** (small) - next upcoming dose
- [ ] **Home screen widget** (medium) - today's dose summary with adherence %
- [ ] **Home screen widget** (large) - full day dose schedule
- [ ] **Lock screen widget** - next dose countdown
- [ ] **StandBy mode widget** - bedside medicine reminder
- [ ] **Interactive widgets** - mark dose as taken directly from widget (iOS 17+)

### 7.3 Accessibility
- [ ] **VoiceOver optimization** - full screen reader support
- [ ] **Dynamic Type** - support all text size settings
- [ ] **High contrast mode** - WCAG AAA compliance
- [ ] **Reduce motion** - respect accessibility settings
- [ ] **RTL language support** - Urdu, Arabic
- [ ] **Color blind mode** - alternative color coding for adherence

### 7.4 Localization
- [ ] **Hindi** - full app translation
- [ ] **Tamil, Telugu, Bengali, Marathi** - top Indian languages
- [ ] **Medicine names in regional scripts** - Devanagari, Tamil script
- [ ] **Voice input in regional languages** - speech-to-text for chat

---

## Phase 8: Monetization & Growth (Ongoing)

### 8.1 Revenue Model
- [ ] **Freemium tiers** already modeled (Free/Pro/Premium)
  - Free: 1 profile, 5 medicines, basic reminders, mock AI chat
  - Pro (149/mo): 3 profiles, unlimited medicines, AI chat, prescription extraction
  - Premium (299/mo): 5 profiles, all features, priority support, family dashboard
- [ ] **Pharmacy affiliate revenue** - commission on medicine orders
- [ ] **Teleconsult booking fees** - commission on doctor consultations
- [ ] **Health insurance partnerships** - discounted premiums for adherent users
- [ ] **Enterprise/Hospital plan** - white-label for hospital patient management

### 8.2 Growth Channels
- [ ] **Doctor referral program** - doctors recommend app to patients
- [ ] **Pharmacy counter QR codes** - scan to add prescription
- [ ] **WhatsApp bot** - dose reminders via WhatsApp for non-app users
- [ ] **ASO (App Store Optimization)** - keywords, screenshots, preview video
- [ ] **Content marketing** - health blog for SEO
- [ ] **Referral rewards** - invite family, earn Pro trial

### 8.3 Analytics & Metrics
- [ ] **DAU/MAU tracking** - daily/monthly active users
- [ ] **Retention cohorts** - D1, D7, D30 retention
- [ ] **Feature usage heatmap** - which features drive engagement
- [ ] **Funnel analysis** - onboarding completion, prescription upload rate
- [ ] **Adherence metrics** - aggregate anonymized adherence data
- [ ] **NPS surveys** - in-app satisfaction measurement

---

## Immediate Priority Tasks (This Week)

### P0 - Critical (Do First)
1. [ ] **Fix device signing** - get app running on physical iPhone
2. [ ] **Test Groq AI chat** on device - verify streaming works over cellular
3. [ ] **Test Dynamic Island** on physical device - verify Live Activities appear
4. [ ] **Test notifications** on device - verify dose reminders fire correctly

### P1 - High Priority (This Sprint)
5. [ ] **Persist chat history** - save conversations to SwiftData
6. [ ] **Add voice input** to AI chat - iOS Speech framework
7. [ ] **Streak tracking UI** - show consecutive days on Home screen
8. [ ] **Refill reminder logic** - alert based on remaining pill count
9. [ ] **Quick reply chips** in AI chat after each response
10. [ ] **Home screen widget** - next dose widget (small + medium)

### P2 - Medium Priority (Next Sprint)
11. [ ] **Real OCR extraction** - Apple Vision framework for prescriptions
12. [ ] **Medicine info cards** - tap medicine to see details, side effects
13. [ ] **Weekly health summary** - automated Sunday report
14. [ ] **Caregiver alerts** - notify family on missed doses
15. [ ] **Appointment tracking** - save follow-up dates from prescriptions

### P3 - Nice to Have (Backlog)
16. [ ] **Apple Watch app** - basic dose reminders
17. [ ] **Backend API** - cloud sync infrastructure
18. [ ] **Pharmacy ordering** - 1mg/PharmEasy integration
19. [ ] **Gamification system** - streaks, achievements, health coins
20. [ ] **Community features** - anonymous health Q&A

---

## Technical Debt & Quality

### Code Quality
- [ ] **Unit tests** - target 70% coverage for Services layer
- [ ] **UI tests** - critical flows (login, add medicine, take dose)
- [ ] **SwiftLint** integration for code style consistency
- [ ] **Error handling audit** - ensure all network calls have proper error states
- [ ] **Memory leak audit** - profile with Instruments
- [ ] **Accessibility audit** - VoiceOver pass on all screens

### Architecture
- [ ] **Dependency injection** - replace singletons with proper DI container
- [ ] **Repository pattern** - abstract SwiftData behind repository interfaces
- [ ] **Network layer** - proper API client with retry, caching, auth token refresh
- [ ] **Feature flags** - remote config for A/B testing and gradual rollout
- [ ] **Crash reporting** - Firebase Crashlytics or Sentry integration
- [ ] **Logging framework** - structured logging for debugging

### Performance
- [ ] **Lazy loading** - don't fetch all episodes on Home screen
- [ ] **Image caching** - document thumbnails should cache
- [ ] **Background refresh** - update dose statuses in background
- [ ] **App size optimization** - strip unused assets, compile size report
- [ ] **Cold start time** - target < 2 seconds to interactive

---

## Success Metrics

| Metric | Target | How to Measure |
|--------|--------|----------------|
| Onboarding completion | >80% | Users who add first medicine |
| D7 retention | >40% | Users returning after 7 days |
| D30 retention | >25% | Users returning after 30 days |
| Daily adherence rate | >85% | Doses taken / doses scheduled |
| AI chat engagement | >3 msgs/session | Average messages per chat session |
| Prescription upload rate | >50% | Users who upload at least 1 prescription |
| Family profile creation | >30% | Users who add a 2nd profile |
| NPS score | >50 | In-app survey |
| App Store rating | >4.5 | App Store reviews |
| Crash-free rate | >99.5% | Crashlytics |

---

## Competitive Landscape

| Competitor | Strength | Our Differentiation |
|------------|----------|---------------------|
| Practo | Doctor network | AI-first, family care |
| 1mg | Pharmacy & delivery | Medicine tracking, adherence |
| MyTherapy | Global med tracker | India-focused, regional languages |
| Medisafe | Reminders & adherence | AI chat, prescription OCR, Dynamic Island |
| HealthifyMe | Health & nutrition | Medicine-centric, post-discharge care |

**Our Unique Moats:**
1. AI-powered prescription extraction (Indian handwriting)
2. Family health management (Indian joint family model)
3. Regional language AI (Hindi, Tamil, code-mixing)
4. Dynamic Island dose experience (premium feel)
5. Post-discharge care tracking (hospital → home transition)

---

*This is a living document. Update as features ship and priorities shift.*
