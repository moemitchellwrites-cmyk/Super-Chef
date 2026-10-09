import XCTest
import PantryScoring
@testable import PantryGame

final class PantryRoundTests: XCTestCase {
    private func library() throws -> ContentLibrary { try ContentLibrary.bundled() }

    private func judge(_ picks: [String], _ dishId: String = "mapo-tofu") throws -> PantryResult {
        let library = try library()
        return PantryJudge.judge(picks: picks, for: try XCTUnwrap(library.dish(id: dishId)), in: library)
    }

    func testMapoTofuHasSixEssentials() throws {
        let library = try library()
        // tofu, doubanjiang, Sichuan peppercorn, two aromatics, chili heat
        XCTAssertEqual(PantryJudge.essentials(in: try XCTUnwrap(library.dish(id: "mapo-tofu"))), 6)
        for dish in library.dishes {
            XCTAssertTrue((4...10).contains(PantryJudge.essentials(in: dish)), dish.id)
        }
    }

    func testAPerfectPantryIsClean() throws {
        let result = try judge(["firm-tofu", "doubanjiang", "sichuan-peppercorn-ground", "garlic", "ginger", "chili-flakes"])
        XCTAssertEqual(result.found.count, 6)
        XCTAssertEqual(result.essentials, 6)
        XCTAssertEqual(result.missed, [])
        XCTAssertEqual(result.wrong, [])
        XCTAssertEqual(result.alsoBelongs, [])
        XCTAssertTrue(result.isClean)
    }

    func testMissedEssentialsAreNamedByTheirLabel() throws {
        let result = try judge(["firm-tofu", "garlic"])
        XCTAssertEqual(result.found, ["firm-tofu", "garlic"])
        XCTAssertEqual(result.missed, ["doubanjiang", "Sichuan peppercorn", "aromatics", "chili heat"])
        XCTAssertFalse(result.isClean)
    }

    func testAThirdAromaticAndOptionalIngredientsBelongButFillNothing() throws {
        let result = try judge(["garlic", "ginger", "scallion", "ground-pork", "sugar"])
        XCTAssertEqual(result.found, ["garlic", "ginger"])
        XCTAssertEqual(result.alsoBelongs, ["scallion", "ground-pork", "sugar"])
        XCTAssertEqual(result.wrong, [])
    }

    func testOffCuisineAndForbiddenPicksAreWrong() throws {
        let result = try judge(["firm-tofu", "basil", "sesame-paste", "duojiao"])
        XCTAssertEqual(result.found, ["firm-tofu"])
        XCTAssertEqual(result.wrong, ["basil", "sesame-paste", "duojiao"])
        XCTAssertFalse(result.isClean)
    }

    func testAllEssentialsPlusSomethingWrongIsNotClean() throws {
        let result = try judge(["firm-tofu", "doubanjiang", "sichuan-peppercorn-ground", "garlic", "ginger", "chili-flakes", "cream"])
        XCTAssertEqual(result.found.count, result.essentials)
        XCTAssertEqual(result.wrong, ["cream"])
        XCTAssertFalse(result.isClean)
    }

    func testRepeatsAndUnknownPicksAreIgnored() throws {
        let result = try judge(["garlic", "garlic", "no-such-thing"])
        XCTAssertEqual(result.found, ["garlic"])
        XCTAssertEqual(result.alsoBelongs, [])
    }

    func testEveryDishCanBeServedCleanWithinItsLimit() throws {
        let library = try library()
        for dish in library.dishes {
            var round = PantryRound(dish: dish, library: library, seed: 3)
            XCTAssertEqual(round.pickLimit, round.essentials + PantryRound.slack, dish.id)
            XCTAssertLessThan(round.pickLimit, round.palette.count, "\(dish.id): the limit must not allow the whole palette")
            // Greedy: add anything that fills a slot.
            for ingredient in round.palette {
                var trial = round
                guard trial.toggle(ingredient.id) == .added, let result = trial.result(in: library) else { continue }
                if result.found.count > (round.result(in: library)?.found.count ?? 0) { round = trial }
            }
            let result = try XCTUnwrap(round.result(in: library))
            XCTAssertTrue(result.isClean, "\(dish.id): \(result)")
            XCTAssertEqual(round.picks.count, round.essentials, dish.id)
        }
    }

    func testToggleAddsRemovesAndStopsAtTheLimit() throws {
        let library = try library()
        var round = PantryRound(dish: try XCTUnwrap(library.dish(id: "mapo-tofu")), library: library, seed: 1)
        XCTAssertFalse(round.canServe)
        XCTAssertNil(round.result(in: library))
        XCTAssertEqual(round.pickLimit, 6, "six essentials, six picks")
        XCTAssertEqual(round.toggle("parmesan"), .notOffered)
        for ingredient in round.palette.prefix(6) {
            XCTAssertEqual(round.toggle(ingredient.id), .added)
        }
        XCTAssertEqual(round.picksLeft, 0)
        XCTAssertEqual(round.toggle(round.palette[6].id), .full)
        XCTAssertEqual(round.toggle(round.palette[0].id), .removed)
        XCTAssertEqual(round.toggle(round.palette[6].id), .added)
        XCTAssertTrue(round.canServe)
        round.clear()
        XCTAssertEqual(round.picks, [])
    }

    func testPaletteIsShuffledFromTheSeed() throws {
        let library = try library()
        let dish = try XCTUnwrap(library.dish(id: "laziji"))
        let a = PantryRound(dish: dish, library: library, seed: 5)
        let b = PantryRound(dish: dish, library: library, seed: 5)
        let c = PantryRound(dish: dish, library: library, seed: 6)
        XCTAssertEqual(a.palette.map(\.id), b.palette.map(\.id))
        XCTAssertNotEqual(a.palette.map(\.id), c.palette.map(\.id))
        XCTAssertEqual(Set(a.palette.map(\.id)), Set(dish.palette))
    }

    func testTheRoundSaysWhatItAsksAndHowFarAlongItIs() throws {
        let library = try library()
        var round = PantryRound(dish: try XCTUnwrap(library.dish(id: "mapo-tofu")), library: library, seed: 1)
        XCTAssertEqual(round.ask, "Pick the 6 essentials")
        XCTAssertEqual(round.countLabel, "0 of 6")
        XCTAssertEqual(round.servePrompt, "Add something to the wok")
        XCTAssertEqual(round.toggle("firm-tofu"), .added)
        XCTAssertEqual(round.countLabel, "1 of 6")
        XCTAssertNil(round.servePrompt)
        XCTAssertEqual(round.ingredient("firm-tofu")?.id, "firm-tofu")
        XCTAssertNil(round.ingredient("not-on-the-palette"))
    }
}
