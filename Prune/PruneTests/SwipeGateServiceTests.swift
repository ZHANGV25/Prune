import XCTest
@testable import Prune

final class SwipeGateServiceTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!
    private var calendar: Calendar!
    private var fakeClock: () -> Date = { Date() }

    override func setUp() {
        super.setUp()
        suiteName = "test.gate.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        calendar = Calendar(identifier: .gregorian)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    private func makeGate(on date: Date = Date()) -> SwipeGateService {
        SwipeGateService(defaults: defaults, calendar: calendar, clock: { date })
    }

    func test_starts_at_zero() {
        let gate = makeGate()
        XCTAssertEqual(gate.countToday(), 0)
        XCTAssertFalse(gate.isExhausted())
        XCTAssertEqual(gate.remaining(), SwipeGateService.freeDailyLimit)
    }

    func test_record_increments() {
        let gate = makeGate()
        gate.recordSwipe()
        gate.recordSwipe()
        XCTAssertEqual(gate.countToday(), 2)
        XCTAssertEqual(gate.remaining(), SwipeGateService.freeDailyLimit - 2)
    }

    func test_isExhausted_atLimit() {
        let gate = makeGate()
        for _ in 0..<SwipeGateService.freeDailyLimit {
            gate.recordSwipe()
        }
        XCTAssertTrue(gate.isExhausted())
        XCTAssertEqual(gate.remaining(), 0)
    }

    func test_rollback_decreases_count() {
        let gate = makeGate()
        gate.recordSwipe()
        gate.recordSwipe()
        gate.rollbackSwipe()
        XCTAssertEqual(gate.countToday(), 1)
    }

    func test_rollback_does_not_go_negative() {
        let gate = makeGate()
        gate.rollbackSwipe()
        XCTAssertEqual(gate.countToday(), 0)
    }

    func test_new_day_resets_count() {
        // Day 1
        let day1 = calendar.date(from: DateComponents(year: 2026, month: 4, day: 20))!
        let gate1 = makeGate(on: day1)
        for _ in 0..<10 { gate1.recordSwipe() }
        XCTAssertEqual(gate1.countToday(), 10)

        // Day 2 — same user, new day
        let day2 = calendar.date(from: DateComponents(year: 2026, month: 4, day: 21))!
        let gate2 = SwipeGateService(defaults: defaults, calendar: calendar, clock: { day2 })
        XCTAssertEqual(gate2.countToday(), 0, "Crossing midnight should reset count")
        XCTAssertFalse(gate2.isExhausted())
    }

    func test_reset_clears() {
        let gate = makeGate()
        for _ in 0..<10 { gate.recordSwipe() }
        gate.reset()
        XCTAssertEqual(gate.countToday(), 0)
    }
}
