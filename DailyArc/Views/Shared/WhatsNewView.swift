import SwiftUI

struct WhatsNewView: View {
    @Environment(\.dismiss) private var dismiss

    private let features: [(icon: String, title: String, description: String)] = [
        ("sparkles", "Polished Experience", "Enhanced animations, card designs, and visual feedback throughout the app."),
        ("paintpalette.fill", "Accent Colors", "Choose from 10 accent color swatches in Settings to personalize your arc."),
        ("hand.tap.fill", "Better Interactions", "Swipe between days, ripple animations on completion, and micro-interactions on the heat map."),
        ("chart.line.uptrend.xyaxis", "Improved Insights", "Glassmorphic mood cards and animated progress arcs for a premium feel.")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DailyArcSpacing.xl) {
                    // Header
                    VStack(spacing: DailyArcSpacing.md) {
                        AppIconView(size: 80)

                        Text("What's New")
                            .font(.largeTitle.bold())

                        Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, DailyArcSpacing.xl)

                    // Feature list
                    VStack(spacing: DailyArcSpacing.lg) {
                        ForEach(features.indices, id: \.self) { index in
                            HStack(spacing: DailyArcSpacing.md) {
                                Image(systemName: features[index].icon)
                                    .font(.title2)
                                    .foregroundStyle(DailyArcTokens.accent)
                                    .symbolRenderingMode(.hierarchical)
                                    .frame(width: 44, height: 44)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(features[index].title)
                                        .font(.headline)
                                    Text(features[index].description)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }
                            .padding(DailyArcSpacing.md)
                            .background(DailyArcTokens.backgroundSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusMedium))
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Continue") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
