# Audition Developer Wishlist / Friction Log

Reflecting on our journey from 0 to 1 with Audition, here is a breakdown of the friction we encountered and how the developers could improve the developer experience (DX):

### 1. Lack of Scaffolding (`au init`)
**The Friction:** Once the executable was downloaded, running `./au` did nothing. There is no built-in way to bootstrap a new project. We had to manually reverse-engineer the README, create three separate files (`lexicon.csv`, `morphology.yaml`, `generator.txt`), and paste in boilerplate configuration just to get a working baseline.
**The Fix:** The developers should add an `au init` command. Running this should instantly scaffold a minimal "Hello World" conlang project in the current directory with heavily commented boilerplate files. This would bring the "time-to-first-success" down to seconds.

### 2. Distribution and Installation
**The Friction:** The original repository (`benchristel/audition`) instructs users to install `bun` and `yarn`, clone the repository, and run it locally. This is a very cumbersome workflow for a CLI tool. 
While `gavmor/audition` solved this by publishing a standalone binary, downloading a raw binary from GitHub Releases requires manual work (`curl`, `chmod +x`, moving it to a `$PATH` directory). 
**The Fix:** It would be highly preferable if it were distributed via standard package managers. Given that it's written in JS/TS, distributing it via `npm` (e.g., `npm install -g @gavmor/audition`) would be the most idiomatic approach. Alternatively, an automated install script (e.g., `curl -fsSL https://.../install.sh | bash`) or a Homebrew tap would make things painless.

### 3. Binary Bloat
**The Friction:** The `gavmor` static binary is nearly **100MB** in size. This is because compiling a standalone executable with Bun bundles the entire JavaScript runtime engine along with the script. For a CLI tool that parses text and runs regex replacements, this is massive and takes noticeable time to download.
**The Fix:** If shipping standalone binaries is the goal, rewriting the tool in a compiled language like Go or Rust would result in a sub-10MB binary that downloads instantly and runs faster. However, sticking to the JS ecosystem and distributing it as a standard Node/Bun package would avoid the static binary bloat entirely.

### 4. Silent Failures and Syntax Quirks
**The Friction:** The syntax requirements (like wrapping conlang blocks in `__` and using `^` to escape proper nouns) are a bit idiosyncratic. When I first wrote the `sample.md.au` file, missing the `__` wrappers or `^` character resulted in silent translation failures (e.g., printing `(Arwen??)`) without clear terminal warnings.
**The Fix:** Adding an `--explain` or `--verbose` flag would be incredibly helpful for debugging *why* a word wasn't inflected or why a regex failed to match. It would also be nice if `au` validated the `yaml`/`csv` files on startup and provided actionable error messages if they were misconfigured.

### 5. Terminal Responsiveness (Live Text Previews)
**The Friction:** When translating large files or performing heavy generation tasks, the CLI blocks until the entire process finishes. There is no live feedback indicating progress, which can make the tool feel unresponsive.
**The Fix:** Leverage the new speed of Bun and the Crust CLI refactor by wiring up async generators or streams. This would allow `au` to stream live text previews and progressive updates directly to the terminal, making the tool feel much snappier and more interactive.

### 6. Complex State Management
**The Friction:** The current architecture handles simple input-output translations but lacks a robust way to orchestrate complex local state or multi-step offline user experiences.
**The Fix:** Build out an orchestration layer for state management to handle transitions and complex workflows more elegantly. This would lay a foundation for more advanced features like interactive wizards (e.g., during `au init`).

### Summary
My preference would be a tool that feels like modern CLI utilities (like `Vite` or `Cargo`). Ideally, the workflow should look exactly like this:
```bash
npx create-audition-project my-conlang
cd my-conlang
au watch
```
This would eliminate almost all the friction we experienced and let the user focus purely on their language creation.
