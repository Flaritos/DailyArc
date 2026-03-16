import SwiftUI

/// Canvas-rendered 52-week x 7-row heat map grid.
/// Cell size: 12pt x 12pt, 3pt gap. Horizontal scroll.
/// Colors: systemGray6 (no data), Sky-to-Indigo gradient based on completion %.
struct HeatMapCanvasView: View {
    let snapshots: [DaySnapshot]
    @Binding var selectedSnapshot: DaySnapshot?

    @Environment(\.colorScheme) private var colorScheme

    private let cellSize: CGFloat = 12
    private let cellGap: CGFloat = 3
    private let topLabelHeight: CGFloat = 20

    private var cellStride: CGFloat { cellSize + cellGap }
    private var totalHeight: CGFloat { topLabelHeight + 7 * cellStride - cellGap }
    private var totalColumns: Int { max(1, (snapshots.count + 6) / 7) }
    private var totalWidth: CGFloat { CGFloat(totalColumns) * cellStride - cellGap }

    private let calendar = Calendar.current
    private let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: DailyArcSpacing.sm) {
            Text("Your Arc This Year")
                .typography(.titleSmall)
                .foregroundStyle(DailyArcTokens.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                Canvas { context, size in
                    drawMonthLabels(context: context, size: size)
                    drawCells(context: context, size: size)
                }
                .frame(width: totalWidth, height: totalHeight)
                .gesture(
                    SpatialTapGesture()
                        .onEnded { value in
                            handleTap(at: value.location)
                        }
                )
            }

            // Detail bar
            if let selected = selectedSnapshot {
                detailBar(for: selected)
            }
        }
    }

    // MARK: - Canvas Drawing

    private func drawMonthLabels(context: GraphicsContext, size: CGSize) {
        var lastMonth = -1
        for col in 0..<totalColumns {
            let dayIndex = col * 7
            guard dayIndex < snapshots.count else { continue }
            let snapshot = snapshots[dayIndex]
            let month = calendar.component(.month, from: snapshot.date)
            if month != lastMonth {
                lastMonth = month
                let x = CGFloat(col) * cellStride
                let label = monthFormatter.string(from: snapshot.date)
                let text = Text(label).font(.caption2).foregroundColor(DailyArcTokens.textTertiary)
                context.draw(text, at: CGPoint(x: x, y: 6), anchor: .topLeading)
            }
        }
    }

    private func drawCells(context: GraphicsContext, size: CGSize) {
        for (index, snapshot) in snapshots.enumerated() {
            let col = index / 7
            let row = index % 7
            let x = CGFloat(col) * cellStride
            let y = topLabelHeight + CGFloat(row) * cellStride
            let rect = CGRect(x: x, y: y, width: cellSize, height: cellSize)
            let color = cellColor(for: snapshot)
            let path = RoundedRectangle(cornerRadius: 2).path(in: rect)
            context.fill(path, with: .color(color))
        }
    }

    // MARK: - Tap Handling

    private func handleTap(at location: CGPoint) {
        let adjustedY = location.y - topLabelHeight
        guard adjustedY >= 0 else { return }

        let col = Int(location.x / cellStride)
        let row = Int(adjustedY / cellStride)

        guard row >= 0, row < 7 else { return }
        let index = col * 7 + row
        guard index >= 0, index < snapshots.count else { return }
        selectedSnapshot = snapshots[index]
    }

    // MARK: - Colors

    private func cellColor(for snapshot: DaySnapshot) -> Color {
        if snapshot.totalHabits == 0 {
            return Color(.systemGray6)
        }
        let pct = snapshot.completionPercentage
        if pct <= 0 {
            return Color(.systemGray5)
        }
        if colorScheme == .dark {
            if pct <= 0.25 {
                return Color(hex: "#2A5F8A") ?? .blue
            } else if pct <= 0.75 {
                return Color(hex: "#3D7AB8") ?? .blue
            } else {
                return Color(hex: "#7B9FE0") ?? .blue
            }
        } else {
            if pct <= 0.25 {
                return Color(hex: "#B3D9F2") ?? .blue
            } else if pct <= 0.75 {
                return Color(hex: "#6BA3D6") ?? .blue
            } else {
                return Color(hex: "#3A5BA0") ?? .blue
            }
        }
    }

    // MARK: - Detail Bar

    private func detailBar(for snapshot: DaySnapshot) -> some View {
        let dateFormatter: DateFormatter = {
            let f = DateFormatter()
            f.dateStyle = .medium
            return f
        }()

        return HStack(spacing: DailyArcSpacing.md) {
            Text(dateFormatter.string(from: snapshot.date))
                .typography(.caption)
                .foregroundStyle(DailyArcTokens.textPrimary)

            Spacer()

            if snapshot.totalHabits > 0 {
                Text("\(Int(snapshot.completionPercentage * 100))%")
                    .typography(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(DailyArcTokens.accent)

                Text("\(snapshot.completedHabits)/\(snapshot.totalHabits)")
                    .typography(.caption)
                    .foregroundStyle(DailyArcTokens.textSecondary)
            } else {
                Text("No data")
                    .typography(.caption)
                    .foregroundStyle(DailyArcTokens.textTertiary)
            }

            if snapshot.moodScore > 0 {
                let moods = ["", "\u{1F614}", "\u{1F615}", "\u{1F610}", "\u{1F642}", "\u{1F604}"]
                Text(moods[safe: snapshot.moodScore] ?? "")
                    .font(.caption)
            }
        }
        .padding(.horizontal, DailyArcSpacing.md)
        .padding(.vertical, DailyArcSpacing.sm)
        .background(DailyArcTokens.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusSmall))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Selected date: \(dateFormatter.string(from: snapshot.date)), \(Int(snapshot.completionPercentage * 100)) percent complete")
    }
}
