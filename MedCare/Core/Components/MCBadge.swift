import SwiftUI

/// Status badge for episodes, confidence levels, etc.
struct MCBadge: View {
    let text: String
    let color: Color
    let style: BadgeStyle

    enum BadgeStyle {
        case filled, outlined, soft
    }

    init(_ text: String, color: Color = MCColors.primaryTeal, style: BadgeStyle = .soft) {
        self.text = text
        self.color = color
        self.style = style
    }

    var body: some View {
        Text(text)
            .font(MCTypography.captionBold)
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, MCSpacing.xs)
            .padding(.vertical, MCSpacing.xxs)
            .background(backgroundColor)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(borderColor, lineWidth: style == .outlined ? 1 : 0)
            )
    }

    private var foregroundColor: Color {
        switch style {
        case .filled: return .white
        case .outlined: return color
        case .soft: return color
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .filled: return color
        case .outlined: return .clear
        case .soft: return color.opacity(0.12)
        }
    }

    private var borderColor: Color {
        style == .outlined ? color : .clear
    }
}

/// Confidence indicator with percentage
struct MCConfidenceBadge: View {
    let score: Double

    var body: some View {
        HStack(spacing: MCSpacing.xxs) {
            Circle()
                .fill(MCColors.confidenceColor(score))
                .frame(width: 8, height: 8)
            Text("\(Int(score * 100))%")
                .font(MCTypography.captionBold)
                .foregroundStyle(MCColors.confidenceColor(score))
        }
        .padding(.horizontal, MCSpacing.xs)
        .padding(.vertical, MCSpacing.xxs)
        .background(MCColors.confidenceColor(score).opacity(0.1))
        .clipShape(Capsule())
    }
}
