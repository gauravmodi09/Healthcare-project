# Contributing to MedCare

Thank you for your interest in contributing to MedCare! This document provides guidelines for contributing to the project.

## 🌿 Branch Strategy

| Branch | Purpose |
|---|---|
| `main` | Production-ready code |
| `develop` | Integration branch for features |
| `feature/<name>` | Individual feature development |
| `bugfix/<name>` | Bug fixes |

## 📝 Commit Convention

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add prescription upload screen
fix: correct OTP timer countdown
docs: update API endpoint documentation
chore: update dependencies
refactor: restructure episode repository
```

## 🔄 Pull Request Process

1. Create a feature branch from `develop`
2. Make your changes with clear, descriptive commits
3. Ensure all tests pass
4. Open a PR targeting `develop`
5. Request review from at least one team member

## 📁 Project Structure

- **`ios/`** — SwiftUI frontend code
- **`backend/`** — Node.js API code
- **`docs/`** — Product, architecture, and design documentation

## ⚠️ Important Rules

- **Never** bypass the Human-in-the-Loop (HITL) safety gate for AI extraction
- **Always** encrypt health data in transit (TLS 1.3) and at rest (AES-256)
- **Always** run the test suite before submitting a PR
