# MedCare UI Design Mockups

This document contains the Google Stitch MCP AI-generated high-fidelity design mockups for the core screens of the MedCare iOS app. These designs establish the visual language, typography, and color palette that will be used during the SwiftUI implementation phase.

## Design System Foundations
- **Primary Color:** Deep Teal/Medical Blue (`#0A7E8C` → `#3EC6C8` gradient)
- **Accent Color:** Warm Coral (`#FF6B6B`) for primary Call to Actions
- **Warning Color:** Amber (`#F5A623`) — used strictly for low-confidence AI extraction flags
- **Success Color:** Green (`#34C759`) — used for "Verified from packaging" badges
- **Background:** Off-white (`#F7F9FC`) surfaces with subtle drop shadows to create depth
- **Corners:** High border radius (rounded) for a modern, friendly medical feel
- **Language:** English-only

---

## 1. Home Screen (Dashboard)
The main entry point for the user after onboarding.

**Key Elements:**
- Profile switcher at the top (Caregiver feature).
- Two primary "Doors": **Consult a Doctor** (v3 placeholder) and **Upload Prescription** (v1 Core).
- Active episode tracker showing the current status of the user's care plan (e.g., *Fever & Cough*).

![MedCare Home Screen Mockup (Google Stitch)](/Users/modi/.gemini/antigravity/brain/5704d3f7-5d11-421c-bf15-e327bd036062/stitch_home.png)

---

## 2. Prescription Capture Screen (Step 1 of Dual-Capture)
First step of the core upload flow. User photographs the doctor's prescription.

**Key Elements:**
- Camera viewfinder with alignment guide overlay
- Options: Camera (default), Gallery, PDF import
- Header text: "Step 1: Photograph your prescription"
- Subtext: "This helps us understand your doctor's instructions"
- "Next: Scan your medicines" button after capture

---

## 3. Medicine Scan Screen (Step 2 of Dual-Capture — NEW CORE SCREEN)
The key differentiator for the India market. After capturing the prescription, the user photographs each medicine they purchased.

**Key Elements:**
- Header text: "Now photograph each medicine you bought"
- Guide image showing an example medicine strip/box with printed text highlighted
- Grid layout of captured medicine photos with "+" button to add more (1-10 photos)
- Each thumbnail shows a checkmark overlay once captured
- Bottom section: "I don't have medicines yet" skip link (falls back to prescription-only mode with a warning that accuracy will be lower)
- Primary CTA: "Upload & Extract" (enabled when at least 1 medicine photo is added)
- Progress indicator: "3 medicines photographed"

**Design Notes:**
- This screen should feel guided and simple — many users will be first-time smartphone camera users
- The guide image is critical for showing exactly what to photograph (the printed side of the strip/box, not the pills themselves)
- Consider adding a brief animation showing the camera pointing at a medicine box

---

## 4. Upload Progress Screen
Shows progress while images are being compressed and uploaded to S3, then extracted by AI.

**Key Elements:**
- Per-image upload progress bars (prescription + each medicine photo)
- Overall progress indicator
- "Analysing your medicines..." animation during GPT-4V extraction phase
- Handles network interruption gracefully with "Resume" button
- Estimated time remaining (optimized for Indian 3G/4G speeds)

---

## 5. Prescription Confirmation Screen (Safety Critical)
The most critical screen in the app. This appears after the backend (GPT-4 Vision + Stitch MCP) returns the cross-referenced extraction from both prescription and medicine photos.

**Key Elements:**
- **Image Gallery:** Scrollable thumbnails of all uploaded images (prescription + medicine photos) at the top.
- **Extracted Medicine Cards:** Each medicine is an editable card showing:
  - Brand name + generic name (from packaging)
  - Strength + dosage form (from packaging)
  - Frequency + duration (from prescription)
  - Timing instructions (from prescription)
  - Manufacturer + expiry date (from packaging)
  - MRP in INR (from packaging)
- **Source Attribution Badges:**
  - Green badge: `"✓ From packaging"` — fields extracted from printed medicine photos (high confidence)
  - Grey badge: `"From prescription"` — fields extracted from handwritten prescription (variable confidence)
- **Amber Warning System:** If any field has `confidence_score < 0.7`, highlighted in amber with `⚠` icon prompting manual verification.
- **Medicine Photo Thumbnail:** Each card shows a small thumbnail of the packaging photo it was sourced from, so the user can visually verify.
- **"Needs Your Input" Section:** If the AI found prescription entries that couldn't be matched to any medicine photo, they appear here with:
  - Raw extracted text from prescription
  - "Add medicine photo" button (to photograph the missing medicine)
  - "Enter manually" button (to type in the details)
- **Medical Disclaimer:** Always visible: *"Please verify all details with your doctor's prescription. This app does not provide medical advice."*
- **Primary CTA:** "Confirm & Create Plan" — disabled until all medicines are explicitly confirmed.

![MedCare Confirmation Screen Mockup (Google Stitch)](/Users/modi/.gemini/antigravity/brain/5704d3f7-5d11-421c-bf15-e327bd036062/stitch_confirmation.png)
