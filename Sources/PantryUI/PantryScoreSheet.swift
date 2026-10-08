#if canImport(SwiftUI) && canImport(SpriteKit)
import SwiftUI
import PantryGame
import PantryScoring

/// The verdict on a Pantry round (PD-025): a count, and a name for everything behind it.
/// The recipe is one tap away (PD-032).
struct PantryScoreSheet: View {
    let dish: DishProfile
    let result: PantryResult
    let library: ContentLibrary
    let onKeepCooking: () -> Void
    let onStartOver: () -> Void

    @State private var showingRecipe = false

    private func names(_ ids: [String]) -> [String] {
        ids.map { library.ingredient(id: $0)?.chipName ?? $0 }
    }

    private var missed: [String] {
        result.missed.map { $0.prefix(1).uppercased() + $0.dropFirst() }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Text(dish.name)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("\(result.found.count)")
                    .font(.system(size: 76, weight: .heavy, design: .rounded))
                    .accessibilityIdentifier("score-total")
                    .accessibilityLabel("\(result.found.count) of \(result.essentials) essentials found")
                Text("of \(result.essentials) essentials found")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                if result.isClean {
                    Text("Clean: every essential, and nothing that doesn't belong.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.green)
                }
                if !result.wrong.isEmpty {
                    TagGroup(title: "Doesn't belong", items: names(result.wrong), tint: .red, note: nil)
                }
                if !missed.isEmpty {
                    TagGroup(title: "Missed", items: missed, tint: .red, note: nil)
                }
                if !result.found.isEmpty {
                    TagGroup(title: "Found", items: names(result.found), tint: .green, note: nil)
                }
                if !result.alsoBelongs.isEmpty {
                    // Moe read this group as "incorrect" when it had a neutral title, so it says what it is.
                    TagGroup(
                        title: "Not wrong, just not essential",
                        items: names(result.alsoBelongs),
                        tint: .gray,
                        note: "These belong in the dish and may be in the recipe. This round only counts the \(result.essentials) things the dish can't be without."
                    )
                }
                if dish.recipe != nil {
                    Button("See the recipe") { showingRecipe = true }
                        .buttonStyle(.bordered)
                        .tint(.orange)
                        .controlSize(.large)
                        .accessibilityIdentifier("see-recipe")
                }
                HStack(spacing: 10) {
                    Button("Keep cooking", action: onKeepCooking)
                        .buttonStyle(.bordered)
                    Button("Start over", action: onStartOver)
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                }
                .controlSize(.large)
            }
            .padding(20)
        }
        .presentationDetents([.medium, .large])
        .sheet(isPresented: $showingRecipe) {
            if let recipe = dish.recipe {
                RecipeView(dish: dish, recipe: recipe, library: library) { showingRecipe = false }
            }
        }
    }
}

/// A titled set of tags. Each item is its own tag: a comma-joined line can't tell
/// "garlic, ginger and scallion" (one thing) from three.
private struct TagGroup: View {
    let title: String
    let items: [String]
    let tint: Color
    let note: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint == .gray ? Color.secondary : tint)
            TagFlow(spacing: 6) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.subheadline)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(tint.opacity(0.16)))
                }
            }
            if let note {
                Text(note)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// Lays tags out left to right, wrapping to a new row when the next one doesn't fit.
private struct TagFlow: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var widest: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            widest = max(widest, x - spacing)
        }
        return CGSize(width: proposal.width ?? widest, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
#endif
