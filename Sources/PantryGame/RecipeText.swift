import Foundation
import PantryScoring

/// How a recipe's amounts read on the score sheet: "2½ tbsp", "⅓ cup", "400 g".
public enum RecipeText {
    private static let fractions: [(Double, String)] = [
        (0.125, "⅛"), (0.25, "¼"), (1.0 / 3.0, "⅓"), (0.5, "½"), (2.0 / 3.0, "⅔"), (0.75, "¾"),
    ]

    public static func amount(_ amount: Double, _ unit: AmountUnit) -> String {
        if unit == .grams {
            return amount >= 1000 ? "\(number(amount / 1000)) kg" : "\(number(amount)) g"
        }
        if unit == .pinch {
            return amount == 1 ? "a pinch" : "\(number(amount)) pinches"
        }
        let name = unit == .cup && amount > 1 ? "cups" : unit.rawValue
        return "\(number(amount)) \(name)"
    }

    /// Whole numbers plain, common fractions as one glyph, anything else to one decimal place.
    static func number(_ value: Double) -> String {
        let whole = value.rounded(.down)
        let rest = value - whole
        if rest < 0.001 { return String(Int(whole)) }
        for (fraction, glyph) in fractions where abs(rest - fraction) < 0.01 {
            return whole == 0 ? glyph : "\(Int(whole))\(glyph)"
        }
        return String(format: "%.1f", value)
    }

    /// One recipe line as the player's measures read it (PD-041): the amount is shown as the step of
    /// that ingredient's stepper nearest to it, so the recipe and the stepper always speak the same way.
    public static func line(_ line: Attempt.Line, in library: ContentLibrary, system: MeasureSystem) -> String {
        guard let ingredient = library.ingredient(id: line.ingredientId) else {
            return "\(amount(line.amount, line.unit)) \(lowercasedFirst(line.ingredientId))"
        }
        return "\(measure(line, of: ingredient, system: system).label) \(lowercasedFirst(ingredient.name))"
    }

    /// The stepper position a recipe line lands on in a measure system.
    public static func measure(_ line: Attempt.Line, of ingredient: Ingredient, system: MeasureSystem) -> Measure {
        let ladder = AmountLadder(for: ingredient, system: system)
        if let exact = ladder.steps.first(where: { $0.unit == line.unit && abs($0.amount - line.amount) < 0.0001 }) {
            return exact
        }
        guard let grams = ingredient.grams(amount: line.amount, unit: line.unit) else {
            return Measure(line.amount, line.unit, amount(line.amount, line.unit))
        }
        return ladder.measure(at: ladder.nearestIndex(toGrams: grams, of: ingredient))
    }

    /// The recipe lines that are the dish's essentials, the ones a Pantry round asks for. Marked on the recipe
    /// so "not essential" never reads as "wrong" (PD-025).
    public static func essentialIds(of dish: DishProfile, in library: ContentLibrary) -> Set<String> {
        guard let recipe = dish.recipe else { return [] }
        return Set(PantryJudge.judge(picks: recipe.lines.map(\.ingredientId), for: dish, in: library).found)
    }

    /// "Garlic, minced" reads as "garlic, minced" after an amount; "Sichuan peppercorns" keeps its capital.
    static func lowercasedFirst(_ name: String) -> String {
        let properNouns = ["Sichuan", "Shaoxing", "Chinkiang", "Napa", "Chongqing"]
        if properNouns.contains(where: name.hasPrefix) { return name }
        return name.prefix(1).lowercased() + name.dropFirst()
    }
}
