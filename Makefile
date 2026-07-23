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

build: setup
	@for lang in $(LANGUAGES); do \
		echo "==> Translating $$lang"; \
		rm -f $$lang*.md; \
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
	rm -f $(foreach lang,$(LANGUAGES),$(lang)*.md)
