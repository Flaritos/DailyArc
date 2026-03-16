import SwiftUI

/// Renders the DailyArc branded 270-degree arc icon programmatically
struct AppIconView: View {
    var size: CGFloat = 60

    private let skyColor = Color(hex: "2563EB")!
    private let indigoColor = Color(hex: "5F27CD")!

    var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let radius = min(canvasSize.width, canvasSize.height) * 0.35
            let lineWidth = min(canvasSize.width, canvasSize.height) * 0.12

            // 270-degree arc, gap faces upper-right at 45 degrees
            let startAngle = Angle.degrees(-135)
            let endAngle = Angle.degrees(135)

            var path = Path()
            path.addArc(center: center, radius: radius,
                       startAngle: startAngle, endAngle: endAngle, clockwise: false)

            context.stroke(
                path,
                with: .linearGradient(
                    Gradient(colors: [skyColor, indigoColor]),
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: canvasSize.width, y: canvasSize.height)
                ),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
        }
        .frame(width: size, height: size)
    }
}
