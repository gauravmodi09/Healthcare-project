import SwiftUI

/// Style presets for mesh gradient backgrounds
enum MeshStyle {
    case teal, celebration, calm
}

/// Animated mesh gradient background for onboarding/celebration screens
struct MeshGradientBackground: View {
    let style: MeshStyle
    @State private var animationPhase: CGFloat = 0

    var body: some View {
        if #available(iOS 18.0, *) {
            meshGradientView
        } else {
            fallbackGradient
        }
    }

    @available(iOS 18.0, *)
    private var meshGradientView: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: animatedPoints,
            colors: meshColors
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                animationPhase = 1
            }
        }
    }

    private var fallbackGradient: some View {
        LinearGradient(
            colors: fallbackColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Mesh Points (animated)

    @available(iOS 18.0, *)
    private var animatedPoints: [SIMD2<Float>] {
        let offset = Float(animationPhase) * 0.08
        return [
            SIMD2<Float>(0, 0),          SIMD2<Float>(0.5, 0),             SIMD2<Float>(1, 0),
            SIMD2<Float>(0, 0.5 + offset), SIMD2<Float>(0.5 + offset, 0.5 - offset), SIMD2<Float>(1, 0.5),
            SIMD2<Float>(0, 1),          SIMD2<Float>(0.5, 1),             SIMD2<Float>(1, 1),
        ]
    }

    // MARK: - Colors per style

    private var meshColors: [Color] {
        switch style {
        case .teal:
            return [
                MCColors.primaryTeal.opacity(0.8), MCColors.primaryTealLight.opacity(0.6), MCColors.primaryTeal.opacity(0.4),
                MCColors.primaryTealLight.opacity(0.5), MCColors.primaryTeal.opacity(0.7), MCColors.primaryTealLight.opacity(0.3),
                MCColors.primaryTeal.opacity(0.3), MCColors.primaryTealLight.opacity(0.5), MCColors.primaryTeal.opacity(0.6),
            ]
        case .celebration:
            return [
                MCColors.accentCoral.opacity(0.7), MCColors.warning.opacity(0.5), MCColors.success.opacity(0.6),
                MCColors.primaryTeal.opacity(0.6), MCColors.accentCoral.opacity(0.5), MCColors.warning.opacity(0.4),
                MCColors.success.opacity(0.5), MCColors.primaryTealLight.opacity(0.6), MCColors.accentCoral.opacity(0.4),
            ]
        case .calm:
            return [
                Color(hex: "E8F4F8"), Color(hex: "D1ECF1"), Color(hex: "E8F4F8"),
                Color(hex: "D1ECF1"), Color(hex: "BEE3DB"), Color(hex: "D1ECF1"),
                Color(hex: "E8F4F8"), Color(hex: "D1ECF1"), Color(hex: "E8F4F8"),
            ]
        }
    }

    private var fallbackColors: [Color] {
        switch style {
        case .teal:
            return [MCColors.primaryTeal, MCColors.primaryTealLight]
        case .celebration:
            return [MCColors.accentCoral, MCColors.warning, MCColors.success]
        case .calm:
            return [Color(hex: "E8F4F8"), Color(hex: "BEE3DB")]
        }
    }
}

/// ViewModifier for applying mesh gradient background
struct MeshBackgroundModifier: ViewModifier {
    let style: MeshStyle

    func body(content: Content) -> some View {
        content
            .background(MeshGradientBackground(style: style))
    }
}

extension View {
    /// Apply an animated mesh gradient background
    func meshBackground(style: MeshStyle = .teal) -> some View {
        modifier(MeshBackgroundModifier(style: style))
    }
}

#Preview("Teal") {
    VStack {
        Text("Welcome to MedCare")
            .font(MCTypography.display)
            .foregroundStyle(.white)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .meshBackground(style: .teal)
}

#Preview("Celebration") {
    VStack {
        Text("Great Job!")
            .font(MCTypography.display)
            .foregroundStyle(.white)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .meshBackground(style: .celebration)
}

#Preview("Calm") {
    VStack {
        Text("Your Health Summary")
            .font(MCTypography.display)
            .foregroundStyle(MCColors.textPrimary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .meshBackground(style: .calm)
}
