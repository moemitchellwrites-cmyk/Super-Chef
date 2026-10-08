import XCTest
import PantryScoring
@testable import PantryGame

/// The five-round session and what the game remembers (PB-005).
final class SessionTests: XCTestCase {
    private func dishes() throws -> [DishProfile] { try ContentLibrary.bundled().dishes }

    func testASessionDealsFiveDifferentDishes() throws {
        let session = Session(mode: .kitchen, dishes: try dishes(), seed: 3)
        XCTAssertEqual(session.dishIds.count, 5)
        XCTAssertEqual(Set(session.dishIds).count, 5)
        XCTAssertEqual(session.roundNumber, 1)
        XCTAssertEqual(session.progressLabel, "1 of 5")
        XCTAssertEqual(session.currentDishId, session.dishIds[0])
        XCTAssertFalse(session.isComplete)
        XCTAssertEqual(session, Session(mode: .kitchen, dishes: try dishes(), seed: 3), "the same seed deals the same session")
        XCTAssertNotEqual(session.dishIds, Session(mode: .kitchen, dishes: try dishes(), seed: 4).dishIds)
    }

    func testTheNextSessionBringsTheOtherFiveDishes() throws {
        let all = try dishes()
        let first = Session(mode: .pantry, dishes: all, seed: 1)
        let second = Session(mode: .pantry, dishes: all, avoiding: Set(first.dishIds), seed: 2)
        XCTAssertTrue(Set(first.dishIds).isDisjoint(with: second.dishIds))
        // With fewer dishes than two sessions need, the avoided ones come back at the end.
        let few = Array(all.prefix(6))
        let third = Session(mode: .pantry, dishes: few, avoiding: Set(few.prefix(4).map(\.id)), seed: 2)
        XCTAssertEqual(third.dishIds.count, 5)
        XCTAssertEqual(Set(third.dishIds.prefix(2)), Set(few.suffix(2).map(\.id)))
    }

    func testASessionCanOpenOnANamedDish() throws {
        let session = Session(mode: .kitchen, dishes: try dishes(), first: "mapo-tofu", seed: 9)
        XCTAssertEqual(session.dishIds.first, "mapo-tofu")
        XCTAssertEqual(Set(session.dishIds).count, 5)
        XCTAssertEqual(Session(mode: .kitchen, dishes: try dishes(), first: "no-such-dish", seed: 9).dishIds.count, 5)
    }

    func testRecordingFiveRoundsCompletesTheSession() throws {
        var session = Session(mode: .kitchen, dishes: try dishes(), seed: 3)
        for (index, score) in [90, 60, 100, 75, 40].enumerated() {
            XCTAssertEqual(session.roundNumber, index + 1)
            XCTAssertEqual(session.isLastRound, index == 4)
            XCTAssertTrue(session.record(points: score, outOf: 100))
        }
        XCTAssertTrue(session.isComplete)
        XCTAssertNil(session.currentDishId)
        XCTAssertEqual(session.progressLabel, "5 of 5")
        XCTAssertFalse(session.record(points: 100, outOf: 100), "a sixth round has nowhere to go")
        XCTAssertEqual(session.records.map(\.dishId), session.dishIds)

        let summary = session.summary
        XCTAssertEqual(summary.headlineNumber, "73")
        XCTAssertEqual(summary.headlineCaption, "average across 5 dishes")
        XCTAssertEqual(summary.line, "Solid cooking, with a dish or two to tighten.")
        XCTAssertEqual(summary.best?.points, 100)
        XCTAssertEqual(summary.revisit?.points, 40)
    }

    func testAPantrySummaryCountsEssentialsAndNeverNamesAPerfectRoundToRevisit() throws {
        var session = Session(mode: .pantry, dishes: try dishes(), seed: 3)
        for (found, of) in [(6, 6), (7, 7), (5, 5), (8, 8), (5, 5)] { session.record(points: found, outOf: of) }
        let summary = session.summary
        XCTAssertEqual(summary.headlineNumber, "31 of 31")
        XCTAssertEqual(summary.line, "A strong service.")
        XCTAssertNil(summary.revisit)
        XCTAssertEqual(summary.best?.dishId, session.dishIds[0], "the first round wins a tie")

        var rough = Session(mode: .pantry, dishes: try dishes(), seed: 3)
        for (found, of) in [(2, 6), (3, 7), (1, 5), (4, 8), (2, 5)] { rough.record(points: found, outOf: of) }
        XCTAssertEqual(rough.summary.line, "A learning service. The cards are the shortcut.")
        XCTAssertEqual(rough.summary.revisit?.dishId, rough.dishIds[2])
    }

    func testProgressFilesFinishedSessionsAndRemembersTheBest() throws {
        let all = try dishes()
        var progress = GameProgress()
        var session = Session(mode: .kitchen, dishes: all, first: "mapo-tofu", seed: 1)
        progress.setSession(session)
        XCTAssertEqual(progress.session(for: .kitchen), session)
        XCTAssertNil(progress.session(for: .pantry))
        XCTAssertFalse(progress.finish(session, at: Date(timeIntervalSince1970: 0)), "an unfinished session can't be filed")

        for score in [55, 80, 80, 80, 80] { session.record(points: score, outOf: 100) }
        progress.setSession(session)
        XCTAssertTrue(progress.finish(session, at: Date(timeIntervalSince1970: 1_000)))
        XCTAssertNil(progress.session(for: .kitchen))
        XCTAssertEqual(progress.finishedCount(in: .kitchen), 1)
        XCTAssertEqual(progress.finishedCount(in: .pantry), 0)
        XCTAssertEqual(progress.lastDishIds(in: .kitchen), Set(session.dishIds))
        XCTAssertEqual(progress.best(dishId: "mapo-tofu", in: .kitchen)?.points, 55)
        XCTAssertNil(progress.best(dishId: "mapo-tofu", in: .pantry))

        var again = Session(mode: .kitchen, dishes: all, first: "mapo-tofu", seed: 2)
        for score in [91, 50, 50, 50, 50] { again.record(points: score, outOf: 100) }
        progress.finish(again, at: Date(timeIntervalSince1970: 2_000))
        XCTAssertEqual(progress.best(dishId: "mapo-tofu", in: .kitchen)?.points, 91)
    }

    func testProgressSurvivesTheFileAndABrokenFileIsAnEmptyStart() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("pantry-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = ProgressFile(url: folder.appendingPathComponent("nested/progress.json"))
        XCTAssertEqual(file.load(), GameProgress(), "no file yet")

        var progress = GameProgress()
        var session = Session(mode: .pantry, dishes: try dishes(), seed: 5)
        session.record(points: 4, outOf: 6)
        progress.setSession(session)
        var done = Session(mode: .kitchen, dishes: try dishes(), seed: 6)
        for _ in 0..<5 { done.record(points: 70, outOf: 100) }
        progress.finish(done, at: Date(timeIntervalSince1970: 86_400))
        try file.save(progress)
        XCTAssertEqual(file.load(), progress)

        try Data("not json".utf8).write(to: file.url)
        XCTAssertEqual(file.load(), GameProgress())
    }

    func testOnlyTheFirstServeOfARoundCounts() throws {
        var session = Session(mode: .kitchen, dishes: try dishes(), seed: 3)
        XCTAssertFalse(session.advance(), "nothing served yet")
        XCTAssertTrue(session.serve(points: 62, outOf: 100))
        XCTAssertFalse(session.serve(points: 95, outOf: 100), "a second serve of the same dish is practice")
        XCTAssertEqual(session.served?.points, 62)
        XCTAssertEqual(session.roundNumber, 1, "serving doesn't move the session on")
        XCTAssertTrue(session.advance())
        XCTAssertEqual(session.records.map(\.points), [62])
        XCTAssertNil(session.served)
        XCTAssertEqual(session.roundNumber, 2)
        XCTAssertTrue(session.serve(points: 80, outOf: 100), "the next dish starts clean")
    }
}
