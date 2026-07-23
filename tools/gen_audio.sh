#!/usr/bin/env bash
# tools/gen_audio.sh
# Generate Swahili TTS audio for all compiled Kisangani src/*.md files and
# embed each as a self-contained base64 <audio> player directly into the
# corresponding docs/**/*.html page (no separate audio/ asset tree).
#
# Usage:
#   bash tools/gen_audio.sh [lang]
#   Default lang: kisangani
#
# Requires: edge-tts, python3 (standard lib only), base64

set -euo pipefail

LANG="${1:-kisangani}"
SRC_DIR="src/${LANG}"
DOCS_DIR="docs/${LANG}"
VOICE="sw-TZ-RehemaNeural"
RATE="-10%"

# Register map: override voice per subdirectory register
declare -A REGISTER_VOICE=(
  ["Gov_and_Legal"]="sw-TZ-DaudiNeural"
  ["diagetic_samples"]="sw-TZ-DaudiNeural"
  ["Graffiti_and_Informal"]="sw-KE-ZuriNeural"
  ["Commercial_and_Tourist"]="sw-TZ-RehemaNeural"
  ["Hazard_Markings"]="sw-TZ-RehemaNeural"
)

# The stripper script must live in its own file, not a heredoc passed to
# `python3 -`: `python3 - <<PYEOF` reads the script itself from stdin, which
# consumes the stdin pipe before the script's own sys.stdin.read() ever runs.
STRIP_SCRIPT="$(mktemp)"
trap 'rm -f "$STRIP_SCRIPT"' EXIT
cat > "$STRIP_SCRIPT" <<'PYEOF'
import sys, re
text = sys.stdin.read()
# Extract only the translated text from <x-out>TRANSLATED<x-src>...</x-src></x-out>
# (ignore the gloss source inside <x-src>)
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

# Injects a pre-built <div> (read from a file) before </article> in an HTML
# file. Takes file paths as args rather than the div's HTML as an argv string,
# since a base64-embedded mp3 can be large enough to risk blowing past ARG_MAX
# if passed through a shell variable into sed/python's argv.
INJECT_SCRIPT="$(mktemp)"
trap 'rm -f "$STRIP_SCRIPT" "$INJECT_SCRIPT"' EXIT
cat > "$INJECT_SCRIPT" <<'PYEOF'
import sys
htmlpath, divpath = sys.argv[1], sys.argv[2]
with open(htmlpath, encoding='utf-8') as f:
    html = f.read()
with open(divpath, encoding='utf-8') as f:
    div = f.read()
html = html.replace('</article>', div + '\n          </article>', 1)
with open(htmlpath, 'w', encoding='utf-8') as f:
    f.write(html)
PYEOF

inject_audio() {
  python3 "$INJECT_SCRIPT" "$1" "$2"
}

echo "==> Generating audio for src/${LANG}/**/*.md"

find "$SRC_DIR" -name '*.md' ! -name 'AGENTS.md' | sort | while read -r mdfile; do
  # Derive relative subpath, e.g. "Commercial_and_Tourist/scipio_auroral_viewing_rules"
  relpath="${mdfile#${SRC_DIR}/}"
  subdir="$(dirname "$relpath")"
  stem="$(basename "$relpath" .md)"
  htmlpath="${DOCS_DIR}/${subdir}/${stem}.html"

  if [[ ! -f "$htmlpath" ]]; then
    continue
  fi

  # Only generate/inject if not already present
  if grep -q 'class="kisangani-audio"' "$htmlpath"; then
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

  mp3tmp="$(mktemp --suffix=.mp3)"
  b64tmp="$(mktemp)"
  divtmp="$(mktemp)"
  echo "  [${voice}] ${relpath} → embedding into ${htmlpath}"
  edge-tts --voice "$voice" --rate="$RATE" --text "$text" --write-media "$mp3tmp"

  # Embed the mp3 directly into the HTML as a base64 data URI, so the page
  # is self-contained and doesn't depend on a separate docs/**/audio/ tree.
  # base64/cat/printf here write via I/O redirection, never through argv, so
  # there's no ARG_MAX risk even for large audio.
  base64 -w0 "$mp3tmp" > "$b64tmp"
  {
    printf '          <div class="kisangani-audio"><audio controls preload="none"><source src="data:audio/mpeg;base64,'
    cat "$b64tmp"
    printf '" type="audio/mpeg">Your browser does not support audio.</audio></div>'
  } > "$divtmp"
  rm -f "$mp3tmp" "$b64tmp"

  inject_audio "$htmlpath" "$divtmp"
  rm -f "$divtmp"
  echo "    ↳ Embedded audio player into ${htmlpath}"
done

echo "==> Audio generation complete."
