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
