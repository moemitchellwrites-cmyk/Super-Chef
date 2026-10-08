#if canImport(SwiftUI) && canImport(SpriteKit)
import SpriteKit
import SwiftUI
import PantryGame
import PantryScoring

/// One round at the vessel (PB-002): the wok, the cooking method, the amount stepper,
/// the ingredient palette and the serve button, laid out for one thumb in portrait.
///
/// The palette is SwiftUI and the wok is SpriteKit (PD-012). A chip is tapped to add it,
/// or dragged: the drag is tracked here and handed to the scene when it ends over the wok.
struct RoundView: View {
    @State private var model: RoundViewModel
    @Binding private var mode: GameMode
    private let onToggleMute: () -> Void
    @State private var drag: Drag?
    @State private var wokFrame: CGRect = .zero

    private static let space = "round"

    private struct Drag: Equatable {
        var ingredientId: String
        var location: CGPoint
    }

    init(model: RoundViewModel, mode: Binding<GameMode>, onToggleMute: @escaping () -> Void) {
        _model = State(initialValue: model)
        _mode = mode
        self.onToggleMute = onToggleMute
    }

    private var round: Round { model.round }

    /// Below this height (points, inside the safe area) the screen takes the small-phone layout.
    private static let compactBelow: CGFloat = 700

    var body: some View {
        GeometryReader { proxy in
            screen(compact: proxy.size.height < Self.compactBelow)
        }
    }

    /// Layout B (PD-031): the dish, its brief, the wok and the amount stepper share one panel;
    /// the six methods are one row under it.
    private func screen(compact: Bool) -> some View {
        VStack(spacing: 8) {
            RoundHeader(
                mode: $mode,
                canStartOver: !(round.entries.isEmpty && round.method == nil),
                isMuted: model.isMuted,
                onStartOver: { model.startOver() },
                onToggleMute: onToggleMute
            )
            panel(compact: compact)
            methodRow
            palette(compact: compact)
            serveButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .coordinateSpace(name: Self.space)
        .overlay(alignment: .topLeading) { ghost }
        .sheet(isPresented: Binding(get: { model.result != nil }, set: { if !$0 { model.dismissResult() } })) {
            if let result = model.result {
                ScoreSheet(dish: round.dish, breakdown: result, library: model.library) {
                    model.dismissResult()
                } onStartOver: {
                    model.startOver()
                }
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: model.impactCount)
        .onChange(of: isOverWok) { _, over in
            model.scene.setDropHighlight(over)
        }
        .onAppear { model.warmUp() }
    }

    // MARK: Panel

    private func panel(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: compact ? 3 : 5) {
            titleRow
            if let brief = round.dish.brief {
                Text(brief)
                    .font(.footnote)
                    .foregroundStyle(PanelInk.soft)
                    .lineLimit(compact ? 1 : 3)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("brief")
            }
            SpriteView(scene: model.scene, options: [.allowsTransparency])
                .aspectRatio(WokScene.logicalSize.width / WokScene.logicalSize.height, contentMode: .fit)
                // SpriteKit can draw a stray dark column on the view's last pixel (seen on an iPhone 16); trim the edge.
                .clipShape(Rectangle().inset(by: 1.5))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityElement()
                .accessibilityLabel(wokSummary)
                .accessibilityIdentifier("wok")
            stepperBar(compact: compact)
        }
        .padding(EdgeInsets(top: compact ? 10 : 12, leading: 14, bottom: compact ? 8 : 10, trailing: 14))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(PanelInk.panel))
        .background {
            // Where the panel sits in the round's coordinate space, so a drag knows when it is over it.
            GeometryReader { proxy in
                let frame = proxy.frame(in: .named(Self.space))
                Color.clear
                    .onAppear { wokFrame = frame }
                    .onChange(of: frame) { _, moved in wokFrame = moved }
            }
        }
    }

    private var titleRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            // Until the session loop (PB-005) deals the dishes, pick one here.
            Menu {
                ForEach(model.library.dishes) { dish in
                    Button(dish.name) { model.start(dish) }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(round.dish.name)
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(PanelInk.chili)
            }
            .accessibilityIdentifier("dish-menu")
            Text("\(model.library.cuisine.name) · Wok".uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(PanelInk.soft)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
    }

    // MARK: Wok

    private var wokSummary: String {
        if round.entries.isEmpty { return "Wok, empty" }
        let contents = round.entries.compactMap { entry -> String? in
            guard let ingredient = round.ingredient(entry.ingredientId), let measure = round.measure(for: entry.ingredientId) else { return nil }
            return "\(measure.label) \(ingredient.chipName)"
        }
        return "Wok with " + contents.joined(separator: ", ")
    }

    private var isOverWok: Bool {
        guard let drag else { return false }
        return wokFrame.contains(drag.location)
    }

    @ViewBuilder
    private var ghost: some View {
        if let drag, let ingredient = round.ingredient(drag.ingredientId) {
            Text(IngredientLook(for: ingredient).emoji)
                .font(.system(size: 44))
                .scaleEffect(isOverWok ? 1.25 : 1)
                .shadow(radius: 4, y: 2)
                .position(drag.location)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    // MARK: Method

    private var methodRow: some View {
        HStack(spacing: 4) {
            ForEach(round.methodChoices, id: \.self) { method in
                let chosen = round.method == method
                Button {
                    model.choose(method)
                } label: {
                    Text(method.title)
                        .font(.system(size: 12, weight: chosen ? .bold : .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(chosen ? Color.orange : Color.gray.opacity(0.16)))
                        .foregroundStyle(chosen ? Color.white : Color.primary)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(chosen ? .isSelected : [])
                .accessibilityIdentifier("method-\(method.rawValue)")
            }
        }
    }

    // MARK: Stepper

    /// The amount of the selected ingredient, inside the wok's panel. Two rows on a regular phone,
    /// one on a small one, where take-out is a cross (the one place it has no words, for width).
    private func stepperBar(compact: Bool) -> some View {
        Group {
            if let id = round.selectedId, let ingredient = round.ingredient(id), let ladder = round.ladder(for: id),
               let entry = round.entry(for: id) {
                let measure = ladder.measure(at: entry.stepIndex)
                if compact {
                    VStack(alignment: .leading, spacing: 0) {
                        stepperName(ingredient, size: 11, short: false)
                        HStack(spacing: 6) {
                            stepperControls(ingredient: ingredient, ladder: ladder, entry: entry, measure: measure)
                            amountText(measure, size: 16)
                                .frame(width: 62, alignment: .trailing)
                            Button {
                                model.removeSelected()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .frame(width: 36, height: 36)
                                    .background(Circle().fill(Color.white.opacity(0.7)))
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(PanelInk.chili)
                            .accessibilityLabel("Take \(ingredient.chipName) out")
                        }
                    }
                } else {
                    VStack(spacing: 4) {
                        HStack(spacing: 8) {
                            stepperName(ingredient, size: 13, short: true)
                            Spacer(minLength: 4)
                            amountText(measure, size: 18)
                            Button {
                                model.removeSelected()
                            } label: {
                                Text("Take out")
                                    .font(.system(size: 12, weight: .bold))
                                    .padding(.horizontal, 10)
                                    .frame(height: 32)
                                    .background(Capsule().fill(Color.white.opacity(0.7)))
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(PanelInk.chili)
                            .accessibilityLabel("Take \(ingredient.chipName) out")
                        }
                        HStack(spacing: 10) {
                            stepperControls(ingredient: ingredient, ladder: ladder, entry: entry, measure: measure)
                        }
                    }
                }
            } else {
                Text("Tap an ingredient, or drag it into the wok.")
                    .font(.footnote)
                    .foregroundStyle(PanelInk.soft)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, compact ? 6 : 10)
        .frame(maxWidth: .infinity)
        .frame(height: compact ? 58 : 84)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.55)))
    }

    /// The short name where the amount and "Take out" share its row; the full one where it has a row to itself.
    private func stepperName(_ ingredient: Ingredient, size: CGFloat, short: Bool) -> some View {
        Text("\(IngredientLook(for: ingredient).emoji) \(short ? ingredient.chipName : ingredient.name)")
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(PanelInk.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }

    private func amountText(_ measure: Measure, size: CGFloat) -> some View {
        Text(measure.label)
            .font(.system(size: size, weight: .semibold, design: .rounded).monospacedDigit())
            .foregroundStyle(PanelInk.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .accessibilityIdentifier("amount")
    }

    /// Less, the slider, more. The caller lays them out in a row.
    @ViewBuilder
    private func stepperControls(ingredient: Ingredient, ladder: AmountLadder, entry: Round.Entry, measure: Measure) -> some View {
        Button {
            model.stepSelected(by: -1)
        } label: {
            Image(systemName: "minus.circle.fill").font(.system(size: 34))
        }
        .buttonStyle(.plain)
        .foregroundStyle(PanelInk.chili)
        .opacity(entry.stepIndex == 0 ? 0.35 : 1)
        .disabled(entry.stepIndex == 0)
        .accessibilityLabel("Less")
        Slider(
            value: Binding(
                get: { Double(entry.stepIndex) },
                set: { model.setSelectedStep(Int($0.rounded())) }
            ),
            in: 0...Double(ladder.steps.count - 1),
            step: 1
        )
        .tint(PanelInk.chili)
        .accessibilityLabel("Amount of \(ingredient.chipName)")
        .accessibilityValue(measure.label)
        Button {
            model.stepSelected(by: 1)
        } label: {
            Image(systemName: "plus.circle.fill").font(.system(size: 34))
        }
        .buttonStyle(.plain)
        .foregroundStyle(PanelInk.chili)
        .opacity(entry.stepIndex == ladder.steps.count - 1 ? 0.35 : 1)
        .disabled(entry.stepIndex == ladder.steps.count - 1)
        .accessibilityLabel("More")
    }

    // MARK: Palette

    private func palette(compact: Bool) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
            ForEach(round.palette) { ingredient in
                PaletteChip(
                    ingredient: ingredient,
                    amount: round.measure(for: ingredient.id)?.label,
                    isSelected: round.selectedId == ingredient.id,
                    height: compact ? 46 : 50
                )
                .opacity(drag?.ingredientId == ingredient.id ? 0.35 : 1)
                .onTapGesture {
                    model.add(ingredient.id)
                }
                .gesture(
                    DragGesture(minimumDistance: 10, coordinateSpace: .named(Self.space))
                        .onChanged { value in
                            // Hold the ghost a little above the finger so the thumb doesn't cover it.
                            drag = Drag(ingredientId: ingredient.id,
                                        location: CGPoint(x: value.location.x, y: value.location.y - 36))
                        }
                        .onEnded { value in
                            let drop = CGPoint(x: value.location.x, y: value.location.y - 36)
                            if wokFrame.width > 0, wokFrame.contains(drop) {
                                model.add(ingredient.id, atFraction: Double((drop.x - wokFrame.minX) / wokFrame.width))
                            }
                            drag = nil
                        }
                )
            }
        }
    }

    // MARK: Serve

    private var serveButton: some View {
        Button {
            model.serve()
        } label: {
            Text(round.servePrompt ?? "Serve it")
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(.orange)
        .disabled(!round.canServe)
        .accessibilityIdentifier("serve")
    }
}

/// One ingredient on the palette. Shows its amount once it is in the wok.
private struct PaletteChip: View {
    let ingredient: Ingredient
    let amount: String?
    let isSelected: Bool
    let height: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // The emoji rides on the first line so the second gets the chip's full width.
            Text("\(IngredientLook(for: ingredient).emoji) \(ingredient.chipName)")
                .font(.system(size: 11, weight: .medium))
                .lineLimit(2)
                .allowsTightening(true)
                .minimumScaleFactor(0.75)
                .multilineTextAlignment(.leading)
            if let amount {
                Text(amount)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.orange)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: height)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(amount == nil ? Color.gray.opacity(0.14) : Color.orange.opacity(0.16))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(isSelected ? Color.orange : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(amount.map { "\(ingredient.name), \($0) in the wok" } ?? ingredient.name)
        .accessibilityHint(amount == nil ? "Adds it to the wok" : "Selects it to change the amount")
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("chip-\(ingredient.id)")
    }
}
#endif
