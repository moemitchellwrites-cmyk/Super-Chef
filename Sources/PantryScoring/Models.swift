import Foundation

// The data model behind the scoring engine. These types mirror the bundled JSON
// (Resources/<cuisine>/*.json) one to one; change both together and bump
// `schemaVersion` when the shape changes.

/// Units the amount stepper offers. Everything converts to grams before scoring
/// (see `Ingredient.grams(amount:unit:)`); the units are a display choice.
public enum AmountUnit: String, Codable, CaseIterable, Sendable {
    case pinch, tsp, tbsp, cup, grams

    /// Teaspoons per unit, or nil for a weight unit.
    public var teaspoons: Double? {
        switch self {
        case .pinch: return 1.0 / 8.0
        case .tsp: return 1
        case .tbsp: return 3
        case .cup: return 48
        case .grams: return nil
        }
    }
}

public enum Vessel: String, Codable, CaseIterable, Sendable {
    case pot, pan, skillet, wok
    case bakingDish = "baking-dish"
    case breadPan = "bread-pan"
}

public enum CookingMethod: String, Codable, CaseIterable, Sendable {
    case stirFry = "stir-fry"
    case deepFry = "deep-fry"
    case dryFry = "dry-fry"
    case braise, boil, simmer, steam, poach, bake
}

public enum FlavorAxis: String, Codable, CaseIterable, Sendable {
    case heat, numbing, acid, umami, sweet
}

/// A closed range on a 0 to 5 flavour scale, or a ratio range. Encoded as `[low, high]`.
public struct Band: Codable, Equatable, Sendable {
    public var low: Double
    public var high: Double

    public init(low: Double, high: Double) {
        self.low = low
        self.high = high
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        low = try container.decode(Double.self)
        high = try container.decode(Double.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(low)
        try container.encode(high)
    }

    public func contains(_ value: Double) -> Bool {
        value >= low && value <= high
    }
}

/// Five flavour axes as numbers. Used both for an ingredient's potency (level
/// contributed per 1 % of the dish by weight) and for a measured attempt's levels.
public struct FlavorVector: Codable, Equatable, Sendable {
    public var heat: Double
    public var numbing: Double
    public var acid: Double
    public var umami: Double
    public var sweet: Double

    public init(heat: Double = 0, numbing: Double = 0, acid: Double = 0, umami: Double = 0, sweet: Double = 0) {
        self.heat = heat
        self.numbing = numbing
        self.acid = acid
        self.umami = umami
        self.sweet = sweet
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        heat = try c.decodeIfPresent(Double.self, forKey: .heat) ?? 0
        numbing = try c.decodeIfPresent(Double.self, forKey: .numbing) ?? 0
        acid = try c.decodeIfPresent(Double.self, forKey: .acid) ?? 0
        umami = try c.decodeIfPresent(Double.self, forKey: .umami) ?? 0
        sweet = try c.decodeIfPresent(Double.self, forKey: .sweet) ?? 0
    }

    public subscript(axis: FlavorAxis) -> Double {
        get {
            switch axis {
            case .heat: return heat
            case .numbing: return numbing
            case .acid: return acid
            case .umami: return umami
            case .sweet: return sweet
            }
        }
        set {
            switch axis {
            case .heat: heat = newValue
            case .numbing: numbing = newValue
            case .acid: acid = newValue
            case .umami: umami = newValue
            case .sweet: sweet = newValue
            }
        }
    }
}

/// The acceptable band per flavour axis, on a 0 to 5 scale.
public struct SignatureEnvelope: Codable, Equatable, Sendable {
    public var heat: Band
    public var numbing: Band
    public var acid: Band
    public var umami: Band
    public var sweet: Band

    public init(heat: Band, numbing: Band, acid: Band, umami: Band, sweet: Band) {
        self.heat = heat
        self.numbing = numbing
        self.acid = acid
        self.umami = umami
        self.sweet = sweet
    }

    public subscript(axis: FlavorAxis) -> Band {
        switch axis {
        case .heat: return heat
        case .numbing: return numbing
        case .acid: return acid
        case .umami: return umami
        case .sweet: return sweet
        }
    }
}

public struct Cuisine: Codable, Equatable, Sendable {
    public var schemaVersion: Int
    public var id: String
    public var name: String
    /// Fallback envelope for dishes that don't define their own.
    public var signature: SignatureEnvelope
    /// Ingredient families that signal drift to another cuisine. Penalised in every dish.
    public var offCuisineFamilies: [String]
    public var vessels: [Vessel]
    public var notes: String?

    public init(schemaVersion: Int = 1, id: String, name: String, signature: SignatureEnvelope,
                offCuisineFamilies: [String], vessels: [Vessel], notes: String? = nil) {
        self.schemaVersion = schemaVersion
        self.id = id
        self.name = name
        self.signature = signature
        self.offCuisineFamilies = offCuisineFamilies
        self.vessels = vessels
        self.notes = notes
    }
}

public struct Ingredient: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var name: String
    /// A label short enough for a palette chip, when `name` isn't. Like `name`, it must
    /// not say which cuisine the ingredient belongs to: that is the player's job.
    public var shortName: String?
    /// Profiles refer to families, not ingredients, so substitutes score alike
    /// (firm and silken tofu are both `tofu`).
    public var family: String
    public var defaultUnit: AmountUnit
    /// Grams in one level teaspoon. Nil for ingredients measured by weight only.
    public var gramsPerTeaspoon: Double?
    public var potency: FlavorVector
    public var soundCue: String
    public var icon: String

    public init(id: String, name: String, family: String, defaultUnit: AmountUnit, gramsPerTeaspoon: Double? = nil,
                potency: FlavorVector = FlavorVector(), soundCue: String = "clatter", icon: String = "generic",
                shortName: String? = nil) {
        self.id = id
        self.name = name
        self.shortName = shortName
        self.family = family
        self.defaultUnit = defaultUnit
        self.gramsPerTeaspoon = gramsPerTeaspoon
        self.potency = potency
        self.soundCue = soundCue
        self.icon = icon
    }

    /// Converts an amount in any unit to grams. Returns nil when a volume unit is
    /// used on an ingredient that has no teaspoon weight.
    public func grams(amount: Double, unit: AmountUnit) -> Double? {
        guard let teaspoons = unit.teaspoons else { return amount }
        guard let perTeaspoon = gramsPerTeaspoon else { return nil }
        return amount * teaspoons * perTeaspoon
    }
}

/// One required element of a dish: any of these families, at least `minPresent` of them.
public struct Requirement: Codable, Equatable, Sendable {
    public var label: String
    public var anyOf: [String]
    public var weight: Double
    public var minPresent: Int

    public init(label: String, anyOf: [String], weight: Double = 1, minPresent: Int = 1) {
        self.label = label
        self.anyOf = anyOf
        self.weight = weight
        self.minPresent = minPresent
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        label = try c.decode(String.self, forKey: .label)
        anyOf = try c.decode([String].self, forKey: .anyOf)
        weight = try c.decodeIfPresent(Double.self, forKey: .weight) ?? 1
        minPresent = try c.decodeIfPresent(Int.self, forKey: .minPresent) ?? 1
    }
}

/// A key ratio by weight: (sum of numerator families) / (sum of denominator families)
/// should fall in `low...high`.
public struct RatioBand: Codable, Equatable, Sendable {
    public var label: String
    public var numerator: [String]
    public var denominator: [String]
    public var low: Double
    public var high: Double
    public var weight: Double

    public init(label: String, numerator: [String], denominator: [String], low: Double, high: Double, weight: Double = 1) {
        self.label = label
        self.numerator = numerator
        self.denominator = denominator
        self.low = low
        self.high = high
        self.weight = weight
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        label = try c.decode(String.self, forKey: .label)
        numerator = try c.decode([String].self, forKey: .numerator)
        denominator = try c.decode([String].self, forKey: .denominator)
        low = try c.decode(Double.self, forKey: .low)
        high = try c.decode(Double.self, forKey: .high)
        weight = try c.decodeIfPresent(Double.self, forKey: .weight) ?? 1
    }
}

public struct DishProfile: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var cuisineId: String
    public var name: String
    /// One line shown before cooking, for a player who has never eaten the dish (PD-024).
    /// It describes the plate: texture, look, how it should taste. It never names a
    /// seasoning, an amount or a cooking method; working those out is the round.
    public var brief: String?
    public var vessels: [Vessel]
    public var methods: [CookingMethod]
    public var required: [Requirement]
    /// Families that are common but not expected. Informational; never scored.
    public var optional: [String]
    /// Families that signal the player has drifted from this dish, on top of the cuisine's off-cuisine list.
    public var forbidden: [String]
    public var ratios: [RatioBand]
    /// Per-dish envelope. Falls back to the cuisine's when nil.
    public var signature: SignatureEnvelope?
    /// The 12 to 20 ingredient ids offered in a round, real and decoy mixed.
    public var palette: [String]
    public var cardId: String
    /// Internal: reference sources and authoring notes. Never shown to players.
    public var notes: String?

    public init(id: String, cuisineId: String, name: String, vessels: [Vessel], methods: [CookingMethod],
                required: [Requirement], optional: [String] = [], forbidden: [String] = [], ratios: [RatioBand] = [],
                signature: SignatureEnvelope? = nil, palette: [String] = [], cardId: String, notes: String? = nil,
                brief: String? = nil) {
        self.id = id
        self.brief = brief
        self.cuisineId = cuisineId
        self.name = name
        self.vessels = vessels
        self.methods = methods
        self.required = required
        self.optional = optional
        self.forbidden = forbidden
        self.ratios = ratios
        self.signature = signature
        self.palette = palette
        self.cardId = cardId
        self.notes = notes
    }
}

/// What the player submitted.
public struct Attempt: Codable, Equatable, Sendable {
    public struct Line: Codable, Equatable, Sendable {
        public var ingredientId: String
        public var amount: Double
        public var unit: AmountUnit

        public init(ingredientId: String, amount: Double, unit: AmountUnit) {
            self.ingredientId = ingredientId
            self.amount = amount
            self.unit = unit
        }
    }

    public var dishId: String
    public var lines: [Line]
    public var vessel: Vessel
    /// Optional until the UX offers a method choice (see docs/decisions.md PD-007).
    public var method: CookingMethod?
    public var timestamp: Date?

    public init(dishId: String, lines: [Line], vessel: Vessel, method: CookingMethod? = nil, timestamp: Date? = nil) {
        self.dishId = dishId
        self.lines = lines
        self.vessel = vessel
        self.method = method
        self.timestamp = timestamp
    }
}

/// One specific thing that cost points. The judge (canned or LLM) turns these into a sentence.
public struct Miss: Codable, Equatable, Hashable, Sendable {
    public enum Kind: String, Codable, CaseIterable, Sendable {
        case missingRequired, partialRequired, wrongAmount
        case offCuisine, forbiddenForDish
        case ratioUndefined, ratioLow, ratioHigh
        case signatureLow, signatureHigh
        case wrongVessel, wrongMethod
        case unknownIngredient, unmeasurable
    }

    public var kind: Kind
    /// A requirement label, ratio label, ingredient id, axis name, vessel or method.
    public var subject: String

    public init(_ kind: Kind, _ subject: String) {
        self.kind = kind
        self.subject = subject
    }

    public var code: String { "\(kind.rawValue):\(subject)" }
}

public struct ScoreBreakdown: Codable, Equatable, Sendable {
    /// Out of 40: required families present, forbidden ones absent.
    public var coverage: Double
    /// Out of 35: key ratios inside their bands, with partial credit for near misses.
    public var ratioFit: Double
    /// Out of 15: heat, numbing, acid, umami and sweetness inside the dish's envelope.
    public var signature: Double
    /// Out of 10: vessel and method.
    public var technique: Double
    /// Out of 100, rounded from the unrounded parts.
    public var total: Int
    /// The attempt's measured flavour levels, 0 to 5 per axis. For the judge.
    public var levels: FlavorVector
    public var misses: [Miss]

    public init(coverage: Double, ratioFit: Double, signature: Double, technique: Double, total: Int,
                levels: FlavorVector, misses: [Miss]) {
        self.coverage = coverage
        self.ratioFit = ratioFit
        self.signature = signature
        self.technique = technique
        self.total = total
        self.levels = levels
        self.misses = misses
    }

    /// A stable key for caching judge feedback per (dish, score pattern): the score
    /// decile plus the sorted miss codes. Two attempts with the same pattern read the same.
    public var pattern: String {
        let codes = Set(misses.map(\.code)).sorted()
        return "t\(min(total, 99) / 10)|" + codes.joined(separator: ",")
    }
}
