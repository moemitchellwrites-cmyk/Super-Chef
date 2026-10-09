import XCTest
import PantryScoring
@testable import PantryGame

final class SoundTests: XCTestCase {
    func testEveryIngredientNamesACueTheGameKnows() throws {
        let library = try ContentLibrary.bundled()
        for ingredient in library.ingredients {
            XCTAssertTrue(SoundCue.known(ingredient.soundCue), "\(ingredient.id): unknown sound cue \(ingredient.soundCue)")
        }
    }

    func testUnknownCueFallsBackToClatter() {
        XCTAssertEqual(SoundCue(contentCue: "kazoo"), .clatter)
        XCTAssertEqual(SoundCue(contentCue: "boil"), .boil)
        XCTAssertFalse(SoundCue.known("kazoo"))
        XCTAssertFalse(SoundCue.known("flame"), "the flame belongs to the method tap, not to an ingredient")
    }

    func testEveryCueHasAVisualTwin() {
        for cue in SoundCue.allCases {
            XCTAssertFalse(cue.word.isEmpty, cue.rawValue)
            XCTAssertFalse(cue.twin.isEmpty, cue.rawValue)
        }
        XCTAssertEqual(Set(SoundCue.allCases.map(\.word)).count, SoundCue.allCases.count)
    }

    func testEveryIconInTheContentHasPlaceholderArt() throws {
        let library = try ContentLibrary.bundled()
        for ingredient in library.ingredients {
            XCTAssertNotNil(IngredientLook.byIcon[ingredient.icon], "\(ingredient.id): no look for icon \(ingredient.icon)")
        }
        XCTAssertEqual(IngredientLook(for: Ingredient(id: "x", name: "X", family: "x", defaultUnit: .grams, icon: "mystery")), .fallback)
    }

    func testPlaceholderSoundsAreShortAudibleAndBounded() {
        for cue in SoundCue.allCases {
            let samples = PlaceholderSynth.samples(for: cue)
            let seconds = Double(samples.count) / PlaceholderSynth.sampleRate
            XCTAssertTrue((0.2...1.0).contains(seconds), "\(cue.rawValue) lasts \(seconds) s")
            let peak = samples.reduce(Float(0)) { max($0, abs($1)) }
            XCTAssertEqual(peak, 0.6, accuracy: 0.001, cue.rawValue)
            XCTAssertTrue(samples.allSatisfy { $0.isFinite }, cue.rawValue)
            let energy = samples.reduce(Float(0)) { $0 + $1 * $1 } / Float(samples.count)
            XCTAssertGreaterThan(energy, 0.0005, "\(cue.rawValue) is nearly silent")
        }
    }

    func testPlaceholderSoundsAreDeterministicAndDistinct() {
        var seen: [[Float]] = []
        for cue in SoundCue.allCases {
            let samples = PlaceholderSynth.samples(for: cue)
            XCTAssertEqual(samples, PlaceholderSynth.samples(for: cue), cue.rawValue)
            XCTAssertFalse(seen.contains(samples), cue.rawValue)
            seen.append(samples)
        }
    }

    func testSeededGeneratorRepeats() {
        var a = SeededGenerator(seed: 42)
        var b = SeededGenerator(seed: 42)
        var c = SeededGenerator(seed: 43)
        let first = (0..<8).map { _ in a.next() }
        XCTAssertEqual(first, (0..<8).map { _ in b.next() })
        XCTAssertNotEqual(first, (0..<8).map { _ in c.next() })
        for _ in 0..<1000 {
            XCTAssertTrue((-1...1).contains(a.signedUnit()))
            XCTAssertTrue((0..<1).contains(a.unit()))
        }
    }
}
