import SwiftUI

/// Reusable floating microphone button with voice-to-action parsing.
/// Shows transcribed text and detected action for confirmation.
struct VoiceInputButton: View {

    // MARK: - Callbacks

    /// Called when the user confirms a parsed action.
    var onActionConfirmed: ((VoiceAction) -> Void)?

    /// Called when multiple actions are detected (e.g. dose + symptom).
    var onMultipleActions: (([VoiceAction]) -> Void)?

    // MARK: - State

    @State private var speechService = SpeechService()
    @State private var voiceActionService = VoiceActionService()

    @State private var showTranscription = false
    @State private var parsedActions: [VoiceAction] = []
    @State private var showConfirmation = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var errorMessage: String?

    var body: some View {
        ZStack(alignment: .bottom) {
            // Floating card (transcription + confirmation)
            if showTranscription || showConfirmation {
                floatingCard
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 80)
            }

            // Mic button
            micButton
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showTranscription)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showConfirmation)
        .onChange(of: speechService.transcribedText) { _, newValue in
            if !newValue.isEmpty && !speechService.isRecording {
                processTranscription(newValue)
            }
        }
        .onChange(of: speechService.isRecording) { _, isRecording in
            if !isRecording && !speechService.transcribedText.isEmpty {
                processTranscription(speechService.transcribedText)
            }
        }
        .onAppear {
            speechService.requestAuthorization()
        }
    }

    // MARK: - Mic Button

    private var micButton: some View {
        Button {
            toggleRecording()
        } label: {
            ZStack {
                // Pulse ring when recording
                if speechService.isRecording {
                    Circle()
                        .fill(MCColors.primaryTeal.opacity(0.2))
                        .frame(width: 72, height: 72)
                        .scaleEffect(pulseScale)
                        .onAppear { startPulse() }
                        .onDisappear { pulseScale = 1.0 }

                    Circle()
                        .fill(MCColors.primaryTeal.opacity(0.1))
                        .frame(width: 88, height: 88)
                        .scaleEffect(pulseScale * 0.9)
                }

                Circle()
                    .fill(
                        speechService.isRecording
                            ? MCColors.accentCoral
                            : MCColors.primaryTeal
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: MCColors.primaryTeal.opacity(0.3), radius: 8, y: 4)

                Image(systemName: speechService.isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .accessibilityLabel(speechService.isRecording ? "Stop recording" : "Start voice input")
    }

    // MARK: - Floating Card

    private var floatingCard: some View {
        VStack(spacing: 12) {
            // Error
            if let errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(MCColors.error)
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(MCColors.error)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }

            // Transcription
            if showTranscription && !speechService.transcribedText.isEmpty {
                transcriptionView
            }

            // Recording indicator
            if speechService.isRecording {
                recordingIndicator
            }

            // Confirmation
            if showConfirmation && !parsedActions.isEmpty {
                confirmationView
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(MCColors.cardBackground)
                .shadow(color: .black.opacity(0.15), radius: 16, y: 8)
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Transcription View

    private var transcriptionView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "text.quote")
                    .foregroundStyle(MCColors.textSecondary)
                    .font(.caption)
                Text("You said:")
                    .font(.caption)
                    .foregroundStyle(MCColors.textSecondary)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(MCColors.textTertiary)
                }
            }

            Text(speechService.transcribedText)
                .font(.subheadline)
                .foregroundStyle(MCColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
    }

    // MARK: - Recording Indicator

    private var recordingIndicator: some View {
        HStack(spacing: 8) {
            // Audio level bars
            ForEach(0..<5, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(MCColors.accentCoral)
                    .frame(width: 3, height: barHeight(for: i))
                    .animation(
                        .easeInOut(duration: 0.15),
                        value: speechService.audioLevel
                    )
            }

            Text("Listening...")
                .font(.caption)
                .foregroundStyle(MCColors.accentCoral)
                .fontWeight(.medium)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, parsedActions.isEmpty && errorMessage == nil ? 16 : 0)
    }

    // MARK: - Confirmation View

    private var confirmationView: some View {
        VStack(spacing: 10) {
            ForEach(Array(parsedActions.enumerated()), id: \.offset) { _, action in
                actionRow(action)
            }

            // Action buttons
            HStack(spacing: 12) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(MCColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(MCColors.surface)
                        )
                }

                Button {
                    confirmActions()
                } label: {
                    Text("Confirm")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(MCColors.primaryTeal)
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    private func actionRow(_ action: VoiceAction) -> some View {
        HStack(spacing: 10) {
            Image(systemName: action.icon)
                .font(.body)
                .foregroundStyle(MCColors.primaryTeal)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(MCColors.primaryTeal.opacity(0.12))
                )

            Text(action.displayTitle)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(MCColors.textPrimary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private func toggleRecording() {
        if speechService.isRecording {
            speechService.stopRecording()
        } else {
            // Reset state
            parsedActions = []
            showConfirmation = false
            errorMessage = nil
            showTranscription = true

            do {
                try speechService.startRecording()
            } catch {
                errorMessage = "Could not start recording: \(error.localizedDescription)"
            }
        }
    }

    private func processTranscription(_ text: String) {
        let actions = voiceActionService.parseAllActions(text)
        parsedActions = actions
        showConfirmation = true
    }

    private func confirmActions() {
        if parsedActions.count == 1, let action = parsedActions.first {
            onActionConfirmed?(action)
        } else if parsedActions.count > 1 {
            onMultipleActions?(parsedActions)
        }
        dismiss()
    }

    private func dismiss() {
        showTranscription = false
        showConfirmation = false
        parsedActions = []
        errorMessage = nil
        speechService.transcribedText = ""
    }

    private func startPulse() {
        withAnimation(
            .easeInOut(duration: 0.8)
            .repeatForever(autoreverses: true)
        ) {
            pulseScale = 1.3
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        let base: CGFloat = 6
        let level = CGFloat(speechService.audioLevel)
        // Stagger the bars for a wave effect
        let offset = CGFloat(index) * 0.15
        let adjusted = max(0, min(1, level + offset - 0.3))
        return base + adjusted * 18
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        MCColors.backgroundLight
            .ignoresSafeArea()

        VStack {
            Spacer()

            HStack {
                Spacer()
                VoiceInputButton { action in
                    print("Action confirmed: \(action.displayTitle)")
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
    }
}
