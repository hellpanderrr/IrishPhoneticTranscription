# Token-Array Monolith Replacement: Irish G2P Engine

**Date:** 2026-06-14  
**Author:** Claude (brainstorming session with user)  
**Goal:** Replace the monolith `irish.lua`/`irish_engine.lua`/`irish_rules.lua` (~500KB) with a clean, modular token-array pipeline (`passes/` directory + orchestrator).  

---

## 1. Problem Statement

The current production engine is a single monolith (`irish.lua`, `irish_engine.lua`, `irish_rules.lua`, `irish_rules_data.lua`, `irish_processors.lua`, `irish_core.lua`) totaling ~500KB of Lua code. It uses a marker-based string-manipulation pipeline where orthographic patterns are replaced with internal markers, resolved to base phonemes, then refined with diacritics.

This architecture has two critical flaws:
1. **String spaghetti:** Rules operate on opaque strings via regex, making context-dependent decisions fragile and hard to debug.
2. **Untestable passes:** Individual pipeline stages cannot be tested in isolation; only the full pipeline can be validated.

The goal is to replace this with a clean, modular pipeline where each stage is an independent function operating on an array of typed token objects — a compiler-style architecture (Lexer → Semantic Analysis → AST Transformations → Code Generation).

---

## 2. Target Architecture

### 2.1. Token Schema

Every orthographic element is represented as a token object:

```lua
{
  ortho,            -- original orthographic text (e.g. "bh", "ea", "s")
  phon,             -- phonetic output (mutated by passes; empty string = silent)
  type,             -- "vowel" | "cons" | "boundary" | "unknown"
  palatal,          -- nil | true | false (broad/slender polarity)
  broad, slender,   -- derived booleans from palatal
  is_mutated,       -- bool: true if this token underwent lenition/eclipsis
  mutation,         -- "lenition" | "eclipsis" | nil
  ortho_indices,    -- {start, end} character positions in original string
  stress,           -- bool: true if this vowel bears primary stress
  source,           -- provenance tag: "lexeme", "cluster_shift", "vowel_before_silent_fricative", etc.
  is_voiceless,     -- bool: true for sonorants after h-mutations (GD/CR: m̥, n̥, l̥, r̥)
  is_epenthetic,    -- bool: true for svarabhakti vowels inserted by Pass #12; immune to stress and certain gradation rules
}
```

### 2.2. Context Object

Shared, read-only state passed to every pass:

```lua
context = {
  dialect = "connacht",
  word_ortho = "seanbhean",
  is_monosyllabic = false,         -- set by stress pass (#2)
  vowel_count = 3,                 -- total vowel tokens
  root_vowel_count = 2,            -- vowel tokens in root only (for prefix words like "seanbhean")
  stress_index = 2,                -- token index of primary stress (1-based)
  stress_position = 1,             -- char offset in original ortho (0-based)
  known_prefixes = { "sean", "mór", "droch", "deich", "go", "an", ... },
}
```

**Rule:** A pass may NOT read a context field that hasn't been written yet. Passes with `writes_context = false` (the default) must not modify context.

### 2.3. Pass Interface

Every pass file exports a single function:

```lua
return {
  name = "pass_name",
  run = function(tokens, context) → tokens,  -- may mutate in place or return new array
  writes_context = false,   -- only stress pass (#2) and vowel_count pass set this to true
  depends_on = {},          -- pass names that must have run first
}
```

### 2.4. Orchestrator

`irish_engine_new.lua` loads all passes in order, validates dependency constraints, and calls them sequentially:

```lua
local passes = require("passes.init")  -- loads all 14 passes in order

function engine.transcribe(word, dialect)
  local tokens = tokenize(word)
  local context = { dialect = dialect or "connacht", word_ortho = word, ... }
  for _, pass in ipairs(passes) do
    tokens = pass.run(tokens, context)
  end
  return render_output(tokens)
end
```

---

## 3. Pass Ordering

| # | Pass Name | Purpose | New/Extracted |
|---|-----------|---------|---------------|
| 1 | `polarity` | Assign broad/slender to consonants from flanking vowels | Extracted |
| 2 | `stress` | Calculate primary stress index; compute root_vowel_count for prefix words | Extracted (moved up) |
| 3 | `eclipsis` | Handle eclipsis markers (mb, gc, bpr, dt, ngc, ngl) | **New** |
| 4 | `cluster_simplify` | Normalize consonant clusters (chn→chr, cn→cr, gn→gr, mn→mr) | **New** |
| 5 | `mutated_fricatives` | Handle lenited fricatives (bh, mh, ch, th, sh, fh); ghost-palatal trace on fh deletion | Extracted |
| 6 | `vocalization` | Vowel+fricative merging (ea+bh→əu); stress-aware: -adh stressed→[ai], unstressed→[ə] | Extracted |
| 7 | `nasalization` | Vowel nasal raising (o/u/ó/ú→uː before nn/ng) | Extracted |
| 8 | `slender_coda` | Vowel gradation before slender codas (lt/rt→ɛ, ng→ɪ) | Extracted |
| 9 | `consonants` | Resolve consonant tokens to IPA (broad/slender, voiceless sonorants) | Extracted |
| 10 | `vowels` | Resolve vowel tokens to IPA (dialect-aware, long/short, diphthongs) | Extracted |
| 11 | `unstressed_reduction` | Reduce unstressed vowels to schwa [ə] or [ɪ] | Extracted |
| 12 | `epenthesis` | Insert svarabhakti vowels before heterorganic sonorant+voiced-obstruent clusters after short stressed vowels | **New** |
| 13 | `sonorants` | Vowel lengthening/diphthongization before strong sonorants (nn, ll) in monosyllables/word-final | **New** |
| 14 | `final_cleanup` | Diacritics (velarization/palatalization), final devoicing of slender g→[c], final ç/ɣ/h deletion after long vowels, sandhi | **New** |

---

## 4. Detailed Pass Notes

### Pass #1: `01_polarity.lua`

**Source:** Extracted from current `assign_polarity` in `irish_tokens.lua`.

Scans left and right of each consonant token to find flanking vowels. Sets `palatal`, `broad`, `slender` on the consonant based on the polarity of its vowel neighbors.

No changes needed.

---

### Pass #2: `02_stress.lua`

**Source:** Extracted from current `apply_stress`. Enhanced with `root_vowel_count` for prefix words.

**Logic:**
1. Count vowel tokens → `context.vowel_count`
2. If monosyllabic (1 vowel): `context.is_monosyllabic = true`, `context.stress_index = vowel_index`
3. Check if word starts with a known prefix (sean, mór, droch, deich, etc.): if so, compute `context.root_vowel_count` (vowel tokens after the prefix), and stress the first root vowel, not the prefix vowel
4. For non-monosyllabic words without a prefix: stress first vowel (Connacht rule: initial fixed stress)
5. Write `context.stress_index` and `context.stress_position` (char offset)

**Example:** `seanbhean` has tokens [s, e, a, n, b, h, e, a, n]. Prefix "sean" occupies tokens 1-4. Root vowels are tokens 7 and 8 (`ea` in `bhean`). Stress is on token 7.

---

### Pass #3: `03_eclipsis.lua`

**New.** Handles eclipsis markers where initial consonants undergo nasal substitution.

**Eclipsis mapping:**
| Eclipsis | Result | Notes |
|----------|--------|-------|
| `mb` | `mˠ` | voicing unchanged |
| `gc` | `ɡ` | c → g |
| `bpr` | `bˠ` | p → b |
| `dt` | `d̪ˠ` | t → d |
| `ngl` | `ŋ` | l → ng |
| `ngc` | `ŋ` | c → ng |
| `bF` / `mF` | `h` or `fˠ` | f → b → silent in initial position |

Eclipsis in Irish is largely a spelling phenomenon: the pronunciation of `mb` is just `mˠ`, `gc` is `ɡ`, etc. The pass sets the token's base consonant correctly so that polarity and consonant resolution in later passes use the right base form.

---

### Pass #4: `04_cluster_simplify.lua`

**New.** Normalizes consonant clusters before they hit the main pipeline.

**Rules:**
- `chn` → `chr`
- `bhth` → `r`
- `cn` → `cr` (before a vowel — sonorant shift per Hickey Ch.2)
- `gn` → `gr` (before a vowel)
- `mn` → `mr` (before a vowel)

Modifies tokens in-place (updates `ortho` field). Must run before Pass #5.

---

### Pass #5: `05_mutated_fricatives.lua`

**Source:** Extracted from current `apply_final_mutated_fricative_polarity` + scattered logic in `resolve_consonants`.

Handles lenited fricatives: `bh`, `mh`, `dh`, `gh`, `th`, `sh`, `fh`.

**Key behaviors:**
- `bh/mh` after vowels → voiced labial approximant `[w]` or `[vʲ]` depending on polarity
- `dh/gh` after vowels → voiced velar approximant `[ɣ]` or `[j]` depending on polarity
- `th/sh` after vowels → `[h]` (palatal) or `[ç]` (broad)
- `fh` → always silent (`phon = ""`), but **ghost-palatal trace**: before deletion, copy `palatal` to the previous consonant token

**Ghost-palatal trace:**
```lua
if token.ortho == "fh" then
    if prev and prev.type == "cons" then
        prev.palatal = token.palatal
    end
    token.phon = ""
end
```

---

### Pass #6: `06_vocalization.lua`

**Source:** Extracted from current `apply_fricative_vocalization` + `resolve_vowel_plus_mutated_fricative`. Now stress-aware.

**Key stress-dependent rules:**
- `-adh` stressed → `[ai]` or `[eː]` (full diphthongization)
- `-adh` unstressed → `[ə]` (reduced)
- `ea+bh` → `[əu]`
- `u+gh` → `[uː]`
- `a/o/u+bh/mh` → `[əu]`

Logic: for each vowel+fricative pair, check `context.stress_index == i` to decide between full vocalization and reduction.

---

### Pass #7: `07_nasalization.lua`

**Source:** Extracted from nasal raising logic in `resolve_vowels`.

**Key rules:**
- `o/u/ó/ú` → `[uː]` before geminate nasals (`nn`, `ng`, doubled `n n` tokens)
- Vowel nasalization before word-final `m/n/ng`
- Vowel quality changes in nasal environment

Must run after Pass #6 (vocalization) so vocalized forms like `[əu]` aren't re-nasalized.

---

### Pass #8: `08_slender_coda.lua`

**Source:** Extracted from current `apply_slender_coda_vowels`.

**Key rules:**
- Before `lt/rt` → vowel becomes `[ɛ]`
- Before slender `ng` → vowel becomes `[ɪ]`
- Before slender `nn` → vowel becomes `[ɪ]`

---

### Pass #9: `09_consonants.lua`

**Source:** Extracted from current `resolve_consonants`. Maps consonant tokens to IPA.

**Key mapping:**
| Ortho | Broad | Slender | Voiceless (after h-mutation) |
|-------|-------|---------|------------------------------|
| b | bˠ | bʲ | — |
| c | k | c | — |
| d | d̪ˠ | dʲ | — |
| f | fˠ | fʲ | — |
| g | ɡ | ɟ | — |
| l | lˠ | lʲ | l̥ |
| m | mˠ | mʲ | m̥ |
| n | n̪ˠ | nʲ | n̥ |
| p | pˠ | pʲ | — |
| r | ɾˠ | ɾʲ | r̥ |
| s | sˠ | ʃ | — |
| t | t̪ˠ | tʲ | — |

---

### Pass #10: `10_vowels.lua`

**Source:** Extracted from current `resolve_vowels`. Dialect-aware.

**Connacht key mapping:**
| Ortho | Short | Long | Diphthong |
|-------|-------|------|-----------|
| a | a | ɑː | — |
| e | ɛ | eː | — |
| i | ɪ | iː | — |
| o | ɔ | oː | — |
| u | ʊ | uː | — |
| ea | a | eː | — |
| eo | ɔ | oː | — |
| ao | — | iː | — |
| ai | a | — | ai |
| oi | ɔ | — | ɔi |
| ui | ʊ | — | ʊi |

---

### Pass #11: `11_unstressed_reduction.lua`

**Source:** Extracted from current `apply_unstressed_reduction`.

If `i ~= context.stress_index` and vowel is short: reduce to `[ə]` (or `[ɪ]` in slender context). Monosyllables never reduce (via `context.is_monosyllabic`).

---

### Pass #12: `12_epenthesis.lua`

**New.** Inserts svarabhakti (epenthetic) vowels into heterorganic sonorant+voiced-obstruent clusters when the cluster immediately follows a **short, stressed vowel**.

**Critical constraint:** Epenthesis is NOT restricted to monosyllabic words. It occurs in polysyllabic words whenever the structural conditions are met:
- `dorcha` (dark) → `[ˈd̪ˠɔɾˠəxə]` (polysyllabic, has epenthesis)
- `airgead` (money) → `[ˈaɾʲəɟəd̪ˠ]` (polysyllabic, has epenthesis)
- `seirbhís` (service) → `[ˈʃɛɾʲəvʲiːʃ]` (polysyllabic, has epenthesis)

**Logic:**
```lua
-- Check: preceding vowel token has stress=true AND is a short vowel
if is_sonorant(tokens[i]) and is_voiced_obstruent(tokens[i+1]) then
    local prev_vowel = find_preceding_vowel(tokens, i)
    if prev_vowel and prev_vowel.stress and is_short_vowel(prev_vowel) then
        local epenthetic = make_epenthetic_token(tokens[i].palatal)
        epenthetic.is_epenthetic = true
        table.insert(tokens, i+1, epenthetic)
    end
end
```

The `is_epenthetic = true` flag makes the inserted vowel immune to stress assignment (already ran) and certain vowel gradation rules in later passes.

---

### Pass #13: `13_sonorants.lua`

**New.** Handles vowel lengthening/diphthongization before strong sonorants (`nn`, `ll`).

**This pass IS restricted to monosyllables or word-final positions.**
- Monosyllable: `peann` → `[pʲɑːn̪ˠ]` (vowel lengthens before strong `nn`)
- Polysyllable: `peanna` → `[pʲan̪ˠə]` (no lengthening — `nn` is not word-final)

Uses `context.is_monosyllabic` and `context.root_vowel_count` to decide.

---

### Pass #14: `14_final_cleanup.lua`

**New.** Combines diacritics, final devoicing, final fricative deletion, and sandhi.

**Key behaviors:**
1. **Unstressed final devoicing** (Connacht/Ulster rule from Hickey Ch.2): word-final slender `g` (`[ɟ]`) in an unstressed syllable devoices to `[c]`
   - `Nollaig` → `[ˈn̪ˠʌl̪ˠəc]` (not `*...ɟ`)
   - `Pádraig` → `[ˈpˠɑːd̪ˠɾˠəc]`
2. Delete final `ç/ɣ/h` after long vowels: `([ɑeiou]ː)[ɣçh]$` → `%1`
3. Add velarization `[ˠ]` / palatalization `[ʲ]` diacritics to all consonants based on polarity
4. Resolve palatal markers to final IPA (`sʲ` → `[ʃ]`, `kʲ` → `[c]`, etc.)
5. Handle `ch+s` → `[tʃ]` sandhi
6. Remove empty tokens and intermediate markers; normalize Unicode

**Final devoicing logic:**
```lua
if token.phon == "ɟ" and i == #non_empty_tokens then
    local prev_vowel = find_preceding_vowel(tokens, i)
    if prev_vowel and not prev_vowel.stress then
        token.phon = "c"
    end
end
```

---

## 5. File Layout

```
irish/
  passes/
    init.lua                   -- loads all passes in order, returns {run_all(tokens, context)}
    01_polarity.lua
    02_stress.lua              -- MOVED UP per design correction
    03_eclipsis.lua
    04_cluster_simplify.lua
    05_mutated_fricatives.lua
    06_vocalization.lua
    07_nasalization.lua
    08_slender_coda.lua
    09_consonants.lua
    10_vowels.lua
    11_unstressed_reduction.lua
    12_epenthesis.lua
    13_sonorants.lua
    14_final_cleanup.lua
  irish_engine_new.lua         -- orchestrator; exports transcribe(word, dialect)
  compare_engine.lua           -- comparison harness (Section 6)
```

---

## 6. Comparison Harness: `compare_engine.lua`

Runs both `irish.transcribe(word)` and `engine_new.transcribe(word)` against the full 6,911 Connacht wordlist, reporting per-word differences.

**Purpose:** Catch regressions immediately when adding or modifying a pass.

**Logic:**
1. Load `data/connacht_only.csv` (word, expected_ipa)
2. For each word:
   - Run `irish.transcribe(word)` → `prod_ipa`
   - Run `engine_new.transcribe(word)` → `new_ipa`
   - Compute Levenshtein distance between `prod_ipa` and `new_ipa`
   - If distance > 0: log the difference
3. Report summary:
   - Total words processed
   - Words where `new_ipa == prod_ipa` (exact match)
   - Words where `new_ipa != prod_ipa` (differences)
   - Average Levenshtein distance across all words
   - Top 20 most different words (for debugging)

**Target:** The "Different" count must be 0 (or as close as possible) before the new engine becomes production.

**Output format:**
```
--- Comparison Summary ---
Total words: 6911
Exact match: 6850 (99.1%)
Different: 61 (0.9%)
Average Levenshtein distance: 0.12

--- Top 20 Differences ---
Word        | Production          | New Engine          | Distance
---------------------------------------------------------------
seanbhean   | ˈʃan̪ˠwɛn̪ˠ        | ˈʃan̪ˠwɛn̪ˠ        | 0
...
```

---

## 7. Migration Strategy

### Phase 1: Scaffold (no behavior change)
1. Create `passes/` directory and `init.lua`
2. Create `irish_engine_new.lua` orchestrator
3. Create `compare_engine.lua`
4. Extract existing 12 passes from `irish_tokens.lua` into numbered pass files
5. Validate: `compare_engine.lua` shows 0 differences vs. current `irish_tokens.lua` output

### Phase 2: New passes (eclipsis, cluster_simplify, epenthesis, sonorants, final_cleanup)
1. Implement each new pass as a separate commit
2. After each new pass, run `compare_engine.lua` against production
3. Note: new passes will initially show differences from the monolith (the monolith doesn't have clean token-level passes for these)
4. Target: new passes produce identical output to monolith on the full 6,911-word set

### Phase 3: Accuracy tuning
1. Run `regression.lua` (28 words) and `regression_extended.lua` (56 words) against the new engine
2. Fix any regressions pass-by-pass
3. Expand `compare_engine.lua` to use `data/all_regions.csv` (17,281 words) for dialect testing

### Phase 4: Swap
1. When `compare_engine.lua` shows 0 differences on all test sets:
   - Replace `irish.transcribe()` with `engine_new.transcribe()` in the entry point
   - Archive old `irish_engine.lua`, `irish_rules.lua`, `irish_rules_data.lua`, `irish_processors.lua`
2. Update `token_probe.lua` to use the new engine
3. Commit and celebrate

---

## 8. Constraints

- **Connacht first, extensible:** All passes default to Connacht. Dialect routing happens via `context.dialect` → pass-specific dialect tables. Other dialects (Munster, Ulster) are added later without changing pass structure.
- **No WORD_EXCEPTIONS for regular phenomena:** Phonetic patterns that look like exceptions (e.g., `leabhar`, `trom`, `chugham`) are rule-based phonological passes, not hardcoded exceptions.
- **Theory-driven:** Every pass references Hickey (2014) or O Raghallaigh (2013) for the phonological rule it implements.
- **Incremental validation:** Each pass is committed independently and validated against the full 6,911-word Connacht test set before proceeding.

---

## 9. Risks

1. **Vowel resolver guard clobbering:** The current `token.phon == ortho` guard in the vowel resolver is too aggressive for vowels like `a` (whose default phon equals ortho). This must be fixed before Pass #10 is extracted. Use a `modified` flag set by earlier passes instead of comparing phon to ortho.
2. **Pass ordering sensitivity:** Moving stress up (#2) fixes vocalization, but may break existing stress-dependent logic that was tuned for the old ordering. Validate against the full test set after extraction.
3. **Epenthesis false positives:** The epenthesis rule must be carefully conditioned on "short, stressed vowel" — not just "stressed vowel" (long vowels don't trigger epenthesis).

---

## 10. Success Metrics

| Metric | Current (monolith) | Target (new engine) |
|--------|-------------------|---------------------|
| `regression.lua` failures | 28 | ≤ 28 |
| `regression_extended.lua` failures | 56 | ≤ 56 |
| `compare_engine.lua` differences | — | 0 |
| Token probe distance (27 words) | 51 | ≤ 51 |
| `connacht_only.csv` Dolgo distance | 0.9413 | ≥ 0.9413 |
