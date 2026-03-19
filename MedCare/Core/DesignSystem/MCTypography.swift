import SwiftUI

/// MedCare Design System — Typography (Dynamic Type supporting)
enum MCTypography {
    // MARK: - Display
    static let largeDisplay = Font.system(size: 34, weight: .bold, design: .rounded)
    static let display = Font.system(size: 28, weight: .bold, design: .rounded)

    // MARK: - Titles
    static let title = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let title2 = Font.system(size: 20, weight: .semibold, design: .rounded)

    // MARK: - Body
    static let headline = Font.system(size: 17, weight: .semibold)
    static let body = Font.system(.body)
    static let bodyMedium = Font.system(size: 16, weight: .medium)
    static let callout = Font.system(.callout)
    static let subheadline = Font.system(size: 14, weight: .medium)
    static let footnote = Font.system(.footnote)
    static let caption = Font.system(.caption)
    static let captionBold = Font.system(size: 12, weight: .semibold)

    // MARK: - Section Header
    /// 15pt semibold uppercase with tracking — use with `.textCase(.uppercase)` and `.kerning(1.2)`
    static let sectionHeader = Font.system(size: 15, weight: .semibold)

    // MARK: - Numeric
    /// Monospaced digit variant for numbers in lists/tables
    static let bodyMonospaced = Font.system(size: 16, weight: .regular).monospacedDigit()

    /// 28pt bold monospaced digits for adherence percentages
    static let metric = Font.system(size: 28, weight: .bold, design: .monospaced).monospacedDigit()

    // MARK: - OTP / Phone
    static let otpDigit = Font.system(size: 32, weight: .bold, design: .monospaced)
    static let phoneNumber = Font.system(size: 24, weight: .semibold, design: .monospaced)
}
