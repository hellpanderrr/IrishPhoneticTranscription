# Irish G2P Refactoring Plan

## Baseline
- **Current score**: Total Levenshtein Distance = 30 across 28 test words (regression.lua)
- **Source file**: `irish.lua` (4298 lines)
- **Goal**: Split into logical modules while maintaining score = 30

---

## Module Boundaries

### 1. `irish_constants.lua` (~150 lines)
**Content**: All pattern definitions, character sets, lookup tables
- `CONSONANTS_ORTHO_CHARS_STR`, `VOWELS_ORTHO_CHARS_STR`, etc.
- `ALL_VOWELS_ORTHO_PATTERN`, `CONSONANT_CLASS_NO_CAPTURE`, etc.
- `DIPHTHONG_LITERALS_FOR_PRIORITY`, phonetic unit priority lists
- `ALL_PHONETIC_CONSONANTS_INTERMEDIATE_PRIORITY`, `ALL_PHONETIC_NUCLEI_PRIORITY`
- `COMBINED_PHONETIC_UNITS_PRIORITY`, `PHONETIC_TRIE` (build function)
- `lexical_exceptions_connacht`, `UNSTRESSED_WORDS_AND_SUFFIXES`
- `UNSTRESSED_PREFIXES_ORTHO`
- Marker constants: `MKR_*`, `ZZZ_*`
- Epenthesis cluster sets: `EPENTHESIS_TARGET_CLUSTERS_BROAD/SLENDER`
- `BROAD_LNM_MARKERS_FOR_STAGE5`, `PALATAL_LNM_MARKERS_FOR_STAGE5`, etc.
- `PLACEHOLDER_*` marker strings
- `DEFAULT_STRESS_RULES`, `STRESS_EXCEPTIONS_ORTHO`

### 2. `irish_utils.lua` (~100 lines)
**Content**: Shared utility functions
- `N()`, `ulen`, `usub`, `umatch`, `ufind`, `ugsub`, `ulower`, `ureverse`
- `memoize()` helper
- `debug_print_minimal()`, debug control
- `get_original_indices_from_map()`
- `is_stressed_vowel_phonetic()`

### 3. `irish_rules_data.lua` (~800 lines)
**Content**: All rule tables (declarative data)
- `rules_stage1_preprocess`
- `rules_stage1_5_ortho_cluster_simplification`
- `rules_stage2_mark_digraphs_and_vocalisation_triggers`
- `rules_stage2_5_mark_suffixes`
- `rules_stage3_1_marker_resolution`
- `rules_stage3_5_placeholder_resolution`
- `placeholder_restoration_rules_stage4_5`
- `rules_stage5_consonant_assimilation`
- `rules_stage6_vowel_adjustments`
- `rules_final_cleanup`
- `placeholder_restoration_rules_final`

### 4. `irish_procedural.lua` (~500 lines)
**Content**: Procedural/algorithmic functions
- `get_ortho_vowel_quality_implication_from_char_or_group_impl`
- `determine_consonant_quality_ortho_impl`
- `parse_phonetic_string_to_units_for_epenthesis_impl`
- `is_likely_monosyllable_phonetic_revised_impl`
- `resolve_lenited_consonant_impl`
- `process_epenthesis_on_units()`
- `process_quality_assignment_on_units()`
- `process_strong_sonorants_on_units()`
- `parse_phonetic_for_consonant_assimilation()`
- `apply_consonant_assimilation_rules()`
- `apply_final_cleanup_rules()`
- `find_ortho_vowel_group_for_stress()`

### 5. `irish_stages.lua` (~300 lines)
**Content**: Pipeline stage execution logic
- `apply_rules()` (generic rule engine)
- Stage runner functions for each pipeline stage
- `transcribe()` main entry point (or moved to main module)

### 6. `irish_sandhi.lua` (~200 lines)
**Content**: Sandhi/word-boundary processing
- `apply_sandhi_rules_to_sequence()`
- `apply_sandhi_to_text()`
- All sandhi helper functions (tn->tr, assimilation, etc.)

### 7. `irish.lua` (~200 lines) - **Main API**
**Content**: Public interface only
- Module requires
- `irishPhonetics` table assembly
- `transcribe()` exported function
- CLI handling (if no input, run default tests)

---

## Dependency Graph

```
irish_constants.lua (no deps)
       ↓
irish_utils.lua (no deps)
       ↓
irish_rules_data.lua → requires: irish_constants
       ↓
irish_procedural.lua → requires: irish_constants, irish_utils, irish_rules_data (for markers)
       ↓
irish_stages.lua → requires: irish_constants, irish_utils, irish_rules_data, irish_procedural
       ↓
irish_sandhi.lua → requires: irish_constants, irish_utils, irish_stages
       ↓
irish.lua (main) → requires: all above
```

---

## Migration Strategy

### Phase 1: Extract Constants & Utils (Low Risk)
1. Create `irish_constants.lua` - move all pattern/char-set definitions
2. Create `irish_utils.lua` - move memoize, debug, string helpers
3. Update `irish.lua` to `require()` them
4. Run regression → **must stay at 30**

### Phase 2: Extract Rule Data Tables (Low Risk)
1. Create `irish_rules_data.lua` - move all `irishPhonetics.rules_*` tables
2. Update references in `irish.lua`
3. Run regression → **must stay at 30**

### Phase 3: Extract Procedural Functions (Medium Risk)
1. Create `irish_procedural.lua` - move all algorithmic functions
2. These have internal dependencies - move carefully
3. Run regression → **must stay at 30**

### Phase 4: Extract Stage Pipeline (Medium Risk)
1. Create `irish_stages.lua` - move `apply_rules()` and stage runners
2. Run regression → **must stay at 30**

### Phase 5: Extract Sandhi (Low Risk)
1. Create `irish_sandhi.lua` - move sandhi functions
2. Run regression → **must stay at 30**

### Phase 6: Slim Main Module (Low Risk)
1. Reduce `irish.lua` to just public API + CLI
2. Run regression → **must stay at 30**

---

## Test Strategy

### After Each Phase:
```bash
lua regression.lua
```
**Assert**: Total Levenshtein Distance == 30

### Additional Validation:
- Run `irish_debug_43_lua_p_strict.txt` test cases if available
- Test CLI: `echo "glas" | lua irish.lua`
- Test multi-word: `lua -e "require('irish').transcribe('a Sheáin')"`

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Global variable pollution | Use `local` everywhere, explicit module returns |
| Circular dependencies | Strict dependency order above; `irish_rules_data` only needs constants |
| Memoization cache invalidation | Keep `memoize` in utils; functions stay pure |
| Debug flag propagation | Keep `MINIMAL_DEBUG_ENABLED` in constants |
| Marker string collisions | All markers in constants with `N()` prefix |

---

## File Size Targets (Post-Refactor)

| Module | Est. Lines |
|--------|------------|
| irish_constants.lua | ~150 |
| irish_utils.lua | ~100 |
| irish_rules_data.lua | ~800 |
| irish_procedural.lua | ~500 |
| irish_stages.lua | ~300 |
| irish_sandhi.lua | ~200 |
| irish.lua (main) | ~200 |
| **Total** | **~2250** (vs 4298) |

Note: Reduction comes from removing duplication, comments, and dead code.

---

## Phase 2+: Phonetics Improvements (Post-Refactor)

After refactoring is complete and validated:

1. **Read Irish phonetics book** - identify gaps in current rules
2. **Target high-distance words** from regression:
   - `a Sheáin` (distance 3) - sandhi/initial mutation
   - `trom` (distance 2) - vowel quality
   - `sheol` (distance 2) - lenition realization
   - `fón` (distance 1) - long vowel
   - `seomra/seomraí` (distance 1) - vowel quality before rr
3. **Add missing phonological rules**:
   - Stress placement (currently simplified)
   - Sandhi (partial implementation)
   - Epenthesis edge cases
   - Vowel quality before consonant clusters
4. **Iterate**: modify rules → run regression → target distance < 30