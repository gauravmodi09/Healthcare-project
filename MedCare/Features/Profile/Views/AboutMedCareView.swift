import SwiftUI

struct AboutMedCareView: View {
    @Environment(\.dismiss) private var dismiss

    private let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.sectionSpacing) {
                    // Logo
                    VStack(spacing: MCSpacing.sm) {
                        Image(systemName: "cross.case.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(MCColors.primaryTeal)
                            .padding(.top, MCSpacing.lg)

                        Text("MedCare")
                            .font(MCTypography.title)
                            .foregroundStyle(MCColors.textPrimary)

                        Text("v\(version) (Build \(build))")
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textTertiary)
                    }

                    // Description
                    MCCard {
                        VStack(alignment: .leading, spacing: MCSpacing.sm) {
                            Text("Your Family Health Companion")
                                .font(MCTypography.headline)
                                .foregroundStyle(MCColors.textPrimary)

                            Text("MedCare helps Indian families manage medications, track health, and stay on top of their treatment plans. Built with love for Bharat.")
                                .font(MCTypography.body)
                                .foregroundStyle(MCColors.textSecondary)
                                .lineSpacing(4)
                        }
                    }
                    .padding(.horizontal, MCSpacing.screenPadding)

                    // Features
                    MCCard {
                        VStack(alignment: .leading, spacing: MCSpacing.sm) {
                            Text("Key Features")
                                .font(MCTypography.headline)
                                .foregroundStyle(MCColors.textPrimary)

                            featureRow(icon: "pills.fill", text: "Smart medication tracking")
                            featureRow(icon: "bell.fill", text: "Dose reminders & nudges")
                            featureRow(icon: "heart.text.square.fill", text: "Health score & insights")
                            featureRow(icon: "sparkles", text: "AI-powered health companion")
                            featureRow(icon: "person.3.fill", text: "Family profile management")
                            featureRow(icon: "doc.text.fill", text: "Prescription upload & OCR")
                        }
                    }
                    .padding(.horizontal, MCSpacing.screenPadding)

                    // Links
                    VStack(spacing: 0) {
                        linkRow(icon: "globe", title: "Website", url: "https://medcare.app")
                        Divider().padding(.leading, 60)
                        linkRow(icon: "envelope.fill", title: "Contact Support", url: "mailto:support@medcare.app")
                        Divider().padding(.leading, 60)
                        linkRow(icon: "doc.text", title: "Terms of Use", url: "https://medcare.app/terms")
                        Divider().padding(.leading, 60)
                        linkRow(icon: "hand.raised.fill", title: "Privacy Policy", url: "https://medcare.app/privacy")
                    }
                    .background(MCColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
                    .padding(.horizontal, MCSpacing.screenPadding)

                    Text("Made in India 🇮🇳")
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textTertiary)
                        .padding(.bottom, MCSpacing.lg)
                }
                .padding(.vertical, MCSpacing.md)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(MCColors.primaryTeal)
                }
            }
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: MCSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(MCColors.primaryTeal)
                .frame(width: 24)
            Text(text)
                .font(MCTypography.body)
                .foregroundStyle(MCColors.textSecondary)
        }
    }

    private func linkRow(icon: String, title: String, url: String) -> some View {
        Button {
            if let linkURL = URL(string: url) {
                UIApplication.shared.open(linkURL)
            }
        } label: {
            HStack(spacing: MCSpacing.sm) {
                Image(systemName: icon)
                    .foregroundStyle(MCColors.primaryTeal)
                    .font(.system(size: 15))
                    .frame(width: 32, height: 32)
                    .background(MCColors.primaryTeal.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))

                Text(title)
                    .font(MCTypography.body)
                    .foregroundStyle(MCColors.textPrimary)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(MCColors.textTertiary)
            }
            .padding(.horizontal, MCSpacing.cardPadding)
            .padding(.vertical, MCSpacing.sm)
        }
    }
}
