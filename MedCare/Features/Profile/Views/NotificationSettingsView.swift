import SwiftUI

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("mc_dose_reminders") private var doseReminders = true
    @AppStorage("mc_refill_reminders") private var refillReminders = true
    @AppStorage("mc_health_tips") private var healthTips = true
    @AppStorage("mc_weekly_report") private var weeklyReport = true
    @AppStorage("mc_reminder_minutes_before") private var reminderMinutesBefore = 5

    var body: some View {
        NavigationStack {
            List {
                Section("Medication Reminders") {
                    Toggle("Dose Reminders", isOn: $doseReminders)
                    Toggle("Refill Alerts", isOn: $refillReminders)

                    if doseReminders {
                        Picker("Remind Before", selection: $reminderMinutesBefore) {
                            Text("At time").tag(0)
                            Text("5 min before").tag(5)
                            Text("10 min before").tag(10)
                            Text("15 min before").tag(15)
                            Text("30 min before").tag(30)
                        }
                    }
                }

                Section("Health Updates") {
                    Toggle("Daily Health Tips", isOn: $healthTips)
                    Toggle("Weekly Progress Report", isOn: $weeklyReport)
                }

                Section {
                    Button("Open System Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .foregroundStyle(MCColors.primaryTeal)
                } footer: {
                    Text("To change notification sounds or badges, go to System Settings > MedCare.")
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(MCColors.primaryTeal)
                }
            }
        }
    }
}
