# Irish G2P Engine — Full LLM Report

> Generated: 2026-06-23 | Baseline: 3351/6593 (50.83%) | Connacht dialect

---

## 1. Project Overview

**Goal**: Transcribe Irish (Gaeilge) orthography to IPA for the Connacht dialect using a modular 16-pass token-array pipeline.

**Engine**: `irish_engine_new.lua` — entry point. Tokenizes a word, runs 16 sequential passes, renders output.

**Benchmark**: `_benchmark.lua` — 6,593 word-IPA pairs with multi-variant support. `bench_run.lua` compares engine output to expected IPA using exact match and Levenshtein distance.

**Lua executable**: `F:/soft/lua/lua.exe` (not on PATH). Use script files, NOT `-e` flag (corrupts UTF-8).

**Encoding**: Lua strings are raw bytes. IPA uses UTF-8 multi-byte sequences:
- ɛ = `\xc9\x9b` (U+025B)
- ɪ = `\xc9\xaa` (U+026A)
- ʊ = `\xca\x8a` (U+028A)
- ˠ = `\xcb\xa0` (U+02E0, broad)
- ʲ = `\xca\xb2` (U+02B2, slender)
- ɾ = `\xca\xbe` (U+027E, flap)
- r = `r` (U+0072, trill)
- ç = `\xc3\xa7` (U+00E7)
- ɣ = `\xc9\xa3` (U+0263)

---

## 2. Architecture

### Pass Pipeline (in order)

| # | Pass file | Purpose |
|---|-----------|---------|
| 1 | `01_polarity.lua` | Assign broad/slender polarity to consonants based on surrounding vowels |
| 2 | `02_stress.lua` | Assign primary stress (penultimate default) and secondary stress |
| 3 | `03_eclipsis.lua` | Handle eclipsis mutations (mb→m, gc→ɡ, dt→d, bp→b, ng→ŋ) |
| 4 | `04_cluster_simplify.lua` | Simplify consonant clusters (cn→cr, gn→gr, etc.) |
| 5 | `05_mutated_fricatives.lua` | Resolve lenited fricatives (bh→v, dh→ɣ, fh→∅, etc.) |
| 6 | `06_vocalization.lua` | Vocalize vowel+fricative sequences (ea+bh→əu, u+bh→əu) |
| 6d | `06d_anticipatory_raising.lua` | Anticipatory vowel raising before certain clusters |
| 7 | `07_nasalization.lua` | Nasalization assimilation |
| 8 | `08_slender_coda.lua` | Handle slender codas (lt, rt → dental/velar variants) |
| 9 | `09_consonants.lua` | Resolve consonants to IPA (broad/slender alternation) |
| 9b | `09b_vowel_adjunct.lua` | Silence vocalized fricatives, handle vowel adjuncts |
| 10 | `10_vowels.lua` | Resolve vowels to IPA (dialect-aware: short/long/diphthong) |
| 11 | `11_unstressed_reduction.lua` | Reduce unstressed vowels to ə |
| 12 | `12_epenthesis.lua` | Insert epenthetic vowels |
| 13 | `13_sonorants.lua` | Handle sonorant quality (r/ɾ, l/l̠, n/n̠) |
| 14 | `14_final_cleanup.lua` | Final devoicing, sandhi, stress overrides, function word IPA |

### Key Supporting Files

- `passes/_shared.lua` — shared constants: VOWEL_DIGRAPHS, DIALECTS table (Connacht/Munster/Ulster vowel mappings), FUNCTION_WORDS_OVERRIDE, KNOWN_PREFIXES, helper functions
- `passes/init.lua` — pass loader and orchestrator
- `irish_engine_new.lua` — tokenizer + render_output (stress mark positioning)

### Token Structure

Each token is a Lua table with:
```lua
{
  ortho = "bh",      -- original text
  phon = "v",         -- IPA output (modified by passes)
  type = "cons",      -- "vowel", "cons", "boundary", "unknown"
  palatal = true,     -- true=slender, false=broad, nil=unset
  broad = false,      -- true=broad, false=slender
  slender = true,     -- true=slender
  is_mutated = true,  -- lenition/eclipsis
  mutation = "lenition",
  stress = true,      -- primary stress
  secondary = false,  -- secondary stress
  source = "lexeme",  -- "vocalized", "strong_sonorant", etc.
  restore_i = true,   -- restore ə→ɪ after reduction
  is_voiceless = false,
  is_epenthetic = false,
}
```

### Render Output

`render_output()` in `irish_engine_new.lua`:
1. Moves stress marks from vowel to preceding onset consonant (IPA convention: ˈCV not CˈV)
2. Concatenates all non-empty phon values

---

## 3. Current Accuracy

### Overall

- **Exact match**: 3,351 / 6,593 = **50.83%**
- **Avg Levenshtein**: 1.15
- **Normalized Levenshtein**: 94.27%

### Error Distribution by Levenshtein Distance

| Distance | Count | % of wrong |
|----------|-------|------------|
| Lev-1    | 1,176 | 36.3%      |
| Lev-2    | 913   | 28.2%      |
| Lev-3    | 586   | 18.1%      |
| Lev-4+   | 567   | 17.5%      |

### Top Lev-1 Substitution Buckets

| Count | Substitution | Examples | Notes |
|-------|-------------|----------|-------|
| 12 | ɾ → r | treascair, car, greannach | Trill vs flap in coda/consonant clusters |
| 3 | a → ə | fadhbanna, adhairc, mba | Over-reduction of unstressed a |
| 2 | ɪ → e | beidh, tirim | Short i quality before slender consonant |
| 2 | ə → ː | riaráiste, carria | Length mismatch |
| 2 | ː → ə | beithíoch, cíoch | Length mismatch |
| 2 | ʲ → ˠ | facabhair, Dé Sathairn | Broad/slender polarity mismatch |
| 2 | ɛ → ə | le déanaí, le chéile | Reduction over-applies |
| 2 | ʲ → l̠ | leic, cinnigí | l̠ velarization issue |
| 2 | v → w | vác, Baváir | bh/v quality |
| 2 | ə → ɑ | beathaisnéisí, gabhlóg | a quality in unstressed |

### Top Broad Categories

| Category | Count | % of wrong |
|----------|-------|------------|
| Other/multi-character | 1,367 | 42.2% |
| i/ɪ/e/ɛ quality | 311 | 9.6% |
| Schwa vs full vowel | 287 | 8.9% |
| Length (ː) | 277 | 8.5% |
| Consonant quality (ç/h/x/ɣ/v/w/j) | 256 | 7.9% |
| Stress placement | 225 | 6.9% |
| a/ɑ quality | 216 | 6.7% |
| o/u/ɔ/ʊ quality | 148 | 4.6% |
| Consonant broad/slender (ˠ/ʲ) | 106 | 3.3% |
| r vs ɾ | 38 | 1.2% |
| Devoicing | 11 | 0.3% |

---

## 4. Dialect Settings (Connacht)

From `_shared.lua`:

```lua
connacht = {
  ao = "iː", ai = "a", ea = "a", eo = "oː", ["ío"] = "iː",
  oi = "ɔ", ui = "ʊ", ua = "uə", ia = "iə", ["éi"] = "eː",
  short = { a = "a", o = "ɔ", u = "ʊ", i = "ɪ", e = "ɛ" },
  long  = { a = "ɑː", o = "oː", u = "uː", i = "iː", e = "eː" },
  diphthong = {},
  r_lowering_trigger = true,
  anticipatory_raising = true,
  vowel_gradation = {
    a = { broad = "a", slender = "ɛ" },
    o = { broad = "ɔ", slender = "ɔ" },
    u = { broad = "ʊ", slender = "ʊ" },
    i = { broad = "ɪ", slender = "ɪ" },
    e = { broad = "ɛ", slender = "ɛ" },
  },
}
```

**Key Connacht features**:
- ao → iː
- Short a = [a], Long áː = [ɑː] (back a)
- ui → ʊ
- oi → ɔ
- r_lowering_trigger = true (r affects preceding vowel)
- anticipatory_raising = true

---

## 5. Known Issues & Gotchas

### Encoding

- **Lua `-e` flag corrupts UTF-8**: Always use script files, not `-e` for IPA strings
- **CRLF line endings**: Some Lua files use CRLF. Python edits break these. Edit tool sometimes fails on multi-byte IPA chars.
- **Edit tool on IPA**: The Edit tool may fail to match strings containing multi-byte IPA. Use Python binary edits with explicit byte patterns when needed.

### Pass 10 (Vowels) Corruption Risk

`passes/10_vowels.lua` is 675+ lines. Python string replacements break Lua syntax due to:
- Multibyte IPA characters
- CRLF line endings
- The `end      end` pattern on line 423 (closes both `if phon == "ɛ"` and `if ortho == "oi"` blocks)

**Rule**: Fix vowel quality issues in pass 14 (`14_final_cleanup.lua`) instead.

### r vs ɾ Distribution

The expected IPA uses BOTH r (trill) and ɾ (flap) in a complex phonological pattern:
- ɾ is used in ~2,700 positions (most common)
- r is used in ~42 positions (consonant clusters, specific words)
- Blanket trill→flap replacement caused catastrophic regression (3349→2018)
- Cluster-based rules still regressed (3349→2971)
- **SKIP**: This is low-ROI unless a narrow trigger context can be identified

### Lexical Exceptions vs Structural Rules

The engine has ~50 lexical exception entries across passes. Categories:
1. **Legitimately required**: goid/ghoid (oi→ɞ), coite/coiteann (oi→ɔ), 12 stress-override phrases, loanword overrides
2. **Phonological gaps**: tháinig/easpaig (final ɟ preservation), dubhach (ubh→ʊw), domlas (o→u before m)
3. **Padded hacks**: ar bís/ar nós/ar dtús (ar→əɾˠ) — 3-word lexical exception for function word

---

## 6. Remaining Error Patterns

### 6.1 a/ɑ Quality (~216 errors, HIGHEST ROI)

**Problem**: Connacht short a is [ɑ] (back) but engine gives [a] (front). Long áː is [aː] but engine gives [ɑː].

**Fix**: Swap the short/long a mapping in `_shared.lua` dialect definition:
```lua
short = { a = "ɑ", ... },  -- was "a"
long  = { a = "aː", ... },  -- was "ɑː"
```

**Risk**: May cause regressions in words where [a] is currently correct. Need to test carefully.

### 6.2 Stress in Single-Syllable Words (~225 errors)

**Problem**: Many single-syllable words have spurious stress marks. Expected IPA has no stress on monosyllabic content words.

**Examples**: bhfuair (got ˈwuəɾʲ, exp wuəɾʲ), uair (got ˈuəɾʲ, exp uəɾʲ), ruaig (got ˈɾˠuəɟ, exp ɾˠuəɟ)

**Fix**: Likely a rule in pass 02 or 14 that incorrectly assigns stress to monosyllabic words.

### 6.3 Consonant Broad/slender — l vs l̠ (~106 errors)

**Problem**: The expected IPA uses l̠ (velarized/dark l) in many positions where engine gives l or lʲ.

**Examples**: leic (got lʲɛc, exp l̠ɛc), lios (got lʲɪsˠ, exp l̠ʲɪsˠ)

**Fix**: Need to map l → l̠ in specific phonological contexts.

### 6.4 o/u/ɔ/ʊ Quality (~148 errors)

**Problem**: o before broad m should raise to u in Connacht. Also various o/u quality mismatches.

**Examples**: domlas (got ˈd̪ˠɔmˠlˠəsˠ, exp ˈd̪ˠumˠlˠəsˠ), comhluadar (got ˈkəulˠuəd̪ˠəɾˠ, exp ˈkoːlˠuəd̪ˠəɾˠ)

**Fix**: Add a general rule: o → u before broad m in pass 10. Currently fixed only via lexical overrides (domlas).

### 6.5 i/ɪ/e/ɛ Quality (~311 errors)

**Problem**: Multiple sub-patterns:
- Short i in initial syllable before slender consonant → should be i not ɪ
- oi before slender consonant → ɪ not ɛ (partially fixed via restore_i)
- e → ɛ in unstressed positions

**Fix**: restore_i mechanism handles ~60 errors. ~20 remaining gaps need either additional restore_i words or rule-level fixes.

### 6.6 Schwa vs Full Vowel (~287 errors)

**Problem**: Some words over-reduce to ə, others under-reduce (keep full vowel where ə expected).

**Fix**: restore_i handles under-reduction. Over-reduction needs analysis of which words should keep ɪ.

### 6.7 Length (~277 errors)

**Problem**: Many words have length mismatches (short where long expected, or vice versa).

**Fix**: Mostly lexical — no general rule possible. Low ROI.

### 6.8 Consonant Quality (~256 errors)

**Problem**: v/w confusion (bh→v vs bh→w), ç/h confusion (slender ch/sh), x/ɣ confusion.

**Examples**: scríobh (got ʃcɾʲiːvʲ, exp ʃcɾʲiːw), vác (got vɑːk, exp wɑːk)

**Fix**: Medium complexity. v→w and w→v are rule-level issues in pass 09.

### 6.9 r vs ɾ (38 Lev-1 errors)

**Problem**: Engine uses ɾ (flap) everywhere, but expected uses r (trill) in ~42 specific positions.

**Examples**: treascair (got ˈtʲɾʲasˠkəɾʲ, exp ˈtʲrʲasˠkəɾʲ), crosta (got ˈkɾˠɔsˠt̪ˠə, exp ˈkrˠɔs̪ˠt̪ˠə)

**Verdict**: LOWEST ROI. Blanket swap caused catastrophic regression. Skip.

### 6.10 Devoicing (11 errors)

**Problem**: Final slender g sometimes devoices to c when it shouldn't (or vice versa).

**Examples**: céadta (got ˈceːd̪ˠt̪ˠə, exp ˈceːt̪ˠə) — extra d̪ˠ

**Fix**: Already handled via lexical exception tables (tháinig/easpaig added this session).

---

## 7. Previous Fix History

### This Session (2026-06-23)

| Commit | Change | Score | Delta |
|--------|--------|-------|-------|
| 4031dea (reverted) | Reorder restore_i before devoicing + lexical hacks | 3351 | +2 (but hacks) |
| 5cd14df | Revert above | 3349 | baseline |
| ae12340 | Lexical exceptions for tháinig/easpaig final ɟ preservation | 3351 | +2 |

### Prior Sessions

- 3326 → 3349: 7 commits, +23 exact, 0 regressions
  - fáiscim in reduction exceptions
  - dílis in is_keep_i table
  - Doire rule scope fix
  - goid/ghoid/coite/coiteann overrides
  - Stress override table for 12 phrases
  - s-before-m broad rule
  - mo function word

- Earlier sessions: Various fixes for r polarity, slender ch/sh, eclipsis, vocalization

---

## 8. Actionable Next Steps

### Priority 1: a/ɑ Quality Swap (structural, ~216 errors)

Edit `_shared.lua` Connacht dialect:
```lua
short = { a = "ɑ", ... },
long  = { a = "aː", ... },
```
Then run benchmark, check for regressions. Expected: +100-200 exact matches.

### Priority 2: Stress on Monosyllabic Words (~225 errors)

Investigate pass 02 (`02_stress.lua`) to understand why monosyllabic words get stress marks. Fix: suppress stress on monosyllabic content words.

### Priority 3: l̠ Velarized l (~106 errors)

Add a rule in pass 09 to map l → l̠ in broad contexts.

### Priority 4: o→u before broad m (~148 errors)

Add to pass 10: if ortho == "o" and next consonant is broad m, then phon = "u".

### Priority 5: Remaining i/ɪ quality gaps (~20-30 errors)

Add restore_i words or fix rule in pass 10.

---

## 9. Testing Commands

```bash
# Run benchmark
F:/soft/lua/lua.exe bench_run.lua "label"

# Test single word
F:/soft/lua/lua.exe -e "local e=require('irish_engine_new'); print(e.transcribe('word','connacht'))"

# Generate detailed per-word output
F:/soft/lua/lua.exe bench_run.lua "label" "../output.tsv"

# Run error analysis
PYTHONIOENCODING=utf-8 python _py_analysis.py > ../docs/error_analysis_current.md
```

---

## 10. File Locations

- **Engine**: `irish_engine_new.lua`
- **Passes**: `passes/` directory (16 files)
- **Benchmark**: `_benchmark.lua`, `bench_run.lua`
- **Reference data**: `_base.tsv` (per-word engine vs expected)
- **Analysis scripts**: `_py_analysis.py`, `_full_analysis.lua`
- **Documentation**: `docs/error_analysis_current.md`
- **Memory**: GrayMatter (agent_id: `irish-g2p-engine`)

---

## 11. Constraints

1. **No data leakage**: Engine must never reference `_benchmark.lua`
2. **No catastrophic regressions**: Any structural change must be tested — a rule that fixes 200 words but breaks 100 is a net negative
3. **Connacht-only**: All fixes target Connacht dialect. Munster/Ulster have separate dialect settings.
4. **Lexical exceptions are acceptable**: Irish phonology has genuine lexical irregularity. A 5-word lexical exception table that fixes 10 errors is a valid improvement.
5. **Frequent commits**: Commit after each fix with benchmark score in message.
