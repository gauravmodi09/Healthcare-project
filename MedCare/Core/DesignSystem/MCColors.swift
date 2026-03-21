import SwiftUI

/// MedCare Design System — Colors (adaptive light/dark mode)
enum MCColors {
    // MARK: - Primary (Teal) — same in both modes
    static let primaryTeal = Color(hex: "0D9488")
    static let primaryTealLight = Color(hex: "2DD4BF")
    static let primaryTealDark = Color(hex: "0D9488")

    // MARK: - Accent (Coral)
    static let accentCoral = Color(hex: "F97066")

    // MARK: - Semantic
    static let success = Color(hex: "22C55E")
    static let warning = Color(hex: "F59E0B")
    static let error = Color(hex: "EF4444")
    static let info = Color(hex: "60A5FA")

    // MARK: - Surface (adaptive)
    static let surface = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(Color(hex: "2C2C2C"))
                : UIColor(Color(hex: "F0FDFA"))
        }
    )

    // MARK: - Background (adaptive)
    static let backgroundLight = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(Color(hex: "121212"))
                : UIColor(Color(hex: "FAFAFA"))
        }
    )
    static let backgroundDark = Color(hex: "121212")

    static let cardBackground = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(Color(hex: "1E1E1E"))
                : .white
        }
    )
    static let cardBackgroundDark = Color(hex: "1E1E1E")

    // MARK: - Text (adaptive)
    static let textPrimary = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(Color(hex: "F5F5F5"))
                : UIColor(Color(hex: "1A1A1A"))
        }
    )
    static let textSecondary = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(Color(hex: "A0A0A0"))
                : UIColor(Color(hex: "6B7280"))
        }
    )
    static let textTertiary = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(Color(hex: "707070"))
                : UIColor(Color(hex: "9CA3AF"))
        }
    )
    static let textOnPrimary = Color.white

    // MARK: - Divider / Border (adaptive)
    static let divider = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(Color(hex: "3A3A3A"))
                : UIColor(Color(hex: "E5E7EB"))
        }
    )

    // MARK: - Medication Status Colors
    static let statusTaken = Color(hex: "22C55E")
    static let statusTakenLate = Color(hex: "F59E0B")
    static let statusMissed = Color(hex: "F97066")
    static let statusUpcoming = Color(hex: "0D9488")
    static let statusSkipped = Color(hex: "94A3B8")
    static let statusSnoozed = Color(hex: "A78BFA")

    // MARK: - Gradients
    static let primaryGradient = LinearGradient(
        colors: [Color(hex: "0D9488"), Color(hex: "2DD4BF")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let coralGradient = LinearGradient(
        colors: [Color(hex: "F97066"), Color(hex: "FCA5A1")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Colors for mesh gradient backgrounds (onboarding, achievements)
    static let meshGradientColors: [Color] = [
        Color(hex: "0D9488"),
        Color(hex: "2DD4BF"),
        Color(hex: "F0FDFA"),
        Color(hex: "A78BFA"),
        Color(hex: "60A5FA"),
        Color(hex: "F97066"),
    ]

    // MARK: - Confidence
    static func confidenceColor(_ score: Double) -> Color {
        switch score {
        case 0..<0.50: return error
        case 0.50..<0.70: return warning
        case 0.70..<0.90: return info
        default: return success
        }
    }

    // MARK: - Dose Status Color
    static func statusColor(_ status: DoseStatus) -> Color {
        switch status {
        case .taken: return statusTaken
        case .missed: return statusMissed
        case .skipped: return statusSkipped
        case .snoozed: return statusSnoozed
        case .pending: return statusUpcoming
        case .outOfStock: return statusSkipped
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
