# Irish G2P Engine

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/hellpanderrr/IrishPhoneticTranscription)

A rule-based, standalone **grapheme-to-phoneme (G2P) engine for Irish**, implemented in Lua. Converts standard Irish orthography to IPA phonetic representation for all three major dialects — **Connacht** (primary target), **Munster**, and **Ulster**. Academic/experimental tool based on Raymond Hickey's *The Sound Structure of Modern Irish* (2014) and Ó Raghallaigh's *Fuaimeanna na Gaeilge*.

## Architecture

Modular **16-pass token-array pipeline**. The engine tokenizes orthographic input, then processes the token array sequentially through specialized passes, each handling one phonological domain:

| Pass | Name | Purpose |
|------|------|---------|
| 01 | `polarity` | Consonant broad/slender polarity |
| 02 | `stress` | Default initial-stress + lexical exceptions |
| 03 | `eclipsis` | Eclipsis detection and resolution |
| 04 | `cluster_simplify` | Cluster reduction (chn→chr, cn→cr, etc.) |
| 05 | `mutated_fricatives` | Lenited consonant resolution (bh, mh, dh, gh, etc.) |
| 06 | `vocalization` | Fricative vocalization (agh, adh, abh, amh → vowel/diphthong) |
| 06d | `anticipatory_raising` | Anticipatory vowel raising before velarized consonants |
| 07 | `nasalization` | Nasal raising effects |
| 08 | `slender_coda` | Slender coda consonant handling |
| 09 | `consonants` | Consonant quality, devoicing, and contextual allophony |
| 09b | `vowel_adjunct` | Additional vowel-consonant interactions |
| 10 | `vowels` | Vowel resolution + contextual allophony |
| 11 | `unstressed_reduction` | Unstressed vowel reduction (→ ə, ɪ) |
| 12 | `epenthesis` | Epenthetic vowel insertion in clusters |
| 13 | `sonorants` | Sonorant dental/postalveolar diacritics |
| 14 | `final_cleanup` | Final IPA cleanup, artifact removal |

## Repository Structure

```
├── irish_engine_new.lua      # Engine entry point: tokenizer + pass orchestrator
├── irish.lua                 # Compatibility alias → irish_engine_new
├── passes/                   # 18 module files (16 passes + init + shared)
│   ├── init.lua              # Pass ordering
│   ├── _shared.lua           # Shared definitions (VOWEL_DIGRAPHS, DIALECTS, make_token)
│   ├── 01_polarity.lua
│   ├── ...
│   └── 14_final_cleanup.lua
├── archive/                  # Previous engine versions (monolith, tokens prototype)
│   ├── irish.lua             # Original monolith entry point
│   ├── irish_core.lua        # Monolith phonetic data
│   ├── irish_tokens.lua      # Token-prototype (predecessor to passes/)
│   └── regression*.lua       # Old regression tests
├── theory/                   # Reference materials
│   ├── Fuaimeanna na Gaeilge — Chapter 1 Summary.txt
│   ├── The Sound Structure of Modern Irish — Hickey Ch.1.txt
│   └── The Sound Structure of Modern Irish — Hickey Ch.2.txt
├── data/
│   ├── connacht_only.csv     # Wiktionary IPA: Connacht dialect (6,593 words)
│   └── all_regions.csv       # Wiktionary IPA: all Irish dialects
├── ustring/                  # Unicode-aware string library for Lua 5.4
├── bench_run.lua             # Benchmark harness
└── summary.md                # Detailed project summary
```

## Usage

### Prerequisites
- Lua 5.4+
- `ustring` library (included at `ustring/`)

### Transcribe a word
```sh
lua -e "local e=require('irish_engine_new'); print(e.transcribe('seomra','connacht'))"
# dialect: 'connacht' | 'munster' | 'ulster'
```

### Run benchmark
```sh
lua bench_run.lua "label" [dialect]     # dialect defaults to connacht
python tools/make_dialect_benchmarks.py # regenerate Munster/Ulster dictionaries
```

## Current Status

The engine models a large and growing portion of Irish phonology across the three dialects. Connacht is the primary, most-tuned target; Munster and Ulster support was added via dialect-gated rules (Munster stress attraction, pretonic reduction, bh/mh friction retention, geminate diphthongization; Ulster post-tonic long-vowel shortening, o/u→ʌ merger, á-fronting, ó-lowering, suffix vowel realizations).

Benchmark dictionaries are built from dialect-tagged Wiktionary IPA (`data/all_regions.csv`, 17,281 rows / 9,719 words). Only words with at least one dialect-tagged transcription are scored per dialect; untagged rows are accepted as alternate variants.

### Benchmark Results

| Metric | Connacht (6,598 words) | Munster (4,102) | Ulster (4,785) |
|--------|------------------------|-----------------|----------------|
| Exact match | **4963 (75.22%)** | **1661 (40.49%)** | **1700 (35.53%)** |
| Exact, stress-insensitive | 78.27% | 44.25% | 36.49% |
| Exact, diacritic skeleton | 81.98% | 49.51% | 38.75% |
| Norm Levenshtein (0–100) | **94.47** | 85.35 | 84.51 |
| Norm Dolgopolsky (0–100) | **95.39** | 84.75 | 84.42 |
| Phone Error Rate (PER) | **7.52%** | 19.71% | 23.61% |
| — vowel PER / consonant PER | 10.14 / 5.96 | 31.14 / 12.14 | 41.08 / 15.00 |

> Normalized scores are 0–100 where 100 = perfect match.<br>
> Lev normalization: `(1 − lev / max_segment_length) × 100`<br>
> Dolgo normalization: `(1 − dolgo_edit_distance) × 100`<br>
> PER: corpus-aggregated phone-token edit distance / expected phone count.
>
> Per-word results: [data/results.csv](data/results.csv) (Connacht), `data/results_munster.csv`, `data/results_ulster.csv`; mismatches in the corresponding `errors*.csv`.
>
> Note: the reference transcriptions come from multiple transcribers and are internally inconsistent on some conventions (sonorant diacritics, `a/ɑ` backing, stress marking on monosyllables). The stress-insensitive and skeleton rows quantify that ceiling — for Munster, ~9pp of the gap is diacritic-convention noise alone.

### Remote

```sh
git remote add origin https://github.com/hellpanderrr/IrishPhoneticTranscription
```

### Error Breakdown (Connacht; snapshot from the 73.96% run — categories still representative)

#### Broad/Slender Quality (24.5% of errors)

| Count | % | Error type |
|-------|---|------------|
| 421 | 24.5% | Broad/slender quality mismatch (ˠ/ʲ diacritics wrong or missing) |
| 147 | 8.6% | Missing broad velarization [ˠ] specifically |

These are primarily **sonorant pass** issues (pass 13) — the engine places broad/slender diacritics imperfectly, especially on consonants in unstressed or derived environments where the polarity signal is ambiguous.

#### Dental/Postalveolar Diacritics (17.3% of errors)

| Count | % | Error type |
|-------|---|------------|
| 127 | 7.4% | Missing dental diacritic [̪] on t/d/n/l |
| 108 | 6.3% | Extra dental diacritic [̪] (over-application) |
| 62 | 3.6% | Missing postalveolar diacritic [̠] on n/l |

The engine's dental rule fires based on onset position, cluster composition, and preceding vowel length, but doesn't fully capture per-word lexical exceptions or the full range of conditioning environments.

#### Stress (29.0% of errors)

| Count | % | Error type |
|-------|---|------------|
| 217 | 12.6% | Missing primary stress mark [ˈ] |
| 170 | 9.9% | Extra primary stress mark [ˈ] |
| 110 | 6.4% | Missing secondary stress mark [ˌ] |

Default initial-stress with lexical exceptions but no productive secondary-stress modeling for compounds and derivational suffixes. Multi-word phrase stress reassignment (pass 14 Step 10) handles phrases but misses many compound-noun and loanword stress patterns.

#### Vowel Quality

| Count | % | Error type |
|-------|---|------------|
| ~53 net | — | Extra [ɪ] (over-produced, often where expected [ə] or [i]) |
| ~46 net | — | Extra [ɛ] (produced where expected [e] or [ə]) |
| ~19 net | — | Missing [ɑ] (produces [a] instead) |
| ~18 net | — | Missing [æ] (never produced — æ-raising rule absent) |
| ~247 net | — | Extra [ə] (over-reduction in unstressed syllables) |

The vowel pass (10) and unstressed reduction pass (11) handle most cases but fail on context-dependent allophony — especially æ-raising, ɑ-backing, and ɪ/ʊ/ɛ near-close distinctions in non-initial syllables.

#### Other Known Issues

1. **Dialect depth**: Connacht is the most complete. Munster/Ulster rule sets cover the major systematic differences (stress, vowel quality/quantity, bh-mh, sonorants) but lack the lexical-exception layers Connacht has accumulated.
2. **Stress**: Default initial-stress with limited lexical exceptions. Fails on loanwords (`ospidéal`, `tobac`) and derivational suffixes (`-án`, `-óir`).
3. **Compound prosody**: No systematic secondary stress for compounds (veidhlín → ˌvʲəiˈlʲiːnʲ, not ˈvʲəilʲiːnʲ). Multi-word phrase stress (pass 14 Step 10) handles ~20 lexicalized phrases but doesn't generalize.
4. **Lenited sh/th**: Inconsistent /h/ vs /ç/ realization depending on following vowel.
5. **Vocalization**: Intervocalic bh/mh/dh/gh inconsistent — sometimes produces diphthongs where long vowel expected, or vice-versa.
6. **bh/mh w-coda**: Multi-pass interaction issue prevents correct w preservation after diphthongs in some words.
7. **Dental diacritics**: [̪]/[̠] placement sensitive to cluster composition and stress environment — doesn't fully generalize to all contexts.
8. **Vowel allophony**: æ/ɑ/ɪ/ʊ/ɛ allophones inconsistently produced in unstressed or derived environments.
9. **sVarabhakti epenthesis**: Over-applies in some unstressed contexts (marbh → [mˠaɾˠəvˠ] vs expected [mˠaɾˠvˠ]).
10. **æ-raising**: No rule produces [æ]; expected in words like *leadhb* /l̠ʲæbˠ/, *feadh* /fˠæː/.

### Progress

Connacht has improved from **60.5%** → **75.2%** exact match through targeted phonological fixes. Munster went 23.1% → 40.5% and Ulster 16.4% → 35.5% in the initial dialect-expansion rounds. Typical methodology: analyze the dialect's `errors*.csv`, bucket by error type (Levenshtein-1 substitution patterns), fix the highest-volume pattern in the relevant pass with a theory-cited rule, verify no cross-dialect regressions, repeat.

### Encoding Notes
- Lua 5.4 strings are raw bytes. Unicode IPA characters use UTF-8 byte sequences.
- `ustring` library provides `ulen(s)`, `usub(s,i,i)` for Unicode-aware operations.

## References
- Hickey, Raymond (2014). *The Sound Structure of Modern Irish*. De Gruyter Mouton.
- Ó Raghallaigh, Brian (2013). *Fuaimeanna na Gaeilge*. Cois Life, Dublin.
