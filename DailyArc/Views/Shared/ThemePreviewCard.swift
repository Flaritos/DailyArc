import SwiftUI

/// A miniature preview card showing a theme's visual style.
/// Used in onboarding theme picker and settings.
struct ThemePreviewCard: View {
    let themeID: String
    let isSelected: Bool
    let onSelect: () -> Void

    private var isTactile: Bool { themeID == "tactile" }

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 0) {
                // Mini preview
                miniPreview
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(10)

                // Label
                VStack(spacing: 4) {
                    Text(isTactile ? "Tactile" : "Command")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.white)

                    Text(isTactile ? "Soft, physical, satisfying" : "Focused, precise, powerful")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.6))
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 16)
            }
            .frame(width: 170)
            .background(Color(hex: "#1A1A1A")!)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected
                            ? (isTactile ? Color(hex: "#6366F1")! : Color(hex: "#22D3EE")!)
                            : Color.white.opacity(0.08),
                        lineWidth: 2.5
                    )
            )
            .shadow(
                color: isSelected
                    ? (isTactile ? Color(hex: "#6366F1")!.opacity(0.3) : Color(hex: "#22D3EE")!.opacity(0.3))
                    : .clear,
                radius: 20
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Circle()
                        .fill(isTactile ? Color(hex: "#6366F1")! : Color(hex: "#22D3EE")!)
                        .frame(width: 24, height: 24)
                        .overlay {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .offset(x: -8, y: 8)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Mini Previews

    @ViewBuilder
    private var miniPreview: some View {
        if isTactile {
            tactilePreview
        } else {
            commandPreview
        }
    }

    private var tactilePreview: some View {
        ZStack {
            Color(hex: "#E8ECF1")!

            VStack(spacing: 8) {
                // Mini header bar
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(hex: "#E8ECF1")!)
                    .frame(height: 20)
                    .shadow(color: Color.white.opacity(0.6), radius: 4, x: -2, y: -2)
                    .shadow(color: Color(hex: "#A3B1C6")!.opacity(0.4), radius: 4, x: 2, y: 2)
                    .padding(.horizontal, 12)

                // Mini dial
                ZStack {
                    Circle()
                        .fill(Color(hex: "#E8ECF1")!)
                        .frame(width: 70, height: 70)
                        .shadow(color: Color.white.opacity(0.7), radius: 8, x: -4, y: -4)
                        .shadow(color: Color(hex: "#A3B1C6")!.opacity(0.5), radius: 8, x: 4, y: 4)

                    Circle()
                        .trim(from: 0, to: 0.6)
                        .stroke(
                            LinearGradient(colors: [Color(hex: "#6366F1")!, Color(hex: "#EC4899")!], startPoint: .top, endPoint: .bottom),
                            lineWidth: 4
                        )
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))

                    Text("60%")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(Color(hex: "#334155")!)
                }

                // Mini mood circles
                HStack(spacing: 6) {
                    ForEach(0..<5, id: \.self) { i in
                        Circle()
                            .fill(Color(hex: "#E8ECF1")!)
                            .frame(width: 18, height: 18)
                            .shadow(color: Color.white.opacity(0.6), radius: 3, x: -1, y: -1)
                            .shadow(color: Color(hex: "#A3B1C6")!.opacity(0.4), radius: 3, x: 1, y: 1)
                            .overlay {
                                Text(["😔","😕","😐","😊","😄"][i])
                                    .font(.system(size: 10))
                            }
                    }
                }

                // Mini cards
                VStack(spacing: 6) {
                    ForEach(0..<2, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "#E8ECF1")!)
                            .frame(height: 22)
                            .shadow(color: Color.white.opacity(0.6), radius: 3, x: -1, y: -1)
                            .shadow(color: Color(hex: "#A3B1C6")!.opacity(0.4), radius: 3, x: 1, y: 1)
                    }
                }
                .padding(.horizontal, 12)
            }
            .padding(.top, 12)
        }
    }

    private var commandPreview: some View {
        ZStack {
            Color.black

            // Grid overlay
            Canvas { context, size in
                let spacing: CGFloat = 12
                let color = Color(hex: "#6366F1")!.opacity(0.06)
                var x: CGFloat = 0
                while x < size.width {
                    context.stroke(
                        Path { p in p.move(to: .init(x: x, y: 0)); p.addLine(to: .init(x: x, y: size.height)) },
                        with: .color(color), lineWidth: 0.5
                    )
                    x += spacing
                }
                var y: CGFloat = 0
                while y < size.height {
                    context.stroke(
                        Path { p in p.move(to: .init(x: 0, y: y)); p.addLine(to: .init(x: size.width, y: y)) },
                        with: .color(color), lineWidth: 0.5
                    )
                    y += spacing
                }
            }

            VStack(spacing: 8) {
                // Mini header
                HStack {
                    Text("SOL 47")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(Color(hex: "#22D3EE")!)
                    Spacer()
                    Text("CMDR")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.5))
                }
                .padding(.horizontal, 12)

                // Mini HUD ring
                ZStack {
                    Circle()
                        .stroke(Color(hex: "#22D3EE")!.opacity(0.15), lineWidth: 1.5)
                        .frame(width: 70, height: 70)

                    Circle()
                        .trim(from: 0, to: 0.55)
                        .stroke(
                            LinearGradient(colors: [Color(hex: "#22D3EE")!, Color(hex: "#6366F1")!], startPoint: .top, endPoint: .bottom),
                            lineWidth: 2
                        )
                        .frame(width: 62, height: 62)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: Color(hex: "#22D3EE")!.opacity(0.3), radius: 4, x: 0, y: 0)

                    // Crosshairs
                    Rectangle().fill(Color(hex: "#22D3EE")!.opacity(0.06)).frame(width: 60, height: 0.5)
                    Rectangle().fill(Color(hex: "#22D3EE")!.opacity(0.06)).frame(width: 0.5, height: 60)

                    Text("73%")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: "#22D3EE")!)
                }

                // Mini status rows
                VStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { i in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(i < 2 ? Color(hex: "#22C55E")! : Color(hex: "#F97316")!)
                                .frame(width: 4, height: 4)
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color(hex: "#111122")!)
                                .frame(height: 14)
                                .overlay(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color(hex: "#6366F1")!.opacity(0.12))
                                        .frame(width: 3)
                                }
                        }
                    }
                }
                .padding(.horizontal, 12)
            }
            .padding(.top, 12)
        }
    }
}

// MARK: - Theme Picker View (for onboarding and settings)

/// A side-by-side theme picker used in onboarding and settings.
/// Writes through ThemeManager.shared so @Observable mutation tracking fires.
struct ThemePickerView: View {
    // Read from ThemeManager directly so observation triggers re-render
    private var selectedThemeID: String { ThemeManager.shared.themeID }

    var body: some View {
        HStack(spacing: 14) {
            ThemePreviewCard(
                themeID: "tactile",
                isSelected: selectedThemeID == "tactile",
                onSelect: { ThemeManager.shared.themeID = "tactile" }
            )

            ThemePreviewCard(
                themeID: "command",
                isSelected: selectedThemeID == "command",
                onSelect: { ThemeManager.shared.themeID = "command" }
            )
        }
    }
}
