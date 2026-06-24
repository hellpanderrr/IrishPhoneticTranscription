# Graph Report - .  (2026-06-23)

## Corpus Check
- 136 files · ~445,219 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 466 nodes · 675 edges · 69 communities (50 shown, 19 thin omitted)
- Extraction: 94% EXTRACTED · 6% INFERRED · 0% AMBIGUOUS · INFERRED: 40 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_G2P Engine Pipeline Core|G2P Engine Pipeline Core]]
- [[_COMMUNITY_Archive Monolith Engine|Archive Monolith Engine]]
- [[_COMMUNITY_Archive Compare Tooling|Archive Compare Tooling]]
- [[_COMMUNITY_Ustring Library|Ustring Library]]
- [[_COMMUNITY_Pass Module Implementations|Pass Module Implementations]]
- [[_COMMUNITY_Benchmark and Error Analysis|Benchmark and Error Analysis]]
- [[_COMMUNITY_Phonological Theory Docs|Phonological Theory Docs]]
- [[_COMMUNITY_Debug and Diagnostic Tools|Debug and Diagnostic Tools]]
- [[_COMMUNITY_Design Docs and Plans|Design Docs and Plans]]
- [[_COMMUNITY_Categorization Tools|Categorization Tools]]
- [[_COMMUNITY_GrayMatter Session Memory|GrayMatter Session Memory]]
- [[_COMMUNITY_Sonorant and Vowel Cleanup Passes|Sonorant and Vowel Cleanup Passes]]
- [[_COMMUNITY_Community 12|Community 12]]
- [[_COMMUNITY_Community 13|Community 13]]
- [[_COMMUNITY_Community 14|Community 14]]
- [[_COMMUNITY_Community 15|Community 15]]
- [[_COMMUNITY_Community 16|Community 16]]
- [[_COMMUNITY_Community 18|Community 18]]
- [[_COMMUNITY_Community 20|Community 20]]
- [[_COMMUNITY_Community 21|Community 21]]
- [[_COMMUNITY_Community 22|Community 22]]
- [[_COMMUNITY_Community 23|Community 23]]
- [[_COMMUNITY_Community 24|Community 24]]
- [[_COMMUNITY_Community 25|Community 25]]
- [[_COMMUNITY_Community 26|Community 26]]
- [[_COMMUNITY_Community 27|Community 27]]
- [[_COMMUNITY_Community 29|Community 29]]
- [[_COMMUNITY_Community 30|Community 30]]
- [[_COMMUNITY_Community 31|Community 31]]
- [[_COMMUNITY_Community 32|Community 32]]
- [[_COMMUNITY_Community 33|Community 33]]
- [[_COMMUNITY_Community 44|Community 44]]
- [[_COMMUNITY_Community 45|Community 45]]
- [[_COMMUNITY_Community 52|Community 52]]
- [[_COMMUNITY_Community 53|Community 53]]
- [[_COMMUNITY_Community 55|Community 55]]
- [[_COMMUNITY_Community 56|Community 56]]
- [[_COMMUNITY_Community 57|Community 57]]
- [[_COMMUNITY_Community 58|Community 58]]
- [[_COMMUNITY_Community 60|Community 60]]
- [[_COMMUNITY_Community 61|Community 61]]
- [[_COMMUNITY_Community 62|Community 62]]

## God Nodes (most connected - your core abstractions)
1. `usub()` - 35 edges
2. `checkString()` - 17 edges
3. `utf8_explode()` - 15 edges
4. `Irish G2P Engine` - 14 edges
5. `Lexical Override Tables (Vowel Quality)` - 13 edges
6. `Pass 10: Vowel Resolution + Contextual Allophony` - 12 edges
7. `Implementation Plan (10 Issues)` - 12 edges
8. `irish_engine_new.lua (Engine Entry Point)` - 10 edges
9. `irish_tokens.lua (Token Prototype)` - 10 edges
10. `Token-Array Monolith Replacement Design` - 10 edges

## Surprising Connections (you probably didn't know these)
- `levenshtein()` --calls--> `usub()`  [INFERRED]
  _gen_base.lua → categorize_diff.lua
- `build_phonetic_trie()` --calls--> `usub()`  [INFERRED]
  archive/irish.lua → categorize_diff.lua
- `build_phonetic_trie()` --calls--> `usub()`  [INFERRED]
  archive/irish_rules_data.lua → categorize_diff.lua
- `build_phonetic_trie()` --calls--> `usub()`  [INFERRED]
  archive/irish_rules_data_backup.lua → categorize_diff.lua
- `build_phonetic_trie()` --calls--> `usub()`  [INFERRED]
  archive/irish_rules_monolith.lua → categorize_diff.lua

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **16-Pass Pipeline Module System** — repo_pass_01_polarity, repo_pass_02_stress, repo_pass_03_eclipsis, repo_pass_06_vocalization, repo_pass_07_nasalization, repo_pass_08_slender_coda, repo_pass_09_consonants, repo_pass_09b_vowel_adjunct, repo_pass_10_vowels, repo_pass_11_unstressed_reduction, repo_pass_12_epenthesis, repo_pass_13_sonorants, repo_pass_14_final_cleanup [EXTRACTED 1.00]
- **Vowel Quality Correction Strategy (Lexical Overrides)** — repo_lexical_override_tables, repo_pass_10_vowels, repo_pass_11_unstressed_reduction, repo_error_analysis_doc, repo_vowel_digraph_resolution [EXTRACTED 1.00]
- **Phonological Theory to Implementation Chain** — repo_hickey_theory, repo_oraghallaigh_theory, repo_hickey_h_rule, repo_pass_09_consonants, repo_pass_10_vowels, repo_pass_13_sonorants, repo_dental_sonorant_polarity [EXTRACTED 1.00]
- **Theory-Grounded Passes Added to Pipeline** — plans_vowel_gradation_pass, plans_r_lowering_pass, plans_anticipatory_raising_pass, plans_labial_vocalization_pass, plans_x_nonassimilation_rule, plans_sonorant_lengthening_fix [EXTRACTED 1.00]
- **10-Priority Implementation Issues** — imp_plan_issue1_sh_th_lenition, imp_plan_issue2_stress_false_positives, imp_plan_issue3_nasal_raising, imp_plan_issue4_dental_diacritics, imp_plan_issue5_vocalized_fricatives, imp_plan_issue6_sonorant_shift, imp_plan_issue7_bh_mh_broad, imp_plan_issue8_unstressed_reduction, imp_plan_issue9_vowel_shift_long_low, imp_plan_issue10_empty_ipa [EXTRACTED 1.00]
- **Three Irish Dialect Phonologies** — theory_gd_ulster, theory_cr_connacht, theory_cd_munster [EXTRACTED 1.00]

## Communities (69 total, 19 thin omitted)

### Community 0 - "G2P Engine Pipeline Core"
Cohesion: 0.07
Nodes (53): bench_run.lua (Benchmark Runner), 6593-Word Connacht Benchmark, Benchmark Accuracy Progression, compare_engine.lua (Comparison Harness), Connacht Dialect, Connacht-First Strategy, Dental Sonorant Polarity (n-l dental/postalveolar), Disabled Sandhi Processing (+45 more)

### Community 1 - "Archive Monolith Engine"
Cohesion: 0.07
Nodes (11): build_phonetic_trie(), is_monosyllabic_impl(), apply_rules_to_string_generic_impl(), irish_engine.transcribe(), irish_engine.transcribe_single_word(), irish_processors.process_sandhi(), levenshtein(), levenshtein() (+3 more)

### Community 2 - "Archive Compare Tooling"
Cohesion: 0.08
Nodes (14): build_phonetic_trie(), create_rules_for_specific_sonorant(), debug_print_minimal(), get_original_indices_from_map(), irishPhonetics.process_sandhi(), irishPhonetics.transcribe(), irishPhonetics.transcribe_single_word(), process_contextual_allophony_procedurally() (+6 more)

### Community 3 - "Ustring Library"
Cohesion: 0.19
Nodes (28): checkPattern(), checkString(), checkType(), cpoffset(), find(), internalChar(), internalCompose(), internalDecompose() (+20 more)

### Community 5 - "Benchmark and Error Analysis"
Cohesion: 0.09
Nodes (3): render_output(), tokenize_word(), transcribe()

### Community 6 - "Phonological Theory Docs"
Cohesion: 0.20
Nodes (11): build_phonetic_trie(), create_rules_for_specific_sonorant(), debug_print_minimal(), get_original_indices_from_map(), irishPhonetics.process_sandhi(), irishPhonetics.transcribe(), irishPhonetics.transcribe_single_word(), process_contextual_allophony_procedurally() (+3 more)

### Community 7 - "Debug and Diagnostic Tools"
Cohesion: 0.20
Nodes (11): build_phonetic_trie(), create_rules_for_specific_sonorant(), debug_print_minimal(), get_original_indices_from_map(), process_contextual_allophony_procedurally(), process_epenthesis_on_units(), process_phonetic_units_procedurally(), process_quality_assignment_on_units() (+3 more)

### Community 8 - "Design Docs and Plans"
Cohesion: 0.20
Nodes (11): build_phonetic_trie(), create_rules_for_specific_sonorant(), debug_print_minimal(), get_original_indices_from_map(), irishPhonetics.process_sandhi(), irishPhonetics.transcribe(), irishPhonetics.transcribe_single_word(), process_contextual_allophony_procedurally() (+3 more)

### Community 9 - "Categorization Tools"
Cohesion: 0.23
Nodes (5): irishPhonetics.process_sandhi(), irishPhonetics.transcribe(), irishPhonetics.transcribe_single_word(), process_phonetic_units_procedurally(), process_quality_assignment_on_units()

### Community 10 - "GrayMatter Session Memory"
Cohesion: 0.17
Nodes (12): Issue 10: Empty Expected IPA / Multi-phrase Entries, Issue 2: Stress Mark False Positives on Monosyllables, Issue 3: ó Not Raised to uː Before Nasals, Issue 4: Missing Dental Diacritics (̪), Issue 5: Vocalized Fricative Diphthongs (bh/mh/gh/dh), Issue 6: cn-/gn-/mn- Sonorant Shift and Marker Leak, Implementation Plan (10 Issues), Project Summary (+4 more)

### Community 11 - "Sonorant and Vowel Cleanup Passes"
Cohesion: 0.18
Nodes (11): Eclipsis Collapse Fix, Function Word Vowel Quality Fix (i, do, ag, go), Long Vowel Quality Fix (diphthong iə, eː→ə), Multi-word Phrase Stress Handling, Sonorant Polarization Fix (n/l/r polarity), Vowel Reduction Tuning (coda-conditioned exceptions), Issue 8: Unstressed Vowel Reduction (ə vs ɪ), Improvement Plan Fresh (EDA-driven fixes) (+3 more)

### Community 12 - "Community 12"
Cohesion: 0.18
Nodes (11): Issue 9: Vowel Shift Before Long Low Vowels (Western), Theory-Grounded Refinement Plan, Anticipatory Vowel Raising Pass (Western Irish), R-Lowering Pass (Hickey Ch.2), Sonorant Lengthening with Suffix/Compound Distinction, Vowel Gradation (Umlaut) Pass, Anticipatory Vowel Raising (Western short a/o → ʊ/ɪ before aː), R-Lowering (/ɪ/, /e/ → [ɛ] before slender /ɾʲ/) (+3 more)

### Community 13 - "Community 13"
Cohesion: 0.25
Nodes (7): get_vowels(), matches_any(), norm(), Deeper error analysis on fresh new_results.csv., Extract vowel phonemes (including diphthongs)., Check if stress placement matches expected., stress_correctness()

### Community 14 - "Community 14"
Cohesion: 0.25
Nodes (8): Token-Array Monolith Replacement Design, Comparison Harness (compare_engine.lua), Dialect-First Architecture (Connacht default, extensible), Ghost-Palatal Trace on fh Deletion, Pass Interface Contract, Stress Pass Moved to Position #2 (design correction), Token-Array Pipeline Architecture, Vowel Resolver token.phon == ortho Guard Bug

### Community 15 - "Community 15"
Cohesion: 0.38
Nodes (4): classify(), matches_any(), norm(), Analyze new_results.csv vs expected IPA, with results.csv as monolith baseline.

### Community 18 - "Community 18"
Cohesion: 0.33
Nodes (5): matches_any(), norm(), Analyze the two biggest error categories: stress_position and initial_consonant_, Return list of (offset, stress_type) for each stress mark., stress_positions()

### Community 20 - "Community 20"
Cohesion: 0.47
Nodes (4): deep_classify(), matches_any(), norm(), Deeper error analysis: breakdown"other" category, monolith vs expected scores.

### Community 22 - "Community 22"
Cohesion: 0.40
Nodes (5): ç vs h Distinction Fix (medial ch/th/sh rules), Issue 1: sh/th Lenition h vs. ç Confusion, /x/ Palatal Non-Assimilation Rule (Hickey), Lenition (Séimhiú) Initial Mutation, /x/ Palatal Non-Assimilation (ch blocks vowel fronting)

### Community 23 - "Community 23"
Cohesion: 0.60
Nodes (3): lev(), match_and_score(), norm()

### Community 25 - "Community 25"
Cohesion: 0.50
Nodes (4): Corca Dhuibhne (CD) - Munster Irish Dialect Phonology, An Cheathrú Rua (CR) - Connacht Irish Dialect Phonology, Gaoth Dobhair (GD) - Ulster Irish Dialect Phonology, Three Irish Dialect Regions (GD, CR, CD)

### Community 30 - "Community 30"
Cohesion: 0.67
Nodes (3): Issue 7: bh/mh Broad → w Rule, Labial Fricative Vocalization Pass, Labial Fricative Vocalization (broad v → uː)

### Community 32 - "Community 32"
Cohesion: 0.67
Nodes (3): _shared.is_broad_vowel_char(), _shared.is_slender_vowel_char(), _shared.vowel_polarity()

### Community 33 - "Community 33"
Cohesion: 0.67
Nodes (3): The Sound Structure of Modern Irish (Hickey 2014) - PDF, The Sound Structure of Modern Irish - Hickey Part 1 (Ch.1-4), The Sound Structure of Modern Irish - Hickey Part 2 (Ch.5 + Appendices)

## Knowledge Gaps
- **32 isolated node(s):** `graymatter`, `graymatter`, `Unicode UTF-8 Byte Encoding`, `ustring Library`, `Pass 03: Eclipsis` (+27 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **19 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `usub()` connect `Archive Monolith Engine` to `Community 32`, `Archive Compare Tooling`, `Benchmark and Error Analysis`, `Phonological Theory Docs`, `Debug and Diagnostic Tools`, `Design Docs and Plans`, `Categorization Tools`, `Community 45`, `Community 16`, `Community 24`?**
  _High betweenness centrality (0.176) - this node is a cross-community bridge._
- **Why does `tokenize_word()` connect `Benchmark and Error Analysis` to `Archive Monolith Engine`?**
  _High betweenness centrality (0.025) - this node is a cross-community bridge._
- **Why does `_shared.vowel_polarity()` connect `Community 32` to `Archive Monolith Engine`, `Pass Module Implementations`?**
  _High betweenness centrality (0.021) - this node is a cross-community bridge._
- **Are the 34 inferred relationships involving `usub()` (e.g. with `build_phonetic_trie()` and `build_phonetic_trie()`) actually correct?**
  _`usub()` has 34 INFERRED edges - model-reasoned connections that need verification._
- **What connects `graymatter`, `graymatter`, `Replace literal ː with byte escape.` to the rest of the system?**
  _55 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `G2P Engine Pipeline Core` be split into smaller, more focused modules?**
  _Cohesion score 0.06918238993710692 - nodes in this community are weakly interconnected._
- **Should `Archive Monolith Engine` be split into smaller, more focused modules?**
  _Cohesion score 0.06829268292682927 - nodes in this community are weakly interconnected._