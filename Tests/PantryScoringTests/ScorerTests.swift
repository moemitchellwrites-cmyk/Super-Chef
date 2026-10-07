import XCTest
@testable import PantryScoring

/// Properties the engine must hold regardless of content, checked on the mapo tofu profile.
final class ScorerTests: XCTestCase {
    var library: ContentLibrary!
    var mapo: DishProfile!

    override func setUpWithError() throws {
        library = try ContentLibrary.bundled()
        mapo = try XCTUnwrap(library.dish(id: "mapo-tofu"))
    }

    func line(_ id: String, _ amount: Double, _ unit: Unit = .grams) -> Attempt.Line {
        Attempt.Line(ingredientId: id, amount: amount, unit: unit)
    }

    var goodMapo: Attempt {
        Attempt(dishId: "mapo-tofu", lines: [
            line("firm-tofu", 400), line("ground-pork", 100), line("doubanjiang", 2.5, .tbsp), line("douchi", 1, .tbsp),
            line("sichuan-peppercorn-ground", 2, .tsp), line("garlic", 1, .tbsp), line("ginger", 2, .tsp), line("scallion", 3, .tbsp),
            line("chili-flakes", 1, .tsp), line("light-soy", 1, .tbsp), line("stock", 150), line("cornstarch", 2, .tsp),
            line("neutral-oil", 2, .tbsp), line("sugar", 1, .tsp),
        ], vessel: .wok, method: .braise)
    }

    // MARK: units

    func testVolumeUnitsConvertThroughGramsPerTeaspoon() throws {
        let doubanjiang = try XCTUnwrap(library.ingredient(id: "doubanjiang"))
        XCTAssertEqual(doubanjiang.grams(amount: 1, unit: .tbsp), 18)
        XCTAssertEqual(doubanjiang.grams(amount: 2, unit: .tsp), 12)
        XCTAssertEqual(doubanjiang.grams(amount: 1, unit: .cup), 288)
        XCTAssertEqual(try XCTUnwrap(doubanjiang.grams(amount: 1, unit: .pinch)), 0.75, accuracy: 1e-9)
        XCTAssertEqual(doubanjiang.grams(amount: 37, unit: .grams), 37)
    }

    func testVolumeUnitOnWeightOnlyIngredientIsUnmeasurable() throws {
        let tofu = try XCTUnwrap(library.ingredient(id: "firm-tofu"))
        XCTAssertNil(tofu.grams(amount: 1, unit: .cup))
        var attempt = goodMapo
        attempt.lines[0] = line("firm-tofu", 2, .cup)
        let breakdown = library.scorer.score(attempt, against: mapo)
        XCTAssertTrue(breakdown.misses.contains { $0.kind == .unmeasurable })
        XCTAssertTrue(breakdown.misses.contains { $0.kind == .missingRequired && $0.subject == "tofu" })
    }

    // MARK: invariants

    func testScoringIsDeterministic() {
        let a = library.scorer.score(goodMapo, against: mapo)
        let b = library.scorer.score(goodMapo, against: mapo)
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.pattern, b.pattern)
    }

    func testScoreIsInvariantToScalingEveryAmount() {
        let base = library.scorer.score(goodMapo, against: mapo)
        for factor in [0.25, 3.0, 10.0] {
            var scaled = goodMapo
            scaled.lines = scaled.lines.map { line in
                var line = line
                line.amount *= factor
                return line
            }
            let result = library.scorer.score(scaled, against: mapo)
            XCTAssertEqual(result.total, base.total, accuracy: 1, "factor \(factor)")
            XCTAssertEqual(result.misses, base.misses, "factor \(factor)")
        }
    }

    func testSplittingOneIngredientAcrossTwoLinesChangesNothing() {
        var split = goodMapo
        split.lines.removeAll { $0.ingredientId == "firm-tofu" }
        split.lines.append(line("firm-tofu", 250))
        split.lines.append(line("firm-tofu", 150))
        XCTAssertEqual(library.scorer.score(split, against: mapo).total, library.scorer.score(goodMapo, against: mapo).total)
    }

    func testAddingAnOffCuisineIngredientNeverRaisesTheScore() throws {
        let scorer = library.scorer
        let goldens = try GoldenTests.loadGoldens()
        let spoilers: [(id: String, amount: Double, unit: Unit)] = [("cream", 1, .tbsp), ("basil", 1, .grams), ("lime", 1, .cup)]
        for dish in library.dishes {
            let good = try XCTUnwrap(goldens.first { $0.dishId == dish.id && $0.kind == "good" }).attempt
            let base = scorer.score(good, against: dish)
            for (id, amount, unit) in spoilers {
                var spoiled = good
                spoiled.lines.append(line(id, amount, unit))
                let result = scorer.score(spoiled, against: dish)
                XCTAssertLessThan(result.total, base.total, "\(dish.id) + \(amount) \(unit) \(id)")
                XCTAssertTrue(result.misses.contains { $0.kind == .offCuisine && $0.subject == id })
            }
        }
    }

    func testAPinchOfDecoyCostsLessThanACup() {
        var pinch = goodMapo
        pinch.lines.append(line("lime", 1, .pinch))
        var cup = goodMapo
        cup.lines.append(line("lime", 1, .cup))
        let pinchScore = library.scorer.score(pinch, against: mapo).total
        let cupScore = library.scorer.score(cup, against: mapo).total
        XCTAssertGreaterThan(pinchScore, cupScore)
        XCTAssertLessThan(pinchScore, 100)
    }

    func testRemovingTheDefiningIngredientCostsMoreThanAGarnish() {
        var noPaste = goodMapo
        noPaste.lines.removeAll { $0.ingredientId == "doubanjiang" }
        var noScallion = goodMapo
        noScallion.lines.removeAll { $0.ingredientId == "scallion" }
        let base = library.scorer.score(goodMapo, against: mapo).total
        let pasteScore = library.scorer.score(noPaste, against: mapo).total
        let scallionScore = library.scorer.score(noScallion, against: mapo).total
        XCTAssertLessThan(pasteScore, scallionScore)
        XCTAssertLessThanOrEqual(scallionScore, base)
        XCTAssertTrue(library.scorer.score(noPaste, against: mapo).misses.contains(Miss(.missingRequired, "doubanjiang")))
    }

    func testEmptyAttemptScoresLowAndListsEveryRequirement() {
        let empty = Attempt(dishId: "mapo-tofu", lines: [], vessel: .wok, method: .braise)
        let breakdown = library.scorer.score(empty, against: mapo)
        XCTAssertLessThan(breakdown.total, 20)
        XCTAssertEqual(breakdown.coverage, 0)
        XCTAssertEqual(breakdown.ratioFit, 0)
        for requirement in mapo.required {
            XCTAssertTrue(breakdown.misses.contains(Miss(.missingRequired, requirement.label)), requirement.label)
        }
    }

    func testUnknownIngredientIsReportedNotFatal() {
        var attempt = goodMapo
        attempt.lines.append(line("unicorn-dust", 5))
        let breakdown = library.scorer.score(attempt, against: mapo)
        XCTAssertTrue(breakdown.misses.contains(Miss(.unknownIngredient, "unicorn-dust")))
        XCTAssertEqual(breakdown.total, library.scorer.score(goodMapo, against: mapo).total)
    }

    func testZeroAmountLinesAreIgnored() {
        var attempt = goodMapo
        attempt.lines.append(line("cream", 0))
        XCTAssertEqual(library.scorer.score(attempt, against: mapo), library.scorer.score(goodMapo, against: mapo))
    }

    // MARK: technique

    func testWrongVesselLosesTechniquePoints() {
        var attempt = goodMapo
        attempt.vessel = .breadPan
        let breakdown = library.scorer.score(attempt, against: mapo)
        XCTAssertEqual(breakdown.technique, ScoreWeights.method)
        XCTAssertTrue(breakdown.misses.contains(Miss(.wrongVessel, "bread-pan")))
    }

    func testWithoutAMethodTheVesselCarriesAllTechniquePoints() {
        var attempt = goodMapo
        attempt.method = nil
        XCTAssertEqual(library.scorer.score(attempt, against: mapo).technique, ScoreWeights.technique)
        attempt.vessel = .pot
        XCTAssertEqual(library.scorer.score(attempt, against: mapo).technique, 0)
    }

    func testWrongMethodLosesOnlyTheMethodPoints() {
        var attempt = goodMapo
        attempt.method = .bake
        let breakdown = library.scorer.score(attempt, against: mapo)
        XCTAssertEqual(breakdown.technique, ScoreWeights.vessel)
        XCTAssertTrue(breakdown.misses.contains(Miss(.wrongMethod, "bake")))
    }

    // MARK: ratio credit

    func testBandCreditIsFullInsideAndSymmetricOutside() {
        XCTAssertEqual(Scorer.bandCredit(ratio: 0.1, low: 0.08, high: 0.12), 1)
        XCTAssertEqual(Scorer.bandCredit(ratio: 0.08, low: 0.08, high: 0.12), 1)
        XCTAssertEqual(Scorer.bandCredit(ratio: 0.12, low: 0.08, high: 0.12), 1)
        let below = Scorer.bandCredit(ratio: 0.04, low: 0.08, high: 0.12)
        let above = Scorer.bandCredit(ratio: 0.24, low: 0.08, high: 0.12)
        XCTAssertEqual(below, above, accuracy: 1e-9)
        XCTAssertEqual(below, 1 - log(2) / log(3), accuracy: 1e-9)
        XCTAssertEqual(Scorer.bandCredit(ratio: 0.36, low: 0.08, high: 0.12), 0, accuracy: 1e-9)
        XCTAssertEqual(Scorer.bandCredit(ratio: 1, low: 0.08, high: 0.12), 0)
        XCTAssertEqual(Scorer.bandCredit(ratio: 0, low: 0.08, high: 0.12), 0)
    }

    func testOverSaucingFlagsTheRatioAsHigh() {
        var attempt = goodMapo
        attempt.lines = attempt.lines.map { line in
            var line = line
            if line.ingredientId == "doubanjiang" { line.amount *= 4 }
            return line
        }
        let breakdown = library.scorer.score(attempt, against: mapo)
        XCTAssertTrue(breakdown.misses.contains(Miss(.ratioHigh, "doubanjiang to tofu")))
        XCTAssertLessThan(breakdown.ratioFit, ScoreWeights.ratioFit)
    }

    // MARK: pattern

    func testPatternIsStableAndCarriesTheMissCodes() {
        var attempt = goodMapo
        attempt.lines.append(line("cream", 1, .tbsp))
        attempt.lines.removeAll { $0.ingredientId == "sichuan-peppercorn-ground" }
        let breakdown = library.scorer.score(attempt, against: mapo)
        XCTAssertTrue(breakdown.pattern.hasPrefix("t\(breakdown.total / 10)|"))
        XCTAssertTrue(breakdown.pattern.contains("offCuisine:cream"))
        XCTAssertTrue(breakdown.pattern.contains("missingRequired:Sichuan peppercorn"))
        XCTAssertEqual(library.scorer.score(goodMapo, against: mapo).pattern, "t9|")
    }

    func testBreakdownRoundTripsThroughJSON() throws {
        let breakdown = library.scorer.score(goodMapo, against: mapo)
        let data = try JSONEncoder().encode(breakdown)
        XCTAssertEqual(try JSONDecoder().decode(ScoreBreakdown.self, from: data), breakdown)
        let attemptData = try JSONEncoder().encode(goodMapo)
        XCTAssertEqual(try JSONDecoder().decode(Attempt.self, from: attemptData), goodMapo)
    }
}
