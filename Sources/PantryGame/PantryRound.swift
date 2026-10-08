import Foundation
import PantryScoring

/// The verdict on a Pantry round (PD-025): a count the player can act on, and names
/// for everything behind it. No percentage and no amounts.
public struct PantryResult: Equatable, Sendable {
    /// Picked ingredients that are essential to the dish, in the order they were picked.
    public var found: [String]
    /// Essentials the player left out, as the dish profile labels them ("Sichuan peppercorn").
    /// A requirement that wants two things and got one appears once.
    public var missed: [String]
    /// Picked ingredients that are at home in the dish but that it stands without.
    public var alsoBelongs: [String]
    /// Picked ingredients from another cuisine, or wrong for this dish.
    public var wrong: [String]
    /// How many essentials the dish has. `found.count` is out of this.
    public var essentials: Int

    /// Every essential found and nothing that doesn't belong.
    public var isClean: Bool {
        found.count == essentials && wrong.isEmpty
    }
}

/// Judges a set of picks against a dish. An essential is one slot of one of the
/// profile's requirements: "aromatics, any two of garlic, ginger and scallion" is two
/// essentials, and a third aromatic is welcome but fills nothing.
public enum PantryJudge {
    public static func essentials(in dish: DishProfile) -> Int {
        dish.required.reduce(0) { $0 + max(1, $1.minPresent) }
    }

    public static func judge(picks: [String], for dish: DishProfile, in library: ContentLibrary) -> PantryResult {
        let offCuisine = Set(library.cuisine.offCuisineFamilies)
        let forbidden = Set(dish.forbidden)
        var filled: [[String]] = Array(repeating: [], count: dish.required.count)
        var result = PantryResult(found: [], missed: [], alsoBelongs: [], wrong: [], essentials: essentials(in: dish))
        var seen = Set<String>()

        for id in picks {
            guard seen.insert(id).inserted, let ingredient = library.ingredient(id: id) else { continue }
            let family = ingredient.family
            if offCuisine.contains(family) || forbidden.contains(family) {
                result.wrong.append(id)
                continue
            }
            // A family fills one slot of the first requirement that still wants it.
            var filledASlot = false
            for (index, requirement) in dish.required.enumerated() where requirement.anyOf.contains(family) {
                if filled[index].count < max(1, requirement.minPresent) && !filled[index].contains(family) {
                    filled[index].append(family)
                    filledASlot = true
                    break
                }
            }
            if filledASlot {
                result.found.append(id)
            } else {
                result.alsoBelongs.append(id)
            }
        }
        for (index, requirement) in dish.required.enumerated() where filled[index].count < max(1, requirement.minPresent) {
            result.missed.append(requirement.label)
        }
        return result
    }
}

/// One Pantry round: pick what the dish can't be without. A value type like `Round`.
public struct PantryRound: Equatable, Sendable {
    public enum ToggleOutcome: Equatable, Sendable {
        case added, removed
        /// The wok is at its limit; something has to come out first.
        case full
        case notOffered
    }

    /// Picks allowed beyond the number of essentials: none. "Find the 6" means six picks, so every
    /// pick has to earn its place and the count means one thing (Moe, after playing with two and
    /// then three spare picks; PD-025). Taking a pick back out is free.
    public static let slack = 0

    public let dish: DishProfile
    public let palette: [Ingredient]
    public let essentials: Int
    public let pickLimit: Int
    public private(set) var picks: [String] = []

    public init(dish: DishProfile, library: ContentLibrary, seed: UInt64) {
        self.dish = dish
        var generator = SeededGenerator(seed: seed)
        var seen = Set<String>()
        let offered = dish.palette.compactMap { id -> Ingredient? in
            guard seen.insert(id).inserted else { return nil }
            return library.ingredient(id: id)
        }
        palette = offered.shuffled(using: &generator)
        essentials = PantryJudge.essentials(in: dish)
        pickLimit = min(offered.count, essentials + PantryRound.slack)
    }

    public var picksLeft: Int { pickLimit - picks.count }
    public var canServe: Bool { !picks.isEmpty }

    public func contains(_ id: String) -> Bool {
        picks.contains(id)
    }

    /// Tap a chip: in if it was out, out if it was in.
    @discardableResult
    public mutating func toggle(_ id: String) -> ToggleOutcome {
        guard palette.contains(where: { $0.id == id }) else { return .notOffered }
        if let index = picks.firstIndex(of: id) {
            picks.remove(at: index)
            return .removed
        }
        guard picks.count < pickLimit else { return .full }
        picks.append(id)
        return .added
    }

    public mutating func clear() {
        picks = []
    }

    public func result(in library: ContentLibrary) -> PantryResult? {
        guard canServe else { return nil }
        return PantryJudge.judge(picks: picks, for: dish, in: library)
    }
}
