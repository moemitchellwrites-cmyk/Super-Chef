# Pantry (working title): the cooking game

A cartoony, commute-length iOS game: cook a dish from a cuisine by choosing
ingredients and amounts, and get scored on how well the choices fit that
cuisine's grammar. The product brief is `docs/brief.md`; the project docs
(overview, decisions, backlog, definition of done) are in `docs/`.

## What's here

- `Sources/PantryScoring/`: the scoring engine. Pure Swift, no dependencies,
  no network, deterministic. `Models.swift` is the data model, `Scorer.swift`
  the scoring, `ContentLibrary.swift` loads and validates bundled content.
- `Sources/PantryScoring/Resources/sichuan/`: the Sichuan content. One cuisine
  file, 65 ingredients (Sichuan pantry plus decoys from neighbouring cuisines),
  ten dish profiles. Hand-authored by Claude from the sources named in each
  profile's `notes`; awaiting chef review.
- `Sources/PantryGame/`: one round as plain values, no UI frameworks.
  `Round.swift` (what's in the wok, amounts, method, the attempt it becomes),
  `AmountLadder.swift` (the stepper's steps), `SoundCue.swift` (cues, their
  visual twins, placeholder art), `PlaceholderSynth.swift` (placeholder sounds
  generated in code).
- `Sources/PantryUI/`: the round screen. `RoundView.swift` (SwiftUI: palette,
  stepper, method chips, serve), `WokScene.swift` (SpriteKit: the wok, the
  pile, every visual twin), `SoundPlayer.swift` (AVAudioEngine),
  `ScoreSheet.swift` (a stand-in until the judge line and cards),
  `PantryRootView.swift` (entry point and the CI demo script).
- `App/Pantry.xcodeproj`: the iOS app, a one-file shell around `PantryUI`.
  iPhone, portrait, iOS 17.
- `Tests/PantryScoringTests/`: golden tests (`Fixtures/goldens.json`: a good,
  an off-cuisine and a neighbour-cuisine attempt per dish, plus a wrong-amounts
  case), engine invariants, and content validation.
- `Tests/PantryGameTests/`: round rules, the stepper (every good golden is
  rebuilt on the stepper and must still score 85+), cues and the synth.
- `scripts/ci-screenshots.sh`: plays a scripted round in the simulator on CI.
- `web/`: a browser stand-in for reviewing rounds from a phone before the app
  is on TestFlight (PD-023). `engine.js` is a port of the scorer and stepper,
  held to the same goldens by `node web/test-engine.cjs`;
  `python3 scripts/build-web-standin.py out.html` builds the page with the
  bundled content inlined. Not a product, and not a web version.

## Playing a round

Add ingredients by tapping a chip or dragging it into the wok. The selected
ingredient's amount is set with minus, plus or the slider. Pick how to cook
it, then serve. Every sound has a visual twin in the scene (sparks and steam,
bubbles, droplets, a shaking pan, a flaring burner, and a comic-strip word),
so the round plays the same muted. The dish menu in the header stands in for
the session loop until PB-005.

## Scoring in one paragraph

Every amount converts to grams (per-ingredient grams per teaspoon; a pinch is
an eighth of a teaspoon). Coverage (40) credits required ingredient families by
weight (half credit when a family is present but its key ratio is off by 3x
or more) and charges 5 to 12 points per forbidden or off-cuisine ingredient,
scaled by how much of the dish it is. Ratio fit (35) compares key weight
ratios against bands in log space, with linear partial credit that reaches
zero at 3x off. Signature (15) measures heat, numbing, acid, umami and
sweetness as potency times percent of the dish by weight, against the dish's
envelope. Technique (10) is the vessel, and the cooking method when one is
given. The breakdown carries a list of misses and a `pattern` string for
caching judge feedback.

## Commands

On a Mac, from the repository root: `swift build`, `swift test`. To run the
game, open `App/Pantry.xcodeproj` in Xcode 15 or newer and run the `Pantry`
scheme on an iPhone or a simulator.

CI (`.github/workflows/ci.yml`) runs on every pull request and every push to
`main`: package build and tests, an iOS Simulator build of the app, then a
scripted round on an iPhone 16 and an iPhone SE with screenshots, then the
UI tests. That run's
logs and screenshots are force-pushed to the `ci-output` branch; nothing else
lives there.

Launch arguments: `-pantryDemo` plays the scripted round (muted, fixed seed);
add `-pantryDemoServe` to serve it and show the score. `-pantryMuted` starts
with the sound off.

`App/PantryUITests/` drives the real screen on a simulator (drag a chip into
the wok, drop one outside it, tap, step, pick a method, serve). In Xcode:
Product, Test.
