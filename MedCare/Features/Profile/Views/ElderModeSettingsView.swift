import SwiftUI

/// Settings view for configuring Elder Mode — larger text, simpler UI, high contrast
struct ElderModeSettingsView: View {
    @Environment(\.elderModeService) private var elderMode

    var body: some View {
        List {
            // MARK: - Master Toggle
            Section {
                Toggle(isOn: Bindable(elderMode).isElderModeEnabled) {
                    Label("Elder Mode", systemImage: "accessibility")
                        .font(MCTypography.headline)
                }
                .tint(MCColors.primaryTeal)
            } footer: {
                Text("Enables larger text, bigger touch targets, and a simplified interface for easier use.")
                    .font(MCTypography.footnote)
                    .foregroundStyle(MCColors.textSecondary)
            }

            if elderMode.isElderModeEnabled {
                // MARK: - Font Size
                Section("Text Size") {
                    Picker("Font Size", selection: Bindable(elderMode).fontSize) {
                        ForEach(ElderFontSize.allCases, id: \.self) { size in
                            Label(size.rawValue, systemImage: size.icon)
                                .tag(size)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowSeparator(.hidden)

                    // Live preview
                    VStack(alignment: .leading, spacing: MCSpacing.sm) {
                        Text("Preview")
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textTertiary)
                            .textCase(.uppercase)

                        Text("This is how text will look")
                            .font(elderMode.title)
                            .foregroundStyle(MCColors.textPrimary)

                        Text("Body text and descriptions appear at this size for comfortable reading.")
                            .font(elderMode.body)
                            .foregroundStyle(MCColors.textSecondary)

                        Text("Smaller captions look like this")
                            .font(elderMode.caption)
                            .foregroundStyle(MCColors.textTertiary)
                    }
                    .padding(.vertical, MCSpacing.xs)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contrast(elderMode.highContrastEnabled ? 1.15 : 1.0)
                }

                // MARK: - Display Options
                Section("Display") {
                    Toggle(isOn: Bindable(elderMode).highContrastEnabled) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("High Contrast")
                                    .font(MCTypography.headline)
                                Text("Makes text and icons stand out more")
                                    .font(MCTypography.caption)
                                    .foregroundStyle(MCColors.textSecondary)
                            }
                        } icon: {
                            Image(systemName: "circle.lefthalf.filled")
                        }
                    }
                    .tint(MCColors.primaryTeal)
                }

                // MARK: - Navigation
                Section("Navigation") {
                    Toggle(isOn: Bindable(elderMode).simplifiedNavigationEnabled) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Simplified Navigation")
                                    .font(MCTypography.headline)
                                Text("Fewer menu items, clearer layout")
                                    .font(MCTypography.caption)
                                    .foregroundStyle(MCColors.textSecondary)
                            }
                        } icon: {
                            Image(systemName: "square.grid.2x2")
                        }
                    }
                    .tint(MCColors.primaryTeal)
                }

                // MARK: - Feedback
                Section("Feedback") {
                    Toggle(isOn: Bindable(elderMode).hapticFeedbackEnabled) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Haptic Feedback")
                                    .font(MCTypography.headline)
                                Text("Vibration on button taps for confirmation")
                                    .font(MCTypography.caption)
                                    .foregroundStyle(MCColors.textSecondary)
                            }
                        } icon: {
                            Image(systemName: "hand.tap")
                        }
                    }
                    .tint(MCColors.primaryTeal)
                }
            }
        }
        .navigationTitle("Elder Mode")
        .navigationBarTitleDisplayMode(.large)
        .animation(.easeInOut(duration: 0.25), value: elderMode.isElderModeEnabled)
        .animation(.easeInOut(duration: 0.2), value: elderMode.fontSize)
    }
}

#Preview {
    NavigationStack {
        ElderModeSettingsView()
            .environment(\.elderModeService, ElderModeService())
    }
}
