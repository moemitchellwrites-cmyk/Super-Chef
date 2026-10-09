import XCTest

/// Plays a Kitchen round through the real screen on a simulator: the gestures CI can't
/// otherwise vouch for. The rules themselves are tested in the package.
final class PantryUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-pantryMuted", "-pantryFreshProgress", "-pantryFirstDish", "mapo-tofu", "-pantryMeasures", "metric", "-pantryMode", "kitchen"]
        app.launch()
        XCTAssertTrue(app.buttons["serve"].waitForExistence(timeout: 30), "the round screen never appeared")
        // A Kitchen round starts with a bare burner (PD-035). These tests cook in the wok.
        XCTAssertEqual(app.buttons["serve"].label, "Choose a wok or a pot")
        app.buttons["vessel-wok"].tap()
    }

    private func chip(_ id: String) -> XCUIElement {
        app.buttons["chip-\(id)"]
    }

    private var amount: XCUIElement {
        app.staticTexts["amount"]
    }

    func testTheRoundOpensOnMapoTofuWithNothingToServe() {
        XCTAssertTrue(app.staticTexts["dish-name"].label.contains("Mapo tofu"), app.staticTexts["dish-name"].label)
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
        // Tofu and doubanjiang alone: the judge names the first essential that is missing.
        XCTAssertEqual(app.staticTexts["judge-line"].label, "It isn't mapo tofu without Sichuan peppercorn.")
        XCTAssertEqual(app.staticTexts["card-title"].label, "Fry the paste first")

        // The recipe is one tap from the score sheet, never on it (PD-032).
        XCTAssertFalse(app.staticTexts["recipe-title"].exists)
        app.buttons["see-recipe"].tap()
        XCTAssertTrue(app.staticTexts["recipe-title"].waitForExistence(timeout: 5), "the recipe didn't open")
        app.buttons["recipe-done"].tap()
        XCTAssertTrue(score.waitForExistence(timeout: 5))
    }

    /// A phone set to a US region reads ounces and cups; the same round, the same scoring (PD-041).
    func testUSMeasuresReadInOuncesAndCups() {
        app.terminate()
        app.launchArguments = ["-pantryMuted", "-pantryFreshProgress", "-pantryFirstDish", "mapo-tofu", "-pantryMeasures", "us", "-pantryMode", "kitchen"]
        app.launch()
        XCTAssertTrue(app.buttons["vessel-wok"].waitForExistence(timeout: 30), "the round screen never appeared")
        app.buttons["vessel-wok"].tap()
        chip("firm-tofu").tap()
        XCTAssertTrue(amount.waitForExistence(timeout: 5))
        XCTAssertEqual(amount.label, "4 oz")
        chip("stock").tap()
        XCTAssertEqual(amount.label, "1 cup")
    }

    func testHoldingAChipReadsWhatItIsWithoutAddingIt() {
        chip("doubanjiang").press(forDuration: 0.8)
        let note = app.staticTexts["note"]
        XCTAssertTrue(note.waitForExistence(timeout: 3), "holding an ingredient showed no note")
        XCTAssertTrue(note.label.hasPrefix("Doubanjiang."), note.label)
        XCTAssertEqual(app.otherElements["wok"].label, "Wok, empty")
        XCTAssertEqual(chip("doubanjiang").label, "Doubanjiang")

        // Adding something puts the amount back where the note was.
        chip("garlic").tap()
        XCTAssertTrue(amount.waitForExistence(timeout: 5))
        XCTAssertFalse(note.exists)
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

/// Plays a Pantry round through the real screen (PD-025, laid out per PD-031). The app opens in this mode.
final class PantryModeUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-pantryMuted", "-pantryFreshProgress", "-pantryFirstDish", "mapo-tofu", "-pantryMeasures", "metric"]
        app.launch()
        XCTAssertTrue(app.buttons["serve"].waitForExistence(timeout: 30), "the round screen never appeared")
    }

    private func chip(_ id: String) -> XCUIElement {
        app.buttons["chip-\(id)"]
    }

    private var picks: XCUIElement {
        app.otherElements["picks"]
    }

    func testTheAppOpensInPantryModeSayingHowManyEssentialsToFind() {
        XCTAssertTrue(app.buttons["mode-pantry"].isSelected)
        XCTAssertTrue(app.staticTexts["dish-name"].label.contains("Mapo tofu"), app.staticTexts["dish-name"].label)
        XCTAssertEqual(app.staticTexts["ask"].label, "Pick the 6 essentials")
        XCTAssertEqual(picks.label, "0 of 6 picked")
        XCTAssertFalse(app.buttons["serve"].isEnabled)
        XCTAssertFalse(app.buttons["method-braise"].exists, "Pantry mode has no cooking method")
    }

    func testPickReadTakeOutServeAndOpenTheRecipe() {
        chip("firm-tofu").tap()
        // The note leaves by itself after a few seconds, so look for it before anything else:
        // on a slow simulator the other checks can outlast it.
        let note = app.staticTexts["note"]
        XCTAssertTrue(note.waitForExistence(timeout: 3), "touching an ingredient showed no note")
        XCTAssertTrue(note.label.hasPrefix("Firm tofu."), note.label)
        XCTAssertEqual(picks.label, "1 of 6 picked")
        XCTAssertEqual(chip("firm-tofu").label, "Firm tofu, picked")

        // Tapping a picked ingredient takes it back out.
        chip("firm-tofu").tap()
        XCTAssertEqual(picks.label, "0 of 6 picked")

        chip("firm-tofu").tap()
        chip("doubanjiang").tap()
        chip("garlic").tap()
        XCTAssertEqual(picks.label, "3 of 6 picked")
        app.buttons["serve"].tap()
        let score = app.staticTexts["score-total"]
        XCTAssertTrue(score.waitForExistence(timeout: 5), "serving showed no verdict")
        XCTAssertEqual(score.label, "3 of 6 essentials found")
        XCTAssertEqual(app.staticTexts["judge-line"].label, "3 of 6. Start with Sichuan peppercorn.")
        XCTAssertEqual(app.staticTexts["card-title"].label, "Fry the paste first")

        app.buttons["see-recipe"].tap()
        XCTAssertTrue(app.staticTexts["recipe-title"].waitForExistence(timeout: 5), "the recipe didn't open")
    }

    func testHoldingAChipReadsWhatItIsWithoutPickingIt() {
        chip("doubanjiang").press(forDuration: 0.8)
        let note = app.staticTexts["note"]
        XCTAssertTrue(note.waitForExistence(timeout: 3), "holding an ingredient showed no note")
        XCTAssertTrue(note.label.hasPrefix("Doubanjiang."), note.label)
        XCTAssertEqual(picks.label, "0 of 6 picked")
    }

    func testDraggingAChipOntoThePanelPicksIt() {
        chip("firm-tofu").press(forDuration: 0.2, thenDragTo: app.otherElements["wok"])
        XCTAssertEqual(picks.label, "1 of 6 picked")
    }

    func testSwitchingToKitchenKeepsTheDish() {
        app.buttons["mode-kitchen"].tap()
        XCTAssertTrue(app.buttons["method-braise"].waitForExistence(timeout: 5), "Kitchen mode didn't appear")
        XCTAssertTrue(app.staticTexts["dish-name"].label.contains("Mapo tofu"), app.staticTexts["dish-name"].label)

        // The burner is bare: nothing goes in until there is something to put it in.
        XCTAssertEqual(app.buttons["serve"].label, "Choose a wok or a pot")
        XCTAssertEqual(app.otherElements["wok"].label, "No vessel yet")
        chip("firm-tofu").tap()
        XCTAssertFalse(app.staticTexts["amount"].exists, "an ingredient went in with no vessel")

        app.buttons["vessel-pot"].tap()
        XCTAssertEqual(app.otherElements["wok"].label, "Pot, empty")
        XCTAssertEqual(app.buttons["serve"].label, "Add something to the pot")
        chip("firm-tofu").tap()
        XCTAssertEqual(app.otherElements["wok"].label, "Pot with 100 g Firm tofu")

        // Swapping the vessel keeps what is in it.
        app.buttons["vessel-switch"].tap()
        XCTAssertEqual(app.otherElements["wok"].label, "Wok with 100 g Firm tofu")
    }

    // MARK: The session (PB-005)

    private func waitForLabel(_ element: XCUIElement, _ label: String, timeout: TimeInterval = 15) {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", label), object: element)
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: timeout), .completed, "never read \"\(label)\"; it reads \"\(element.label)\"")
    }

    func testFiveRoundsEndInASummaryAndThenANewSession() {
        let progress = app.staticTexts["round-progress"]
        XCTAssertEqual(progress.label, "Sichuan, round 1 of 5")
        var dishes: [String] = []
        for round in 1...5 {
            dishes.append(app.staticTexts["dish-name"].label)
            app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "chip-")).firstMatch.tap()
            app.buttons["serve"].tap()
            let next = app.buttons["next"]
            XCTAssertTrue(next.waitForExistence(timeout: 10), "round \(round) showed no verdict")
            XCTAssertEqual(next.label, round == 5 ? "Finish" : "Next dish")
            next.tap()
            if round < 5 {
                waitForLabel(progress, "Sichuan, round \(round + 1) of 5")
            }
        }
        XCTAssertEqual(dishes.first, "Mapo tofu")
        XCTAssertEqual(Set(dishes).count, 5, "a session deals five different dishes: \(dishes)")

        XCTAssertTrue(app.staticTexts["session-total"].waitForExistence(timeout: 15), "the fifth round led to no summary")
        XCTAssertTrue(app.staticTexts["session-total"].label.contains(" of "), app.staticTexts["session-total"].label)
        app.buttons["new-session"].tap()
        waitForLabel(progress, "Sichuan, round 1 of 5")
        XCTAssertFalse(app.staticTexts["session-total"].exists)
    }
}
