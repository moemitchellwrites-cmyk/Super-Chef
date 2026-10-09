import XCTest
import PantryScoring
@testable import PantryGame

/// The judge's one line (PB-003). The exact sentences for every golden are pinned in the parity file;
/// these check the rules behind them.
final class JudgeLineTests: XCTestCase {
    private func mapo(_ lines: [(String, Double, AmountUnit)], vessel: Vessel = .wok, method: CookingMethod = .braise) throws -> String {
        let library = try ContentLibrary.bundled()
        let dish = try XCTUnwrap(library.dish(id: "mapo-tofu"))
        let attempt = Attempt(dishId: dish.id, lines: lines.map { Attempt.Line(ingredientId: $0.0, amount: $0.1, unit: $0.2) },
                              vessel: vessel, method: method)
        return JudgeLine.kitchen(try library.score(attempt), dish: dish, library: library)
    }

    private var good: [(String, Double, AmountUnit)] {
        get throws {
            let library = try ContentLibrary.bundled()
            let recipe = try XCTUnwrap(library.dish(id: "mapo-tofu")?.recipe)
            return recipe.lines.map { ($0.ingredientId, $0.amount, $0.unit) }
        }
    }

    func testAGoodDishIsToldSo() throws {
        XCTAssertEqual(try mapo(try good), "That's mapo tofu. Nothing to fix.")
    }

    func testSomethingThatDoesNotBelongComesFirst() throws {
        let line = try mapo(try good + [("basil", 25, .grams)], method: .stirFry)
        XCTAssertEqual(line, "The basil came from another kitchen. Leave that out and this is close.")
    }

    func testTheWrongPanAndTheWrongMethodAreNamedWithTheRightOne() throws {
        XCTAssertEqual(try mapo(try good, vessel: .pot), "Right idea, wrong pan: mapo tofu is cooked in a wok.")
        XCTAssertEqual(try mapo(try good, method: .deepFry), "Deep-frying is the wrong method here: mapo tofu wants braising.")
    }

    func testAMissingEssentialIsNamed() throws {
        let line = try mapo(try good.filter { $0.0 != "doubanjiang" })
        XCTAssertEqual(line, "It isn't mapo tofu without doubanjiang.")
    }

    func testEveryLineIsOneShortSentenceOrTwo() throws {
        for item in try ParityTests.load().scoring {
            XCTAssertLessThanOrEqual(item.expect.line.count, 110, item.id)
            XCTAssertTrue(item.expect.line.hasSuffix("."), item.id)
        }
    }

    func testRatioLabelsSplitIntoTheirTwoSides() {
        XCTAssertEqual(JudgeLine.ratioSides("doubanjiang to tofu")?.0, "doubanjiang")
        XCTAssertEqual(JudgeLine.ratioSides("sugar to vinegar (the litchi balance)")?.1, "vinegar")
        XCTAssertNil(JudgeLine.ratioSides("heat"))
    }
}
