import SwiftUI

struct ConsentManagementView: View {
    @Environment(ConsentService.self) private var consentService
    @State private var showAuditLog = false

    var body: some View {
        ScrollView {
            VStack(spacing: MCSpacing.sectionSpacing) {
                // Header
                headerSection

                // Consent Toggles
                consentTogglesSection

                // Last Updated
                lastUpdatedSection

                // Audit Log Button
                auditLogButton
            }
            .padding(.vertical, MCSpacing.md)
        }
        .background(MCColors.backgroundLight)
        .navigationTitle("Manage Consents")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAuditLog) {
            auditLogSheet
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        MCCard {
            VStack(spacing: MCSpacing.sm) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(MCColors.primaryTeal)

                Text("Your Data, Your Control")
                    .font(MCTypography.title2)
                    .foregroundStyle(MCColors.textPrimary)

                Text("Under India's DPDPA 2023, you have the right to control how your personal data is processed. Manage your consents below.")
                    .font(MCTypography.subheadline)
                    .foregroundStyle(MCColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Consent Toggles

    private var consentTogglesSection: some View {
        VStack(spacing: MCSpacing.sm) {
            ForEach(ConsentType.allCases) { type in
                consentToggleCard(type)
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    private func consentToggleCard(_ type: ConsentType) -> some View {
        @Bindable var service = consentService

        return MCCard {
            VStack(alignment: .leading, spacing: MCSpacing.sm) {
                HStack(spacing: MCSpacing.sm) {
                    // Icon
                    Image(systemName: type.icon)
                        .foregroundStyle(type.color)
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 36, height: 36)
                        .background(type.color.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))

                    VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                        HStack(spacing: MCSpacing.xs) {
                            Text(type.title)
                                .font(MCTypography.headline)
                                .foregroundStyle(MCColors.textPrimary)

                            if type.isRequired {
                                Text("Required")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(MCColors.primaryTeal)
                                    .clipShape(Capsule())
                            }
                        }
                    }

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { consentService.isConsentGranted(type) },
                        set: { _ in
                            if !type.isRequired {
                                consentService.toggleConsent(type)
                            }
                        }
                    ))
                    .labelsHidden()
                    .tint(MCColors.primaryTeal)
                    .disabled(type.isRequired)
                }

                Text(type.description)
                    .font(MCTypography.caption)
                    .foregroundStyle(MCColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Last Updated

    private var lastUpdatedSection: some View {
        HStack(spacing: MCSpacing.xs) {
            Image(systemName: "clock")
                .font(.system(size: 12))
                .foregroundStyle(MCColors.textTertiary)

            Text("Last updated: \(consentService.lastUpdated.formatted(date: .abbreviated, time: .shortened))")
                .font(MCTypography.caption)
                .foregroundStyle(MCColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Audit Log

    private var auditLogButton: some View {
        Button {
            showAuditLog = true
        } label: {
            HStack(spacing: MCSpacing.sm) {
                Image(systemName: "list.clipboard")
                    .foregroundStyle(MCColors.info)
                    .font(.system(size: 15))
                    .frame(width: 32, height: 32)
                    .background(MCColors.info.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))

                Text("View Consent History")
                    .font(MCTypography.body)
                    .foregroundStyle(MCColors.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(MCColors.textTertiary)
            }
            .padding(.horizontal, MCSpacing.cardPadding)
            .padding(.vertical, MCSpacing.sm)
            .background(MCColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
            .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        }
        .padding(.horizontal, MCSpacing.screenPadding)
        .padding(.bottom, MCSpacing.lg)
    }

    private var auditLogSheet: some View {
        NavigationStack {
            let entries = consentService.getAuditLog()
            List {
                if entries.isEmpty {
                    ContentUnavailableView(
                        "No History",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Consent changes will appear here.")
                    )
                } else {
                    ForEach(entries) { entry in
                        HStack(spacing: MCSpacing.sm) {
                            Image(systemName: entry.action == "granted" ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(entry.action == "granted" ? MCColors.success : MCColors.error)

                            VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                                if let type = ConsentType(rawValue: entry.consentType) {
                                    Text(type.title)
                                        .font(MCTypography.subheadline)
                                        .foregroundStyle(MCColors.textPrimary)
                                }

                                Text(entry.action.capitalized)
                                    .font(MCTypography.caption)
                                    .foregroundStyle(entry.action == "granted" ? MCColors.success : MCColors.error)
                            }

                            Spacer()

                            Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.textTertiary)
                        }
                    }
                }
            }
            .navigationTitle("Consent History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showAuditLog = false }
                }
            }
        }
    }
}
