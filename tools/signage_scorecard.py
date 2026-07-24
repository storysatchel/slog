#!/usr/bin/env python3
"""tools/signage_scorecard.py

Reports, per src/<lang>, how many of the canonical wiki/English_Signage_Reference
signs have been translated (i.e. have a matching src/<lang>/<Category>/<slug>.md.au).

The canonical sign list is every *.md file at least two levels deep under
wiki/English_Signage_Reference/<Category>/ -- this deliberately excludes the
flat, un-categorized copies sitting directly in English_Signage_Reference/
itself, which are stale duplicates left over from before the Category
subdirectories existed (see wiki/projects/slog/dev/ for background). A
language's own src/<lang>/<other-dir>/ content that has no Category match in
the reference set (e.g. Kisangani's diagetic_samples/, which is original
content, not a translation of an English reference) is correctly never
counted here, since this script only ever iterates the reference set.

Usage:
  python3 tools/signage_scorecard.py
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REFERENCE_DIR = ROOT / "wiki" / "English_Signage_Reference"
SRC_DIR = ROOT / "src"

FALLBACK_MARKER = re.compile(r"\?\?")


def canonical_signs():
    """(category, slug) for every reference sign, sorted."""
    signs = []
    for md in REFERENCE_DIR.glob("*/*.md"):
        category = md.parent.name
        slug = md.stem
        signs.append((category, slug))
    return sorted(signs)


def languages():
    return sorted(
        p.parent.name for p in SRC_DIR.glob("*/lexicon.csv")
    )


def fallback_count(lang, category, slug):
    """Best-effort count of untranslated '(word??)' markers in the compiled
    .md, if it happens to exist (it's gitignored/ephemeral -- built by `make
    build`). Returns None if not built, so callers can distinguish "0
    fallbacks" from "not built yet"."""
    compiled = SRC_DIR / lang / category / f"{slug}.md"
    if not compiled.exists():
        return None
    return len(FALLBACK_MARKER.findall(compiled.read_text(encoding="utf-8")))


def main():
    signs = canonical_signs()
    categories = sorted(set(c for c, _ in signs))
    langs = languages()

    if not signs:
        print("No canonical signage reference files found under", REFERENCE_DIR)
        return

    totals_per_category = {c: sum(1 for cc, _ in signs if cc == c) for c in categories}
    total_signs = len(signs)

    col_headers = categories + ["TOTAL"]
    lang_col_width = max(len("Language"), max((len(l) for l in langs), default=0)) + 2
    col_widths = {
        c: max(len(c), len(f"{totals_per_category.get(c, total_signs)}/{totals_per_category.get(c, total_signs)}")) + 2
        for c in categories
    }
    col_widths["TOTAL"] = max(len("TOTAL"), len(f"{total_signs}/{total_signs} (100%)")) + 2

    def row(cells, first):
        return first.ljust(lang_col_width) + "".join(
            str(cells.get(c, "")).rjust(col_widths[c]) for c in col_headers
        )

    print(f"Signage Coverage Scorecard  ({total_signs} canonical signs across {len(categories)} categories)")
    print()
    header_cells = {c: c for c in col_headers}
    print(row(header_cells, "Language"))
    print("-" * (lang_col_width + sum(col_widths.values())))

    fallback_notes = []
    for lang in langs:
        cells = {}
        lang_implemented = 0
        for category in categories:
            cat_signs = [s for c, s in signs if c == category]
            implemented = sum(
                1 for slug in cat_signs
                if (SRC_DIR / lang / category / f"{slug}.md.au").exists()
            )
            lang_implemented += implemented
            cells[category] = f"{implemented}/{len(cat_signs)}"

            for slug in cat_signs:
                if (SRC_DIR / lang / category / f"{slug}.md.au").exists():
                    fc = fallback_count(lang, category, slug)
                    if fc:
                        fallback_notes.append((lang, category, slug, fc))

        pct = round(100 * lang_implemented / total_signs) if total_signs else 0
        cells["TOTAL"] = f"{lang_implemented}/{total_signs} ({pct}%)"
        print(row(cells, lang))

    if fallback_notes:
        print()
        print(f"Note: {len(fallback_notes)} implemented sign(s) still have untranslated")
        print("'(word??)' fallback markers in their compiled output (run `make build` first")
        print("if this section looks empty -- it only inspects already-compiled .md files):")
        for lang, category, slug, fc in sorted(fallback_notes, key=lambda t: -t[3])[:10]:
            print(f"  {fc:>4}  {lang}/{category}/{slug}")
        if len(fallback_notes) > 10:
            print(f"  ... and {len(fallback_notes) - 10} more")


if __name__ == "__main__":
    main()
