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
        XCTAssertEqual(RecipeText.line(Attempt.Line(ingredientId: "garlic", amount: 1, unit: .tbsp), in: library, system: .us), "1 tbsp garlic, minced")
        XCTAssertEqual(RecipeText.line(Attempt.Line(ingredientId: "sichuan-peppercorn-ground", amount: 2, unit: .tsp), in: library, system: .metric),
                       "2 tsp Sichuan peppercorn, ground")
        XCTAssertEqual(RecipeText.line(Attempt.Line(ingredientId: "mystery", amount: 5, unit: .grams), in: library, system: .us), "5 g mystery")
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

    /// The recipe must read in the same measures the Kitchen stepper offers (PD-033): a player who
    /// reads "¾ cup" can dial exactly "¾ cup".
    func testEveryRecipeAmountIsAStepOnThatIngredientsLadder() throws {
        let library = try ContentLibrary.bundled()
        for dish in library.dishes {
            for line in dish.recipe?.lines ?? [] {
                let ingredient = try XCTUnwrap(library.ingredient(id: line.ingredientId), line.ingredientId)
                let onLadder = AmountLadder(for: ingredient, system: .metric).steps.contains {
                    $0.unit == line.unit && abs($0.amount - line.amount) < 0.0001
                }
                XCTAssertTrue(onLadder, "\(dish.id): \(line.amount) \(line.unit.rawValue) of \(line.ingredientId) can't be dialled")
            }
        }
    }

    // MARK: Measures by region (PD-041)

    func testARecipeReadsInThePlayersMeasures() throws {
        let library = try ContentLibrary.bundled()
        let tofu = Attempt.Line(ingredientId: "firm-tofu", amount: 400, unit: .grams)
        XCTAssertEqual(RecipeText.line(tofu, in: library, system: .metric), "400 g firm tofu")
        XCTAssertEqual(RecipeText.line(tofu, in: library, system: .us), "14 oz firm tofu")
        let stock = Attempt.Line(ingredientId: "stock", amount: 0.75, unit: .cup)
        XCTAssertEqual(RecipeText.line(stock, in: library, system: .us), "¾ cup chicken stock")
        XCTAssertEqual(RecipeText.line(stock, in: library, system: .metric), "180 ml chicken stock")
    }

    func testEveryRecipeStillCooksWellInEitherSystem() throws {
        let library = try ContentLibrary.bundled()
        for system in MeasureSystem.allCases {
            for dish in library.dishes {
                let recipe = try XCTUnwrap(dish.recipe, dish.id)
                let lines = try recipe.lines.map { line -> Attempt.Line in
                    let ingredient = try XCTUnwrap(library.ingredient(id: line.ingredientId))
                    let measure = RecipeText.measure(line, of: ingredient, system: system)
                    return Attempt.Line(ingredientId: line.ingredientId, amount: measure.amount, unit: measure.unit)
                }
                let breakdown = try library.score(Attempt(dishId: dish.id, lines: lines, vessel: recipe.vessel, method: recipe.method))
                XCTAssertGreaterThanOrEqual(breakdown.total, 85, "\(dish.id) read in \(system.rawValue) measures scored \(breakdown.total)")
                XCTAssertEqual(breakdown.misses.map(\.code), [], "\(dish.id) in \(system.rawValue)")
            }
        }
    }

    func testEachSystemSpeaksOnlyItsOwnUnits() throws {
        let library = try ContentLibrary.bundled()
        for ingredient in library.ingredients {
            for step in AmountLadder(for: ingredient, system: .metric).steps {
                XCTAssertFalse(step.label.contains("cup") || step.label.contains("oz") || step.label.contains("lb"), "\(ingredient.id): \(step.label)")
            }
            for step in AmountLadder(for: ingredient, system: .us).steps {
                XCTAssertFalse(step.label.hasSuffix(" g") || step.label.hasSuffix("kg") || step.label.contains("ml") || step.label.hasSuffix(" L"),
                               "\(ingredient.id): \(step.label)")
            }
        }
    }
}
