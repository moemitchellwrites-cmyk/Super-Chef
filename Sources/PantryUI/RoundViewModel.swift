#if canImport(SwiftUI) && canImport(SpriteKit)
import Foundation
import Observation
import PantryGame
import PantryScoring

/// Drives one round: owns the `Round` value, and keeps the wok scene and the sound
/// in step with it. Every rule lives in `Round` (tested in PantryGameTests); this
/// class only forwards and plays the cues.
@MainActor
@Observable
final class RoundViewModel {
    let library: ContentLibrary
    private(set) var round: Round
    /// The score for the attempt just served, while its sheet is up.
    private(set) var result: ScoreBreakdown?
    private(set) var isMuted: Bool
    /// Bumps whenever something lands in the wok or the burner lights; the view turns it into a haptic tap.
    private(set) var impactCount = 0

    @ObservationIgnored let scene = WokScene.make()
    @ObservationIgnored private let sound: SoundPlayer
    @ObservationIgnored private var fixedSeed: UInt64?

    /// - Parameters:
    ///   - dishId: the dish to open on; the first in the library when nil or unknown.
    ///   - seed: fixes the palette order (tests, demo). Random per round when nil.
    init(library: ContentLibrary, dishId: String? = nil, seed: UInt64? = nil, muted: Bool = false) {
        self.library = library
        let dish = dishId.flatMap(library.dish(id:)) ?? library.dishes[0]
        round = Round(dish: dish, library: library, seed: seed ?? UInt64.random(in: .min ... .max))
        fixedSeed = seed
        isMuted = muted
        sound = SoundPlayer(isMuted: muted)
    }

    func warmUp() {
        sound.prepare()
    }

    func toggleMute() {
        isMuted.toggle()
        sound.isMuted = isMuted
    }

    // MARK: The round

    func start(_ dish: DishProfile) {
        scene.clear()
        result = nil
        round = Round(dish: dish, library: library, seed: fixedSeed ?? UInt64.random(in: .min ... .max))
    }

    func startOver() {
        scene.clear()
        result = nil
        round.clear()
    }

    /// Tap or drop. `fraction` is how far across the wok view the ingredient was dropped (0...1); nil for a tap.
    func add(_ id: String, atFraction fraction: Double? = nil) {
        guard round.add(id) == .added, let ingredient = round.ingredient(id) else { return }
        let x = fraction.map { scene.dropX(fraction: CGFloat($0)) }
        let cue = SoundCue(contentCue: ingredient.soundCue)
        scene.setPieces(for: id, count: round.pieceCount(for: id), look: IngredientLook(for: ingredient), atX: x)
        scene.playTwin(cue, atX: x)
        sound.play(cue)
        impactCount += 1
    }

    func select(_ id: String) {
        round.select(id)
    }

    func stepSelected(by delta: Int) {
        guard let id = round.selectedId, round.step(id, by: delta) else { return }
        syncPieces(id)
    }

    func setSelectedStep(_ index: Int) {
        guard let id = round.selectedId, round.setStep(id, to: index) else { return }
        syncPieces(id)
    }

    func removeSelected() {
        guard let id = round.selectedId, let ingredient = round.ingredient(id), round.remove(id) else { return }
        scene.setPieces(for: id, count: 0, look: IngredientLook(for: ingredient))
    }

    func choose(_ method: CookingMethod) {
        guard round.method != method else { return }
        round.choose(method)
        scene.setFlame(level: CGFloat(method.flameLevel))
        sound.play(.flame)
        impactCount += 1
    }

    func serve() {
        guard let attempt = round.attempt(timestamp: Date()) else { return }
        result = try? library.score(attempt)
    }

    func dismissResult() {
        result = nil
    }

    private func syncPieces(_ id: String) {
        guard let ingredient = round.ingredient(id) else { return }
        scene.setPieces(for: id, count: round.pieceCount(for: id), look: IngredientLook(for: ingredient))
    }

    // MARK: Demo support

    /// Moves an ingredient already in the wok to the step with this label ("2½ tbsp"). For the demo script.
    func setAmount(_ id: String, label: String) {
        guard let ladder = round.ladder(for: id), let index = ladder.steps.firstIndex(where: { $0.label == label }) else { return }
        round.select(id)
        setSelectedStep(index)
    }
}
#endif
