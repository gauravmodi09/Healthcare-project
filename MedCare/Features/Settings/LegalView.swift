import SwiftUI

struct LegalView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: LegalTab = .terms

    enum LegalTab: String, CaseIterable {
        case terms = "Terms of Service"
        case privacy = "Privacy Policy"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Legal", selection: $selectedTab) {
                    ForEach(LegalTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, MCSpacing.screenPadding)
                .padding(.vertical, MCSpacing.sm)

                ScrollView {
                    VStack(alignment: .leading, spacing: MCSpacing.lg) {
                        switch selectedTab {
                        case .terms:
                            termsContent
                        case .privacy:
                            privacyContent
                        }
                    }
                    .padding(.horizontal, MCSpacing.screenPadding)
                    .padding(.vertical, MCSpacing.md)
                }
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Legal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(MCColors.primaryTeal)
                }
            }
        }
    }

    // MARK: - Terms of Service

    private var termsContent: some View {
        VStack(alignment: .leading, spacing: MCSpacing.md) {
            legalHeader("Terms of Service", lastUpdated: "March 2026")

            legalSection(title: "1. Nature of Service") {
                Text("MedCare is a health tracking and medication management tool designed to help users organize their health information. MedCare is NOT a medical device, does NOT provide medical advice, and should NOT be used as a substitute for professional medical consultation, diagnosis, or treatment.")
            }

            legalSection(title: "2. Professional Medical Advice") {
                Text("Users must always consult qualified healthcare professionals for any medical decisions, including but not limited to starting, stopping, or modifying any medication regimen. The information displayed in MedCare is for organizational purposes only.")
            }

            legalSection(title: "3. Data Storage") {
                Text("All health data entered into MedCare is stored locally on your device by default. Data is only transmitted to external services (such as ABDM or cloud backup) when you explicitly opt in and provide consent. You retain full control over your data at all times.")
            }

            legalSection(title: "4. AI-Powered Features") {
                Text("MedCare uses artificial intelligence to extract prescription information, provide health insights, and offer suggestions. These AI features provide convenience-based suggestions only and are NOT diagnoses, medical opinions, or treatment recommendations. AI outputs should always be verified by the user and their healthcare provider.")
            }

            legalSection(title: "5. User Responsibility") {
                Text("Users are solely responsible for the accuracy of all data entered into MedCare, including medication names, dosages, frequencies, and schedules. MedCare is not liable for any adverse outcomes resulting from incorrect data entry or reliance on AI-extracted information without verification.")
            }

            legalSection(title: "6. No Warranty") {
                Text("MedCare is provided \"as is\" and \"as available\" without any warranties of any kind, either express or implied, including but not limited to implied warranties of merchantability, fitness for a particular purpose, and non-infringement. We do not warrant that the service will be uninterrupted, timely, secure, or error-free.")
            }

            legalSection(title: "7. Limitation of Liability") {
                Text("In no event shall MedCare, its developers, or affiliates be liable for any indirect, incidental, special, consequential, or punitive damages, including without limitation loss of data, health complications, or other intangible losses arising from the use of or inability to use the service.")
            }

            legalSection(title: "8. Changes to Terms") {
                Text("We reserve the right to modify these terms at any time. Continued use of MedCare after changes constitutes acceptance of the updated terms. Users will be notified of significant changes through the app.")
            }
        }
    }

    // MARK: - Privacy Policy

    private var privacyContent: some View {
        VStack(alignment: .leading, spacing: MCSpacing.md) {
            legalHeader("Privacy Policy", lastUpdated: "March 2026")

            legalSection(title: "1. Data We Collect") {
                VStack(alignment: .leading, spacing: MCSpacing.xs) {
                    bulletPoint("Health data: medications, dosages, schedules, adherence logs")
                    bulletPoint("Vitals: blood pressure, blood glucose, weight, temperature")
                    bulletPoint("Symptoms and mood tracking entries")
                    bulletPoint("Medical documents and prescription images (stored locally)")
                    bulletPoint("Profile information: name, age, blood group, allergies")
                    bulletPoint("Device information for crash reporting (anonymized)")
                }
            }

            legalSection(title: "2. Data Storage & Security") {
                VStack(alignment: .leading, spacing: MCSpacing.xs) {
                    Text("All health data is stored on-device by default using encrypted local storage. We use Apple's data protection APIs to ensure your data is encrypted at rest. No health data is transmitted to our servers unless you explicitly opt in to cloud sync or data sharing features.")
                }
            }

            legalSection(title: "3. Third-Party Sharing") {
                VStack(alignment: .leading, spacing: MCSpacing.xs) {
                    Text("Your health data is never shared with third parties without your explicit consent. Data may be shared in the following scenarios, only with your prior authorization:")
                        .padding(.bottom, MCSpacing.xxs)
                    bulletPoint("With your designated doctors via the Doctor Dashboard feature")
                    bulletPoint("With ABDM (Ayushman Bharat Digital Mission) if you link your ABHA ID")
                    bulletPoint("Export to PDF or other formats initiated by you")
                }
            }

            legalSection(title: "4. Data Retention") {
                Text("Your data is retained on your device until you choose to delete it. You can delete individual records, entire episodes, or all data from the Settings menu. Upon account deletion, all locally stored data is permanently erased.")
            }

            legalSection(title: "5. Children's Privacy") {
                Text("MedCare can be used to manage health data for children under 18, but only under the supervision of a parent or legal guardian. Parental consent is required for any data processing related to minors. Parents/guardians are responsible for managing their children's profiles.")
            }

            legalSection(title: "6. DPDPA 2023 Compliance") {
                VStack(alignment: .leading, spacing: MCSpacing.xs) {
                    Text("In compliance with India's Digital Personal Data Protection Act, 2023, you have the following rights:")
                        .padding(.bottom, MCSpacing.xxs)
                    bulletPoint("Right to Access: View all data stored about you at any time")
                    bulletPoint("Right to Correction: Edit or update any personal data")
                    bulletPoint("Right to Erasure: Delete all your data permanently")
                    bulletPoint("Right to Data Portability: Export your data in standard formats")
                    bulletPoint("Right to Withdraw Consent: Revoke any previously given consent")
                    bulletPoint("Right to Grievance Redressal: Contact us for any data-related concerns")
                }
            }

            legalSection(title: "7. Contact Us") {
                VStack(alignment: .leading, spacing: MCSpacing.xs) {
                    Text("For any privacy-related questions, data requests, or concerns, please contact us:")
                        .padding(.bottom, MCSpacing.xxs)
                    HStack(spacing: MCSpacing.xs) {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(MCColors.primaryTeal)
                        Text("support@medcare.app")
                            .font(MCTypography.bodyMedium)
                            .foregroundStyle(MCColors.primaryTeal)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func legalHeader(_ title: String, lastUpdated: String) -> some View {
        MCCard {
            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                Text(title)
                    .font(MCTypography.title2)
                    .foregroundStyle(MCColors.textPrimary)
                HStack(spacing: MCSpacing.xs) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("Last updated: \(lastUpdated)")
                        .font(MCTypography.caption)
                }
                .foregroundStyle(MCColors.textTertiary)
            }
        }
    }

    private func legalSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        MCCard {
            VStack(alignment: .leading, spacing: MCSpacing.sm) {
                Text(title)
                    .font(MCTypography.headline)
                    .foregroundStyle(MCColors.textPrimary)
                content()
                    .font(MCTypography.body)
                    .foregroundStyle(MCColors.textSecondary)
                    .lineSpacing(3)
            }
        }
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: MCSpacing.xs) {
            Circle()
                .fill(MCColors.primaryTeal)
                .frame(width: 5, height: 5)
                .padding(.top, 7)
            Text(text)
                .font(MCTypography.body)
                .foregroundStyle(MCColors.textSecondary)
        }
    }
}
