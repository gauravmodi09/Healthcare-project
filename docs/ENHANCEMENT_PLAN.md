# MedCare Enhancement Plan
**Date:** 2026-03-19 | **Status:** In Progress

## Executive Summary
MedCare occupies an **uncontested niche** — India has 300M+ people on daily medication with 50-70% non-adherence, yet ZERO purpose-built medication management apps. Pharmacy apps (1mg, PharmEasy, Apollo) treat medicines as products to sell, not regimens to manage. Global apps (Medisafe, CareClinic) have no India relevance.

## Research Findings

### Competitor Analysis (10 apps analyzed)
| App | Best Feature | MedCare Has It? |
|-----|-------------|-----------------|
| Medisafe | Medfriend caregiver alerts + JITI AI prediction | Partial (family profiles, no alerts) |
| CareClinic | Symptom-medication correlation | Service built, not wired |
| MyTherapy | Health journal + doctor printouts | Built, not wired |
| Round Health | Minimal UX + Apple Watch | No Watch app |
| Mango Health | Gamification + real rewards | Achievement service built, not wired |

### India Market Opportunity
- **Diabetes**: 101M patients (world's highest)
- **Hypertension**: 220M+ patients (10% controlled)
- **Thyroid**: 42M patients
- **Total on daily medication**: ~300-350M
- **Non-adherence rate**: 50-70% (vs global ~50%)
- **Digital health market**: $9-11B (2025) → $37B (2030)

### Key India-Specific Needs
1. Multi-generational family medicine management
2. Generic vs brand name confusion (60,000+ brands)
3. Handwritten prescription digitization
4. Jan Aushadhi price comparison (50-90% savings)
5. AYUSH/Ayurvedic medicine support
6. Hinglish UI for elder accessibility

---

## Phase 1: Critical Bug Fixes (This Session)

### CRITICAL
| # | Issue | File | Fix |
|---|-------|------|-----|
| 1 | Edit Profile sheet not wired | ProfileManagementView.swift:143 | Create EditProfileView + wire sheet |
| 2 | Delete Account is no-op | ProfileManagementView.swift:64 | Clear SwiftData + UserDefaults + sign out |

### HIGH — Disconnected Services (Built but Never Called)
| # | Service | Status | Fix |
|---|---------|--------|-----|
| 3 | Notifications never scheduled | DataService.createDoseLogs() | Call scheduleDoseReminder() for future doses |
| 4 | SmartNudgeService.evaluateNudges() | Never called | Call on app foreground in MainTabView |
| 5 | MorningBriefingCard | Built, not in UI | Add to HomeView above nudge banner |
| 6 | MoodCheckInCard | Built, not in UI | Add to HomeView |
| 7 | AchievementService (21 achievements) | Never called | Check on dose events, create view |
| 8 | PredictiveInsightsService | Never called | Integrate into HistoryView |
| 9 | RefillReminderService | Never called | Add stock UI + check on foreground |
| 10 | HealthJournalView | Built, unreachable | Add to HistoryView tabs |
| 11 | Drug interaction check | Not auto-triggered | Check on medicine add |

### MEDIUM — Calculation/Logic Bugs
| # | Issue | Fix |
|---|-------|-----|
| 12 | Adherence % includes future pending doses | Filter to scheduledTime <= Date() |
| 13 | Dose logs only created 7 days ahead | Auto-extend for chronic meds |
| 14 | Snooze doesn't reschedule DoseLog | Reset to pending after snooze period |
| 15 | Symptom log navigation broken in EpisodeDetail | Fix NavigationLink destination |

---

## Phase 2: Feature Enhancements (Next Sessions)

### Tier 1 — Must Have
- [ ] Persistent dose alarms (not just notifications)
- [ ] Caregiver missed-dose alerts (push to family member)
- [ ] Doctor visit report PDF generation
- [ ] Adherence report sharing via WhatsApp
- [ ] Dark mode support

### Tier 2 — India Differentiators
- [ ] Molecule-level medicine tracking (brand-agnostic)
- [ ] Jan Aushadhi generic price comparison
- [ ] Hindi medicine name toggle
- [ ] AYUSH/Ayurvedic medicine category with flexible scheduling
- [ ] WhatsApp sharing for reports and refill alerts

### Tier 3 — Engagement & Growth
- [ ] Gamification with streaks and badges UI
- [ ] Morning briefing push notification
- [ ] Apple Watch complication
- [ ] Pharmacy reorder integration (1mg/PharmEasy affiliate)
- [ ] Voice-activated dose logging

---

## Monetization Strategy (India)

### Free Tier
- Up to 5 medicines, 1 profile
- Basic reminders, 30-day history
- Drug interaction warnings

### Pro (₹79/month or ₹599/year)
- Unlimited medicines, 3 family profiles
- Adherence analytics, prescription scanning
- Refill predictions, doctor reports

### Premium (₹149/month or ₹999/year)
- 6 family profiles, caregiver alerts
- AI health companion (full Medi features)
- Jan Aushadhi price comparison
- Priority support

---

## Success Metrics
- DAU/MAU ratio > 60% (daily engagement)
- Dose reminder response rate > 80%
- 7-day retention > 50%
- Family profile adoption > 40%
- App Store rating > 4.5
