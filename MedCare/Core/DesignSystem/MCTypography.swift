import SwiftUI

/// MedCare Design System — Typography
enum MCTypography {
    static let display = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let title2 = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let headline = Font.system(size: 17, weight: .semibold)
    static let body = Font.system(size: 16, weight: .regular)
    static let bodyMedium = Font.system(size: 16, weight: .medium)
    static let callout = Font.system(size: 15, weight: .regular)
    static let subheadline = Font.system(size: 14, weight: .medium)
    static let footnote = Font.system(size: 13, weight: .regular)
    static let caption = Font.system(size: 12, weight: .regular)
    static let captionBold = Font.system(size: 12, weight: .semibold)

    // MARK: - OTP specific
    static let otpDigit = Font.system(size: 32, weight: .bold, design: .monospaced)
    static let phoneNumber = Font.system(size: 24, weight: .semibold, design: .monospaced)
}
