#if canImport(SwiftUI) && canImport(SpriteKit)
import SwiftUI
import PantryGame
import PantryScoring

/// The app's root: loads the bundled content and shows a round. The iOS app target
/// is a shell around this view, so everything the app does builds and tests from the package.
public struct PantryRootView: View {
    @State private var model: RoundViewModel?
    @State private var problem: String?

    public init() {}

    public var body: some View {
        Group {
            if let model {
                RoundView(model: model)
            } else if let problem {
                ContentUnavailableView("The pantry didn't load", systemImage: "exclamationmark.triangle", description: Text(problem))
            } else {
                ProgressView()
            }
        }
        .task {
            guard model == nil else { return }
            do {
                let library = try ContentLibrary.bundled()
                let arguments = ProcessInfo.processInfo.arguments
                let demo = DemoScript(arguments: arguments)
                let loaded = RoundViewModel(
                    library: library,
                    dishId: demo?.dishId,
                    seed: demo == nil ? nil : 1,
                    muted: demo != nil || arguments.contains("-pantryMuted")
                )
                model = loaded
                await demo?.run(on: loaded)
            } catch {
                problem = String(describing: error)
            }
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
