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
- `Tests/PantryScoringTests/`: golden tests (`Fixtures/goldens.json`: a good,
  an off-cuisine and a neighbour-cuisine attempt per dish, plus a wrong-amounts
  case), engine invariants, and content validation.

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

From this folder, on a Mac: `swift build`, `swift test`. CI runs both on
macOS for every push. The cloud session can't run Swift; it calibrates the
content with a Python mirror of the scorer and lets CI verify.
