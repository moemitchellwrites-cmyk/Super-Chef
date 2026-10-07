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

    func testValidationCatchesLabelsTooLongForAChip() throws {
        let library = try ContentLibrary.bundled()
        let wordy = Ingredient(id: "wordy", name: "An ingredient with a very long name", family: "sugar", defaultUnit: .grams)
        let padded = Ingredient(id: "padded", name: "Sugar", family: "sugar", defaultUnit: .grams,
                                shortName: "A short name that is not short")
        let blank = Ingredient(id: "blank", name: "Sugar", family: "sugar", defaultUnit: .grams, shortName: "")
        let problems = ContentLibrary(cuisine: library.cuisine, ingredients: library.ingredients + [wordy, padded, blank],
                                      dishes: library.dishes).validate()
        XCTAssertTrue(problems.contains { $0.hasPrefix("wordy:") && $0.contains("no shortName") }, "\(problems)")
        XCTAssertTrue(problems.contains { $0.hasPrefix("padded:") && $0.contains("shortName must be") }, "\(problems)")
        XCTAssertTrue(problems.contains { $0.hasPrefix("blank:") && $0.contains("shortName must be") }, "\(problems)")
        XCTAssertEqual(problems.count, 3, "\(problems)")
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
}
