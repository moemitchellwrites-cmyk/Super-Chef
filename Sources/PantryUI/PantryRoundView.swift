#if canImport(SwiftUI) && canImport(SpriteKit)
import SpriteKit
import SwiftUI
import PantryGame
import PantryScoring

/// A Pantry round (PD-025), laid out per PD-031: the dish, its brief and the ask sit in the wok's
/// panel. On a regular phone the picks are dots and the ingredient note floats over the panel; on a
/// short one the note is a strip under the panel and the count rides on the serve button.
struct PantryRoundView: View {
    @State private var model: PantryRoundViewModel
    @Binding private var mode: GameMode
    private let isMuted: Bool
    private let onToggleMute: () -> Void

    @State private var drag: Drag?
    @State private var panelFrame: CGRect = .zero
    @State private var noteId: String?
    @State private var noteToken = 0

    private static let space = "pantry-round"
    /// Below this height (points, inside the safe area) the screen takes the small-phone layout.
    private static let compactBelow: CGFloat = 700

    private struct Drag: Equatable {
        var ingredientId: String
        var location: CGPoint
    }

    init(model: PantryRoundViewModel, mode: Binding<GameMode>, isMuted: Bool, onToggleMute: @escaping () -> Void) {
        _model = State(initialValue: model)
        _mode = mode
        self.isMuted = isMuted
        self.onToggleMute = onToggleMute
    }

    private var round: PantryRound { model.round }

    var body: some View {
        GeometryReader { proxy in
            screen(compact: proxy.size.height < Self.compactBelow)
        }
    }

    private func screen(compact: Bool) -> some View {
        VStack(spacing: 8) {
            RoundHeader(
                mode: $mode,
                canStartOver: !round.picks.isEmpty,
                isMuted: isMuted,
                onStartOver: { model.startOver() },
                onToggleMute: onToggleMute
            )
            panel(compact: compact)
            if compact {
                noteStrip
            }
            palette(compact: compact)
            serveButton(compact: compact)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .coordinateSpace(name: Self.space)
        .overlay(alignment: .topLeading) { ghost }
        .sheet(isPresented: Binding(get: { model.result != nil }, set: { if !$0 { model.dismissResult() } })) {
            if let result = model.result {
                PantryScoreSheet(dish: round.dish, result: result, library: model.library) {
                    model.dismissResult()
                } onStartOver: {
                    model.startOver()
                }
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: model.impactCount)
        .sensoryFeedback(.warning, trigger: model.fullCount)
        .onChange(of: isOverPanel) { _, over in
            model.scene.setDropHighlight(over)
        }
        .onAppear { model.warmUp() }
    }

    // MARK: Panel

    private func panel(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            titleRow
            if let brief = round.dish.brief {
                Text(brief)
                    .font(.footnote)
                    .foregroundStyle(PanelInk.soft)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("brief")
            }
            askRow(compact: compact)
            SpriteView(scene: model.scene, options: [.allowsTransparency])
                .aspectRatio(WokScene.logicalSize.width / WokScene.logicalSize.height, contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityElement()
                .accessibilityLabel(wokSummary)
                .accessibilityIdentifier("wok")
        }
        .padding(EdgeInsets(top: 12, leading: 14, bottom: 10, trailing: 14))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(PanelInk.panel))
        .background {
            // Where the panel sits in the round's coordinate space, so a drag knows when it is over it.
            GeometryReader { proxy in
                let frame = proxy.frame(in: .named(Self.space))
                Color.clear
                    .onAppear { panelFrame = frame }
                    .onChange(of: frame) { _, moved in panelFrame = moved }
            }
        }
        .overlay(alignment: .bottom) {
            if !compact, let noted = notedIngredient {
                noteText(for: noted)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(PanelInk.ink))
                    .shadow(color: Color.black.opacity(0.25), radius: 8, y: 4)
                    .padding(10)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
    }

    private var titleRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            // Until the session loop (PB-005) deals the dishes, pick one here.
            Menu {
                ForEach(model.library.dishes) { dish in
                    Button(dish.name) {
                        noteId = nil
                        model.start(dish)
                    }
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
            Text(model.library.cuisine.name.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(PanelInk.soft)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
    }

    private func askRow(compact: Bool) -> some View {
        HStack(spacing: 10) {
            Text(compact ? round.ask + " this dish can't be without." : round.ask)
                .font(.footnote.weight(.bold))
                .foregroundStyle(PanelInk.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("ask")
            Spacer(minLength: 0)
            if !compact {
                dots
            }
        }
        .padding(.top, 2)
    }

    private var dots: some View {
        HStack(spacing: 5) {
            ForEach(0..<round.pickLimit, id: \.self) { index in
                let filled = index < round.picks.count
                Circle()
                    .fill(filled ? PanelInk.chili : Color.clear)
                    .overlay(Circle().strokeBorder(filled ? PanelInk.chili : PanelInk.soft, lineWidth: 2))
                    .frame(width: 16, height: 16)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(round.countLabel) picked")
        .accessibilityIdentifier("picks")
    }

    private var wokSummary: String {
        if round.picks.isEmpty { return "Wok, empty" }
        let names = round.picks.compactMap { round.ingredient($0)?.chipName }
        return "Wok with " + names.joined(separator: ", ")
    }

    // MARK: Ingredient note (PD-028)

    private var notedIngredient: Ingredient? {
        noteId.flatMap { round.ingredient($0) }
    }

    private func noteText(for ingredient: Ingredient) -> some View {
        Text("\(Text(ingredient.chipName + ".").bold()) \(ingredient.about ?? "")")
            .font(.footnote)
            .accessibilityIdentifier("note")
    }

    /// Small phones: the note has its own strip, so it never covers the wok.
    private var noteStrip: some View {
        Group {
            if let noted = notedIngredient {
                noteText(for: noted)
                    .foregroundStyle(Color.primary)
            } else {
                Text("Touch an ingredient to read what it is. Hold it to read without adding it.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .lineLimit(3)
        .minimumScaleFactor(0.85)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .frame(height: 50)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.gray.opacity(0.14)))
    }

    /// Shows what an ingredient is. On a regular phone the note leaves after a few seconds;
    /// on a small one it stays in its strip until the next one.
    private func showNote(_ id: String, compact: Bool) {
        noteId = id
        noteToken += 1
        guard !compact else { return }
        let token = noteToken
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(4))
            if noteToken == token {
                noteId = nil
            }
        }
    }

    // MARK: Drag

    private var isOverPanel: Bool {
        guard let drag else { return false }
        return panelFrame.contains(drag.location)
    }

    @ViewBuilder
    private var ghost: some View {
        if let drag, let ingredient = round.ingredient(drag.ingredientId) {
            Text(IngredientLook(for: ingredient).emoji)
                .font(.system(size: 44))
                .scaleEffect(isOverPanel ? 1.25 : 1)
                .shadow(radius: 4, y: 2)
                .position(drag.location)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    // MARK: Palette

    private func palette(compact: Bool) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
            ForEach(round.palette) { ingredient in
                PantryChip(
                    ingredient: ingredient,
                    isPicked: round.contains(ingredient.id),
                    isNoted: noteId == ingredient.id,
                    height: compact ? 46 : 50
                )
                .opacity(drag?.ingredientId == ingredient.id ? 0.35 : 1)
                .onTapGesture {
                    showNote(ingredient.id, compact: compact)
                    model.toggle(ingredient.id)
                }
                .onLongPressGesture(minimumDuration: 0.4) {
                    // Hold to read without adding.
                    showNote(ingredient.id, compact: compact)
                }
                .gesture(
                    DragGesture(minimumDistance: 10, coordinateSpace: .named(Self.space))
                        .onChanged { value in
                            if drag == nil {
                                showNote(ingredient.id, compact: compact)
                            }
                            // Hold the ghost a little above the finger so the thumb doesn't cover it.
                            drag = Drag(ingredientId: ingredient.id,
                                        location: CGPoint(x: value.location.x, y: value.location.y - 36))
                        }
                        .onEnded { value in
                            let drop = CGPoint(x: value.location.x, y: value.location.y - 36)
                            if panelFrame.width > 0, panelFrame.contains(drop) {
                                model.drop(ingredient.id, atFraction: Double((drop.x - panelFrame.minX) / panelFrame.width))
                            }
                            drag = nil
                        }
                )
            }
        }
    }

    // MARK: Serve

    private func serveButton(compact: Bool) -> some View {
        Button {
            model.serve()
        } label: {
            HStack(spacing: 12) {
                Text(round.servePrompt ?? "Serve it")
                    .font(.headline)
                if compact, round.canServe {
                    Text(round.countLabel)
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.black.opacity(0.22)))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(.orange)
        .disabled(!round.canServe)
        .accessibilityIdentifier("serve")
    }
}

/// The wok panel is the same warm cream in light and dark mode (it matches the SpriteKit scene),
/// so what sits on it uses fixed inks rather than the system's.
enum PanelInk {
    static let panel = Color(red: 0.99, green: 0.95, blue: 0.87)
    static let ink = Color(red: 0.11, green: 0.14, blue: 0.13)
    static let soft = Color(red: 0.36, green: 0.33, blue: 0.24)
    static let chili = Color(red: 0.72, green: 0.23, blue: 0.08)
}

/// One ingredient on the Pantry palette. A picked chip wears the mark that takes it back out.
private struct PantryChip: View {
    let ingredient: Ingredient
    let isPicked: Bool
    let isNoted: Bool
    let height: CGFloat

    var body: some View {
        Text("\(IngredientLook(for: ingredient).emoji) \(ingredient.chipName)")
            .font(.system(size: 11, weight: .medium))
            .lineLimit(3)
            .allowsTightening(true)
            .minimumScaleFactor(0.85)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isPicked ? Color.orange.opacity(0.18) : Color.gray.opacity(0.14))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isNoted ? Color.orange : Color.clear, lineWidth: 2)
            )
            .overlay(alignment: .topTrailing) {
                if isPicked {
                    // Sits on the corner, so it doesn't cover the name on a narrow chip.
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.white, Color.orange)
                        .offset(x: 5, y: -5)
                }
            }
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(isPicked ? "\(ingredient.name), picked" : ingredient.name)
            .accessibilityHint(isPicked ? "Takes it back out" : "Picks it")
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("chip-\(ingredient.id)")
    }
}
#endif
