# MedCare Mega Upgrade — Design Spec

> **Date:** 2026-03-19
> **Scope:** Complete UI/UX redesign + Phases 3, 4, 6, 7, 8 + Tech Debt (skip Phase 5 backend)
> **Target:** iOS 17+ SwiftUI, local-only, Indian market

---

## 1. UI/UX Redesign — Design System

### 1.1 Color System Overhaul

**Primary Palette — "Medical Teal"**
| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `primary` | `#0D9488` | `#2DD4BF` | Primary buttons, active states, nav |
| `primaryLight` | `#CCFBF1` | `#134E4A` | Backgrounds, subtle highlights |
| `primaryDark` | `#134E4A` | `#F0FDFA` | Text emphasis |
| `surface` | `#F0FDFA` | `#1E293B` | Card backgrounds |
| `background` | `#FAFAFA` | `#0F172A` | App background (not pure white/black) |

**Accent Palette**
| Token | Color | Usage |
|-------|-------|-------|
| `accent` | `#F97066` (Coral) | Notifications, urgent, missed doses |
| `success` | `#22C55E` (Green) | Taken, completed, positive |
| `warning` | `#F59E0B` (Amber) | Upcoming, caution, low confidence |
| `info` | `#60A5FA` (Blue) | Tips, informational |

**Medication Status Colors**
- Taken on time: Green `#22C55E` + checkmark
- Taken late: Amber `#F59E0B` + clock
- Missed: Coral `#F97066` + X mark
- Upcoming: Teal `#0D9488` + bell
- Skipped: Gray `#94A3B8` + skip icon
- Snoozed: Purple `#A78BFA` + snooze icon

### 1.2 Typography Scale

Use SF Pro (system font) with Dynamic Type support throughout:
| Element | Style | Weight | Usage |
|---------|-------|--------|-------|
| Display | 34pt | Bold | Screen titles |
| Title | 22pt | Bold | Section headers |
| Headline | 17pt | Semibold | Card titles |
| Body | 17pt | Regular | Content text |
| Subhead | 15pt | Regular | Secondary info |
| Caption | 12pt | Regular | Timestamps, labels |
| Metric | 28pt | Bold + monospaced digits | Adherence %, streak count |

### 1.3 Layout — Bento Grid Dashboard

Replace flat list layout with size-hierarchical bento grid:
```
+---------------------------+
|   Next Dose Card (Large)  |  ← Hero card with countdown
|   "Metformin in 2h 15m"  |
+-------------+-------------+
| Streak      | Adherence   |  ← Two medium metric cards
| 🔥 14 days  | ◐ 92%      |  ← Activity ring style
+-------------+-------------+
| AI Tip      | Refill Alert|  ← Two small info cards
+-------------+-------------+
| Active Episodes Section   |  ← Scrollable list below
+---------------------------+
```

### 1.4 Navigation — 5 Tabs (down from 6)

Merge "Today" into "Home" as the hero card. New tab structure:
1. **Home** — Bento dashboard + today's schedule
2. **Meds** — All medications grouped by time-of-day
3. **Health** — Symptoms, vitals, correlations, history
4. **AI** — Chat with health companion
5. **Profile** — Family, settings, subscription

### 1.5 Component Upgrades

**MedicationCard** — Swipeable, expandable
- Swipe right → Mark taken (haptic success)
- Swipe left → Skip/Snooze options
- Tap → Hero expand with `matchedGeometryEffect`
- Status icon + color + text triple-encoding (accessibility)

**ActivityRing** — Apple Watch-style adherence ring
- Animated fill with `.trim(from: 0, to: progress)`
- Percentage in center with `.contentTransition(.numericText())`

**StreakBadge** — Enhanced with flame animation
- Grows from small to large over milestones (7/14/30/60/90/365)
- Grace period: 1 miss per week doesn't break streak

**MeshGradientBackground** — For onboarding, achievements, empty states
- Animated teal/mint/sky gradient using `MeshGradient`

### 1.6 Animations & Haptics

| Action | Animation | Haptic |
|--------|-----------|--------|
| Take pill | Checkmark morph + green flash + confetti at milestones | `.success` |
| Miss reminder | Card pulses red briefly | `.warning` |
| Complete streak milestone | Confetti + ring animation | `.success` + pattern |
| Swipe action | Smooth spring | `.selection` |
| Navigate detail | `matchedGeometryEffect` zoom | `.impact(.light)` |
| Error | Shake animation | `.error` |
| Loading | Shimmer with `.redacted(reason: .placeholder)` | None |

---

## 2. New Features — Phase 3 Completion

### 2.1 Reminder Windows (from Round Health)
Instead of exact reminder times, support "windows" (e.g., "Morning: 7-9 AM").
User picks window; notification fires at window start; persistent until taken or window closes.

### 2.2 Smart Snooze Learning
Track snooze patterns per medication. If user always snoozes 8 AM → takes at 8:30 AM, auto-suggest 8:30 AM.

### 2.3 Meal-Aware Reminders
Integrate meal timing with dose scheduling. "Take after breakfast" adapts to when user typically eats (learned over time).

### 2.4 Buddy System / Caregiver Alerts (from Medisafe Medfriend)
When a dose is missed for >30 min, auto-notify designated family member via local notification (no backend needed — use shared UserDefaults via App Group for family members on same device, or generate shareable text for WhatsApp).

### 2.5 Refill Reminders with Pill Count
Track remaining pill count per medication. Auto-calculate based on doses taken. Alert 5 days before stock runs out.

### 2.6 Medicine Expiry Alerts
Monthly scan of all medicines. Alert 30 days before expiry. Alert on day of expiry. Visual indicator on medicine cards.

### 2.7 Persistent Alarm Mode (for Critical Meds)
For critical medicines (insulin, blood thinners), use critical notification category that bypasses DND.

### 2.8 Missed Dose Guidance
When user marks a dose as missed, show contextual guidance:
- "It's been 2 hours. You can still take it safely."
- "It's been 6+ hours. Skip this dose, take next as scheduled."
- Based on medicine type and timing.

### 2.9 Guided Tour Overlay
First-time user sees tooltip bubbles pointing to key features. Dismissable, shown once.

### 2.10 Lock Screen Widgets
- Small: Next medication name + time
- Circular: Adherence ring percentage

### 2.11 Siri Shortcuts
- "Hey Siri, mark my medicine as taken"
- "Hey Siri, what's my next dose?"
- "Hey Siri, show my adherence"

### 2.12 Control Center Widget (iOS 18+)
Quick "Mark as Taken" toggle for current/next medication.

---

## 3. New Features — Phase 4: Intelligence

### 3.1 Apple Vision OCR for Prescriptions
Replace mock extraction with real `VNRecognizeTextRequest`. Process prescription photos locally on-device. Extract: medicine names, dosages, frequencies, doctor name.

### 3.2 Indian Drug Database
Build a local SQLite database of 500+ common Indian medicines with:
- Brand name → Generic name mapping
- Salt composition
- Common dosages
- Manufacturer
- Typical pricing
- Drug interactions

### 3.3 Fuzzy Medicine Name Matching
When OCR extracts "Augmentin 625 Duo", fuzzy match against drug DB to find correct entry. Use Levenshtein distance + phonetic matching for Indian medicine names.

### 3.4 Generic Substitute Finder (from 1mg)
After medicine is added, show: "Generic alternative: Amoxicillin + Clavulanate (₹45 vs ₹185)". Same salt, lower price. Disclaimer: "Consult your doctor before switching."

### 3.5 Drug Interaction Checker (Real Database)
Expand from 8 hard-coded interactions to 200+ common Indian prescription interactions. Severity levels: Major (red), Moderate (amber), Minor (blue). Source: curated from WHO essential medicines list + Indian pharmacopeia.

### 3.6 Food-Drug Interaction Alerts
"Avoid grapefruit with Atorvastatin", "Take on empty stomach", "Avoid dairy within 2 hours of Ciprofloxacin". Per-medicine food guidance.

### 3.7 Side Effect Tracker
Log side effects per medicine. Track frequency and severity over time. Correlate with medication changes.

### 3.8 Symptom-Medicine Correlation Engine (from CareClinic)
Analyze symptom logs vs medication adherence. Surface insights: "Your headaches decreased 60% since starting Metformin" or "Nausea is most common when you take Augmentin on empty stomach."

### 3.9 Medicine Info Cards
Tap any medicine to see: what it's for, how it works, common side effects, storage instructions, Indian brand alternatives. Sourced from local drug DB.

### 3.10 Body Symptom Mapper (from CareClinic)
Visual body outline. Tap area to log pain/symptom. Track by body region over time. Much more intuitive than text-only symptom logging.

### 3.11 Health Score
Composite metric (0-100) based on: adherence rate (40%), symptom trends (25%), streak consistency (20%), completeness (15%). Shown as a prominent number on home screen.

### 3.12 Weekly Health Summary
Auto-generated weekly report: adherence %, symptoms, trends, AI insights. Shareable as image or PDF.

### 3.13 Injection Site Rotation Tracker (from MyTherapy)
For insulin/injection users: visual body map showing last injection sites. Suggests next site. Tracks rotation pattern.

### 3.14 Tapering/Complex Schedules (from Dosecast)
Support: steroid tapers (decreasing doses over weeks), every-X-hours schedules (not time-of-day), PRN/as-needed medicines with max daily dose limits, alternate day dosing.

---

## 4. New Features — Phase 6: Engagement

### 4.1 Achievement System
Badges earned for milestones:
- "First Week" (7 days), "Monthly Champion" (30), "Century" (100), "Yearly Hero" (365)
- "Family Guardian" (managing family member's meds)
- "Early Bird" (all morning meds on time for a week)
- "Night Owl" (all evening meds on time for a week)
- "Perfect Day" (100% adherence for a day)
- "Comeback King" (resumed after 3+ day gap)

### 4.2 Daily Health Missions
Simple daily goals: "Log your symptoms today", "Check your medication stock", "Review this week's adherence". Completing missions gives small visual rewards.

### 4.3 Progress Animations
- Weekly adherence ring fills up with satisfying animation
- Streak flame grows larger at milestones
- Confetti burst on perfect weeks
- Calendar day turns green with a pop animation when 100% adherence

### 4.4 Medicine Education Cards
Short educational snippets about each medicine: "Did you know? Metformin works by reducing glucose production in the liver." Shown contextually, not as spam.

### 4.5 Streak Grace Period
Allow 1 miss per week without breaking streak. "Recovery day" concept — health apps shouldn't punish sick people.

---

## 5. New Features — Phase 7: Platform

### 5.1 HealthKit Integration
- Read: heart rate, blood pressure, weight, blood glucose, SpO2, sleep
- Write: medication dose events using new `HKMedicationDoseEvent` API
- Show HealthKit vitals alongside symptom logs for correlation

### 5.2 Apple Watch App (WatchKit + SwiftUI)
- Complication: Next dose name + time
- Quick take/skip from wrist
- Haptic reminder on wrist
- Today's adherence ring

### 5.3 Hindi Localization (Primary Indian Language)
- All UI strings in English + Hindi
- Medication names stay in English
- Instructions, labels, buttons in Hindi
- Use `String(localized:)` with `.strings` files

### 5.4 Simplified Elder Mode
Toggle in settings. When enabled:
- 3 tabs only (Home, Meds, Profile)
- Extra large text (22pt body minimum)
- Simplified home: just next dose + take button
- No charts, no gamification, no AI chat
- High contrast colors
- Bigger touch targets (56x56pt minimum)

### 5.5 VoiceOver Accessibility Audit
- Every medication card reads properly
- Charts have `accessibilityChartDescriptor`
- Magic tap (double-two-finger-tap) marks current dose as taken
- All images have alt text
- Rotor actions for common operations

### 5.6 iPad Optimization
- Sidebar navigation on iPad
- Multi-column layout for medication details
- Drag and drop for document management

### 5.7 Lock Screen Widgets
- Small: Next medication name + time
- Circular: Today's adherence %

---

## 6. Phase 8: Growth

### 6.1 Analytics Events
Track key events with local analytics service:
- Onboarding completion rate
- Dose taken/skipped/missed rates
- Feature usage (chat, symptoms, documents)
- Time-to-action from notification to dose log
- Subscription conversion funnel

### 6.2 Crash Reporting
Integrate basic crash logging to local file. Export-friendly for debugging.

### 6.3 Doctor Sharing
Generate a one-time shareable link/code containing:
- Medication list
- Adherence report (last 30 days)
- Symptom trends
- Rendered as a clean PDF

---

## 7. Tech Debt

### 7.1 Unit Tests
- All services: DataService, AuthService, AIChatService, SmartNudgeService
- All models: computed properties, status transitions
- Target: 70% code coverage

### 7.2 UI Tests
- Critical flows: onboarding → add medicine → take dose → view adherence
- Profile management: create, switch, delete
- Episode lifecycle: create → add meds → complete

### 7.3 SwiftLint
- Add SwiftLint via SPM plugin
- Configure rules matching project style
- Fix all warnings

### 7.4 Error Handling Audit
- Ensure all service methods have proper error handling
- User-facing error messages (not raw errors)
- Retry logic for transient failures

### 7.5 Repository Pattern
- Abstract SwiftData access behind repository protocols
- Enable future backend swap without changing ViewModels/Services

---

## 8. Implementation Order

### Wave 1: Design System + Home Redesign (Foundation)
1. New color system (MCColors overhaul)
2. New typography scale
3. New components (ActivityRing, enhanced MedicationCard, BentoGrid)
4. Home screen redesign with bento grid
5. 5-tab navigation (merge Today into Home)
6. Animations & haptics system

### Wave 2: Core Feature Upgrades
7. Reminder windows
8. Refill reminders with pill count
9. Medicine expiry alerts
10. Missed dose guidance
11. Smart snooze learning
12. Caregiver alerts / buddy system
13. Health score

### Wave 3: Intelligence
14. Apple Vision OCR
15. Indian drug database (500+ medicines)
16. Fuzzy medicine matching
17. Drug interaction checker (200+)
18. Generic substitute finder
19. Food-drug interactions
20. Symptom-medicine correlation engine
21. Body symptom mapper
22. Side effect tracker
23. Medicine info cards
24. Tapering/complex schedules

### Wave 4: Engagement + Platform
25. Achievement system & badges
26. Daily health missions
27. Streak grace period
28. Medicine education cards
29. HealthKit integration
30. Hindi localization
31. Elder simplified mode
32. Lock screen widgets
33. Siri shortcuts
34. Weekly health summary
35. Doctor sharing (PDF report)

### Wave 5: Quality
36. Unit tests (70% coverage)
37. UI tests (critical flows)
38. SwiftLint integration
39. Error handling audit
40. VoiceOver accessibility audit
41. Repository pattern refactor

---

**Total new/upgraded items: 41**
**Estimated Swift files to create/modify: 60+**
**Scope: Everything except Phase 5 (backend/cloud)**
