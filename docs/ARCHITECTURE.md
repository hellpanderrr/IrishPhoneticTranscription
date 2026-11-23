# Architecture

The engine is a rule pipeline over a token array, followed by a small per-word exception layer.

## Pipeline (17 passes, in order)
Defined in `passes/init.lua`. Each pass receives the token array + context, modifies tokens, and returns them.

1. **01_polarity** — broad/slender polarity from flanking vowels. Simplifies initial clusters (cn→cr, gn→gr, mn→mr, tn→tr). Sets word-initial r→broad, sonorant polarity from following consonant.
2. **02_stress** — primary stress on first syllable by default. Computes `is_monosyllabic`, `vowel_count`, `root_vowel_count`. First pass that writes to `context`.
3. **03_eclipsis** — word-initial eclipsis clusters (mb→m, gc→g, dt→d, bp→b, bhf→w, ng→ŋ, nn→n). Also handles T-prefix mutation (Hickey III.2.2.2): word-initial ts→t, tch→t (s and ch silenced). Scans multi-word inputs for phrase-internal eclipsis.
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
16. **14_final_cleanup** — final silent fricatives, trailing ç/ɣ/h deletion, unstressed final devoicing (ɟ→c), lexical ɪ→i overrides, dh+cons→i vocalization, j-glide insertions, u→w before vowels, bh/mh→uː lexical overrides, function word IPA overrides (60+ entries), multi-word phrase cliticization and stress reassignment, sandhi affrication (ch+s→tʃ), regressive devoicing before th, **-íocht suffix override** (Connacht: iːçtʲ→iəxt̪ˠ). The largest and most complex pass.
17. **15_dialect_finalize** — LAST pass: per-dialect surface normalizations that must not be bypassable by later passes regenerating their input (Ulster ɑː→aː, Munster sonorant notation flatten). New dialect-wide surface normalizations belong here, not mid-pipeline.

## Token Model
- `irish_engine_new.lua` — `tokenize_word()` splits orthography into tokens with `{ortho, phon, type, palatal, stress, is_mutated, mutation, source, is_epenthetic, ortho_indices, ...}`
- `render_output()` — assembles IPA output, moving stress marks before syllable onsets (ˈCV not CˈV)
- `context` object carries `word_ortho`, `dialect`, `is_monosyllabic`, `vowel_count`, `stress_index`

## Lexical Table Pattern
Many passes use local Lua tables keyed by normalized orthography for exception handling. The normalized key must use `S.strip_fadas(S.normalize_ortho(word))` because `normalize_ortho()` preserves acute accents (áéíóú), and bare UTF-8 fadas in table key brackets cause parse errors.

## Shared Module
`passes/_shared.lua` contains:
- Dialect definitions (Connacht/Munster/Ulster vowel mappings)
- Vowel digraph table, known prefixes, eclipsis map
- Utility functions: `normalize_ortho()`, `strip_fadas()`, `vowel_polarity()`, `palatal_consonant()`, `is_short_vowel()`, `count_syllables()`, `find_preceding_vowel()`, `clone_token()`
- `FUNCTION_WORDS_OVERRIDE` — ~60 hardcoded IPA transcriptions
