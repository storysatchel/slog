---
title: Audition Gloss Punctuation and #CAP Convention
category: project
tags: [compiler-design, linguistics, decision]
sources:
  - conversation:2026-07-23
created: 2026-07-24T02:15:28Z
updated: 2026-07-24T02:15:28Z
summary: >-
  Kisangani .md.au glosses must carry real punctuation and Audition's built-in #CAP tag directly in the source; downstream reconstruction is the wrong layer.
provenance:
  extracted: 0.9
  inferred: 0.1
  ambiguous: 0.0
base_confidence: 0.8
lifecycle: draft
lifecycle_changed: 2026-07-24
---

# Audition Gloss Punctuation and #CAP Convention

## Context

The compiled Kisangani text (visible on the site, and fed to TTS narration)
was, until this fix, entirely lowercase and unpunctuated everywhere. The
symptom first showed up in TTS audio — narration ran signage lines together
with no pause and no capitalization — but the audio wasn't the actual bug;
the same flat, unpunctuated text was already sitting on every compiled HTML
page.

## Decision / Finding

Audition (`tools/audition/`) already has a documented, built-in convention
for this, evidenced by its own README and test fixtures
(`tools/audition/test-language/sample.md.au`):

- **Literal punctuation** — periods, commas, colons, `!`, `?` — are typed
  directly into the `.md.au` gloss stream between/after word tags, e.g.
  `__1SG#CAP ^Arwen. come#1SG 2ACC help#INF.__`. They pass through untouched
  as literal text in the compiled output.
- **`#CAP`** is a built-in inflection (`tools/audition/src/morphology.ts`,
  `CAP: capitalize`, always registered) that capitalizes a word's *rendered*
  output. Applied via the normal `#TAG` stacking mechanism, and inflections
  apply left-to-right, so `#CAP` must be the *last* tag in a stack (e.g.
  `record#CL9#CAP`) to capitalize the word *after* other inflections (like
  class prefixing) have already been applied.

None of the 35 Kisangani `.md.au` files used either convention. Fixed by
adding `#CAP` to the first word of every sentence/span and literal terminal
punctuation to every span lacking its own, across all of them.

## Reasoning

Reconstructing punctuation/capitalization downstream (originally attempted
in the TTS text-extraction script, treating each markdown line as a
sentence) only ever fixed the *audio*, not the actual compiled/visible text
on the site — the real bug was that the source never used Audition's own
authoring convention in the first place. Fixing it at the source layer means
every consumer (site HTML, audio, any future export) gets it for free,
instead of needing its own reconstruction heuristic.

## Implications / Open Issues Found Along the Way

Applying this fix required distinguishing real sentence-ending punctuation
from **pre-existing typos already in the source** that just happen to look
similar — these were deliberately left untouched rather than "fixed" by
guessing:

- **`#CL9.ASSOC` instead of `#CL9#ASSOC`** — a `.` used where `#` was
  clearly intended, breaking Audition's tag-chain parsing for that suffix.
  Widespread across `Hazard_Markings` (`ceramic_storage_label`,
  `erika_sanctuary_intake`, `quarantine_breach_warning`,
  `research_site_seal`, `warp_relay_radiation_warning`).
- **Severe lexicon-coverage gaps**, visible as `(word??)` untranslated
  fallback markers in compiled output — far worse than `Hazard_Markings`
  alone: `retinalia_proxy_clash` (135 fallbacks), `un_decree_resolution_884`
  (121), `kisangani_trade_agreement` (120), `solar_confederation_transit_form`
  (111), `salusa_customs_quarantine` (75). These are lexicography gaps, not
  build-pipeline bugs — a separate, much larger cleanup task than punctuation.

## Related
- [[projects/slog/dev/dev]]
- [[synthesis/audition-conlang-compiler-decolonial-rule-design]]
- [[synthesis/audition-compiler-morphology-workarounds]]
