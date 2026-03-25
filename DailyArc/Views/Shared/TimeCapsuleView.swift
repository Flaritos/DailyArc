import SwiftUI
import SwiftData

/// Premium feature: At day 90 of usage, prompts user to write a message to their future self.
/// 90 days later, delivers it with a before/after comparison of habits and mood.
struct TimeCapsuleView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.theme) private var theme

    let totalDaysLogged: Int
    let onDismiss: () -> Void

    @State private var capsuleState: CapsuleState = .checking
    @State private var messageText = ""
    @State private var isSealed = false
    @State private var isDelivered = false
    @State private var revealProgress: CGFloat = 0
    @State private var showStats = false

    enum CapsuleState {
        case checking
        case promptCreate    // Day 90+, no capsule yet
        case sealed          // Capsule exists, waiting for delivery
        case readyToDeliver  // Delivery date reached
        case none            // Not applicable
    }

    // MARK: - Storage Keys

    private static let messageKey = "timeCapsuleMessage"
    private static let createdDateKey = "timeCapsuleCreatedDate"
    private static let deliveryDateKey = "timeCapsuleDeliveryDate"
    private static let deliveredKey = "timeCapsuleDelivered"
    private static let moodAtCreationKey = "timeCapsuleMoodAtCreation"
    private static let habitCountAtCreationKey = "timeCapsuleHabitCountAtCreation"
    private static let streaksAtCreationKey = "timeCapsuleStreaksAtCreation"

    var body: some View {
        Group {
            switch capsuleState {
            case .checking:
                EmptyView()
            case .promptCreate:
                createPromptView
            case .sealed:
                sealedView
            case .readyToDeliver:
                deliveryView
            case .none:
                EmptyView()
            }
        }
        .onAppear { checkCapsuleState() }
    }

    // MARK: - Create Prompt

    private var createPromptView: some View {
        VStack(spacing: DailyArcSpacing.lg) {
            if theme.id == "command" {
                commandCreateView
            } else {
                tactileCreateView
            }
        }
        .padding(DailyArcSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusMedium)
                .fill(theme.id == "command"
                      ? CommandTheme.cyan.opacity(0.04)
                      : DailyArcTokens.backgroundSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusMedium)
                .stroke(theme.id == "command"
                        ? CommandTheme.cyan.opacity(0.2)
                        : DailyArcTokens.premiumGold.opacity(0.3),
                        lineWidth: DailyArcTokens.borderThin)
        )
        .padding(.horizontal, DailyArcSpacing.lg)
    }

    @ViewBuilder
    private var tactileCreateView: some View {
        // Wax seal icon
        ZStack {
            Circle()
                .fill(DailyArcTokens.premiumGold.opacity(0.15))
                .frame(width: 64, height: 64)
            Image(systemName: "seal.fill")
                .font(.system(size: 32))
                .foregroundStyle(DailyArcTokens.premiumGold)
        }

        VStack(spacing: DailyArcSpacing.sm) {
            Text("Time Capsule")
                .typography(.titleSmall)
                .foregroundStyle(theme.textPrimary)

            Text("Write a message to yourself, 90 days from now.")
                .typography(.bodySmall)
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)
        }

        TextField("Dear future me...", text: $messageText, axis: .vertical)
            .lineLimit(3...8)
            .textFieldStyle(.roundedBorder)
            .padding(.horizontal, DailyArcSpacing.sm)

        HStack(spacing: DailyArcSpacing.md) {
            Button {
                onDismiss()
            } label: {
                Text("Not now")
                    .typography(.caption)
                    .foregroundStyle(theme.textTertiary)
            }
            .buttonStyle(.plain)

            Button {
                sealCapsule()
            } label: {
                HStack(spacing: DailyArcSpacing.xs) {
                    Image(systemName: "seal.fill")
                        .font(.caption)
                    Text("Seal it")
                        .typography(.bodySmall)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, DailyArcSpacing.lg)
                .padding(.vertical, DailyArcSpacing.sm)
                .background(
                    Capsule()
                        .fill(DailyArcTokens.premiumGold)
                )
            }
            .buttonStyle(.plain)
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
        }
    }

    @ViewBuilder
    private var commandCreateView: some View {
        VStack(alignment: .leading, spacing: DailyArcSpacing.sm) {
            Text("> TIME CAPSULE")
                .font(.system(.caption, design: .monospaced).weight(.bold))
                .foregroundStyle(CommandTheme.cyan)
                .tracking(1.5)

            Text("> Write a message to your future self")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(CommandTheme.cyan.opacity(0.7))

            Text("> Delivery in: 90 days")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(CommandTheme.cyan.opacity(0.5))
        }

        TextField("> ", text: $messageText, axis: .vertical)
            .lineLimit(3...8)
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(CommandTheme.cyan)
            .textFieldStyle(.roundedBorder)
            .padding(.horizontal, DailyArcSpacing.sm)

        HStack(spacing: DailyArcSpacing.md) {
            Button {
                onDismiss()
            } label: {
                Text("ABORT")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(theme.textTertiary)
            }
            .buttonStyle(.plain)

            Button {
                sealCapsule()
            } label: {
                Text("> SEAL MESSAGE")
                    .font(.system(.caption, design: .monospaced).weight(.bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, DailyArcSpacing.md)
                    .padding(.vertical, DailyArcSpacing.sm)
                    .background(Capsule().fill(CommandTheme.cyan))
                    .shadow(color: CommandTheme.glowCyan, radius: 8)
            }
            .buttonStyle(.plain)
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
        }
    }

    // MARK: - Sealed View (countdown)

    private var sealedView: some View {
        let daysRemaining = daysUntilDelivery()
        return HStack(spacing: DailyArcSpacing.md) {
            if theme.id == "command" {
                Image(systemName: "lock.fill")
                    .font(.title3)
                    .foregroundStyle(CommandTheme.cyan)
                VStack(alignment: .leading, spacing: DailyArcSpacing.xxs) {
                    Text("> CAPSULE: SEALED")
                        .font(.system(.caption2, design: .monospaced).weight(.bold))
                        .foregroundStyle(CommandTheme.cyan)
                    Text("> OPENS IN: \(daysRemaining) DAYS")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(CommandTheme.cyan.opacity(0.6))
                }
            } else {
                ZStack {
                    Circle()
                        .fill(DailyArcTokens.premiumGold.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: "seal.fill")
                        .font(.title3)
                        .foregroundStyle(DailyArcTokens.premiumGold)
                }
                VStack(alignment: .leading, spacing: DailyArcSpacing.xxs) {
                    Text("Time Capsule sealed")
                        .typography(.bodySmall)
                        .fontWeight(.medium)
                        .foregroundStyle(theme.textPrimary)
                    Text("\(daysRemaining) days until delivery")
                        .typography(.caption)
                        .foregroundStyle(theme.textSecondary)
                }
            }
            Spacer()
        }
        .padding(DailyArcSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusMedium)
                .fill(theme.id == "command"
                      ? CommandTheme.cyan.opacity(0.04)
                      : DailyArcTokens.backgroundSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusMedium)
                .stroke(theme.id == "command"
                        ? CommandTheme.cyan.opacity(0.1)
                        : DailyArcTokens.premiumGold.opacity(0.2),
                        lineWidth: DailyArcTokens.borderThin)
        )
        .padding(.horizontal, DailyArcSpacing.lg)
    }

    // MARK: - Delivery View

    private var deliveryView: some View {
        VStack(spacing: DailyArcSpacing.lg) {
            if !isDelivered {
                deliveryPromptView
            } else {
                deliveredContentView
            }
        }
        .padding(DailyArcSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusMedium)
                .fill(theme.id == "command"
                      ? CommandTheme.cyan.opacity(0.04)
                      : DailyArcTokens.backgroundSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusMedium)
                .stroke(theme.id == "command"
                        ? CommandTheme.cyan.opacity(0.2)
                        : DailyArcTokens.premiumGold.opacity(0.4),
                        lineWidth: DailyArcTokens.borderMedium)
        )
        .padding(.horizontal, DailyArcSpacing.lg)
    }

    @ViewBuilder
    private var deliveryPromptView: some View {
        if theme.id == "command" {
            VStack(spacing: DailyArcSpacing.md) {
                Text("[MESSAGE FROM YOUR PAST SELF]")
                    .font(.system(.caption, design: .monospaced).weight(.bold))
                    .foregroundStyle(CommandTheme.cyan)
                    .shadow(color: CommandTheme.glowCyan, radius: 8)

                Text("> OPENING...")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(CommandTheme.cyan.opacity(0.7))

                Button {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        isDelivered = true
                    }
                    markDelivered()
                } label: {
                    Text("> DECRYPT")
                        .font(.system(.caption, design: .monospaced).weight(.bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, DailyArcSpacing.lg)
                        .padding(.vertical, DailyArcSpacing.sm)
                        .background(Capsule().fill(CommandTheme.cyan))
                        .shadow(color: CommandTheme.glowCyan, radius: 12)
                }
                .buttonStyle(.plain)
            }
        } else {
            VStack(spacing: DailyArcSpacing.md) {
                ZStack {
                    Circle()
                        .fill(DailyArcTokens.premiumGold.opacity(0.2))
                        .frame(width: 80, height: 80)
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(DailyArcTokens.premiumGold)
                }
                .scaleEffect(1.0 + sin(Date().timeIntervalSinceReferenceDate * 2) * 0.02)

                Text("A message from your past self")
                    .typography(.titleSmall)
                    .foregroundStyle(theme.textPrimary)

                Text("Sealed 90 days ago")
                    .typography(.caption)
                    .foregroundStyle(theme.textSecondary)

                Button {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        isDelivered = true
                    }
                    markDelivered()
                } label: {
                    HStack(spacing: DailyArcSpacing.xs) {
                        Image(systemName: "envelope.open.fill")
                            .font(.caption)
                        Text("Open it")
                            .typography(.bodySmall)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, DailyArcSpacing.xl)
                    .padding(.vertical, DailyArcSpacing.md)
                    .background(
                        Capsule()
                            .fill(DailyArcTokens.premiumGold)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var deliveredContentView: some View {
        VStack(spacing: DailyArcSpacing.lg) {
            // The message
            VStack(spacing: DailyArcSpacing.sm) {
                if theme.id == "command" {
                    Text("> DECRYPTED MESSAGE:")
                        .font(.system(.caption, design: .monospaced).weight(.bold))
                        .foregroundStyle(CommandTheme.cyan)
                } else {
                    Text("Your message:")
                        .typography(.bodySmall)
                        .fontWeight(.medium)
                        .foregroundStyle(theme.textSecondary)
                }

                Text(loadMessage())
                    .font(theme.id == "command"
                          ? .system(.body, design: .monospaced)
                          : .body)
                    .foregroundStyle(theme.textPrimary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(DailyArcSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusSmall)
                            .fill(theme.id == "command"
                                  ? CommandTheme.cyan.opacity(0.06)
                                  : theme.backgroundPrimary)
                    )
            }

            // Before/after stats
            statsComparisonView

            // Write another button
            Button {
                clearCapsule()
                capsuleState = .promptCreate
            } label: {
                Text(theme.id == "command" ? "> COMPOSE NEW TRANSMISSION" : "Write another")
                    .font(theme.id == "command"
                          ? .system(.caption, design: .monospaced).weight(.semibold)
                          : .caption.weight(.semibold))
                    .foregroundStyle(theme.id == "command" ? CommandTheme.cyan : DailyArcTokens.accent)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Stats Comparison

    @ViewBuilder
    private var statsComparisonView: some View {
        let currentStats = computeCurrentStats()
        let pastMood = UserDefaults.standard.integer(forKey: Self.moodAtCreationKey)
        let pastHabitCount = UserDefaults.standard.integer(forKey: Self.habitCountAtCreationKey)
        let pastStreaks = UserDefaults.standard.integer(forKey: Self.streaksAtCreationKey)

        VStack(alignment: .leading, spacing: DailyArcSpacing.sm) {
            Text(theme.id == "command" ? "> STATUS COMPARISON" : "Then vs. Now")
                .font(theme.id == "command"
                      ? .system(.caption, design: .monospaced).weight(.bold)
                      : .caption.weight(.bold))
                .foregroundStyle(theme.id == "command" ? CommandTheme.cyan : theme.textSecondary)

            HStack(spacing: DailyArcSpacing.lg) {
                statColumn(label: "Then", mood: pastMood, habits: pastHabitCount, streaks: pastStreaks)
                    .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(theme.separator)
                    .frame(width: 1)
                    .frame(height: 60)

                statColumn(label: "Now", mood: currentStats.avgMood, habits: currentStats.habitCount, streaks: currentStats.totalStreaks)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(DailyArcSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: DailyArcTokens.cornerRadiusSmall)
                .fill(theme.id == "command"
                      ? CommandTheme.cyan.opacity(0.04)
                      : theme.backgroundPrimary)
        )
    }

    @ViewBuilder
    private func statColumn(label: String, mood: Int, habits: Int, streaks: Int) -> some View {
        VStack(spacing: DailyArcSpacing.xs) {
            Text(label)
                .font(theme.id == "command"
                      ? .system(.caption2, design: .monospaced).weight(.bold)
                      : .caption2.weight(.bold))
                .foregroundStyle(theme.textTertiary)

            if mood > 0 {
                Text(moodEmoji(for: mood))
                    .font(.title3)
            }

            Text("\(habits) habits")
                .font(theme.id == "command"
                      ? .system(.caption2, design: .monospaced)
                      : .caption2)
                .foregroundStyle(theme.textSecondary)

            HStack(spacing: 2) {
                Image(systemName: "flame.fill")
                    .font(.caption2)
                    .foregroundStyle(DailyArcTokens.streakFire)
                Text("\(streaks)")
                    .font(theme.id == "command"
                          ? .system(.caption2, design: .monospaced)
                          : .caption2)
                    .foregroundStyle(theme.textSecondary)
            }
        }
    }

    // MARK: - State Management

    private func checkCapsuleState() {
        guard StoreKitManager.shared.isPremium else {
            capsuleState = .none
            return
        }

        let delivered = UserDefaults.standard.bool(forKey: Self.deliveredKey)
        let hasMessage = UserDefaults.standard.string(forKey: Self.messageKey) != nil

        if delivered && !hasMessage {
            // Previously delivered and cleared — check if day count warrants new prompt
            // Allow new capsule every 90 days after last delivery
            capsuleState = totalDaysLogged >= 90 ? .promptCreate : .none
            return
        }

        if hasMessage {
            if delivered {
                capsuleState = .readyToDeliver
                isDelivered = true
                return
            }
            if let deliveryDate = UserDefaults.standard.object(forKey: Self.deliveryDateKey) as? Date {
                if Date() >= deliveryDate {
                    capsuleState = .readyToDeliver
                } else {
                    capsuleState = .sealed
                }
            } else {
                capsuleState = .sealed
            }
            return
        }

        // No capsule exists
        if totalDaysLogged >= 90 {
            capsuleState = .promptCreate
        } else {
            capsuleState = .none
        }
    }

    private func sealCapsule() {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let now = Date()
        let deliveryDate = Calendar.current.date(byAdding: .day, value: 90, to: now)!

        UserDefaults.standard.set(trimmed, forKey: Self.messageKey)
        UserDefaults.standard.set(now, forKey: Self.createdDateKey)
        UserDefaults.standard.set(deliveryDate, forKey: Self.deliveryDateKey)
        UserDefaults.standard.set(false, forKey: Self.deliveredKey)

        // Snapshot current stats
        let stats = computeCurrentStats()
        UserDefaults.standard.set(stats.avgMood, forKey: Self.moodAtCreationKey)
        UserDefaults.standard.set(stats.habitCount, forKey: Self.habitCountAtCreationKey)
        UserDefaults.standard.set(stats.totalStreaks, forKey: Self.streaksAtCreationKey)

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            capsuleState = .sealed
            isSealed = true
        }
    }

    private func markDelivered() {
        UserDefaults.standard.set(true, forKey: Self.deliveredKey)
    }

    private func clearCapsule() {
        UserDefaults.standard.removeObject(forKey: Self.messageKey)
        UserDefaults.standard.removeObject(forKey: Self.createdDateKey)
        UserDefaults.standard.removeObject(forKey: Self.deliveryDateKey)
        UserDefaults.standard.set(false, forKey: Self.deliveredKey)
        messageText = ""
        isDelivered = false
    }

    private func loadMessage() -> String {
        UserDefaults.standard.string(forKey: Self.messageKey) ?? ""
    }

    private func daysUntilDelivery() -> Int {
        guard let deliveryDate = UserDefaults.standard.object(forKey: Self.deliveryDateKey) as? Date else {
            return 0
        }
        return max(0, Calendar.current.dateComponents([.day], from: Date(), to: deliveryDate).day ?? 0)
    }

    // MARK: - Stats Computation

    private struct CurrentStats {
        let avgMood: Int
        let habitCount: Int
        let totalStreaks: Int
    }

    private func computeCurrentStats() -> CurrentStats {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today)!

        // Average mood over last 30 days
        let moodDescriptor = FetchDescriptor<MoodEntry>(
            predicate: #Predicate { $0.date >= thirtyDaysAgo }
        )
        let moods = (try? context.fetch(moodDescriptor)) ?? []
        let validMoods = moods.filter { $0.moodScore > 0 }
        let avgMood = validMoods.isEmpty ? 0 : validMoods.reduce(0) { $0 + $1.moodScore } / validMoods.count

        // Active habit count
        let habitDescriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { !$0.isArchived }
        )
        let habits = (try? context.fetch(habitDescriptor)) ?? []

        // Total current streaks
        let totalStreaks = habits.reduce(0) { $0 + $1.currentStreak }

        return CurrentStats(avgMood: avgMood, habitCount: habits.count, totalStreaks: totalStreaks)
    }

    private func moodEmoji(for score: Int) -> String {
        switch score {
        case 1: return "\u{1F614}"
        case 2: return "\u{1F615}"
        case 3: return "\u{1F610}"
        case 4: return "\u{1F642}"
        case 5: return "\u{1F604}"
        default: return "\u{2014}"
        }
    }
}

// MARK: - Static Helper

extension TimeCapsuleView {
    /// Check if the Time Capsule UI should be shown on TodayView.
    static func shouldShow(totalDaysLogged: Int) -> Bool {
        guard StoreKitManager.shared.isPremium else { return false }

        let delivered = UserDefaults.standard.bool(forKey: deliveredKey)
        let hasMessage = UserDefaults.standard.string(forKey: messageKey) != nil

        // Show if: ready to deliver, or capsule is sealed, or at day 90+ with no capsule
        if hasMessage {
            if delivered {
                // Already delivered and opened — don't keep showing
                return false
            }
            return true // sealed or ready to deliver
        }

        // No capsule — show prompt at day 90+
        return totalDaysLogged >= 90
    }
}
