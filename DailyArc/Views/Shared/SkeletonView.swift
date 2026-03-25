import SwiftUI

/// Shimmer skeleton placeholder for loading states
struct SkeletonView: View {
    var width: CGFloat? = nil
    var height: CGFloat = 16
    var cornerRadius: CGFloat = 8

    @State private var shimmer = false

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color(hex: "#E5E5EA")!)
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [.clear, Color(hex: "#D1D1D6")!.opacity(0.5), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmer ? 200 : -200)
            )
            .clipped()
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    shimmer = true
                }
            }
    }
}

/// Today View skeleton
struct TodaySkeletonView: View {
    var body: some View {
        VStack(spacing: DailyArcSpacing.lg) {
            // Date bar
            SkeletonView(width: 150, height: 24)

            // Mood section - 5 circles
            HStack(spacing: DailyArcSpacing.lg) {
                ForEach(0..<5, id: \.self) { _ in
                    SkeletonView(width: 60, height: 60, cornerRadius: 30)
                }
            }

            // 3 habit rows
            ForEach(0..<3, id: \.self) { _ in
                HStack {
                    SkeletonView(width: 40, height: 40, cornerRadius: 20)
                    VStack(alignment: .leading, spacing: 4) {
                        SkeletonView(width: 120, height: 16)
                        SkeletonView(width: 60, height: 12)
                    }
                    Spacer()
                    SkeletonView(width: 36, height: 36, cornerRadius: 18)
                }
                .padding(.horizontal, DailyArcSpacing.lg)
            }
        }
        .padding(.top, DailyArcSpacing.xl)
    }
}

/// Stats View skeleton
struct StatsSkeletonView: View {
    var body: some View {
        VStack(spacing: DailyArcSpacing.lg) {
            // Heat map
            SkeletonView(height: 102, cornerRadius: 8)

            // Trend chart
            SkeletonView(height: 200, cornerRadius: 12)

            // 2 insight cards
            HStack(spacing: DailyArcSpacing.md) {
                SkeletonView(height: 120, cornerRadius: 12)
                SkeletonView(height: 120, cornerRadius: 12)
            }
        }
        .padding(.horizontal, DailyArcSpacing.lg)
    }
}

#Preview {
    VStack(spacing: 32) {
        TodaySkeletonView()
        Divider()
        StatsSkeletonView()
    }
    .padding()
}
