import SwiftUI
import SwiftData

struct DataDeletionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DataService.self) private var dataService
    @Environment(AuthService.self) private var authService
    @Environment(ConsentService.self) private var consentService
    @Query private var users: [User]

    let profile: UserProfile
    let exportService: ExportService

    @State private var showExportSheet = false
    @State private var exportURL: URL?
    @State private var showDeleteAccountConfirm = false
    @State private var showDeleteProfileConfirm = false
    @State private var deleteAccountConfirmText = ""

    private var currentUser: User? { users.first }

    var body: some View {
        ScrollView {
            VStack(spacing: MCSpacing.sectionSpacing) {
                // Warning Header
                warningHeader

                // Data Summary
                dataSummarySection

                // Export Before Delete
                exportSection

                // Delete Options
                deleteOptionsSection
            }
            .padding(.vertical, MCSpacing.md)
        }
        .background(MCColors.backgroundLight)
        .navigationTitle("Delete My Data")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showExportSheet) {
            if let url = exportURL {
                ShareSheetView(items: [url])
            }
        }
        .alert("Delete All Account Data", isPresented: $showDeleteAccountConfirm) {
            TextField("Type DELETE to confirm", text: $deleteAccountConfirmText)
            Button("Cancel", role: .cancel) {
                deleteAccountConfirmText = ""
            }
            Button("Delete Everything", role: .destructive) {
                if deleteAccountConfirmText == "DELETE" {
                    performFullDeletion()
                }
                deleteAccountConfirmText = ""
            }
        } message: {
            Text("This will permanently delete your account, all profiles, medications, dose logs, symptoms, documents, and cached data. This cannot be undone. Type DELETE to confirm.")
        }
        .alert("Delete Profile Data", isPresented: $showDeleteProfileConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete Profile", role: .destructive) {
                performProfileDeletion()
            }
        } message: {
            Text("This will delete all data for \(profile.name) including episodes, medications, dose logs, symptoms, and documents. Your account and other profiles will be kept.")
        }
    }

    // MARK: - Warning Header

    private var warningHeader: some View {
        MCCard {
            VStack(spacing: MCSpacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(MCColors.error)

                Text("Data Deletion")
                    .font(MCTypography.title2)
                    .foregroundStyle(MCColors.textPrimary)

                Text("Under DPDPA 2023, you have the right to erase your personal data. Please review what will be deleted before proceeding.")
                    .font(MCTypography.subheadline)
                    .foregroundStyle(MCColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Data Summary

    private var dataSummarySection: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            Text("Data that will be deleted")
                .font(MCTypography.headline)
                .foregroundStyle(MCColors.textPrimary)
                .padding(.horizontal, MCSpacing.screenPadding)

            VStack(spacing: 0) {
                deletionItem(
                    icon: "person.fill",
                    title: "Profile Information",
                    detail: "Name, age, gender, blood group, conditions, allergies",
                    color: MCColors.primaryTeal
                )

                Divider().padding(.leading, 60)

                deletionItem(
                    icon: "heart.text.clipboard.fill",
                    title: "Episodes",
                    detail: "\(profile.episodes.count) episode(s) with diagnoses and notes",
                    color: MCColors.accentCoral
                )

                Divider().padding(.leading, 60)

                deletionItem(
                    icon: "pills.fill",
                    title: "Medications",
                    detail: "\(profile.episodes.flatMap { $0.medicines }.count) medicine(s) with schedules",
                    color: MCColors.primaryTeal
                )

                Divider().padding(.leading, 60)

                deletionItem(
                    icon: "checkmark.circle.fill",
                    title: "Dose Logs",
                    detail: "\(profile.episodes.flatMap { $0.medicines }.flatMap { $0.doseLogs }.count) dose record(s)",
                    color: MCColors.success
                )

                Divider().padding(.leading, 60)

                deletionItem(
                    icon: "waveform.path.ecg",
                    title: "Symptom Logs",
                    detail: "\(profile.episodes.flatMap { $0.symptomLogs }.count) symptom record(s)",
                    color: MCColors.warning
                )

                Divider().padding(.leading, 60)

                deletionItem(
                    icon: "doc.text.fill",
                    title: "Documents",
                    detail: "\(profile.episodes.flatMap { $0.images }.count) document(s) and images",
                    color: MCColors.info
                )

                Divider().padding(.leading, 60)

                deletionItem(
                    icon: "checklist",
                    title: "Care Tasks",
                    detail: "\(profile.episodes.flatMap { $0.tasks }.count) task(s)",
                    color: MCColors.textSecondary
                )
            }
            .background(MCColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
            .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
            .padding(.horizontal, MCSpacing.screenPadding)
        }
    }

    private func deletionItem(icon: String, title: String, detail: String, color: Color) -> some View {
        HStack(spacing: MCSpacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.system(size: 15))
                .frame(width: 32, height: 32)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))

            VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                Text(title)
                    .font(MCTypography.subheadline)
                    .foregroundStyle(MCColors.textPrimary)

                Text(detail)
                    .font(MCTypography.caption)
                    .foregroundStyle(MCColors.textSecondary)
            }

            Spacer()
        }
        .padding(.horizontal, MCSpacing.cardPadding)
        .padding(.vertical, MCSpacing.sm)
    }

    // MARK: - Export Section

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            Text("Export before deleting")
                .font(MCTypography.headline)
                .foregroundStyle(MCColors.textPrimary)
                .padding(.horizontal, MCSpacing.screenPadding)

            MCSecondaryButton("Export My Data First", icon: "square.and.arrow.up") {
                if let url = exportService.exportAllData(for: profile) {
                    exportURL = url
                    showExportSheet = true
                }
            }
            .padding(.horizontal, MCSpacing.screenPadding)
        }
    }

    // MARK: - Delete Options

    private var deleteOptionsSection: some View {
        VStack(spacing: MCSpacing.sm) {
            // Delete Profile Data Only (if multiple profiles exist)
            if let user = currentUser, user.profiles.count > 1 {
                Button {
                    showDeleteProfileConfirm = true
                } label: {
                    HStack(spacing: MCSpacing.sm) {
                        Image(systemName: "person.badge.minus")
                            .foregroundStyle(MCColors.warning)
                            .font(.system(size: 16, weight: .semibold))

                        VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                            Text("Delete Profile Data Only")
                                .font(MCTypography.headline)
                                .foregroundStyle(MCColors.warning)

                            Text("Keep your account, delete \(profile.name)'s data")
                                .font(MCTypography.caption)
                                .foregroundStyle(MCColors.textSecondary)
                        }

                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(MCSpacing.cardPadding)
                    .background(MCColors.warning.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: MCSpacing.cornerRadius)
                            .stroke(MCColors.warning.opacity(0.3), lineWidth: 1)
                    )
                }
            }

            // Delete Account (everything)
            Button {
                showDeleteAccountConfirm = true
            } label: {
                HStack(spacing: MCSpacing.sm) {
                    Image(systemName: "trash.fill")
                        .foregroundStyle(.white)
                        .font(.system(size: 16, weight: .semibold))

                    VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                        Text("Delete Everything")
                            .font(MCTypography.headline)
                            .foregroundStyle(.white)

                        Text("Account, all profiles, and all associated data")
                            .font(MCTypography.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(MCSpacing.cardPadding)
                .background(MCColors.error)
                .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
        .padding(.bottom, MCSpacing.lg)
    }

    // MARK: - Deletion Actions

    private func performFullDeletion() {
        let context = dataService.modelContext

        // Delete all model objects
        try? context.delete(model: Nudge.self)
        try? context.delete(model: ChatMessage.self)
        try? context.delete(model: ChatSession.self)
        try? context.delete(model: DoseLog.self)
        try? context.delete(model: SymptomLog.self)
        try? context.delete(model: CareTask.self)
        try? context.delete(model: EpisodeImage.self)
        try? context.delete(model: Medicine.self)
        try? context.delete(model: Episode.self)
        try? context.delete(model: UserProfile.self)
        try? context.delete(model: User.self)
        dataService.save()

        // Clear all UserDefaults
        if let bundleId = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleId)
        }

        // Clear consent data
        consentService.clearAllConsents()

        // Clear caches
        clearCachedData()

        // Logout
        authService.logout()
    }

    private func performProfileDeletion() {
        let context = dataService.modelContext

        // Delete all episodes and their cascade data for this profile
        for episode in profile.episodes {
            context.delete(episode)
        }

        // Remove profile from user
        if let user = profile.user {
            user.profiles.removeAll { $0.id == profile.id }

            // Activate another profile if this was active
            if profile.isActive, let nextProfile = user.profiles.first {
                nextProfile.isActive = true
            }
        }

        context.delete(profile)
        dataService.save()
        dismiss()
    }

    private func clearCachedData() {
        // Clear URL cache
        URLCache.shared.removeAllCachedResponses()

        // Clear temp files
        let tempDir = FileManager.default.temporaryDirectory
        if let files = try? FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil) {
            for file in files {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
