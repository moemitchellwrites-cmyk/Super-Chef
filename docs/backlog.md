# Pantry: Backlog

## Next session: open with this
1. PB-002 is built and in review (pull request #1): CI is green: it plays a scripted round on an iPhone 16 and an iPhone SE simulator, and UI tests drag, tap, step and serve. It is **not done** until Moe has played a round on a phone: see "PB-002: what's left" below.
2. Needed from Moe: play it (Xcode 15 or newer, open `App/Pantry.xcodeproj`, run on an iPhone or a simulator), then say what feels wrong. Name the bundle identifier and Apple team (PD-017).
3. Then PB-008 (vessel choice) and PB-003 (canned judge line).

### PB-002: what's left
- [ ] Moe plays a round on a real phone: drag and tap both feel right, a round fits 60 to 120 seconds one-handed, the sounds are tolerable as placeholders. Nothing in CI can judge these.
- [ ] Moe's review of PD-012 to PD-022 (all Claude's calls).

Ordered by priority. New requests go to the **Parking lot** unless Moe trades out existing scope.

Item format: `- [ ] PB-NNN: <title>: <outcome>`

## MVP (brief, build order)
- [ ] PB-002: Vessel scene: one wok, drag-and-drop ingredients, amount stepper, a one-tap cooking method (PD-007), placeholder sounds. Ugly is fine. **Built 2026-10-07, in review (PR #1); awaiting Moe's hands on a phone.**
- [ ] PB-008: Vessel choice: wok or pot, one tap, with the flame click. Mouth-watering chicken is a pot dish and tops out at 94 in the wok (PD-019). Before PB-005.
- [ ] PB-003: Canned judge line from the score breakdown (`ScoreBreakdown.misses` and `pattern`). No LLM yet.
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
- [ ] PB-023: Should an off-cuisine ingredient cap the score? The CI demo round is a sound mapo tofu with 25 g of basil and no chili, and it scores 88, above the "good" line. Needs Moe's ear and then the chef's (found building PB-002).
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
- [x] PB-105: Short ingredient names that fit a chip and don't name the ingredient's home (2026-10-07, PD-021; found and fixed inside PB-002).
- [x] PB-007: Split into its own repository with history (2026-10-07): Moe created `moemitchellwrites-cmyk/Super-Chef`; history pushed, own CI green, own CLAUDE.md, pointer left in Studio-Companion.
- [x] PB-001: Scoring module with golden tests (2026-10-07; CI green; chef review of profiles and potencies stays open under PB-013).
- [x] PB-020: PD-008 amendment: half coverage credit for a present-but-grossly-off family (2026-10-07).
