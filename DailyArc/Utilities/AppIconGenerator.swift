import SwiftUI

/// Generates the app icon PNG programmatically using ImageRenderer.
/// Run from DEBUG settings to export the icon to Files.
enum AppIconGenerator {
    @MainActor
    static func generateIcon() -> Data? {
        let iconView = ZStack {
            // Background
            RoundedRectangle(cornerRadius: 224)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "0F172A")!, Color(hex: "1E293B")!],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // 270-degree arc
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = size.width * 0.32
                let lineWidth = size.width * 0.08

                var path = Path()
                path.addArc(center: center, radius: radius,
                           startAngle: .degrees(-135), endAngle: .degrees(135),
                           clockwise: false)

                context.stroke(
                    path,
                    with: .linearGradient(
                        Gradient(colors: [Color(hex: "2563EB")!, Color(hex: "5F27CD")!]),
                        startPoint: CGPoint(x: size.width * 0.2, y: size.height * 0.2),
                        endPoint: CGPoint(x: size.width * 0.8, y: size.height * 0.8)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
            }
        }
        .frame(width: 1024, height: 1024)

        let renderer = ImageRenderer(content: iconView)
        renderer.scale = 1.0
        return renderer.uiImage?.pngData()
    }
}
