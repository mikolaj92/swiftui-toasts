import XCTest

@MainActor
final class FocusWhileToastTests: XCTestCase {
    func testRemoteCanMoveFocusWhileTheToastIsUp() {
        let app = XCUIApplication()
        app.launch()

        let toast = app.descendants(matching: .any)["island-toast"]
        XCTAssertTrue(toast.waitForExistence(timeout: 8))
        XCTAssertFalse(toast.hasFocus)

        let one = app.buttons["one"]
        let two = app.buttons["two"]
        XCTAssertTrue(one.waitForExistence(timeout: 8))
        XCTAssertTrue(waitForFocus(on: one), focusDump(app))

        XCUIRemote.shared.press(.down)
        XCTAssertTrue(waitForFocus(on: two), focusDump(app))
        XCTAssertFalse(toast.hasFocus)

        XCUIRemote.shared.press(.up)
        XCTAssertTrue(waitForFocus(on: one), focusDump(app))
        XCTAssertFalse(toast.hasFocus)
    }

    private func focusDump(_ app: XCUIApplication) -> String {
        let focused = app.descendants(matching: .any).allElementsBoundByIndex.filter { $0.hasFocus }
        let described = focused.map { "type=\($0.elementType.rawValue) id=\($0.identifier) label=\($0.label)" }
        return described.isEmpty ? "nothing has focus" : described.joined(separator: " | ")
    }

    private func waitForFocus(on element: XCUIElement) -> Bool {
        let focused = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "hasFocus == true"),
            object: element
        )
        return XCTWaiter().wait(for: [focused], timeout: 5) == .completed
    }
}
