---
title: >-
  Audition Compiler Morphology Bug and Tag Adjustments
category: synthesis
tags: [compiler-design, linguistics, shona, troubleshooting]
sources:
  - conversation:2026-07-22
created: 2026-07-22T16:26:00Z
updated: 2026-07-22T16:26:00Z
summary: >-
  Identifies a period-parsing bug in the Audition compiler regex and details the morphological tag workarounds used to implement Shona tense and mood rules.
provenance:
  extracted: 1.0
  inferred: 0.0
  ambiguous: 0.0
base_confidence: 0.9
lifecycle: draft
lifecycle_changed: 2026-07-22
---

# Audition Compiler Morphology Bug and Tag Adjustments

## Context
When implementing the Bantu (Shona) grammatical framework for the Kisangani language in the Audition compiler, several morphological tags were defined to handle complex agglutinative structures, such as associative concords (`#CL5.ASSOC`), tense markers (`#TM`), and final vowels (`#FV.SUBJ`). The Audition compiler generated parsing errors when encountering tags containing periods.

## Finding / Decision
The Audition compiler's JavaScript regex splits input segments at punctuation boundaries, including periods (`.`). This causes tags like `#CL5.ASSOC` and `#FV.SUBJ` to be split into a tag and a loose string (e.g., `#CL5` and `.ASSOC`), breaking the grammatical generation.

The fix requires stripping all periods from morphological tag definitions:
1. `#CL5.ASSOC` must be written as `#ASSOC` or `#CL5ASSOC`.
2. `#FV.SUBJ` must be written as `#FVSUBJ`.

Additionally, proper implementation of the Shona finite verbal taxonomy requires the following sequence: Subject Prefix + Tense Marker + Radical + Extensions + Terminal Vowel.
1. **Present Indicative**: Requires the `#TM` tag (evaluating to `-no-`) inserted between the Subject Prefix and the radical to ground the verb temporally (e.g., *tinochengeta*).
2. **Subjunctive Mood**: Formal commands using subject prefixes require a shift from the indicative final vowel `-a` to the hortative `-e`. This is achieved using the `#FVSUBJ` tag (e.g., *vakomere*).

## Reasoning
The regex boundary parsing in Audition is hardcoded into `text.ts` and splitting on punctuation is intentional for isolating words. Rather than rewriting the compiler core, adjusting the tag nomenclature in `morphology.yaml` to avoid punctuation entirely circumvents the issue while preserving full grammatical capability.

The addition of `#TM` and `#FVSUBJ` ensures that the simulated language remains authentic to Shona syntactic rules, avoiding "translationese" and embedding the strict sociopolitical hierarchy directly into the grammatical structure.

## Implications
- Any new morphological tags added to `morphology.yaml` must consist strictly of alphanumeric characters without punctuation.
- Associative markers (which act as proclitics) should be implemented as separate tags (e.g., `#ASSOC`) rather than dotted sub-tags, maintaining concord agreement dynamically.

## Related
- [[concepts/shona-verbal-extension-stacking]]
- [[concepts/computational-decolonization]]
