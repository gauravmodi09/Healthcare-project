# MedCare — Git Branching Strategy

> **For all contributors: human developers, Claude, Antigravity, and any other AI agents.**

---

## Branch Structure

```
main                          ← production-ready, always stable
  └── develop                 ← integration branch, latest working code
       ├── feature/xxx        ← new features
       ├── fix/xxx            ← bug fixes
       └── chore/xxx          ← docs, refactors, config changes
```

---

## Rules

### 1. Never push directly to `main`
All changes reach `main` through a **Pull Request from `develop`** only.

### 2. Never push directly to `develop`
All changes reach `develop` through a **Pull Request from a feature/fix/chore branch**.

### 3. Branch naming convention

| Type | Pattern | Example |
|------|---------|---------|
| New feature | `feature/<short-description>` | `feature/ai-chat-streaming` |
| Bug fix | `fix/<short-description>` | `fix/dose-log-crash` |
| Docs/config/refactor | `chore/<short-description>` | `chore/update-readme` |

**Naming rules:**
- All lowercase
- Use hyphens (`-`) not underscores
- Keep it short (2–4 words max)
- No ticket numbers unless we adopt a tracker

### 4. Branch lifecycle

```
1. Create branch from `develop`     → git checkout develop && git pull
2. Do your work                     → git checkout -b feature/my-feature
3. Commit with clear messages       → git commit -m "feat: add chat bubbles"
4. Push branch                      → git push origin feature/my-feature
5. Open PR to `develop`             → Review → Merge → Delete branch
6. Periodically merge develop→main  → When develop is stable and tested
```

---

## Commit Message Format

```
<type>: <short description>

<optional body — what and why, not how>
```

| Type | When to use |
|------|-------------|
| `feat:` | New feature or capability |
| `fix:` | Bug fix |
| `refactor:` | Code restructure, no behavior change |
| `docs:` | Documentation only |
| `chore:` | Build, config, dependencies |
| `test:` | Adding or updating tests |

**Examples:**
```
feat: add treatment timeline with progress bar
fix: resolve crash when episode has no medicines
refactor: extract chat bubble into reusable component
docs: add branching strategy guide
```

---

## Instructions for AI Agents (Claude, Antigravity, etc.)

When an AI agent is asked to implement something:

```bash
# 1. Always start from latest develop
git checkout develop
git pull origin develop

# 2. Create a properly named branch
git checkout -b feature/ai-chat-streaming

# 3. Make changes and commit with conventional messages
git add -A
git commit -m "feat: implement AI chat with streaming responses"

# 4. Push the branch (NEVER push to main or develop directly)
git push origin feature/ai-chat-streaming

# 5. Tell the user: "Changes pushed to feature/ai-chat-streaming — ready for PR to develop"
```

> ⚠️ **AI agents must NEVER force push, rebase main, or merge directly into main/develop.**

---

## When to Merge `develop` → `main`

Merge `develop` into `main` when:
- A feature set is complete and tested
- The app builds successfully on the simulator
- Key features have been manually verified
- This is a deliberate release checkpoint

```bash
git checkout main
git pull origin main
git merge develop
git push origin main
```

---

## Quick Reference

```
I want to...                    → Branch from    → Branch name
─────────────────────────────────────────────────────────────
Add a new feature               → develop        → feature/xxx
Fix a bug                       → develop        → fix/xxx
Update docs or config           → develop        → chore/xxx
Release to production           → merge develop  → main
```

---

## Current Repository Setup

**Repo:** [github.com/gauravmodi09/Healthcare-project](https://github.com/gauravmodi09/Healthcare-project)

| Branch | Purpose | Status |
|--------|---------|--------|
| `main` | Stable production code | ✅ Active |
| `develop` | Integration branch | 🔲 To be created |
