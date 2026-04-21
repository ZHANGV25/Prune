import XCTest

final class PruneUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func test_onboarding_appearsOnFirstLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-UITEST_RESET_ONBOARDING"]
        app.launch()

        XCTAssertTrue(
            app.staticTexts["Clean your\nphoto library\nin minutes"].waitForExistence(timeout: 5)
            || app.buttons["Continue"].waitForExistence(timeout: 5),
            "Onboarding should appear on first launch"
        )
    }

    func test_onboarding_progressThroughPages() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-UITEST_RESET_ONBOARDING"]
        app.launch()

        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5), "Continue button visible on page 1")
        continueButton.tap()

        XCTAssertTrue(app.staticTexts["Your photos\nstay on device"].waitForExistence(timeout: 2),
                      "Privacy page appears on page 2")

        XCTAssertTrue(app.buttons["Allow Access"].waitForExistence(timeout: 2),
                      "Allow Access button appears on the final page")
    }

    func test_home_loadsAfterOnboarding() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-UITEST_SKIP_ONBOARDING"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Pruned"].waitForExistence(timeout: 5),
                      "Home title should appear when onboarding is skipped")
    }
}
