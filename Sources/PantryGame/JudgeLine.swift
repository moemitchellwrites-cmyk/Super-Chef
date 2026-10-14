import Foundation
import PantryScoring

/// The judge's one line (PB-003): a sentence built from the verdict that names the single thing most
/// worth fixing. Canned, with no model call. When the AI judge arrives it replaces these words and
/// never the score. `web/engine.js` carries the same sentences, held equal by the parity file.
public enum JudgeLine {
    /// Which miss the line is about, most important first. One wrong ingredient matters more than a
    /// missing one, which matters more than the pan, the method, and then the amounts.
    static let priority: [Miss.Kind] = [
        .offCuisine, .forbiddenForDish, .missingRequired, .wrongVessel, .wrongMethod,
        .partialRequired, .wrongAmount, .ratioHigh, .ratioLow, .signatureHigh, .signatureLow,
    ]

    public static func kitchen(_ breakdown: ScoreBreakdown, dish: DishProfile, library: ContentLibrary) -> String {
        let name = RecipeText.lowercasedFirst(dish.name)
        var chosen: Miss?
        for kind in priority {
            if let miss = breakdown.misses.first(where: { $0.kind == kind }) {
                chosen = miss
                break
            }
        }
        guard let miss = chosen else {
            return breakdown.total >= 95 ? "That's \(name). Nothing to fix." : "Close to the mark all round."
        }
        // What the parts add up to before any ceiling: how good the dish is apart from the one wrong thing.
        let earned = breakdown.coverage + breakdown.ratioFit + breakdown.signature + breakdown.technique
        // Worded so the sentence reads the same for "basil" and for "chopped salted chilies".
        let leaveOut = earned >= 80 ? "Leave that out and this is close." : "Start by leaving that out."
        switch miss.kind {
        case .offCuisine:
            return "The \(ingredientName(miss.subject, in: library)) came from another kitchen. \(leaveOut)"
        case .forbiddenForDish:
            return "No \(ingredientName(miss.subject, in: library)) in \(name). \(leaveOut)"
        case .missingRequired:
            return "It isn't \(name) without \(miss.subject)."
        case .wrongVessel:
            // Name what the recipe uses, so the line and the recipe agree when a dish allows more than one.
            guard let wanted = dish.recipe?.vessel ?? dish.vessels.first else { return "Right idea, wrong pan." }
            return "Right idea, wrong pan: \(name) is cooked in a \(wanted.noun)."
        case .wrongMethod:
            let used = CookingMethod(rawValue: miss.subject)?.gerund ?? miss.subject
            let start = used.prefix(1).uppercased() + used.dropFirst()
            guard let wanted = dish.recipe?.method ?? dish.methods.first else { return "\(start) is the wrong method here." }
            return "\(start) is the wrong method here: \(name) wants \(wanted.gerund)."
        case .partialRequired:
            return "It's thin on \(miss.subject)."
        case .wrongAmount:
            return "There's \(miss.subject) in it, but the amount is far off."
        case .ratioHigh:
            let sides = ratioSides(miss.subject)
            return sides.map { "Too much \($0.0) for the \($0.1)." } ?? "Too much \(miss.subject)."
        case .ratioLow:
            let sides = ratioSides(miss.subject)
            return sides.map { "It wants more \($0.0) for that much \($0.1)." } ?? "It wants more \(miss.subject)."
        case .signatureHigh:
            return "Too much \(axisName(miss.subject)) for \(name)."
        case .signatureLow:
            return "It wants more \(axisName(miss.subject))."
        case .ratioUndefined, .unknownIngredient, .unmeasurable:
            return "Close to the mark all round."
        }
    }

    public static func pantry(_ result: PantryResult, dish: DishProfile, library: ContentLibrary) -> String {
        if result.isClean {
            return "All \(result.essentials) essentials, and nothing that doesn't belong."
        }
        if let wrong = result.wrong.first {
            let line = "No \(ingredientName(wrong, in: library)) in \(RecipeText.lowercasedFirst(dish.name))."
            return result.missed.first.map { "\(line) And it still needs \($0)." } ?? line
        }
        guard let missed = result.missed.first else {
            return "\(result.found.count) of \(result.essentials) essentials found."
        }
        if result.essentials - result.found.count == 1 {
            return "One short: it needs \(missed)."
        }
        return "\(result.found.count) of \(result.essentials). Start with \(missed)."
    }

    static func ingredientName(_ id: String, in library: ContentLibrary) -> String {
        RecipeText.lowercasedFirst(library.ingredient(id: id)?.chipName ?? id)
    }

    /// "doubanjiang to tofu" is doubanjiang against tofu. A label may carry a note in brackets.
    static func ratioSides(_ label: String) -> (String, String)? {
        let plain = label.components(separatedBy: " (")[0]
        let sides = plain.components(separatedBy: " to ")
        guard sides.count == 2 else { return nil }
        return (sides[0], sides[1])
    }

    static func axisName(_ axis: String) -> String {
        switch FlavorAxis(rawValue: axis) {
        case .heat: return "heat"
        case .numbing: return "numbing"
        case .acid: return "sourness"
        case .umami: return "savoury depth"
        case .sweet: return "sweetness"
        case nil: return axis
        }
    }
}
