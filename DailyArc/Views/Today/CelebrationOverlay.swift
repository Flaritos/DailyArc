import SwiftUI

/// Canvas-based confetti celebration overlay.
/// Triggers when all habits for the day are completed.
/// 50 particles: 60% rectangles, 30% circles, 10% emoji.
/// Uses brand colors (Sky, Coral, Indigo). Duration: 2 seconds.
/// Respects reduce motion: shows static "All done!" banner instead.
struct CelebrationOverlay: View {
    @Binding var isShowing: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if isShowing {
            ZStack {
                if reduceMotion {
                    // Static banner for reduce motion
                    VStack {
                        Spacer()
                            .frame(height: 120)

                        Text("All done!")
                            .font(.title.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(hex: "#2563EB")!,
                                                Color(hex: "#5F27CD")!
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .transition(.scale.combined(with: .opacity))

                        Spacer()
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation { isShowing = false }
                        }
                    }
                } else {
                    ConfettiCanvasView(isShowing: $isShowing)
                }
            }
            .allowsHitTesting(false)
            .accessibilityLabel("Celebration! All habits completed.")
        }
    }
}

// MARK: - Confetti Canvas

private struct ConfettiCanvasView: View {
    @Binding var isShowing: Bool
    @State private var particles: [ConfettiParticle] = []
    @State private var elapsed: TimeInterval = 0

    private static let duration: TimeInterval = 2.0
    private static let particleCount = 50

    // Brand colors: Sky, Coral, Indigo
    private static let brandColors: [Color] = [
        Color(hex: "#2563EB")!, // Sky
        Color(hex: "#54A0FF")!, // Sky light
        Color(hex: "#E63946")!, // Coral
        Color(hex: "#FF6B6B")!, // Coral light
        Color(hex: "#5F27CD")!, // Indigo
        Color(hex: "#8B5CF6")!, // Indigo light
    ]

    private static let emojis = ["🎉", "⭐", "✨", "🎊", "💪"]

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                for particle in particles {
                    let age = now - particle.startTime
                    guard age >= 0 && age <= Self.duration else { continue }

                    let progress = age / Self.duration
                    let opacity = 1.0 - max(0, (progress - 0.6) / 0.4) // Fade out in last 40%

                    let x = particle.startX * size.width + particle.driftX * CGFloat(progress) * 60
                    let y = particle.startY * size.height + CGFloat(progress) * size.height * particle.speed
                    let rotation = Angle.degrees(particle.rotation + particle.rotationSpeed * progress * 360)

                    var particleContext = context
                    particleContext.translateBy(x: x, y: y)
                    particleContext.rotate(by: rotation)
                    particleContext.opacity = opacity

                    switch particle.shape {
                    case .rectangle:
                        let rect = CGRect(x: -particle.width / 2, y: -particle.height / 2,
                                          width: particle.width, height: particle.height)
                        particleContext.fill(
                            Path(rect),
                            with: .color(particle.color)
                        )
                    case .circle:
                        let rect = CGRect(x: -particle.width / 2, y: -particle.width / 2,
                                          width: particle.width, height: particle.width)
                        particleContext.fill(
                            Path(ellipseIn: rect),
                            with: .color(particle.color)
                        )
                    case .emoji:
                        let text = Text(particle.emoji)
                            .font(.system(size: particle.width))
                        particleContext.draw(text, at: .zero)
                    }
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            let now = Date().timeIntervalSinceReferenceDate
            particles = (0..<Self.particleCount).map { i in
                let shapeRoll = Double(i) / Double(Self.particleCount)
                let shape: ConfettiParticle.Shape
                if shapeRoll < 0.6 {
                    shape = .rectangle
                } else if shapeRoll < 0.9 {
                    shape = .circle
                } else {
                    shape = .emoji
                }

                return ConfettiParticle(
                    startX: CGFloat.random(in: 0.05...0.95),
                    startY: CGFloat.random(in: -0.2...(-0.05)),
                    speed: CGFloat.random(in: 0.5...1.0),
                    driftX: CGFloat.random(in: -1.0...1.0),
                    rotation: Double.random(in: 0...360),
                    rotationSpeed: Double.random(in: 0.5...2.0),
                    width: CGFloat.random(in: 8...14),
                    height: CGFloat.random(in: 4...8),
                    color: Self.brandColors.randomElement()!,
                    shape: shape,
                    emoji: Self.emojis.randomElement()!,
                    startTime: now + Double.random(in: 0...0.3)
                )
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + Self.duration) {
                withAnimation { isShowing = false }
            }
        }
    }
}

// MARK: - Particle Model

private struct ConfettiParticle {
    enum Shape {
        case rectangle, circle, emoji
    }

    let startX: CGFloat
    let startY: CGFloat
    let speed: CGFloat
    let driftX: CGFloat
    let rotation: Double
    let rotationSpeed: Double
    let width: CGFloat
    let height: CGFloat
    let color: Color
    let shape: Shape
    let emoji: String
    let startTime: TimeInterval
}
