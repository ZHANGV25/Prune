import Foundation

/// Tracks daily swipe count for freemium gating.
/// Free users get `Self.freeDailyLimit` swipes per day across all feeds;
/// Pro users are unlimited (caller should short-circuit the check).
final class SwipeGateService {
    static let shared = SwipeGateService()

    static let freeDailyLimit = 50

    private let countKey = "swipeCountForDate"
    private let dateKey = "swipeCountDate"
    private let defaults: UserDefaults
    private let calendar: Calendar
    private let clock: () -> Date

    init(defaults: UserDefaults = .standard,
         calendar: Calendar = .current,
         clock: @escaping () -> Date = Date.init) {
        self.defaults = defaults
        self.calendar = calendar
        self.clock = clock
    }

    /// Current swipe count for today, 0-indexed.
    func countToday() -> Int {
        guard let storedDate = defaults.object(forKey: dateKey) as? Date,
              calendar.isDate(storedDate, inSameDayAs: clock()) else {
            return 0
        }
        return defaults.integer(forKey: countKey)
    }

    /// Has the free user hit the daily limit?
    func isExhausted() -> Bool {
        return countToday() >= Self.freeDailyLimit
    }

    /// Swipes remaining today for a free user.
    func remaining() -> Int {
        return max(0, Self.freeDailyLimit - countToday())
    }

    /// Record one swipe. Call only for free users.
    func recordSwipe() {
        let today = clock()
        let current: Int
        if let storedDate = defaults.object(forKey: dateKey) as? Date,
           calendar.isDate(storedDate, inSameDayAs: today) {
            current = defaults.integer(forKey: countKey)
        } else {
            current = 0
        }
        defaults.set(current + 1, forKey: countKey)
        defaults.set(today, forKey: dateKey)
    }

    /// For test isolation / undo-of-undos. Removes one from today's count.
    func rollbackSwipe() {
        let current = defaults.integer(forKey: countKey)
        defaults.set(max(0, current - 1), forKey: countKey)
    }

    /// Reset — used by tests and by "restored purchase" flow in case we ever want to grant today back.
    func reset() {
        defaults.removeObject(forKey: countKey)
        defaults.removeObject(forKey: dateKey)
    }
}
