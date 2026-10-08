import Foundation

/// The point values. They sum to 100. The brief's split was 40/35/15/10; PD-027 moved
/// ten points from coverage to ratio fit once Pantry mode took over the question of
/// what belongs. The tuning constants under them are Claude's calls, logged in docs/decisions.md.
public enum ScoreWeights {
    public static let coverage = 30.0
    public static let ratioFit = 45.0
    public static let signature = 15.0
    public static let technique = 10.0

    /// Technique splits into vessel and method when the attempt names a method.
    public static let vessel = 6.0
    public static let method = 4.0

    /// Each forbidden or off-cuisine ingredient costs `forbiddenFloor` points plus up to
    /// `forbiddenScaled` more, reached when it is `forbiddenFullAt` of the dish by weight.
    /// A pinch of basil costs 5; a cup of cream costs 12.
    public static let forbiddenFloor = 5.0
    public static let forbiddenScaled = 7.0
    public static let forbiddenFullAt = 0.10

    /// A ratio outside its band loses credit linearly in log space and reaches zero
    /// when it is off by this factor. 1.5x off keeps about 56 %; 2x keeps about 24 %.
    public static let ratioZeroAtFactor = 2.5

    /// A dish with anything in it that doesn't belong (off-cuisine, or forbidden for the
    /// dish) can't score above a ceiling, however good the rest is (PD-027). A trace caps
    /// it at `wrongIngredientCeiling`, under the 85 where "good" starts; the ceiling then
    /// falls in a straight line to `wrongIngredientLowCeiling`, reached when the things
    /// that don't belong are `wrongIngredientLowAt` of the dish by weight.
    /// A pinch of basil caps a perfect mapo tofu at 79; a cup of cream caps it at 50.
    public static let wrongIngredientCeiling = 79.0
    public static let wrongIngredientLowCeiling = 50.0
    public static let wrongIngredientLowAt = 0.20

    /// A flavour axis outside its band loses credit linearly and reaches zero this
    /// many levels (on the 0 to 5 scale) past the band edge.
    public static let signatureZeroAtLevels = 2.0

    /// Flavour levels are capped here.
    public static let maxLevel = 5.0
}

/// Deterministic, offline scoring of an attempt against a dish profile.
/// Pure function of its inputs: no clock, no randomness, no I/O.
public struct Scorer: Sendable {
    public let cuisine: Cuisine
    public let ingredients: [String: Ingredient]

    public init(cuisine: Cuisine, ingredients: [Ingredient]) {
        self.cuisine = cuisine
        var byId: [String: Ingredient] = [:]
        for ingredient in ingredients {
            byId[ingredient.id] = ingredient
        }
        self.ingredients = byId
    }

    public func score(_ attempt: Attempt, against dish: DishProfile) -> ScoreBreakdown {
        var misses: [Miss] = []

        // Weigh everything. Grams per family drive coverage and ratios; grams per
        // ingredient drive the forbidden penalty and the flavour levels.
        var gramsByFamily: [String: Double] = [:]
        var gramsByIngredient: [String: Double] = [:]
        var ingredientOrder: [String] = []
        var totalGrams = 0.0
        for line in attempt.lines {
            guard let ingredient = ingredients[line.ingredientId] else {
                misses.append(Miss(.unknownIngredient, line.ingredientId))
                continue
            }
            guard line.amount > 0 else { continue }
            guard let grams = ingredient.grams(amount: line.amount, unit: line.unit) else {
                misses.append(Miss(.unmeasurable, "\(line.ingredientId) in \(line.unit.rawValue)"))
                continue
            }
            gramsByFamily[ingredient.family, default: 0] += grams
            if gramsByIngredient[ingredient.id] == nil { ingredientOrder.append(ingredient.id) }
            gramsByIngredient[ingredient.id, default: 0] += grams
            totalGrams += grams
        }
        func familyGrams(_ families: [String]) -> Double {
            families.reduce(0) { $0 + (gramsByFamily[$1] ?? 0) }
        }

        // PD-008: a family that is present but whose key ratio (one it is the numerator of)
        // is off by `ratioZeroAtFactor` or more counts as "present, but wrong amount" and
        // earns half its coverage credit.
        var grosslyOffFamilies = Set<String>()
        for band in dish.ratios {
            let numerator = familyGrams(band.numerator)
            let denominator = familyGrams(band.denominator)
            guard numerator > 0, denominator > 0 else { continue }
            if Scorer.bandCredit(ratio: numerator / denominator, low: band.low, high: band.high) == 0 {
                grosslyOffFamilies.formUnion(band.numerator)
            }
        }

        // Coverage: required families present...
        let requiredWeight = dish.required.reduce(0) { $0 + $1.weight }
        var earned = 0.0
        for requirement in dish.required {
            let need = max(1, requirement.minPresent)
            let present = requirement.anyOf.filter { (gramsByFamily[$0] ?? 0) > 0 }.count
            if present >= need {
                if grosslyOffFamilies.isDisjoint(with: requirement.anyOf) {
                    earned += requirement.weight
                } else {
                    earned += requirement.weight / 2
                    misses.append(Miss(.wrongAmount, requirement.label))
                }
            } else if present == 0 {
                misses.append(Miss(.missingRequired, requirement.label))
            } else {
                earned += requirement.weight * Double(present) / Double(need)
                misses.append(Miss(.partialRequired, requirement.label))
            }
        }
        var coverage = requiredWeight > 0 ? ScoreWeights.coverage * earned / requiredWeight : ScoreWeights.coverage

        // ...and forbidden ones absent. Amount-aware, with a floor so a pinch still costs.
        let offCuisine = Set(cuisine.offCuisineFamilies)
        let forbidden = Set(dish.forbidden)
        var penalty = 0.0
        var wrongFraction = 0.0
        var hasWrongIngredient = false
        for id in ingredientOrder {
            guard let ingredient = ingredients[id] else { continue }
            let isOff = offCuisine.contains(ingredient.family)
            let isForbidden = forbidden.contains(ingredient.family)
            guard isOff || isForbidden else { continue }
            let fraction = totalGrams > 0 ? (gramsByIngredient[id] ?? 0) / totalGrams : 0
            hasWrongIngredient = true
            wrongFraction += fraction
            penalty += ScoreWeights.forbiddenFloor
                + ScoreWeights.forbiddenScaled * min(1, fraction / ScoreWeights.forbiddenFullAt)
            misses.append(Miss(isOff ? .offCuisine : .forbiddenForDish, id))
        }
        coverage = max(0, coverage - penalty)

        // Ratio fit.
        let ratioWeight = dish.ratios.reduce(0) { $0 + $1.weight }
        var ratioCredit = 0.0
        for band in dish.ratios {
            let numerator = familyGrams(band.numerator)
            let denominator = familyGrams(band.denominator)
            guard numerator > 0, denominator > 0 else {
                misses.append(Miss(.ratioUndefined, band.label))
                continue
            }
            let ratio = numerator / denominator
            ratioCredit += band.weight * Scorer.bandCredit(ratio: ratio, low: band.low, high: band.high)
            if ratio < band.low {
                misses.append(Miss(.ratioLow, band.label))
            } else if ratio > band.high {
                misses.append(Miss(.ratioHigh, band.label))
            }
        }
        let ratioFit = ratioWeight > 0 ? ScoreWeights.ratioFit * ratioCredit / ratioWeight : ScoreWeights.ratioFit

        // Signature: level per axis = sum over ingredients of potency x percent of the dish by weight.
        let envelope = dish.signature ?? cuisine.signature
        var levels = FlavorVector()
        var signatureCredit = 0.0
        for axis in FlavorAxis.allCases {
            var level = 0.0
            if totalGrams > 0 {
                for id in ingredientOrder {
                    guard let ingredient = ingredients[id], let grams = gramsByIngredient[id] else { continue }
                    level += ingredient.potency[axis] * (grams / totalGrams * 100)
                }
            }
            level = min(ScoreWeights.maxLevel, level)
            levels[axis] = level
            let band = envelope[axis]
            if band.contains(level) {
                signatureCredit += 1
            } else {
                let distance = level < band.low ? band.low - level : level - band.high
                signatureCredit += max(0, 1 - distance / ScoreWeights.signatureZeroAtLevels)
                misses.append(Miss(level < band.low ? .signatureLow : .signatureHigh, axis.rawValue))
            }
        }
        let signature = ScoreWeights.signature * signatureCredit / Double(FlavorAxis.allCases.count)

        // Technique. Without a method the vessel carries the whole 10.
        let vesselFits = dish.vessels.contains(attempt.vessel)
        var technique = 0.0
        if let method = attempt.method {
            technique += vesselFits ? ScoreWeights.vessel : 0
            if dish.methods.contains(method) {
                technique += ScoreWeights.method
            } else {
                misses.append(Miss(.wrongMethod, method.rawValue))
            }
        } else {
            technique = vesselFits ? ScoreWeights.technique : 0
        }
        if !vesselFits { misses.append(Miss(.wrongVessel, attempt.vessel.rawValue)) }

        let sum = Int(min(100, max(0, coverage + ratioFit + signature + technique)).rounded())
        var ceiling: Int?
        if hasWrongIngredient {
            let slide = min(1, wrongFraction / ScoreWeights.wrongIngredientLowAt)
            let limit = ScoreWeights.wrongIngredientCeiling
                - (ScoreWeights.wrongIngredientCeiling - ScoreWeights.wrongIngredientLowCeiling) * slide
            if Double(sum) > limit { ceiling = Int(limit.rounded(.down)) }
        }
        return ScoreBreakdown(
            coverage: Scorer.tenths(coverage),
            ratioFit: Scorer.tenths(ratioFit),
            signature: Scorer.tenths(signature),
            technique: Scorer.tenths(technique),
            total: ceiling ?? sum,
            levels: levels,
            misses: misses,
            cappedAt: ceiling
        )
    }

    /// 1 inside the band; outside, linear falloff in log space reaching 0 at `ratioZeroAtFactor` off.
    /// Symmetric: half the low edge and twice the high edge cost the same.
    static func bandCredit(ratio: Double, low: Double, high: Double) -> Double {
        if ratio >= low && ratio <= high { return 1 }
        guard ratio > 0 else { return 0 }
        let edge = ratio < low ? low : high
        let distance = abs(log(ratio / edge))
        return max(0, 1 - distance / log(ScoreWeights.ratioZeroAtFactor))
    }

    static func tenths(_ value: Double) -> Double {
        (value * 10).rounded() / 10
    }
}
