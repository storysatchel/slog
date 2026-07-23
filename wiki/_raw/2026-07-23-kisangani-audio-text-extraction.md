---
title: "Kisangani audio pipeline: heredoc stdin bug and duplicated x-out/x-src stripping logic"
category: skills
tags:
  - topic/bash
  - topic/tts
  - project/kisangani
summary: "python3 - <<EOF heredoc consumes stdin before the script's own sys.stdin.read() runs; a second, independent text-extraction implementation in a skill has a related but different bug."
tier: supporting
related: []
extends: null
contradicts: null
superseded_by: null
capture_source: claude-session
project: "SLOG (Kisangani conlang wiki)"
base_confidence: 0.72
lifecycle: draft
lifecycle_changed: 2026-07-23
provenance:
  extracted: 0.85
  inferred: 0.15
sources:
  - "SLOG session (2026-07-23)"
---

# Kisangani audio pipeline: heredoc stdin bug and duplicated stripping logic

Two related findings from building a TTS audio pipeline (`tools/gen_audio.sh`) for the Kisangani
conlang wiki, which strips `<x-out>word<x-src>gloss</x-src></x-out>` markup out of compiled `.md`
files before sending text to `edge-tts`.

## `python3 - <<'PYEOF'` inside a function silently swallows piped stdin

**Problem:** A `strip_xml()` bash function piped `.md` file content in
(`cat "$mdfile" | strip_xml`) and internally ran a small Python script via
`python3 - <<'PYEOF' ... PYEOF`. Every single file was reported as "empty after stripping" —
the extraction script itself was logically correct (verified independently), but produced
empty output when invoked through the pipe.

**Root cause:** `python3 -` tells Python to read its *script* from stdin. The heredoc
(`<<'PYEOF' ... PYEOF`) is exactly what bash attaches as stdin for that invocation, so Python
consumes the entire heredoc as the program source. By the time the script's own
`sys.stdin.read()` executes, stdin is already at EOF — the piped `.md` content
(`cat "$mdfile" | strip_xml`) never reaches it. This fails silently (empty string, no error),
which is what made it easy to miss.

**Fix:**
```bash
# ❌ before — heredoc script consumes the piped stdin before sys.stdin.read() runs
strip_xml() {
  python3 - <<'PYEOF'
import sys
text = sys.stdin.read()
...
PYEOF
}

# ✅ after — write the script to its own temp file once; stdin stays free for the pipe
STRIP_SCRIPT="$(mktemp)"
trap 'rm -f "$STRIP_SCRIPT"' EXIT
cat > "$STRIP_SCRIPT" <<'PYEOF'
import sys
text = sys.stdin.read()
...
PYEOF
strip_xml() {
  python3 "$STRIP_SCRIPT"
}
```

**Confirmed by:** Isolated test — piping a real compiled `.md` file through the fixed
`strip_xml` correctly produced the extracted Kisangani text (English glosses stripped, tags
removed). Full end-to-end run of `gen_audio.sh` (mp3 generation + HTML injection across all
files) was not completed in this session — pending re-run.

**Notes:** General pattern, not Kisangani-specific: any bash helper that does
`python3 - <<HEREDOC` (or `python3 - <<<"$var"`) while also expecting to consume the caller's
piped stdin has this bug. `python3 -c "$code"` does not have this problem since `-c` takes the
program as an argument, leaving stdin free — but inline multi-line code via `-c` gets awkward
for anything beyond a couple of statements, so a temp-file script is usually cleaner anyway.

## Two independent, diverging implementations of the same `<x-out>/<x-src>` extraction logic

**Behavior:** The codebase has two separate places that strip Audition's `<x-out>word<x-src>gloss</x-src></x-out>`
tooltip markup down to plain speakable text: `tools/gen_audio.sh` (build-time, Python regex) and
the `speak-kisangani` skill at `.agents/skills/speak-kisangani/SKILL.md` (interactive,
documented as `sed 's/<[^>]*>//g'`).

**Explanation:** `sed 's/<[^>]*>//g'` only deletes the tag delimiters themselves, not the text
between them. Since `<x-src>` is nested *inside* `<x-out>` (e.g.
`<x-out>kugamuchira<x-src>welcome#CL15</x-src></x-out>`), this sed pattern leaves both spans'
text concatenated — e.g. `kugamuchirawelcome#CL15` — so the English gloss would leak into and be
audibly synthesized alongside the Kisangani word. `gen_audio.sh`'s Python version avoids this by
removing `<x-src>...</x-src>` (tag *and* contents) as a distinct first pass before unwrapping
`<x-out>`.

**Workaround / Pattern:** Not yet fixed — flagged for the user, who was mid-decision on how to
reconcile the two implementations (fix the skill's sed pattern to match, leave it as documented
for now since it's a separate interactive-only code path, or something else) when the session
ended.

**Confirmed by:** Traced logically from the nesting structure of the markup and the semantics of
`sed 's/<[^>]*>//g'`; not reproduced by actually running the skill's documented command.

**Notes:** If reconciling, consider having the skill delegate to (or literally reuse) the same
extraction script `gen_audio.sh` now uses, rather than maintaining two copies of this logic.
</content>
