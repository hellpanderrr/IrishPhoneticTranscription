# Irish G2P (Grapheme-to-Phoneme) Engine — Project Summary

## Purpose

A rule-based, standalone **Grapheme-to-Phoneme (G2P) engine for Irish**, implemented in Lua. Converts Irish orthography to IPA phonetic representation, targeting the **Connacht dialect**. Academic/experimental tool based on Raymond Hickey's *The Sound Structure of Modern Irish* (2014) and Ó Raghallaigh's *Fuaimeanna na Gaeilge*.

## Architecture

Modular **16-pass token-array pipeline**. The engine tokenizes orthographic input into structured tokens, then processes the token array through 16 sequential passes, each handling one phonological domain. Passes are loaded from `passes/init.lua` which defines the ordering.

## Repository Structure

```
repo/
├── irish_engine_new.lua      # Engine entry point: tokenizer + pass orchestrator
├── irish.lua                 # Compatibility alias → irish_engine_new
├── passes/                   # 18 module files (16 passes + init + shared)
│   ├── init.lua              # Pass ordering
│   ├── _shared.lua           # Shared definitions: VOWEL_DIGRAPHS, DIALECTS, make_token
│   ├── 01_polarity.lua       # Consonant broad/slender polarity
│   ├── 02_stress.lua         # Default initial-stress + lexical exceptions
│   ├── 03_eclipsis.lua       # Eclipsis detection and resolution
│   ├── 04_cluster_simplify.lua # Cluster reduction (chn→chr, cn→cr)
│   ├── 05_mutated_fricatives.lua # Lenited consonant resolution (bh, mh, dh, gh)
│   ├── 06_vocalization.lua   # Fricative vocalization → vowel/diphthong
│   ├── 06d_anticipatory_raising.lua # Anticipatory vowel raising
│   ├── 07_nasalization.lua   # Nasal raising effects
│   ├── 08_slender_coda.lua   # Slender coda consonant handling
│   ├── 09_consonants.lua     # Consonant quality, devoicing, allophony
│   ├── 09b_vowel_adjunct.lua # Vowel-consonant interactions
│   ├── 10_vowels.lua         # Vowel resolution + contextual allophony
│   ├── 11_unstressed_reduction.lua # Unstressed vowel reduction
│   ├── 12_epenthesis.lua     # Epenthetic vowel insertion
│   ├── 13_sonorants.lua      # Sonorant dental/postalveolar diacritics
│   └── 14_final_cleanup.lua  # Final IPA cleanup, artifact removal
├── archive/                  # Previous engine versions for reference
│   ├── irish.lua             # Original monolith entry point
│   ├── irish_core.lua        # Monolith phonetic data
│   ├── irish_tokens.lua      # Token-prototype predecessor
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
├── README.md                 # Project overview
└── summary.md                # This file
```

## Usage

```sh
# Transcribe a word
lua -e "local e=require('irish_engine_new'); print(e.transcribe('seomra','connacht'))"

# Run benchmark
lua bench_run.lua "label"
```

## Encoding Notes

- Lua 5.4 strings are raw bytes. IPA characters use UTF-8 byte sequences.
- Common IPA escapes: ɛ = `\xc9\x9b` (U+025B), ɪ = `\xc9\xaa` (U+026A), ʊ = `\xca\x8a` (U+028A), ˠ = `\xcb\xa0` (U+02E0, broad), ʲ = `\xca\xb2` (U+02B2, slender)
- Use `ustring` library: `ulen(s)`, `usub(s,i,i)` for Unicode-aware operations.

## References

- Hickey, Raymond (2014). *The Sound Structure of Modern Irish*. De Gruyter Mouton.
- Ó Raghallaigh, Brian (2013). *Fuaimeanna na Gaeilge*. Cois Life, Dublin.