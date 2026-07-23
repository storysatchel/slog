#!/usr/bin/env bash
# tools/embed_audio.sh
# Embed each committed src/<lang>/**/<stem>.mp3 as a self-contained base64
# <audio> player directly into the corresponding docs/<lang>/**/<stem>.html
# page (no separate audio/ asset tree). Purely offline and deterministic —
# safe to run in CI. tools/synth_audio.sh is the (network-dependent, local-
# only) step that produces the .mp3 files this script embeds.
#
# Usage:
#   bash tools/embed_audio.sh [lang]
#   Default lang: kisangani
#
# Requires: python3 (standard lib only), base64

set -euo pipefail

LANG="${1:-kisangani}"
SRC_DIR="src/${LANG}"
DOCS_DIR="docs/${LANG}"

# Injects a pre-built <div> (read from a file) before </article> in an HTML
# file. Takes file paths as args rather than the div's HTML as an argv string,
# since a base64-embedded mp3 can be large enough to risk blowing past ARG_MAX
# if passed through a shell variable into sed/python's argv.
INJECT_SCRIPT="$(mktemp)"
trap 'rm -f "$INJECT_SCRIPT"' EXIT
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

echo "==> Embedding audio for docs/${LANG}/**/*.html"

find "$SRC_DIR" -name '*.md.au' | sort | while read -r aufile; do
  mdfile="${aufile%.au}"
  relpath="${mdfile#${SRC_DIR}/}"
  subdir="$(dirname "$relpath")"
  stem="$(basename "$relpath" .md)"
  mp3path="${SRC_DIR}/${subdir}/${stem}.mp3"
  htmlpath="${DOCS_DIR}/${subdir}/${stem}.html"

  [[ -f "$mp3path" ]] || continue
  [[ -f "$htmlpath" ]] || continue

  # Only embed if not already present
  if grep -q 'class="kisangani-audio"' "$htmlpath"; then
    continue
  fi

  # Embed the mp3 directly into the HTML as a base64 data URI, so the page
  # is self-contained and doesn't depend on a separate docs/**/audio/ tree.
  # base64/cat/printf here write via I/O redirection, never through argv, so
  # there's no ARG_MAX risk even for large audio.
  b64tmp="$(mktemp)"
  divtmp="$(mktemp)"
  base64 -w0 "$mp3path" > "$b64tmp"
  {
    printf '          <div class="kisangani-audio"><audio controls preload="none"><source src="data:audio/mpeg;base64,'
    cat "$b64tmp"
    printf '" type="audio/mpeg">Your browser does not support audio.</audio></div>'
  } > "$divtmp"
  rm -f "$b64tmp"

  inject_audio "$htmlpath" "$divtmp"
  rm -f "$divtmp"
  echo "  ↳ Embedded ${mp3path} into ${htmlpath}"
done

echo "==> Audio embedding complete."
