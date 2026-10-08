import XCTest
import PantryScoring
@testable import PantryGame

/// The stepper only offers the amounts on `AmountLadder`. These tests prove the game
/// is winnable with it: every known-good attempt, rebuilt from the palette with each
/// amount snapped to the nearest step, still scores as a good attempt (PD-009: 85+).
final class StepperReachabilityTests: XCTestCase {
    struct Golden: Decodable {
        let id: String
        let dishId: String
        let kind: String
        let vessel: Vessel
        let method: CookingMethod?
        let lines: [Attempt.Line]
    }

    struct GoldenFile: Decodable {
        let attempts: [Golden]
    }

    /// The scoring tests own the goldens; read the same file rather than keep a copy.
    static func goodGoldens() throws -> [Golden] {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("PantryScoringTests/Fixtures/goldens.json")
        let file = try JSONDecoder().decode(GoldenFile.self, from: Data(contentsOf: url))
        return file.attempts.filter { $0.kind == "good" }
    }

    /// Plays a golden through a `Round` the way a player would: add, then step to the nearest amount.
    static func play(_ golden: Golden, in library: ContentLibrary, vessel: Vessel) throws -> Round {
        let dish = try XCTUnwrap(library.dish(id: golden.dishId))
        var round = Round(dish: dish, library: library, seed: 1)
        round.place(vessel)
        for line in golden.lines {
            let ingredient = try XCTUnwrap(library.ingredient(id: line.ingredientId))
            let grams = try XCTUnwrap(ingredient.grams(amount: line.amount, unit: line.unit))
            XCTAssertEqual(round.add(line.ingredientId), .added, "\(golden.id): \(line.ingredientId) is not on the palette")
            let ladder = try XCTUnwrap(round.ladder(for: line.ingredientId))
            round.setStep(line.ingredientId, to: ladder.nearestIndex(toGrams: grams, of: ingredient))
        }
        round.choose(try XCTUnwrap(golden.method ?? dish.methods.first))
        return round
    }

    func testEveryGoodGoldenIsReachableOnTheStepper() throws {
        let library = try ContentLibrary.bundled()
        let goldens = try Self.goodGoldens()
        XCTAssertEqual(Set(goldens.map(\.dishId)), Set(library.dishes.map(\.id)))
        for golden in goldens {
            let round = try Self.play(golden, in: library, vessel: golden.vessel)
            let breakdown = try library.score(XCTUnwrap(round.attempt()))
            XCTAssertGreaterThanOrEqual(
                breakdown.total, 85,
                "\(golden.id) snapped to the stepper scored \(breakdown.total); misses \(breakdown.misses.map(\.code))"
            )
        }
    }

    /// Choosing the wok for everything costs a pot dish only the vessel points (6 of 100); nothing loses more.
    func testTheWokAloneCostsAtMostTheVesselPoints() throws {
        let library = try ContentLibrary.bundled()
        var potOnly: [String] = []
        for golden in try Self.goodGoldens() {
            let round = try Self.play(golden, in: library, vessel: .wok)
            let breakdown = try library.score(XCTUnwrap(round.attempt()))
            XCTAssertGreaterThanOrEqual(breakdown.total, 85, "\(golden.id) in the wok scored \(breakdown.total)")
            if breakdown.misses.contains(where: { $0.kind == .wrongVessel }) { potOnly.append(golden.dishId) }
        }
        XCTAssertEqual(potOnly, ["kou-shui-chicken"], "the dishes that want a pot")
    }

    func testLaddersAreStrictlyIncreasingByWeight() throws {
        let library = try ContentLibrary.bundled()
        for ingredient in library.ingredients {
            let ladder = AmountLadder(for: ingredient)
            let grams = try ladder.steps.map { try XCTUnwrap(ingredient.grams(amount: $0.amount, unit: $0.unit), ingredient.id) }
            XCTAssertEqual(grams, grams.sorted(), ingredient.id)
            XCTAssertEqual(Set(grams).count, grams.count, ingredient.id)
            XCTAssertEqual(Set(ladder.steps.map(\.label)).count, ladder.steps.count, ingredient.id)
            XCTAssertTrue(ladder.steps.indices.contains(ladder.startIndex), ingredient.id)
        }
    }

    func testStartingAmountIsOneOfTheDefaultUnit() throws {
        let library = try ContentLibrary.bundled()
        for ingredient in library.ingredients {
            let ladder = AmountLadder(for: ingredient)
            let start = ladder.measure(at: ladder.startIndex)
            if ingredient.defaultUnit == .grams {
                XCTAssertEqual(start, Measure(100, .grams, "100 g"), ingredient.id)
            } else {
                XCTAssertEqual(start.unit, ingredient.defaultUnit, ingredient.id)
                XCTAssertEqual(start.amount, 1, ingredient.id)
            }
        }
    }

    func testVolumeLadderUsesEveryUnitFromTheBrief() {
        XCTAssertEqual(Set(AmountLadder.volume.map(\.unit)), [.pinch, .tsp, .tbsp, .cup])
        XCTAssertEqual(Set(AmountLadder.weight.map(\.unit)), [.grams])
    }
}
