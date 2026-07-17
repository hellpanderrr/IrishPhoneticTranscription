# Irish G2P Engine

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/hellpanderrr/IrishPhoneticTranscription)

A rule-based, standalone **grapheme-to-phoneme (G2P) engine for Irish**, implemented in Lua. Converts standard Irish orthography to IPA phonetic representation, targeting the **Connacht dialect**. Academic/experimental tool based on Raymond Hickey's *The Sound Structure of Modern Irish* (2014) and Ó Raghallaigh's *Fuaimeanna na Gaeilge*.

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
```

### Run benchmark
```sh
lua bench_run.lua "label"
```

## Current Status

The engine correctly models a significant and growing portion of Connacht Irish phonology. The benchmark dictionary contains 6,598 words with expected IPA variants from Wiktionary.

### Benchmark Results

| Metric | Score |
|--------|-------|
| Exact match | **4880/6598 (73.96%)** |
| Avg Levenshtein | 0.57 |
| Norm Lev (0–100) | **94.19** |
| Norm Dolgo (0–100) | **95.55** |

> Normalized scores are 0–100 where 100 = perfect match.<br>
> Lev normalization: `(1 − lev / max_segment_length) × 100`<br>
> Dolgo normalization: `(1 − dolgo_edit_distance) × 100`
>
> See per-word results in [results.csv](results.csv) — columns: `word`, `got`, `expected`, `exact`, `lev`, `lev_norm`, `dolgo`, `dolgo_norm`.

### Remote

```sh
git remote add origin https://github.com/hellpanderrr/IrishPhoneticTranscription
```

### Error Breakdown (1,718 mismatches)

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

1. **Dialectal focus**: Connacht only. Does not accurately model Munster stress or Ulster vowel qualities.
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

The engine has improved from **60.5%** → **74.0%** exact match through a series of targeted phonological fixes. Typical methodology: analyze benchmark `errors.csv`, bucket by error type (Levenshtein-1 substitution patterns), fix the highest-volume pattern in the relevant pass, verify no regressions, repeat.

### Encoding Notes
- Lua 5.4 strings are raw bytes. Unicode IPA characters use UTF-8 byte sequences.
- `ustring` library provides `ulen(s)`, `usub(s,i,i)` for Unicode-aware operations.

## References
- Hickey, Raymond (2014). *The Sound Structure of Modern Irish*. De Gruyter Mouton.
- Ó Raghallaigh, Brian (2013). *Fuaimeanna na Gaeilge*. Cois Life, Dublin.
