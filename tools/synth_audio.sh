#!/usr/bin/env bash
# tools/synth_audio.sh
# Synthesize TTS narration for every compiled src/<lang>/**/*.md file and
# save it as a sibling src/<lang>/**/<stem>.mp3, committed alongside the
# source so downstream builds never need to regenerate it.
#
# This is the ONLY step in the audio pipeline that talks to the network (via
# edge-tts, an unofficial client for Microsoft Edge's undocumented Read-Aloud
# service, which is known to intermittently 403 — a bad dependency for a
# deploy pipeline). Run it locally whenever gloss text changes; it is NOT
# part of `make build`/`make audio` or CI. tools/embed_audio.sh does the
# actual (offline) embedding of these committed .mp3 files into HTML.
#
# Voice selection is per-language: each language may define
# src/<lang>/voice.conf setting VOICE, RATE, and an optional REGISTER_VOICE
# map (override by src/<lang>/<subdir> name). See src/kisangani/voice.conf
# for a worked example. Languages without a voice.conf fall back to the
# generic defaults below.
#
# Usage:
#   bash tools/synth_audio.sh [lang]
#   FORCE=1 bash tools/synth_audio.sh [lang]   # regenerate existing .mp3s too
#   Default lang: kisangani
#
# Requires: edge-tts, python3 (standard lib only)

set -euo pipefail

LANG="${1:-kisangani}"
SRC_DIR="src/${LANG}"

# Generic fallback voice/rate, used only when the language has no voice.conf
# (e.g. still-placeholder languages with no real content yet).
VOICE="en-US-AriaNeural"
RATE="+0%"
declare -A REGISTER_VOICE=()

VOICE_CONF="${SRC_DIR}/voice.conf"
if [[ -f "$VOICE_CONF" ]]; then
  # shellcheck disable=SC1090
  source "$VOICE_CONF"
fi

# The stripper script must live in its own file, not a heredoc passed to
# `python3 -`: `python3 - <<PYEOF` reads the script itself from stdin, which
# consumes the stdin pipe before the script's own sys.stdin.read() ever runs.
STRIP_SCRIPT="$(mktemp)"
trap 'rm -f "$STRIP_SCRIPT"' EXIT
cat > "$STRIP_SCRIPT" <<'PYEOF'
import sys, re
text = sys.stdin.read()
# Extract only the translated text from <x-out>TRANSLATED<x-src>...</x-src></x-out>
# (ignore the gloss source inside <x-src>). Sentence punctuation and the #CAP
# inflection are authored directly in the .md.au gloss (Audition's own
# convention), so by the time this runs the compiled text is already properly
# punctuated and capitalized -- no reconstruction needed here.
text = re.sub(r'<x-src>[^<]*</x-src>', '', text)
text = re.sub(r'<x-out>([^<]*)</x-out>', r'\1', text)
# Strip remaining tags and markdown syntax
text = re.sub(r'<[^>]+>', ' ', text)
text = re.sub(r'_+', ' ', text)
text = re.sub(r'[>#+\*\[\]\|`←↑→]', ' ', text)
text = re.sub(r'\s+', ' ', text).strip()
print(text)
PYEOF

strip_xml() {
  python3 "$STRIP_SCRIPT"
}

echo "==> Synthesizing audio for src/${LANG}/**/*.md"

find "$SRC_DIR" -name '*.md.au' | sort | while read -r aufile; do
  mdfile="${aufile%.au}"
  [[ -f "$mdfile" ]] || continue

  relpath="${mdfile#${SRC_DIR}/}"
  subdir="$(dirname "$relpath")"
  stem="$(basename "$relpath" .md)"
  mp3path="${SRC_DIR}/${subdir}/${stem}.mp3"

  if [[ -f "$mp3path" && "${FORCE:-}" != "1" ]]; then
    continue
  fi

  # Pick register-appropriate voice
  voice="${REGISTER_VOICE[$subdir]:-${VOICE}}"

  # Extract text, stripping all markup
  text="$(cat "$mdfile" | strip_xml)"

  if [[ -z "$text" ]]; then
    echo "  Skipping ${relpath} (empty after stripping)"
    continue
  fi

  echo "  [${voice}] ${relpath} → ${mp3path}"
  edge-tts --voice "$voice" --rate="$RATE" --text "$text" --write-media "$mp3path"
done

echo "==> Audio synthesis complete."
