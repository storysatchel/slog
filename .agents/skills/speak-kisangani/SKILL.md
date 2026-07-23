---
name: speak-kisangani
description: Speak or pronounce Kisangani Basic (conlang) text out loud using a Swahili TTS voice. Use this skill whenever the user uses the `/speak-kisangani` slash command, asks to hear a Kisangani passage, or asks how a Kisangani diegetic text sounds when spoken aloud.
---
# Speak Kisangani

This skill synthesizes audio for Kisangani Basic conlang text using Microsoft's `edge-tts` with a Swahili (Tanzanian) voice and plays it back directly to the user.

Kisangani Basic is a Shona-derived, Bantu agglutinative constructed language. Its phonotactics are fully open-syllable (CV structure — no closed syllables), consistent with Bantu phonology. Swahili TTS voices render the morphological structure and tonal cadence far closer to the authentic Kisangani soundscape than any European voice would.

## Voice Selection

| Voice | Locale | Register | Use Case |
|---|---|---|---|
| `sw-TZ-RehemaNeural` | Tanzanian Swahili (Female) | Formal / Civic | Default; signage, announcements, official texts |
| `sw-TZ-DaudiNeural` | Tanzanian Swahili (Male) | Formal / Maritime | Naval charters, trade protocols, tribunal speech |
| `sw-KE-ZuriNeural` | Kenyan Swahili (Female) | Informal / Graffiti | Informal/graffiti texts, dialogue, street register |

Default voice: **`sw-TZ-RehemaNeural`**

## Instructions

When the user asks you to speak or pronounce Kisangani Basic text (e.g. `/speak-kisangani vaparadzi vaguriwa ruvhumo reruvo na mumutongi`), use the `run_command` tool to execute the following pipeline.

**Voice Engine Modes:**

1. **Interactive Mode** (Default): Generate the mp3 to `/tmp/` and play it immediately using `ffplay`.
2. **Export Mode**: When invoked by another skill or when the user explicitly asks to save the audio, generate the mp3 to the requested permanent location (e.g. `assets/audio/`) and DO NOT play it.

**Bash Command Generation Pipeline:**
```bash
TEXT="[INSERT_KISANGANI_TEXT_HERE]" && OUTFILE="[INSERT_OUTPUT_PATH].mp3" && edge-tts --voice sw-TZ-RehemaNeural --rate=-10% --pitch=+0Hz --text "$TEXT" --write-media "$OUTFILE"
```

> **Rate note:** `-10%` slightly slows the cadence to let the agglutinative morphology breathe. For informal/graffiti texts, use `+5%`.

### Steps:
1. Extract the Kisangani Basic text the user wants to hear. If the user provided a mix of English and Kisangani, extract **only the Kisangani text** to avoid the Swahili voice reading English words.
2. Select the appropriate voice based on the register of the text:
   - Formal signage / civic / legal → `sw-TZ-RehemaNeural`
   - Naval / maritime / trade protocols → `sw-TZ-DaudiNeural`
   - Graffiti / informal dialogue / street → `sw-KE-ZuriNeural`
3. Determine the mode:
   - If **Interactive**, set `[INSERT_OUTPUT_PATH]` to `/tmp/kisangani_[SNIPPET]` and append `&& ffplay -nodisp -autoexit -loglevel quiet "$OUTFILE"` to the command.
   - If **Export**, set `[INSERT_OUTPUT_PATH]` to the requested path (e.g. `assets/audio/[FILENAME]`) and execute the generation pipeline as-is.
4. Replace `[INSERT_KISANGANI_TEXT_HERE]` with the target text, ensuring proper shell escaping.
5. Run the command using the `run_command` tool.
6. Notify the user:
   - If Interactive, say the audio is playing and provide a clickable markdown file link to the `/tmp/` file as backup.
   - If Export, say the audio has been saved to the specified location.

## Source Text Lookup

When the user invokes `/speak-kisangani` with a reference (e.g. a file name or sign name) rather than raw text, look up the compiled output from the source files:

- **Compiled Kisangani `.md` files**: `src/kisangani/[Category]/[filename].md` — these contain the compiled conlang text with `<x-out>` tooltip wrappers. Strip the `<x-out>...</x-src>...</x-out>` XML tags and extract only the inner translated text before passing to TTS.
- **Strip helper** (inline sed):
  ```bash
  sed 's/<[^>]*>//g'
  ```

## Examples

```bash
# Speak the compiled Scipio Auroral Viewing Rules (formal/civic register)
TEXT="$(cat src/kisangani/Commercial_and_Tourist/scipio_auroral_viewing_rules.md | sed 's/<[^>]*>//g' | tr -s ' \n' ' ' | sed 's/^ //;s/ $//')" && OUTFILE="/tmp/scipio_auroral.mp3" && edge-tts --voice sw-TZ-RehemaNeural --rate=-10% --text "$TEXT" --write-media "$OUTFILE" && ffplay -nodisp -autoexit -loglevel quiet "$OUTFILE"

# Speak a raw Kisangani phrase (interactive)
TEXT="vaparadzi vaguriwa ruvhumo reruvo na mumutongi" && OUTFILE="/tmp/kisangani_phrase.mp3" && edge-tts --voice sw-TZ-RehemaNeural --rate=-10% --text "$TEXT" --write-media "$OUTFILE" && ffplay -nodisp -autoexit -loglevel quiet "$OUTFILE"
```
