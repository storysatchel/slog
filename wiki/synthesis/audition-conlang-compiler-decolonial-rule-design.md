---
title: >-
  Audition Conlang Compiler Rule Design for Decolonial Conlang Syntax
category: synthesis
tags: [conlang, audition, morphology, decolonial, linguistics]
sources:
  - conversation:2026-07-22
created: 2026-07-22T21:50:00-07:00
updated: 2026-07-22T21:50:00-07:00
summary: >-
  Architectural patterns for configuring the Audition conlang compiler to prevent pidginization and maintain Bantu morphosyntactic integrity.
provenance:
  extracted: 0.8
  inferred: 0.2
  ambiguous: 0.0
base_confidence: 0.95
lifecycle: draft
lifecycle_changed: 2026-07-22
---

# Audition Conlang Compiler Rule Design for Decolonial Conlang Syntax

## Context
During translation of English texts into Kisangani Basic via the Audition compiler, technical and administrative vocabulary often falls back to epenthetic phonological transliteration ("Shinglish" pidginization) if unmapped. Furthermore, naive tag attachment can cause double-prefixing or terminal vowel truncation.

## Finding / Decision
To enforce decolonial linguistic alignment and avoid pidginized output:
1. **Aggressive Lexicon Mapping**: All technical/administrative terms must be mapped to authentic Bantu roots (e.g. `safety` $\rightarrow$ `dziviriro`, `rules` $\rightarrow$ `mitemo`, `violator` $\rightarrow$ `paradzi`, `pass` $\rightarrow$ `mvumo`).
2. **Double-Prefix Prevention**: Noun class rules (`CL9`, `CL10`) in `morphology.yaml` must explicitly check if a root already carries an inherent class prefix (`ku-`, `mi-`, `m-`, `k-`) before applying prenasalization.
3. **Terminal Vowel Syllabilizers**: Passive (`PASS`), imperative (`IMP`), and final vowel (`FV`) rules must append vocalic nuclei (`-wa`, `-iwa`, `-ewa`, `-a`) to guarantee open-syllable phonotactics.

## Reasoning
Mechanically forcing Western vocabulary into Bantu C-V structures without semantic translation treats the indigenous language as a mere aesthetic costume for European thought. Ensuring proper morphological rules and authentic lexicon roots preserves the mathematical and relational logic of the Mupanda noun class system.

## Implications
- Keeps conlang translation outputs 100% clean of fallback `(??)` markers and English loanword ciphers.
- Maintains narrative consistency where Kisangani Basic grammatically reframes foreign coercive concepts (e.g., pejorative Class 21 `zikirediti` for currency and `kukuruva` for fines).

## Related
- [[concepts/shona-verbal-extension-stacking]]
- [[concepts/computational-decolonization]]
- [[synthesis/audition-compiler-morphology-workarounds]]
