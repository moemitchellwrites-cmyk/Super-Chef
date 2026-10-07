import Foundation
import PantryScoring

/// The state of one round at the vessel: what is in the pan, how much of each,
/// and how it will be cooked. A value type with no UI and no clock, so the
/// whole round can be driven and checked from tests.
public struct Round: Equatable, Sendable {
    public struct Entry: Equatable, Identifiable, Sendable {
        public let ingredientId: String
        public var stepIndex: Int
        public var id: String { ingredientId }
    }

    public enum AddOutcome: Equatable, Sendable {
        /// Went into the vessel at its starting amount.
        case added
        /// Was already in the vessel; it is now the selected ingredient.
        case alreadyIn
        /// Not on this round's palette.
        case notOffered
    }

    public let dish: DishProfile
    /// The ingredients on offer, shuffled from the profile's palette by the round's seed.
    /// The authored order lists the real ingredients first and the decoys last,
    /// which would give the decoys away.
    public let palette: [Ingredient]
    /// The cooking methods on offer: every method some dish in the cuisine uses.
    public let methodChoices: [CookingMethod]
    public private(set) var entries: [Entry] = []
    /// PB-002 has one vessel, the wok. A vessel choice is PB-008.
    public var vessel: Vessel = .wok
    public private(set) var method: CookingMethod?
    /// The ingredient the amount stepper is showing.
    public private(set) var selectedId: String?

    private let ladders: [String: AmountLadder]

    public init(dish: DishProfile, library: ContentLibrary, seed: UInt64) {
        self.dish = dish
        var generator = SeededGenerator(seed: seed)
        var seen = Set<String>()
        let offered = dish.palette.compactMap { id -> Ingredient? in
            guard seen.insert(id).inserted else { return nil }
            return library.ingredient(id: id)
        }
        palette = offered.shuffled(using: &generator)
        var ladders: [String: AmountLadder] = [:]
        for ingredient in offered {
            ladders[ingredient.id] = AmountLadder(for: ingredient)
        }
        self.ladders = ladders
        let used = Set(library.dishes.flatMap(\.methods))
        methodChoices = CookingMethod.allCases.filter(used.contains)
    }

    // MARK: Reading

    public func ingredient(_ id: String) -> Ingredient? {
        palette.first { $0.id == id }
    }

    public func ladder(for id: String) -> AmountLadder? {
        ladders[id]
    }

    public func entry(for id: String) -> Entry? {
        entries.first { $0.ingredientId == id }
    }

    public func contains(_ id: String) -> Bool {
        entry(for: id) != nil
    }

    public func measure(for id: String) -> Measure? {
        guard let entry = entry(for: id), let ladder = ladders[id] else { return nil }
        return ladder.measure(at: entry.stepIndex)
    }

    public func pieceCount(for id: String) -> Int {
        guard let entry = entry(for: id), let ladder = ladders[id] else { return 0 }
        return ladder.pieceCount(at: entry.stepIndex)
    }

    /// A method is required before serving (PD-015): with the method optional, skipping
    /// it would be the safest play, because the vessel alone then carries all ten technique points.
    public var canServe: Bool {
        !entries.isEmpty && method != nil
    }

    /// What still stands between the player and serving, or nil when ready.
    public var servePrompt: String? {
        if entries.isEmpty { return "Add something to the wok" }
        if method == nil { return "Choose how to cook it" }
        return nil
    }

    // MARK: Changing

    @discardableResult
    public mutating func add(_ id: String) -> AddOutcome {
        guard let ladder = ladders[id] else { return .notOffered }
        selectedId = id
        guard !contains(id) else { return .alreadyIn }
        entries.append(Entry(ingredientId: id, stepIndex: ladder.startIndex))
        return .added
    }

    public mutating func select(_ id: String?) {
        guard let id else {
            selectedId = nil
            return
        }
        if contains(id) { selectedId = id }
    }

    /// Moves an ingredient's amount to a step on its ladder, clamped to the ladder's ends.
    /// Returns true when the amount changed.
    @discardableResult
    public mutating func setStep(_ id: String, to index: Int) -> Bool {
        guard let position = entries.firstIndex(where: { $0.ingredientId == id }), let ladder = ladders[id] else {
            return false
        }
        let clamped = ladder.clamped(index)
        guard entries[position].stepIndex != clamped else { return false }
        entries[position].stepIndex = clamped
        return true
    }

    @discardableResult
    public mutating func step(_ id: String, by delta: Int) -> Bool {
        guard let entry = entry(for: id) else { return false }
        return setStep(id, to: entry.stepIndex + delta)
    }

    @discardableResult
    public mutating func remove(_ id: String) -> Bool {
        guard let position = entries.firstIndex(where: { $0.ingredientId == id }) else { return false }
        entries.remove(at: position)
        if selectedId == id { selectedId = entries.last?.ingredientId }
        return true
    }

    public mutating func choose(_ method: CookingMethod) {
        self.method = method
    }

    public mutating func clear() {
        entries = []
        method = nil
        selectedId = nil
    }

    // MARK: Serving

    /// The attempt the scorer sees. Nil until the round can be served.
    public func attempt(timestamp: Date? = nil) -> Attempt? {
        guard canServe else { return nil }
        let lines = entries.compactMap { entry -> Attempt.Line? in
            guard let measure = ladders[entry.ingredientId]?.measure(at: entry.stepIndex) else { return nil }
            return Attempt.Line(ingredientId: entry.ingredientId, amount: measure.amount, unit: measure.unit)
        }
        return Attempt(dishId: dish.id, lines: lines, vessel: vessel, method: method, timestamp: timestamp)
    }
}

extension CookingMethod {
    /// Player-facing name.
    public var title: String {
        switch self {
        case .stirFry: return "Stir-fry"
        case .deepFry: return "Deep-fry"
        case .dryFry: return "Dry-fry"
        case .braise: return "Braise"
        case .boil: return "Boil"
        case .simmer: return "Simmer"
        case .steam: return "Steam"
        case .poach: return "Poach"
        case .bake: return "Bake"
        }
    }

    /// How hard the burner runs for this method, 0...1. Drives the flame's size, nothing else.
    public var flameLevel: Double {
        switch self {
        case .stirFry, .deepFry: return 1.0
        case .dryFry: return 0.8
        case .boil: return 0.7
        case .braise, .steam, .bake: return 0.45
        case .simmer, .poach: return 0.3
        }
    }
}

extension Ingredient {
    /// What a palette chip shows: the content's short name, or the full name when it is short already.
    public var chipName: String {
        shortName ?? name
    }
}
