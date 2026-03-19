import SwiftUI

/// Confetti celebration overlay — colorful falling particles for 2 seconds
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var opacity: Double = 1.0

    private let particleCount = 50
    private let colors: [Color] = [
        MCColors.primaryTeal,
        MCColors.accentCoral,
        MCColors.success,
        MCColors.warning,
        MCColors.info,
        Color(hex: "FFD700"),
        Color(hex: "9B59B6"),
        Color(hex: "3EC6C8"),
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    confettiPiece(particle: particle, size: geo.size)
                }
            }
            .opacity(opacity)
            .onAppear {
                generateParticles(in: geo.size)
                // Fade out after 2 seconds
                withAnimation(.easeOut(duration: 0.5).delay(1.5)) {
                    opacity = 0
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func confettiPiece(particle: ConfettiParticle, size: CGSize) -> some View {
        particle.shapeView
            .rotationEffect(.degrees(particle.rotation))
            .offset(x: particle.x, y: particle.y)
            .onAppear {
                withAnimation(
                    .easeIn(duration: particle.fallDuration)
                    .delay(particle.delay)
                ) {
                    // Animate via the particle's final state
                    // We handle this through the offset modifier in the TimelineView approach below
                }
            }
    }

    private func generateParticles(in size: CGSize) {
        particles = (0..<particleCount).map { _ -> ConfettiParticle in
            let startX = CGFloat.random(in: 0...size.width)
            return ConfettiParticle(
                color: colors.randomElement() ?? MCColors.primaryTeal,
                x: startX + CGFloat.random(in: -40...40),
                y: size.height + 20,
                width: CGFloat.random(in: 6...12),
                height: CGFloat.random(in: 6...12),
                rotation: Double.random(in: 0...360),
                delay: Double.random(in: 0...0.3),
                fallDuration: Double.random(in: 1.5...2.5),
                shapeType: ConfettiShapeType.allCases.randomElement() ?? .rectangle
            )
        }

        // Animate particles falling
        withAnimation(.easeOut(duration: 0.01)) {
            particles = particles.map { p in
                var updated = p
                updated.y = -20  // start from top
                return updated
            }
        }

        // Then animate to bottom
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            withAnimation(.easeIn(duration: 2.0)) {
                particles = particles.map { p in
                    var updated = p
                    updated.y = size.height + 40
                    updated.x = p.x + CGFloat.random(in: -60...60)
                    updated.rotation = p.rotation + Double.random(in: 180...720)
                    return updated
                }
            }
        }
    }
}

// MARK: - Particle Model

enum ConfettiShapeType: CaseIterable {
    case rectangle
    case circle
    case capsule
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    var x: CGFloat
    var y: CGFloat
    let width: CGFloat
    let height: CGFloat
    var rotation: Double
    let delay: Double
    let fallDuration: Double
    let shapeType: ConfettiShapeType

    @ViewBuilder
    var shapeView: some View {
        switch shapeType {
        case .rectangle:
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: width, height: height)
        case .circle:
            Circle()
                .fill(color)
                .frame(width: width, height: height)
        case .capsule:
            Capsule()
                .fill(color)
                .frame(width: width, height: height)
        }
    }
}

#Preview("Confetti") {
    ZStack {
        MCColors.backgroundLight
            .ignoresSafeArea()

        VStack {
            Text("Congratulations!")
                .font(MCTypography.title)
                .foregroundStyle(MCColors.textPrimary)
        }

        ConfettiView()
    }
}
