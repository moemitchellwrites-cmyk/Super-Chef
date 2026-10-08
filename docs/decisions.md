# Pantry: Decision Log

Every material decision gets an entry: date, rationale and who made the call.
Don't edit past entries; supersede them with a new one. The brief's own
decisions table (`brief.md`, 2026-10-06, all Moe) stands as PD-000.

## Template

```
## PD-NNN: <title>
- Date: YYYY-MM-DD
- Made by: Moe | Claude | Moe (overruled Claude)
- Status: proposed | accepted | superseded by PD-NNN
- Context:
- Decision:
- Rationale:
- Consequences:
```

---

## PD-001: Project Ownership Mode applies to Pantry
- Date: 2026-10-07
- Made by: Moe (in the brief)
- Status: accepted
- Decision: Claude owns the product; Moe advises, consents, shapes, reviews and has the final word on completion. Project docs live in `pantry/docs/`.
- Consequences: Decisions are logged here as PD-NNN; backlog items are PB-NNN.

## PD-002: Build inside the Studio-Companion repository under `pantry/` for now
- Date: 2026-10-07
- Made by: Claude; accepted by Moe 2026-10-07, including the split
- Status: accepted
- Context: The brief positions the game as a separate SkasieHI product. Step one is a dependency-free Swift package; creating a new GitHub repository is an outward-facing act Moe should name and own.
- Decision: The package lives at `pantry/` with its own docs and its own CI job. It shares nothing with the studio code.
- Rationale: Keeps today's work verifiable on the existing CI without blocking on a repository decision.
- Consequences: Recommend splitting into its own repository before step 2 (the iOS app target), while the history is one folder deep and easy to lift.
- Outcome (2026-10-07): done. Moe created `moemitchellwrites-cmyk/Super-Chef`; the `pantry/` history was pushed there as `main`, and Studio-Companion keeps a pointer.

## PD-003: Weight under the hood; units are a display choice
- Date: 2026-10-07
- Made by: Claude
- Status: accepted (answers the brief's open question on units for the engine; what the US player sees stays open)
- Context: The brief's ratio bands are by weight but the stepper offers pinch, tsp, tbsp, cup and 100 g. "Density" alone doesn't convert a teaspoon of peppercorns and a teaspoon of oil.
- Decision: Every ingredient carries `gramsPerTeaspoon` (nil for weight-only ingredients). Tablespoon is 3 tsp, cup is 48 tsp, pinch is 1/8 tsp. A volume unit on a weight-only ingredient is reported as an `unmeasurable` miss, never guessed.
- Consequences: The UI can show any unit; scoring never sees one.

## PD-004: Ratios are compared in log space with partial credit to 3x off
- Date: 2026-10-07
- Made by: Claude
- Status: accepted
- Decision: Inside the band is full credit. Outside, credit falls linearly in log distance from the nearest edge and reaches zero at a factor of 3. Half the low edge and twice the high edge cost the same. Bands are on ingredient families, so substitutes (firm or silken tofu) score alike. A ratio whose numerator or denominator is absent earns nothing and is reported as `ratioUndefined`.
- Rationale: Ratios are multiplicative; a linear scale would punish "too much" far harder than "too little".

## PD-005: Two tiers of forbidden, with amount-aware penalties
- Date: 2026-10-07
- Made by: Claude
- Status: accepted
- Decision: The cuisine lists off-cuisine families (penalised in every dish); each dish lists families that signal drift inside the cuisine (black vinegar in mapo tofu, peppercorn in fish-fragrant eggplant). Each offending ingredient costs 5 points plus up to 7 more, reaching the full 12 when it is 10 % of the dish by weight. Coverage can't go below zero.
- Rationale: A pinch of basil is a mistake; a cup of cream is a different dish. Both should read as misses, not equally.

## PD-006: Signature is potency times percent of the dish, against a per-dish envelope
- Date: 2026-10-07
- Made by: Claude
- Status: accepted
- Context: The brief puts the envelope on the cuisine. Mapo tofu and kung pao chicken differ more on numbing and sweetness than Sichuan and Hunan do.
- Decision: Each ingredient has a potency per axis (heat, numbing, acid, umami, sweet): the level it contributes per 1 % of the dish by weight. Levels are capped at 5. Each dish has its own envelope; the cuisine's is the fallback. Outside the band, credit falls linearly and reaches zero two levels past the edge.
- Consequences: Potencies are the most hand-tuned numbers in the content and the first thing the chef reviewer should sanity-check. They are scale-free, so doubling the recipe changes nothing.

## PD-007: Technique scores the vessel, and the method only when the player chose one
- Date: 2026-10-07
- Made by: Claude; accepted by Moe 2026-10-07
- Status: accepted (the method tap is an acceptance criterion of PB-002)
- Context: The brief gives technique 10 points for "vessel and technique match", but the described UX only lets the player pick a vessel.
- Decision: `Attempt.method` is optional. With a method: vessel 6, method 4. Without: vessel 10. Proposal: add a one-tap method choice (stir-fry, braise, deep-fry, poach...) to the round; it is one of the most teachable things about a cuisine and costs nothing in time.

## PD-008: Keep the brief's score composition; flag that it is coverage-heavy
- Date: 2026-10-07
- Made by: Claude (objection recorded); Moe accepted the proposal 2026-10-07
- Status: accepted
- Context: With 40/35/15/10, a mapo tofu with the right pantry but five times the doubanjiang and ten times the sugar scores 85, the "known-good" threshold. Two ingredients (doubanjiang, peppercorn) decide 24 of the coverage points and 23 of the ratio points.
- Decision: Ship the composition as written; add the over-sauced case to the goldens with a 55 to 90 range so the behaviour is visible.
- Proposal: a required family that is present but whose key ratio is off by more than 3x earns only half its coverage credit ("present, but wrong amount"). That drops the over-sauced mapo to about 79 without touching the point split.
- Outcome (2026-10-07): implemented. "Key ratio" means a ratio band the family is the numerator of; the denominator family is not penalised. Reported as a `wrongAmount` miss. The over-sauced mapo golden moved from 85 to 79; no other golden moved.

## PD-009: The golden test contract
- Date: 2026-10-07
- Made by: Claude (extends the brief's two cases)
- Status: accepted
- Decision: Per dish: a good attempt scores 85 to 100 with no misses; an off-cuisine attempt scores under 40; a neighbour-cuisine attempt scores 25 to 65 and above the off-cuisine one. At least one right-pantry-wrong-amounts attempt scores 55 to 90, below the good one, and names a ratio as high. Engine invariants: deterministic, invariant to scaling amounts, splitting a line, zero-amount lines; adding an off-cuisine ingredient never raises a score.
- Rationale: The brief's two thresholds pass trivially once the content is calibrated; the ordering and invariant tests are what catch an arbitrary-feeling engine.

## PD-010: The palette is part of the dish profile
- Date: 2026-10-07
- Made by: Claude
- Status: accepted
- Decision: `DishProfile.palette` lists the 12 to 20 ingredient ids a round offers, hand-authored, with at least one decoy from a neighbouring cuisine and one from inside the cuisine. Validation checks the good attempt is buildable from it.
- Rationale: Decoy design is where the learning happens (brief); it is content, not UI logic.

## PD-011: Definition of done approved
- Date: 2026-10-07
- Made by: Moe (on Claude's proposal)
- Status: accepted
- Decision: `definition-of-done.md` as proposed is the bar. Nothing is complete until it meets it.

## PD-012: The palette is SwiftUI, the wok is SpriteKit; tap or drag to add
- Date: 2026-10-07
- Made by: Claude
- Status: accepted
- Context: The brief gives SpriteKit "drag, drop, and particle effects in the pan" and also says "tap to add". The backlog item says drag-and-drop. Ingredient names run to two lines, and a palette drawn in SpriteKit is invisible to VoiceOver and to UI tests.
- Decision: The palette, stepper, method chips and serve button are SwiftUI. The wok, the pile of ingredients and every visual twin are one SpriteKit scene. A chip is tapped to add it, or dragged: SwiftUI tracks the drag, lights the wok's rim while the chip is over it, and hands the drop point to the scene. Both gestures stay.
- Rationale: Tap is the one-thumb, 60-to-120-second path; drag is the toy. Text, layout and accessibility are SwiftUI's strengths; physics and particles are SpriteKit's.
- Consequences: A drop outside the wok does nothing. The scene has no touch handling of its own.

## PD-013: One amount ladder per ingredient; the player never picks a unit
- Date: 2026-10-07
- Made by: Claude
- Status: accepted (the units shown to US players stay open under PB-100)
- Context: The brief offers "a dial or stepper" in pinch, tsp, tbsp, cup and 100 g. A unit picker plus a number is two controls per ingredient, twelve or more times a round.
- Decision: Volume ingredients share one 21-step ladder that climbs pinch, ¼ tsp ... 1 tbsp ... ¼ cup ... 4 cups. Weight-only ingredients step 5 g to 1 kg in 22 steps. A new ingredient starts at one of its default unit (1 tsp, 1 tbsp, 1 cup) or 100 g, which is never tuned to the dish. The control is minus, plus and a slider over the same steps.
- Rationale: Steps are roughly geometric because the scorer compares ratios in log space (PD-004), so each tap is a similar move in score terms. `StepperReachabilityTests` rebuilds every good golden on the ladder: all ten still score 100.
- Consequences: Amounts between steps can't be entered. If the chef's red pen produces a profile that needs a finer step, that test fails and names it.

## PD-014: Placeholder sounds are synthesised in code
- Date: 2026-10-07
- Made by: Claude
- Status: accepted (replaced by Moe's recordings in PB-011)
- Context: The brief suggests public-domain or licensed libraries for the MVP.
- Decision: `PlaceholderSynth` generates the five cues (sizzle, boil, splash, clatter, flame) as samples at launch. No audio files in the repository.
- Rationale: Nothing to license, attribute or audit, nothing binary to review, and the cues are deterministic so they can be tested. They are placeholders either way; time spent choosing library sounds is time not spent on the recordings that ship.
- Consequences: They sound like placeholders. PB-011 swaps the buffers for files without touching the cue names.

## PD-015: A cooking method is required before serving
- Date: 2026-10-07
- Made by: Claude
- Status: accepted (amends the UX half of PD-007; the scorer still accepts an attempt without a method)
- Context: PD-007 scores the vessel alone (10 points) when no method is given, and vessel 6 plus method 4 when one is. With one vessel on screen, a player who skips the method tap gets all 10 for free and one who guesses risks 4.
- Decision: The serve button stays disabled, and says "Choose how to cook it", until a method is picked. The round offers every method some dish in the cuisine uses (six for Sichuan), so wrong ones are always on the table.
- Rationale: The method is one of the most teachable things about a cuisine (PD-007); it shouldn't be optional homework.

## PD-016: The audio session is ambient
- Date: 2026-10-07
- Made by: Claude
- Status: accepted
- Decision: `AVAudioSession` category `.ambient`. The game obeys the silent switch and plays over the player's own music or podcast instead of stopping it. There is also a mute button on the round screen.
- Rationale: It is a commute game. Killing someone's podcast on launch is how a game gets deleted. Every cue has a visual twin, so silence costs nothing.

## PD-017: The app is a thin shell around the package
- Date: 2026-10-07
- Made by: Claude
- Status: accepted (the bundle identifier needs Moe)
- Decision: Three package targets: `PantryScoring` (engine and content), `PantryGame` (the round as plain values: ladder, round state, cues, synth; no UI frameworks) and `PantryUI` (SwiftUI, SpriteKit, AVAudioEngine). `App/Pantry.xcodeproj` holds one Swift file and the asset catalog and links `PantryUI`. iPhone only, portrait only, iOS 17.
- Rationale: Rules that live in `PantryGame` are tested by `swift test` and can be compiled in the cloud session. Adding a source file never touches the hand-written project file.
- Consequences: The bundle identifier is `ai.skasiehi.pantry`, a placeholder. Moe names the real one and the Apple team before TestFlight (PB-006).

## PD-018: CI builds the app, plays a scripted round and publishes what it saw
- Date: 2026-10-07
- Made by: Claude
- Status: accepted
- Context: The cloud session can't run Xcode or a simulator, and can't download workflow logs or artifacts.
- Decision: One CI job: `swift build`, `swift test`, an iOS Simulator build of the app, then `scripts/ci-screenshots.sh` launches it on an iPhone 16 and an iPhone SE, plays a scripted round (`-pantryDemo`) and screenshots it. The last step force-pushes that run's logs and screenshots to the `ci-output` branch. App work goes through pull requests.
- Rationale: A green build says the code compiles. A screenshot says the screen fits an SE and the round plays. The branch is the only channel the cloud session can read.
- Consequences: `ci-output` is rewritten every run and holds nothing else. The workflow has `contents: write` for that push. The demo script ships in the app, muted and inert without its launch argument.

## PD-019: PB-002 ships one vessel; the vessel choice is PB-008
- Date: 2026-10-07
- Made by: Claude
- Status: accepted
- Context: The backlog scopes PB-002 to "one wok". Mouth-watering chicken is a pot dish, so in the wok it tops out at 94.
- Decision: Keep the scope. `Round.vessel` exists and defaults to the wok; choosing a vessel (wok or pot, with the flame click the brief asks for) is PB-008, ahead of the session loop.
- Rationale: The scene had to be proven with one vessel first. A test pins the list of dishes the wok shortchanges to exactly that one.

## PD-020: The palette order is shuffled per round
- Date: 2026-10-07
- Made by: Claude
- Status: accepted
- Decision: `Round` shuffles the profile's palette with a seeded generator. The app seeds randomly; tests and the CI demo fix the seed.
- Rationale: Profiles list real ingredients first and decoys last. Shown in that order, the bottom row of the palette is the answer key.

## PD-021: Ingredients carry a short name, and no label says where an ingredient is from
- Date: 2026-10-07
- Made by: Claude
- Status: accepted
- Context: The first simulator screenshots showed palette chips breaking words ("Cornstarc-h") and truncating ("Fermente-d black..."). One decoy was labelled "Hunan chopped salted chilies (duojiao)".
- Decision: `Ingredient.shortName` (optional) is what a chip shows; validation requires it whenever `name` is over 22 characters. Twenty-two ingredients have one. Duojiao's name drops "Hunan". A test fails if any label names a cuisine or country.
- Rationale: A chip has room for two short lines. Telling Sichuan from Hunan is the lesson (brief, "Decoy design"), so the label can't do it for the player.
- Consequences: The field is optional and additive, so `schemaVersion` stays 1. Closes PB-105.

## PD-022: UI tests drive the real screen on CI
- Date: 2026-10-07
- Made by: Claude
- Status: accepted
- Context: Drag-and-drop is PB-002's headline, and the cloud session can't touch a phone.
- Decision: `App/PantryUITests` runs on an iPhone 16 simulator in CI: drag a chip into the wok, drop one outside it, tap to add, step the amount, switch between ingredients, pick a method, serve, take an ingredient out.
- Rationale: It proves the gestures work. It can't say whether they feel good; that stays with Moe.
- Outcome (2026-10-07): on its first run it caught that no drop ever landed: drags were tracked, but the wok's frame never reached the drag handler. Fixed the same day. The build had been green and the screenshots looked right.

## PD-023: A browser stand-in so Moe can play a round from his phone
- Date: 2026-10-07
- Made by: Moe, on Claude's offer (new scope, accepted knowingly)
- Status: accepted
- Context: The iOS app needs Xcode 15 and a Mac that can run it. Moe's Mac wasn't reachable and may be too old; the new laptop is weeks out. Without a way to play, PB-002 can't be reviewed.
- Decision: `web/` holds a one-page stand-in: a JavaScript port of the scorer and the stepper (`web/engine.js`), the same bundled Sichuan content inlined at build time (`scripts/build-web-standin.py`), tap or drag into a canvas wok, the method tap, synthesised cues with visual twins. Published as a private Claude artifact, "Pantry Stand-in".
- Rationale: It answers two of the review questions today: does a round fit 60 to 120 seconds, and do the scores feel fair. The score sheet shows how long the round took, which the app never will (no timers).
- Consequences: It is not the product. Drag feel, sound and the wok are approximations, and it must never be mistaken for a web version (the brief is native iOS only). The Swift engine stays the source of truth: `web/test-engine.cjs` runs the port against the same goldens on CI, so the two can't drift silently. Delete `web/` once the app is on TestFlight.

## PD-024: Every dish opens with a one-line brief that describes the plate, not the recipe
- Date: 2026-10-07
- Made by: Moe raised the gap playing the stand-in; Claude proposed the rule; Moe accepted it
- Status: accepted
- Context: A player who has never eaten mapo tofu has nothing to aim at, so the score reads as arbitrary.
- Decision: `DishProfile.brief`, one line of at most 120 characters, shown under the dish name before cooking in the app and the stand-in. It describes texture, look and how the dish should taste, and may name what the dish's own name names (or its main body in plain words). It never names a seasoning, an amount, a vessel or a method. Validation requires it and rejects digits; a test rejects seasoning and method words.
- Rationale: The brief gives the target ("hot, numbing and deeply savoury"); finding what delivers it is still the round.
- Consequences: Ten briefs written by Claude, for chef review with the profiles (PB-013). The field is optional in the schema and required by validation, so `schemaVersion` stays 1. Closes PB-009. The brief costs the wok a little height on small phones (PB-108).

## PD-025: Two modes: Pantry (ingredients only) and Kitchen (the full round)
- Date: 2026-10-07
- Made by: Moe raised it (amounts are a lot to ask of a beginner, and recipes disagree on them); Claude argued for two modes over three levels; Moe: "two is probably fine"
- Status: accepted (direction; not built)
- Context: The round built in PB-002 asks for ingredients, amounts and a method at once. Moe's worry after playing: choosing amounts is tricky for a first-timer, especially when cookbooks differ.
- Decision: Two modes, working names Moe can change.
  - **Pantry**: pick what belongs. No amounts, no method, about thirty seconds a round. The score is a count, not a percentage: how many of the dish's ingredients you found, out of how many there are, plus a plain list of what you missed and what you added that doesn't belong.
  - **Kitchen**: the full round as built, with amounts and a method, scored out of 100.
- Rationale: The modes ask different questions (recognition, then proportion and technique), which is a truer split than easy, medium and hard. A count is a score the player can act on: "7 of 10" says three things are missing and the sheet names them. An 81 is a verdict, and a verdict that feels wrong (PB-023) teaches nothing. The scorer already separates ingredients, ratios, flavour and technique, so Pantry is a new round type and score sheet, not a new engine.
- Amended 2026-10-07 (Moe, after playing): the pick limit is the essentials plus three, not plus two.
- Amended again 2026-10-07 (Moe, with Claude agreeing): the pick limit is exactly the number of essentials. Spare picks made the count mean two things and put two numbers side by side ("find the 6" next to "0 of 9 picks"). Cost, accepted: a good but inessential pick now uses a slot an essential needed, so "not wrong, just not essential" has to be said clearly, and a third aromatic costs a slot. Taking a pick out stays free.
- Consequences: Pantry is PB-015. It must not be brute-forceable by adding every chip: cap how many can go in, since lives are ruled out (brief: no lives). PB-023 (Kitchen scores too forgiving) is not solved by this; it stays open and comes before the judge line. The vessel choice (PB-008) belongs to Kitchen only.

## PD-026: Progression is two brigade ladders, earned by consistency
- Date: 2026-10-07
- Made by: Moe (titles for consistent scores; build them on the traditional brigade; a separate ladder per mode); Claude (shape, rungs, ordering)
- Status: accepted (direction; not built)
- Decision: A title is earned by holding a level across the last five rounds, not by one good dish. Each mode has its own ladder, named from the kitchen brigade:
  - Pantry: commis, chef de partie, sous chef.
  - Kitchen: the same rungs and one more, chef de cuisine.
  - Executive chef is held back until there is more than one cuisine.
  - Three or four rungs per ladder, no more: a title only means something if it is rare.
- Rationale: A rolling five rewards knowing the food over getting lucky, and gives a reason to keep playing once every dish has been seen. Separate ladders keep a title honest about what the player knows: finding ten of ten ingredients is not the same skill as holding 90 on proportions.
- Consequences: Thresholds are open (Moe's examples: 80 over five for the first rung, 90 for the next). A title, once earned, is kept: taking one away would be streak shaming, which the brief rules out (Claude's call; say so if you disagree). What each rung should mean is a question for the chef reviewer. Built as PB-016, after the judge line (PB-003) and the scoring fix (PB-023): a badge on a score nobody trusts is decoration.

## PD-027: Kitchen scoring: ratios carry more, and anything that doesn't belong sets a ceiling
- Date: 2026-10-07
- Made by: Claude (Moe asked to test "the scoring fix" in the stand-in; his verdict on how it feels is pending)
- Status: accepted, pending Moe's play. Supersedes the point split in the brief and PD-008's 3x threshold.
- Context: PB-023. Two rounds scored as near-good with real mistakes in them: a mapo tofu with 25 g of basil and no chili (88), and 100 g of tofu drowned in seasoning with all four ratios too high (81). A cup of cream in an otherwise perfect mapo tofu scored about 85. A score that says "good" to those teaches nothing.
- Decision: three changes.
  1. **Point split 30/45/15/10** (was 40/35/15/10): ten points move from ingredients to ratios. Pantry mode now asks what belongs; Kitchen is about proportion.
  2. **Ratio credit reaches zero at 2.5x off** (was 3x). "Present, but wrong amount" (PD-008) follows the same threshold.
  3. **A ceiling for things that don't belong.** Any off-cuisine or forbidden-for-the-dish ingredient caps the total: at 79 for a trace, falling in a straight line to 50 when such ingredients are a fifth of the dish by weight. `ScoreBreakdown.cappedAt` is set when the ceiling is what lowered the total, and the sheet says so, because the four parts then add up to more.
- Rationale: "Good" starts at 85, so the rule is one a player can hold in their head: nothing that doesn't belong, and the proportions right. The penalties inside the ingredients part (PD-005) stay as they were; the ceiling does what they could not without pushing neighbour-cuisine attempts to zero. Considered and dropped: a large flat penalty for the first wrong ingredient (it put one neighbour attempt below its off-cuisine twin), and taking penalties off the total (neighbour attempts fell to single digits).
- Consequences: basil mapo 88 to 74; drowned tofu 81 to 72; a pinch of basil in a perfect mapo 95 to 78; a cup of cream in it to 50. Every golden stays in its range and none moved more than 5 points; all good attempts still score 100. Still forgiving, on purpose left for Moe's ear and the chef: a perfect mapo without any chili scores 96 (chili heat is weighted 1 of 10), and five times the doubanjiang with ten times the sugar scores 77.
- Amended 2026-10-07 (Moe, after playing: 74 for the basil mapo was "still a little kind, but close"): the ceiling now reaches 50 at a tenth of the dish, not a fifth. Basil mapo 74 to 69; a little basil in a perfect mapo 78 to 77; a tablespoon of sesame paste in it 76 to 73. No golden moved.
- Also: the Swift engine and the stand-in's JavaScript port are now held to one file of exact results (`Tests/PantryScoringTests/Fixtures/parity.json`: 34 scored attempts, 40 Pantry verdicts), asserted by `ParityTests` and by `web/test-engine.cjs`.

## PD-028: Every ingredient says what it tastes like and what it does
- Date: 2026-10-07
- Made by: Moe (players won't know doubanjiang; suggested a pop-up on first selecting an ingredient); Claude (the rule, and a strip in place of a pop-up)
- Status: accepted; the strip-not-pop-up call is Claude's and open to Moe's objection
- Decision: `Ingredient.about`, one line of at most 110 characters for all 65 ingredients: taste, texture and what it does in the pan ("Fermented broad bean and chili paste. Salty, deep and hot. Fried in oil first, until the oil turns red."). It never names a cuisine, a country or a dish. Required by validation; a test rejects cuisine words and dish names.
- How it shows: touching a chip puts its note in a strip above the palette at once. Holding the chip still reads the note without adding it; a quick tap or a drag adds as before.
- Rationale: A pop-up on first touch would sit between the finger and the wok, in a round meant to take thirty seconds, and it would stop being available after the first time, which is when a learner needs it again. The strip costs nothing to ignore and is there on every touch. Decoys get the same plain treatment as everything else, so the note never marks one out.
- Consequences: Notes are Claude's writing and go to the chef with the profiles (PB-013). The strip costs height: on a short phone the round screen now scrolls, with the wok pinned (PB-108). In the stand-in now; the app shows it when the Pantry screen is built (PB-015).

## PD-029: The score sheet ends with a real recipe
- Date: 2026-10-07
- Made by: Moe (the sheet should list an actual recipe with amounts and process after the scoring explanation); Claude (shape, and two objections recorded below)
- Status: accepted for the stand-in; **two questions open for Moe before it goes into the app**
- Decision: `DishProfile.recipe`: serves, vessel, method, amounts and three to seven steps. Shown on the score sheet after the verdict, in both modes, never before serving. Ten recipes written by Claude. Each recipe's amounts are the dish's known-good reference attempt, and content validation scores every recipe against its own profile: a recipe that the game would not call good fails the build.
- Rationale: The verdict says what was off; the recipe shows what right looks like, with the process the round can't teach. Tying the recipe to the scorer means the game never teaches one thing and scores another.
- Objections (Claude, once, for the record):
  1. **This is most of "Cook It Tonight", which the brief makes the first paid feature** ($3.99 a month): "turn any attempt into a real recipe with quantities, steps, and a shopping list". A reference recipe free on every score sheet leaves the paid feature with the shopping list, scaling and export. That may be the right trade (the free recipe is the proof people cook what the game taught), but it is a pricing decision and Moe's to make.
  2. **It works against "one judge line, one card, per round"** and the under-60-word card in the brief. A recipe is 150 to 200 words. In the stand-in it sits at the end of a scrolling sheet with the buttons pinned, so it costs nothing to skip; whether it replaces the card (PB-004) or sits beside it is open.
- Consequences: Recipes go to the chef with everything else (PB-013); they are the most checkable thing in the content. `RecipeText` formats amounts ("2½ tbsp") and is tested. Not yet on the app's score sheet.

## PD-030: The recipe is free to see; keeping and using it is Cook It Tonight
- Date: 2026-10-07
- Made by: Moe, on Claude's proposal
- Status: accepted. Settles the first open question in PD-029. Moe wants to revisit whether seeing the recipe stays free; it stays free for now.
- Decision: Free: the recipe appears on the score sheet after a round. Paid (Cook It Tonight): save it to a recipe list, shopping list, scale the servings, export.
- Rationale: The free recipe proves the game teaches real cooking. The paid step is keeping and using what was learned.
- Consequences: A screenshot gets a free player the recipe, so the saved list has to be worth more than a screenshot: the shopping list and scaling carry that. Saving is PB-019. Still open from PD-029: whether the recipe replaces the 60-word card or sits beside it.

## PD-031: The round screen is layout B, with layout C for Pantry on small phones
- Date: 2026-10-07
- Made by: Moe, from three options Claude put on the "Pantry Round Screen" design canvas (PB-025). Claude recommended B; the small-phone exception is Moe's and Claude agrees with it.
- Status: accepted. Spec for the app's Pantry screen (PB-015) and for the Kitchen screen when it is next touched. The stand-in follows it.
- Decision:
  - **Both modes, every size:** the mode switch sits in the header row with start-over and sound. The dish name, cuisine and brief live inside the wok's panel. Four-column palette, serve button at the bottom, nothing scrolls on a 375 × 667 screen.
  - **Pantry, regular phones (B):** "Pick the N essentials" with N dots that fill, inside the panel. The ingredient note is a dark callout floating over the bottom of the panel while a chip is touched and for a moment after.
  - **Pantry, small phones (C):** the ask is a full sentence in the panel, the count rides on the serve button ("Serve it · 3 of 6"), and the ingredient note is a fixed strip between the panel and the palette.
  - **Kitchen, every size (B):** the amount stepper sits in the bottom of the panel and the six methods are one row of 44-point buttons. On small phones the brief is one line and the stepper is one row with a × for take-out.
- Rationale: A (today's stack) is 133 points too tall on a small phone and spends four rows before the wok. B puts what the round is about next to the wok. On a small phone the panel is short, so B's floating note covers the wok just as the player is looking at it; C's strip doesn't.
- Consequences: Two placements for the note and the count, switched on screen height (the stand-in uses 700 points). The small-phone stepper's × has no words, which goes against "say Take out in words" from PB-015: it keeps the accessibility label and is the one exception, for width. Placeholder art only; art direction stays with PB-011.
