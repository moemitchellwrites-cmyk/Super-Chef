import XCTest
@testable import PantryScoring

final class ContentTests: XCTestCase {
    func testSichuanContentLoads() throws {
        let library = try ContentLibrary.bundled()
        XCTAssertEqual(library.cuisine.id, "sichuan")
        XCTAssertEqual(library.cuisine.schemaVersion, 1)
        XCTAssertEqual(library.dishes.count, 10, "the MVP ships ten Sichuan dishes")
        XCTAssertGreaterThanOrEqual(library.ingredients.count, 40)
    }

    func testSichuanContentValidates() throws {
        let library = try ContentLibrary.bundled()
        XCTAssertEqual(library.validate(), [])
    }

    func testEveryDishHasItsOwnSignatureEnvelopeAndSources() throws {
        // The cuisine envelope is only a fallback: mapo tofu and kung pao differ more
        // than Sichuan and Hunan do on some axes. Sources are the chef reviewer's starting point.
        for dish in try ContentLibrary.bundled().dishes {
            XCTAssertNotNil(dish.signature, dish.id)
            XCTAssertTrue((dish.notes ?? "").contains("Dunlop") || (dish.notes ?? "").contains("Chengdu"), "\(dish.id) cites no source")
        }
    }

    func testEveryIngredientSaysWhatItIsWithoutSayingWhereItBelongs() throws {
        let library = try ContentLibrary.bundled()
        // Taste and use, never a home: a cuisine, a country or a dish would be the answer.
        var answers = ["sichuan", "hunan", "canton", "chinese", "china", "thai", "vietnam", "japan", "korea", "ital",
                       "india", "mexic", "french", "asia", "western"]
        answers += library.dishes.map { $0.name.lowercased() }
        for ingredient in library.ingredients {
            let about = try XCTUnwrap(ingredient.about, ingredient.id).lowercased()
            XCTAssertTrue(about.hasSuffix("."), ingredient.id)
            for word in answers where !ingredient.name.lowercased().contains(word) {
                XCTAssertFalse(about.contains(word), "\(ingredient.id): the about line names \"\(word)\"")
            }
        }
    }

    func testValidationCatchesAMissingOrLongAboutLine() throws {
        let library = try ContentLibrary.bundled()
        let silent = Ingredient(id: "silent", name: "Silent", family: "sugar", defaultUnit: .grams)
        let chatty = Ingredient(id: "chatty", name: "Chatty", family: "sugar", defaultUnit: .grams,
                                about: String(repeating: "and so on ", count: 20))
        let problems = ContentLibrary(cuisine: library.cuisine, ingredients: library.ingredients + [silent, chatty],
                                      dishes: library.dishes, cards: library.cards).validate()
        XCTAssertEqual(problems, ["silent: no about line", "chatty: about line is over 110 characters"])
    }

    func testValidationCatchesLabelsTooLongForAChip() throws {
        let library = try ContentLibrary.bundled()
        let wordy = Ingredient(id: "wordy", name: "An ingredient with a very long name", family: "sugar", defaultUnit: .grams,
                               about: "A test ingredient.")
        let padded = Ingredient(id: "padded", name: "Sugar", family: "sugar", defaultUnit: .grams,
                                shortName: "A short name that is not short", about: "A test ingredient.")
        let blank = Ingredient(id: "blank", name: "Sugar", family: "sugar", defaultUnit: .grams, shortName: "",
                               about: "A test ingredient.")
        let problems = ContentLibrary(cuisine: library.cuisine, ingredients: library.ingredients + [wordy, padded, blank],
                                      dishes: library.dishes, cards: library.cards).validate()
        XCTAssertTrue(problems.contains { $0.hasPrefix("wordy:") && $0.contains("no shortName") }, "\(problems)")
        XCTAssertTrue(problems.contains { $0.hasPrefix("padded:") && $0.contains("shortName must be") }, "\(problems)")
        XCTAssertTrue(problems.contains { $0.hasPrefix("blank:") && $0.contains("shortName must be") }, "\(problems)")
        XCTAssertEqual(problems.count, 3, "\(problems)")
    }

    func testEveryDishHasABriefThatDescribesThePlateAndNotTheRecipe() throws {
        let library = try ContentLibrary.bundled()
        // Seasonings and methods are the answers; the brief may not hand them over.
        let answers = ["doubanjiang", "bean paste", "peppercorn", "soy", "vinegar", "sugar", "sesame", "garlic",
                       "ginger", "scallion", "peanut", "starch", "wine", "stock", "yacai", "douchi",
                       "stir-fry", "deep-fry", "dry-fry", "braise", "boil", "poach", "simmer", "steam", "bake", "wok", "pot"]
        for dish in library.dishes {
            let brief = try XCTUnwrap(dish.brief, dish.id).lowercased()
            let name = dish.name.lowercased()
            for word in answers where !name.contains(word) {
                XCTAssertFalse(brief.contains(word), "\(dish.id): the brief names \"\(word)\"")
            }
            // Whole words only ("salty" is a taste, "salt" is an answer), and the dish's own name is fair game.
            let words = " " + brief.map { $0.isLetter ? String($0) : " " }.joined() + " "
            for id in dish.palette {
                let label = try XCTUnwrap(library.ingredient(id: id)).name.lowercased()
                guard !name.contains(label) else { continue }
                XCTAssertFalse(words.contains(" \(label) "), "\(dish.id): the brief names \(label)")
            }
        }
    }

    func testValidationCatchesAMissingLongOrNumericBrief() throws {
        let library = try ContentLibrary.bundled()
        var missing = try XCTUnwrap(library.dish(id: "mapo-tofu"))
        missing.brief = nil
        var long = try XCTUnwrap(library.dish(id: "laziji"))
        long.brief = String(repeating: "very ", count: 30)
        var numeric = try XCTUnwrap(library.dish(id: "kung-pao-chicken"))
        numeric.brief = "Chicken with 2 kinds of heat."
        let problems = ContentLibrary(cuisine: library.cuisine, ingredients: library.ingredients,
                                      dishes: [missing, long, numeric]).validate()
        XCTAssertTrue(problems.contains("mapo-tofu: no brief"), "\(problems)")
        XCTAssertTrue(problems.contains { $0.hasPrefix("laziji: brief is over") }, "\(problems)")
        XCTAssertTrue(problems.contains("kung-pao-chicken: brief gives a number"), "\(problems)")
    }

    func testEveryDishHasARecipeThatScoresAsAGoodAttempt() throws {
        let library = try ContentLibrary.bundled()
        for dish in library.dishes {
            let recipe = try XCTUnwrap(dish.recipe, dish.id)
            let breakdown = try library.score(recipe.attempt(dishId: dish.id))
            XCTAssertEqual(breakdown.total, 100, "\(dish.id): \(breakdown.misses.map(\.code))")
            XCTAssertTrue(dish.methods.contains(recipe.method), dish.id)
            XCTAssertTrue(dish.vessels.contains(recipe.vessel), dish.id)
            // Every ingredient the recipe lists is named in its steps' vocabulary at least by being on the palette.
            XCTAssertEqual(Set(recipe.lines.map(\.ingredientId)).count, recipe.lines.count, "\(dish.id): an ingredient is listed twice")
        }
    }

    func testValidationCatchesARecipeThatContradictsItsProfile() throws {
        let library = try ContentLibrary.bundled()
        var none = try XCTUnwrap(library.dish(id: "laziji"))
        none.recipe = nil
        var wrong = try XCTUnwrap(library.dish(id: "mapo-tofu"))
        wrong.recipe?.lines.append(Attempt.Line(ingredientId: "cream", amount: 240, unit: .grams))
        wrong.recipe?.lines.append(Attempt.Line(ingredientId: "parmesan", amount: 20, unit: .grams))
        wrong.recipe?.steps = ["Cook it."]
        let problems = ContentLibrary(cuisine: library.cuisine, ingredients: library.ingredients, dishes: [none, wrong]).validate()
        XCTAssertTrue(problems.contains("laziji: no recipe"), "\(problems)")
        XCTAssertTrue(problems.contains("mapo-tofu: recipe has 1 steps, want 3 to 7"), "\(problems)")
        XCTAssertTrue(problems.contains("mapo-tofu: recipe uses parmesan, which is not on the palette"), "\(problems)")
        XCTAssertTrue(problems.contains { $0.hasPrefix("mapo-tofu: its own recipe scores") }, "\(problems)")
    }

    func testValidationCatchesABrokenProfile() throws {
        let library = try ContentLibrary.bundled()
        var broken = try XCTUnwrap(library.dish(id: "mapo-tofu"))
        broken.required.append(Requirement(label: "ghost", anyOf: ["ectoplasm"]))
        broken.palette = Array(broken.palette.prefix(5))
        broken.ratios[0].low = 2
        let problems = ContentLibrary(cuisine: library.cuisine, ingredients: library.ingredients, dishes: [broken]).validate()
        XCTAssertTrue(problems.contains { $0.contains("ectoplasm") }, "\(problems)")
        XCTAssertTrue(problems.contains { $0.contains("palette has 5") }, "\(problems)")
        XCTAssertTrue(problems.contains { $0.contains("0 < low < high") }, "\(problems)")
    }

    func testMissingCuisineThrows() {
        XCTAssertThrowsError(try ContentLibrary.bundled(cuisineId: "atlantis")) { error in
            XCTAssertEqual(error as? ContentError, .missingResource("atlantis/cuisine.json"))
        }
    }

    func testDecoysComeFromNeighbouringCuisines() throws {
        // The learning happens at the boundary: every palette carries at least one
        // off-cuisine decoy and at least one in-cuisine ingredient that is wrong for this dish.
        let library = try ContentLibrary.bundled()
        let offCuisine = Set(library.cuisine.offCuisineFamilies)
        for dish in library.dishes {
            let families = dish.palette.compactMap { library.ingredient(id: $0)?.family }
            XCTAssertTrue(families.contains(where: offCuisine.contains), "\(dish.id) has no off-cuisine decoy")
            XCTAssertTrue(families.contains(where: Set(dish.forbidden).contains), "\(dish.id) has no in-cuisine decoy")
        }
    }

    // MARK: Cards (PB-004)

    func testEveryDishEndsOnACardUnderSixtyWords() throws {
        let library = try ContentLibrary.bundled()
        XCTAssertEqual(library.cards.count, library.dishes.count)
        for dish in library.dishes {
            let card = try XCTUnwrap(library.card(for: dish), dish.id)
            XCTAssertLessThan(card.wordCount, ContentLibrary.cardWordLimit, card.id)
            XCTAssertFalse(card.rule.isEmpty, card.id)
            XCTAssertFalse(card.tryTonight.isEmpty, card.id)
        }
    }

    func testValidationCatchesALongCardAndAMissingOne() throws {
        let library = try ContentLibrary.bundled()
        var cards = library.cards
        let dropped = cards.removeLast()
        cards[0].body = Array(repeating: "word", count: 70).joined(separator: " ") + ". And more."
        let problems = ContentLibrary(cuisine: library.cuisine, ingredients: library.ingredients, dishes: library.dishes, cards: cards).validate()
        XCTAssertTrue(problems.contains { $0.hasPrefix("\(cards[0].id):") && $0.contains("words") }, "\(problems)")
        XCTAssertTrue(problems.contains { $0.contains("card \(dropped.id) is not in cards.json") }, "\(problems)")
    }
}
