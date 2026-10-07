# Pantry: Backlog

## Next session: open with this
1. PB-001 is done (CI green, PD-008 amendment in). Moe accepted PD-002, PD-007, PD-008 and the definition of done on 2026-10-07.
2. PB-007: the split into its own repository (PD-002). Once it is done, start sessions from that repository, not this one.
3. Then PB-002, the vessel scene, with the method tap (PD-007).

Ordered by priority. New requests go to the **Parking lot** unless Moe trades out existing scope.

Item format: `- [ ] PB-NNN: <title>: <outcome>`

## MVP (brief, build order)
- [ ] PB-007: Split `pantry/` into its own repository with history (PD-002): own CI, own CLAUDE.md, pointer left in Studio-Companion.
- [ ] PB-002: Vessel scene: one wok, drag-and-drop ingredients, amount stepper, a one-tap cooking method (PD-007), placeholder sounds. Ugly is fine.
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
- [ ] PB-022: A second cuisine's content to prove the schema isn't Sichuan-shaped (Japanese home cooking: 1:1:1 soy, mirin, sake is a clean ratio test).

## Parking lot
- [ ] PB-100: Units shown to US players (cups and spoons) versus weight everywhere. Engine is weight-based (PD-003); this is display only.
- [ ] PB-101: Judge voice: one persona or one per track.
- [ ] PB-102: Which chef first, and through whom.
- [ ] PB-103: Cook It Tonight on-device from the profile, or via the backend.
- [ ] PB-104: Name for the game.
- Declined for MVP (brief): accounts, social, leaderboards, multiplayer, recipe import, user-generated dishes, Android.

## Done
- [x] PB-001: Scoring module with golden tests (2026-10-07; CI green; chef review of profiles and potencies stays open under PB-013).
- [x] PB-020: PD-008 amendment: half coverage credit for a present-but-grossly-off family (2026-10-07).
