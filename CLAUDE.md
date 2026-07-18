# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Irish G2P Engine

## Project
Irish G2P (grapheme-to-phoneme) engine — modular 17-pass token-array pipeline. Transcribes Irish orthography to IPA for Connacht dialect. About 6600 words in the benchmark dictionary, each with expected IPA variants.

## Key Commands
- **Benchmark**: `D:/soft/lua/lua.exe bench_run.lua "label" [dialect]` — dialect: connacht (default) | munster | ulster
- **Lua**: `D:/soft/lua/lua.exe` (not on PATH; formerly on the unmounted F: drive)
- **Test a word**: `D:/soft/lua/lua.exe -e "local e=require('irish_engine_new'); print(e.transcribe('word','connacht'))"`
- **Regenerate dialect benchmarks**: `python tools/make_dialect_benchmarks.py` (from `data/all_regions.csv`; writes `_benchmark_munster.lua`, `_benchmark_ulster.lua`. `_benchmark.lua` stays the curated Connacht dictionary)

## Architecture

### Pipeline (17 passes in order)
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
- Current: ~75.16% exact match (4959/6598) Connacht
- Munster (tagged-only benchmark, 4102 words): 40.49% (1661) after two rule batches (untuned Connacht-engine baseline was 23.06%)
- Ulster (tagged-only benchmark, 4785 words): 36.51% (1747) after two vowel batches + pass-15 finalization (untuned baseline was 16.43%)
- Dialect benchmarks score only words with ≥1 dialect-tagged row; untagged rows are accepted as alternate variants but untagged-only words are excluded (mixed transcription conventions)
- `data/all_regions.csv` is the dialect-tagged source (17,281 rows, 9,719 words; tags like Munster/Ulster/Connacht/Aran/Cois-Fharraige; untagged rows are treated as pan-dialectal and included in every dialect's benchmark)
- Norm Lev: ~94.06, Norm Dolgo: ~95.44
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
- **Every commit message must report the full metric set for all three dialects** (Exact, NoStress, Skeleton, Norm Lev, Norm Dolgo, PER V/C) — run `bench_run.lua` for connacht, munster, and ulster before committing

## Self-Updating Gotchas

**How this section works:** Whenever the agent discovers a non-obvious tooling or workflow pitfall during a session, it **appends** an entry here before committing. This accumulates tribal knowledge across sessions. Duplicate or superseded entries should be removed.

### Encoding / Shell
- **Fadas vanish in inline `lua -e` scripts** — bash strips UTF-8 acute accents on the command line. Always test fada-containing words (í, ó, á, etc.) from a `.lua` file, never inline.
- **Python on Windows** is `python`, not `python3`.
- **`errors.csv` is tab-delimited** — `csv.DictReader` needs `delimiter='\t'`. The header is `word\tgot\texpected\tlev\tlev_norm\tdolgo\tdolgo_norm`.
- **cp1251 encoding** — printing IPA chars to a Windows terminal gives `UnicodeEncodeError`. Redirect to a file or write to JSON instead.
- **Python `\u` escape** — string literals containing `\u` (e.g. `'\u'.replace(...)`) fail before compilation. Use a raw string or escape the backslash.

### Lua
- The module exports `tokenize_word`, not `tokenize`.
- No CSV module is installed — use Python for data analysis.
- `ustring` library (`ulen`, `usub`) for Unicode operations; byte-string comparisons must compare the full byte sequence.

### Benchmark
- **Monosyllabic stress is inconsistent** — many expected values lack `ˈ` on monosyllabic content words. A blanket `t.stress=true` for all single-vowel words (pass 02) caused ~1400 regressions. Always verify blanket rules.
- **Apostrophe-prefixed words** (`d'ith`, `b'fhearr`) lack lexical stress and must be excluded from stress assignment (pass 02 UNSTRESSED table + pass 14 Step 10 skip).
- **IGH_RESTORE condition must catch ɪ as well as ə** — many `-igh` words end as `ɪ` after vowel gradation (pass 10), not `ə` from reduction (pass 11). Checking only `phon == "ə"` silently skips them.
- **Suffix fada keys must use normalized form** — FUNCTION_WORDS_OVERRIDE lookup uses `ustring.lower(seg_ortho)` which preserves multi-byte fada chars. Key `["-igí"]` matches; `["-igi"]` (strip_fadas) would silently fail.

### Dialect work (learned 2026-07-18)
- **The benchmark source is multi-transcriber and internally inconsistent.** Tagged rows disagree with each other on sonorant diacritics (l̪ˠ vs lˠ in identical contexts), aː vs æː (Ulster), u vs uː for -adh, h/x/∅ for final ch — *per word, not per rule*. When an error bucket has a sizeable mirror bucket (X→Y and Y→X both ≥ ~15), it's transcriber noise: a rule can only trade one bucket for the other. Check for the mirror bucket BEFORE writing the rule.
- **Empirical flatten beats textbook description.** Hickey says Munster has a clean 2-way sonorant system; the benchmark data doesn't. When theory and majority-data disagree, benchmark against both variants and keep the winner — record the loser as a tried-and-reverted note.
- **Tried and reverted (don't re-attempt without new evidence):** Munster final -e→ɪ (-90), Munster eá→aː in pass 14 (-5, note comment left at site), Ulster word-final broad ch→h (fixed 41, broke 166), Munster retracted-slender-only-in-geminates (worse than full flatten).
- **Dialect rules are pass-order sensitive**: a pass-11 vowel conversion can be bypassed by pass 13 *creating* new instances afterwards (Ulster ɑː→aː misses ard-cluster lengthening output). When a gated rule underperforms, check whether a later pass regenerates the input pattern.
- **ExactSkeleton−ExactNoStress delta measures convention noise** per dialect (Connacht ~3.7pp, Munster ~5.3pp). Use it to decide rule-vs-noise before chasing a bucket.
- **Untagged all_regions.csv rows are excluded from dialect scoring** (mixed conventions) but kept as accepted alternate variants for tagged words — policy lives in tools/make_dialect_benchmarks.py.

### Git / Shell
- **`nul` file in git status** — Windows shell leaks a file named `nul` when redirecting to `/dev/null`. `rm -f nul` before `git add` avoids "short read while indexing" errors.
- **`-íocht` suffix** tokenizes two ways: `ío+ch+t` (ríocht) or `aí+o+ch+t` (draíocht). Both must be handled.
- **Lua keyword bare identifiers** — Never use Lua reserved words (`do`, `in`, `so`, `end`, `for`, `if`, etc.) as bare table keys. Always bracket-quote: `["do"]=true` not `do=true`. This caused a 120-point regression when the COMPOUND_PREFIXES table turned out to be dead code for months (the entire Rule 4 section never compiled due to `do`/`in`/`so` as bare identifiers). Fixing it without removing the bad table causes mass regressions from 2-char prefix false matches.

## Phonological Error Buckets

**How this section works:** Whenever the agent identifies a persistent, high-volume error pattern through benchmark error analysis (Levenshtein distance 1 bucketing), it **appends** an entry here before committing. Move entries to "Resolved" once the fix is committed. This is the working queue of phonological patterns to fix.

### Active

- **[Connacht multiword phrases]** — 215 errors (13%); lexicalized contractions (tá a fhios ag→t̪ˠɑːsˠ eɟ). Extend FUNCTION_WORDS_OVERRIDE with top ~50 phrases from errors.csv.
- **[Connacht sl- slender l̠ʲ]** — slis/slios/slige family (~23): s+slender-l onset should give retracted l̠ʲ (slender counterpart of the existing preceded_by_s broad rule in pass 13).
- **[Connacht w→vˠ after long vowel]** — snámh, fhómhair (~23): broad mh coda after long vowel keeps friction. Conflicts with FINAL_BH_V_TO_W table — needs careful condition.
- **[Ulster -f(a)idh→i]** — verbal future endings, majority want short i (~38 mixed with iː).

<!-- Use this format when adding new entries:
- **[pattern_name]** — Brief description. e.g. "Vowel X before heavy sonorant clusters"
  - **Count:** NN errors (errors.csv Lev-1 bucket)
  - **Examples:** word1, word2, word3
  - **Root cause:** Root phonological/technical issue.
  - **Fix in:** passes/NN_passname.lua step X
  - **Theory:** Hickey/FG citation
-->

- **[ts-/tch- mutation]** — Word-initial ts→t̪ˠ, tch→tʲ (silence second consonant). ~25 errors, fixed in pass 03.
- **[-íocht suffix]** — Connacht /iəxt̪ˠ/ not /iːçtʲ/. ~21 errors, fixed in pass 14 (Step 4n).
- **[function_word_reduction]** — do→ɡə, is→sˠ, agam/agat→uɡəmˠ/uɡəd̪ˠ, chonaic→hanʲic, mar→mˠəɾˠ, seo→ʃɔ. Fixed in _shared.lua FUNCTION_WORDS_OVERRIDE.
- **[á→aː vowel quality]** — ~64 errors where Connacht long á produces ɑː but expected aː. Fixed in pass 10 (AA_TO_A, AAI_TO_AI) + pass 14 (éa digraph E_PLUS_AA_TO_A). +12 exact match.
- **[ío→iə before ch]** — Connacht ío→iː but expected iə before velar fricative ch in specific words (críochnaigh, cíoch, beithíoch, buíochán, etc.). Fixed in pass 10 IO_TO_IA lexical table. +5 exact match.
- **[dental n medial]** — ~35 Lev-1 errors where medial broad n before vowel should be n̪ˠ not nˠ (déanaí, gcónaí, Seán, etc.). All blanket-rule attempts caused regressions. The Phase 1a rule strips dental from n before vowels unconditionally; a targeted fix requires per-word or per-vowel-context logic.

### Resolved

- **[Ulster ɑː leak via pass 13]** — fixed by new pass 15 dialect_finalize (2026-07-18): Ulster ɑː→aː re-runs after passes 13/14. Part of +47 Ulster.
- **[Ulster liquid-ɔ syllable condition]** — fixed in pass 11: ɔ only before coda liquids; intervocalic liquids/geminates take ʌ. Part of +47 Ulster.

<!-- Move fixed entries here with the commit hash -->

- **[dental l medial]** — ~63 Lev-1 errors where broad l should be dental l̪ˠ at word onset, after stop (cl-/gl-), or between vowels (mála, eolas, clocha, glór, etc.). Fixed in pass 13 Phase 1 with lexical L_CONS_NON_DENTAL exemption table (prevents over-application on loanwords like alpán, bolcán, dúlra) + L_VOWEL_DENTAL lexical table (targeted per-word for medially-occuring V+l+V). +45 exact match.

- **[comh- prefix]** — Connacht: o+mh in comh- prefix → oː (not əu). Hickey II.1.9: comh- reduces to /koː/ before consonants. Fixed in pass 06. +3 exact match (comhlacht, comhluadar, comhrá).
- **[s+onset l dental]** — Broad l after s (sl-, shl-, -sl- sequences) is denti-alveolar l̪ˠ, not lenis lˠ. Added `preceded_by_s` detection in Phase 1. +8 exact match.
- **[word-final broad n dental rule]** — Long stressed vowels keep n̪ˠ; short vowels and unstressed long vowels strip to nˠ. Removed blanket Phase 1 strip (over-applied to long-vowel words like bán). Moved nuance to Phase 1b with `not is_long or (is_long and not is_stressed)` condition. KEEP_N_DENTAL table restored for short-vowel/diphthong exceptions (Brian, buan, cuan, etc.). +9 exact match.
- **[ea→aː before rd/rn]** — 13 words with ea-derived vowels before rd/rn clusters (bearn, dearnadar, etc.) got back vowel ɑː instead of front aː. Lexical EA_FRONT_A table in Phase 3. +13 exact match.
- **[ponc/sponc/phonc o→ʊ]** — Short o before ŋk should raise to ʊ (Connacht). Added to O_TO_U lexical table in pass 10. +3 exact match (ponc, sponc, phonc).
- **[word-final slender bh/mh→w]** — Connacht: word-final slender bh/mh after long vowels (scríobh, sníomh, gníomh, gríobh, shníomh) weakens to w not vʲ. Lexical FINAL_BH_V_TO_W table in pass 14 Step 8d. +5 exact match.
- **[ll vowel lengthening exceptions]** — 6 words (mall, breall, ngeall, gheall, mhall, i ngeall ar) have short vowel before geminate ll. Lexical LENGTHEN_EXCEPTIONS table in pass 13 Phase 2. +6 exact match.
- **[slender n postalveolar]** — ~19 Lev-1 errors where slender n before vowel (airne, míneach, sní, inis) or word-initial (ní, níos) should be retracted n̠ʲ not palatal nʲ. Fixed in pass 13: GRAMMATICAL_SLENDER no longer exempts lowercase ní/níos (benchmark expects retraction), added N_VOWEL_POSTALVEOLAR lexical table for r+n, sh+n, and word-initial n+e/i sequences. NON_TENSOR_SLENDER exempts loanwords and -t- verbal suffix (caintím, guíochtaint, péinteáilte). Uses raw word_ortho for case-preserving Ní (surname) exemption. +18 exact match.

<!-- graymatter:instructions:begin — managed by `graymatter init`; edits inside this block are overwritten -->
## Memory (GrayMatter)

This project has persistent agent memory via the `graymatter` MCP tools:

- `memory_search` (`agent_id`, `query`) — call at the **start of a task** when prior context might matter.
- `memory_add` (`agent_id`, `text`) — call whenever you learn something **durable**: user preferences, decisions, conventions, gotchas.
- `memory_reflect` (`action`, `agent`, `text`/`target`) — update or forget stale facts. ⚠ takes `agent`, not `agent_id`.
- `checkpoint_save` / `checkpoint_resume` (`agent_id`) — snapshot/restore session state before major refactors or across restarts.

Use a stable `agent_id` of the form `<project>-<role>` (e.g. `myapp-backend`). Store conclusions, not conversation logs. Err on the side of remembering.
<!-- graymatter:instructions:end -->
