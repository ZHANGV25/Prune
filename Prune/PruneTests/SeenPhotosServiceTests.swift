import XCTest
@testable import Prune

final class SeenPhotosServiceTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "test.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func test_emptyByDefault() {
        let svc = SeenPhotosService(defaults: defaults)
        XCTAssertFalse(svc.isSeen("anything"))
        XCTAssertTrue(svc.allSeenIds().isEmpty)
    }

    func test_markAsSeen_persists() {
        let svc = SeenPhotosService(defaults: defaults)
        svc.markAsSeen("photo1")
        XCTAssertTrue(svc.isSeen("photo1"))

        // New instance reads from the same defaults
        let reloaded = SeenPhotosService(defaults: defaults)
        XCTAssertTrue(reloaded.isSeen("photo1"))
    }

    func test_markAsSeen_dedupes() {
        let svc = SeenPhotosService(defaults: defaults)
        svc.markAsSeen(["a", "b", "a", "c"])
        XCTAssertEqual(svc.allSeenIds(), ["a", "b", "c"])
    }

    func test_markAsUnseen_removes() {
        let svc = SeenPhotosService(defaults: defaults)
        svc.markAsSeen("photo1")
        svc.markAsUnseen("photo1")
        XCTAssertFalse(svc.isSeen("photo1"))
    }

    func test_markAsUnseen_nonexistent_noop() {
        let svc = SeenPhotosService(defaults: defaults)
        svc.markAsUnseen("never-seen")
        XCTAssertTrue(svc.allSeenIds().isEmpty)
    }

    func test_clearAll_empties() {
        let svc = SeenPhotosService(defaults: defaults)
        svc.markAsSeen(["a", "b", "c"])
        svc.clearAll()
        XCTAssertTrue(svc.allSeenIds().isEmpty)

        let reloaded = SeenPhotosService(defaults: defaults)
        XCTAssertTrue(reloaded.allSeenIds().isEmpty)
    }
}
