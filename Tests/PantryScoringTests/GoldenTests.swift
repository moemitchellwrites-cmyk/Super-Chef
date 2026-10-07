import XCTest
@testable import PantryScoring

/// A golden attempt from Fixtures/goldens.json: an attempt plus the range it must score in.
struct GoldenAttempt: Decodable {
    struct Expect: Decodable {
        let min: Int
        let max: Int
    }

    let id: String
    let dishId: String
    let kind: String
    let vessel: Vessel
    let method: Method?
    let note: String?
    let lines: [Attempt.Line]
    let expect: Expect

    var attempt: Attempt {
        Attempt(dishId: dishId, lines: lines, vessel: vessel, method: method)
    }
}

struct GoldenFile: Decodable {
    let schemaVersion: Int
    let attempts: [GoldenAttempt]
}

/// The contract from the brief: a known-good attempt per dish scores 85+, a known
/// off-cuisine attempt scores under 40. Added here: a neighbour-cuisine attempt
/// lands between and above the off-cuisine one, and a right-pantry-wrong-amounts
/// attempt lands below the good one and names the ratios it missed.
final class GoldenTests: XCTestCase {
    static func loadGoldens() throws -> [GoldenAttempt] {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "goldens", withExtension: "json", subdirectory: "Fixtures"))
        return try JSONDecoder().decode(GoldenFile.self, from: Data(contentsOf: url)).attempts
    }

    func testEveryGoldenScoresInsideItsRange() throws {
        let library = try ContentLibrary.bundled()
        let goldens = try Self.loadGoldens()
        XCTAssertFalse(goldens.isEmpty)
        for golden in goldens {
            let breakdown = try library.score(golden.attempt)
            let inRange = (golden.expect.min...golden.expect.max).contains(breakdown.total)
            XCTAssertTrue(
                inRange,
                "\(golden.id) scored \(breakdown.total), wanted \(golden.expect.min)...\(golden.expect.max). "
                    + "coverage \(breakdown.coverage) ratio \(breakdown.ratioFit) signature \(breakdown.signature) "
                    + "technique \(breakdown.technique); misses \(breakdown.misses.map(\.code))"
            )
        }
    }

    func testEveryDishHasGoodOffCuisineAndNeighborGoldens() throws {
        let library = try ContentLibrary.bundled()
        let goldens = try Self.loadGoldens()
        for dish in library.dishes {
            let kinds = Set(goldens.filter { $0.dishId == dish.id }.map(\.kind))
            XCTAssertTrue(kinds.isSuperset(of: ["good", "offCuisine", "neighbor"]), "\(dish.id) has goldens \(kinds)")
        }
        for golden in goldens {
            XCTAssertNotNil(library.dish(id: golden.dishId), "\(golden.id) names unknown dish \(golden.dishId)")
        }
    }

    func testNeighborScoresAboveOffCuisineForTheSameDish() throws {
        let library = try ContentLibrary.bundled()
        let goldens = try Self.loadGoldens()
        for dish in library.dishes {
            let mine = goldens.filter { $0.dishId == dish.id }
            guard let off = mine.first(where: { $0.kind == "offCuisine" }),
                  let neighbor = mine.first(where: { $0.kind == "neighbor" }) else { continue }
            let offScore = try library.score(off.attempt).total
            let neighborScore = try library.score(neighbor.attempt).total
            XCTAssertGreaterThan(neighborScore, offScore, "\(dish.id): neighbor \(neighborScore) vs off-cuisine \(offScore)")
        }
    }

    func testWrongAmountsScoreBelowGoodAndNameTheRatios() throws {
        let library = try ContentLibrary.bundled()
        let goldens = try Self.loadGoldens()
        let wrong = goldens.filter { $0.kind == "wrongAmounts" }
        XCTAssertFalse(wrong.isEmpty)
        for golden in wrong {
            let good = try XCTUnwrap(goldens.first { $0.dishId == golden.dishId && $0.kind == "good" })
            let goodScore = try library.score(good.attempt)
            let wrongScore = try library.score(golden.attempt)
            XCTAssertLessThan(wrongScore.total, goodScore.total, golden.id)
            XCTAssertTrue(wrongScore.misses.contains { $0.kind == .ratioHigh }, "\(golden.id) should flag a ratio as high: \(wrongScore.misses)")
            XCTAssertFalse(wrongScore.misses.contains { $0.kind == .missingRequired }, golden.id)
        }
    }

    func testGoodAttemptsUseOnlyPaletteIngredients() throws {
        // The player can only pick from the palette, so the reference attempt must be buildable from it.
        let library = try ContentLibrary.bundled()
        for golden in try Self.loadGoldens() where golden.kind == "good" {
            let dish = try XCTUnwrap(library.dish(id: golden.dishId))
            let outside = Set(golden.lines.map(\.ingredientId)).subtracting(dish.palette)
            XCTAssertTrue(outside.isEmpty, "\(golden.id) uses ingredients outside the palette: \(outside.sorted())")
        }
    }

    func testGoodAttemptsHaveNoMisses() throws {
        // A reference attempt is the dish done right; nothing in it should read as a miss.
        let library = try ContentLibrary.bundled()
        for golden in try Self.loadGoldens() where golden.kind == "good" {
            let breakdown = try library.score(golden.attempt)
            XCTAssertTrue(breakdown.misses.isEmpty, "\(golden.id): \(breakdown.misses.map(\.code))")
        }
    }
}
