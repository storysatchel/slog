---
title: "Verify destination content before deleting a file described as 'folded back'"
category: skills
tags:
  - topic/git
  - topic/process
  - project/kisangani
summary: "A commit deleted src/kisangani/AGENTS.md assuming its content was merged into the top-level AGENTS.md; only one unrelated line had actually been added, requiring a revert."
tier: supporting
related: []
extends: null
contradicts: null
superseded_by: null
capture_source: claude-session
project: "SLOG (Kisangani conlang wiki)"
base_confidence: 0.75
lifecycle: draft
lifecycle_changed: 2026-07-23
provenance:
  extracted: 0.9
  inferred: 0.1
sources:
  - "SLOG session (2026-07-23)"
---

# Verify destination content before deleting a file described as "folded back"

## Committing a file deletion on the assumption its content moved elsewhere, without diffing to confirm

**Problem:** A batch of pending Kisangani lexicography changes included an already-deleted
`src/kisangani/AGENTS.md`. When committing it, the commit message characterized this as folding
the language-specific rules back into the top-level `AGENTS.md`. In fact only one small, unrelated
rule (a gloss-block markdown-escaping note) had been added to the top-level file — none of
`src/kisangani/AGENTS.md`'s actual content (the Sovereign Decolonial Shield term-replacement table,
noun-class prefix rules, Audition gloss syntax rules) was present anywhere else. The user caught
this after the commit was already pushed to `origin/main` and asked for the file back.

**Root cause:** The deletion was pre-existing working-tree state from an earlier, unrelated
session (visible in `git status` before this session's own edits began). When asked to "commit
and push the rest" of a large pile of unstaged changes, the deletion was folded into a commit
message that assumed a narrative (rules "folded back") without actually running `git show
HEAD:<path>` on the deleted file and grepping the destination for overlap first. A quick check
(`grep -n "uzororo\|dare\|mutungamiri" AGENTS.md`) would have immediately shown zero matches and
surfaced the discrepancy before committing/pushing, not after.

**Fix:** Restored the file from a prior commit (`git show <old-sha>:<path> > <path>`) and pushed a
new revert commit — no history rewriting, since the mistaken commit was already on a shared
remote branch.

**Confirmed by:** User explicitly requested the file be kept in `src/kisangani/`; restored file
content verified byte-for-byte against the pre-deletion commit.

**Notes:** General pattern: before committing *any* deletion whose justification is "this content
now lives elsewhere" (a merge, a fold-back, a consolidation), actually diff/grep the claimed new
location for the old content first — especially when the deletion is inherited from someone else's
prior edits rather than something just written in the current turn, since there's no first-hand
memory of *why* it was deleted to fall back on.
