---
title: "Alacritty's referenced auto-theme script is a dead import — colors must be set directly"
category: skills
tags:
  - topic/dotfiles
  - topic/chezmoi
  - topic/terminal
summary: "alacritty.toml imported a theme.toml from an 'alacritty-auto-theme' dir/script that doesn't exist anywhere, including in chezmoi source — the light/dark auto-switcher was never actually installed."
tier: supporting
related: []
extends: null
contradicts: null
superseded_by: null
capture_source: claude-session
project: "Personal dotfiles (chezmoi)"
base_confidence: 0.75
lifecycle: draft
lifecycle_changed: 2026-07-23
provenance:
  extracted: 0.85
  inferred: 0.15
sources:
  - "dotfiles session (2026-07-23)"
---

# Alacritty's referenced auto-theme script is a dead import

## Behavior: theme switching appeared configured but never worked

**Problem:** `~/.config/alacritty/alacritty.toml` had `import = ["~/.config/alacritty/alacritty-auto-theme/theme.toml"]`
under `[general]`, and `~/.config/autostart/alacritty-auto-theme.desktop` referenced a script at
`~/.config/alacritty/alacritty-auto-theme/AlacrittyAutoTheme.sh` meant to auto-switch the terminal
theme based on system light/dark preference. Neither the script nor the `theme.toml` it was
supposed to generate/import exists anywhere on disk, nor in the chezmoi source
(`~/.local/share/chezmoi/dot_config/`) — only the `.desktop` autostart stub was ever committed.
So the theme was effectively hardcoded to whatever colors Alacritty falls back to when an imported
file is missing, and the "auto theme" mechanism was never actually functional.

**Root cause:** The auto-theme tooling (script + generated theme file) was planned/scaffolded
(the autostart entry and import line exist) but the actual script was never written or was lost —
it's absent from both the live filesystem and the chezmoi-tracked source, so there's no way to
recover it; it has to be rebuilt from scratch if auto light/dark switching is wanted again.

**Fix:** Removed the dead `import` line and added a `[colors.*]` block directly in
`alacritty.toml` (deployed file) and the chezmoi source (`dot_config/alacritty/private_alacritty.toml`)
to hardcode a theme (Gruvbox Light) instead of relying on the missing auto-switch mechanism.

**Confirmed by:** User confirmed `find` turned up no trace of the script/theme.toml in either
location; `chezmoi diff` was used to review the source-vs-deployed delta before applying.

**Notes:** Separately discovered the chezmoi source for this file (`private_alacritty.toml`) has
drifted from the deployed config in an unrelated way: source specifies
`program = "/usr/bin/tmux"` with `args = ["new-session", "-A", "-D", "-s", "main"]` (auto-attach
tmux), while the deployed file just runs `/usr/bin/zsh` directly — user chose to keep zsh deployed
and leave that drift unresolved for now rather than run `chezmoi apply` wholesale. Worth checking
before assuming `chezmoi apply` is a safe no-op operation on this machine's dotfiles — always diff
first.
