#if canImport(SwiftUI) && canImport(SpriteKit)
import SwiftUI
import PantryGame
import PantryScoring

/// The score for a served Kitchen attempt: the number, the judge's one line (PB-003) and the four parts.
/// then the card (PB-004) and the way to the recipe.
struct ScoreSheet: View {
    let dish: DishProfile
    let breakdown: ScoreBreakdown
    let library: ContentLibrary
    let measures: MeasureSystem
    /// What the forward button says: "Next dish", or "Finish" on the last round of a session.
    let nextTitle: String
    /// Set on a second go at the same dish: which result the session keeps.
    let countedNote: String?
    let onKeepCooking: () -> Void
    let onNext: () -> Void

    private struct Part: Identifiable {
        let name: String
        let earned: Double
        let possible: Double
        var id: String { name }
    }

    private var parts: [Part] {
        [
            Part(name: "Ingredients", earned: breakdown.coverage, possible: ScoreWeights.coverage),
            Part(name: "Ratios", earned: breakdown.ratioFit, possible: ScoreWeights.ratioFit),
            Part(name: "Flavour", earned: breakdown.signature, possible: ScoreWeights.signature),
            Part(name: "Technique", earned: breakdown.technique, possible: ScoreWeights.technique),
        ]
    }

    @State private var showingRecipe = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Text(dish.name)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("\(breakdown.total)")
                    .font(.system(size: 76, weight: .heavy, design: .rounded))
                    .accessibilityIdentifier("score-total")
                    .accessibilityLabel("\(breakdown.total) out of 100")
                // The judge's one line (PB-003): the single thing most worth fixing.
                Text(JudgeLine.kitchen(breakdown, dish: dish, library: library))
                    .font(.system(.title3, design: .rounded).weight(.medium))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("judge-line")
                if let ceiling = breakdown.cappedAt {
                    Text("Held at \(ceiling): something in the wok doesn't belong, and the more of the dish it is, the lower the ceiling. The parts below add up to more.")
                        .font(.footnote)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.orange.opacity(0.16)))
                        .accessibilityIdentifier("score-capped")
                }
                VStack(spacing: 8) {
                    ForEach(parts) { part in
                        HStack(spacing: 10) {
                            Text(part.name)
                                .font(.subheadline)
                                .frame(width: 92, alignment: .leading)
                            ProgressView(value: min(max(part.earned, 0), part.possible), total: part.possible)
                                .tint(.orange)
                            Text("\(part.earned.formatted(.number.precision(.fractionLength(0...1)))) / \(Int(part.possible))")
                                .font(.subheadline.monospacedDigit())
                                .frame(width: 74, alignment: .trailing)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                if let card = library.card(for: dish) {
                    CardView(card: card)
                }
                // The recipe is one tap away, so the sheet stays one screen (PD-032).
                if dish.recipe != nil {
                    Button("See the recipe") { showingRecipe = true }
                        .buttonStyle(.bordered)
                        .tint(.orange)
                        .controlSize(.large)
                        .accessibilityIdentifier("see-recipe")
                }
                if let countedNote {
                    Text(countedNote)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("counted-note")
                }
                HStack(spacing: 10) {
                    Button("Keep cooking", action: onKeepCooking)
                        .buttonStyle(.bordered)
                    Button(nextTitle, action: onNext)
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        .accessibilityIdentifier("next")
                }
                .controlSize(.large)
            }
            .padding(20)
        }
        .presentationDetents([.medium, .large])
        .sheet(isPresented: $showingRecipe) {
            if let recipe = dish.recipe {
                RecipeView(dish: dish, recipe: recipe, library: library, measures: measures) { showingRecipe = false }
            }
        }
    }
}
#endif
