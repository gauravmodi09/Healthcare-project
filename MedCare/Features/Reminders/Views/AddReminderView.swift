import SwiftUI
import SwiftData

struct AddReminderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]

    @State private var title = ""
    @State private var notes = ""
    @State private var reminderDate = Date()
    @State private var repeatOption: ReminderRepeat = .never
    @State private var isSaving = false

    private var activeProfile: UserProfile? { users.first?.activeProfile }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && reminderDate > Date()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.lg) {
                    // MARK: - Title
                    titleSection

                    // MARK: - Notes
                    notesSection

                    // MARK: - Quick Presets
                    quickPresetsSection

                    // MARK: - Date & Time Picker
                    dateTimeSection

                    // MARK: - Repeat
                    repeatSection

                    // MARK: - Save Button
                    MCPrimaryButton("Set Reminder", icon: "bell.badge.fill", isLoading: isSaving) {
                        saveReminder()
                    }
                    .disabled(!canSave)
                    .opacity(canSave ? 1.0 : 0.5)
                    .padding(.horizontal, MCSpacing.screenPadding)
                    .padding(.top, MCSpacing.sm)
                }
                .padding(.vertical, MCSpacing.md)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("New Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(MCColors.primaryTeal)
                }
            }
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: MCSpacing.xs) {
            Text("What to remind?")
                .font(MCTypography.headline)
                .foregroundStyle(MCColors.textPrimary)
                .padding(.horizontal, MCSpacing.screenPadding)

            MCTextField(label: "Reminder title", icon: "pencil", text: $title)
                .padding(.horizontal, MCSpacing.screenPadding)
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: MCSpacing.xs) {
            Text("Notes (optional)")
                .font(MCTypography.subheadline)
                .foregroundStyle(MCColors.textSecondary)
                .padding(.horizontal, MCSpacing.screenPadding)

            MCTextField(label: "Add notes...", icon: "note.text", text: $notes)
                .padding(.horizontal, MCSpacing.screenPadding)
        }
    }

    // MARK: - Quick Presets

    private var quickPresetsSection: some View {
        VStack(alignment: .leading, spacing: MCSpacing.xs) {
            Text("Quick set")
                .font(MCTypography.subheadline)
                .foregroundStyle(MCColors.textSecondary)
                .padding(.horizontal, MCSpacing.screenPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MCSpacing.sm) {
                    presetChip("In 30 min", icon: "clock") {
                        reminderDate = Date().addingTimeInterval(30 * 60)
                    }
                    presetChip("In 1 hour", icon: "clock.fill") {
                        reminderDate = Date().addingTimeInterval(60 * 60)
                    }
                    presetChip("Tomorrow 9 AM", icon: "sunrise") {
                        reminderDate = tomorrowAt(hour: 9, minute: 0)
                    }
                    presetChip("Tomorrow 7 PM", icon: "sunset") {
                        reminderDate = tomorrowAt(hour: 19, minute: 0)
                    }
                }
                .padding(.horizontal, MCSpacing.screenPadding)
            }
        }
    }

    private func presetChip(_ label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack(spacing: MCSpacing.xxs) {
                Image(systemName: icon)
                    .font(.footnote)
                Text(label)
                    .font(MCTypography.caption)
            }
            .foregroundStyle(MCColors.primaryTeal)
            .padding(.horizontal, MCSpacing.sm)
            .padding(.vertical, MCSpacing.xs)
            .background(MCColors.primaryTeal.opacity(0.1))
            .clipShape(Capsule())
        }
    }

    // MARK: - Date & Time Picker

    private var dateTimeSection: some View {
        MCCard {
            VStack(alignment: .leading, spacing: MCSpacing.sm) {
                HStack(spacing: MCSpacing.xs) {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(MCColors.primaryTeal)
                    Text("When")
                        .font(MCTypography.headline)
                        .foregroundStyle(MCColors.textPrimary)
                }

                DatePicker(
                    "Reminder time",
                    selection: $reminderDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .tint(MCColors.primaryTeal)
                .labelsHidden()
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Repeat Section

    private var repeatSection: some View {
        MCCard {
            VStack(alignment: .leading, spacing: MCSpacing.sm) {
                HStack(spacing: MCSpacing.xs) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(MCColors.primaryTeal)
                    Text("Repeat")
                        .font(MCTypography.headline)
                        .foregroundStyle(MCColors.textPrimary)
                }

                HStack(spacing: MCSpacing.xs) {
                    ForEach(ReminderRepeat.allCases, id: \.self) { option in
                        Button {
                            repeatOption = option
                        } label: {
                            Text(option.rawValue)
                                .font(MCTypography.captionBold)
                                .foregroundStyle(repeatOption == option ? .white : MCColors.textSecondary)
                                .padding(.horizontal, MCSpacing.sm)
                                .padding(.vertical, MCSpacing.xs)
                                .background(repeatOption == option ? MCColors.primaryTeal : MCColors.backgroundLight)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Save

    private func saveReminder() {
        guard canSave else { return }
        isSaving = true

        let reminder = CustomReminder(
            title: title.trimmingCharacters(in: .whitespaces),
            notes: notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces),
            reminderTime: reminderDate,
            repeatOption: repeatOption,
            profileId: activeProfile?.id
        )

        modelContext.insert(reminder)
        try? modelContext.save()

        // Schedule notification
        Task {
            await NotificationService.shared.scheduleCustomReminder(
                id: reminder.id,
                title: reminder.title,
                notes: reminder.notes,
                time: reminder.reminderTime,
                repeatOption: repeatOption
            )
            await MainActor.run {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                dismiss()
            }
        }
    }

    // MARK: - Helpers

    private func tomorrowAt(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: tomorrow)!
    }
}
