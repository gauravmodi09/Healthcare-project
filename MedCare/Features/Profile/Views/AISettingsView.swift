import SwiftUI

struct AISettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey: String = LLMConfig.storedGroqAPIKey
    @State private var isKeyVisible = false
    @State private var testResult: (success: Bool, message: String)?
    @State private var isTesting = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.sectionSpacing) {
                    // Header
                    VStack(spacing: MCSpacing.sm) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundStyle(Color(hex: "A78BFA"))
                            .frame(width: 72, height: 72)
                            .background(Color(hex: "A78BFA").opacity(0.12))
                            .clipShape(Circle())

                        Text("AI Chat Settings")
                            .font(MCTypography.title2)
                            .foregroundStyle(MCColors.textPrimary)

                        Text("Configure your Groq API key to enable AI-powered health chat.")
                            .font(MCTypography.subheadline)
                            .foregroundStyle(MCColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, MCSpacing.screenPadding)

                    // API Key Input
                    VStack(alignment: .leading, spacing: MCSpacing.sm) {
                        HStack(spacing: MCSpacing.xs) {
                            Image(systemName: "key.fill")
                                .foregroundStyle(Color(hex: "A78BFA"))
                                .font(.system(size: 14))
                            Text("GROQ API KEY")
                                .font(MCTypography.sectionHeader)
                                .foregroundStyle(MCColors.textSecondary)
                                .kerning(1.2)
                        }

                        MCCard {
                            VStack(alignment: .leading, spacing: MCSpacing.sm) {
                                HStack {
                                    if isKeyVisible {
                                        TextField("gsk_...", text: $apiKey)
                                            .font(.system(.body, design: .monospaced))
                                            .autocorrectionDisabled()
                                            .textInputAutocapitalization(.never)
                                    } else {
                                        SecureField("gsk_...", text: $apiKey)
                                            .font(.system(.body, design: .monospaced))
                                            .autocorrectionDisabled()
                                            .textInputAutocapitalization(.never)
                                    }

                                    Button {
                                        isKeyVisible.toggle()
                                    } label: {
                                        Image(systemName: isKeyVisible ? "eye.slash.fill" : "eye.fill")
                                            .foregroundStyle(MCColors.textTertiary)
                                    }
                                }

                                // Status indicator
                                if LLMConfig.groqAPIKey != nil && !LLMConfig.groqAPIKey!.isEmpty {
                                    HStack(spacing: MCSpacing.xxs) {
                                        Circle()
                                            .fill(MCColors.success)
                                            .frame(width: 8, height: 8)
                                        Text("API key configured")
                                            .font(MCTypography.caption)
                                            .foregroundStyle(MCColors.success)
                                    }
                                } else {
                                    HStack(spacing: MCSpacing.xxs) {
                                        Circle()
                                            .fill(MCColors.warning)
                                            .frame(width: 8, height: 8)
                                        Text("No API key set")
                                            .font(MCTypography.caption)
                                            .foregroundStyle(MCColors.warning)
                                    }
                                }

                                Link(destination: URL(string: "https://console.groq.com")!) {
                                    HStack(spacing: MCSpacing.xxs) {
                                        Image(systemName: "arrow.up.right.square")
                                            .font(.system(size: 12))
                                        Text("Get your free API key at console.groq.com")
                                            .font(MCTypography.caption)
                                    }
                                    .foregroundStyle(MCColors.primaryTeal)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, MCSpacing.screenPadding)

                    // Action buttons
                    VStack(spacing: MCSpacing.sm) {
                        MCPrimaryButton("Save API Key", icon: "checkmark.circle") {
                            LLMConfig.setGroqAPIKey(apiKey)
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                        .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .opacity(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)

                        // Test Connection button
                        Button {
                            testConnection()
                        } label: {
                            HStack(spacing: MCSpacing.xs) {
                                if isTesting {
                                    ProgressView()
                                        .tint(MCColors.primaryTeal)
                                } else {
                                    Image(systemName: "antenna.radiowaves.left.and.right")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                Text("Test Connection")
                                    .font(MCTypography.subheadline)
                            }
                            .foregroundStyle(MCColors.primaryTeal)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, MCSpacing.sm)
                            .background(MCColors.primaryTeal.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
                        }
                        .disabled(isTesting || apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(.horizontal, MCSpacing.screenPadding)

                    // Test result
                    if let result = testResult {
                        MCCard {
                            HStack(spacing: MCSpacing.sm) {
                                Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(result.success ? MCColors.success : MCColors.error)

                                VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                                    Text(result.success ? "Connection Successful" : "Connection Failed")
                                        .font(MCTypography.headline)
                                        .foregroundStyle(MCColors.textPrimary)
                                    Text(result.message)
                                        .font(MCTypography.caption)
                                        .foregroundStyle(MCColors.textSecondary)
                                }
                                Spacer()
                            }
                        }
                        .padding(.horizontal, MCSpacing.screenPadding)
                    }

                    // Clear key
                    if !LLMConfig.storedGroqAPIKey.isEmpty {
                        Button {
                            apiKey = ""
                            LLMConfig.setGroqAPIKey("")
                            testResult = nil
                        } label: {
                            Text("Remove Saved Key")
                                .font(MCTypography.subheadline)
                                .foregroundStyle(MCColors.error)
                        }
                    }
                }
                .padding(.vertical, MCSpacing.md)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("AI Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func testConnection() {
        // Save key first so LLMConfig picks it up
        LLMConfig.setGroqAPIKey(apiKey)
        isTesting = true
        testResult = nil

        Task {
            let result = await LLMConfig.testConnection()
            await MainActor.run {
                testResult = result
                isTesting = false
            }
        }
    }
}

#Preview {
    AISettingsView()
}
