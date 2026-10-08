#if canImport(SwiftUI) && canImport(SpriteKit)
import SwiftUI
import PantryGame
import PantryScoring

/// The app's root: loads the bundled content and shows a round in one of the two modes. The iOS app
/// target is a shell around this view, so everything the app does builds and tests from the package.
///
/// Launch arguments: `-pantryMode kitchen` opens in Kitchen mode (Pantry is the default),
/// `-pantryMuted` starts silent, `-pantryDemo` and `-pantryDemoPantry` play a scripted round.
public struct PantryRootView: View {
    @State private var game: Game?
    @State private var problem: String?

    private struct Game {
        let pantry: PantryRoundViewModel
        let kitchen: RoundViewModel
        let mode: GameMode
        let muted: Bool
    }

    public init() {}

    public var body: some View {
        Group {
            if let game {
                GameView(pantry: game.pantry, kitchen: game.kitchen, mode: game.mode, muted: game.muted)
            } else if let problem {
                ContentUnavailableView("The pantry didn't load", systemImage: "exclamationmark.triangle", description: Text(problem))
            } else {
                ProgressView()
            }
        }
        .task {
            guard game == nil else { return }
            do {
                let library = try ContentLibrary.bundled()
                let arguments = ProcessInfo.processInfo.arguments
                let demo = DemoScript(arguments: arguments)
                let pantryDemo = PantryDemoScript(arguments: arguments)
                let scripted = demo != nil || pantryDemo != nil
                let muted = scripted || arguments.contains("-pantryMuted")
                let kitchen = RoundViewModel(library: library, dishId: demo?.dishId, seed: scripted ? 1 : nil, muted: muted)
                let pantry = PantryRoundViewModel(library: library, dishId: pantryDemo?.dishId, seed: scripted ? 1 : nil, muted: muted)
                var mode = GameMode.pantry
                if let flag = arguments.firstIndex(of: "-pantryMode"), arguments.indices.contains(flag + 1),
                   let asked = GameMode(rawValue: arguments[flag + 1]) {
                    mode = asked
                }
                if demo != nil { mode = .kitchen }
                if pantryDemo != nil { mode = .pantry }
                game = Game(pantry: pantry, kitchen: kitchen, mode: mode, muted: muted)
                await demo?.run(on: kitchen)
                await pantryDemo?.run(on: pantry)
            } catch {
                problem = String(describing: error)
            }
        }
    }
}

/// Both modes of one dish. Each mode keeps its own wok, so switching back finds the round as it was left;
/// choosing a different dish in one mode carries over to the other.
struct GameView: View {
    let pantry: PantryRoundViewModel
    let kitchen: RoundViewModel
    @State private var mode: GameMode
    @State private var isMuted: Bool

    init(pantry: PantryRoundViewModel, kitchen: RoundViewModel, mode: GameMode, muted: Bool) {
        self.pantry = pantry
        self.kitchen = kitchen
        _mode = State(initialValue: mode)
        _isMuted = State(initialValue: muted)
    }

    var body: some View {
        Group {
            switch mode {
            case .pantry:
                PantryRoundView(model: pantry, mode: $mode, isMuted: isMuted, onToggleMute: { toggleMute() })
            case .kitchen:
                RoundView(model: kitchen, mode: $mode, onToggleMute: { toggleMute() })
            }
        }
        .onChange(of: mode) { _, chosen in
            switch chosen {
            case .kitchen:
                if kitchen.round.dish.id != pantry.round.dish.id { kitchen.start(pantry.round.dish) }
            case .pantry:
                if pantry.round.dish.id != kitchen.round.dish.id { pantry.start(kitchen.round.dish) }
            }
        }
    }

    private func toggleMute() {
        isMuted.toggle()
        pantry.setMuted(isMuted)
        kitchen.setMuted(isMuted)
    }
}

/// Plays a scripted Pantry round when the app is launched with `-pantryDemoPantry`, so CI can
/// screenshot the Pantry screen (and its verdict, with `-pantryDemoServe`).
struct PantryDemoScript {
    let dishId = "mapo-tofu"
    let serves: Bool

    /// Three essentials, one that belongs but isn't essential, one that doesn't belong.
    private let picks: [(id: String, fraction: Double?)] = [
        ("firm-tofu", 0.5), ("doubanjiang", 0.35), ("garlic", nil), ("stock", 0.65), ("basil", nil),
    ]

    init?(arguments: [String]) {
        guard arguments.contains("-pantryDemoPantry") else { return nil }
        serves = arguments.contains("-pantryDemoServe")
    }

    @MainActor
    func run(on model: PantryRoundViewModel) async {
        try? await Task.sleep(for: .milliseconds(700))
        for pick in picks {
            if let fraction = pick.fraction {
                model.drop(pick.id, atFraction: fraction)
            } else {
                model.toggle(pick.id)
            }
            try? await Task.sleep(for: .milliseconds(350))
        }
        if serves {
            try? await Task.sleep(for: .milliseconds(900))
            model.serve()
        }
    }
}

/// Plays a scripted round when the app is launched with `-pantryDemo`, so CI can
/// screenshot the scene mid-round (and the score, with `-pantryDemoServe`) on a
/// simulator nobody is touching. Muted, fixed seed, inert without the argument.
struct DemoScript {
    let dishId = "mapo-tofu"
    let serves: Bool

    /// A decent mapo tofu with one deliberate slip (basil), so the score sheet has something to say.
    private let steps: [(id: String, amount: String, fraction: Double?)] = [
        ("firm-tofu", "400 g", 0.5),
        ("neutral-oil", "2 tbsp", nil),
        ("doubanjiang", "2½ tbsp", 0.35),
        ("garlic", "1 tbsp", nil),
        ("ginger", "2 tsp", 0.7),
        ("sichuan-peppercorn-ground", "2 tsp", nil),
        ("stock", "¾ cup", 0.6),
        ("basil", "25 g", 0.4),
        ("scallion", "3 tbsp", nil),
    ]

    init?(arguments: [String]) {
        guard arguments.contains("-pantryDemo") else { return nil }
        serves = arguments.contains("-pantryDemoServe")
    }

    @MainActor
    func run(on model: RoundViewModel) async {
        try? await Task.sleep(for: .milliseconds(700))
        for step in steps {
            model.add(step.id, atFraction: step.fraction)
            model.setAmount(step.id, label: step.amount)
            try? await Task.sleep(for: .milliseconds(350))
        }
        model.choose(.braise)
        model.select("doubanjiang")
        if serves {
            try? await Task.sleep(for: .milliseconds(900))
            model.serve()
        }
    }
}
#endif
