# Agent Instructions & Translation Workflow

Welcome, fellow agent! When working with the worldbuilding texts and conlangs in this repository, you must adhere strictly to the following workflow for generating translations and glossing "diegetic grist" (the in-world texts).

## 1. Produce the Diegetic Grist
New top-level English-language or non-diegetic texts (e.g., signage, forms, narrative dialogue) should always be written as pure markdown (`.md`) files in the top-level `wiki/` directory.
**Never** write `.md.au` files into the `wiki/` directory.

## 2. Gloss into the Conlang Source Directory
To translate a text into one of the constructed languages (e.g., Kisangani Basic), create an Audition source file (`.md.au`) in the corresponding `src/[lang]/` directory (e.g., `src/kisangani/Hazard_Markings/`).
- Copy the English text from the `wiki/` file into the new `.md.au` file.
- Add the `> __gloss__` syntax blocks directly above the English text using the specific conlang's roots and morphological tags from its `lexicon.csv` and `morphology.yaml`.
- Respect the specific linguistic ontology and phonotactics of the target language. Do not apply Western inflectional logic to non-Western languages.

## 3. Compilation via CI/CD
The `src/[lang]/` directories are the structural hubs for their respective languages; they contain the `lexicon.csv` and `morphology.yaml` required by the Audition compiler.
Once the `.md.au` file is saved in `src/[lang]/`, our CI/CD workers (such as the `npm run watch` or `make build` scripts) will automatically detect it, apply the grammar rules, and compile it into a final `.md` file containing the translated conlang text alongside the English within the `src/` tree.

### Summary of Directory Roles
*   `wiki/` -> Pure English texts ("diegetic grist"). Only `.md` files.
*   `src/[lang]/` -> Conlang source files (`.md.au`) and the CI/CD-generated compiled translations (`.md`).
*   `tools/` -> Build tools and compiler scripts (e.g., the Audition engine).
