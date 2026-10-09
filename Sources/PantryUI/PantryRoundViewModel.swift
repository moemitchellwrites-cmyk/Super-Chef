#if canImport(SwiftUI) && canImport(SpriteKit)
import Foundation
import Observation
import PantryGame
import PantryScoring

/// Drives one Pantry round (PD-025): owns the `PantryRound` value and keeps the wok scene and
/// the sound in step with it. Every rule lives in `PantryRound` and `PantryJudge`.
@MainActor
@Observable
final class PantryRoundViewModel {
    let library: ContentLibrary
    /// The measures the recipe reads in (PD-041). A Pantry round itself has no amounts.
    let measures: MeasureSystem
    private(set) var round: PantryRound
    /// The verdict on the picks just served, while its sheet is up.
    private(set) var result: PantryResult?
    /// Bumps whenever something lands in the wok; the view turns it into a haptic tap.
    private(set) var impactCount = 0
    /// Bumps when a pick is refused because every pick is spent; the view answers with a warning tap.
    private(set) var fullCount = 0

    @ObservationIgnored let scene = WokScene.make(vessel: .wok)
    @ObservationIgnored private let sound: SoundPlayer
    @ObservationIgnored private var fixedSeed: UInt64?
    /// Called after every serve that produced a verdict. The session uses it to note the first one.
    @ObservationIgnored var onServed: (() -> Void)?

    /// How many pieces one pick shows in the wok. There are no amounts in this mode.
    private static let piecesPerPick = 2

    init(library: ContentLibrary, dishId: String? = nil, seed: UInt64? = nil, muted: Bool = false, measures: MeasureSystem = .metric) {
        self.library = library
        self.measures = measures
        let dish = dishId.flatMap(library.dish(id:)) ?? library.dishes[0]
        round = PantryRound(dish: dish, library: library, seed: seed ?? UInt64.random(in: .min ... .max))
        fixedSeed = seed
        sound = SoundPlayer(isMuted: muted)
    }

    func warmUp() {
        sound.prepare()
    }

    func setMuted(_ muted: Bool) {
        sound.isMuted = muted
    }

    func start(_ dish: DishProfile) {
        scene.clear()
        result = nil
        round = PantryRound(dish: dish, library: library, seed: fixedSeed ?? UInt64.random(in: .min ... .max))
    }

    func startOver() {
        scene.clear()
        result = nil
        round.clear()
    }

    /// A tap: in if it was out, out if it was in.
    func toggle(_ id: String) {
        switch round.toggle(id) {
        case .added:
            land(id, atFraction: nil)
        case .removed:
            if let ingredient = round.ingredient(id) {
                scene.setPieces(for: id, count: 0, look: IngredientLook(for: ingredient))
            }
        case .full:
            fullCount += 1
        case .notOffered:
            break
        }
    }

    /// A drop on the wok: puts it in, never takes it out. `fraction` is how far across the wok it landed (0...1).
    func drop(_ id: String, atFraction fraction: Double) {
        guard !round.contains(id) else { return }
        switch round.toggle(id) {
        case .added:
            land(id, atFraction: fraction)
        case .full:
            fullCount += 1
        case .removed, .notOffered:
            break
        }
    }

    func serve() {
        result = round.result(in: library)
        if result != nil { onServed?() }
    }

    func dismissResult() {
        result = nil
    }

    private func land(_ id: String, atFraction fraction: Double?) {
        guard let ingredient = round.ingredient(id) else { return }
        let x = fraction.map { scene.dropX(fraction: CGFloat($0)) }
        let cue = SoundCue(contentCue: ingredient.soundCue)
        scene.setPieces(for: id, count: Self.piecesPerPick, look: IngredientLook(for: ingredient), atX: x)
        scene.playTwin(cue, atX: x)
        sound.play(cue)
        impactCount += 1
    }
}
#endif
