import SwiftUI

/// Date navigation bar: < arrow, center date text ("Today"/"Yesterday"/formatted), > arrow.
/// Right arrow disabled if showing today (can't navigate to future).
struct DateNavigationBar: View {
    let dateLabel: String
    let canNavigateForward: Bool
    let onBack: () -> Void
    let onForward: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(DailyArcTokens.accent)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            HStack(spacing: DailyArcSpacing.xs) {
                Image(systemName: "calendar")
                    .font(.system(size: 14))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(DailyArcTokens.textTertiary)

                Text(dateLabel)
                    .typography(.titleSmall)
                    .foregroundStyle(DailyArcTokens.textPrimary)
            }

            Spacer()

            Button(action: onForward) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(canNavigateForward ? DailyArcTokens.accent : DailyArcTokens.disabled)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!canNavigateForward)
        }
        .padding(.horizontal, DailyArcSpacing.sm)
    }
}

#Preview {
    VStack(spacing: 20) {
        DateNavigationBar(dateLabel: "Today", canNavigateForward: false, onBack: {}, onForward: {})
        DateNavigationBar(dateLabel: "Yesterday", canNavigateForward: true, onBack: {}, onForward: {})
        DateNavigationBar(dateLabel: "Mon, Mar 10", canNavigateForward: true, onBack: {}, onForward: {})
    }
    .padding()
}
