import SwiftUI
import UIKit

// MARK: - Elder Font Size

enum ElderFontSize: String, CaseIterable, Codable {
    case regular = "Regular"
    case large = "Large"
    case extraLarge = "Extra Large"

    var scaleFactor: CGFloat {
        switch self {
        case .regular: 1.0
        case .large: 1.3
        case .extraLarge: 1.6
        }
    }

    var icon: String {
        switch self {
        case .regular: "textformat.size.smaller"
        case .large: "textformat.size"
        case .extraLarge: "textformat.size.larger"
        }
    }
}

// MARK: - Elder Mode Service

/// Manages elder-friendly UI adaptations: larger text, higher contrast, simpler navigation
@Observable
@MainActor
final class ElderModeService {

    // MARK: - Persisted Settings

    var isElderModeEnabled: Bool {
        didSet { UserDefaults.standard.set(isElderModeEnabled, forKey: Keys.enabled) }
    }

    var fontSize: ElderFontSize {
        didSet { UserDefaults.standard.set(fontSize.rawValue, forKey: Keys.fontSize) }
    }

    var highContrastEnabled: Bool {
        didSet { UserDefaults.standard.set(highContrastEnabled, forKey: Keys.highContrast) }
    }

    var simplifiedNavigationEnabled: Bool {
        didSet { UserDefaults.standard.set(simplifiedNavigationEnabled, forKey: Keys.simplifiedNav) }
    }

    var hapticFeedbackEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticFeedbackEnabled, forKey: Keys.hapticFeedback) }
    }

    // MARK: - Init

    init() {
        let defaults = UserDefaults.standard
        self.isElderModeEnabled = defaults.bool(forKey: Keys.enabled)
        self.highContrastEnabled = defaults.bool(forKey: Keys.highContrast)
        self.simplifiedNavigationEnabled = defaults.bool(forKey: Keys.simplifiedNav)

        // Default haptic feedback to true for first launch
        if defaults.object(forKey: Keys.hapticFeedback) == nil {
            self.hapticFeedbackEnabled = true
            defaults.set(true, forKey: Keys.hapticFeedback)
        } else {
            self.hapticFeedbackEnabled = defaults.bool(forKey: Keys.hapticFeedback)
        }

        if let raw = defaults.string(forKey: Keys.fontSize),
           let size = ElderFontSize(rawValue: raw) {
            self.fontSize = size
        } else {
            self.fontSize = .regular
        }
    }

    // MARK: - Font Scaling

    /// Returns the active scale factor (1.0 when elder mode is off)
    var activeScaleFactor: CGFloat {
        isElderModeEnabled ? fontSize.scaleFactor : 1.0
    }

    /// Scale a font when elder mode is active
    func scaled(_ font: Font, size baseSize: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
        let scaledSize = baseSize * activeScaleFactor
        return .system(size: scaledSize, weight: isElderModeEnabled ? bolderWeight(weight) : weight, design: design)
    }

    /// Returns the elder-adapted version of common MCTypography fonts
    var title: Font { scaled(.title, size: 22, weight: .semibold, design: .rounded) }
    var title2: Font { scaled(.title2, size: 20, weight: .semibold, design: .rounded) }
    var headline: Font { scaled(.headline, size: 17, weight: .semibold) }
    var body: Font { scaled(.body, size: 17, weight: .regular) }
    var callout: Font { scaled(.callout, size: 16, weight: .regular) }
    var caption: Font { scaled(.caption, size: 12, weight: .regular) }

    // MARK: - Haptic Feedback

    func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard isElderModeEnabled && hapticFeedbackEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    // MARK: - Helpers

    /// Bump font weight one step bolder for elder mode readability
    private func bolderWeight(_ weight: Font.Weight) -> Font.Weight {
        switch weight {
        case .ultraLight: .light
        case .thin: .regular
        case .light: .regular
        case .regular: .medium
        case .medium: .semibold
        case .semibold: .bold
        case .bold: .heavy
        case .heavy: .black
        default: .bold
        }
    }

    // MARK: - Keys

    private enum Keys {
        static let enabled = "elderMode.enabled"
        static let fontSize = "elderMode.fontSize"
        static let highContrast = "elderMode.highContrast"
        static let simplifiedNav = "elderMode.simplifiedNav"
        static let hapticFeedback = "elderMode.hapticFeedback"
    }
}

// MARK: - Environment Key

private struct ElderModeServiceKey: EnvironmentKey {
    @MainActor static let defaultValue = ElderModeService()
}

extension EnvironmentValues {
    var elderModeService: ElderModeService {
        get { self[ElderModeServiceKey.self] }
        set { self[ElderModeServiceKey.self] = newValue }
    }
}

// MARK: - Elder Mode Adapted View Modifier

struct ElderModeAdaptedModifier: ViewModifier {
    @Environment(\.elderModeService) private var elderMode

    func body(content: Content) -> some View {
        content
            .frame(minHeight: elderMode.isElderModeEnabled ? MCSpacing.touchTargetLarge : MCSpacing.touchTarget)
            .font(elderMode.isElderModeEnabled ? elderMode.body : nil)
            .foregroundStyle(elderMode.isElderModeEnabled && elderMode.highContrastEnabled ? MCColors.textPrimary : MCColors.textPrimary)
            .contrast(elderMode.isElderModeEnabled && elderMode.highContrastEnabled ? 1.15 : 1.0)
    }
}

extension View {
    /// Adapts the view for elder mode: larger touch targets, bolder fonts, optional high contrast
    func elderModeAdapted() -> some View {
        modifier(ElderModeAdaptedModifier())
    }
}
