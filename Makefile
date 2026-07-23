AUDITION := tools/audition/au

# Every subdirectory of src/ with its own lexicon.csv is a separate language.
# Audition translates one language (one lexicon.csv/morphology.yaml/generator.txt) per
# invocation, so we run it once per language directory before handing the whole src/
# tree to mdsite in a single pass.
LANGUAGES := $(dir $(wildcard src/*/lexicon.csv))

.PHONY: setup build serve clean audio

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

audio: build
	@for lang in $(LANGUAGES); do \
		langname=$$(basename $$lang); \
		echo "==> Generating audio for $$langname"; \
		bash $(CURDIR)/tools/gen_audio.sh $$langname || true; \
	done

serve: build
	npx http-server -o -c-1 -p 3000 docs

clean:
	rm -rf docs
	@for lang in $(LANGUAGES); do \
		for auf in $$(find $$lang -name '*.md.au'); do rm -f "$${auf%.au}"; done; \
	done
