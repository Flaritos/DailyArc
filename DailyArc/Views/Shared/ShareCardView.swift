import SwiftUI

/// Share card for streak milestones.
/// Renders a 1080x1350 image (4:5 aspect ratio for social feeds).
/// Background: Sky-to-Indigo gradient. Content: habit emoji, streak count, branding, QR placeholder.
/// Uses ImageRenderer on @MainActor to generate UIImage for sharing.
struct ShareCardView: View {
    let habitEmoji: String
    let habitName: String
    let streakCount: Int

    /// Privacy guard: sanitize health-related habit names.
    private static let healthKeywords: Set<String> = [
        "medication", "therapy", "medicine", "pill", "drug", "treatment",
        "doctor", "psychiatrist", "counseling", "rehab", "addiction",
        "mental health", "anxiety", "depression", "bipolar", "adhd"
    ]

    private var displayName: String {
        let lower = habitName.lowercased()
        for keyword in Self.healthKeywords {
            if lower.contains(keyword) {
                return "a daily habit"
            }
        }
        return habitName
    }

    var body: some View {
        ZStack {
            // Background gradient: Sky to Indigo at 135 degrees
            LinearGradient(
                colors: [
                    Color(hex: "#2563EB") ?? .blue,
                    Color(hex: "#5F27CD") ?? .indigo
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 24) {
                Spacer()

                // Habit emoji
                Text(habitEmoji)
                    .font(.system(size: 80))

                // Streak count
                Text("\(streakCount)")
                    .font(.system(size: 96, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)

                // Label
                Text("\(streakCount)-day streak")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))

                // Attribution
                Text("I just hit a \(streakCount)-day streak with DailyArc!")
                    .font(.system(size: 18))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()

                // Tagline
                Text("Every day adds to your arc.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))

                // Bottom bar: branding + QR placeholder
                HStack {
                    // Wordmark
                    Text("DailyArc")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)

                    Spacer()

                    // QR code placeholder
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white.opacity(0.9))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "qrcode")
                                .font(.system(size: 36))
                                .foregroundStyle(Color(hex: "#2563EB") ?? .blue)
                        )
                }
                .padding(.horizontal, 32)

                // Recipient CTA
                Text("Track your own habits \u{2192} DailyArc")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.bottom, 20)
            }
        }
        .frame(width: 540, height: 675) // @2x = 1080x1350
    }

    // MARK: - Image Generation

    /// Render the share card to a UIImage using ImageRenderer.
    /// Must be called on @MainActor.
    @MainActor
    static func renderImage(habitEmoji: String, habitName: String, streakCount: Int) -> UIImage? {
        let view = ShareCardView(
            habitEmoji: habitEmoji,
            habitName: habitName,
            streakCount: streakCount
        )

        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0 // @2x for 1080x1350 actual pixels
        return renderer.uiImage
    }
}
