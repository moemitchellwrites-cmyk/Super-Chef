#if canImport(SwiftUI) && canImport(SpriteKit)
import Foundation
import Observation
import PantryGame
import PantryScoring

/// Runs the five-round session in each mode (PB-005): deals the dishes, settles a round when the
/// player moves on, shows the summary, and keeps progress in one small file on the phone.
/// The rules are `Session` and `GameProgress`; this class moves the two round models along.
@MainActor
@Observable
final class SessionController {
    let library: ContentLibrary
    let pantry: PantryRoundViewModel
    let kitchen: RoundViewModel
    private(set) var progress: GameProgress
    /// The mode whose finished session is on the summary screen.
    private(set) var summaryMode: GameMode?

    @ObservationIgnored private let file: ProgressFile?
    @ObservationIgnored private let firstDish: String?
    @ObservationIgnored private var fixedSeed: UInt64?

    /// - Parameters:
    ///   - file: where progress is kept. Nil keeps it in memory only (tests, demos).
    ///   - firstDish: the dish each new session opens on (tests, demos).
    ///   - seed: fixes the deal and the palettes (tests, demos).
    ///   - measures: the measures the stepper and recipes read in.
    init(library: ContentLibrary, file: ProgressFile?, firstDish: String? = nil, seed: UInt64? = nil, muted: Bool = false,
         measures: MeasureSystem = .metric) {
        self.library = library
        self.file = file
        self.firstDish = firstDish
        fixedSeed = seed
        var loaded = file?.load() ?? GameProgress()
        var sessions: [GameMode: Session] = [:]
        for mode in GameMode.allCases {
            // A saved session whose dishes are no longer in the content is dealt again.
            if let saved = loaded.session(for: mode), saved.dishIds.allSatisfy({ library.dish(id: $0) != nil }) {
                sessions[mode] = saved
            } else {
                let dealt = Session(mode: mode, dishes: library.dishes, avoiding: loaded.lastDishIds(in: mode),
                                    first: firstDish, seed: seed ?? UInt64.random(in: .min ... .max))
                loaded.setSession(dealt)
                sessions[mode] = dealt
            }
        }
        progress = loaded
        let pantryDish = sessions[.pantry].flatMap { $0.currentDishId ?? $0.dishIds.last }
        let kitchenDish = sessions[.kitchen].flatMap { $0.currentDishId ?? $0.dishIds.last }
        pantry = PantryRoundViewModel(library: library, dishId: pantryDish, seed: seed, muted: muted, measures: measures)
        kitchen = RoundViewModel(library: library, dishId: kitchenDish, seed: seed, muted: muted, measures: measures)
        // A session finished but not yet acknowledged (the app closed on the summary) opens on it again.
        summaryMode = GameMode.allCases.first { sessions[$0]?.isComplete == true }
        save()
        pantry.onServed = { [weak self] in self?.noteServe(.pantry) }
        kitchen.onServed = { [weak self] in self?.noteServe(.kitchen) }
    }

    /// Notes a serve. The first serve of a round is the one the session keeps (see `Session.served`).
    private func noteServe(_ mode: GameMode) {
        guard var session = session(for: mode) else { return }
        let counted: Bool
        switch mode {
        case .pantry:
            guard let result = pantry.result else { return }
            counted = session.serve(points: result.found.count, outOf: result.essentials)
        case .kitchen:
            guard let result = kitchen.result else { return }
            counted = session.serve(points: result.total, outOf: 100)
        }
        if counted {
            progress.setSession(session)
            save()
        }
    }

    /// Set when the verdict on screen is a second go at the dish: says which result the session keeps.
    func countedNote(for mode: GameMode) -> String? {
        guard let served = session(for: mode)?.served else { return nil }
        switch mode {
        case .pantry:
            guard let result = pantry.result, result.found.count != served.points else { return nil }
            return "Your first serve, \(served.points) of \(served.outOf), is the one this session keeps."
        case .kitchen:
            guard let result = kitchen.result, result.total != served.points else { return nil }
            return "Your first serve, \(served.points), is the one this session keeps."
        }
    }

    func session(for mode: GameMode) -> Session? {
        progress.session(for: mode)
    }

    /// "2 of 5" for the round in play.
    func progressLabel(for mode: GameMode) -> String {
        session(for: mode)?.progressLabel ?? ""
    }

    /// What the score sheet's forward button says.
    func nextTitle(for mode: GameMode) -> String {
        session(for: mode)?.isLastRound == true ? "Finish" : "Next dish"
    }

    /// Settles the served round and moves on: the next dish, or the summary after the fifth.
    func advance(_ mode: GameMode) {
        guard var session = session(for: mode), session.advance() else { return }
        progress.setSession(session)
        save()
        if let next = session.currentDishId.flatMap(library.dish(id:)) {
            start(next, in: mode)
        } else {
            // Let the score sheet leave before the summary arrives; two sheets can't trade places in one step.
            dismissResult(in: mode)
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(500))
                summaryMode = mode
            }
        }
    }

    /// Files the finished session and deals the next one, with different dishes where there are enough.
    func startNewSession() {
        guard let mode = summaryMode, let finished = session(for: mode) else { return }
        progress.finish(finished, at: Date())
        let dealt = Session(mode: mode, dishes: library.dishes, avoiding: Set(finished.dishIds),
                            first: firstDish, seed: fixedSeed ?? UInt64.random(in: .min ... .max))
        progress.setSession(dealt)
        save()
        if let first = dealt.currentDishId.flatMap(library.dish(id:)) {
            start(first, in: mode)
        }
        summaryMode = nil
    }

    func finishedCount(in mode: GameMode) -> Int {
        progress.finishedCount(in: mode)
    }

    private func start(_ dish: DishProfile, in mode: GameMode) {
        switch mode {
        case .pantry: pantry.start(dish)
        case .kitchen: kitchen.start(dish)
        }
    }

    private func dismissResult(in mode: GameMode) {
        switch mode {
        case .pantry: pantry.dismissResult()
        case .kitchen: kitchen.dismissResult()
        }
    }

    /// Progress is a convenience. If the file can't be written the game carries on.
    private func save() {
        try? file?.save(progress)
    }
}
#endif
