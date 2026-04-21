import XCTest
@testable import Prune

final class TimeframeMatcherTests: XCTestCase {
    private var calendar: Calendar!
    private var now: Date!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        // Fixed reference: 2026-04-15 15:00 America/New_York
        var components = DateComponents()
        components.year = 2026; components.month = 4; components.day = 15
        components.hour = 15; components.minute = 0
        now = calendar.date(from: components)!
    }

    // MARK: - Today

    func test_today_matchesSameDay() {
        let morning = calendar.date(bySettingHour: 8, minute: 30, second: 0, of: now)!
        XCTAssertTrue(PhotoLibraryService.does(morning, match: "Today", using: calendar, now: now))
    }

    func test_today_excludesYesterday() {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        XCTAssertFalse(PhotoLibraryService.does(yesterday, match: "Today", using: calendar, now: now))
    }

    // MARK: - Yesterday

    func test_yesterday_matches() {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        XCTAssertTrue(PhotoLibraryService.does(yesterday, match: "Yesterday", using: calendar, now: now))
    }

    func test_yesterday_excludesToday() {
        XCTAssertFalse(PhotoLibraryService.does(now, match: "Yesterday", using: calendar, now: now))
    }

    // MARK: - Last 7 Days

    func test_last7Days_includesToday() {
        XCTAssertTrue(PhotoLibraryService.does(now, match: "Last 7 Days", using: calendar, now: now))
    }

    func test_last7Days_includes6DaysAgo() {
        let date = calendar.date(byAdding: .day, value: -6, to: now)!
        XCTAssertTrue(PhotoLibraryService.does(date, match: "Last 7 Days", using: calendar, now: now))
    }

    func test_last7Days_excludes8DaysAgo() {
        let date = calendar.date(byAdding: .day, value: -8, to: now)!
        XCTAssertFalse(PhotoLibraryService.does(date, match: "Last 7 Days", using: calendar, now: now))
    }

    // MARK: - Last 30 Days

    func test_last30Days_includes29DaysAgo() {
        let date = calendar.date(byAdding: .day, value: -29, to: now)!
        XCTAssertTrue(PhotoLibraryService.does(date, match: "Last 30 Days", using: calendar, now: now))
    }

    func test_last30Days_excludes31DaysAgo() {
        let date = calendar.date(byAdding: .day, value: -31, to: now)!
        XCTAssertFalse(PhotoLibraryService.does(date, match: "Last 30 Days", using: calendar, now: now))
    }

    // MARK: - Older

    func test_older_matches31DaysAgo() {
        let date = calendar.date(byAdding: .day, value: -31, to: now)!
        XCTAssertTrue(PhotoLibraryService.does(date, match: "Older", using: calendar, now: now))
    }

    func test_older_excludesToday() {
        XCTAssertFalse(PhotoLibraryService.does(now, match: "Older", using: calendar, now: now))
    }

    // MARK: - Unknown frame

    func test_unknownFrame_returnsTrue() {
        // Current impl returns true for unknown — documents behavior.
        XCTAssertTrue(PhotoLibraryService.does(now, match: "Gibberish", using: calendar, now: now))
    }
}
