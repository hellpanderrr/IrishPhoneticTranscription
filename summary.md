# Irish G2P (Grapheme-to-Phoneme) Engine — Project Summary

## Purpose

A rule-based, standalone **Grapheme-to-Phoneme (G2P) engine for Irish**, implemented in Lua. Converts Irish orthography to IPA phonetic representation, targeting the **Connacht dialect**. Academic/experimental tool based on Raymond Hickey's *The Sound Structure of Modern Irish* (2014).

## Current Accuracy (as of v19, 2025-06-15)

| Metric | Value |
|---|---|
| Words tested | 6,911 (Wiktionary Connacht IPA) |
| Perfect match (`match=100`) | 2,423 (35.1%) |
| Average Levenshtein match | 84.81 / 100 |
| Average Dolgo distance | 0.9413 (1.0 = perfect) |
| Significant errors (Dolgo < 0.8) | 611 words |

## Repository Structure

```
irish/repo/
├── irish_main.lua          # CLI entrypoint, transcribe() API
├── irish_core.lua          # Phonetic data, vowel/consonant classes, exceptions (36 KB)
├── irish_engine.lua        # Rules engine + pipeline orchestration (44 KB)
├── irish_rules.lua         # All rule tables by pipeline stage (65 KB)
├── irish_processors.lua    # Procedural functions: vocalization, reduction, epenthesis (22 KB)
├── irish_rules_data.lua    # Additional rules data (101 KB)
├── regression.lua          # Regression test suite with history tracking
├── analyze_deep.py         # Failure analysis of results.csv
├── results.csv             # Full test output vs. expected IPA
├── data/
│   ├── connacht_only.csv   # Wiktionary IPA: Connacht dialect (6,911 words)
│   └── all_regions.csv     # Wiktionary IPA: all Irish dialects (17,281 words)
├── ustring/                # Unicode-aware string library for Lua
├── implementation_plan.md  # 10-issue improvement roadmap
└── README.md               # Project overview and usage
```

## Architecture: Multi-Stage Pipeline

The engine transforms Irish text to IPA through **13 sequential stages** using a marker-based approach (orthographic features → internal markers → base phonemes → refined output):

| Stage | Name | Purpose |
|---|---|---|
| 1 | Preprocessing | Lowercasing, whitespace normalization |
| 1.5 | Cluster Simplification | Reduce clusters (`chn`→`chr`, `cn`→`cr`) |
| 2 | Digraph Marking | Insert markers for lenited consonants, eclipsis, vocalization triggers |
| 2.5 | Suffix Marking | Mark derivational/inflectional suffixes |
| 3.1 | Marker Resolution | Resolve markers to base phonemes, determine broad/slender quality |
| 3.2 | Stress Assignment | Default initial stress + lexical exceptions |
| 4.0–4.4 | Vowel Processing | Long vowels, diphthongs, vocalized fricatives |
| 4.5 | Contextual Allophony | Nasal raising, velar raising, gradation, Connacht shifts |
| 4.6 | Unstressed Reduction | Reduce unstressed vowels to schwa/allophones |
| — | Epenthesis | Insert epenthetic vowels in consonant clusters |
| — | Diacritics | Apply `ʲ`, `ˠ`, `̪` quality markers |
| — | Final Cleanup | Remove artifacts, final IPA normalization |

## Known Issues (prioritized by impact)

### Priority 1 — High Impact
1. **`sh`/`th` lenition confusion** (113 cases) — wrong `h` vs `ç` based on following vowel
2. **Stress mark false positives** (362 cases) — `ˈ` added to monosyllabic words where conventions omit it
3. **`ó` not raised to `uː` before nasals** (~30 cases) — nasal raising rule not applied

### Priority 2 — Phonological Accuracy
4. **Missing dental diacritics** (52 cases) — `n`, `l`, `d`, `t` broad forms lack `̪`
5. **Vocalized fricative diphthongs** (200+ cases) — `bh/mh/gh/dh` produce wrong output
6. **`cn-`/`gn-` marker leak** (13 cases) — internal `Kɾˠ_O_SHT` markers appear in output

### Priority 3 — Fine-Tuning
7. **`bh`/`mh` broad → `w` rule** (30 cases)
8. **Unstressed vowel reduction** (`ə` vs `ɪ`, ~70 cases)
9. **Vowel shift before long low vowels** (~20 cases)

### Priority 4 — Data Quality
10. **Empty expected IPA** (~100 cases) — should be excluded from scoring

## Limitations

- **Connacht only** — does not model Munster or Ulster phonology
- **Incomplete stress system** — limited lexical exception list
- **Sandhi disabled** — each word processed in isolation
- **Marker leaks** — internal markers occasionally appear in output

## Git History

20 commits (2025-05-24 to 2025-06-15), iterative improvement from initial commit to v19 with Dolgo 0.9413.

## Memory / Refactoring Status

An in-progress modularization effort has extracted `irish_rules_data.lua`, `irish_utils.lua`, and `irish_constants.lua` from the monolith. Current blocker: procedural code accidentally placed in the data module. Regression baseline for refactoring: Levenshtein distance = 30 across 28 test words.
