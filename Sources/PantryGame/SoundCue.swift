import PantryScoring

/// Every sound the vessel scene makes. Each has a visual twin (brief:
/// "all sound cues must have a visual twin"), so the game reads the same muted.
public enum SoundCue: String, CaseIterable, Sendable {
    /// Fat and aromatics hitting a hot pan.
    case sizzle
    /// Liquids going in.
    case boil
    /// Wet, soft things: tofu, sauces from a bottle.
    case splash
    /// Dry goods dumped in.
    case clatter
    /// The burner catching when a cooking method is chosen.
    case flame

    /// The cue an ingredient's content names (`Ingredient.soundCue`). Unknown names
    /// fall back to `clatter`; `GameContentTests` fails if the bundled content relies on that.
    public init(contentCue: String) {
        self = SoundCue(rawValue: contentCue) ?? .clatter
    }

    public static func known(_ contentCue: String) -> Bool {
        SoundCue(rawValue: contentCue) != nil && contentCue != SoundCue.flame.rawValue
    }

    /// The comic-strip word shown in the scene when the cue plays.
    public var word: String {
        switch self {
        case .sizzle: return "Tssss!"
        case .boil: return "Blub blub"
        case .splash: return "Sploosh!"
        case .clatter: return "Clack!"
        case .flame: return "Fwoomp!"
        }
    }

    /// What the motion in the scene is, for the docs and for accessibility labels.
    public var twin: String {
        switch self {
        case .sizzle: return "sparks spit from the pan and steam puffs up"
        case .boil: return "bubbles rise and pop"
        case .splash: return "droplets arc out of the pan"
        case .clatter: return "the pan shakes and bits bounce"
        case .flame: return "the burner flares"
        }
    }
}

/// Placeholder art for an ingredient until PB-011: an emoji and a tint, keyed by
/// the content's `icon` name.
public struct IngredientLook: Equatable, Sendable {
    public let emoji: String
    public let red: Double
    public let green: Double
    public let blue: Double

    public static let fallback = IngredientLook(emoji: "🥄", red: 0.72, green: 0.72, blue: 0.72)

    public static let byIcon: [String: IngredientLook] = [
        "tofu": IngredientLook(emoji: "🧊", red: 0.96, green: 0.93, blue: 0.84),
        "meat": IngredientLook(emoji: "🥩", red: 0.80, green: 0.36, blue: 0.36),
        "fish": IngredientLook(emoji: "🐟", red: 0.55, green: 0.72, blue: 0.86),
        "jar": IngredientLook(emoji: "🫙", red: 0.66, green: 0.26, blue: 0.16),
        "spice": IngredientLook(emoji: "🧂", red: 0.86, green: 0.78, blue: 0.62),
        "chili": IngredientLook(emoji: "🌶️", red: 0.86, green: 0.18, blue: 0.14),
        "oil": IngredientLook(emoji: "🫗", red: 0.95, green: 0.78, blue: 0.25),
        "aromatic": IngredientLook(emoji: "🧄", red: 0.93, green: 0.90, blue: 0.78),
        "vegetable": IngredientLook(emoji: "🥬", red: 0.42, green: 0.70, blue: 0.36),
        "bottle": IngredientLook(emoji: "🍶", red: 0.35, green: 0.22, blue: 0.16),
        "nut": IngredientLook(emoji: "🥜", red: 0.78, green: 0.60, blue: 0.38),
        "liquid": IngredientLook(emoji: "💧", red: 0.50, green: 0.72, blue: 0.92),
        "noodle": IngredientLook(emoji: "🍜", red: 0.94, green: 0.84, blue: 0.56),
        "egg": IngredientLook(emoji: "🥚", red: 0.97, green: 0.94, blue: 0.86),
        "herb": IngredientLook(emoji: "🌿", red: 0.30, green: 0.62, blue: 0.32),
        "citrus": IngredientLook(emoji: "🍋", red: 0.96, green: 0.86, blue: 0.30),
        "dairy": IngredientLook(emoji: "🧀", red: 0.98, green: 0.84, blue: 0.40),
    ]

    public init(emoji: String, red: Double, green: Double, blue: Double) {
        self.emoji = emoji
        self.red = red
        self.green = green
        self.blue = blue
    }

    public init(for ingredient: Ingredient) {
        self = IngredientLook.byIcon[ingredient.icon] ?? .fallback
    }
}
