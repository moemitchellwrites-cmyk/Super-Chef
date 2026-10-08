import XCTest
import PantryScoring
@testable import PantryGame

final class RecipeTextTests: XCTestCase {
    func testAmountsReadLikeARecipe() {
        XCTAssertEqual(RecipeText.amount(400, .grams), "400 g")
        XCTAssertEqual(RecipeText.amount(1000, .grams), "1 kg")
        XCTAssertEqual(RecipeText.amount(2.5, .tbsp), "2½ tbsp")
        XCTAssertEqual(RecipeText.amount(0.5, .tsp), "½ tsp")
        XCTAssertEqual(RecipeText.amount(1.5, .tsp), "1½ tsp")
        XCTAssertEqual(RecipeText.amount(1.0 / 3.0, .cup), "⅓ cup")
        XCTAssertEqual(RecipeText.amount(1, .cup), "1 cup")
        XCTAssertEqual(RecipeText.amount(2, .cup), "2 cups")
        XCTAssertEqual(RecipeText.amount(1, .pinch), "a pinch")
        XCTAssertEqual(RecipeText.amount(1.2, .tbsp), "1.2 tbsp")
    }

    func testLinesNameTheIngredientAfterTheAmount() throws {
        let library = try ContentLibrary.bundled()
        XCTAssertEqual(RecipeText.line(Attempt.Line(ingredientId: "garlic", amount: 1, unit: .tbsp), in: library), "1 tbsp garlic, minced")
        XCTAssertEqual(RecipeText.line(Attempt.Line(ingredientId: "sichuan-peppercorn-ground", amount: 2, unit: .tsp), in: library),
                       "2 tsp Sichuan peppercorn, ground")
        XCTAssertEqual(RecipeText.line(Attempt.Line(ingredientId: "mystery", amount: 5, unit: .grams), in: library), "5 g mystery")
    }

    func testEveryRecipeLineInTheContentFormatsWithoutADecimal() throws {
        let library = try ContentLibrary.bundled()
        for dish in library.dishes {
            for line in try XCTUnwrap(dish.recipe, dish.id).lines {
                let text = RecipeText.amount(line.amount, line.unit)
                XCTAssertFalse(text.contains("."), "\(dish.id): \(line.ingredientId) reads as \(text)")
            }
        }
    }

    func testEveryRecipeMarksExactlyTheDishEssentials() throws {
        let library = try ContentLibrary.bundled()
        for dish in library.dishes {
            let marked = RecipeText.essentialIds(of: dish, in: library)
            XCTAssertEqual(marked.count, PantryJudge.essentials(in: dish), dish.id)
            XCTAssertTrue(marked.isSubset(of: Set(dish.recipe?.lines.map(\.ingredientId) ?? [])), dish.id)
        }
    }
}
