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

    /// Swipe deck mock. Bypasses PHPhotoLibrary via -UITEST_SCREENSHOT_DECK
    /// so the simulator never shows the permission dialog and no real photos
    /// are needed. Renders a procedural sunset-mountain "photo" with the deck
    /// chrome (back button, counter, KEEP/DELETE labels, mid-swipe indicator).
    func test_capture_swipeDeck() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-UITEST_SCREENSHOT_DECK"]
        app.launch()
        sleep(1)
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
