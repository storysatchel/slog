---
title: Kisangani Audio Pipeline Architecture
category: project
tags: [build-tooling, ci-cd, audio, decision]
sources:
  - conversation:2026-07-23
created: 2026-07-24T02:15:28Z
updated: 2026-07-24T02:15:28Z
summary: >-
  TTS synthesis and audio embedding are deliberately separate build steps because edge-tts is an unofficial, network-dependent client CI must never rely on.
provenance:
  extracted: 0.85
  inferred: 0.15
  ambiguous: 0.0
base_confidence: 0.75
lifecycle: draft
lifecycle_changed: 2026-07-24
---

# Kisangani Audio Pipeline Architecture

## Context

The site embeds spoken Swahili-voice narration of each Kisangani sign
directly into its compiled HTML page, as a self-contained base64
`data:audio/mpeg;base64,...` `<audio>` element rather than a link to a
separate `docs/**/audio/*.mp3` file. This keeps each page fully
self-contained with no separate asset tree to keep in sync.

## Decision

The pipeline is split into two separate `Makefile` targets, backed by two
separate scripts, instead of one combined step:

- **`make narrate`** (`tools/synth_audio.sh`) — the only step that talks to
  the network. Calls `edge-tts` to synthesize narration for every compiled
  `src/<lang>/**/*.md`, writing the result as a sibling
  `src/<lang>/**/<stem>.mp3` **committed to git** alongside the source.
  Skips files that already have an `.mp3` unless `FORCE=1`.
- **`make audio`** (`tools/embed_audio.sh`) — purely offline. Reads the
  already-committed `.mp3`s and base64-embeds them into the built HTML. This
  is what the GitHub Actions deploy workflow runs (`.github/workflows/deploy.yml`),
  in place of `make build`.

## Reasoning

`edge-tts` is an unofficial, reverse-engineered client for Microsoft Edge's
internal, undocumented "Read Aloud" WebSocket service — not a supported
public API. It has a recurring history of breaking with `403` errors
whenever Microsoft changes an internal signing requirement, independent of
anything in this repo, and some evidence (not fully confirmed) suggests
datacenter/cloud IPs get blocked outright.^[inferred] Depending on it at
*build* time means the deploy pipeline's success depends on an
unauthenticated third-party service staying reachable — an unacceptable
dependency for CI. Committing the synthesized `.mp3`s and only ever
embedding them offline removes that dependency entirely from the deploy
path; synthesis becomes a manual, local step run only when gloss text
changes.

## Related Gotchas Found Building This

- **`python3 - <<PYEOF` inside a function silently eats piped stdin.**
  `python3 -` reads its *script* from stdin, so a heredoc passed that way
  consumes the heredoc as the program source — by the time the script's own
  `sys.stdin.read()` runs, stdin is already at EOF. A pipe like
  `cat file | strip_xml` (where `strip_xml` internally does
  `python3 - <<PYEOF`) silently returns an empty string, with no error.
  Fix: write the script to its own temp file, then `python3 "$SCRIPT"`,
  leaving stdin free for the actual piped input.
- **Never pass large data through argv when it can go through a file.**
  Base64-embedding an `.mp3` into HTML via a shell variable interpolated
  into `sed -i "s|...|${var}|"` risks exceeding `ARG_MAX` for large audio.
  `tools/embed_audio.sh` writes the base64 blob to a temp file via `base64
  ... > file` (pure I/O redirection, never touching argv) and passes the
  *file path* to a small Python injector, not the blob itself.
- **A blind `rm -f $dir*.md` glob is not safe cleanup.** `Makefile`'s
  `build`/`clean` targets deleted *any* `.md` file sitting directly in
  `src/<lang>/`, including the hand-authored `AGENTS.md` — every single
  `make build` silently deleted it, which is how it went missing before this
  session even started. Fixed by deriving deletion targets from existing
  `*.md.au` sources (`for auf in $(find $lang -name '*.md.au'); do rm -f
  "${auf%.au}"; done`) instead of a blind extension glob, so cleanup can
  never touch a file Audition didn't generate.
- **A hand-patched `node_modules` fix is invisible to CI.** `mdsite`'s page
  title/TOC extraction (`cheerio.text()` on the raw `<h1>`) pulled in hidden
  `<x-src>` gloss-tooltip text alongside the visible word, leaking English
  glosses into page titles on the deployed site — but not locally, because
  someone had already hand-patched the installed `node_modules` copy, a fix
  invisible to git and to CI's fresh `npm install`. Captured properly via
  `patch-package` (`patches/@benchristel+mdsite+0.9.0.patch`) plus a
  `postinstall` hook, so the fix reapplies on every install, including CI.

## Implications

Any future build-pipeline step that depends on an external, unauthenticated,
undocumented service should follow this same pattern: isolate it into a
manual/local-only step whose *output* gets committed, never let CI's success
path depend on the service being reachable at build time.

## Related
- [[projects/slog/dev/dev]]
- [[projects/slog/slog]]
- [[synthesis/audition-compiler-morphology-workarounds]]
