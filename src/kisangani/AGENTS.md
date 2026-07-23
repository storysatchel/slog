# Kisangani Basic: Language & Decolonial Guidelines

Welcome! When working with Kisangani Basic in `src/kisangani/`, follow these language-specific rules to maintain the decolonial architecture and linguistic integrity of the setting.

## 1. Sovereign Decolonial Shield
Kisangani Basic acts as a sovereign linguistic shield against Eurocentric corporate/capitalist administrative logic.
- **Reject Colonial Penal & Market Terms**: Replace neoliberal administrative terms ("fines", "credits", "passes", "concierge", "resort", "lobby") with relational governance, restorative justice, and indigenous space concepts:
  - `resort` $\rightarrow$ `uzororo` (Class 14 abstract state of sanctuary/rest)
  - `lobby` $\rightarrow$ `dare` (Class 5 sovereign council chamber)
  - `concierge` $\rightarrow$ `mutungamiri` (Class 1 communal guide/adjudicator)
  - `fine` / `credits` $\rightarrow$ `sangana mutongi` (relational meeting with adjudicator) / `zikirediti` (Solar credits)
  - `pass` $\rightarrow$ `ruvhumo` (Class 11 permission/consent)
  - `gravitypool` $\rightarrow$ `dziva` (great lake / ecological basin)

## 2. Noun Class Prefix Rules (`morphology.yaml`)
Ensure `morphology.yaml` prevents double-prefixing by detecting existing initial prefixes before prepending:
- **Class 7/8**: Singular `chi-` (`chombo`), Plural `zvi-` replacing `ch-/k-/chi-/ki-` to yield `zvombo` (not *zvichombo*).
- **Class 11**: Preserve `ru-` initial roots to yield `ruvhumo` (not *ruruvhumo*).
- **Associative Coalescence**: Map associative *na-* + Class 1 *mu-* to `nemu-` / `na mumutongi` for relational copulative agreement.

## 3. Audition Gloss Syntax (`.md.au`)
- **Column 1 in `lexicon.csv`**: Must strictly be pure English gloss keys (`sanctuary`, `adjudicator`, `permission`). Never insert "Shinglish" epenthesis loanword fallbacks (`accept,akikepiti` or `dollar,dolilari`).
- **Tag Syntax**: Always use `#` stackable delimiters (`#CL15#PASS`, `#1PL#SUBJ#ADV`). Do not use periods or spaces within tag strings.
