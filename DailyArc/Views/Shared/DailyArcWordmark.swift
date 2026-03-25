import SwiftUI

/// Combines the DailyArcLogo arc with "DailyArc" text in either vertical or horizontal layout.
struct DailyArcWordmark: View {
    /// Layout style for the wordmark.
    enum WordmarkStyle {
        /// Arc centered above "DailyArc" text.
        case vertical
        /// Arc on the left, "DailyArc" text on the right.
        case horizontal
    }

    /// Layout orientation.
    var style: WordmarkStyle = .vertical

    /// Controls the arc size; text scales proportionally.
    var size: CGFloat = 60

    /// Text color for the "DailyArc" label.
    var textColor: Color = .primary

    /// Whether the arc animates on appear.
    var animated: Bool = false

    // MARK: - Derived values

    private var fontSize: CGFloat {
        size * 0.3
    }

    var body: some View {
        switch style {
        case .vertical:
            VStack(spacing: size * 0.12) {
                DailyArcLogo(size: size, animated: animated)
                wordmarkText
            }

        case .horizontal:
            HStack(spacing: size * 0.15) {
                DailyArcLogo(size: size, animated: animated)
                wordmarkText
            }
        }
    }

    private var wordmarkText: some View {
        Text("DailyArc")
            .font(.system(size: fontSize, weight: .medium))
            .tracking(fontSize * 0.03)
            .foregroundStyle(textColor)
    }
}

#Preview("Vertical") {
    DailyArcWordmark(style: .vertical, size: 100)
        .padding()
}

#Preview("Horizontal") {
    DailyArcWordmark(style: .horizontal, size: 60)
        .padding()
}
