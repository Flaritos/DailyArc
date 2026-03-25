import SwiftUI

/// The G6 "Arc with Milestone Dot" logo as a reusable SwiftUI view.
///
/// Draws a 270-degree arc in the brand gradient (#2563EB -> #5F27CD) with a
/// filled circle (milestone dot) at the endpoint. The gap sits at the upper-right,
/// suggesting forward/upward progress.
struct DailyArcLogo: View {
    /// Overall canvas size (width and height).
    var size: CGFloat = 140

    /// Optional stroke width override. Defaults to proportional sizing (~14px at 200px).
    var strokeWidth: CGFloat? = nil

    /// Whether to show the milestone dot at the arc endpoint.
    var showDot: Bool = true

    /// If true, the arc draws itself on appear via a trim animation (0.8s ease-out).
    var animated: Bool = false

    /// If true, adds a subtle blue glow for dark backgrounds (Command theme).
    var glowOnDark: Bool = false

    // MARK: - Derived values

    private var computedStrokeWidth: CGFloat {
        strokeWidth ?? (size * 0.07)
    }

    private var dotDiameter: CGFloat {
        computedStrokeWidth * 1.8
    }

    private var padding: CGFloat {
        size * 0.15
    }

    private var radius: CGFloat {
        (size - padding * 2 - computedStrokeWidth) / 2
    }

    /// Arc starts at 315 degrees (upper-right, clockwise from 3-o'clock)
    /// and sweeps 270 degrees clockwise, ending at 225 degrees (which is also
    /// the upper-right region, leaving the gap from 225 to 315 = 90 degrees open).
    ///
    /// In SwiftUI coordinate space (0 = right, clockwise):
    /// - Start angle: -45 degrees (= 315 degrees, upper-right)
    /// - End angle: 225 degrees (lower-left area, sweeping 270 CW)
    private let startAngleDeg: Double = -45
    private let endAngleDeg: Double = 225

    // MARK: - Animation state

    @State private var trimEnd: CGFloat = 0

    // MARK: - Brand colors

    private let brandBlue = Color(hex: "#2563EB") ?? .blue
    private let brandPurple = Color(hex: "#5F27CD") ?? .purple

    var body: some View {
        let center = CGPoint(x: size / 2, y: size / 2)

        ZStack {
            // The 270-degree arc with gradient stroke
            Circle()
                .trim(from: 0, to: animated ? trimEnd : 0.75) // 270/360 = 0.75
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [brandBlue, brandPurple]),
                        center: .center,
                        startAngle: .degrees(startAngleDeg),
                        endAngle: .degrees(endAngleDeg)
                    ),
                    style: StrokeStyle(
                        lineWidth: computedStrokeWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(startAngleDeg - 90))
                // Circle().trim starts from the right (3 o'clock).
                // We rotate so that trim(from: 0) starts at our desired start angle.
                // SwiftUI rotation: -90 makes 0 point up. Adding startAngleDeg positions it.
                .frame(width: radius * 2, height: radius * 2)
                .position(center)

            // Milestone dot at the arc endpoint
            if showDot {
                let endAngleRad = endAngleDeg * .pi / 180
                let dotX = center.x + radius * cos(endAngleRad)
                let dotY = center.y + radius * sin(endAngleRad)

                Circle()
                    .fill(brandPurple)
                    .frame(width: dotDiameter, height: dotDiameter)
                    .position(x: dotX, y: dotY)
                    .opacity(animated ? (trimEnd >= 0.74 ? 1 : 0) : 1)
                    .scaleEffect(animated ? (trimEnd >= 0.74 ? 1 : 0.3) : 1)
                    .animation(.easeOut(duration: 0.2), value: trimEnd >= 0.74)
            }
        }
        .frame(width: size, height: size)
        .modifier(LogoGlowModifier(enabled: glowOnDark, color: brandBlue))
        .onAppear {
            if animated {
                withAnimation(.easeOut(duration: 0.8)) {
                    trimEnd = 0.75
                }
            }
        }
    }
}

// MARK: - Glow modifier

private struct LogoGlowModifier: ViewModifier {
    let enabled: Bool
    let color: Color

    func body(content: Content) -> some View {
        if enabled {
            content
                .shadow(color: color.opacity(0.15), radius: 20)
        } else {
            content
        }
    }
}

#Preview("Default") {
    DailyArcLogo()
        .padding()
}

#Preview("Animated") {
    DailyArcLogo(size: 200, animated: true)
        .padding()
}

#Preview("Glow on Dark") {
    DailyArcLogo(size: 200, glowOnDark: true)
        .padding()
        .background(Color.black)
}
