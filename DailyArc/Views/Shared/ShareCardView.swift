import SwiftUI

// MARK: - Share Card Type

/// The type of share card to render, each with its own data and layout.
enum ShareCardType {
    case streakMilestone(habitName: String, emoji: String, streak: Int, message: String)
    case weeklyRecap(habitsCompleted: Int, moodAverage: String, topHabit: String)
    case badgeUnlock(badgeName: String, badgeEmoji: String, dateEarned: Date)
}

// MARK: - ShareCardView

/// Share card for social sharing.
/// Renders a 1080x1350 image (4:5 aspect ratio for social feeds).
/// Background: brand gradient. Content varies by card type.
/// Uses ImageRenderer on @MainActor to generate UIImage for sharing.
struct ShareCardView: View {
    let cardType: ShareCardType

    /// Privacy guard: sanitize health-related habit names.
    private static let healthKeywords: Set<String> = [
        "medication", "therapy", "medicine", "pill", "drug", "treatment",
        "doctor", "psychiatrist", "counseling", "rehab", "addiction",
        "mental health", "anxiety", "depression", "bipolar", "adhd"
    ]

    private static func sanitizeName(_ name: String) -> String {
        let lower = name.lowercased()
        for keyword in healthKeywords {
            if lower.contains(keyword) {
                return "a daily habit"
            }
        }
        return name
    }

    // MARK: - Brand Colors

    private static let gradientStart = Color(hex: "#2563EB") ?? .blue
    private static let gradientEnd = Color(hex: "#5F27CD") ?? .indigo
    private static let goldAccent = Color(hex: "#FFD700") ?? .yellow

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Self.gradientStart, Self.gradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 24) {
                Spacer()

                cardContent

                Spacer()

                brandingFooter
            }
        }
        .frame(width: 540, height: 675) // @2x = 1080x1350
    }

    // MARK: - Card Content (per type)

    @ViewBuilder
    private var cardContent: some View {
        switch cardType {
        case .streakMilestone(let habitName, let emoji, let streak, let message):
            streakMilestoneContent(
                habitName: habitName,
                emoji: emoji,
                streak: streak,
                message: message
            )

        case .weeklyRecap(let habitsCompleted, let moodAverage, let topHabit):
            weeklyRecapContent(
                habitsCompleted: habitsCompleted,
                moodAverage: moodAverage,
                topHabit: topHabit
            )

        case .badgeUnlock(let badgeName, let badgeEmoji, let dateEarned):
            badgeUnlockContent(
                badgeName: badgeName,
                badgeEmoji: badgeEmoji,
                dateEarned: dateEarned
            )
        }
    }

    // MARK: - Streak Milestone

    private func streakMilestoneContent(
        habitName: String,
        emoji: String,
        streak: Int,
        message: String
    ) -> some View {
        VStack(spacing: 24) {
            Text(emoji)
                .font(.system(size: 80))

            Text("\(streak)")
                .font(.system(size: 96, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)

            Text("\(streak)-day streak")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))

            if !message.isEmpty {
                Text(message)
                    .font(.system(size: 18))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            } else {
                Text("I just hit a \(streak)-day streak with DailyArc!")
                    .font(.system(size: 18))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }

    // MARK: - Weekly Recap

    private func weeklyRecapContent(
        habitsCompleted: Int,
        moodAverage: String,
        topHabit: String
    ) -> some View {
        VStack(spacing: 32) {
            // Title
            Text("Weekly Recap")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            // Stats grid
            VStack(spacing: 20) {
                statRow(label: "Habits Completed", value: "\(habitsCompleted)")
                statRow(label: "Mood Average", value: moodAverage)
                statRow(label: "Top Habit", value: Self.sanitizeName(topHabit))
            }
            .padding(.horizontal, 48)

            // Summary
            Text("Another week of building your arc.")
                .font(.system(size: 18))
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.7))

            Spacer()

            Text(value)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.1))
        )
    }

    // MARK: - Badge Unlock

    private func badgeUnlockContent(
        badgeName: String,
        badgeEmoji: String,
        dateEarned: Date
    ) -> some View {
        VStack(spacing: 24) {
            // Badge icon with gold ring
            ZStack {
                Circle()
                    .stroke(Self.goldAccent, lineWidth: 4)
                    .frame(width: 120, height: 120)

                Text(badgeEmoji)
                    .font(.system(size: 64))
            }

            Text("Badge Unlocked!")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Self.goldAccent)

            Text(badgeName)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)

            Text("Earned on \(dateEarned, format: .dateTime.month(.wide).day().year())")
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    // MARK: - Branding Footer

    private var brandingFooter: some View {
        VStack(spacing: 12) {
            // Tagline
            Text("Every day adds to your arc.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))

            // Bottom bar: branding + QR placeholder
            HStack {
                Text("DailyArc")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                RoundedRectangle(cornerRadius: 4)
                    .fill(.white.opacity(0.9))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "qrcode")
                            .font(.system(size: 36))
                            .foregroundStyle(Self.gradientStart)
                    )
            }
            .padding(.horizontal, 32)

            // CTA
            Text("Track your own habits \u{2192} DailyArc")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.bottom, 20)
        }
    }

    // MARK: - Image Generation

    /// Render the share card to a UIImage using ImageRenderer.
    /// Must be called on @MainActor.
    @MainActor
    static func renderImage(cardType: ShareCardType) -> UIImage? {
        let view = ShareCardView(cardType: cardType)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0 // @2x for 1080x1350 actual pixels
        return renderer.uiImage
    }

    /// Convenience: render a streak milestone image (backward-compatible).
    @MainActor
    static func renderImage(habitEmoji: String, habitName: String, streakCount: Int) -> UIImage? {
        renderImage(cardType: .streakMilestone(
            habitName: habitName,
            emoji: habitEmoji,
            streak: streakCount,
            message: ""
        ))
    }
}

// MARK: - ShareButton

/// A reusable share button that renders a ShareCardView as an image and presents ShareLink.
struct ShareButton: View {
    let cardType: ShareCardType
    let label: String

    init(cardType: ShareCardType, label: String = "Share") {
        self.cardType = cardType
        self.label = label
    }

    @State private var renderedImage: UIImage?

    var body: some View {
        Group {
            if let image = renderedImage {
                ShareLink(
                    item: Image(uiImage: image),
                    preview: SharePreview("DailyArc", image: Image(uiImage: image))
                ) {
                    Label(label, systemImage: "square.and.arrow.up")
                }
            } else {
                Button {
                    renderedImage = ShareCardView.renderImage(cardType: cardType)
                } label: {
                    Label(label, systemImage: "square.and.arrow.up")
                }
            }
        }
        .onAppear {
            renderedImage = ShareCardView.renderImage(cardType: cardType)
        }
    }
}
