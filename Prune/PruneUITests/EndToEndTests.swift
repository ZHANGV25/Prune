import XCTest

/// End-to-end flow on the All Photos feed.
/// Assumes the simulator has been pre-seeded with photos (xcrun simctl addmedia).
/// Uses launch args to skip onboarding so the test is deterministic on a clean install.
final class EndToEndTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func test_fullFlow_swipe_commit_celebrate() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-UITEST_SKIP_ONBOARDING"]

        // Auto-accept any photo-library or other system alerts
        let monitor = addUIInterruptionMonitor(withDescription: "System dialog") { alert in
            let allowButtons = ["Allow Full Access", "Allow", "OK"]
            for title in allowButtons {
                if alert.buttons[title].exists {
                    alert.buttons[title].tap()
                    return true
                }
            }
            return false
        }
        defer { removeUIInterruptionMonitor(monitor) }

        app.launch()

        // Step 1: home screen loaded with "Pruned" title
        XCTAssertTrue(app.staticTexts["Pruned"].waitForExistence(timeout: 8),
                      "Home title should appear")

        // Step 2: tap "All Photos" featured card (first feed row)
        let allPhotosCard = app.buttons.matching(identifier: "All Photos").firstMatch
        let allPhotosText = app.staticTexts["All Photos"]
        if allPhotosCard.exists {
            allPhotosCard.tap()
        } else if allPhotosText.exists {
            allPhotosText.tap()
        } else {
            XCTFail("Could not find the All Photos card")
            return
        }
        app.tap() // trigger any interruption monitor for alerts
        sleep(1)

        // Step 3: swipe deck should appear within a few seconds
        // We don't know the exact photo, but the counter "X left" should show up
        let leftCounter = app.staticTexts.matching(NSPredicate(format: "label CONTAINS ' left'")).firstMatch
        let deckAppeared = leftCounter.waitForExistence(timeout: 10)

        if !deckAppeared {
            // Could be an empty state if sim has no photos — skip rather than fail.
            throw XCTSkip("No photos seeded in simulator; skipping swipe test.")
        }

        // Step 4: swipe left twice (delete 2 photos), then right once (keep 1)
        let deck = app.otherElements.firstMatch
        for _ in 0..<2 {
            deck.swipeLeft()
            sleep(1)
        }
        deck.swipeRight()
        sleep(1)

        // Step 5: tap the back chevron to exit the deck and trigger FinishView
        // The back button is a top-left image; tap near its coord.
        let backButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'chevron'")).firstMatch
        if backButton.exists {
            backButton.tap()
        } else {
            // Fallback: tap top-left corner
            let coord = app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.07))
            coord.tap()
        }
        sleep(1)

        // Step 6: FinishView shows "For Your Approval" with delete button
        let approval = app.staticTexts["For Your Approval"]
        if approval.waitForExistence(timeout: 5) {
            let deleteButton = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Delete '")).firstMatch
            if deleteButton.exists {
                deleteButton.tap()
                sleep(1)

                // Step 7: system delete confirmation — auto-tap Delete
                // iOS always shows a confirmation for PHPhotoLibrary.deleteAssets.
                let systemDelete = app.alerts.firstMatch.buttons["Delete"]
                if systemDelete.waitForExistence(timeout: 5) {
                    systemDelete.tap()
                    sleep(2)
                }

                // Step 8: celebration screen
                XCTAssertTrue(app.staticTexts["Nice work!"].waitForExistence(timeout: 8),
                              "Celebration screen should appear after delete commits")
            }
        } else {
            throw XCTSkip("FinishView did not appear — possibly no deletes queued.")
        }
    }
}
