import Foundation

enum JournalingPrompts {
    // 60% reflective
    private static let reflective = [
        "What made you smile today?",
        "What's on your mind?",
        "How did you take care of yourself today?",
        "What challenged you today?",
        "Who made a difference in your day?",
        "What would you do differently?",
        "Describe today in one word.",
        "What gave you energy today?",
        "What drained your energy?",
        "Name one small win from today.",
        "What did you learn today?",
        "How did you help someone today?",
        "What surprised you today?",
        "What's something you did just for fun?",
        "What's weighing on your mind?",
        "What habit felt easiest today?",
        "What's shaping your arc this week?",
        "What part of today's arc would you replay?",
        "If your arc had a theme this week, what would it be?",
    ]

    // 25% gratitude
    private static let gratitude = [
        "One thing you're grateful for?",
        "What made today a good day?",
        "Who are you thankful for right now?",
        "What's one thing your arc taught you recently?",
        "What simple pleasure did you enjoy today?",
        "What's something you often take for granted?",
        "What made you laugh today?",
        "What's a recent moment you'd love to relive?",
    ]

    // 15% forward-looking
    private static let forwardLooking = [
        "What are you looking forward to?",
        "What would make tomorrow better?",
        "Where is your arc heading?",
        "What's one goal for the rest of the week?",
        "What do you want to feel more of?",
    ]

    private static let allPrompts: [String] = reflective + gratitude + forwardLooking

    /// Select a deterministic prompt for a given date using StableHash.
    /// Same date always returns same prompt. Different dates rotate through all prompts.
    static func prompt(for date: Date) -> String {
        let cal = Calendar.current
        let dayOfYear = cal.ordinality(of: .day, in: .year, for: date) ?? 1
        let year = cal.component(.year, from: date)
        let hashInput = "\(dayOfYear)-\(year)"
        let index = Int(StableHash.hash(hashInput)) % allPrompts.count
        return allPrompts[index]
    }

    /// Dynamic habit-aware prompt when data is available.
    static func habitAwarePrompt(topHabitName: String) -> String {
        "How did \(topHabitName) feel today?"
    }

    /// Energy-contextual prompt.
    static func energyPrompt(energyScore: Int) -> String {
        "Your energy was \(energyScore) — what do you think drove that?"
    }
}
