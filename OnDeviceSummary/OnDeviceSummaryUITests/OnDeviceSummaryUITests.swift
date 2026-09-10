import XCTest

nonisolated final class OnDeviceSummaryUITests: XCTestCase {
    @MainActor
    func testAppLaunches() {
        let app = XCUIApplication()
        app.launch()
    }
}
