AUDITION := tools/audition/au

# Every subdirectory of src/ with its own lexicon.csv is a separate language.
# Audition translates one language (one lexicon.csv/morphology.yaml/generator.txt) per
# invocation, so we run it once per language directory before handing the whole src/
# tree to mdsite in a single pass.
LANGUAGES := $(dir $(wildcard src/*/lexicon.csv))

# Every input that actually affects compiled output. mdsite has no
# incremental/skip-unchanged logic of its own -- it rewrites every HTML file
# on every invocation, unconditionally, even with zero source changes (this
# was verified by running `make build` twice with nothing changed and diffing
# output: every file's mtime and content changed). So `build`/`audio` are
# real file targets keyed off these inputs via stamp files, not .PHONY --
# that's what makes them a no-op when nothing has changed, instead of
# silently re-wiping already-embedded audio out of docs/ on every invocation.
GLOSS_INPUTS := $(shell find src -type f \( -name '*.md.au' -o -name 'lexicon.csv' -o -name 'morphology.yaml' -o -name 'generator.txt' -o -name 'voice.conf' \))
AUDITION_SRC := $(shell find tools/audition/src tools/audition/peg -type f 2>/dev/null)
MP3_FILES := $(shell find src -name '*.mp3')
BUILD_INPUTS := $(GLOSS_INPUTS) $(AUDITION_SRC) src/assets/style.css template.html

.PHONY: setup build serve clean audio narrate scorecard

setup:
	git submodule update --init --recursive
	npm install

# Delete only compiled .md files that have a .md.au source, never a blind *.md
# glob: hand-authored .md files (AGENTS.md) live in the same directories, and a
# blind glob has silently deleted AGENTS.md more than once.
docs/.build.stamp: $(BUILD_INPUTS) | setup
	@for lang in $(LANGUAGES); do \
		echo "==> Translating $$lang"; \
		for auf in $$(find $$lang -name '*.md.au'); do rm -f "$${auf%.au}"; done; \
		bun $(CURDIR)/$(AUDITION) -s -C $$lang || exit 1; \
	done
	npx mdsite
	@mkdir -p docs && touch docs/.build.stamp

build: docs/.build.stamp

# Offline: embeds .mp3s already committed under src/ into the built HTML.
# Safe to run in CI. See `narrate` for the (network-dependent) step that
# produces those .mp3s in the first place. Re-embeds only when build output
# or an .mp3 actually changed -- not on every invocation.
docs/.audio.stamp: docs/.build.stamp $(MP3_FILES)
	@for lang in $(LANGUAGES); do \
		langname=$$(basename $$lang); \
		echo "==> Embedding audio for $$langname"; \
		bash $(CURDIR)/tools/embed_audio.sh $$langname || true; \
	done
	@touch docs/.audio.stamp

audio: docs/.audio.stamp

# Network-dependent: synthesizes new .mp3s via edge-tts, an unofficial client
# for an undocumented Microsoft service known to intermittently 403. Run this
# locally and commit the resulting .mp3s whenever gloss text changes; it is
# deliberately NOT a dependency of build/audio/CI, which must not depend on
# an unauthenticated third-party service staying reachable. Per-file skip
# logic (unless FORCE=1) already lives in tools/synth_audio.sh itself.
narrate: build
	@for lang in $(LANGUAGES); do \
		langname=$$(basename $$lang); \
		echo "==> Synthesizing audio for $$langname"; \
		bash $(CURDIR)/tools/synth_audio.sh $$langname; \
	done

# Depends on `audio`, not `build` directly: local preview should always show
# a complete page (audio included), matching what actually gets deployed.
serve: audio
	npx http-server -o -c-1 -p 3000 docs

# Reports, per language, how many wiki/English_Signage_Reference/<Category>/
# signs have a matching src/<lang>/<Category>/<slug>.md.au, plus a completeness
# check for missing lexicon roots/morphology rules (Audition's "(word??)"
# fallback markers) in the compiled output. Depends on `build` so the
# completeness half is always checked against fresh output, not stale.
scorecard: build
	python3 $(CURDIR)/tools/signage_scorecard.py

clean:
	rm -rf docs
	@for lang in $(LANGUAGES); do \
		for auf in $$(find $$lang -name '*.md.au'); do rm -f "$${auf%.au}"; done; \
	done
