import SwiftUI

/// Generates the app icon PNG programmatically using ImageRenderer.
/// Run from DEBUG settings to export the icon to Files.
///
/// Renders the G6 "Arc with Milestone Dot" logo: a uniform-width 270-degree arc
/// in the brand gradient (#2563EB -> #5F27CD) with a filled milestone dot at the
/// arc endpoint. White background, 15% padding from edges.
enum AppIconGenerator {
    @MainActor
    static func generateIcon() -> Data? {
        let canvasSize: CGFloat = 1024
        let padding = canvasSize * 0.15
        let strokeWidth = canvasSize * 0.07
        let radius = (canvasSize - padding * 2 - strokeWidth) / 2
        let center = canvasSize / 2
        let dotDiameter = strokeWidth * 1.8

        // Arc angles: gap at upper-right
        // Start at -45 degrees (upper-right), sweep 270 degrees clockwise to 225 degrees
        let startAngleDeg: Double = -45
        let endAngleDeg: Double = 225

        let iconView = ZStack {
            // White background
            RoundedRectangle(cornerRadius: 224)
                .fill(Color.white)

            // 270-degree arc with gradient
            Canvas { context, size in
                let c = CGPoint(x: size.width / 2, y: size.height / 2)

                var path = Path()
                path.addArc(
                    center: c,
                    radius: radius,
                    startAngle: .degrees(startAngleDeg),
                    endAngle: .degrees(endAngleDeg),
                    clockwise: false
                )

                context.stroke(
                    path,
                    with: .linearGradient(
                        Gradient(colors: [
                            Color(hex: "#2563EB") ?? .blue,
                            Color(hex: "#5F27CD") ?? .purple
                        ]),
                        startPoint: CGPoint(x: size.width * 0.2, y: size.height * 0.2),
                        endPoint: CGPoint(x: size.width * 0.8, y: size.height * 0.8)
                    ),
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )

                // Milestone dot at arc endpoint
                let endAngleRad = endAngleDeg * .pi / 180
                let dotX = c.x + radius * cos(endAngleRad)
                let dotY = c.y + radius * sin(endAngleRad)

                let dotRect = CGRect(
                    x: dotX - dotDiameter / 2,
                    y: dotY - dotDiameter / 2,
                    width: dotDiameter,
                    height: dotDiameter
                )
                context.fill(
                    Path(ellipseIn: dotRect),
                    with: .color(Color(hex: "#5F27CD") ?? .purple)
                )
            }
        }
        .frame(width: canvasSize, height: canvasSize)

        let renderer = ImageRenderer(content: iconView)
        renderer.scale = 1.0
        return renderer.uiImage?.pngData()
    }
}
