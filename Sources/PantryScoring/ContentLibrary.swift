import Foundation

public enum ContentError: Error, Equatable {
    case missingResource(String)
    case unknownDish(String)
}

/// A cuisine's bundled content: the cuisine, its ingredients and its dish profiles,
/// loaded from `Resources/<cuisineId>/` and checked for internal consistency.
public struct ContentLibrary: Sendable {
    public let cuisine: Cuisine
    public let ingredients: [Ingredient]
    public let dishes: [DishProfile]
    public let cards: [Card]

    public init(cuisine: Cuisine, ingredients: [Ingredient], dishes: [DishProfile], cards: [Card] = []) {
        self.cuisine = cuisine
        self.ingredients = ingredients
        self.dishes = dishes
        self.cards = cards
    }

    struct CardsFile: Codable {
        var schemaVersion: Int
        var cards: [Card]
    }

    struct IngredientsFile: Codable {
        var schemaVersion: Int
        var ingredients: [Ingredient]
    }

    struct DishesFile: Codable {
        var schemaVersion: Int
        var dishes: [DishProfile]
    }

    /// Loads a cuisine shipped inside this package.
    public static func bundled(cuisineId: String = "sichuan") throws -> ContentLibrary {
        try load(cuisineId: cuisineId, from: .module)
    }

    static func load(cuisineId: String, from bundle: Bundle) throws -> ContentLibrary {
        func data(_ name: String) throws -> Data {
            guard let url = bundle.url(forResource: name, withExtension: "json", subdirectory: cuisineId) else {
                throw ContentError.missingResource("\(cuisineId)/\(name).json")
            }
            return try Data(contentsOf: url)
        }
        let decoder = JSONDecoder()
        let cuisine = try decoder.decode(Cuisine.self, from: data("cuisine"))
        let ingredients = try decoder.decode(IngredientsFile.self, from: data("ingredients")).ingredients
        let dishes = try decoder.decode(DishesFile.self, from: data("dishes")).dishes
        let cards = try decoder.decode(CardsFile.self, from: data("cards")).cards
        return ContentLibrary(cuisine: cuisine, ingredients: ingredients, dishes: dishes, cards: cards)
    }

    /// The longest label a palette chip can show on two lines.
    public static let shortNameLimit = 22

    /// The longest ingredient note: three short lines on a phone.
    public static let aboutLimit = 110

    /// The longest recipe step: about three lines on a phone.
    public static let recipeStepLimit = 190

    /// The longest dish brief: two lines under the dish name on a phone.
    public static let briefLimit = 120

    public func dish(id: String) -> DishProfile? {
        dishes.first { $0.id == id }
    }

    public func ingredient(id: String) -> Ingredient? {
        ingredients.first { $0.id == id }
    }

    public func card(id: String) -> Card? {
        cards.first { $0.id == id }
    }

    /// The card a round of this dish ends on.
    public func card(for dish: DishProfile) -> Card? {
        card(id: dish.cardId)
    }

    /// A card must stay under this many words (brief: "under 60 words").
    public static let cardWordLimit = 60

    public var scorer: Scorer {
        Scorer(cuisine: cuisine, ingredients: ingredients)
    }

    /// Scores an attempt against the dish it names.
    public func score(_ attempt: Attempt) throws -> ScoreBreakdown {
        guard let dish = dish(id: attempt.dishId) else { throw ContentError.unknownDish(attempt.dishId) }
        return scorer.score(attempt, against: dish)
    }

    /// Checks that every reference resolves and every profile is playable.
    /// Returns one line per problem; empty means the content is sound.
    public func validate() -> [String] {
        var problems: [String] = []
        if Set(cards.map(\.id)).count != cards.count {
            problems.append("duplicate card ids")
        }
        for card in cards {
            if card.wordCount >= ContentLibrary.cardWordLimit {
                problems.append("\(card.id): \(card.wordCount) words, want under \(ContentLibrary.cardWordLimit)")
            }
            if card.title.isEmpty || card.rule.isEmpty || card.tryTonight.isEmpty {
                problems.append("\(card.id): needs a title, a rule and something to try tonight")
            }
            let sentences = card.body.split(whereSeparator: { ".!?".contains($0) }).filter { !$0.allSatisfy(\.isWhitespace) }.count
            if !(2...4).contains(sentences) {
                problems.append("\(card.id): body has \(sentences) sentences, want two to four")
            }
            if !dishes.contains(where: { $0.cardId == card.id }) {
                problems.append("\(card.id): no dish uses this card")
            }
        }
        let ingredientIds = Set(ingredients.map(\.id))
        let families = Set(ingredients.map(\.family))
        let offCuisine = Set(cuisine.offCuisineFamilies)

        if ingredientIds.count != ingredients.count {
            problems.append("duplicate ingredient ids")
        }
        for ingredient in ingredients {
            if ingredient.defaultUnit != .grams && ingredient.gramsPerTeaspoon == nil {
                problems.append("\(ingredient.id): default unit is volume but no gramsPerTeaspoon")
            }
            if let perTeaspoon = ingredient.gramsPerTeaspoon, perTeaspoon <= 0 {
                problems.append("\(ingredient.id): gramsPerTeaspoon must be positive")
            }
            if let shortName = ingredient.shortName, shortName.isEmpty || shortName.count > ContentLibrary.shortNameLimit {
                problems.append("\(ingredient.id): shortName must be 1 to \(ContentLibrary.shortNameLimit) characters")
            }
            if ingredient.shortName == nil && ingredient.name.count > ContentLibrary.shortNameLimit {
                problems.append("\(ingredient.id): name is over \(ContentLibrary.shortNameLimit) characters and has no shortName")
            }
            let about = ingredient.about ?? ""
            if about.isEmpty {
                problems.append("\(ingredient.id): no about line")
            } else if about.count > ContentLibrary.aboutLimit {
                problems.append("\(ingredient.id): about line is over \(ContentLibrary.aboutLimit) characters")
            }
            for axis in FlavorAxis.allCases where ingredient.potency[axis] < 0 {
                problems.append("\(ingredient.id): negative potency on \(axis.rawValue)")
            }
        }
        for family in offCuisine where !families.contains(family) {
            problems.append("cuisine off-cuisine family \(family) has no ingredient")
        }

        var dishIds = Set<String>()
        for dish in dishes {
            let tag = dish.id
            if !dishIds.insert(dish.id).inserted { problems.append("\(tag): duplicate dish id") }
            if dish.cuisineId != cuisine.id { problems.append("\(tag): cuisineId \(dish.cuisineId) is not \(cuisine.id)") }
            if dish.vessels.isEmpty { problems.append("\(tag): no vessels") }
            if dish.methods.isEmpty { problems.append("\(tag): no methods") }
            if dish.required.isEmpty { problems.append("\(tag): no required families") }

            let paletteFamilies = Set(dish.palette.compactMap { id in ingredients.first { $0.id == id }?.family })
            if !(12...20).contains(Set(dish.palette).count) {
                problems.append("\(tag): palette has \(Set(dish.palette).count) ingredients, want 12 to 20")
            }
            for id in dish.palette where !ingredientIds.contains(id) {
                problems.append("\(tag): palette ingredient \(id) does not exist")
            }
            let decoys = paletteFamilies.filter { offCuisine.contains($0) || dish.forbidden.contains($0) }
            if decoys.count < 2 { problems.append("\(tag): palette needs at least two decoys") }

            let forbidden = Set(dish.forbidden)
            for requirement in dish.required {
                if requirement.weight <= 0 { problems.append("\(tag): requirement \(requirement.label) has no weight") }
                if requirement.minPresent < 1 || requirement.minPresent > requirement.anyOf.count {
                    problems.append("\(tag): requirement \(requirement.label) minPresent out of range")
                }
                for family in requirement.anyOf {
                    if !families.contains(family) { problems.append("\(tag): required family \(family) has no ingredient") }
                    if forbidden.contains(family) { problems.append("\(tag): \(family) is both required and forbidden") }
                    if offCuisine.contains(family) { problems.append("\(tag): required family \(family) is off-cuisine") }
                }
                if !requirement.anyOf.contains(where: paletteFamilies.contains) {
                    problems.append("\(tag): palette cannot satisfy \(requirement.label)")
                }
            }
            for family in dish.optional {
                if !families.contains(family) { problems.append("\(tag): optional family \(family) has no ingredient") }
                if forbidden.contains(family) { problems.append("\(tag): \(family) is both optional and forbidden") }
            }
            for family in dish.forbidden where !families.contains(family) {
                problems.append("\(tag): forbidden family \(family) has no ingredient")
            }
            for band in dish.ratios {
                if !(band.low > 0 && band.low < band.high) { problems.append("\(tag): ratio \(band.label) band is not 0 < low < high") }
                if band.weight <= 0 { problems.append("\(tag): ratio \(band.label) has no weight") }
                for family in band.numerator + band.denominator where !families.contains(family) {
                    problems.append("\(tag): ratio \(band.label) names unknown family \(family)")
                }
                if !band.numerator.contains(where: paletteFamilies.contains)
                    || !band.denominator.contains(where: paletteFamilies.contains) {
                    problems.append("\(tag): ratio \(band.label) cannot be built from the palette")
                }
            }
            if let envelope = dish.signature {
                for axis in FlavorAxis.allCases {
                    let band = envelope[axis]
                    if !(band.low >= 0 && band.low <= band.high && band.high <= ScoreWeights.maxLevel) {
                        problems.append("\(tag): signature \(axis.rawValue) band is not within 0...5")
                    }
                }
            }
            let brief = dish.brief ?? ""
            if brief.isEmpty {
                problems.append("\(tag): no brief")
            } else if brief.count > ContentLibrary.briefLimit {
                problems.append("\(tag): brief is over \(ContentLibrary.briefLimit) characters")
            }
            if brief.contains(where: \.isNumber) { problems.append("\(tag): brief gives a number") }
            if let recipe = dish.recipe {
                if recipe.serves < 1 { problems.append("\(tag): recipe serves nobody") }
                if !(3...7).contains(recipe.steps.count) { problems.append("\(tag): recipe has \(recipe.steps.count) steps, want 3 to 7") }
                for step in recipe.steps where step.isEmpty || step.count > ContentLibrary.recipeStepLimit {
                    problems.append("\(tag): a recipe step is empty or over \(ContentLibrary.recipeStepLimit) characters")
                }
                for line in recipe.lines where !dish.palette.contains(line.ingredientId) {
                    problems.append("\(tag): recipe uses \(line.ingredientId), which is not on the palette")
                }
                // The recipe is the answer the game teaches toward, so it must be a good attempt at its own dish.
                let breakdown = scorer.score(recipe.attempt(dishId: dish.id), against: dish)
                if breakdown.total < 85 || !breakdown.misses.isEmpty {
                    problems.append("\(tag): its own recipe scores \(breakdown.total) with misses \(breakdown.misses.map(\.code))")
                }
            } else {
                problems.append("\(tag): no recipe")
            }
            if dish.cardId.isEmpty {
                problems.append("\(tag): no cardId")
            } else if card(id: dish.cardId) == nil {
                problems.append("\(tag): card \(dish.cardId) is not in cards.json")
            }
            if (dish.notes ?? "").isEmpty { problems.append("\(tag): no source notes") }
        }
        return problems
    }
}
