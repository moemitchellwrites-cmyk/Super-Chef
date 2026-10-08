#if canImport(SwiftUI) && canImport(SpriteKit)
import SwiftUI
import PantryGame
import PantryScoring

/// The app's root: loads the bundled content and progress, and shows the round in play in one of the
/// two modes. The iOS app target is a shell around this view, so everything the app does builds and
/// tests from the package.
///
/// Launch arguments: `-pantryMode kitchen` opens in Kitchen mode (Pantry is the default);
/// `-pantryMuted` starts silent; `-pantryFreshProgress` keeps progress in memory, so every launch is
/// a first launch; `-pantryFirstDish <id>` opens each session on that dish; `-pantryDemo` and
/// `-pantryDemoPantry` play a scripted round, and `-pantryDemoSession` plays five Pantry rounds through
/// to the summary (each implies muted and fresh progress).
public struct PantryRootView: View {
    @State private var game: Game?
    @State private var problem: String?

    private struct Game {
        let controller: SessionController
        let mode: GameMode
        let muted: Bool
    }

    public init() {}

    public var body: some View {
        Group {
            if let game {
                GameView(controller: game.controller, mode: game.mode, muted: game.muted)
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
                func value(after flag: String) -> String? {
                    guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else { return nil }
                    return arguments[index + 1]
                }
                let demo = DemoScript(arguments: arguments)
                let pantryDemo = PantryDemoScript(arguments: arguments)
                let scripted = demo != nil || pantryDemo != nil || arguments.contains("-pantryDemoSession")
                let muted = scripted || arguments.contains("-pantryMuted")
                let fresh = scripted || arguments.contains("-pantryFreshProgress")
                let controller = SessionController(
                    library: library,
                    file: fresh ? nil : Self.progressFile(),
                    firstDish: demo?.dishId ?? pantryDemo?.dishId ?? value(after: "-pantryFirstDish"),
                    seed: scripted ? 1 : nil,
                    muted: muted
                )
                var mode = value(after: "-pantryMode").flatMap(GameMode.init(rawValue:)) ?? .pantry
                if demo != nil { mode = .kitchen }
                if pantryDemo != nil { mode = .pantry }
                game = Game(controller: controller, mode: mode, muted: muted)
                await demo?.run(on: controller.kitchen)
                await pantryDemo?.run(on: controller.pantry)
                if arguments.contains("-pantryDemoSession") {
                    await SessionDemoScript().run(on: controller)
                }
            } catch {
                problem = String(describing: error)
            }
        }
    }

    /// Progress lives in the app's Application Support folder. Nil if the system won't name one;
    /// the game then runs without remembering.
    private static func progressFile() -> ProgressFile? {
        guard let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        return ProgressFile(url: folder.appendingPathComponent("Pantry/progress.json"))
    }
}

/// The round in play, in whichever mode is chosen, and the summary when a session ends. Each mode
/// has its own session and its own wok, so switching back finds the round as it was left (PD-034).
struct GameView: View {
    let controller: SessionController
    @State private var mode: GameMode
    @State private var isMuted: Bool

    init(controller: SessionController, mode: GameMode, muted: Bool) {
        self.controller = controller
        _mode = State(initialValue: mode)
        _isMuted = State(initialValue: muted)
    }

    var body: some View {
        Group {
            switch mode {
            case .pantry:
                PantryRoundView(
                    model: controller.pantry, mode: $mode, isMuted: isMuted,
                    progressLabel: controller.progressLabel(for: .pantry),
                    nextTitle: controller.nextTitle(for: .pantry),
                    countedNote: controller.countedNote(for: .pantry),
                    onNext: { controller.advance(.pantry) },
                    onToggleMute: { toggleMute() }
                )
            case .kitchen:
                RoundView(
                    model: controller.kitchen, mode: $mode,
                    progressLabel: controller.progressLabel(for: .kitchen),
                    nextTitle: controller.nextTitle(for: .kitchen),
                    countedNote: controller.countedNote(for: .kitchen),
                    onNext: { controller.advance(.kitchen) },
                    onToggleMute: { toggleMute() }
                )
            }
        }
        .sheet(isPresented: Binding(get: { controller.summaryMode != nil }, set: { _ in })) {
            if let finished = controller.summaryMode, let session = controller.session(for: finished) {
                SessionSummaryView(
                    summary: session.summary,
                    library: controller.library,
                    finishedBefore: controller.finishedCount(in: finished),
                    onNewSession: { controller.startNewSession() }
                )
            }
        }
    }

    private func toggleMute() {
        isMuted.toggle()
        controller.pantry.setMuted(isMuted)
        controller.kitchen.setMuted(isMuted)
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
        model.place(.wok)
        try? await Task.sleep(for: .milliseconds(350))
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
/// Plays a whole Pantry session when the app is launched with `-pantryDemoSession`, so CI can
/// screenshot the summary screen.
struct SessionDemoScript {
    @MainActor
    func run(on controller: SessionController) async {
        try? await Task.sleep(for: .milliseconds(700))
        for _ in 0..<Session.length {
            for ingredient in controller.pantry.round.palette.prefix(4) {
                controller.pantry.toggle(ingredient.id)
            }
            try? await Task.sleep(for: .milliseconds(300))
            controller.pantry.serve()
            try? await Task.sleep(for: .milliseconds(700))
            controller.advance(.pantry)
            try? await Task.sleep(for: .milliseconds(400))
        }
    }
}
#endif
