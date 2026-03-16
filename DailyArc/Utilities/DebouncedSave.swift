import Foundation
import SwiftData

/// Coalesces rapid SwiftData writes into a single save() after 300ms of inactivity.
/// Prevents write storms when user rapidly taps habits.
/// Usage: call debouncedSave.trigger() instead of context.save() in all main-actor auto-save paths.
@MainActor
final class DebouncedSave {
    private let context: ModelContext
    private let delay: Duration
    var userCalendar: Calendar
    private var pendingTask: Task<Void, Never>?
    private var retryTask: Task<Void, Never>?

    init(context: ModelContext, delay: Duration = .milliseconds(300), calendar: Calendar = .current) {
        self.context = context
        self.delay = delay
        self.userCalendar = calendar
    }

    /// Published error state for UI observation.
    private(set) var lastError: Error?
    var onError: (@Sendable (Error) -> Void)?
    private var retryCount = 0
    private let maxRetries = 1

    /// Bypass debounce — save immediately. Use for streak-critical, mood, and recovery writes.
    func triggerImmediate() {
        pendingTask?.cancel()
        pendingTask = nil
        performSave()
    }

    /// Call after every model mutation. Cancels any pending save and retry, then restarts the timer.
    func trigger() {
        pendingTask?.cancel()
        retryTask?.cancel()
        retryCount = 0
        pendingTask = Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: self.delay)
            guard !Task.isCancelled else { return }
            self.performSave()
        }
    }

    /// Force immediate save (use for app backgrounding via .scenePhase).
    func flush() {
        pendingTask?.cancel()
        retryTask?.cancel()
        pendingTask = nil
        retryTask = nil
        retryCount = 0
        performSave()
    }

    private func performSave() {
        // GDPR consent withdrawal safety net
        guard !UserDefaults.standard.bool(forKey: "gdprConsentWithdrawn") else { return }
        do {
            try context.save()
            // Update widget data after successful save
            try? WidgetDataService.writeNow(context: context, calendar: userCalendar)
            lastError = nil
            retryCount = 0
        } catch {
            if retryCount < maxRetries {
                retryCount += 1
                retryTask = Task { @MainActor [weak self] in
                    try? await Task.sleep(for: .milliseconds(500))
                    guard let self, !Task.isCancelled else { return }
                    self.performSave()
                }
            } else {
                lastError = error
                retryCount = 0
                onError?(error)
            }
        }
    }
}
