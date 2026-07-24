AUDITION := tools/audition/au

# Every subdirectory of src/ with its own lexicon.csv is a separate language.
# Audition translates one language (one lexicon.csv/morphology.yaml/generator.txt) per
# invocation, so we run it once per language directory before handing the whole src/
# tree to mdsite in a single pass.
LANGUAGES := $(dir $(wildcard src/*/lexicon.csv))

.PHONY: setup build serve clean audio narrate scorecard

setup:
	git submodule update --init --recursive
	npm install

# Delete only compiled .md files that have a .md.au source, never a blind *.md
# glob: hand-authored .md files (AGENTS.md) live in the same directories, and a
# blind glob has silently deleted AGENTS.md more than once.
build: setup
	@for lang in $(LANGUAGES); do \
		echo "==> Translating $$lang"; \
		for auf in $$(find $$lang -name '*.md.au'); do rm -f "$${auf%.au}"; done; \
		bun $(CURDIR)/$(AUDITION) -s -C $$lang || exit 1; \
	done
	npx mdsite

# Offline: embeds .mp3s already committed under src/ into the built HTML.
# Safe to run in CI. See `narrate` for the (network-dependent) step that
# produces those .mp3s in the first place.
audio: build
	@for lang in $(LANGUAGES); do \
		langname=$$(basename $$lang); \
		echo "==> Embedding audio for $$langname"; \
		bash $(CURDIR)/tools/embed_audio.sh $$langname || true; \
	done

# Network-dependent: synthesizes new .mp3s via edge-tts, an unofficial client
# for an undocumented Microsoft service known to intermittently 403. Run this
# locally and commit the resulting .mp3s whenever gloss text changes; it is
# deliberately NOT a dependency of build/audio/CI, which must not depend on
# an unauthenticated third-party service staying reachable.
narrate: build
	@for lang in $(LANGUAGES); do \
		langname=$$(basename $$lang); \
		echo "==> Synthesizing audio for $$langname"; \
		bash $(CURDIR)/tools/synth_audio.sh $$langname; \
	done

serve: build
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
