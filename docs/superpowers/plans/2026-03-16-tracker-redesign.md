# MedCare Tracker Redesign Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the MedCare project tracker from a functional Kanban board into a polished, minimalistic "Clean Medical" tool with quick-add, slide-over detail panel, and notes/comments.

**Architecture:** Single-file rewrite of `tracker/index.html`. No dependencies, no build step. All CSS, HTML, and JS in one file. Data persisted in `tasks.json` (backward compatible — adds `notes` array field).

**Tech Stack:** Vanilla HTML/CSS/JS, File System Access API, localStorage

**Spec:** `docs/superpowers/specs/2026-03-16-tracker-redesign-design.md`

---

## Chunk 1: Complete Rewrite

Since this is a single HTML file with no tests (static browser app), the implementation is a full rewrite of `tracker/index.html`. The file is self-contained — CSS, HTML, and JS are tightly coupled and must change together.

### Task 1: Rewrite CSS — Clean Medical Theme

**Files:**
- Modify: `tracker/index.html:1-404` (entire `<style>` block)

- [ ] **Step 1: Replace the entire `<style>` block with Clean Medical CSS**

The new CSS must include:

**CSS Variables (`:root`):**
```css
--teal: #0A7E8C;
--teal-light: #e8f5f6;
--teal-dark: #065A64;
--red: #ef4444;
--red-light: #fef2f2;
--green: #22c55e;
--green-light: #f0fdf4;
--amber: #f59e0b;
--amber-light: #fef3c7;
--blue: #3b82f6;
--blue-light: #eff6ff;
--purple: #7c3aed;
--purple-light: #ede9fe;
--gray-50: #f8fafb;
--gray-100: #f1f5f9;
--gray-200: #e2e8f0;
--gray-400: #94a3b8;
--gray-600: #64748b;
--gray-800: #1a2332;
--gray-900: #111827;
--card-shadow: 0 1px 2px rgba(0,0,0,0.04);
--card-shadow-hover: 0 4px 12px rgba(0,0,0,0.08);
```

**Key CSS sections to include:**
- Reset (`* { margin:0; padding:0; box-sizing:border-box }`)
- Body: system font stack, `background: var(--gray-50)`, `color: var(--gray-800)`
- `.header` — sticky, white, slim (padding: 12px 20px), border-bottom
- `.header-inner` — max-width 1400px, flex between logo and actions
- `.logo` — flex, gap 8px, teal gradient SVG icon + text
- `.quick-add-bar` — white bg, border-bottom, padding 12px 20px, flex row
- `.quick-add-input` — flex:1, background #f1f5f9, border-radius 8px, padding 10px 14px, 13px font, border 1.5px solid transparent, focus: border-color teal
- `.filter-chip` — padding 4px 10px, border-radius 12px, 11px font, 500 weight, border 1px solid gray-200
- `.filter-chip.active` — background teal-light, color teal, no border
- `.stats-row` — max-width 1400px, padding 10px 20px, flex, gap 16px, font-size 11px, color gray-400
- `.stats-row strong` — font-size 14px, color gray-800
- `.stats-row .progress-track` — inline-block, width 80px, height 4px, background gray-200, border-radius 2px
- `.stats-row .progress-fill` — height 4px, border-radius 2px, gradient teal→green
- `.board` — max-width 1400px, margin auto, padding 0 20px 20px, flex, gap 12px, overflow-x auto
- `.column` — flex:1, min-width 280px, background gray-100, border-radius 10px, max-height calc(100vh - 220px), flex column
- `.column.done` — background green-light (for done column differentiation)
- `.column-header` — padding 10px 12px, font-size 12px, font-weight 600, flex between, color per column
- `.column-header .count` — pill badge, matching column color background
- `.column-body` — padding 8px, overflow-y auto, flex:1, flex column, gap 6px
- `.task-card` — white bg, border-radius 8px, padding 10px 12px, card-shadow, cursor grab, border-left 3px solid, transition
- `.task-card:hover` — card-shadow-hover, translateY(-1px)
- `.task-card.dragging` — opacity 0.5, rotate(2deg)
- `.task-card.priority-critical` — border-left-color red
- `.task-card.priority-high` — border-left-color amber
- `.task-card.priority-medium` — border-left-color teal
- `.task-card.priority-low` — border-left-color gray-400
- `.task-title` — font-weight 600, font-size 13px, line-height 1.4
- `.task-description` — font-size 11px, color gray-600, -webkit-line-clamp 1, overflow hidden
- `.task-meta` — flex, gap 4px, flex-wrap, align-items center, margin-top 6px
- `.tag` — font-size 9px, padding 1px 6px, border-radius 6px, font-weight 500
- Tag colors: `.tag-feature` purple-light/purple, `.tag-bug` red-light/red, `.tag-infra` blue-light/blue, `.tag-design` amber-light/amber
- `.tag-priority-critical` red-light/red, `.tag-priority-high` amber-light/amber
- `.task-note-count` — font-size 9px, color gray-400, margin-left auto
- `.btn-add-task` — width 100%, padding 8px, border 1.5px dashed gray-200, border-radius 8px, transparent bg, gray-400 color, 12px font, hover: teal border/color/teal-light bg
- `.btn` — padding 6px 12px, border-radius 6px, border none, 12px font, 600 weight, cursor pointer, transition
- `.btn-secondary` — white bg, gray-600 color, border 1px solid gray-200, hover: teal border/color
- `.btn-primary` — teal bg, white color, hover: teal-dark
- **Slide-over panel CSS:**
  - `.panel-overlay` — fixed inset 0, background rgba(0,0,0,0.3), backdrop-filter blur(2px), z-index 200, opacity 0, pointer-events none, transition opacity 0.2s
  - `.panel-overlay.active` — opacity 1, pointer-events all
  - `.panel` — position fixed, top 0, right 0, bottom 0, width 420px, max-width 90vw, background white, box-shadow -8px 0 30px rgba(0,0,0,0.1), border-left 3px solid teal, transform translateX(100%), transition transform 0.25s ease, overflow-y auto, padding 24px, z-index 201, display flex, flex-direction column
  - `.panel-overlay.active .panel` — transform translateX(0)
  - `.panel-close` — position absolute, top 16px, right 16px, background none, border none, font-size 18px, color gray-400, cursor pointer, hover: color gray-800
  - `.panel-title` — font-size 16px, font-weight 700, color gray-800, margin-bottom 12px, outline none (for contenteditable)
  - `.panel-tags` — flex, gap 4px, flex-wrap, margin-bottom 12px
  - `.panel-field` — margin-bottom 12px
  - `.panel-field label` — display block, font-size 10px, font-weight 600, color gray-400, text-transform uppercase, letter-spacing 0.3px, margin-bottom 4px
  - `.panel-field select, .panel-field textarea` — width 100%, padding 8px 10px, border 1.5px solid gray-200, border-radius 6px, font-size 13px, font-family inherit, outline none, focus: border-color teal
  - `.panel-field textarea` — resize vertical, min-height 60px
  - `.panel-divider` — height 1px, background gray-200, margin 16px 0
  - `.panel-notes-header` — font-size 12px, font-weight 600, color gray-600, margin-bottom 8px
  - `.note-item` — background #f8fafc, border-radius 6px, padding 8px 10px, margin-bottom 6px
  - `.note-date` — font-size 10px, font-weight 600, color teal, margin-right 4px
  - `.note-text` — font-size 12px, color #475569, line-height 1.4
  - `.note-input` — width 100%, padding 8px 10px, background gray-100, border-radius 6px, border 1.5px solid transparent, font-size 12px, font-family inherit, outline none, focus: border-color teal, focus: background white
  - `.panel-delete` — margin-top auto, padding-top 16px, border-top 1px solid gray-200
  - `.panel-delete button` — width 100%, padding 8px, border-radius 6px, border 1px solid red-light, background white, color red, font-size 12px, cursor pointer, hover: background red-light
- **Modal CSS** (keep for "+ Add task" column buttons):
  - Same structure as current but with updated styling to match Clean Medical
  - `.modal-overlay` — fixed inset 0, rgba(0,0,0,0.3), backdrop-filter blur(2px), z-index 300, flex center
  - `.modal` — white bg, border-radius 12px, padding 24px, width 440px, max-width 90vw, box-shadow
- `.column-body.drag-over` — background rgba(10, 126, 140, 0.05)
- **Responsive** `@media (max-width: 768px)`: board flex-direction column, column min-width auto/max-height none

- [ ] **Step 2: Verify CSS compiles** — open the file in a browser, check there are no rendering issues with the new styles.

### Task 2: Rewrite HTML Structure

**Files:**
- Modify: `tracker/index.html:406-507` (entire `<body>` HTML before `<script>`)

- [ ] **Step 3: Replace the HTML body with new structure**

```html
<body>

<!-- Header -->
<div class="header">
  <div class="header-inner">
    <div class="logo">
      <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
        <defs><linearGradient id="tealGrad" x1="0" y1="0" x2="24" y2="24">
          <stop offset="0%" stop-color="#0A7E8C"/>
          <stop offset="100%" stop-color="#0ea5e9"/>
        </linearGradient></defs>
        <rect width="24" height="24" rx="6" fill="url(#tealGrad)"/>
        <path d="M12 6v12M6 12h12" stroke="white" stroke-width="2" stroke-linecap="round"/>
      </svg>
      <span class="logo-text">MedCare <span class="logo-sub">Tracker</span></span>
    </div>
    <div class="header-actions">
      <button class="btn btn-secondary" id="saveStatus" onclick="connectAndSave()">Connect File</button>
      <button class="btn btn-secondary" onclick="exportData()">Export</button>
      <button class="btn btn-secondary" onclick="importData()">Import</button>
    </div>
  </div>
</div>

<!-- Quick Add Bar -->
<div class="quick-add-bar">
  <div class="quick-add-inner">
    <input type="text" class="quick-add-input" id="quickAddInput"
           placeholder="⚡ Quick add — type a task and press Enter..."
           onkeydown="if(event.key==='Enter')quickAdd()">
    <div class="filter-chips">
      <button class="filter-chip active" data-filter="all" onclick="setFilter('all',this)">All</button>
      <button class="filter-chip" data-filter="feature" onclick="setFilter('feature',this)">Features</button>
      <button class="filter-chip" data-filter="bug" onclick="setFilter('bug',this)">Bugs</button>
      <button class="filter-chip" data-filter="infra" onclick="setFilter('infra',this)">Infra</button>
      <button class="filter-chip" data-filter="design" onclick="setFilter('design',this)">Design</button>
    </div>
  </div>
</div>

<!-- Stats Row -->
<div class="stats-row" id="statsRow"></div>

<!-- Kanban Board -->
<div class="board" id="board"></div>

<!-- Slide-over Detail Panel -->
<div class="panel-overlay" id="panelOverlay" onclick="if(event.target===this)closePanel()">
  <div class="panel" id="panel">
    <button class="panel-close" onclick="closePanel()">✕</button>
    <div class="panel-title" id="panelTitle" contenteditable="true"
         onblur="updatePanelField('title',this.textContent)"></div>
    <div class="panel-tags" id="panelTags"></div>

    <div class="panel-field">
      <label>Status</label>
      <select id="panelStatus" onchange="updatePanelField('status',this.value)">
        <option value="backlog">Backlog</option>
        <option value="todo">To Do</option>
        <option value="in-progress">In Progress</option>
        <option value="done">Done</option>
      </select>
    </div>

    <div class="panel-field">
      <label>Description</label>
      <textarea id="panelDesc" placeholder="Add description..."
                onblur="updatePanelField('desc',this.value)"></textarea>
    </div>

    <div style="display:flex;gap:8px">
      <div class="panel-field" style="flex:1">
        <label>Category</label>
        <select id="panelCategory" onchange="updatePanelField('category',this.value)">
          <option value="feature">Feature</option>
          <option value="bug">Bug</option>
          <option value="infra">Infra</option>
          <option value="design">Design</option>
        </select>
      </div>
      <div class="panel-field" style="flex:1">
        <label>Priority</label>
        <select id="panelPriority" onchange="updatePanelField('priority',this.value)">
          <option value="medium">Medium</option>
          <option value="high">High</option>
          <option value="critical">Critical</option>
          <option value="low">Low</option>
        </select>
      </div>
    </div>

    <div class="panel-field">
      <label>Phase</label>
      <select id="panelPhase" onchange="updatePanelField('phase',this.value)">
        <option value="">None</option>
        <option value="Phase 1: Core">Phase 1: Core Foundation</option>
        <option value="Phase 2: Wearable">Phase 2: Wearable Integration</option>
        <option value="Phase 2.5: AI">Phase 2.5: AI Health Assistant</option>
        <option value="Phase 3: Polish">Phase 3: Core Experience Polish</option>
        <option value="Phase 4: Intelligence">Phase 4: Intelligence Layer</option>
        <option value="Phase 5: Connected">Phase 5: Connected Care</option>
        <option value="Phase 6: Engagement">Phase 6: Engagement & Retention</option>
        <option value="Phase 7: Platform">Phase 7: Platform Expansion</option>
        <option value="Phase 8: Growth">Phase 8: Monetization & Growth</option>
        <option value="Tech Debt">Tech Debt & Quality</option>
        <option value="Phase 3: Telecon">Phase 3: Teleconsultation</option>
      </select>
    </div>

    <div class="panel-divider"></div>

    <div class="panel-notes-header">Notes <span id="panelNoteCount"></span></div>
    <div id="panelNotes"></div>
    <input type="text" class="note-input" id="noteInput" placeholder="Add a note..."
           onkeydown="if(event.key==='Enter')addNote()">

    <div class="panel-delete">
      <button onclick="deletePanelTask()">Delete Task</button>
    </div>
  </div>
</div>

<!-- Add Task Modal (for column "+ Add task" buttons) -->
<div class="modal-overlay" id="modalOverlay" onclick="if(event.target===this)closeModal()">
  <div class="modal">
    <h2 id="modalTitle">Add Task</h2>
    <input type="hidden" id="editTaskId">
    <div class="form-group">
      <label>Title</label>
      <input type="text" id="taskTitle" placeholder="What needs to be done?">
    </div>
    <div class="form-group">
      <label>Description</label>
      <textarea id="taskDesc" placeholder="Details, context..."></textarea>
    </div>
    <div style="display:flex;gap:12px">
      <div class="form-group" style="flex:1">
        <label>Category</label>
        <select id="taskCategory">
          <option value="feature">Feature</option>
          <option value="bug">Bug</option>
          <option value="infra">Infra</option>
          <option value="design">Design</option>
        </select>
      </div>
      <div class="form-group" style="flex:1">
        <label>Priority</label>
        <select id="taskPriority">
          <option value="medium">Medium</option>
          <option value="high">High</option>
          <option value="critical">Critical</option>
          <option value="low">Low</option>
        </select>
      </div>
    </div>
    <div class="form-group">
      <label>Phase</label>
      <select id="taskPhase">
        <option value="">None</option>
        <option value="Phase 1: Core">Phase 1: Core Foundation</option>
        <option value="Phase 2: Wearable">Phase 2: Wearable Integration</option>
        <option value="Phase 2.5: AI">Phase 2.5: AI Health Assistant</option>
        <option value="Phase 3: Polish">Phase 3: Core Experience Polish</option>
        <option value="Phase 4: Intelligence">Phase 4: Intelligence Layer</option>
        <option value="Phase 5: Connected">Phase 5: Connected Care</option>
        <option value="Phase 6: Engagement">Phase 6: Engagement & Retention</option>
        <option value="Phase 7: Platform">Phase 7: Platform Expansion</option>
        <option value="Phase 8: Growth">Phase 8: Monetization & Growth</option>
        <option value="Tech Debt">Tech Debt & Quality</option>
        <option value="Phase 3: Telecon">Phase 3: Teleconsultation</option>
      </select>
    </div>
    <div class="form-group">
      <label>Status</label>
      <select id="taskStatus">
        <option value="backlog">Backlog</option>
        <option value="todo">To Do</option>
        <option value="in-progress">In Progress</option>
        <option value="done">Done</option>
      </select>
    </div>
    <div class="form-actions">
      <button class="btn btn-secondary" onclick="closeModal()">Cancel</button>
      <button class="btn btn-primary" onclick="saveTask()">Save Task</button>
    </div>
  </div>
</div>

<input type="file" id="importFile" accept=".json" style="display:none" onchange="handleImport(event)">
```

### Task 3: Rewrite JavaScript — Core State & Persistence

**Files:**
- Modify: `tracker/index.html:509-898` (entire `<script>` block)

- [ ] **Step 4: Replace the script block — constants, state, and persistence functions**

Keep these functions exactly as-is from current code (they work correctly):
- `COLUMNS` array — update colors to match new theme: `{id:'backlog', title:'Backlog', color:'var(--gray-400)'}`, `{id:'todo', title:'To Do', color:'var(--teal)'}`, `{id:'in-progress', title:'In Progress', color:'var(--amber)'}`, `{id:'done', title:'Done', color:'var(--green)'}`
- `tasks`, `currentFilter`, `searchQuery`, `draggedTask` state variables
- Add: `let activePanelTaskId = null;` for tracking which task the panel shows
- `fileHandle` variable
- `loadTasks()` — keep as-is
- `saveTasks()` — keep as-is
- `connectAndSave()` — keep as-is
- `updateSaveButton()` — keep as-is but update emoji to text-only labels
- `getDefaultTasks()` — keep as-is but add `notes: []` to each default task
- `genId()` — keep as-is
- `esc()` — keep as-is

- [ ] **Step 5: Write new render functions**

**`render()`** — calls `renderStats()` and `renderBoard()`

**`renderStats()`** — compact inline stats:
```javascript
function renderStats() {
    const total = tasks.length;
    const done = tasks.filter(t => t.status === 'done').length;
    const inProgress = tasks.filter(t => t.status === 'in-progress').length;
    const todo = tasks.filter(t => t.status === 'todo').length;
    const pct = total ? Math.round((done / total) * 100) : 0;

    document.getElementById('statsRow').innerHTML = `
        <span><strong>${total}</strong> total</span>
        <span><strong style="color:var(--teal)">${todo}</strong> to do</span>
        <span><strong style="color:var(--amber)">${inProgress}</strong> in progress</span>
        <span><strong style="color:var(--green)">${done}</strong> done</span>
        <span style="margin-left:auto;display:flex;align-items:center;gap:6px;">
            <span class="progress-track"><span class="progress-fill" style="width:${pct}%"></span></span>
            ${pct}%
        </span>
    `;
}
```

**`renderBoard()`** — same logic as current but:
- Add `done` class to done column: `colEl.className = 'column' + (col.id === 'done' ? ' done' : '')`
- Column header uses column-specific color for title
- Column count badge uses column-specific color background

**`renderTaskCard(task)`** — updated card markup:
- Priority class on card for left border
- Title (13px, 600 weight)
- Description (11px, 1-line clamp)
- Tags: category + priority (only critical/high) + phase text (small, gray)
- Note count badge: `💬 ${task.notes?.length}` only if notes array has items, right-aligned with `margin-left:auto`
- Card click opens panel: `onclick="openPanel('${task.id}')"`
- Draggable with drag handlers (same as current)
- Remove edit/delete action buttons from card (moved to panel)

- [ ] **Step 6: Write Quick Add function**

```javascript
function quickAdd() {
    const input = document.getElementById('quickAddInput');
    const title = input.value.trim();
    if (!title) return;
    tasks.push({
        id: genId(),
        title,
        desc: '',
        category: 'feature',
        priority: 'medium',
        phase: '',
        status: 'backlog',
        created: new Date().toISOString().split('T')[0],
        notes: []
    });
    input.value = '';
    saveTasks();
    render();
}
```

- [ ] **Step 7: Write Slide-over Panel functions**

**`openPanel(taskId)`:**
```javascript
function openPanel(taskId) {
    const task = tasks.find(t => t.id === taskId);
    if (!task) return;
    activePanelTaskId = taskId;

    document.getElementById('panelTitle').textContent = task.title;
    document.getElementById('panelStatus').value = task.status;
    document.getElementById('panelDesc').value = task.desc || '';
    document.getElementById('panelCategory').value = task.category;
    document.getElementById('panelPriority').value = task.priority;
    document.getElementById('panelPhase').value = task.phase || '';

    // Render tags
    const tags = [];
    tags.push(`<span class="tag tag-${task.category}">${task.category}</span>`);
    if (['critical','high'].includes(task.priority))
        tags.push(`<span class="tag tag-priority-${task.priority}">${task.priority}</span>`);
    if (task.phase)
        tags.push(`<span class="tag" style="background:var(--teal-light);color:var(--teal)">${task.phase}</span>`);
    document.getElementById('panelTags').innerHTML = tags.join('');

    // Render notes
    renderPanelNotes(task);

    document.getElementById('panelOverlay').classList.add('active');
}
```

**`closePanel()`:**
```javascript
function closePanel() {
    document.getElementById('panelOverlay').classList.remove('active');
    activePanelTaskId = null;
}
```

**`updatePanelField(field, value)`:**
```javascript
function updatePanelField(field, value) {
    if (!activePanelTaskId) return;
    const task = tasks.find(t => t.id === activePanelTaskId);
    if (!task) return;
    task[field] = value;
    saveTasks();
    render();
    // Re-render panel tags if category/priority/phase changed
    if (['category','priority','phase'].includes(field)) {
        openPanel(activePanelTaskId); // refresh panel
    }
}
```

**`renderPanelNotes(task)`:**
```javascript
function renderPanelNotes(task) {
    const notes = task.notes || [];
    const count = notes.length;
    document.getElementById('panelNoteCount').textContent = count ? `(${count})` : '';
    document.getElementById('panelNotes').innerHTML = notes.map(n => `
        <div class="note-item">
            <span class="note-date">${formatNoteDate(n.date)}:</span>
            <span class="note-text">${esc(n.text)}</span>
        </div>
    `).join('');
    document.getElementById('noteInput').value = '';
}
```

**`formatNoteDate(dateStr)`:**
```javascript
function formatNoteDate(dateStr) {
    const d = new Date(dateStr);
    return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}
```

**`addNote()`:**
```javascript
function addNote() {
    if (!activePanelTaskId) return;
    const input = document.getElementById('noteInput');
    const text = input.value.trim();
    if (!text) return;
    const task = tasks.find(t => t.id === activePanelTaskId);
    if (!task) return;
    if (!task.notes) task.notes = [];
    task.notes.push({ text, date: new Date().toISOString().split('T')[0] });
    saveTasks();
    render();
    renderPanelNotes(task);
}
```

**`deletePanelTask()`:**
```javascript
function deletePanelTask() {
    if (!activePanelTaskId) return;
    if (!confirm('Delete this task?')) return;
    tasks = tasks.filter(t => t.id !== activePanelTaskId);
    closePanel();
    saveTasks();
    render();
}
```

- [ ] **Step 8: Write remaining functions (drag/drop, filters, modal, import/export, keyboard)**

**Drag & Drop** — keep `handleDragStart`, `handleDragEnd`, `handleDragOver`, `handleDragEnter`, `handleDragLeave`, `handleDrop` exactly as current.

**Filters** — keep `setFilter` and `searchTasks` as current but `searchTasks` reads from quick-add input OR a separate search:
- Actually, the quick-add bar doubles as search. Add: when the input has text but user doesn't press Enter, it should filter. Add `oninput` handler to quick-add input that calls a debounced search.
- Simpler approach: keep search separate. The quick-add input is ONLY for adding. Filter chips handle category filtering. Add a search icon input within the filter-chips area.
- **Decision:** Keep the search input inside the filter chips area as a small input. The quick-add bar is purely for adding tasks.

Update the HTML quick-add-bar to include search:
```html
<div class="filter-chips">
  <!-- filter buttons -->
  <input type="text" class="search-input" placeholder="Search..." oninput="searchTasks(this.value)">
</div>
```

**Modal** — keep `openModal`, `closeModal`, `saveTask` as current but add `notes: []` to new tasks in `saveTask`.

**Import/Export** — keep `exportData`, `importData`, `handleImport` as-is.

**Keyboard shortcuts:**
```javascript
document.addEventListener('keydown', e => {
    if (e.key === 'Escape') {
        if (document.getElementById('panelOverlay').classList.contains('active')) {
            closePanel();
        } else {
            closeModal();
        }
    }
    if (e.key === 'n' && (e.metaKey || e.ctrlKey)) {
        e.preventDefault();
        document.getElementById('quickAddInput').focus();
    }
});
```

**Delete task** — remove standalone `deleteTask()` (moved to panel's `deletePanelTask`). But keep it in case modal edit buttons reference it — actually, modal no longer has delete. Remove.

- [ ] **Step 9: Init call**

```javascript
loadTasks();
```

### Task 4: Verify & Commit

- [ ] **Step 10: Open in browser and verify**

Open `tracker/index.html` in Chrome/Edge. Verify:
1. Clean Medical styling renders correctly
2. Quick-add bar creates tasks in Backlog on Enter
3. Filter chips filter the board
4. Search input filters by title/description/phase
5. Task cards show correct priority borders, tags, note count badges
6. Click card → slide-over panel opens with all fields
7. Edit title (contenteditable), status, description, category, priority, phase in panel → changes reflect on board
8. Add a note → appears in notes list with today's date
9. Delete task from panel → task removed, panel closes
10. Drag and drop cards between columns
11. "+ Add task" button opens modal, modal creates task correctly
12. Export/Import JSON works
13. Connect File persists to disk
14. Cmd+N focuses quick-add
15. Escape closes panel/modal
16. Done column has green tint, done cards slightly muted
17. Existing `tasks.json` loads correctly (backward compat — tasks without `notes` field work)

- [ ] **Step 11: Commit**

```bash
cd /Users/modi/R&D/MedCare
git add tracker/index.html
git commit -m "feat: redesign tracker — Clean Medical theme, quick-add, slide-over panel, notes"
```
