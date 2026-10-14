import Foundation
import PantryScoring

/// One position on the amount stepper: what the player sees and what the scorer gets.
public struct Measure: Equatable, Hashable, Sendable {
    public let amount: Double
    public let unit: AmountUnit
    /// What the stepper shows: "pinch", "1½ tbsp", "400 g", "14 oz", "180 ml".
    public let label: String

    public init(_ amount: Double, _ unit: AmountUnit, _ label: String) {
        self.amount = amount
        self.unit = unit
        self.label = label
    }
}

/// Which measures the player reads (PD-041). The scorer never sees this: it works in grams.
public enum MeasureSystem: String, CaseIterable, Sendable {
    /// Spoons and cups; ounces and pounds.
    case us
    /// Spoons for small amounts, then millilitres; grams.
    case metric
}

/// The amounts the stepper offers for one ingredient (PD-013).
///
/// Volume ingredients share one ladder that climbs through the brief's units
/// (pinch, tsp, tbsp, cup) so the player never picks a unit; weight-only
/// ingredients step through grams. The steps are roughly geometric because the
/// scorer compares ratios in log space (PD-004): each tap is a similar-sized
/// move in score terms. `StepperReachabilityTests` proves every good golden
/// still scores 85+ when its amounts are snapped to these steps.
public struct AmountLadder: Equatable, Sendable {
    public let steps: [Measure]
    /// Where a freshly added ingredient starts: one of its default unit, or 100 g.
    public let startIndex: Int

    public static let volume: [Measure] = [
        Measure(1, .pinch, "pinch"),
        Measure(0.25, .tsp, "¼ tsp"),
        Measure(0.5, .tsp, "½ tsp"),
        Measure(1, .tsp, "1 tsp"),
        Measure(1.5, .tsp, "1½ tsp"),
        Measure(2, .tsp, "2 tsp"),
        Measure(1, .tbsp, "1 tbsp"),
        Measure(1.5, .tbsp, "1½ tbsp"),
        Measure(2, .tbsp, "2 tbsp"),
        Measure(2.5, .tbsp, "2½ tbsp"),
        Measure(3, .tbsp, "3 tbsp"),
        Measure(0.25, .cup, "¼ cup"),
        Measure(1.0 / 3.0, .cup, "⅓ cup"),
        Measure(0.5, .cup, "½ cup"),
        Measure(0.75, .cup, "¾ cup"),
        Measure(1, .cup, "1 cup"),
        Measure(1.5, .cup, "1½ cups"),
        Measure(2, .cup, "2 cups"),
        Measure(2.5, .cup, "2½ cups"),
        Measure(3, .cup, "3 cups"),
        Measure(4, .cup, "4 cups"),
    ]

    public static let weight: [Measure] = [5, 10, 15, 20, 25, 30, 40, 50, 60, 75, 100, 125, 150, 200, 250,
                                           300, 350, 400, 500, 600, 750, 1000].map { grams in
        Measure(Double(grams), .grams, grams == 1000 ? "1 kg" : "\(grams) g")
    }

    /// The volume ladder as a metric cook reads it: the same amounts, with the cup steps in millilitres
    /// (a metric cup is 250 ml). Spoons stay: nobody weighs half a teaspoon.
    public static let volumeMetric: [Measure] = {
        let millilitres: [Double: String] = [
            0.25: "60 ml", 1.0 / 3.0: "80 ml", 0.5: "125 ml", 0.75: "180 ml", 1: "250 ml",
            1.5: "375 ml", 2: "500 ml", 2.5: "625 ml", 3: "750 ml", 4: "1 L",
        ]
        return volume.map { step in
            guard step.unit == .cup, let label = millilitres[step.amount] else { return step }
            return Measure(step.amount, step.unit, label)
        }
    }()

    static let gramsPerOunce = 28.349523125

    /// Weight as a US cook reads it. Each step is still handed to the scorer in grams.
    public static let weightUS: [Measure] = {
        let ounces: [(Double, String)] = [
            (0.25, "¼ oz"), (0.5, "½ oz"), (0.75, "¾ oz"), (1, "1 oz"), (1.5, "1½ oz"), (2, "2 oz"), (2.5, "2½ oz"),
            (3, "3 oz"), (4, "4 oz"), (5, "5 oz"), (6, "6 oz"), (7, "7 oz"), (8, "8 oz"), (10, "10 oz"), (12, "12 oz"),
            (14, "14 oz"), (16, "1 lb"), (20, "1¼ lb"), (24, "1½ lb"), (32, "2 lb"),
        ]
        return ounces.map { Measure(($0.0 * gramsPerOunce).rounded(), .grams, $0.1) }
    }()

    public init(for ingredient: Ingredient, system: MeasureSystem) {
        // A volume ladder needs a teaspoon weight; without one, fall back to weight
        // rather than hand the scorer an amount it can't measure.
        if ingredient.defaultUnit == .grams || ingredient.gramsPerTeaspoon == nil {
            steps = system == .us ? AmountLadder.weightUS : AmountLadder.weight
            // A quarter pound, or 100 g.
            let start: Double = system == .us ? (4 * AmountLadder.gramsPerOunce).rounded() : 100
            startIndex = steps.firstIndex { $0.amount == start } ?? 0
        } else {
            steps = system == .us ? AmountLadder.volume : AmountLadder.volumeMetric
            let unit = ingredient.defaultUnit
            startIndex = steps.firstIndex { $0.unit == unit && $0.amount == 1 } ?? 0
        }
    }

    public func clamped(_ index: Int) -> Int {
        min(max(index, 0), steps.count - 1)
    }

    public func measure(at index: Int) -> Measure {
        steps[clamped(index)]
    }

    /// How many pieces to show in the vessel for this step: 1 at the bottom of
    /// the ladder, `most` at the top. Purely visual.
    public func pieceCount(at index: Int, most: Int = 4) -> Int {
        guard steps.count > 1, most > 1 else { return 1 }
        return 1 + clamped(index) * (most - 1) / (steps.count - 1)
    }

    /// The step closest (in ratio terms) to a weight in grams. Used by tests and
    /// the demo script to turn a recipe-style amount into a stepper position.
    public func nearestIndex(toGrams grams: Double, of ingredient: Ingredient) -> Int {
        guard grams > 0 else { return 0 }
        var best = 0
        var bestDistance = Double.infinity
        for (index, step) in steps.enumerated() {
            guard let stepGrams = ingredient.grams(amount: step.amount, unit: step.unit), stepGrams > 0 else { continue }
            let distance = abs(log(stepGrams / grams))
            if distance < bestDistance {
                best = index
                bestDistance = distance
            }
        }
        return best
    }
}
