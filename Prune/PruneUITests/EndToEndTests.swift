import XCTest

/// End-to-end delete flow against a REAL photo library.
///
/// The whole point of this app is deleting photos, and that path had never been
/// executed — the previous version of this test wrapped every step in `XCTSkip`
/// or `if exists`, so it reported success while doing nothing.
///
/// Seed the simulator first (see `tools/seed_simulator_photos.sh`):
///   xcrun simctl addmedia <device> <images...>
///   xcrun simctl privacy <device> grant photos com.isotropic.prune
///
/// This test now fails loudly rather than skipping, so an unseeded simulator is
/// reported as a broken test run instead of a green one.
final class EndToEndTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func test_realLibrary_swipeLeft_commitDelete_showsCelebration() throws {
        let app = XCUIApplication()
        // Opens SwipeDeckView(feedType: .recents) directly — the real PhotoKit deck,
        // not MockDeckView. Avoids depending on home-screen layout.
        app.launchArguments += ["-UITEST_OPEN_DECK"]

        let monitor = addUIInterruptionMonitor(withDescription: "System dialog") { alert in
            for title in ["Allow Full Access", "Allow", "OK", "Continue"] where alert.buttons[title].exists {
                alert.buttons[title].tap()
                return true
            }
            return false
        }
        defer { removeUIInterruptionMonitor(monitor) }

        app.launch()
        app.tap()  // let the interruption monitor service any permission alert

        // The deck header shows "<n> left". Its presence proves PhotoKit returned assets.
        let counter = app.staticTexts.matching(
            NSPredicate(format: "label ENDSWITH %@", " left")
        ).firstMatch
        if !counter.waitForExistence(timeout: 30) {
            // Dump what IS on screen so an unseeded library is distinguishable from
            // a predicate that no longer matches the deck chrome.
            print("=====DECK_DUMP_START=====")
            print("staticTexts: \(app.staticTexts.allElementsBoundByIndex.map(\.label))")
            print("buttons: \(app.buttons.allElementsBoundByIndex.map(\.label))")
            print(app.debugDescription)
            print("=====DECK_DUMP_END=====")
            XCTFail("Swipe deck never loaded any photos. Seed the simulator with "
                    + "`xcrun simctl addmedia` before running this test.")
            return
        }

        let remainingBefore = Int(counter.label.components(separatedBy: " ").first ?? "") ?? 0
        XCTAssertGreaterThan(remainingBefore, 3,
                             "Need >3 seeded photos to exercise the flow; got \(remainingBefore)")

        // Queue three deletes. SwiftUI's DragGesture needs a real press-and-drag —
        // XCUIElement.swipeLeft() on a container does not reliably drive it.
        for _ in 0..<3 {
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.78, dy: 0.45))
            let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.12, dy: 0.45))
            start.press(forDuration: 0.05, thenDragTo: end)
            usleep(800_000)
        }

        // Leaving the deck surfaces the review screen.
        // Back chevron is an SF Symbol inside a Button; its accessibility label is not
        // dependable, so tap its position (top-left of the deck chrome).
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.12, dy: 0.125)).tap()

        let approval = app.staticTexts["For Your Approval"]
        XCTAssertTrue(approval.waitForExistence(timeout: 10),
                      "Review screen did not appear after queueing 3 deletes")

        let deleteButton = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Delete ")
        ).firstMatch
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5), "No Delete button on the review screen")
        deleteButton.tap()

        // iOS always confirms PHPhotoLibrary.deleteAssets. The confirmation is hosted
        // by the system, not the app process, so it is NOT under `app.alerts` —
        // it has to be reached through springboard.
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let candidates = [
            springboard.alerts.buttons["Delete"],
            springboard.buttons["Delete"],
            app.alerts.buttons["Delete"],
            app.buttons["Delete"]
        ]
        var confirmed = false
        let deadline = Date().addingTimeInterval(20)
        while Date() < deadline && !confirmed {
            for button in candidates where button.exists && button.isHittable {
                button.tap()
                confirmed = true
                break
            }
            if !confirmed { usleep(500_000) }
        }
        if !confirmed {
            print("=====CONFIRM_DUMP_START=====")
            print("springboard alerts: \(springboard.alerts.allElementsBoundByIndex.map(\.label))")
            print("springboard buttons: \(springboard.buttons.allElementsBoundByIndex.map(\.label))")
            print("app alerts: \(app.alerts.allElementsBoundByIndex.map(\.label))")
            print("app buttons: \(app.buttons.allElementsBoundByIndex.map(\.label))")
            print("=====CONFIRM_DUMP_END=====")
        }
        XCTAssertTrue(confirmed, "Could not find the system delete confirmation")

        XCTAssertTrue(app.staticTexts["Nice work!"].waitForExistence(timeout: 20),
                      "Celebration screen did not appear, so the delete never committed")
    }
}
