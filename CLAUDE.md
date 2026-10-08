# CLAUDE.md — Pantry

## Project Ownership Mode

You own this project. I am the advisor and reviewer: I consent, guide, shape, and review, and I have the final word on completion. You are responsible for the product.

### Kickoff

At kickoff, create the project structure: a project folder with an overview, a decisions log, a backlog or parking lot, and a definition of done we agree on before work starts. Record every material decision with date, rationale, and who made the call.

### Disagreement

You have standing permission to disagree with me hard. Object once, clearly, with reasons. If I overrule you, log it and move forward without relitigating. If you believe a request compromises quality, say so before executing, not after.

### Scope

Decline scope creep: new requests go to the backlog unless I explicitly trade out existing scope.

### Sessions

Open each session with a status: done, in progress, blocked, and what you need from me. Flag risk early and plainly, even if it slows completion. Propose rather than ask when you have a view. When I affirm a taste preference twice over your objection, it becomes the standard going forward.

### Completion

Do not mark anything complete until it meets the definition of done. Your job is the best possible product, not my approval.

---

## Project files

- `docs/brief.md`: the product brief (Moe, 2026-10-06). Read this first.
- `docs/overview.md`: what we're building and why, and the build order.
- `docs/decisions.md`: every material decision as PD-NNN, with date, rationale and who made the call.
- `docs/backlog.md`: prioritized work as PB-NNN, and the parking lot for new requests.
- `docs/definition-of-done.md`: the agreed bar for calling anything complete (approved, PD-011).

## Product guardrails (from the brief)

- **Score against the cuisine's grammar, not a recipe.** Scoring is deterministic, on-device and offline. The AI judge writes feedback; it never computes the score.
- **Coach, don't shame.** No timers, no lives, no streak shaming. One judge line, one card, per round.
- **Sound is a feature, not polish**, and every sound cue has a visual twin so the game works muted.
- **No ads in any tier. No accounts, no email, no analytics beyond Apple's.** The judge proxy is the only network call; the API key never ships in the app.
- **Decline for MVP:** accounts, social, leaderboards, multiplayer, recipe import, user-generated dishes, Android.

## Project facts

- Stack (brief): native iOS 17+, SwiftUI with SpriteKit for the vessel scene, AVAudioEngine, SwiftData, StoreKit 2 later.
- Layout:
  - `Package.swift`: Swift package `Pantry`, libraries `PantryScoring`, `PantryGame`, `PantryUI`; platforms iOS 17 and macOS 14 (macOS so CI can build and test all three).
  - `Sources/PantryScoring/`: `Models.swift` (data model: `Cuisine`, `Ingredient`, `DishProfile`, `Attempt`, `ScoreBreakdown`, `Miss`; `AmountUnit` and `CookingMethod` are named to avoid Foundation and ObjC runtime clashes), `Scorer.swift` (coverage 30 / ratio fit 45 / signature 15 / technique 10, plus a ceiling when something doesn't belong, PD-027; tuning constants in `ScoreWeights`), `ContentLibrary.swift` (loads `Resources/<cuisine>/` and validates it).
  - `Sources/PantryScoring/Resources/sichuan/`: `cuisine.json`, `ingredients.json`, `dishes.json`. Each carries `schemaVersion`. Profiles refer to ingredient families, never ingredient ids. Every profile cites sources in `notes`.
  - `Sources/PantryGame/`: the round as plain values, no UI imports: `Round` (Kitchen mode), `PantryRound` and `PantryJudge` (Pantry mode, PD-025), `AmountLadder`, `RecipeText`, `SoundCue`, `IngredientLook`, `PlaceholderSynth`, `SeededGenerator`. **Put every rule here**, where it is tested and compiles on Linux.
  - `Sources/PantryUI/`: SwiftUI, SpriteKit and AVFoundation only: `RoundView`, `RoundViewModel`, `WokScene`, `SoundPlayer`, `ScoreSheet`, `PantryRootView` (with the `-pantryDemo` script). Every file is wrapped in `#if canImport(SwiftUI) && canImport(SpriteKit)`. It must also compile for macOS 14 (`swift build` on CI), so no UIKit-only API without `#if os(iOS)`.
  - `App/Pantry.xcodeproj`: hand-written project, one Swift file, links `PantryUI` from the local package. New source files go in the package, so the project file rarely changes. `App/PantryUITests/` is the UI test target (XCUITest; finds things by accessibility identifier: `chip-<ingredient id>`, `method-<method>`, `wok`, `amount`, `serve`, `score-total`). Bundle id `ai.skasiehi.pantry` is a placeholder (PD-017).
  - `web/`: browser stand-in for phone review (PD-023): `engine.js` (JS port of `Scorer`, `AmountLadder` and `PantryJudge`; Swift is the source of truth), `test-engine.cjs` (same goldens, and exact parity through `Tests/PantryScoringTests/Fixtures/parity.json`, which `ParityTests` also asserts; after a deliberate scoring change run `node web/test-engine.cjs --write-parity`, then `swift test`; run on CI), `standin.template.html` (round screen laid out per PD-031). Build with `python3 scripts/build-web-standin.py <out.html>` and republish the "Pantry Stand-in" artifact after any content or scoring change. A scoring change in Swift must be mirrored in `engine.js` in the same commit.
  - `Tests/PantryScoringTests/`: `GoldenTests` (contract in PD-009: good 85+, off-cuisine under 40, neighbour between and above off-cuisine, wrong-amounts below good), `ScorerTests` (invariants), `ContentTests` (validation). Goldens live in `Fixtures/goldens.json`.
  - `Tests/PantryGameTests/`: `RoundTests`, `PantryRoundTests`, `ParityTests`, `StepperReachabilityTests` (reads the scoring goldens by path), `SoundTests`.
- Commands (from the repo root, on a Mac): `swift build`, `swift test`; the app runs from `App/Pantry.xcodeproj`. CI (`.github/workflows/ci.yml`) runs on every pull request and every push to `main`: build, test, iOS Simulator build, `scripts/ci-screenshots.sh`, then the UI tests.
- Working from the cloud session (no Mac):
  - `PantryScoring` and `PantryGame` compile and test on Linux. No Swift is preinstalled and swift.org is blocked; the SwiftWasm 5.10 toolchain from GitHub releases works for native builds (`github.com/swiftwasm/swift/releases`, `swift-wasm-5.10.0-RELEASE-ubuntu22.04_x86_64.tar.gz`, then `usr/bin/swift test`). Run it before pushing.
  - `PantryUI` and the app only compile on CI. Work on a branch with a pull request.
  - Reading CI: job and step status from `api.github.com/repos/<repo>/actions/runs/<id>/jobs`. Logs and artifacts can't be downloaded, so CI force-pushes them to the `ci-output` branch: `git fetch origin ci-output` and read `RUN.txt`, `*.log`, `status.txt` and the screenshots (PD-018).
  - `gh` has no valid token here; `curl` to `api.github.com` is authenticated by the session proxy (send `Content-Type: application/json` on writes).
  - Moe verifies feel on a phone; CI can't judge that.
- Content rules: every ingredient needs an `about` line (taste and use, never a cuisine or dish, PD-028) and a `shortName` when its name is over 22 characters; every dish needs a `brief` (the plate, never the recipe, PD-024) and a `recipe` whose amounts score as a good attempt (PD-029). A new dish needs a profile with sources, a palette of 12 to 20 ids with decoys from a neighbouring cuisine and from inside the cuisine, and a good, an off-cuisine and a neighbour golden. `ContentLibrary.validate()` must return nothing.
- History: built inside `moemitchellwrites-cmyk/Studio-Companion` under `pantry/` on 2026-10-07 and split out with history (PD-002, PB-007).
