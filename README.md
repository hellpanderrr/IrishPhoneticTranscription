
# `IrishPhoneticTranscription`

## Project Overview

`IrishPhoneticTranscription` is a rule-based, standalone grapheme-to-phoneme (G2P) engine for the Irish language, implemented in Lua. The system's primary goal is to convert standard Irish orthography into its phonetic representation (IPA), specifically targeting the phonology of the **Connacht dialect**.

This project serves as an exploration of modeling complex, context-sensitive phonological rules. It is a work-in-progress and should be considered an academic or experimental tool rather than a production-ready, pan-dialectal G2P solution.

## Current Status & Known Issues

The engine correctly models a significant portion of Connacht Irish phonology but has several known limitations and areas requiring further development. Users should be aware of these issues before relying on the output for critical applications.

### Primary Limitations:

1.  **Strict Dialectal Focus:** The output is heavily biased towards a generalized Connacht phonology. It does **not** accurately model key features of Munster (e.g., stress patterns) or Ulster (e.g., vowel qualities, lenition of `an`). Using this script for non-Connacht text will produce significant dialectal mismatches.
2.  **Stress System:** The current stress assignment relies on a default initial-stress rule supplemented by a **limited lexical exception list**. Consequently, it frequently fails to correctly place stress on:
    *   Loanwords (e.g., `ospidéal`, `tobac`).
    *   Words with stress-attracting derivational suffixes (e.g., `-án`, `-óir`).
3.  **Sandhi (Word Boundary Phenomena):** Sandhi rules are currently disabled and underdeveloped. The script processes each word in isolation, meaning it does not model phonetic changes that occur across word boundaries (e.g., assimilation, elision). This can lead to inaccuracies in fluent text transcription.
4.  **Inconsistent Lenition of `sh` and `th`:** The realization of initial lenited `sh` and `th` is a known point of failure. The current rule set struggles to consistently apply the correct phonetic output (`/h/` vs. `/ç/`) based on the quality of the following vowel. *See `a Sheáin` vs. `thóg` in test results.*
5.  **Vocalization & Hiatus:** The vocalization of intervocalic lenited consonants (`bh`, `mh`, `dh`, `gh`) is inconsistent. The script often produces diphthongs where a long vowel or complete elision is expected, or vice-versa. *See `leabhar` and `láimh` in test results.*

## Technical Architecture

The transcription process is a multi-stage pipeline, where the output of one stage becomes the input for the next. This architecture is designed for modularity but also introduces complexity, as errors in early stages can cascade.

### Core Pipeline Stages:

1.  **Lexical Lookup:** An initial check against a hard-coded table of irregular words. **Current Weakness:** The exception list is small and requires significant expansion to improve accuracy on common words.
2.  **Orthographic Normalization:** Simplifies consonant clusters (e.g., `cn` -> `cr`).
3.  **Marker-Based Transformation:** The core of the engine. A series of stages insert unique markers for orthographic features (e.g., `bh` -> `MKR_BH`), which are then resolved into base phonemes.
4.  **Procedural Vowel Allophony:** A critical, complex stage that attempts to model context-sensitive vowel changes.
    *   **Implementation:** It uses a single procedural function to handle rule precedence, first resolving long vowels and then applying a prioritized list of contextual rules (nasal raising, velar raising, gradation) to the remaining short vowels.
    *   **Current Weakness:** This stage is highly sensitive to the input from previous marker resolution stages. Errors in consonant quality assignment can prevent allophony rules from triggering correctly. The `greamaím` test case highlights remaining issues in this area.
5.  **Cleanup & Diacritic Application:** Final rules add quality markers (`ʲ`, `ˠ`, `̪`) and clean up any remaining artifacts.

## Usage

### Prerequisites

*   Lua 5.4+
*   `ustring` library 

### Command-Line Execution


**Transcribe a string:**
```sh
 >>> lua irish.lua test
 ˈtʲɛʃtʲ
```

**Debug Mode:**
The script includes a verbose debug mode that logs the transformation at each stage of the pipeline. To enable it, pass the `--d` flag.

```sh
 >>> lua irish.lua --d test
    MIN_DBG (Stage2_5_M):   Stage2_5_MarkSuffixes START: In=    test     Map size:      0
    MIN_DBG (Stage2_5_M):  END: Out=    test     Map size:      4
    MIN_DBG (Stage2_5_M): Af. Stage2_5_MarkSuffixes: [test]
    MIN_DBG (MarkDigrap):   MarkDigraphsAndVocalisationTriggers START: In=      test     Map size:      4
    MIN_DBG (MarkDigrap):  END: Out=    test     Map size:      4
    MIN_DBG (Stage3_1_M):   Stage3_1_MarkerResolution START: In=        test     Map size:      4
    MIN_DBG (Stage3_1_M):  END: Out=    test     Map size:      4
    MIN_DBG (ConsonantR): OVERRIDE (Initial C): For 't', next_v_group 'e' with following cons 'st' implies -> slender
    MIN_DBG (ConsonantR): DEBUG DETERMINE_C_QUAL (Fallback): For 's' in 'test' (idx 3): next_v_group=''(nil), prev_v_group='e'(slender) -> slender
    MIN_DBG (ConsonantR): DEBUG DETERMINE_C_QUAL (Fallback): For 't' in 'test' (idx 4): next_v_group=''(nil), prev_v_group='e'(slender) -> slender
    MIN_DBG (Stage3_2_A):   ApplyStress START: In=      t'es't'  (Original Ortho: '     test    ') Map size:    1
    MIN_DBG (Stage3_2_A): ApplyStress: Adding stress to '       ˈt'es't'        '.
    MIN_DBG (Stage3_2_A): Ortho map updated after stress application. Old map size: 1 -> New map size: 2
    MIN_DBG (Stage3_2_A):  END: Out=    ˈt'es't'         Map size:      2
    MIN_DBG (Stage3_2_A): Af. Stage3_2_ApplyStress: [ˈt'es't']
    MIN_DBG (Stage4_0_S):   Stage4_0_SpecificOrthoToTempMarker START: In=       ˈt'es't'         Map size:      2
    MIN_DBG (Stage4_0_S):  END: Out=    ˈt'es't'         Map size:      2
    MIN_DBG (Stage4_0_1):   Stage4_0_1_Resolve_CH_Marker START: In=     ˈt'es't'         Map size:      2
    MIN_DBG (Stage4_0_1):  END: Out=    ˈt'es't'         Map size:      2
    MIN_DBG (Stage4_1_V):   Stage4_1_VocmarkToTempMarker START: In=     ˈt'es't'         Map size:      2
    MIN_DBG (Stage4_1_V):  END: Out=    ˈt'es't'         Map size:      2
    MIN_DBG (Stage4_2_L):   Stage4_2_LongVowelsOrthoToTempMarker START: In=     ˈt'es't'         Map size:      2
    MIN_DBG (Stage4_2_L):  END: Out=    ˈt'es't'         Map size:      2
    MIN_DBG (Stage4_3_D):   Stage4_3_DiphthongsOrthoToTempMarker START: In=     ˈt'es't'         Map size:      2
    MIN_DBG (Stage4_3_D):  END: Out=    ˈt'es't'         Map size:      2
    MIN_DBG (Stage4_4_R):   Stage4_4_ResolveTempVowelMarkers START: In= ˈt'es't'         Map size:      2
    MIN_DBG (Stage4_4_R):  END: Out=    ˈt'es't'         Map size:      2
    MIN_DBG (Stage4_4_1):   Stage4_4_1_VocalizeLenitedFricatives START (Proc Helper): In=       ˈt'es't'
    MIN_DBG (Stage4_4_1):   Loop 1: Current unit: 'ˈ'
    MIN_DBG (Stage4_4_1):     new_units_build before:
    MIN_DBG (Stage4_4_1):     new_units_build after add: ˈ
    MIN_DBG (Stage4_4_1):   Loop 2: Current unit: 't''
    MIN_DBG (Stage4_4_1):     new_units_build before: ˈ
    MIN_DBG (Stage4_4_1):     new_units_build after add: ˈt'
    MIN_DBG (Stage4_4_1):   Loop 3: Current unit: 'e'
    MIN_DBG (Stage4_4_1):     new_units_build before: ˈt'
    MIN_DBG (Stage4_4_1):     new_units_build after add: ˈt'e
    MIN_DBG (Stage4_4_1):   Loop 4: Current unit: 's''
    MIN_DBG (Stage4_4_1):     new_units_build before: ˈt'e
    MIN_DBG (Stage4_4_1):     new_units_build after add: ˈt'es'
    MIN_DBG (Stage4_4_1):   Loop 5: Current unit: 't''
    MIN_DBG (Stage4_4_1):     new_units_build before: ˈt'es'
    MIN_DBG (Stage4_4_1):     new_units_build after add: ˈt'es't'
    MIN_DBG (Stage4_4_1):  END (no change by unit_processor): Out=      ˈt'es't'
    MIN_DBG (Stage4_5_C):   START: In=  ˈt'es't'
    MIN_DBG (Stage4_5_C):  END: Out=    ˈt'ɛs't'
    MIN_DBG (Stage4_5_C): Af. Stage4_5_ContextualAllophonyOnPhonetic: [ˈt'ɛs't']
    MIN_DBG (Stage4_5_1):   Stage4_5_1_DisyllabicShortLongRaising START (Proc Helper): In=      ˈt'ɛs't'
    MIN_DBG (Stage4_5_1):  END (no change by unit_processor): Out=      ˈt'ɛs't'
    MIN_DBG (Stage4_5_2):   Stage4_5_2_ConnachtSpecificVowelShifts START: In=   ˈt'ɛs't'         Map size:      2
    MIN_DBG (Stage4_5_2):  END: Out=    ˈt'ɛs't'         Map size:      2
    MIN_DBG (Nasalizati):   Nasalization START (Proc Helper): In=       ˈt'ɛs't'
    MIN_DBG (Nasalizati): NO.
    MIN_DBG (Nasalizati):  END (no change by unit_processor): Out=      ˈt'ɛs't'
    MIN_DBG (Stage4_6_U):   START (Outer): In=  ˈt'ɛs't'
    MIN_DBG (Stage4_6_U): Word '        ˈt'ɛs't'        ' is monosyllabic, SKIPPING.
    MIN_DBG (Epenthesis):   START (Proc): In=   ˈt'ɛs't'
    MIN_DBG (Epenthesis): After procedural epenthesis:  ˈt'ɛs't'
    MIN_DBG (Epenthesis): After strong sonorant rules:  ˈt'ɛs't'
    MIN_DBG (Epenthesis):  END (Proc): Out=     ˈt'ɛs't'
    MIN_DBG (Diacritics):   Diacritics START: In=       ˈt'ɛs't'         Map size:      2
    MIN_DBG (Diacritics):  END: Out=    ˈt'ɛs't'         Map size:      2
    MIN_DBG (FinalClean):   FinalCleanup START: In=     ˈt'ɛs't'         Map size:      2
    MIN_DBG (FinalClean): Iter.gsub: Rule '     s'      ' APPLIED to '  ˈt'ɛs't'        ' -> '  ˈt'ɛʃt' ' (     1       x)
    MIN_DBG (FinalClean): Iter.gsub: Rule '     t'      ' APPLIED to '  ˈt'ɛʃt' ' -> '  ˈtʲɛʃtʲ ' (     2       x)
    MIN_DBG (FinalClean): WARN: Ortho map may be misaligned after iterative_gsub. Rebuilding basic map for stage: FinalCleanup
    MIN_DBG (FinalClean):  END: Out=    ˈtʲɛʃtʲ  Map size:      1
    MIN_DBG (FinalClean): Af. FinalCleanup: [ˈtʲɛʃtʲ]
ˈtʲɛʃtʲ
```
The debug output is written to `irish_debug_43_lua_p_strict.txt`.

**Running regression tests:**

lua regression.lua
| Word | Expected IPA | Generated IPA | Distance |
| -------- | ------- | ------- | ------- |
|glas|ɡlˠasˠ|ˈɡlˠasˠ|0
|glais|ɡlˠaʃ|ˈɡlˠaʃ|0
|alt|al̪ˠt̪ˠ|ˈalˠt̪ˠ|1
|ailt|ɛlʲtʲ|ˈɛlʲtʲ|0
|seomra|ʃuːmˠɾˠə|ˈʃoːmˠɾˠə|1
|seomraí|ʃuːmˠɾˠiː|ˈʃoːmˠɾˠiː|1
|trom|t̪ˠɾˠuːmˠ|ˈt̪ˠɾˠɔmˠ|2
|bonn|bˠuːn̪ˠ|ˈbˠuːn̪ˠ|0
|fón|fˠoːnˠ|ˈfˠuːnˠ|1
|sheol|çɔːlˠ|ˈhoːlˠ|2
|thóg|hoːɡ|ˈçoːɡ|1
|shíl|hiːlʲ|ˈhiːlʲ|0
|aSheáin|əçɑːnʲ|aˈhɛɑːnʲ|3
|aithrí|ahɾʲiː|ˈahɾʲiː|0
|brath|bˠɾˠa|ˈbˠɾˠaç|1
|cnoc|kɾˠʊk|ˈkɾˠʊk|0
|tnúth|t̪ˠɾˠuː|ˈt̪ˠɾˠuː|0
|Tadhg|t̪ˠaiɡ|ˈt̪ˠaɡ|1
|'ur|ə|əɾˠ|2
|íocfaidh|iːkə|ˈiːkə|0
|marcaigh|mˠaɾˠkiː|ˈmˠaɾˠkiː|0
|chugham|xuːmˠ|ˈxuːəmˠ|1
|láimh|l̪ˠɑːvʲ|ˈlˠɑːiː|3
|leabhar|lʲəuɾˠ|ˈlʲəuəɾˠ|1
|greamaím|ˈɟɾʲamˠiːmʲ|ˈɟɾʲʊmˠɑːmʲ|2
|dugaire|d̪ˠʊɡəɾʲə|ˈd̪ˠʊɡɪɾʲə|1
|Gaelach|ˈɡeːl̪ˠəx|ˈɡeːlʲəx|2
|Gaedhlaing|ˈɡeːlɪɲ|ˈɡeːjlʲəŋ|4

## Current accuracy
See last 2 columns in [results.csv](results.csv)

Average Levenstein edit distance (from `fuzzywuzzy.partial_ratio`, 0-100 normalized, 100 is full match): 84.81

Average phonetic distance, (edit distance between dolgopolsky' equivalence classes, from `panphon.distance.dolgo_prime_distance_div_maxlen`, 0-1 normalized, 1 is full match): 0.9413
