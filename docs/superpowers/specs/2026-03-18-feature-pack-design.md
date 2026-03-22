# MedCare Feature Pack Design — Saved Progress

> **Status:** Brainstorming paused — resuming later
> **Date:** March 18, 2026

## Feature A: AI Chat Enhancement Pack (APPROVED)

### 1. Voice Input
- Tap mic → iOS Speech framework activates
- Live waveform during recording
- Auto-populates text field, supports English + Hindi (en-IN, hi-IN)
- New `SpeechService.swift`
- Modify `AIChatView.swift` input bar
- Permission: `NSSpeechRecognitionUsageDescription`

### 2. Dynamic Quick Reply Chips
- Context-aware follow-up chips generated from LLM response
- LLM system prompt includes `suggested_replies` field
- Fallback to rule-based chips (symptom → "Log symptom", medicine → "Side effects?")
- Modify: `AIChatService.swift`, `AIChatView.swift`, `ChatMessage.swift`

### 3. Chat Session Management
- New `ChatSession` SwiftData model (id, title, createdAt, profileId)
- ChatMessage gets `sessionId` field (migration needed)
- Auto-title from first user message (truncated 40 chars)
- New session: first message of day or manual "New Chat"
- Multi-turn context: last 10 messages sent to LLM
- New `ChatHistoryView.swift`

## Feature B: Streak Tracking & Gamification (TO DESIGN)
- Adherence streaks with flame/trophy badges
- Dose calendar with color-coded days
- Celebration animations
- Already has: streak calculation in Episode model, flame icon on EpisodeCard

## Feature C: Home Screen Widgets (TO DESIGN)
- Small widget: next dose
- Medium widget: today's summary + adherence %
- Already has: WidgetDataService, Live Activity widget
- Needs: WidgetKit static widgets

## Feature D: Web Dashboard (TO DESIGN)
- Caregiver dashboard
- Adherence analytics
- Marketing landing page
- Use frontend-design plugin

---
*This spec will be completed when MedCare work resumes.*
