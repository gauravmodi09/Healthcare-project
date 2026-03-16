import SwiftUI

/// MedCare Design System — Colors (adaptive light/dark mode)
enum MCColors {
    // MARK: - Primary
    static let primaryTeal = Color(hex: "0A7E8C")
    static let primaryTealLight = Color(hex: "3EC6C8")

    // MARK: - Accent
    static let accentCoral = Color(hex: "FF6B6B")

    // MARK: - Semantic
    static let warning = Color(hex: "F5A623")
    static let success = Color(hex: "34C759")
    static let error = Color(hex: "FF3B30")
    static let info = Color(hex: "007AFF")

    // MARK: - Background (adaptive)
    static let backgroundLight = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(Color(hex: "1A1D29"))
                : UIColor(Color(hex: "F7F9FC"))
        }
    )
    static let backgroundDark = Color(hex: "1A1D29")

    static let cardBackground = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(Color(hex: "252836"))
                : .white
        }
    )
    static let cardBackgroundDark = Color(hex: "252836")

    // MARK: - Text (adaptive)
    static let textPrimary = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(Color(hex: "F1F5F9"))
                : UIColor(Color(hex: "1A1D29"))
        }
    )
    static let textSecondary = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(Color(hex: "9CA3AF"))
                : UIColor(Color(hex: "6B7280"))
        }
    )
    static let textTertiary = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(Color(hex: "6B7280"))
                : UIColor(Color(hex: "9CA3AF"))
        }
    )
    static let textOnPrimary = Color.white

    // MARK: - Divider / Border (adaptive)
    static let divider = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(white: 1, alpha: 0.08)
                : UIColor(white: 0, alpha: 0.06)
        }
    )

    // MARK: - Gradients
    static let primaryGradient = LinearGradient(
        colors: [primaryTeal, primaryTealLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let coralGradient = LinearGradient(
        colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E8E")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Confidence
    static func confidenceColor(_ score: Double) -> Color {
        switch score {
        case 0..<0.50: return error
        case 0.50..<0.70: return warning
        case 0.70..<0.90: return info
        default: return success
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
