# MedCare: Complete App Design Specification

All screens generated via **Google Stitch MCP** using the MedCare design system: Deep Teal `#0A7E8C`, Coral `#FF6B6B`, Off-White `#F7F9FC`, Inter font field.

---

## Flow 1: Onboarding (< 60 seconds)

````carousel
### 1. Splash Screen
Branding-only screen. Deep teal gradient, health shield logo, tagline.

![Splash Screen](/Users/modi/R&D/MedCare/docs/screen_01_splash.png)
<!-- slide -->
### 2. Phone Login
Phone number entry with Indian `+91` country code selector. Single CTA: "Send OTP".

![Phone Login](/Users/modi/R&D/MedCare/docs/screen_02_phone_login.png)
<!-- slide -->
### 3. OTP Verification
6-digit code entry. Auto-focus, countdown timer, resend link.

![OTP Verification](/Users/modi/R&D/MedCare/docs/screen_03_otp.png)
<!-- slide -->
### 4. Profile Setup
Name, Age, Gender. Medical conditions are optional (lazy collection per PRD).

![Profile Setup](/Users/modi/R&D/MedCare/docs/screen_04_profile.png)
````

---

## Flow 2: The "Magic" Loop (Upload → Confirm → Plan)

````carousel
### 5. Home Dashboard
Two-door CTA: "Consult a Doctor" (v3) + "Upload Prescription" (v1 active). Active episode card below.

![Home Dashboard](/Users/modi/R&D/MedCare/docs/stitch_home.png)
<!-- slide -->
### 6. Upload Prescription
Dashed upload area. Camera, Gallery, PDF options. Tip for medicine photo.

![Upload Prescription](/Users/modi/R&D/MedCare/docs/screen_05_upload.png)
<!-- slide -->
### 7. Prescription Confirmation (Safety Critical)
Side-by-side: original image + extracted data. Amber warning on low-confidence fields. Explicit "Confirm" required.

![Prescription Confirmation](/Users/modi/R&D/MedCare/docs/stitch_confirmation.png)
````

---

## Flow 3: Episode Management (4-Tab Interface)

````carousel
### 8. Plan Tab
Medicines list with edit icons, non-medicine tasks with due dates, follow-up appointment card.

![Episode Detail - Plan](/Users/modi/R&D/MedCare/docs/screen_06_episode_plan.png)
<!-- slide -->
### 9. Reminders Tab
Chronological timeline. Past doses (green ✓), current dose (teal highlight with action buttons), upcoming (greyed).

![Reminders](/Users/modi/R&D/MedCare/docs/screen_07_reminders.png)
<!-- slide -->
### 10. Symptoms Tab
Selectable symptom chips, severity slider (1-5), free-text notes. Daily check-in card.

![Symptom Logger](/Users/modi/R&D/MedCare/docs/screen_08_symptoms.png)
<!-- slide -->
### 11. History Tab
87% adherence ring, 7-day bar chart, recent activity log, PDF export button.

![Adherence History](/Users/modi/R&D/MedCare/docs/screen_09_history.png)
````

---

## Screen Inventory

| # | Screen | Flow | Status |
|---|---|---|---|
| 1 | Splash | Onboarding | ✅ Designed |
| 2 | Phone Login | Onboarding | ✅ Designed |
| 3 | OTP Verification | Onboarding | ✅ Designed |
| 4 | Profile Setup | Onboarding | ✅ Designed |
| 5 | Home Dashboard | Magic Loop | ✅ Designed |
| 6 | Upload Prescription | Magic Loop | ✅ Designed |
| 7 | Confirmation | Magic Loop | ✅ Designed |
| 8 | Episode Plan Tab | Episode Mgmt | ✅ Designed |
| 9 | Reminders Tab | Episode Mgmt | ✅ Designed |
| 10 | Symptom Logger | Episode Mgmt | ✅ Designed |
| 11 | Adherence History | Episode Mgmt | ✅ Designed |
