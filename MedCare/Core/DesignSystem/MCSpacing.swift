import SwiftUI

/// MedCare Design System — Spacing & Layout
enum MCSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48

    static let screenPadding: CGFloat = 22
    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 24

    static let cornerRadius: CGFloat = 16
    static let cornerRadiusLarge: CGFloat = 24
    static let cornerRadiusHero: CGFloat = 28
    static let cornerRadiusSmall: CGFloat = 8

    static let buttonHeight: CGFloat = 52
    static let inputHeight: CGFloat = 52
    static let iconSize: CGFloat = 24
    static let avatarSize: CGFloat = 48
    static let avatarSizeLarge: CGFloat = 80

    // MARK: - Accessibility & Touch Targets
    /// Minimum accessible touch target (44pt per Apple HIG)
    static let touchTarget: CGFloat = 44
    /// Larger touch target for elder/accessibility mode
    static let touchTargetLarge: CGFloat = 56

    // MARK: - Bento Grid
    /// Gap between bento grid cards
    static let bentoSpacing: CGFloat = 12

    // MARK: - Tab Bar
    /// Standard tab bar height
    static let tabBarHeight: CGFloat = 49
}
