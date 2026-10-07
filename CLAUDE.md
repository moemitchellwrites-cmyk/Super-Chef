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

- Stack (brief): native iOS 17+, SwiftUI with SpriteKit for the vessel scene, AVAudioEngine, SwiftData, StoreKit 2 later. This repository started as the scoring package; the app target lands with PB-002.
- Layout:
  - `Package.swift`: Swift package `Pantry`, library `PantryScoring`, platforms iOS 17 and macOS 14 (macOS so CI can test).
  - `Sources/PantryScoring/`: `Models.swift` (data model: `Cuisine`, `Ingredient`, `DishProfile`, `Attempt`, `ScoreBreakdown`, `Miss`; `AmountUnit` and `CookingMethod` are named to avoid Foundation and ObjC runtime clashes), `Scorer.swift` (coverage 40 / ratio fit 35 / signature 15 / technique 10; tuning constants in `ScoreWeights`), `ContentLibrary.swift` (loads `Resources/<cuisine>/` and validates it).
  - `Sources/PantryScoring/Resources/sichuan/`: `cuisine.json`, `ingredients.json`, `dishes.json`. Each carries `schemaVersion`. Profiles refer to ingredient families, never ingredient ids. Every profile cites sources in `notes`.
  - `Tests/PantryScoringTests/`: `GoldenTests` (contract in PD-009: good 85+, off-cuisine under 40, neighbour between and above off-cuisine, wrong-amounts below good), `ScorerTests` (invariants), `ContentTests` (validation). Goldens live in `Fixtures/goldens.json`.
- Commands (from the repo root, on a Mac): `swift build`, `swift test`. CI (`.github/workflows/ci.yml`) runs both on macOS for every push to `main` and every pull request.
- Can't be done in the cloud session: compiling Swift or running the app. Calibrate content changes with a Python mirror of `Scorer.swift` in the scratchpad (the mirror is rebuilt per session; keep it exact), push small, let CI verify. Moe verifies the app on their Mac.
- Content rules: a new dish needs a profile with sources, a palette of 12 to 20 ids with decoys from a neighbouring cuisine and from inside the cuisine, and a good, an off-cuisine and a neighbour golden. `ContentLibrary.validate()` must return nothing.
- History: built inside `moemitchellwrites-cmyk/Studio-Companion` under `pantry/` on 2026-10-07 and split out with history (PD-002, PB-007).
