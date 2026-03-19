import Speech
import AVFoundation

/// Speech-to-text service for AI Chat voice input (MEDCA-007)
@MainActor
class SpeechService: ObservableObject {

    // MARK: - Published Properties

    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var audioLevel: Float = 0.0
    @Published var error: String?

    // MARK: - Private Properties

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-IN"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    // MARK: - Authorization

    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor [weak self] in
                switch status {
                case .authorized:
                    self?.error = nil
                case .denied:
                    self?.error = "Speech recognition permission denied. Please enable it in Settings."
                case .restricted:
                    self?.error = "Speech recognition is restricted on this device."
                case .notDetermined:
                    self?.error = "Speech recognition permission not yet determined."
                @unknown default:
                    self?.error = "Unknown speech recognition authorization status."
                }
            }
        }
    }

    // MARK: - Recording

    func startRecording() throws {
        // Reset state
        stopRecording()
        transcribedText = ""
        error = nil

        guard let speechRecognizer, speechRecognizer.isAvailable else {
            error = "Speech recognizer is not available for English (India)."
            return
        }

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Create recognition request
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true

        // Prefer on-device recognition when available
        if speechRecognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }

        recognitionRequest = request

        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self else { return }

                if let result {
                    self.transcribedText = result.bestTranscription.formattedString

                    if result.isFinal {
                        self.stopRecording()
                    }
                }

                if let error {
                    // Ignore cancellation errors (triggered by stopRecording)
                    let nsError = error as NSError
                    if nsError.domain != "kAFAssistantErrorDomain" || nsError.code != 216 {
                        self.error = error.localizedDescription
                    }
                    self.stopRecording()
                }
            }
        }

        // Install audio tap
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            // Feed audio to recognizer
            self?.recognitionRequest?.append(buffer)

            // Calculate RMS power for waveform visualization
            let level = Self.rmsLevel(from: buffer)
            Task { @MainActor [weak self] in
                self?.audioLevel = level
            }
        }

        audioEngine.prepare()
        try audioEngine.start()

        isRecording = true
    }

    func stopRecording() {
        guard isRecording || audioEngine.isRunning || recognitionTask != nil else { return }

        // Stop audio engine and remove tap
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        // End recognition
        recognitionRequest?.endAudio()
        recognitionRequest = nil

        recognitionTask?.cancel()
        recognitionTask = nil

        isRecording = false
        audioLevel = 0.0

        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Audio Level Calculation

    /// Compute RMS power from an audio buffer, normalized to 0.0 - 1.0.
    private static func rmsLevel(from buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0.0 }

        let channelDataValue = channelData.pointee
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return 0.0 }

        var sum: Float = 0.0
        for i in 0..<frameLength {
            let sample = channelDataValue[i]
            sum += sample * sample
        }

        let rms = sqrtf(sum / Float(frameLength))

        // Convert to a 0-1 range. Typical speech RMS is ~0.01-0.1.
        // Multiply and clamp to get a useful visualization range.
        let normalized = min(max(rms * 5.0, 0.0), 1.0)
        return normalized
    }
}
