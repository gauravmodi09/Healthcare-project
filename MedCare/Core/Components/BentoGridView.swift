import SwiftUI

/// Size options for bento grid cards
enum BentoSize {
    case large, medium, small
}

/// Data model for a single bento card
struct BentoCard: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    var subtitle: String?
    let icon: String
    var iconColor: Color = MCColors.primaryTeal
    var size: BentoSize = .medium
}

/// A reusable bento grid card component
struct BentoGridView: View {
    let cards: [BentoCard]

    @Environment(\.colorScheme) private var colorScheme

    private var columns: [GridItem] {
        [GridItem(.flexible(), spacing: MCSpacing.sm), GridItem(.flexible(), spacing: MCSpacing.sm)]
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: MCSpacing.sm) {
            ForEach(cards) { card in
                BentoCardView(card: card)
                    .gridCellColumns(card.size == .large ? 2 : 1)
            }
        }
    }
}

/// Individual bento card view
struct BentoCardView: View {
    let card: BentoCard

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: MCSpacing.xs) {
            // Icon with gradient overlay
            ZStack {
                Circle()
                    .fill(card.iconColor.opacity(0.12))
                    .overlay(
                        LinearGradient(
                            colors: [card.iconColor.opacity(0.2), card.iconColor.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .clipShape(Circle())
                    )
                    .frame(width: iconSize, height: iconSize)

                Image(systemName: card.icon)
                    .font(.system(size: iconFontSize, weight: .semibold))
                    .foregroundStyle(card.iconColor)
            }

            Spacer(minLength: 0)

            // Value
            Text(card.value)
                .font(card.size == .large ? MCTypography.display : MCTypography.title2)
                .foregroundStyle(MCColors.textPrimary)

            // Title
            Text(card.title)
                .font(MCTypography.subheadline)
                .foregroundStyle(MCColors.textSecondary)

            // Subtitle
            if let subtitle = card.subtitle {
                Text(subtitle)
                    .font(MCTypography.caption)
                    .foregroundStyle(MCColors.textTertiary)
            }
        }
        .padding(MCSpacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: cardHeight)
        .background(MCColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.2 : 0.06), radius: 8, y: 2)
    }

    private var iconSize: CGFloat {
        switch card.size {
        case .large: return 44
        case .medium: return 36
        case .small: return 30
        }
    }

    private var iconFontSize: CGFloat {
        switch card.size {
        case .large: return 20
        case .medium: return 16
        case .small: return 14
        }
    }

    private var cardHeight: CGFloat {
        switch card.size {
        case .large: return 140
        case .medium: return 140
        case .small: return 120
        }
    }
}

#Preview {
    ScrollView {
        BentoGridView(cards: [
            BentoCard(title: "Adherence Rate", value: "92%", subtitle: "This week", icon: "chart.bar.fill", iconColor: MCColors.success, size: .large),
            BentoCard(title: "Taken Today", value: "4/6", icon: "pills.fill", iconColor: MCColors.primaryTeal, size: .medium),
            BentoCard(title: "Streak", value: "12 days", icon: "flame.fill", iconColor: MCColors.accentCoral, size: .medium),
            BentoCard(title: "Missed", value: "1", icon: "exclamationmark.circle.fill", iconColor: MCColors.warning, size: .small),
            BentoCard(title: "Refills", value: "2", subtitle: "Due soon", icon: "arrow.clockwise", iconColor: MCColors.info, size: .small),
        ])
        .padding(MCSpacing.screenPadding)
    }
    .background(MCColors.backgroundLight)
}
