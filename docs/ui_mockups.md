# MedCare UI Design Mockups

This document contains the Google Stitch MCP AI-generated high-fidelity design mockups for the core screens of the MedCare iOS app. These designs establish the visual language, typography, and color palette that will be used during the SwiftUI implementation phase.

## Design System Foundations
- **Primary Color:** Deep Teal/Medical Blue
- **Accent Color:** Warm Coral (for primary Call to Actions)
- **Warning Color:** Amber (used strictly for low-confidence AI extraction flags)
- **Background:** Off-white surfaces with subtle drop shadows to create depth
- **Corners:** High border radius (rounded) for a modern, friendly medical feel

---

## 1. Home Screen (Dashboard)
The main entry point for the user after onboarding. 

**Key Elements:**
- Profile switcher at the top (Caregiver feature).
- Two primary "Doors": **Consult a Doctor** (v2) and **Upload Prescription** (v1 Core).
- Active episode tracker showing the current status of the user's care plan (e.g., *Fever & Cough*).

![MedCare Home Screen Mockup (Google Stitch)](/Users/modi/.gemini/antigravity/brain/5704d3f7-5d11-421c-bf15-e327bd036062/stitch_home.png)

---

## 2. Prescription Confirmation Screen (Safety Critical)
The most critical screen in the app. This appears immediately after the backend (GPT-4 Vision + Stitch MCP) returns the extracted JSON.

**Key Elements:**
- **Split View:** The uploaded prescription image is shown alongside the extracted data.
- **Editable Fields:** Every extracted data point (Medication, Strength, Dosage, Frequency, Duration) is an editable card.
- **Amber Warning System:** If the AI has a confidence score of `< 0.7`, the field is highlighted in amber with an explicit warning prompting the user to manually verify against the image above.

![MedCare Confirmation Screen Mockup (Google Stitch)](/Users/modi/.gemini/antigravity/brain/5704d3f7-5d11-421c-bf15-e327bd036062/stitch_confirmation.png)
