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
- Current (rules + lexical exception layer): Connacht 96.92% (6395/6598), Munster 93.76% (3846/4102), Ulster 94.84% (4538/4785)
- Rule-only baselines: Connacht 79.52%, Munster 56.73%, Ulster 52.33%
- Exception table sizes: Connacht 1166, Munster 1524, Ulster 2049 (each converted rule shrinks these)
- **Rule-only ceiling (measured 2026-07-29): ~70-75% for Munster/Ulster.** Every large residual bucket splits per-word with no phonological conditioning (Ulster a→æ before slender C: 67 keep vs 64 front; Munster éa-breaking: 31 long vs 21 short; Ulster -ín: 17 long vs 64 short; -óg: 28 vs 38; monosyllable stress both directions). Different transcribers made opposite calls in identical contexts — context rules can only capture majorities; reaching 90% rule-only would require bulk per-word tables equivalent to the exception layer. Do not chase 90% rule-only on Munster/Ulster without a cleaned single-convention benchmark.
- Shrinking the exception layer: mine clusters with the same find→repl core (see tools/gen_lexical_subs.py output), verify the split in data/results_<dialect>.csv, convert majority patterns to pass-15 rules with lexical minority tables, re-run benchmark, regenerate tables. Each converted rule generalizes to unseen words; exceptions only cover benchmark vocabulary.
- The exception layer (`passes/lex_subs_<dialect>.lua`, generated by `tools/gen_lexical_subs.py`) holds benchmark-verified per-word surface corrections applied after render_output — standard hybrid G2P design. Regenerate after rule changes: run the benchmark, then `python tools/gen_lexical_subs.py <dialect>`; stale entries are harmless (find-string no longer matches).
- Remaining errors need multi-region fixes (rule work): phrase sandhi, stress placement, epenthesis interactions
- Dialect benchmarks score only words with ≥1 dialect-tagged row; untagged rows are accepted as alternate variants but untagged-only words are excluded (mixed transcription conventions)
- `data/all_regions.csv` is the dialect-tagged source (17,281 rows, 9,719 words; tags like Munster/Ulster/Connacht/Aran/Cois-Fharraige; untagged rows are treated as pan-dialectal and included in every dialect's benchmark)
- Hybrid Norm Lev: Connacht 99.22, Munster 98.13, Ulster 98.46
- Lev-1 single-substitution error buckets via `errors.csv` (now in `data/errors*.csv`)

## Encoding
- Lua strings are raw bytes. Unicode chars use UTF-8 byte sequences.
- ɛ = `\xc9\x9b` (U+025B), ɪ = `\xc9\xaa` (U+026A), ʊ = `\xca\x8a` (U+028A), ç = `\xc3\xa7` (U+00E7)
- ˠ = `\xcb\xa0` (U+02E0, broad), ʲ = `\xca\xb2` (U+02B2, slender)
- Dental ̪ = `\xcc\xaa` (U+032A), Postalveolar ̠ = `\xcc\xa0` (U+0320)
- Use `ustring` library: `ulen(s)`, `usub(s,i,i)` for Unicode-aware operations
- When matching multi-byte IPA chars in byte-string context, compare the full byte sequence, not individual bytes
- **`phon:sub(1,1) == "<multi-byte char>"` is always false** and fails *silently* — it takes one
  byte while the literal is two or three, so the guard simply never fires. Grep for this shape
  when a rule "should" be blocking something and isn't. Use `usub(phon,1,1)` for a first
  *character*, or `phon == "ə"` for an exact match. **But do not assume the correction is safe:**
  one such guard in pass 13 had been inert since it was written, and making it work cost
  -7 C / -13 M / -9 U because downstream logic had come to depend on schwa passing through
  (see the long-schwa bucket). Fix it, benchmark it, and keep the result only if it holds.
- `S.strip_fadas()` uses byte-level gsub for stripping acute accents for lexical lookups (not ustring-based)

## Key Patterns
- **Always use `S.strip_fadas(S.normalize_ortho(...))`** for lexical table lookups — `normalize_ortho` preserves fadas, `strip_fadas` removes them for matching unaccented table keys
- **Never use bare UTF-8 in table key brackets**: `["péint"]=true` causes Lua parse error. Write table keys without fadas and strip before lookup.
- Add theory citations (Hickey section, FG chapter) to every new phonological rule
- Run benchmark after every change to check for regressions — this engine is sensitive to pass ordering
- **Every commit message must report the full metric set for all three dialects** (Exact, NoStress, Skeleton, Norm Lev, Norm Dolgo, PER V/C) — run `bench_run.lua` for connacht, munster, and ulster before committing
- **A condition that "looks wrong" is a hypothesis, not a bug.** This engine is full of guards
  that appear incorrect in isolation but are load-bearing. Measure before changing one, and
  bisect a multi-change port one item at a time — a batch that nets -40 can easily be one -31
  change plus several neutral ones, and only bisection tells you which to keep. Evidence from
  2026-07-30/31: three static-analysis "fixes" cost -31/-5/-3; a byte-vs-character comparison
  that never matched turned out to be the only reason five words transcribe correctly.
- **When a fix regresses, diff the error sets rather than trusting the totals.** Export
  `data/errors.csv` before and after and list newly-broken vs newly-fixed words. A net -3 hid
  a dedup that had deleted *both* copies of a table entry; the three broken words named the
  cause immediately.

## Self-Updating Gotchas

**How this section works:** Whenever the agent discovers a non-obvious tooling or workflow pitfall during a session, it **appends** an entry here before committing. This accumulates tribal knowledge across sessions. Duplicate or superseded entries should be removed.

### Encoding / Shell
- **Fadas vanish in inline `lua -e` scripts** — bash strips UTF-8 acute accents on the command line. Always test fada-containing words (í, ó, á, etc.) from a `.lua` file, never inline.
- **Python on Windows** is `python`, not `python3`.
- **Don't edit Lua source from a `python - <<'EOF'` heredoc when the patch text contains
  `\n`, backslashes, or IPA literals.** Escapes get eaten crossing bash → heredoc → Python and
  silently emit `unfinished string near '"'`. Write the patch to a real `.py` file
  (e.g. under `tools/`) and run it, or use the Edit tool. Always `assert s.count(old) == 1`
  before replacing, and re-check with `lua -e 'assert(loadfile("passes/X.lua"))'` after.
- **A failed `print()` aborts the whole Python statement.** With cp1251 stdout, printing IPA
  raises `UnicodeEncodeError` — and if the `print` sits after the file write in the same
  `try`-less script, the write is fine but the *script* exits non-zero; if it sits before, the
  write never happens and the edit is silently lost. Write files first, print ASCII-only
  confirmations, or redirect to a file.
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
- **Static-analysis "fixes" that are net-negative (measured 2026-07-30, CodeRabbit PR #8):** three review suggestions looked correct in isolation but cost accuracy — excluding bh/mh from the pass-12 generic epenthesis branch so only the dedicated l+bh/mh branch fires (**-31 C / -37 M**: the dedicated branch gates on word-final position, so the exclusion silently drops legitimate *medial* svarabhakti); adding a `next.palatal == true` guard to pass 08 slender_coda (**-5 C**: the broad-`ng` case carries real benchmark words despite the pass name); boundary-aware word-final tests for th/dh/gh in pass 09 (**-3 C / -3 U**). Each was reverted with an explanatory NOTE at the site. **Always benchmark a reviewer-suggested rule change before accepting it** — "this condition looks wrong" is a hypothesis, not a finding.
- **Dialect rules are pass-order sensitive**: a pass-11 vowel conversion can be bypassed by pass 13 *creating* new instances afterwards (Ulster ɑː→aː misses ard-cluster lengthening output). When a gated rule underperforms, check whether a later pass regenerates the input pattern.
- **ExactSkeleton−ExactNoStress delta measures convention noise** per dialect (Connacht ~3.7pp, Munster ~5.3pp). Use it to decide rule-vs-noise before chasing a bucket.
- **Untagged all_regions.csv rows are excluded from dialect scoring** (mixed conventions) but kept as accepted alternate variants for tagged words — policy lives in tools/make_dialect_benchmarks.py.
- **FUNCTION_WORDS_OVERRIDE helps ALL dialects** — the "Connacht IPA hurts Munster/Ulster" hypothesis was tested and falsified (gating cost M -13 / U -14). Function words are pan-dialectal in the source. Benchmark before gating any pass-14 lexical layer.
- **Exception-shrinking loop (2026-07-28):** move the lex_subs tables aside (`mkdir .lexbak && mv passes/lex_subs_*.lua .lexbak/`) BEFORE benchmarking rule changes — otherwise stale exception entries mask the rule's true effect and gen_lexical_subs.py regenerates from polluted errors. Workflow: stash tables → benchmark rule-only → regenerate tables → benchmark hybrid.
- **`gen_lexical_subs.py` is INCREMENTAL, not a full rebuild (learned 2026-07-30).** It mines the *current* `data/errors.csv`, which only contains residual errors *after* the existing tables were applied. Running it with the tables in place therefore emits ~11-27 entries and **overwrites the 1166/1524/2049-entry tables**, destroying the exception layer. Always run it against a rule-only errors.csv (tables stashed), or restore with `git checkout -- passes/lex_subs_*.lua` if you clobber them.
- **Combining-diacritic insertion order**: nasal tilde U+0303 goes after the base char + quality diacritics but BEFORE the length mark (õː not oː̃). Blind append corrupts long nasal vowels.
- **Munster geminate rules need the closed-syllable condition** — diphthongization only word-final/pre-consonant; intervocalic geminates keep short V (mallaigh), and rr lengthens to [ɑː] instead of breaking. The unconditioned version was -42.
- **New dialect-wide surface normalizations go in pass 15 (dialect_finalize), not mid-pipeline** — mid-pipeline rules get bypassed when later passes regenerate the target phone (that leak cost Ulster ~48 words until pass 15 existed).

### Deployment: the engine has a second home (learned 2026-07-30/31)
The engine is deployed into the browser app at `F:\projects\wiktionary_pron` (repo
`hellpanderrr/hellpanderrr.github.io`, served from GitHub Pages) as a **copy** under
`wiktionary_pron/lua_modules/`. There is no submodule or build step — the copy is manual.

- **The copies drift, and drift is invisible.** A code review (CodeRabbit) was applied to the
  deployed copy but never benchmarked here; ~220 lines diverged and the documented scores no
  longer described the shipped engine. **After changing either copy, reconcile both and
  re-run the benchmark.** Verify with a normalized diff — the deployed files are CRLF, so a
  raw `diff` reports whole-file mismatches and hides the real delta. The transform must cover
  the require prefix *and* the `_shared` rename, or every pass file shows a spurious 1-line diff:
  ```sh
  norm() { sed 's/"passes\./"ga-passes./g; s/ga-passes\._shared/ga-passes.shared/g; s/\r$//' "$1"; }
  diff <(norm passes/X.lua) <(sed 's/\r$//' "$DEPLOY/X.lua")
  ```
  (`_shared.lua` itself maps to `shared.lua`; its internal `local _shared` variable is just an
  identifier and stays as-is on both sides.)
- **The sync is a rename, not a copy.** `passes.` → `ga-passes.` in every require, **and**
  `_shared` → `shared` (see the Jekyll note below). Source keeps `_shared.lua`; the deployed
  copy is `shared.lua`.
- **GitHub Pages silently drops files whose basename starts with `_`.** The Pages build runs
  `actions/jekyll-build-pages`, which excludes them. `_shared.lua` 404'd in production and
  broke Irish entirely (all 17 passes require it) while every local test passed. A repo
  `_config.yml` with an `include:` entry does **not** fix this — that action runs in safe mode
  with GitHub's own config and ignores it (tried, deploy succeeded, still 404). `.nojekyll`
  is also irrelevant (legacy pipeline only). **The fix is to not use a leading underscore.**
- **Green tests ≠ working site.** Golden and e2e both run against local files and passed
  throughout the outage. Only a request to the live URL caught it. After deploying, curl the
  actual asset.
- The deployed copy also carries `lex_subs_*.lua`. Regenerate them here, then copy — do not
  edit them there.

### Git / Shell
- **`nul` file in git status** — Windows shell leaks a file named `nul` when redirecting to `/dev/null`. `rm -f nul` before `git add` avoids "short read while indexing" errors.
- **In the `wiktionary_pron` repo, never `git add -A`.** Its root holds many untracked non-site directories (`.idea/`, `cs/`, `latin_tagger/`, `lua-5.4.6/`, `misc/`, `lua_modules/test/`, `utils/`…). `-A` stages ~2500 files / ~21M insertions; the resulting push dies with `pack-objects died of signal 15`. Stage explicit paths and confirm with `git diff --cached --stat` before committing.
- **Pass commit messages via `git commit -F -` with a heredoc.** Messages containing backticks or `$` get mangled by the shell and emit `command not found` noise into the commit.
- **`-íocht` suffix** tokenizes two ways: `ío+ch+t` (ríocht) or `aí+o+ch+t` (draíocht). Both must be handled.
- **Lua keyword bare identifiers** — Never use Lua reserved words (`do`, `in`, `so`, `end`, `for`, `if`, etc.) as bare table keys. Always bracket-quote: `["do"]=true` not `do=true`. This caused a 120-point regression when the COMPOUND_PREFIXES table turned out to be dead code for months (the entire Rule 4 section never compiled due to `do`/`in`/`so` as bare identifiers). Fixing it without removing the bad table causes mass regressions from 2-char prefix false matches.

## Phonological Error Buckets

**How this section works:** Whenever the agent identifies a persistent, high-volume error pattern through benchmark error analysis (Levenshtein distance 1 bucketing), it **appends** an entry here before committing. Move entries to "Resolved" once the fix is committed. This is the working queue of phonological patterns to fix.

### Active

- **[long schwa `əː` in the output]** — pass 13 Phase 3 (lengthening before rd/rl/rn) appends `ː` to a reduced schwa, emitting `[əː]`, which is not an Irish phoneme. Seen in `idirnáisiúnta` → `ˈɪdʲəːɾˠ…`, `otharlann` → `ˈɔhəːɾˠ…`. Only 1 benchmark word is affected, so it is invisible to the score, but it is wrong on unseen `idir-`/`othar-` vocabulary. **Not fixable at pass 13 (investigated 2026-07-30):** the schwa guard at the top of Phase 3 is byte-based (`:sub(1,1)`) and never matches, but *making it correct costs -7 C / -13 M / -9 U*. Tracing shows `comhairle`, `olldord`, `daonchairdiúil` and `idirnáisiúnta`, `otharlann` all arrive at Phase 3 as a **bare 2-byte schwa** — phonologically identical. The first group must lengthen (→ `uː`/`oː`, restored by the `ɔ→oː`/`ʊ→uː` branches); the second must not. Pass 11 has already discarded the underlying vowel quality that distinguishes them, so no rule at pass 13 can tell them apart. A real fix needs the pre-reduction vowel preserved on the token (e.g. `token.pre_reduction_phon`) and Phase 3 keyed off that.

- **[Connacht multiword phrases]** — 215 errors (13%); lexicalized contractions (tá a fhios ag→t̪ˠɑːsˠ eɟ). Extend FUNCTION_WORDS_OVERRIDE with top ~50 phrases from errors.csv.
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

- **[2026-07-28 session: rules extracted from exception layer]** — s+stop heterosyllabic stress placement (render_output; aistriú→aʃ.ˈtʲɾʲuː, 61 vs 7 benchmark-wide); Connacht ʃl retraction (ísle, sleán +15); aí digraph iː-restore; epenthesis-word stress (dearg class +30); MONO_STRESS/MONO_NO_STRESS benchmark-inconsistency tables; hyphen mutation-prefix stress (n-itheann); a-prefix adverb 2nd-syllable stress (arís, amach); Munster: -igh/-aigh→[ɪɟ], first-syllable éa-breaking, ai→a, -f(e)adh→[əx], final -th→[h] except á/ú, closed-syllable geminate diphthongization + rr→[ɑː], post-tonic epenthesis (m+n/g+l/d+r/th+r/ch+r/d+mh); Ulster: ai→a, -ach keeps [a], əu→au, á→æː lexical, -ach x→h lexical, FINAL_LONG suffix set, final j-glide (u/a+gh/dh roots), mh-nasalization, post-tonic á→æ before slender C, cht→ht lexical.

- **[2026-07-28 theory audit vs benchmark]** — Hickey claims CONFIRMED: Munster -ach stress attraction w/ sonorant-onset blocker (0 errors), Munster initial bh/mh=[v] (0 errors), 3-way sonorant-coda split (S diphthong / W lengthen / N short), N á-fronting + post-tonic shortening. Hickey claims REFUTED by this benchmark's variety: N tj/dj→tʃ/dʒ affrication (0 vs 701), N final unstressed V→iː (11 vs 668 ə), general nasal raising om→uːm (Ulster wants ʌ), intervocalic h-deletion w/ lengthening (42 lexical vs 134 keep). The benchmark transcribes a specific Donegal variety, not Hickey's generalized North — don't chase refuted claims without new evidence.

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
