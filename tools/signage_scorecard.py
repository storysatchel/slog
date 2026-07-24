#!/usr/bin/env python3
"""tools/signage_scorecard.py

Reports, per src/<lang>, how many of the canonical wiki/English_Signage_Reference
signs have been translated (i.e. have a matching src/<lang>/<Category>/<slug>.md.au),
and separately, whether the compiled output for those signs is actually complete
-- no missing lexicon roots or morphology/inflection rules.

The canonical sign list is every *.md file at least two levels deep under
wiki/English_Signage_Reference/<Category>/ -- this deliberately excludes the
flat, un-categorized copies sitting directly in English_Signage_Reference/
itself, which are stale duplicates left over from before the Category
subdirectories existed (see wiki/projects/slog/dev/ for background). A
language's own src/<lang>/<other-dir>/ content that has no Category match in
the reference set (e.g. Kisangani's diagetic_samples/, which is original
content, not a translation of an English reference) is correctly never
counted here, since this script only ever iterates the reference set.

Root/morphology completeness: Audition (tools/audition/src/translator.ts)
renders every untranslatable gloss as literally "(${s}??)" via one shared
`untranslatable()` helper, called from exactly two places:
  - a lexicon lookup miss -- untranslatable(gloss.lexeme), e.g. "(dog??)",
    always a bare word with no "#" inside the parens.
  - a morphology/inflection lookup miss -- untranslatable(`${stem}#${inflection}`),
    e.g. "(kwa#CL17??)", always containing "#" (stem then the failed tag).
So "does this fallback contain a '#'" is not a heuristic -- it's exactly
Audition's own distinction between "missing root" and "missing morphology
rule", read back out of its output format. A failed inflection whose stem
was ALSO an unresolved root cascades through the same reduce() one tag at a
time, producing nested wraps like "((by??)#CL16??)" -- peeled one layer at a
time below, attributing one miss to each layer, which is how "by" not being
in the lexicon and "#CL16" separately having no matching rule both get
counted independently for that one word.

Usage:
  python3 tools/signage_scorecard.py
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REFERENCE_DIR = ROOT / "wiki" / "English_Signage_Reference"
SRC_DIR = ROOT / "src"

FALLBACK = re.compile(r"\(([^()]*)\?\?\)")


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


def classify_fallbacks(text):
    """(root_misses, morphology_misses) in one compiled .md's text. Repeatedly
    strips innermost (...??) groups so nested wraps from cascading multi-tag
    failures get peeled one layer at a time (see module docstring)."""
    root_misses = 0
    morphology_misses = 0
    while True:
        matches = list(FALLBACK.finditer(text))
        if not matches:
            break
        for m in matches:
            if "#" in m.group(1):
                morphology_misses += 1
            else:
                root_misses += 1
        text = FALLBACK.sub("", text)
    return root_misses, morphology_misses


def compiled_stats(lang, category, slug):
    """(root_misses, morphology_misses) for one sign's compiled .md, or None
    if it hasn't been built (compiled .md is gitignored/ephemeral)."""
    compiled = SRC_DIR / lang / category / f"{slug}.md"
    if not compiled.exists():
        return None
    return classify_fallbacks(compiled.read_text(encoding="utf-8"))


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

    gaps = []  # (lang, category, slug, root_misses, morphology_misses)
    built_anything = False
    lang_implemented_count = {}
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
                if not (SRC_DIR / lang / category / f"{slug}.md.au").exists():
                    continue
                stats = compiled_stats(lang, category, slug)
                if stats is None:
                    continue
                built_anything = True
                root_misses, morphology_misses = stats
                if root_misses or morphology_misses:
                    gaps.append((lang, category, slug, root_misses, morphology_misses))

        pct = round(100 * lang_implemented / total_signs) if total_signs else 0
        cells["TOTAL"] = f"{lang_implemented}/{total_signs} ({pct}%)"
        lang_implemented_count[lang] = lang_implemented
        print(row(cells, lang))

    print()
    if not built_anything:
        print("Root/Morphology Completeness: skipped -- nothing compiled yet, run `make build` first.")
        return

    print(f"Root/Morphology Completeness  ({len(gaps)} implemented sign(s) with gaps)")
    print()
    print("Every gap is read directly out of Audition's own untranslatable-gloss")
    print('format, "(${stem}??)" vs "(${stem}#${tag}??)" -- see module docstring.')
    print()

    by_lang = {}
    for lang, category, slug, root_misses, morphology_misses in gaps:
        r, m = by_lang.get(lang, (0, 0))
        by_lang[lang] = (r + root_misses, m + morphology_misses)

    summary_langs = [l for l in langs if lang_implemented_count.get(l, 0) > 0]
    if summary_langs:
        lw = max(len("Language"), max(len(l) for l in summary_langs)) + 2
        print(
            "Language".ljust(lw)
            + "Root Misses".rjust(14)
            + "Morphology Misses".rjust(20)
            + "Total Gaps".rjust(13)
        )
        print("-" * (lw + 14 + 20 + 13))
        for lang in summary_langs:
            r, m = by_lang.get(lang, (0, 0))
            print(
                lang.ljust(lw)
                + str(r).rjust(14)
                + str(m).rjust(20)
                + str(r + m).rjust(13)
            )
        print()

    if gaps:
        print("Worst signs (by total gaps):")
        for lang, category, slug, root_misses, morphology_misses in sorted(
            gaps, key=lambda t: -(t[3] + t[4])
        )[:10]:
            print(
                f"  {root_misses + morphology_misses:>4}  {lang}/{category}/{slug}"
                f"  (root: {root_misses}, morphology: {morphology_misses})"
            )
        if len(gaps) > 10:
            print(f"  ... and {len(gaps) - 10} more")
    else:
        print("No gaps found in any built, implemented sign.")


if __name__ == "__main__":
    main()
