# Pantry: Backlog

## Next session: open with this
1. PB-002 is built and in review (pull request #1): CI is green: it plays a scripted round on an iPhone 16 and an iPhone SE simulator, and UI tests drag, tap, step and serve. It is **not done** until Moe has played a round on a phone: see "PB-002: what's left" below.
2. Needed from Moe: play it. From a phone today: the browser stand-in (PD-023, the "Pantry Stand-in" artifact) for round length and scoring feel. For drag, sound and the wok: Xcode 15 or newer, open `App/Pantry.xcodeproj`, run on an iPhone or a simulator. Then say what feels wrong. Name the bundle identifier and Apple team (PD-017).
3. In Moe's hands now, in the stand-in: Pantry mode (PB-015, rules built and tested; app screen not built) and the Kitchen scoring fix (PD-027, closes PB-023 if it feels right). Needed from Moe: play both and say what feels wrong.
4. Then: the Pantry screen in the app (rest of PB-015), PB-008 (vessel choice), PB-003 (canned judge line).
5. The real app can't run on either of Moe's current Macs (Mac Pro on Catalina; MacBook Pro Early 2015 tops out at macOS 12, Xcode 14.2, iOS 16). It waits for the new laptop, or for TestFlight from CI, which needs an Apple Developer account (PB-006). The stand-in is the review tool until then.

### PB-002: what's left
- [ ] Moe plays a round on a real phone: drag and tap both feel right, a round fits 60 to 120 seconds one-handed, the sounds are tolerable as placeholders. Nothing in CI can judge these.
- [ ] Moe's review of PD-012 to PD-022 (all Claude's calls).

Ordered by priority. New requests go to the **Parking lot** unless Moe trades out existing scope.

Item format: `- [ ] PB-NNN: <title>: <outcome>`

## MVP (brief, build order)
- [ ] PB-002: Vessel scene: one wok, drag-and-drop ingredients, amount stepper, a one-tap cooking method (PD-007), placeholder sounds. Ugly is fine. **Built 2026-10-07, in review (PR #1); awaiting Moe's hands on a phone.**
- [ ] PB-015: Pantry mode (PD-025): an ingredients-only round, about thirty seconds, no amounts or method. Scored as a count ("4 of 6 essentials found"), with what was missed, what doesn't belong and what belongs but isn't essential named. Picks are limited to the essentials plus three (Moe's call after playing), so it can't be brute-forced. **Rules built and tested (`PantryRound`, `PantryJudge`) and playable in the stand-in, 2026-10-07. Left: the Pantry screen in the app, including the ingredient note strip (PD-028), hold-to-read, and an obvious way to take a pick back out (Moe played the stand-in and didn't find tap-again: picked chips now wear a × and the bar says so; the app's Kitchen stepper should say "Take out" in words, not only show a bin).**
- [ ] PB-008: Vessel choice: wok or pot, one tap, with the flame click. Mouth-watering chicken is a pot dish and tops out at 94 in the wok (PD-019). Before PB-005.
- [ ] PB-003: Canned judge line from the score breakdown (`ScoreBreakdown.misses` and `pattern`). No LLM yet.
- [ ] PB-016: Brigade ladders (PD-026): a title earned by holding a level over the last five rounds, one ladder per mode (Pantry: commis, chef de partie, sous chef; Kitchen adds chef de cuisine). Titles are kept once earned. Thresholds and what each rung means are open; ask the chef. After PB-003 and PB-023.
- [ ] PB-004: Ten cards, one per dish, shown on submit. Card ids are already in the profiles.
- [ ] PB-005: Session loop: five rounds, summary screen, local progress (SwiftData).
- [ ] PB-006: TestFlight to 20 people; measure session completion, day-two return, lowest-scoring dishes.

## After MVP (brief, step 7)
- [ ] PB-010: LLM judge behind a thin proxy, cached by (dish id, pattern). Never ship the key in the app.
- [ ] PB-011: Art and real sound (Moe's recordings through the studio chain).
- [ ] PB-012: StoreKit 2: Cook It Tonight, one-time tracks, All Access.
- [ ] PB-013: First paid track (Sichuan, 40 lessons) and chef review.
- [ ] PB-014: Content manifest with signed remote updates (`schemaVersion` is already in every file).

## Engine follow-ups
- [ ] PB-021: Free-cook scoring (lessons 37 to 40): score an attempt against the cuisine with no dish named. Needs a cuisine-level profile.
- [ ] PB-023: **Fix in for Moe's test (PD-027); close when he says it feels right.** Should an off-cuisine ingredient cap the score? The CI demo round is a sound mapo tofu with 25 g of basil and no chili, and it scores 88, above the "good" line. Needs Moe's ear and then the chef's (found building PB-002). Second case, from the stand-in: 100 g of tofu with every seasoning at its starting amount is "too much" on all four ratios and still scores 81.
- [ ] PB-022: A second cuisine's content to prove the schema isn't Sichuan-shaped (Japanese home cooking: 1:1:1 soy, mirin, sake is a clean ratio test).

## Parking lot
- [ ] PB-100: Units shown to US players (cups and spoons) versus weight everywhere. Engine is weight-based (PD-003); this is display only.
- [ ] PB-101: Judge voice: one persona or one per track.
- [ ] PB-102: Which chef first, and through whom.
- [ ] PB-103: Cook It Tonight on-device from the profile, or via the backend.
- [ ] PB-104: Name for the game.
- [ ] PB-106: Accessibility pass on the round screen: Dynamic Type (the palette uses fixed sizes to fit twenty chips), Reduce Motion, a VoiceOver walk-through. Labels and actions are in; nobody has listened to it yet.
- [ ] PB-108: Small phones. On an iPhone SE the layout fits but the wok shrinks to about half the screen's width. Decide whether that is good enough or the round screen needs a compact layout.
- [ ] PB-107: A sizzle bed that loops under the one-shots once the burner is lit (brief: "a sizzle loop plus one-shot adds"). Belongs with the real sound (PB-011).
- Declined for MVP (brief): accounts, social, leaderboards, multiplayer, recipe import, user-generated dishes, Android.

## Done
- [x] PB-009: A one-line dish brief before cooking (2026-10-07, PD-024; built and tested, in the app and the stand-in; rides in the PB-002 pull request).
- [x] PB-105: Short ingredient names that fit a chip and don't name the ingredient's home (2026-10-07, PD-021; found and fixed inside PB-002).
- [x] PB-007: Split into its own repository with history (2026-10-07): Moe created `moemitchellwrites-cmyk/Super-Chef`; history pushed, own CI green, own CLAUDE.md, pointer left in Studio-Companion.
- [x] PB-001: Scoring module with golden tests (2026-10-07; CI green; chef review of profiles and potencies stays open under PB-013).
- [x] PB-020: PD-008 amendment: half coverage credit for a present-but-grossly-off family (2026-10-07).
