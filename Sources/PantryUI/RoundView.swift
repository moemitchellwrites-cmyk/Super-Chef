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
    @State private var drag: Drag?
    @State private var wokFrame: CGRect = .zero
    @State private var debugTrace = "no drag"
    @State private var debugChanges = 0

    private static let space = "round"

    private struct Drag: Equatable {
        var ingredientId: String
        var location: CGPoint
    }

    init(model: RoundViewModel) {
        _model = State(initialValue: model)
    }

    private var round: Round { model.round }

    var body: some View {
        VStack(spacing: 8) {
            header
            wok
            methodRow
            stepperBar
            palette
            serveButton
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .coordinateSpace(name: Self.space)
        .overlay(alignment: .topLeading) { ghost }
        .overlay(alignment: .top) {
            if ProcessInfo.processInfo.arguments.contains("-pantryDebug") {
                Text("\(debugTrace) | changes \(debugChanges) | dragging \(drag == nil ? "no" : "yes")")
                    .font(.system(size: 9).monospaced())
                    .background(Color.yellow)
                    .accessibilityIdentifier("debug")
            }
        }
        .sheet(isPresented: Binding(get: { model.result != nil }, set: { if !$0 { model.dismissResult() } })) {
            if let result = model.result {
                ScoreSheet(dish: round.dish, breakdown: result) {
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

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                Text("\(model.library.cuisine.name) · Wok".uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                // Until the session loop (PB-005) deals the dishes, pick one here.
                Menu {
                    ForEach(model.library.dishes) { dish in
                        Button(dish.name) { model.start(dish) }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(round.dish.name)
                            .font(.title3.weight(.bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.bold))
                    }
                    .foregroundStyle(.primary)
                }
                .accessibilityIdentifier("dish-menu")
            }
            Spacer(minLength: 0)
            Button {
                model.startOver()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .frame(width: 36, height: 36)
            }
            .disabled(round.entries.isEmpty && round.method == nil)
            .accessibilityLabel("Start over")
            Button {
                model.toggleMute()
            } label: {
                Image(systemName: model.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .frame(width: 36, height: 36)
            }
            .accessibilityLabel(model.isMuted ? "Turn sound on" : "Turn sound off")
        }
    }

    // MARK: Wok

    private var wok: some View {
        SpriteView(scene: model.scene)
            .aspectRatio(WokScene.logicalSize.width / WokScene.logicalSize.height, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .background {
                GeometryReader { proxy in
                    Color.clear.preference(key: WokFrameKey.self, value: proxy.frame(in: .named(Self.space)))
                }
            }
            .onPreferenceChange(WokFrameKey.self) { wokFrame = $0 }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityElement()
            .accessibilityLabel(wokSummary)
            .accessibilityIdentifier("wok")
    }

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
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
            ForEach(round.methodChoices, id: \.self) { method in
                let chosen = round.method == method
                Button {
                    model.choose(method)
                } label: {
                    Text(method.title)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(Capsule().fill(chosen ? Color.orange : Color.gray.opacity(0.16)))
                        .foregroundStyle(chosen ? Color.white : Color.primary)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(chosen ? .isSelected : [])
                .accessibilityIdentifier("method-\(method.rawValue)")
            }
        }
    }

    // MARK: Stepper

    private var stepperBar: some View {
        Group {
            if let id = round.selectedId, let ingredient = round.ingredient(id), let ladder = round.ladder(for: id),
               let entry = round.entry(for: id) {
                let measure = ladder.measure(at: entry.stepIndex)
                VStack(spacing: 2) {
                    HStack(spacing: 8) {
                        Text(IngredientLook(for: ingredient).emoji)
                        Text(ingredient.name)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        Spacer(minLength: 4)
                        Text(measure.label)
                            .font(.headline.monospacedDigit())
                            .accessibilityIdentifier("amount")
                        Button(role: .destructive) {
                            model.removeSelected()
                        } label: {
                            Image(systemName: "trash")
                                .frame(width: 32, height: 32)
                        }
                        .accessibilityLabel("Take \(ingredient.chipName) out")
                    }
                    HStack(spacing: 10) {
                        Button {
                            model.stepSelected(by: -1)
                        } label: {
                            Image(systemName: "minus.circle.fill").font(.title)
                        }
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
                        .accessibilityLabel("Amount of \(ingredient.chipName)")
                        .accessibilityValue(measure.label)
                        Button {
                            model.stepSelected(by: 1)
                        } label: {
                            Image(systemName: "plus.circle.fill").font(.title)
                        }
                        .disabled(entry.stepIndex == ladder.steps.count - 1)
                        .accessibilityLabel("More")
                    }
                }
            } else {
                Text("Tap an ingredient, or drag it into the wok.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 76)
        .padding(.horizontal, 10)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.gray.opacity(0.10)))
    }

    // MARK: Palette

    private var palette: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
            ForEach(round.palette) { ingredient in
                PaletteChip(
                    ingredient: ingredient,
                    amount: round.measure(for: ingredient.id)?.label,
                    isSelected: round.selectedId == ingredient.id
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
                            debugChanges += 1
                        }
                        .onEnded { value in
                            let drop = CGPoint(x: value.location.x, y: value.location.y - 36)
                            debugTrace = "ended at \(Int(drop.x)),\(Int(drop.y)) wok \(Int(wokFrame.minX)),\(Int(wokFrame.minY)) \(Int(wokFrame.width))x\(Int(wokFrame.height))"
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

private struct WokFrameKey: PreferenceKey {
    static let defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

/// One ingredient on the palette. Shows its amount once it is in the wok.
private struct PaletteChip: View {
    let ingredient: Ingredient
    let amount: String?
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // The emoji rides on the first line so the second gets the chip's full width.
            Text("\(IngredientLook(for: ingredient).emoji) \(ingredient.chipName)")
                .font(.system(size: 11, weight: .medium))
                .lineLimit(2)
                .allowsTightening(true)
                .minimumScaleFactor(0.85)
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
        .frame(height: 44)
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
