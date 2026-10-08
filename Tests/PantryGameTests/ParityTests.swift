import XCTest
import PantryScoring
@testable import PantryGame

/// The browser stand-in runs a JavaScript port of the engine (web/engine.js). Both it and
/// this test are held to the same file of exact results, so the two can't drift apart:
/// change the scoring in Swift without mirroring it and one of the two fails.
/// Regenerate the file with `node web/test-engine.cjs --write-parity`.
final class ParityTests: XCTestCase {
    struct File: Decodable {
        struct Scoring: Decodable {
            struct Expect: Decodable {
                let total: Int
                let coverage: Double
                let ratioFit: Double
                let signature: Double
                let technique: Double
                let cappedAt: Int?
                let misses: [String]
            }

            let id: String
            let dishId: String
            let vessel: Vessel
            let method: CookingMethod?
            let lines: [Attempt.Line]
            let expect: Expect
        }

        struct Pantry: Decodable {
            struct Expect: Decodable {
                let found: [String]
                let missed: [String]
                let alsoBelongs: [String]
                let wrong: [String]
                let essentials: Int
            }

            let id: String
            let dishId: String
            let picks: [String]
            let limit: Int
            let expect: Expect
        }

        let scoring: [Scoring]
        let pantry: [Pantry]
    }

    static func load() throws -> File {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("PantryScoringTests/Fixtures/parity.json")
        return try JSONDecoder().decode(File.self, from: Data(contentsOf: url))
    }

    func testScoringMatchesTheSharedResultsExactly() throws {
        let library = try ContentLibrary.bundled()
        let cases = try Self.load().scoring
        XCTAssertGreaterThan(cases.count, 30)
        for expected in cases {
            let attempt = Attempt(dishId: expected.dishId, lines: expected.lines, vessel: expected.vessel, method: expected.method)
            let breakdown = try library.score(attempt)
            XCTAssertEqual(breakdown.total, expected.expect.total, expected.id)
            XCTAssertEqual(breakdown.coverage, expected.expect.coverage, accuracy: 0.0001, expected.id)
            XCTAssertEqual(breakdown.ratioFit, expected.expect.ratioFit, accuracy: 0.0001, expected.id)
            XCTAssertEqual(breakdown.signature, expected.expect.signature, accuracy: 0.0001, expected.id)
            XCTAssertEqual(breakdown.technique, expected.expect.technique, accuracy: 0.0001, expected.id)
            XCTAssertEqual(breakdown.cappedAt, expected.expect.cappedAt, expected.id)
            XCTAssertEqual(breakdown.misses.map(\.code), expected.expect.misses, expected.id)
        }
    }

    func testPantryVerdictsMatchTheSharedResultsExactly() throws {
        let library = try ContentLibrary.bundled()
        let cases = try Self.load().pantry
        XCTAssertEqual(Set(cases.map(\.dishId)), Set(library.dishes.map(\.id)))
        for expected in cases {
            let dish = try XCTUnwrap(library.dish(id: expected.dishId))
            let result = PantryJudge.judge(picks: expected.picks, for: dish, in: library)
            XCTAssertEqual(result.found, expected.expect.found, expected.id)
            XCTAssertEqual(result.missed, expected.expect.missed, expected.id)
            XCTAssertEqual(result.alsoBelongs, expected.expect.alsoBelongs, expected.id)
            XCTAssertEqual(result.wrong, expected.expect.wrong, expected.id)
            XCTAssertEqual(result.essentials, expected.expect.essentials, expected.id)
            XCTAssertEqual(PantryRound(dish: dish, library: library, seed: 1).pickLimit, expected.limit, expected.id)
        }
    }
}
