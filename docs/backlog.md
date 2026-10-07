# Pantry: Backlog

## Next session: open with this
1. PB-001 is built and pushed; check CI (`pantry (Swift, macOS)`) is green. If not, fix from the log.
2. Moe to decide: PD-002 (own repository before step 2), PD-007 (method tap in the round), PD-008 (score composition amendment), and approve the definition of done.
3. Then PB-002, the vessel scene.

Ordered by priority. New requests go to the **Parking lot** unless Moe trades out existing scope.

Item format: `- [ ] PB-NNN: <title>: <outcome>`

## MVP (brief, build order)
- [ ] PB-001: Scoring module with golden tests. Built 2026-10-07: `PantryScoring` package, ten Sichuan profiles, 65 ingredients, 31 goldens, invariants, content validation. Open: CI green; Moe's review; chef review of profiles and potencies.
- [ ] PB-002: Vessel scene: one wok, drag-and-drop ingredients, amount stepper, placeholder sounds. Ugly is fine.
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
- [ ] PB-020: PD-008 amendment if Moe accepts: half coverage credit for a present-but-grossly-off family.
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
- (none yet)
