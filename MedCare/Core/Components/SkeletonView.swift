import SwiftUI

// MARK: - Shimmer Modifier

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: max(0, phase - 0.15)),
                        .init(color: .white.opacity(0.35), location: phase),
                        .init(color: .clear, location: min(1, phase + 0.15)),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .blendMode(.screen)
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 1.4)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 1.15
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Skeleton Primitives

/// Animated shimmer rectangle placeholder
struct SkeletonRectangle: View {
    var width: CGFloat? = nil
    var height: CGFloat = 16
    var cornerRadius: CGFloat = 6

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(MCColors.divider)
            .frame(width: width, height: height)
            .shimmer()
    }
}

/// Animated shimmer circle placeholder
struct SkeletonCircle: View {
    var size: CGFloat = 40

    var body: some View {
        Circle()
            .fill(MCColors.divider)
            .frame(width: size, height: size)
            .shimmer()
    }
}

/// Single-line text placeholder with shimmer
struct SkeletonText: View {
    var width: CGFloat = 120

    var body: some View {
        SkeletonRectangle(width: width, height: 12, cornerRadius: 4)
    }
}

// MARK: - Skeleton Card

/// A placeholder card matching MCCard dimensions: circle avatar + 2 text lines + action area
struct SkeletonCardView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Avatar
                SkeletonCircle(size: 44)

                VStack(alignment: .leading, spacing: 8) {
                    // Title line
                    SkeletonText(width: 140)
                    // Subtitle line
                    SkeletonText(width: 100)
                }

                Spacer()
            }

            // Action area
            HStack(spacing: 10) {
                SkeletonRectangle(width: 80, height: 32, cornerRadius: 16)
                SkeletonRectangle(width: 80, height: 32, cornerRadius: 16)
                Spacer()
            }
        }
        .padding(MCSpacing.cardPadding)
        .background(MCColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.2 : 0.06), radius: 8, y: 2)
    }
}

// MARK: - Previews

#Preview("Skeleton Components") {
    VStack(spacing: 20) {
        SkeletonRectangle(width: 200, height: 20)
        SkeletonCircle(size: 48)
        SkeletonText(width: 160)
        SkeletonCardView()
    }
    .padding()
}
