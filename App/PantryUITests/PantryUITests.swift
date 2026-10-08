import XCTest

/// Plays a round through the real screen on a simulator: the gestures CI can't
/// otherwise vouch for. The rules themselves are tested in the package.
final class PantryUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-pantryMuted"]
        app.launch()
        XCTAssertTrue(app.buttons["serve"].waitForExistence(timeout: 30), "the round screen never appeared")
    }

    private func chip(_ id: String) -> XCUIElement {
        app.buttons["chip-\(id)"]
    }

    private var amount: XCUIElement {
        app.staticTexts["amount"]
    }

    func testTheRoundOpensOnMapoTofuWithNothingToServe() {
        XCTAssertTrue(app.buttons["dish-menu"].label.contains("Mapo tofu"), app.buttons["dish-menu"].label)
        XCTAssertTrue(app.staticTexts["brief"].label.hasPrefix("Soft tofu"), app.staticTexts["brief"].label)
        XCTAssertFalse(app.buttons["serve"].isEnabled)
        XCTAssertEqual(app.buttons["serve"].label, "Add something to the wok")
        XCTAssertEqual(app.otherElements["wok"].label, "Wok, empty")
        XCTAssertFalse(amount.exists)
    }

    func testDraggingAChipIntoTheWokAddsIt() {
        chip("firm-tofu").press(forDuration: 0.2, thenDragTo: app.otherElements["wok"])
        XCTAssertTrue(amount.waitForExistence(timeout: 5), "the drop didn't land")
        XCTAssertEqual(amount.label, "100 g")
        XCTAssertEqual(chip("firm-tofu").label, "Firm tofu, 100 g in the wok")
        XCTAssertEqual(app.otherElements["wok"].label, "Wok with 100 g Firm tofu")
    }

    func testDroppingAChipOutsideTheWokAddsNothing() {
        chip("firm-tofu").press(forDuration: 0.2, thenDragTo: app.buttons["serve"])
        XCTAssertFalse(amount.waitForExistence(timeout: 2))
        XCTAssertEqual(chip("firm-tofu").label, "Firm tofu")
        XCTAssertEqual(app.otherElements["wok"].label, "Wok, empty")
    }

    func testTapStepMethodServe() {
        chip("doubanjiang").tap()
        XCTAssertTrue(amount.waitForExistence(timeout: 5))
        XCTAssertEqual(amount.label, "1 tbsp")

        app.buttons["More"].tap()
        XCTAssertEqual(amount.label, "1½ tbsp")
        app.buttons["Less"].tap()
        app.buttons["Less"].tap()
        XCTAssertEqual(amount.label, "2 tsp")

        // A second ingredient takes over the stepper; tapping the first brings it back.
        chip("firm-tofu").tap()
        XCTAssertEqual(amount.label, "100 g")
        chip("doubanjiang").tap()
        XCTAssertEqual(amount.label, "2 tsp")

        XCTAssertFalse(app.buttons["serve"].isEnabled)
        XCTAssertEqual(app.buttons["serve"].label, "Choose how to cook it")
        app.buttons["method-braise"].tap()
        XCTAssertTrue(app.buttons["serve"].isEnabled)
        XCTAssertEqual(app.buttons["serve"].label, "Serve it")

        app.buttons["serve"].tap()
        let score = app.staticTexts["score-total"]
        XCTAssertTrue(score.waitForExistence(timeout: 5), "serving showed no score")
        XCTAssertTrue(score.label.hasSuffix("out of 100"), score.label)

        // The recipe is one tap from the score sheet, never on it (PD-032).
        XCTAssertFalse(app.staticTexts["recipe-title"].exists)
        app.buttons["see-recipe"].tap()
        XCTAssertTrue(app.staticTexts["recipe-title"].waitForExistence(timeout: 5), "the recipe didn't open")
        app.buttons["recipe-done"].tap()
        XCTAssertTrue(score.waitForExistence(timeout: 5))
    }

    func testTakingAnIngredientOutEmptiesTheWok() {
        chip("garlic").tap()
        XCTAssertTrue(amount.waitForExistence(timeout: 5))
        app.buttons["Take Garlic out"].tap()
        XCTAssertFalse(amount.exists)
        XCTAssertEqual(chip("garlic").label, "Garlic, minced")
        XCTAssertEqual(app.otherElements["wok"].label, "Wok, empty")
    }
}
