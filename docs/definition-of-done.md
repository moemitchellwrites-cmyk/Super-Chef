# Pantry: Definition of Done

- Status: **PROPOSED** by Claude, 2026-10-07. Needs Moe's approval.

Nothing is marked complete until every item that applies is met.

## Every change
- [ ] Delivers the backlog item it names and meets its acceptance criteria.
- [ ] `swift build` and `swift test` pass on CI (macOS). The cloud session can't compile Swift; a change isn't done until CI says so.
- [ ] Tests cover the new behaviour, including failure cases.
- [ ] Docs updated: backlog, decisions (with who made the call), README if layout or commands changed.
- [ ] No API key, secret or analytics SDK in the app. The judge proxy is the only network call, and it degrades to a canned line offline.

## Scoring engine
- [ ] Deterministic: no clock, randomness or I/O inside `Scorer`.
- [ ] Golden tests pass: every dish has a good attempt (85+), an off-cuisine attempt (under 40) and a neighbour-cuisine attempt (between, and above the off-cuisine one). Scores are invariant to scaling all amounts.
- [ ] A scoring change that moves any golden by more than 5 points is called out in the commit and the decisions log.

## Content (profiles and cards)
- [ ] Every profile names two or three reference sources in `notes`.
- [ ] `ContentLibrary.validate()` returns no problems: every family, id and palette entry resolves; palettes have 12 to 20 entries with decoys from a neighbouring cuisine and from inside the cuisine.
- [ ] The good attempt is buildable from the palette alone.
- [ ] Cards are under 60 words: title, two to four sentences, one plain rule, one "try this tonight".
- [ ] Before a track ships: reviewed by a named chef, and the goldens updated from their red pen.

## Game and UX
- [ ] A round completes in 60 to 120 seconds on a phone, one-handed.
- [ ] Every sound cue has a visual twin; the game is playable muted.
- [ ] No timers, lives or streak shaming.

## Privacy
- [ ] No account, no email. Attempts reach the judge proxy anonymously, without device identifiers beyond what rate limiting needs.
