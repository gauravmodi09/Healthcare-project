import SwiftUI

// MARK: - MCShimmer

/// Shimmer loading effect view modifier
struct MCShimmer: ViewModifier {
    @State private var phase: CGFloat = -1

    var duration: Double = 1.5
    var bounce: Bool = false

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    let width = geo.size.width
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: max(0, phase - 0.3)),
                            .init(color: .white.opacity(0.4), location: phase),
                            .init(color: .clear, location: min(1, phase + 0.3)),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: width)
                    .blendMode(.overlay)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))
            .onAppear {
                withAnimation(
                    .linear(duration: duration)
                    .repeatForever(autoreverses: bounce)
                ) {
                    phase = 2
                }
            }
    }
}

extension View {
    /// Adds a shimmer loading effect overlay
    func mcShimmer(duration: Double = 1.5) -> some View {
        modifier(MCShimmer(duration: duration))
    }
}

/// Placeholder shimmer block for loading states
struct MCShimmerBlock: View {
    var width: CGFloat? = nil
    var height: CGFloat = 16
    var cornerRadius: CGFloat = MCSpacing.cornerRadiusSmall

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(MCColors.divider)
            .frame(width: width, height: height)
            .mcShimmer()
    }
}

// MARK: - MCBounce Button Style

/// Button style with scale-down bounce animation on press
struct MCBounce: ButtonStyle {
    var scale: CGFloat = 0.95

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == MCBounce {
    /// Bounce button style with scale animation on press
    static var mcBounce: MCBounce { MCBounce() }

    /// Bounce button style with custom scale factor
    static func mcBounce(scale: CGFloat) -> MCBounce { MCBounce(scale: scale) }
}

// MARK: - MCSlideIn Transition

/// Slide-in from right with spring animation
struct MCSlideIn: ViewModifier {
    var isActive: Bool

    func body(content: Content) -> some View {
        content
            .offset(x: isActive ? 0 : 60)
            .opacity(isActive ? 1 : 0)
    }
}

extension AnyTransition {
    /// Slide in from the right with a spring curve
    static var mcSlideIn: AnyTransition {
        .asymmetric(
            insertion: .modifier(
                active: MCSlideIn(isActive: false),
                identity: MCSlideIn(isActive: true)
            ),
            removal: .modifier(
                active: MCSlideIn(isActive: false),
                identity: MCSlideIn(isActive: true)
            )
        )
        .combined(with: .opacity)
    }
}

extension View {
    /// Applies slide-in-from-right animation when condition is true
    func mcSlideIn(active: Bool) -> some View {
        self
            .offset(x: active ? 0 : 60)
            .opacity(active ? 1 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: active)
    }
}

// MARK: - MCFadeScale Transition

/// Fade + slight scale-up transition
struct MCFadeScale: ViewModifier {
    var isActive: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(isActive ? 1.0 : 0.92)
            .opacity(isActive ? 1 : 0)
    }
}

extension AnyTransition {
    /// Fade in with slight scale-up effect
    static var mcFadeScale: AnyTransition {
        .asymmetric(
            insertion: .modifier(
                active: MCFadeScale(isActive: false),
                identity: MCFadeScale(isActive: true)
            ),
            removal: .modifier(
                active: MCFadeScale(isActive: false),
                identity: MCFadeScale(isActive: true)
            )
        )
    }
}

extension View {
    /// Applies fade + scale animation when condition is true
    func mcFadeScale(active: Bool) -> some View {
        self
            .scaleEffect(active ? 1.0 : 0.92)
            .opacity(active ? 1 : 0)
            .animation(.easeOut(duration: 0.3), value: active)
    }
}

// MARK: - Staggered Animation Helper

extension View {
    /// Delays appearance animation for staggered list effects
    func mcStaggered(index: Int, delay: Double = 0.05) -> some View {
        self
            .animation(
                .spring(response: 0.4, dampingFraction: 0.8)
                .delay(Double(index) * delay),
                value: index
            )
    }
}

// MARK: - Previews

#Preview("MCShimmer") {
    VStack(spacing: MCSpacing.md) {
        MCShimmerBlock(height: 20)
        MCShimmerBlock(width: 200, height: 14)
        MCShimmerBlock(width: 150, height: 14)

        RoundedRectangle(cornerRadius: MCSpacing.cornerRadius)
            .fill(MCColors.divider)
            .frame(height: 100)
            .mcShimmer()
    }
    .padding()
}

#Preview("MCBounce") {
    VStack(spacing: MCSpacing.md) {
        Button("Bounce Me") {}
            .buttonStyle(.mcBounce)
            .font(MCTypography.headline)
            .foregroundStyle(.white)
            .padding()
            .background(MCColors.primaryTeal)
            .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
    }
    .padding()
}
