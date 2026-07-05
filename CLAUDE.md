# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Irish G2P Engine

## Project
Irish G2P (grapheme-to-phoneme) engine — modular 16-pass token-array pipeline. Transcribes Irish orthography to IPA for Connacht dialect. About 6600 words in the benchmark dictionary, each with expected IPA variants.

## Key Commands
- **Benchmark**: `F:/soft/lua/lua.exe bench_run.lua "label"`
- **Lua**: `F:/soft/lua/lua.exe` (not on PATH)
- **Test a word**: `F:/soft/lua/lua.exe -e "local e=require('irish_engine_new'); print(e.transcribe('word','connacht'))"`

## Architecture

### Pipeline (16 passes in order)
Defined in `passes/init.lua`. Each pass receives the token array + context, modifies tokens, and returns them.

1. **01_polarity** — broad/slender polarity from flanking vowels. Simplifies initial clusters (cn→cr, gn→gr, mn→mr, tn→tr). Sets word-initial r→broad, sonorant polarity from following consonant.
2. **02_stress** — primary stress on first syllable by default. Computes `is_monosyllabic`, `vowel_count`, `root_vowel_count`. First pass that writes to `context`.
3. **03_eclipsis** — word-initial eclipsis clusters (mb→m, gc→g, dt→d, bp→b, bhf→w, ng→ŋ, nn→n). Scans multi-word inputs for phrase-internal eclipsis.
4. **04_cluster_simplify** — merges adjacent consonants that form compound clusters (bh+th→r, etc.).
5. **05_mutated_fricatives** — resolves lenited fricatives to approximants after vowels; fh is always silent but leaves a ghost-palatal trace.
6. **06_vocalization** — vowel+fricative sequences: -adh→ai/eː/ə, ea+bh→əu, u+gh→uː, a/o/u+bh/mh→əu. Does NOT silence the fricative (pass 09b handles that).
7. **06d_anticipatory_raising** — Connacht: short /a/ or /o/ raises to [ɪ]/[ʊ] when 2nd syllable has long [aː] (coláiste→kʊlˠaːʃtʲə, caisleán→kɪʃlʲaːnˠ).
8. **07_nasalization** — o/u/ó/ú→[uː] before geminate nasals (nn, ng).
9. **08_slender_coda** — vowel quality adjustment before slender ng/nn (gradation to [ɪ]).
10. **09_consonants** — resolves ALL consonant tokens to IPA. Lenited fricative realizations (bh/mh→vˠ/vʲ/w, ch→ç/h/x, sh→ç/h, th→∅/h/ç, dh/gh→j/ɣ/∅, fh→∅). Future -f- suffix handling with regressive devoicing. Consonant quality: s-before-labial rule, n→ŋ/ɲ before velar stops, ng→n before coronals, broad r before dentals. Word-final th handling for short vowels.
11. **09b_vowel_adjunct** — resolves vowel + mutated fricative adjuncts (supplementary to pass 09).
12. **10_vowels** — vowel resolution by dialect. Short/long/diphthong mappings, contextual allophony (vowel gradation from coda, r-lowering). Dialect table in `_shared.lua` DIATECTS.
13. **11_unstressed_reduction** — reduces unstressed short vowels to [ə]. Long vowels protected. Lexical exception tables prevent over-reduction.
14. **12_epenthesis** — inserts [ə] between heterorganic sonorant+obstruent clusters (Hickey §2.8 svarabhakti). Condition: preceding vowel short + stressed. Excludes homorganic clusters (rd, rn, rl, nd, ld, nn, ll, rr).
15. **13_sonorants** — 4-way l/n diacritic system: broad+/C→l̪ˠ/n̪ˠ, broad+otherwise→lˠ/nˠ, slender+/C→l̠ʲ/n̠ʲ, slender+otherwise→lʲ/nʲ. Geminate handling (ll→l̪ˠ/l̠ʲ, nn→n̪ˠ/n̠ʲ, rr→ɾˠ, mm→mˠ). Vowel lengthening before geminates in monosyllables. Lengthening before heavy sonorant clusters (rd, rl, rn).
16. **14_final_cleanup** — final silent fricatives, trailing ç/ɣ/h deletion, unstressed final devoicing (ɟ→c), lexical ɪ→i overrides, dh+cons→i vocalization, j-glide insertions, u→w before vowels, bh/mh→uː lexical overrides, function word IPA overrides (60+ entries), multi-word phrase cliticization and stress reassignment, sandhi affrication (ch+s→tʃ), regressive devoicing before th. The largest and most complex pass.

### Token Model
- `irish_engine_new.lua` — `tokenize_word()` splits orthography into tokens with `{ortho, phon, type, palatal, stress, is_mutated, mutation, source, is_epenthetic, ortho_indices, ...}`
- `render_output()` — assembles IPA output, moving stress marks before syllable onsets (ˈCV not CˈV)
- `context` object carries `word_ortho`, `dialect`, `is_monosyllabic`, `vowel_count`, `stress_index`

### Lexical Table Pattern
Many passes use local Lua tables keyed by normalized orthography for exception handling. The normalized key must use `S.strip_fadas(S.normalize_ortho(word))` because `normalize_ortho()` preserves acute accents (áéíóú), and bare UTF-8 fadas in table key brackets cause parse errors.

### Shared Module
`passes/_shared.lua` contains:
- Dialect definitions (Connacht/Munster/Ulster vowel mappings)
- Vowel digraph table, known prefixes, eclipsis map
- Utility functions: `normalize_ortho()`, `strip_fadas()`, `vowel_polarity()`, `palatal_consonant()`, `is_short_vowel()`, `count_syllables()`, `find_preceding_vowel()`, `clone_token()`
- `FUNCTION_WORDS_OVERRIDE` — ~60 hardcoded IPA transcriptions

### Benchmark Infrastructure
- `_benchmark.lua` — 6598 words with `expected` (comma-separated IPA variants), `monolith` fields
- `bench_run.lua` — runs every word through engine, compares against all expanded variants (parenthetical expansion for optional elements), outputs `results.csv` (all words) + `errors.csv` (mismatches only)
- Metrics: exact match count, average Levenshtein, normalized Levenshtein, normalized Dolgopolsky distance
- `errors.csv` columns: word, got, expected, lev, lev_norm, dolgo, dolgo_norm

### Pipe Delimiting (Standard Practice)
When analyzing benchmark errors via scripts, use the error-analysis pattern: export `errors.csv`, bucket by single-phone substitution (Levenshtein distance 1), count per bucket, then fix the highest-volume pattern. Each fix should be isolated to specific passes and verified by re-running the benchmark and checking for regressions.

## Theory References
Every phonological rule in the 16 passes cites its source in comments:
- **Hickey 2014** — "The Sound Structure of Modern Irish" (Ch.II: Phonological Framework, Ch.III: Morphonology)
- **FG** — "Fuaimeanna na Gaeilge" (An Gúm, 2003, Ch.5: Connacht inventory, Ch.7: orthography→IPA)
- PDFs in `theory/` on disk (not git-tracked); text extracts `.txt` files are tracked

## Benchmark Target
- Current: ~68.81% exact match (4540/6598) Connacht
- Norm Lev: ~92.8, Norm Dolgo: ~94.8
- Lev-1 single-substitution error buckets via `errors.csv`

## Encoding
- Lua strings are raw bytes. Unicode chars use UTF-8 byte sequences.
- ɛ = `\xc9\x9b` (U+025B), ɪ = `\xc9\xaa` (U+026A), ʊ = `\xca\x8a` (U+028A), ç = `\xc3\xa7` (U+00E7)
- ˠ = `\xcb\xa0` (U+02E0, broad), ʲ = `\xca\xb2` (U+02B2, slender)
- Dental ̪ = `\xcc\xaa` (U+032A), Postalveolar ̠ = `\xcc\xa0` (U+0320)
- Use `ustring` library: `ulen(s)`, `usub(s,i,i)` for Unicode-aware operations
- When matching multi-byte IPA chars in byte-string context, compare the full byte sequence, not individual bytes
- `S.strip_fadas()` uses byte-level gsub for stripping acute accents for lexical lookups (not ustring-based)

## Key Patterns
- **Always use `S.strip_fadas(S.normalize_ortho(...))`** for lexical table lookups — `normalize_ortho` preserves fadas, `strip_fadas` removes them for matching unaccented table keys
- **Never use bare UTF-8 in table key brackets**: `["péint"]=true` causes Lua parse error. Write table keys without fadas and strip before lookup.
- Add theory citations (Hickey section, FG chapter) to every new phonological rule
- Run benchmark after every change to check for regressions — this engine is sensitive to pass ordering

<!-- graymatter:instructions:begin — managed by `graymatter init`; edits inside this block are overwritten -->
## Memory (GrayMatter)

This project has persistent agent memory via the `graymatter` MCP tools:

- `memory_search` (`agent_id`, `query`) — call at the **start of a task** when prior context might matter.
- `memory_add` (`agent_id`, `text`) — call whenever you learn something **durable**: user preferences, decisions, conventions, gotchas.
- `memory_reflect` (`action`, `agent`, `text`/`target`) — update or forget stale facts. ⚠ takes `agent`, not `agent_id`.
- `checkpoint_save` / `checkpoint_resume` (`agent_id`) — snapshot/restore session state before major refactors or across restarts.

Use a stable `agent_id` of the form `<project>-<role>` (e.g. `myapp-backend`). Store conclusions, not conversation logs. Err on the side of remembering.
<!-- graymatter:instructions:end -->
