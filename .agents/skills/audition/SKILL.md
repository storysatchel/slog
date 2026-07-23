description: \>  
Guidelines for using benchristel/audition to manage and iterate on  
conlang (constructed language) lexicons, morphologies, and texts.  
globs:

> * "/\*.au"  
> * "lexicon.csv"  
> * "morphology.yaml"  
> * "generator.txt"

# **Audition Conlang Build Tool**

You are assisting a user in developing a constructed language (conlang) using the benchristel/audition build tool. Audition allows for rapid, interactive iteration on conlang syntaxes, morphologies, and lexicons by compiling an Intermediate Representation (IR) into the target language text.

## **Core Concepts & File Roles**

An Audition project centers around these key files:

> 1. **lexicon.csv**: The dictionary.  
   * **Format**: id,translation,generator  
   * **Function**: Maps gloss IDs (e.g., come, 1SG) to translated words. If the translation column is blank, Audition will auto-generate a word using the specified generator (or the default root generator).  
> 2. **morphology.yaml**: The rules for inflection and compounding.  
   * **Function**: Defines regex-based replacements to alter words based on grammatical tags (e.g., \#PAST, \#INF). Also handles phonological rules at morpheme boundaries during compounding.  
> 3. **generator.txt**: The phonotactics engine.  
   * **Function**: Defines the syllable structure, phoneme inventory, and word shapes used to auto-generate words with specific weights/probabilities.  
> 4. **\*.au files**: The input texts/grammars.  
   * **Function**: Contains the conlang text written in Audition's Intermediate Representation (IR) gloss format. Running au processes these files and outputs plain text files (e.g., sample.md.au \-\> sample.md).

## **The Intermediate Representation (IR) Syntax**

When writing or editing .au files, you must use the IR syntax to tell Audition how to construct the sentences.

> * **Gloss invocation**: Words are built by combining IDs from lexicon.csv with inflection tags from morphology.yaml.  
> * **Format**: id\#INFLECTION1\#INFLECTION2  
> * **Proper noun / Literal text**: Prefix with ^ to pass proper nouns or literal words through unchanged (e.g., ^Arwen).  
> * **Capitalization**: Use the special \#CAP tag to capitalize a generated/inflected word (e.g., 1SG\#CAP).  
> * **IR Blocks**: IR text is usually written in blocks or inline where Audition is expected to parse it. (Often shown in examples inside Markdown quotes, though Audition parses the whole .au file).

**Example IR Input (sample.md.au):**  
\> \_\_1SG\#CAP ^Arwen. come\#1SG 2ACC help\#INF.\_\_  
\> "I am Arwen. I've come to help you."

**Compiled Output (sample.md):**  
\> \_\_Im Arwen. Telin le thaed.\_\_  
\> "I am Arwen. I've come to help you."

## **Compiler Error State Syntax**

When the Audition conlang compiler encounters a source gloss (`.md.au`) containing unmapped roots, invalid morphology tags, or unbound concords, it falls back to explicit diagnostic annotations rather than crashing. These error signatures reveal precisely where the compiler's pipeline failed to synthesize the target language.

### **Key Error Patterns & Anatomy**

#### **1. Bare Unresolved Keys: `(KEY??)`**
* **Examples**: `(LOC??)`, `(DEF??)`, `(AZURE??)`, `(SEAS??)`, `(accept??)`
* **Meaning**: Missing Lexicon Entry / Tag Definition.
* **Diagnosis**: The term inside the double question marks exists in the source `.md.au` text, but has no corresponding definition in `lexicon.csv` or `morphology.yaml`. The compiler wraps the literal English key in `(...)` as a fallback placeholder.

#### **2. Affixed Missing Radicals: `prefix(KEY??)`**
* **Examples**: `ku(welcome??)`, `ki(resort??)`, `n(money??)`, `ri(exchange??)`
* **Meaning**: Morphology Engine Succeeded, Root Engine Failed.
* **Diagnosis**: The morphology engine successfully recognized and applied the Bantu noun-class or verbal prefix (e.g., Class 15 Infinitive `ku-`, Class 7 `ki-`, Class 9 Nasal `n-`, Class 5 `ri-`), but because the core radical (`welcome`, `resort`, `money`) was missing from the lexicon, it glued the compiled prefix onto the diagnostic fallback wrapper.

#### **3. Stacked / Unbound Morphosyntactic Tags: `((TAG??)#EXT??)`**
* **Examples**: `tifara.((SUBJ??)#ADV??)`, `((offer??)#3SG??).(SUBJ??)`
* **Meaning**: Morphological Tag Evaluation Collision.
* **Diagnosis**: Occurs when multi-tag stacks (e.g. `#1PL.SUBJ#ADV` or `#3SG.SUBJ`) fail to map cleanly to a single affixing rule in `morphology.yaml`. The compiler outputs the successfully compiled root (`tifara`), followed by the unparsed or conflicting tags in nested parenthetical blocks.

#### **4. Unbound Concord Suffixes & Floating Clitics: `.class(??)`**
* **Examples**: `.ma(??)`, `gara.ri(??)`
* **Meaning**: Failed Syntactic Agreement / Concord Binding.
* **Diagnosis**: The engine attempted to generate Bantu noun-class concord agreement (such as Class 6 `ma-` or Class 5 `ri-` agreement), but lost the syntactic context of the governing head noun, leaving a dangling agreement suffix at the boundary.

### **Summary Table**

| Syntax Pattern | Meaning | Root Cause |
|---|---|---|
| `(term??)` | Bare fallback | Missing entry in `lexicon.csv` |
| `prefix(term??)` | Hybrid affixation | Prefix rule matched, but root is missing |
| `root.((TAG??))` | Unresolved tag stack | Missing/malformed rule in `morphology.yaml` |
| `root.clitic(??)` | Unbound agreement | Syntactic head noun missing or misaligned |

## **Workflow & Execution**

When asked to update the conlang or translate text, follow this workflow:

> 1. **Understand the Request**: Identify if you are adding new vocabulary, creating grammar rules, adjusting phonotactics, or writing/translating text.  
> 2. **Modify the Lexicon (lexicon.csv)**:  
   * Add new roots or particles.  
   * Leave the translation blank if you want Audition to generate the word based on generator.txt.  
   * *Example*: apple,,root  
> 3. **Modify Morphology (morphology.yaml)**:  
   * Define regex rules for new grammatical inflections requested by the user.  
   * Define compound rules for morpheme boundary changes (sandhi, mutation).  
> 4. **Write/Edit IR text (\*.au)**:  
   * Use the established IDs and tags to construct sentences.  
> 5. **Compile**:  
   * If you have execution capabilities, run ./au (or ./au \-C \<directory\>) to update lexicon.csv with generated words and compile .au files.

## **Syntax Details for Configuration Files**

### **1\. morphology.yaml**

This file uses regex capture groups ($1, etc.) to manipulate strings. Rules are evaluated top-down; the first match wins.  
inflections:  
  PAST:  
    \- \["(\[aeiou\])$", "$1n"\]   \# If ends in vowel, append 'n' (preserve vowel with $1)  
    \- \["$", "ion"\]            \# Else, append 'ion'  
  1SG:  
    \- \["o(\[^aeiouy\])$", "e$1in"\] \# Example of internal vowel mutation/umlaut  
compound:  
  \# Rules for joining morphemes. Matches left side and right side of boundary.  
  \# \[regex\_left, regex\_right, replacement\_left, replacement\_right\]  
  \- \["(\[aeiou\])$", "^p", "$1", "b"\] \# Voice 'p' to 'b' after a vowel

### **2\. generator.txt**

Defines stanzas for word generation.  
root:  
  \[syl\]  
  \[syl\]\[syl\]\*2        \# Weight of 2 (twice as likely)  
  \[syl\]\[syl\]\[syl\]

syl:  
  \[C\]\[V\]\*4  
  \[C\]\[V\]\[C\]  
  \[V\]\[C\]\*0.7

C:  
  t\*3 p k\*2 n\*3 l\*2 r s\*2 h

V:  
  a\*1.3 i u

## **Anti-Rationalization for Conlang Tasks**

| Excuse | Rebuttal |
| :---- | :---- |
| "I'll just write the final translated text directly." | Bypassing Audition ruins the workflow. Always use IR in .au files so the vocabulary and grammar can be globally updated later. |
| "I'll manually invent a word and put it in the translation column." | Unless specifically instructed to create a specific word, let Audition's generator.txt do the work. Leave the translation column blank. |
| "The regex for this inflection is too complex; I'll skip it." | Audition relies on regex for morphology. Write the regex. Use capture groups ($1) to preserve stems. |
| "I don't need to add this particle to the lexicon." | Every single conlang morpheme or word used in the IR must exist in lexicon.csv. |

## **Exit Criteria**

Before concluding a conlang update task:

> 1. Ensure all new vocabulary used in .au files is present in lexicon.csv.  
> 2. Ensure any new grammatical tags (e.g., \#PL, \#ACC) are defined under inflections in morphology.yaml.  
> 3. Ensure the regex in morphology.yaml is valid and uses capture groups correctly to avoid eating characters unintentionally.  
> 4. If asked to build, run ./au and verify it succeeds without errors.
