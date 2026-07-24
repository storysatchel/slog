---
title: SLOG Dev & Build Tooling
category: project
tags: [meta, build-tooling, ci-cd]
sources:
  - conversation:2026-07-23
created: 2026-07-24T02:15:28Z
updated: 2026-07-24T02:15:28Z
summary: >-
  Index for meta/development knowledge about the SLOG repo itself — build pipeline, CI, and tooling decisions — distinct from Kisangani worldbuilding content.
provenance:
  extracted: 1.0
  inferred: 0.0
  ambiguous: 0.0
base_confidence: 0.5
lifecycle: draft
lifecycle_changed: 2026-07-24
---

# SLOG Dev & Build Tooling

[[projects/slog/slog]] is split into two kinds of knowledge: the Kisangani
story world and its computational linguistics (worldbuilding, under
`projects/slog/concepts/`), and knowledge about how the *repo itself* is
built, tested, and deployed. This page indexes the latter — the meta/
development-focused section.

## Pages

- [[projects/slog/dev/kisangani-audio-pipeline-architecture]] — why TTS
  synthesis and audio embedding are two separate build steps, and the
  `patch-package`/Makefile-glob bugs found while building the pipeline.
- [[projects/slog/dev/audition-gloss-punctuation-and-cap-convention]] — the
  correct Audition authoring convention for punctuation and capitalization,
  and the pre-existing content bugs it surfaced.

## Related
- [[projects/slog/slog]]
- [[synthesis/audition-compiler-morphology-workarounds]]
