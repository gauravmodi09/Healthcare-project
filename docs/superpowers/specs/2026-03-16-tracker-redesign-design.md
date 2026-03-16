# MedCare Tracker Redesign — Design Spec

## Overview

Redesign the MedCare project tracker (`tracker/index.html`) from a functional Kanban board into a polished, minimalistic tool with a "Clean Medical" visual identity. The tracker serves as a shared workspace between the user and Claude for planning MedCare features.

**Core principles:** Minimalistic, effective, fast idea capture, Claude-compatible via `tasks.json`.

## Visual Direction: Clean Medical

- **Palette:** White backgrounds, teal (#0A7E8C) as primary accent, soft grays for structure
- **Cards:** White with subtle box-shadows (`0 1px 2px rgba(0,0,0,0.04)`), rounded corners (8px)
- **Columns:** Light gray (#f1f5f9) backgrounds, 10px border-radius
- **Typography:** System font stack (-apple-system, BlinkMacSystemFont, SF Pro Display, Segoe UI, system-ui, sans-serif)
- **Spacing:** Airy — generous padding, clear visual hierarchy
- **Done column:** Light green tint (#f0fdf4) to differentiate, cards slightly muted

## Layout Structure

### 1. Header (Slim)

- Left: MedCare logo (teal gradient square + "MedCare Tracker" text)
- Right: Export JSON, Import buttons (subtle outline style)
- Sticky at top, white background, bottom border

### 2. Quick-Add Bar

- Full-width text input below header: "⚡ Quick add — type a task and press Enter..."
- On Enter: creates task in Backlog with default category=feature, priority=medium
- Inline filter chips to the right: All | Features | Bugs | Infra | Design
- Active filter uses teal background
- Search input integrated — typing filters the board in real-time

### 3. Stats Row (Compact)

- Single horizontal row, not cards — just inline text:
  - **38** total · **6** to do · **2** in progress · **28** done
- Thin progress bar (4px height) at the end showing completion percentage
- Stats color-coded: to do=teal, in progress=amber, done=green

### 4. Kanban Board

Four columns: **Backlog**, **To Do**, **In Progress**, **Done**

**Column header:**
- Column title (color-coded: Backlog=gray, To Do=teal, In Progress=amber, Done=green)
- Task count badge (pill-shaped, matching column color)

**Column body:**
- Scrollable area containing task cards
- "+ Add task" dashed button at bottom of each column
- Drop zone for drag-and-drop

## Task Card Design

**Structure:**
- Left border: 3px colored by priority (red=critical, amber=high, teal=medium, gray=low)
- Title: 12px, font-weight 600
- Description: 10px, gray, truncated to 1 line
- Tags row: category tag (feature=purple, bug=red, infra=blue, design=amber) + priority tag (only for critical/high) + phase text (gray, small)
- Comment badge: 💬 count, shown only when notes exist, right-aligned in tags row

**Interactions:**
- Hover: subtle shadow lift
- Drag: slight rotation + opacity reduction
- Click: opens slide-over detail panel

## Task Detail — Slide-Over Panel

**Trigger:** Click any task card.

**Appearance:**
- Panel slides in from the right edge, ~400px wide
- Board remains visible but dimmed (overlay with rgba backdrop)
- Teal left border accent (3px) on the panel
- Close: X button in top-right, click outside panel, or Escape key

**Panel contents (top to bottom):**

1. **Title** — editable inline, font-weight 700
2. **Tags** — category, priority, phase (displayed as pills)
3. **Status** — dropdown to change status (moves card on board)
4. **Description** — full text, editable
5. **Metadata fields** — category, priority, phase dropdowns for editing
6. **Divider**
7. **Notes section:**
   - Header: "Notes" with count
   - Chronological list of notes, each showing:
     - Date (teal, bold): "Mar 15"
     - Text content
     - Background: light gray (#f8fafc), rounded
   - "Add a note..." input at bottom
   - Enter to add note, auto-timestamps with current date
8. **Footer actions** — Delete task button (red, requires confirm)

## Data Model

### tasks.json Structure

```json
[
  {
    "id": "abc123def",
    "title": "AI Chat — Core engine",
    "desc": "In-app AI chat with case-aware context...",
    "category": "feature",
    "priority": "critical",
    "phase": "Phase 2.5: AI",
    "status": "todo",
    "created": "2026-03-15",
    "notes": [
      { "text": "Should use GPT-4V for context assembly", "date": "2026-03-15" },
      { "text": "Need DPDP Act compliance check", "date": "2026-03-16" }
    ]
  }
]
```

**New field:** `notes` — array of `{text: string, date: string}`. Defaults to empty array. Backward compatible: existing tasks without `notes` field are treated as having no notes.

### Persistence

1. **localStorage** — immediate save on every change (primary fallback)
2. **File System Access API** — "Connect File" button to link to `tasks.json` on disk for auto-save (Chrome/Edge only)
3. **Fetch fallback** — on load, tries to fetch `./tasks.json` first (for when served via local server)

No changes to persistence architecture from current implementation.

## Interactions

### Drag and Drop
- Cards draggable between columns
- Visual feedback: card gets slight rotation + opacity, target column highlights
- Drop updates status field and re-renders

### Quick Add
- Type in quick-add bar, press Enter
- Creates task: `{title: input, category: "feature", priority: "medium", status: "backlog", created: today, notes: []}`
- Input clears, card appears in Backlog column
- For more detail, user clicks the new card to open slide-over and fill in description/notes

### Filtering
- Filter chips: All | Features | Bugs | Infra | Design
- Search input: real-time filter by title, description, phase text
- Both work together (filter + search intersect)

### Keyboard Shortcuts
- `Cmd/Ctrl + N` — focus quick-add bar
- `Escape` — close slide-over panel or modal
- `Enter` (in quick-add) — create task
- `Enter` (in note input) — add note

## Architecture

Single file: `tracker/index.html` containing all HTML, CSS, and JavaScript. No build step, no dependencies, no framework. Data stored in `tasks.json` alongside it.

This keeps the tracker dead simple — open the HTML file in a browser and it works. Claude updates `tasks.json` directly when asked.

## Phase Dropdown Options

Same as current implementation:
- Phase 1: Core Foundation
- Phase 2: Wearable Integration
- Phase 2.5: AI Health Assistant
- Phase 3: Core Experience Polish
- Phase 4: Intelligence Layer
- Phase 5: Connected Care
- Phase 6: Engagement & Retention
- Phase 7: Platform Expansion
- Phase 8: Monetization & Growth
- Tech Debt & Quality

## What's NOT Changing

- Single HTML file architecture
- `tasks.json` format (additive change only — new `notes` field)
- Import/Export JSON functionality
- Default task data for fresh installs
- Basic column structure (Backlog, To Do, In Progress, Done)

## What's New

1. Clean Medical visual redesign (entire UI)
2. Quick-add bar for fast idea capture
3. Compact stats row (replacing stat cards)
4. Slide-over detail panel on card click
5. Notes/comments per task with timestamps
6. Comment count badges on cards
7. Improved card design with better tag layout
8. Done column visual differentiation (green tint, muted cards)
