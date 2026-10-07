# Pantry: Project Overview

- Status: **DRAFT**, derived from the product brief (`brief.md`, Moe, 2026-10-06)
- Owner: Claude · Advisor/reviewer: Moe
- Date: 2026-10-07

## One line

A commute-length iOS game where you cook a dish by choosing ingredients and
amounts, and get scored on how well your choices fit the cuisine's grammar,
so you get better at real cooking.

## What's fixed by the brief

- Score against a cuisine profile, not a recipe. Deterministic, on-device,
  offline. The AI judge writes feedback; it never computes the score.
- One round is 60 to 120 seconds: vessel, palette of 12 to 20 ingredients
  with decoys, amounts as ratios, submit, score, one judge line, one card.
- Sound is a first-class feature with a visual twin for every cue.
- No ads, no accounts, no analytics beyond Apple's.
- MVP: one cuisine (Sichuan), ten dishes, scoring, sound, cards. TestFlight
  to 20 people answers one question: do people finish a session and come back?

## Build order (from the brief)

1. Scoring module with golden tests. **Done 2026-10-07.**
2. Vessel scene: one wok, drag-and-drop, amount stepper, method tap, placeholder sounds. **Built 2026-10-07**, in review; needs Moe's hands on a phone.
3. Canned judge line from the score breakdown.
4. Ten cards.
5. Five-round session and summary.
6. TestFlight.
7. LLM judge, art and real sound, StoreKit, first paid track.

## Where it lives

https://github.com/moemitchellwrites-cmyk/Super-Chef, its own repository
since 2026-10-07 (PD-002). It started under `pantry/` in Studio-Companion
and was split out with its history before the iOS app target.
