import XCTest
import PantryScoring
@testable import PantryGame

final class RoundTests: XCTestCase {
    private func makeRound(_ dishId: String = "mapo-tofu", seed: UInt64 = 7) throws -> (Round, ContentLibrary) {
        let library = try ContentLibrary.bundled()
        let dish = try XCTUnwrap(library.dish(id: dishId))
        var round = Round(dish: dish, library: library, seed: seed)
        round.place(.wok)
        return (round, library)
    }

    func testPaletteOffersEveryProfileIngredientOnce() throws {
        let (round, _) = try makeRound()
        XCTAssertEqual(Set(round.palette.map(\.id)), Set(round.dish.palette))
        XCTAssertEqual(round.palette.count, Set(round.dish.palette).count)
    }

    func testPaletteOrderIsShuffledButRepeatableFromTheSeed() throws {
        let (first, _) = try makeRound(seed: 7)
        let (again, _) = try makeRound(seed: 7)
        let (other, _) = try makeRound(seed: 8)
        XCTAssertEqual(first.palette.map(\.id), again.palette.map(\.id))
        XCTAssertNotEqual(first.palette.map(\.id), other.palette.map(\.id))
        XCTAssertNotEqual(first.palette.map(\.id), first.dish.palette, "authored order puts the decoys last")
    }

    func testMethodChoicesAreTheMethodsTheCuisineUses() throws {
        let (round, library) = try makeRound()
        XCTAssertEqual(Set(round.methodChoices), Set(library.dishes.flatMap(\.methods)))
        XCTAssertGreaterThan(round.methodChoices.count, round.dish.methods.count, "wrong methods must be on offer too")
        for dish in library.dishes {
            XCTAssertTrue(dish.methods.allSatisfy(round.methodChoices.contains))
        }
    }

    func testAddStartsAtOneOfTheDefaultUnitAndSelects() throws {
        var (round, _) = try makeRound()
        XCTAssertEqual(round.add("doubanjiang"), .added)
        XCTAssertEqual(round.measure(for: "doubanjiang")?.label, "1 tbsp")
        XCTAssertEqual(round.add("firm-tofu"), .added)
        XCTAssertEqual(round.measure(for: "firm-tofu")?.label, "100 g")
        XCTAssertEqual(round.selectedId, "firm-tofu")
    }

    func testAddingTwiceKeepsOneEntryAndItsAmount() throws {
        var (round, _) = try makeRound()
        round.add("garlic")
        round.step("garlic", by: 2)
        round.add("ginger")
        XCTAssertEqual(round.add("garlic"), .alreadyIn)
        XCTAssertEqual(round.entries.count, 2)
        XCTAssertEqual(round.selectedId, "garlic")
        XCTAssertEqual(round.measure(for: "garlic")?.label, "2 tbsp")
    }

    func testIngredientsOffThePaletteAreRefused() throws {
        var (round, _) = try makeRound()
        XCTAssertEqual(round.add("parmesan"), .notOffered)
        XCTAssertEqual(round.add("no-such-thing"), .notOffered)
        XCTAssertTrue(round.entries.isEmpty)
        XCTAssertNil(round.selectedId)
    }

    func testStepClampsAtBothEndsOfTheLadder() throws {
        var (round, _) = try makeRound()
        round.add("sugar")
        XCTAssertTrue(round.step("sugar", by: -100))
        XCTAssertEqual(round.measure(for: "sugar")?.label, "pinch")
        XCTAssertFalse(round.step("sugar", by: -1), "already at the bottom")
        XCTAssertTrue(round.step("sugar", by: 100))
        XCTAssertEqual(round.measure(for: "sugar")?.label, "4 cups")
        XCTAssertFalse(round.step("sugar", by: 1))
        XCTAssertFalse(round.step("garlic", by: 1), "not in the wok")
    }

    func testRemoveMovesSelectionToTheLastThingAdded() throws {
        var (round, _) = try makeRound()
        round.add("garlic")
        round.add("ginger")
        XCTAssertTrue(round.remove("ginger"))
        XCTAssertEqual(round.selectedId, "garlic")
        XCTAssertTrue(round.remove("garlic"))
        XCTAssertNil(round.selectedId)
        XCTAssertFalse(round.remove("garlic"))
    }

    func testSelectIgnoresIngredientsNotInTheWok() throws {
        var (round, _) = try makeRound()
        round.add("garlic")
        round.select("ginger")
        XCTAssertEqual(round.selectedId, "garlic")
        round.select(nil)
        XCTAssertNil(round.selectedId)
    }

    func testCannotServeWithoutIngredientsOrWithoutAMethod() throws {
        var (round, _) = try makeRound()
        XCTAssertFalse(round.canServe)
        XCTAssertNil(round.attempt())
        XCTAssertEqual(round.servePrompt, "Add something to the wok")
        round.add("firm-tofu")
        XCTAssertFalse(round.canServe)
        XCTAssertNil(round.attempt())
        XCTAssertEqual(round.servePrompt, "Choose how to cook it")
        round.choose(.braise)
        XCTAssertTrue(round.canServe)
        XCTAssertNil(round.servePrompt)
    }

    func testAttemptCarriesLinesVesselAndMethod() throws {
        var (round, library) = try makeRound()
        round.add("firm-tofu")
        round.step("firm-tofu", by: 7)
        round.add("doubanjiang")
        round.choose(.braise)
        let attempt = try XCTUnwrap(round.attempt())
        XCTAssertEqual(attempt.dishId, "mapo-tofu")
        XCTAssertEqual(attempt.vessel, .wok)
        XCTAssertEqual(attempt.method, .braise)
        XCTAssertEqual(attempt.lines, [
            Attempt.Line(ingredientId: "firm-tofu", amount: 400, unit: .grams),
            Attempt.Line(ingredientId: "doubanjiang", amount: 1, unit: .tbsp),
        ])
        let breakdown = try library.score(attempt)
        XCTAssertFalse(breakdown.misses.contains { $0.kind == .unmeasurable || $0.kind == .unknownIngredient })
    }

    func testAWrongMethodCostsTechniquePoints() throws {
        var (right, library) = try makeRound()
        right.add("firm-tofu")
        var wrong = right
        right.choose(.braise)
        wrong.choose(.deepFry)
        let rightScore = try library.score(XCTUnwrap(right.attempt()))
        let wrongScore = try library.score(XCTUnwrap(wrong.attempt()))
        XCTAssertEqual(rightScore.technique, 10)
        XCTAssertEqual(wrongScore.technique, 6)
        XCTAssertTrue(wrongScore.misses.contains(Miss(.wrongMethod, "deep-fry")))
    }

    func testClearEmptiesTheRound() throws {
        var (round, _) = try makeRound()
        round.add("garlic")
        round.choose(.stirFry)
        round.clear()
        XCTAssertTrue(round.entries.isEmpty)
        XCTAssertNil(round.method)
        XCTAssertNil(round.selectedId)
    }

    func testPieceCountGrowsWithTheAmount() throws {
        var (round, _) = try makeRound()
        XCTAssertEqual(round.pieceCount(for: "garlic"), 0)
        round.add("garlic")
        round.step("garlic", by: -100)
        XCTAssertEqual(round.pieceCount(for: "garlic"), 1)
        round.step("garlic", by: 100)
        XCTAssertEqual(round.pieceCount(for: "garlic"), 4)
    }

    func testChipNamesAreShortDistinctAndDontNameACuisine() throws {
        let library = try ContentLibrary.bundled()
        XCTAssertEqual(library.ingredient(id: "doubanjiang")?.chipName, "Doubanjiang")
        XCTAssertEqual(library.ingredient(id: "sugar")?.chipName, "Sugar")
        XCTAssertEqual(Set(library.ingredients.map(\.chipName)).count, library.ingredients.count)
        // Where an ingredient comes from is what the player is here to learn. "Sichuan pepper"
        // and "Shaoxing wine" are the things' names; a decoy labelled with its home is an answer key.
        let giveaways = ["hunan", "cantonese", "thai", "vietnam", "japan", "korea", "ital", "india"]
        for ingredient in library.ingredients {
            // Chip names are shown in lists; a comma inside one reads as two ingredients ("Sichuan pepper, whole").
            XCTAssertFalse(ingredient.chipName.contains(","), "\(ingredient.id): \"\(ingredient.chipName)\" has a comma")
            XCTAssertLessThanOrEqual(ingredient.chipName.count, ContentLibrary.shortNameLimit, ingredient.id)
            for label in [ingredient.name, ingredient.chipName] {
                for word in giveaways {
                    XCTAssertFalse(label.lowercased().contains(word), "\(ingredient.id): \"\(label)\" names a cuisine")
                }
            }
        }
    }

    // MARK: Vessel (PD-035)

    func testARoundStartsWithABareBurnerAndTakesNothingUntilAVesselIsChosen() throws {
        let library = try ContentLibrary.bundled()
        var round = Round(dish: try XCTUnwrap(library.dish(id: "mapo-tofu")), library: library, seed: 7)
        XCTAssertNil(round.vessel)
        XCTAssertEqual(round.servePrompt, "Choose a wok or a pot")
        XCTAssertEqual(round.add("firm-tofu"), .needsVessel)
        XCTAssertTrue(round.entries.isEmpty)
        XCTAssertNil(round.selectedId)

        XCTAssertTrue(round.place(.pot))
        XCTAssertEqual(round.servePrompt, "Add something to the pot")
        XCTAssertEqual(round.add("firm-tofu"), .added)
        round.choose(.braise)
        XCTAssertEqual(round.attempt()?.vessel, .pot)
    }

    func testSwappingTheVesselKeepsWhatIsInIt() throws {
        var (round, _) = try makeRound()
        round.add("firm-tofu")
        round.choose(.braise)
        XCTAssertFalse(round.place(.wok), "the same vessel again is no change")
        XCTAssertTrue(round.place(.pot))
        XCTAssertEqual(round.entries.map(\.ingredientId), ["firm-tofu"])
        XCTAssertEqual(round.method, .braise)
        XCTAssertFalse(round.place(.skillet), "only the vessels on offer")
        XCTAssertEqual(round.vessel, .pot)
    }

    func testStartingOverClearsTheVesselToo() throws {
        var (round, _) = try makeRound()
        round.add("firm-tofu")
        round.clear()
        XCTAssertNil(round.vessel)
        XCTAssertEqual(round.servePrompt, "Choose a wok or a pot")
    }
}
