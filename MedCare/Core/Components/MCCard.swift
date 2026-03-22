import SwiftUI

/// Reusable card container
struct MCCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        content
            .padding(MCSpacing.cardPadding)
            .background(MCColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.2 : 0.06), radius: 8, y: 2)
    }
}

/// Glass-morphism card with ultra-thin material and layered shadows
struct MCGlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(MCSpacing.cardPadding)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 16, y: 8)
            .shadow(color: .black.opacity(0.03), radius: 2, y: 1)
    }
}

/// Card with a colored left border accent
struct MCAccentCard<Content: View>: View {
    let accentColor: Color
    let content: Content

    init(accent: Color = MCColors.primaryTeal, @ViewBuilder content: () -> Content) {
        self.accentColor = accent
        self.content = content()
    }

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(accentColor)
                .frame(width: 4)

            content
                .padding(MCSpacing.cardPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(MCColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius, style: .continuous))
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.15 : 0.04), radius: 3, y: 1)
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.25 : 0.08), radius: 10, y: 4)
    }
}
