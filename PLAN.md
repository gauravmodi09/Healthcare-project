# MedCare iOS App - Implementation Plan

## Overview
Building an end-to-end iOS application (SwiftUI, iOS 16+) based on the MedCare specification documents. The app transforms physical prescriptions into structured, trackable care plans with automated medication reminders.

## Architecture
- **Pattern:** MVVM with SwiftUI
- **Local Storage:** SwiftData (iOS 17+) with CoreData fallback
- **Networking:** URLSession + async/await
- **State Management:** @Observable (iOS 17+) / ObservableObject
- **Navigation:** NavigationStack with programmatic routing
- **DI:** Environment-based dependency injection

## Build Phases

### Phase 1: Foundation (Project Structure + Design System)
- Xcode project scaffold with proper folder structure
- Design system: Colors, Typography, Components
- Core data models (User, Profile, Episode, Medicine, DoseLog, etc.)
- Navigation router

### Phase 2: Authentication Flow
- Splash screen with branding
- Phone number input (+91 prefilled)
- OTP verification screen
- Profile setup (name, DOB, gender, conditions)
- Keychain-based token storage

### Phase 3: Home Dashboard
- Two-door CTA (Consult Doctor / Upload Prescription)
- Active episodes list
- Today's medication summary
- Quick stats bar

### Phase 4: Dual-Capture Upload
- Camera/gallery picker for prescription photo
- Multi-photo capture for medicine packaging
- Image compression (<500KB)
- Upload progress UI
- Pre-signed URL flow

### Phase 5: AI Extraction & Confirmation
- GPT-4V extraction service integration
- Confidence scoring per field
- Amber warning for low-confidence (<0.70)
- User confirmation gate (HITL)
- Medical disclaimer

### Phase 6: Episode Management
- Episode detail view with tabs (Plan/Reminders/Symptoms)
- Medicine list with dose schedules
- Task tracking (lab tests, follow-ups)
- Edit/delete medications

### Phase 7: Reminders Engine
- Local notification scheduling
- Actionable notifications (Taken/Skip/Snooze)
- Dose logging with status tracking
- Offline-first with sync

### Phase 8: Symptom Tracking & History
- Daily symptom check-in
- Severity scale + notes
- Adherence charts (daily/weekly)
- History timeline
- PDF export

### Phase 9: Family Profiles
- Multi-profile management (up to 5)
- Profile switching
- Per-profile episodes and tracking

### Phase 10: Backend API Service Layer
- RESTful API client with JWT auth
- Request/response models
- Error handling + retry logic
- Offline queue for dose logs

### Phase 11: Testing & Enhancement
- UI testing across flows
- Performance optimization
- Accessibility audit
- Enhancement implementation

### Phase 12: Business Moats & Positioning
- Competitive advantages implementation
- AI positioning agent
- Final polish

---

## Phase 2.5: AI Health Assistant & Post-Discharge Care

> **Full spec:** [`docs/product/phase2_ai_health_assistant.md`](docs/product/phase2_ai_health_assistant.md)

**Core Problem:** Patients abandon treatment because they don't see improvement in 1-2 days, feel better and stop early, panic about side effects, or lose motivation. MedCare Phase 1 tells patients *what* to take — Phase 2.5 tells them *why to keep taking it*.

### Key Features

| # | Feature | Priority | Effort | Status |
|---|---------|----------|--------|--------|
| F1 | AI Health Companion (text chat) | P0 | 3 weeks | To Do |
| F2 | Voice Input for Symptoms | P1 | 2 weeks | Backlog |
| F3 | Treatment Timeline Visualization | P1 | 2 weeks | Backlog |
| F4 | Smart Nudges & Behavioral Interventions | P0 | 1 week | To Do |
| F5 | Virtual Doctor Consultation | P2 | 3 weeks | Backlog |
| F6 | Family Caregiver Dashboard | P2 | 2 weeks | Backlog |
| F7 | Post-Discharge Recovery Guide | P2 | 2 weeks | Backlog |

### The 5 Drop-Off Scenarios MedCare Solves
1. **"No change in 2 days"** → AI explains expected medicine timelines, shows symptom trends
2. **"I feel better, I'll stop"** → AI explains why completing the course matters
3. **"Side effects scare me"** → AI identifies common vs. concerning side effects, calms anxiety
4. **"Doctor is useless"** → AI shows treatment trajectory, offers virtual second opinion
5. **"Forgot / lost motivation"** → Streak gamification, family nudges, adaptive reminders

### Project Tracker
Open `tracker/index.html` in any browser for the Kanban-style project tracker with all tasks, priorities, and progress.

---

## Enhancement Log

| # | Enhancement | Category | Status | Impact |
|---|------------|----------|--------|--------|
| 1 | Offline-First Sync Queue | Reliability | Done | Critical - India has unreliable connectivity |
| 2 | Drug Interaction Checker | Safety | Done | High - Patient safety, competitive moat |
| 3 | Medicine Expiry Tracker | Safety | Done | High - Prevents use of expired medicines |
| 4 | Smart Scheduling Engine | UX | Done | Medium - Learns user routine, optimizes timings |
| 5 | Privacy-First Analytics | Insights | Done | High - Adherence insights, streak tracking |
| 6 | Widget & Watch Data Provider | Engagement | Done | High - Persistent reminders on home screen |
| 7 | Smart Insights Dashboard | Engagement | Done | Medium - Personalized health tips |
| 8 | Drug Interaction Alert Banner | Safety | Done | High - Visual warnings for dangerous combos |
| 9 | Medicine Expiry Alert UI | Safety | Done | Medium - Proactive expiry notifications |
| 10 | Business Moat: Pharma Data Network | Strategy | Done | Critical - Defensible data advantage |
| 11 | Business Moat: Regional Language AI | Strategy | Done | High - India market lock-in |
| 12 | AI Positioning Agent | Strategy | Done | High - Competitive positioning analysis |
| 13 | File Management System | Feature | Done | Medium - Document organization per episode/profile |
| 14 | Rich Sample Case Data | Demo | Done | Medium - 3 profiles, 4 episodes, 25+ documents |
| 15 | AI Health Companion (Phase 2.5) | Feature | Planned | Critical - Core retention differentiator |
| 16 | Smart Nudges System (Phase 2.5) | Feature | Planned | Critical - Reduces treatment drop-off |

---

## Business Moats (Planned)
1. **Data Network Effect** — More prescriptions = better AI accuracy
2. **Dual-Capture IP** — Unique India-specific prescription + packaging cross-reference
3. **Pharma Database Integration** — Stitch MCP validated medicine data
4. **Regulatory Compliance** — DPDP Act 2023 compliant from day one
5. **Family Health Graph** — Multi-generational health data moat
6. **Doctor Trust Network** — Verified prescription sources (v2)

---

## Testing Strategy
- Unit tests for ViewModels and Services
- UI tests for critical flows (auth, upload, confirmation)
- Snapshot tests for design consistency
- Integration tests for API layer
