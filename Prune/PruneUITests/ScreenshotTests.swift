import XCTest

/// Dedicated screenshot capture test. Run:
///   xcodebuild test -scheme Prune -only-testing:PruneUITests/ScreenshotTests \
///     -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=26.1' \
///     -resultBundlePath build/screenshots.xcresult
/// Then extract PNG attachments from the .xcresult bundle.
final class ScreenshotTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Swipe deck with seeded photos. XCUITest handles the system photo permission
    /// dialog via addUIInterruptionMonitor — something simctl grant cannot reliably do.
    func test_capture_swipeDeck() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-UITEST_OPEN_DECK"]

        let monitor = addUIInterruptionMonitor(withDescription: "Photo permission") { alert in
            let buttons = ["Allow Full Access", "Allow", "OK"]
            for title in buttons {
                if alert.buttons[title].exists {
                    alert.buttons[title].tap()
                    return true
                }
            }
            return false
        }
        defer { removeUIInterruptionMonitor(monitor) }

        app.launch()
        app.tap()  // trigger interruption monitor if dialog is present
        sleep(1)
        app.tap()
        sleep(4)  // let deck load photo

        attachScreenshot(name: "06-swipe-deck")
    }

    private func attachScreenshot(name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
