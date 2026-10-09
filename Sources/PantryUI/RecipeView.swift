#if canImport(SwiftUI) && canImport(SpriteKit)
import SwiftUI
import PantryScoring
import PantryGame

/// One way to cook the dish, opened from the score sheet (PD-029, PD-032). Never shown before a round is served.
struct RecipeView: View {
    let dish: DishProfile
    let recipe: Recipe
    let library: ContentLibrary
    let measures: MeasureSystem
    let onDone: () -> Void

    private struct Row: Identifiable {
        let id: Int
        let text: String
        let essential: Bool
    }

    private var rows: [Row] {
        let essentials = RecipeText.essentialIds(of: dish, in: library)
        return recipe.lines.enumerated().map { index, line in
            Row(id: index, text: RecipeText.line(line, in: library, system: measures), essential: essentials.contains(line.ingredientId))
        }
    }

    private var steps: [Row] {
        recipe.steps.enumerated().map { Row(id: $0.offset, text: $0.element, essential: false) }
    }

    private var summary: String {
        "Serves \(recipe.serves) · \(recipe.vessel == .wok ? "Wok" : "Pot") · \(recipe.method.title)"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(dish.name)
                            .font(.system(.title2, design: .rounded).weight(.semibold))
                            .accessibilityIdentifier("recipe-title")
                        Text(summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Done", action: onDone)
                        .accessibilityIdentifier("recipe-done")
                }
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(rows) { row in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Circle()
                                .fill(row.essential ? Color.orange : Color.clear)
                                .frame(width: 7, height: 7)
                            Text(row.text)
                                .font(.callout)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(row.essential ? "Essential: \(row.text)" : row.text)
                    }
                }
                HStack(spacing: 8) {
                    Circle().fill(Color.orange).frame(width: 7, height: 7)
                    Text("Marked: the essentials. The rest round the dish out.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(steps) { step in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("\(step.id + 1)")
                                .font(.callout.weight(.bold))
                                .foregroundStyle(.orange)
                                .frame(width: 16, alignment: .leading)
                            Text(step.text)
                                .font(.callout)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
    }
}
#endif
