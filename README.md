# MedCare — Smart Health Companion for India

<div align="center">

**Turn any prescription into a structured, trackable care plan — powered by AI.**

Built for Indian patients and families managing daily medications, chronic conditions, and post-hospital recovery.

[![Status](https://img.shields.io/badge/Status-Active%20Development-brightgreen)]()
[![Platform](https://img.shields.io/badge/Platform-iOS%2018%2B%20(SwiftUI)-blue)]()
[![AI](https://img.shields.io/badge/AI-Groq%20Llama%203.3%2070B-purple)]()
[![License](https://img.shields.io/badge/License-Proprietary-red)]()

</div>

---

## What is MedCare?

MedCare is a mobile health companion designed for the Indian market. It converts physical prescriptions and medicine packaging photos into structured care plans with smart reminders, adherence tracking, and an AI health companion.

**The dual-capture approach:** Since Indian doctor handwriting is notoriously hard to OCR, MedCare asks users to photograph both the prescription (for context) and the medicine box/strip (for reliable data extraction from CDSCO-mandated printed text).

---

## Features

### Core (Implemented)
- **AI Prescription Scanner** — Snap a photo of prescription + medicine box, get a structured care plan
- **Smart Reminders** — Push notifications with Dynamic Island countdown, Take/Skip/Snooze actions
- **Family Profiles** — Manage medications for parents, children, and self from one account
- **AI Health Companion** — Context-aware chat powered by Groq (Llama 3.3 70B), supports Hinglish
- **Emergency Detection** — Auto-detects crisis keywords and surfaces 112 emergency calling
- **Smart Nudges** — Behavioral nudges for missed doses, low adherence, course endings
- **Document Management** — Store prescriptions, lab reports, bills, insurance docs per episode
- **Symptom Tracking** — Log daily symptoms with severity, track recovery over time

### Phase 3: Polish (Recently Implemented)
- **Dark Mode** — Full adaptive color system (light/dark) across all screens
- **Dose Format Types** — Tablet, capsule, syrup, injection, drops, cream, inhaler, patch
- **Meal Timing Labels** — Before/after/with meal, empty stomach indicators on dose cards
- **Overdose Prevention** — Duplicate dose alert if same medicine taken within 2-hour window
- **Today View** — Consolidated daily schedule with timeline, progress ring, all doses + tasks
- **Dose Confirmation Animation** — Haptic feedback + animated checkmark overlay on dose taken
- **AI Chat Quick Reply Chips** — Tappable suggestions: medicines, progress, side effects, diet
- **Adherence Streak Tracking** — Consecutive-day streaks with flame icon on episode cards
- **Welcome Onboarding** — 4-page carousel for first-time users
- **Chat History Persistence** — Conversations persist across app sessions via SwiftData

### Planned
- **WhatsApp Reminders** — Dose alerts via WhatsApp (critical for India market)
- **ABHA Health ID** — Integration with India's national health records
- **UPI Payments** — Medicine refill and teleconsult payments
- **Apple Watch App** — Glanceable dose reminders on wrist
- **Home Screen Widgets** — Today's schedule at a glance
- **Gamification** — Adherence streaks, points, family competitions

> Full backlog of 100+ tasks tracked in [`tracker/`](tracker/) — a Kanban board built for planning between developer and AI.

---

## Architecture

```
┌─────────────────────────────────────────┐
│           iOS App (SwiftUI)             │
│                                         │
│  ┌──────────┐  ┌──────────┐  ┌───────┐ │
│  │  Views   │  │ Services │  │Models │ │
│  │ (MVVM)   │  │(@Observable)│ │(SwiftData)│
│  └──────────┘  └──────────┘  └───────┘ │
│                                         │
│  ┌──────────┐  ┌──────────┐  ┌───────┐ │
│  │Live      │  │Notif     │  │LLM    │ │
│  │Activity  │  │Service   │  │Service │ │
│  │(Dynamic  │  │(UNNotif) │  │(Groq) │ │
│  │ Island)  │  │          │  │       │ │
│  └──────────┘  └──────────┘  └───────┘ │
└─────────────────────────────────────────┘
         │                    │
    SwiftData             Groq API
    (SQLite)          (Llama 3.3 70B)
```

**Single-device, offline-first.** All data stored locally via SwiftData. AI chat requires network for Groq API, with mock fallback responses when offline.

---

## Tech Stack

| Layer | Technology |
|---|---|
| **UI Framework** | SwiftUI · iOS 18+ |
| **Data Persistence** | SwiftData (SQLite) |
| **AI Chat** | Groq API · Llama 3.3 70B · Streaming responses |
| **Notifications** | UNUserNotificationCenter · Actionable notifications |
| **Live Activities** | ActivityKit · Dynamic Island dose countdown |
| **Design System** | Custom MCColors/MCTypography/MCSpacing tokens |
| **Auth** | OTP-based phone login (simulated) |
| **Project Tracker** | Single-file HTML Kanban board ([`tracker/index.html`](tracker/index.html)) |

---

## Project Structure

```
MedCare/
├── App/
│   ├── MedCareApp.swift              # @main entry, environment setup
│   └── RootView.swift                # Auth/onboarding/home routing
│
├── Core/
│   ├── DesignSystem/                 # MCColors, MCTypography, MCSpacing
│   ├── Components/                   # MCCard, MCButton, MCBadge, MCTextField
│   ├── Navigation/                   # AppRouter (centralized routing)
│   └── Extensions/                   # DateExtensions
│
├── Models/                           # SwiftData @Model entities
│   ├── User.swift                    # Account with subscription tiers
│   ├── UserProfile.swift             # Family member profiles
│   ├── Episode.swift                 # Health journeys (acute/chronic/post-discharge)
│   ├── Medicine.swift                # Medicines with dose form, meal timing, frequency
│   ├── DoseLog.swift                 # Individual dose tracking
│   ├── CareTask.swift                # Follow-ups, lab tests, lifestyle tasks
│   ├── SymptomLog.swift              # Symptom tracking with severity
│   ├── ChatMessage.swift             # AI chat with emergency detection
│   ├── EpisodeImage.swift            # Document storage
│   └── Nudge.swift                   # Smart behavioral nudges
│
├── Services/                         # Business logic (@Observable)
│   ├── DataService.swift             # SwiftData CRUD + demo data seeding
│   ├── AuthService.swift             # OTP phone authentication
│   ├── AIChatService.swift           # Context-aware AI chat + streaming
│   ├── NotificationService.swift     # Push notification scheduling
│   ├── LiveActivityService.swift     # Dynamic Island management
│   ├── SmartNudgeService.swift       # Behavioral nudge evaluation
│   └── LLM/                         # LLMService, GroqProvider, LLMConfig
│
├── Features/
│   ├── Auth/Views/                   # Splash, Login, OTP, Profile Setup, Onboarding
│   ├── Home/Views/                   # HomeView, TodayView, MainTabView
│   ├── Episode/Views/                # EpisodeDetail, Timeline, DoseActionCard
│   ├── Reminders/Views/              # RemindersView with dose confirmation
│   ├── AIChat/Views/                 # AIChatView, ChatBubble, EmergencyAlert
│   ├── Symptoms/Views/               # SymptomLogView
│   ├── Files/Views/                  # Document management views
│   ├── Profile/Views/                # ProfileManagementView
│   └── History/Views/                # HistoryView
│
├── MedCareWidgetExtension/           # Dynamic Island widget
├── Shared/                           # ActivityKit attributes
├── MedCareTests/                     # Unit + service tests
│
└── tracker/                          # Project planning Kanban board
    ├── index.html                    # Clean Medical themed tracker
    └── tasks.json                    # 100+ tasks across 8 phases
```

---

## Data Model

```
User (1) ──── (N) UserProfile
UserProfile (1) ──── (N) Episode
Episode (1) ──── (N) Medicine
Episode (1) ──── (N) CareTask
Episode (1) ──── (N) SymptomLog
Episode (1) ──── (N) EpisodeImage
Medicine (1) ──── (N) DoseLog
```

**Demo data included:** 3 profiles (Rahul, Mom, Dad) with 4 episodes, 12 Indian medicines (Augmentin, Pan 40, Glycomet GP 2, Ecosprin, etc.), realistic dose logs, symptom trajectories, and 20+ documents.

---

## Roadmap

| Phase | Status | Key Features |
|---|---|---|
| **Phase 1: Core Foundation** | Done | Auth, profiles, episodes, medicines, reminders, notifications |
| **Phase 2: Wearable + AI** | Done | Dynamic Island, AI chat (Groq), smart nudges, document management |
| **Phase 3: Polish** | In Progress | Dark mode, dose forms, meal timing, today view, onboarding, streaks |
| **Phase 4: Intelligence** | Planned | Real OCR (Vision framework), drug interactions, medicine photo ID |
| **Phase 5: Connected Care** | Planned | WhatsApp reminders, ABHA integration, UPI payments, cloud sync |
| **Phase 6: Engagement** | Planned | Gamification, family competitions, health briefings |
| **Phase 7: Platform** | Planned | Widgets, Apple Watch, Hindi localization, accessibility |
| **Phase 8: Growth** | Planned | Subscriptions, StoreKit 2, analytics, ASO |

---

## Getting Started

### Prerequisites
- Xcode 16+
- iOS 18+ Simulator or device
- (Optional) Groq API key for live AI chat

### Run
1. Clone the repo
2. Open `MedCare.xcodeproj` in Xcode
3. Select iPhone simulator and hit Run
4. Enter any phone number, use **123456** as OTP
5. Demo data loads automatically on the home screen

### AI Chat Setup (Optional)
Add your Groq API key to `MedCare/Resources/Secrets.plist`:
```xml
<key>GROQ_API_KEY</key>
<string>your-key-here</string>
```
Without a key, the chat uses contextual mock responses.

---

## India-Specific Design Decisions

- **Dual-capture OCR** — Prescription photo for context + medicine box/strip photo for reliable data (CDSCO-mandated printed text)
- **Hinglish AI chat** — Understands mixed Hindi-English queries
- **Indian medicine brands** — Augmentin, Pan 40, Montek LC, Glycomet, Ecosprin recognized
- **Emergency number 112** — Not 911
- **MRP tracking** — Medicine prices in INR
- **Family-first design** — Managing parents' medications is a primary use case in India

---

## Safety

- AI is a **health companion, not a doctor** — never diagnoses or prescribes
- All AI output requires **explicit user confirmation** before creating care plans
- **Emergency detection** in chat with immediate 112 calling prompt
- **Duplicate dose prevention** — Alerts if same medicine taken within 2 hours
- **DPDP Act (India, 2023)** compliant design

---

## License

Proprietary software. All rights reserved.
