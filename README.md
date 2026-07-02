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
repo/
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

## Results

See per-word results in [results.csv](results.csv) — columns: `word`, `got`, `expected`, `exact`, `lev`, `lev_norm`, `dolgo`, `dolgo_norm`.

| Metric | Score |
|--------|-------|
| Exact match | 3975/6598 (60.25%) |
| Avg Levenshtein | 0.91 |
| Norm Lev (0–100) | **90.33** |
| Norm Dolgo (0–100) | **93.15** |

> Normalized scores are 0–100 where 100 = perfect match.<br>
> Lev normalization: `(1 − lev / max_segment_length) × 100`<br>
> Dolgo normalization: `(1 − dolgo_edit_distance) × 100`

## Remote

```sh
git remote add origin https://github.com/hellpanderrr/IrishPhoneticTranscription
```

## Current Status

The engine correctly models a significant portion of Connacht Irish phonology but has known limitations:

### Known Issues
1. **Dialectal focus**: Connacht only. Does not accurately model Munster stress or Ulster vowel qualities.
2. **Stress**: Default initial-stress with limited lexical exceptions. Fails on loanwords (e.g., `ospidéal`, `tobac`) and derivational suffixes (`-án`, `-óir`).
3. **Sandhi**: Processes words in isolation — no cross-word boundary assimilation or elision.
4. **Lenited sh/th**: Inconsistent /h/ vs /ç/ realization depending on following vowel.
5. **Vocalization**: Intervocalic bh/mh/dh/gh inconsistent — sometimes produces diphthongs where long vowel expected, or vice-versa.
6. **th→ç quality**: Requires conditional rule based on preceding vowel environment (not yet implemented).
7. **bh/mh w-coda**: Multi-pass interaction issue prevents correct w preservation after diphthongs in some words.

### Encoding Notes
- Lua 5.4 strings are raw bytes. Unicode IPA characters use UTF-8 byte sequences.
- `ustring` library provides `ulen(s)`, `usub(s,i,i)` for Unicode-aware operations.

## References
- Hickey, Raymond (2014). *The Sound Structure of Modern Irish*. De Gruyter Mouton.
- Ó Raghallaigh, Brian (2013). *Fuaimeanna na Gaeilge*. Cois Life, Dublin.
