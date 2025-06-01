# -*- coding: utf-8 -*-
"""
Created on Wed May 28 23:22:40 2025

@author: hellpanderrr
"""

prompt = """
I am developing a lua script that generates irish IPA transcription. Analyze my script, its output, Wiktionary transcription dump in CSV attached, Hickeley book on Irish phonetics (attached) and next iteration plan from LLM to assess whether I am moving in the right direciton.

Okay, here's an extensive prompt for an LLM, designed to provide a comprehensive overview of the Irish P2P project, its current state, outstanding issues, and the plan forward.

---

**Project Title:** Irish P2P (Phonetics-to-Pronunciation) Transcription System

**Project Goal:** To develop a Lua-based system that accurately transcribes standard Irish orthography (Caighdeán Oifigiúil, with a focus on Connacht Irish pronunciation as a primary target) into its International Phonetic Alphabet (IPA) representation. The system aims to handle complex Irish phonological processes including initial mutations (lenition, eclipsis), consonant quality (palatalization/velarization), vowel allophony, epenthesis, metathesis, and nasalization.

**High-Level Pipeline Overview:**

The transcription process is implemented as a series of sequential stages, each applying a set of rules (regex-based or procedural) to transform the input string:

1.  **Stage 1: Pre-processing:**
    *   Lowercase input.
    *   Normalize whitespace.
    *   Apply primary stress marker (`ˈ`) based on prefix patterns or default initial syllable stress.
    *   *UTF-8 handling is now robust using a `ustring` library.*

2.  **Stage 2: Orthographic Marker Placement:**
    *   Identify and replace multi-letter orthographic sequences (digraphs like `bh`, `mh`, `ch`, `th`, `sh`, `gh`, `dh`; geminates `ll`, `nn`, `rr`, `mm`; vocalization triggers like `amh`, `ibh`, `agh`, `eadh`; and complex vowel groups like `aoi`, `ao`) with unique temporary markers.
    *   This stage preserves original orthographic indices for later contextual quality determination.

3.  **Stage 3: Consonant Resolution (including Metathesis):**
    *   **Initial Mutations:** Resolve urú markers (`_URUF_`, etc.) to their phonetic forms (e.g., `_URUP_` -> `b`).
    *   **Lenition Markers:** Resolve lenition markers (e.g., `_BH_` -> `v` or `v'`, `_CH_` -> `x` or `ç`) based on orthographic context using `determine_consonant_quality_ortho`.
    *   **Metathesis:** Procedurally handle initial `cn-`, `gn-` to `cr-`, `gr-`, deriving the quality of the new `r` from the original `n`'s orthographic context.
    *   **Basic Consonant Quality:** Assign initial palatal/non-palatal quality to remaining single consonants based on orthographic context using `determine_consonant_quality_ortho`.

4.  **Stage 4: Vowel & Diphthong Resolution (Multi-Step):**
    *   **4.0 & 4.0.1:** Convert specific orthographic vowel+consonant sequences (e.g., `ea` before `_CH_`) to temporary vowel markers. Resolve `_CH_` markers to `x` or `ç`.
    *   **4.1:** Resolve vocalization trigger markers (e.g., `&A_VOC_M_MEDIAL_R&`) to intermediate phonetic vowel/diphthong markers.
    *   **4.2 & 4.3:** Convert orthographic long vowels (e.g., `á`) and digraph/trigraph vowels/diphthongs (e.g., `aoi`, `ia`) to temporary phonetic vowel/diphthong markers.
    *   **4.4:** Resolve all temporary vowel/diphthong markers to their base IPA phonetic forms.
    *   **4.5 (Contextual Allophony):** Apply core vowel allophony rules (e.g., `a` -> `ɑ`, `e` -> `ɛ`). This stage uses temporary placeholders for long vowels/diphthongs to simplify rule application, then restores them. Includes Connacht `ɑu` -> `əu` shift in monosyllables.
    *   **4.6 (Unstressed Vowel Reduction - Procedural):** Reduces unstressed short vowels to `ə` or `i` based on surrounding consonant quality. (Currently basic, needs expansion).

5.  **Stage 5: Epenthesis & Strong Sonorants (Procedural):**
    *   **`is_likely_monosyllable_phonetic_revised`:** Robustly checks if a phonetic string (after stress removal) contains only one vowel nucleus, using a prioritized list of phonetic nuclei and consonants for accurate parsing.
    *   **`parse_phonetic_string_to_units_for_epenthesis`:** Parses the phonetic string into units (vowels, consonants, stress marks) and assigns a preliminary `quality` (palatal, nonpalatal, vowel, stress_mark, unknown) to each. **Crucially improved to assign "vowel" to all single phonetic vowels.**
    *   **`apply_procedural_epenthesis`:**
        *   If the word is monosyllabic (per `is_likely_monosyllable_phonetic_revised`):
        *   Iterates through parsed units looking for Vowel-Consonant1-Consonant2 (V-C1-C2) sequences at the end of the syllable.
        *   Checks if C1 is a sonorant (`r,l,n,m`) and C2 is an obstruent.
        *   **Contextual Quality Inference for C1:** If C1 is an unmarked sonorant, its quality is inferred based on the preceding vowel and following C2's quality.
        *   **Heuristic for `nm`:** If C1C2 is `nm` and C2 (`m'`) is palatal, C1 (`n`) is forced palatal.
        *   If C1 and C2 qualities agree (both palatal or both nonpalatal) AND the C1C2 cluster is in a predefined list of epenthesis targets (`EPENTHESIS_TARGET_CLUSTERS_SLENDER` or `_BROAD`), an epenthetic vowel (`i` or `ə` respectively) is inserted.
    *   **Strong Sonorant Rules:** Applies regex-based rules for vowel lengthening/diphthongization before certain sonorants in monosyllables.

6.  **Stage 6: Diacritics:** Applies dental (`̪`) and velarization (`ˠ`) diacritics to relevant non-palatal consonants.

7.  **Stage 7: Final Cleanup:** Converts remaining quality markers (e.g., `s'` -> `ʃ`, `k'` -> `c`), removes silent `h` at word end, and cleans up any residual markers.

**Current Status (as of hypothetical Iteration 37AS completion):**

*   **Strengths:**
    *   UTF-8 handling is now robust.
    *   Metathesis for `cn/gn` is working correctly, including `r`-quality determination.
    *   The procedural epenthesis framework is largely successful for the focused test set:
        *   Monosyllable detection is reliable.
        *   Parser for epenthesis units is improved, especially for vowel quality.
        *   Contextual inference for C1 quality and heuristics (like for `nm`) are correctly triggering epenthesis for previously problematic words (`seilf`, `oilc`, `ainm`).
*   **Known Issues / Areas for Next Focus:**
    1.  **Parser Quality for Initial Unmarked Consonants:** The `parse_phonetic_string_to_units_for_epenthesis` still shows minor inaccuracies for initial consonants if they lack explicit phonetic markers (e.g., `d` in `dorcha` was parsed as palatal). This doesn't currently break epenthesis for the test set but indicates a small area for parser refinement.
    2.  **Vowel Nasalization:** Not yet implemented. This is a significant phonetic feature of Irish.
    3.  **Unstressed Vowel Reduction (Stage 4.6):** The current implementation is basic and needs to be expanded to cover more contexts and ensure accurate reduction to `ə` or `i`.
    4.  **Broader Connacht Allophony & Sandhi:** Many specific vowel shifts (e.g., detailed `ea(…)` contexts, `io`, `iu`), further consonant allophony, and inter-word sandhi phenomena are not yet handled.
    5.  **Completeness of Epenthesis Targets:** The `EPENTHESIS_TARGET_CLUSTERS_BROAD` and `_SLENDER` lists might need expansion based on wider vocabulary testing.

**Next Iteration (37AU - Renaming from previous plan, as 37AS was the "current" one):**

**Primary Goal for 37AU: Implement Vowel Nasalization.**

1.  **Design and Implement `apply_vowel_nasalization` function (New Procedural Stage):**
    *   **Placement:** Likely after Stage 4.5 (Contextual Allophony) and potentially after Stage 5 (Epenthesis) to see if epenthetic vowels can also be nasalized (though this is less common, it's worth considering).
    *   **Logic:**
        *   Use `parse_phonetic_string_to_units_for_epenthesis` (or a similar dedicated parser) to break the phonetic string into units.
        *   Iterate through the units. If a vowel unit is identified:
            *   Check the *phonetic quality* of the immediately preceding and/or immediately following unit.
            *   Define a set of nasal consonants (e.g., `{"m", "n", "ŋ", "N", "M", "mʲ", "nʲ", "Nʲ", "Mʲ"}`).
            *   If an adjacent unit is one of these nasal consonants, modify the vowel unit's `phon` string to add a nasalization diacritic (e.g., `~` after the vowel, or the IPA combining tilde above `̃` if easily representable and rendered).
            *   Consider directionality (regressive, progressive, or both). Irish often shows regressive nasalization (vowel before nasal), but progressive can also occur.
        *   Reconstruct the phonetic string from the (potentially modified) units.
    *   **Test Cases:** `ainm` (CSV: `ˈanʲəmʲ`), `mná` (CSV: `mˠn̪ˠɑ̃ː`), `rámh`, `snámh`, `fonn`, `ceann`, `am`, `cam`, `trom`, `lámh`. Consult CSV for expected nasalized vowels.

2.  **Minor Parser Refinement (Lower Priority for 37AU, but if time allows):**
    *   Address the quality assignment for initial unmarked consonants in `parse_phonetic_string_to_units_for_epenthesis` (e.g., `d` in `dorcha`). This might involve a simple default or a limited lookahead to the first vowel if the consonant is truly initial in the phonetic string being parsed.

**Estimated Iterations Remaining (Post-37AU, assuming successful nasalization):**

*   Vowel Nasalization (current focus): 1-2 (if initial implementation is solid)
*   Detailed Unstressed Vowel Reduction: 2-3
*   Connacht-Specific Allophony & Sandhi: 3-5
*   Final Polish & Broad Testing: 1-2

**Total Revised Estimate (from after 37AU): Approximately 7 - 12 iterations.**

This project is progressing well. The systematic, stage-based approach, coupled with iterative refinement and robust UTF-8 handling, is proving effective. The next major step is to incorporate vowel nasalization, which will add another significant layer of phonetic accuracy.

--[[
    Phonetic Transcription Script for Modern Irish (Iteration 37AU - Final Epenthesis Parser Fixes)
    Focus: 
           1. CRITICAL: Ensure `parse_phonetic_string_to_units_for_epenthesis` correctly assigns 
              `quality = "vowel"` to all single phonetic vowel characters to make 
              `is_likely_monosyllable_phonetic_revised` fully robust.
           2. Verify the contextual consonant quality inference for `ainm` and other cases.
           3. Re-test epenthesis, especially for `oilc`, `ainm`, `balbh`, `garbh`.
    Test words: cnámh, cnead, cnoc, gnaoi, gnó, seilf, dorcha, olc, oilc, dearc, feirc, balbh, garbh, gorm, bolg, ainm.
]]
local ustring_module_path = "ustring.ustring" 
local status, ustring_lib = pcall(require, ustring_module_path)

if not status then
    local early_print = print
    early_print("ERROR: Failed to load ustring module from path: " .. ustring_module_path)
    error("ustring module not found.")
end

local ulower = ustring_lib.lower
local usub = ustring_lib.sub
local ulen = ustring_lib.len
local ufind = ustring_lib.find
local umatch = ustring_lib.match
local ugsub = ustring_lib.gsub
local ugmatch = ustring_lib.gmatch
local utoNFD = ustring_lib.toNFD


-- Debug output file setup
local debug_file_path = "irish_debug_37AU.txt" 
local debug_file = io.open(debug_file_path, "w")
if debug_file then
    debug_file:write("\239\187\191") -- UTF-8 BOM
else
    local original_print_func_early = print
    original_print_func_early("WARN: Could not open debug_file " .. debug_file_path)
end
local original_print_func = print

-- Debug Flags
local DETAILED_DEBUG_ENABLED = true 
local STAGE_DEBUG_ENABLED = {
    PreProcess = false, 
    MarkDigraphsAndVocalisationTriggers = true, 
    ConsonantResolution = true,             
    Stage4_0_SpecificOrthoToTempMarker = true, 
    Stage4_0_1_Resolve_CH_Marker = true,    
    Stage4_1_VocmarkToTempMarker = false,    
    Stage4_2_LongVowelsOrthoToTempMarker = true, 
    Stage4_3_DiphthongsOrthoToTempMarker = true, 
    Stage4_4_ResolveTempVowelMarkers = true, 
    Stage4_5_ContextualAllophonyOnPhonetic = true, 
    Stage4_6_UnstressedVowelReduction_Procedural = false, 
    EpenthesisAndStrongSonorants = true, 
    Diacritics = true,                
    FinalCleanup = true,
}

print = function(...) 
    local args = {...}
    local str_args = {}
    for i, v in ipairs(args) do str_args[i] = tostring(v) end
    local msg = table.concat(str_args, "\t")
    original_print_func(msg) 
    if debug_file then debug_file:write(msg .. "\n"); debug_file:flush() end
end

local function debug_print_detailed(stage_name_for_flag_check, ...)
    if DETAILED_DEBUG_ENABLED or (STAGE_DEBUG_ENABLED[stage_name_for_flag_check]) then
        local args = {...}
        local str_args = {}
        for i, v in ipairs(args) do str_args[i] = tostring(v) end
        local msg = "    DBG (" .. stage_name_for_flag_check:sub(1,8) .. "): " .. table.concat(str_args, "\t") 
        original_print_func(msg) 
        if debug_file then debug_file:write(msg .. "\n"); debug_file:flush() end
    end
end

local irishPhonetics = {}

-- Orthographic Patterns
local SLENDER_VOWELS_ORTHO_CHARS_STR = "eéií"
local BROAD_VOWELS_ORTHO_CHARS_STR = "aáoóuú"
local ALL_VOWELS_ORTHO_CHARS_STR = SLENDER_VOWELS_ORTHO_CHARS_STR .. BROAD_VOWELS_ORTHO_CHARS_STR
local SLENDER_VOWELS_ORTHO_PATTERN = "[" .. SLENDER_VOWELS_ORTHO_CHARS_STR .. "]"
local BROAD_VOWELS_ORTHO_PATTERN = "[" .. BROAD_VOWELS_ORTHO_CHARS_STR .. "]"
local ALL_VOWELS_ORTHO_PATTERN = "[" .. ALL_VOWELS_ORTHO_CHARS_STR .. "]"
local SHORT_VOWELS_ORTHO_SINGLE_STR = "aeiou"
local CONSONANTS_ORTHO_CHARS_STR = "bcdfghlmnprst" 

-- Phonetic Patterns
local ANY_CONSONANT_PHONETIC_RAW_CHARS_STR = "kgptdfbmnszrlLNRMçjɣŋhwcʃɟɾ"
local ANY_CONSONANT_PHONETIC_PATTERN = "[" .. ANY_CONSONANT_PHONETIC_RAW_CHARS_STR .. "]"
local ANY_SHORT_VOWEL_PHONETIC_CHARS_STR = "aæɔeəiɪuʊʌ" 
local ANY_LONG_VOWEL_PHONETIC_CHARS_STR = "ɑeioɨuæ" 
local ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR = ANY_SHORT_VOWEL_PHONETIC_CHARS_STR .. ANY_LONG_VOWEL_PHONETIC_CHARS_STR
local ANY_DIPHTHONG_PHONETIC_STR_NO_CAPTURE = "(?:iə)|(?:ua)|(?:ai)|(?:ei)|(?:oi)|(?:ui)|(?:ɑu)|(?:ou)|(?:əu)|(?:eiə)" 
local SINGLE_VOWEL_WITH_OPT_LONG_STR_NO_CAPTURE = "(?:[" .. ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR .. "]ː?)" 
local PHONETIC_VOWEL_NUCLEUS_STRING_FOR_CAPTURE = ANY_DIPHTHONG_PHONETIC_STR_NO_CAPTURE .. "|" .. SINGLE_VOWEL_WITH_OPT_LONG_STR_NO_CAPTURE
local PHONETIC_VOWEL_NUCLEUS_PATTERN = "(" .. PHONETIC_VOWEL_NUCLEUS_STRING_FOR_CAPTURE .. ")"
local SHORT_VOWEL_PHONETIC_PATTERN_FOR_REDUCTION_INPUT = "["..ANY_SHORT_VOWEL_PHONETIC_CHARS_STR:gsub("[əɪi]", "").."]" 
local SHORT_VOWEL_CAPTURE_FOR_EPENTHESIS = "([" .. ANY_SHORT_VOWEL_PHONETIC_CHARS_STR .. "])"
local L_VARIANTS_PHONETIC = "[lL]"; local N_VARIANTS_PHONETIC = "[nNmM]"; local R_VARIANTS_PHONETIC = "[rR]";

local ALL_PHONETIC_NUCLEI_PRIORITY = {
    "iə", "ua", "ai", "ei", "oi", "ui", "ɑu", "ou", "əu", "eiə", "aw", "əi", 
    "ɑː", "eː", "iː", "oː", "uː", "ɨː", "æː",
    "a", "æ", "ɔ", "e", "ə", "i", "ɪ", "u", "ʊ", "ʌ"
}
local ALL_PHONETIC_CONSONANTS_PRIORITY = { 
    "tʲ", "dʲ", "lʲ", "nʲ", "ɾʲ", "fʲ", "vʲ", "bʲ", "pʲ", "mʲ", "Lʲ", "Nʲ", "Rʲ", "Mʲ", "s'", 
    "ɾˠ", "lˠ", "nˠ", "mˠ", "t̪", "d̪", "n̪", "l̪", 
    "c", "ɟ", "ʃ", "ç", "j", 
    "k", "g", "t", "d", "p", "b", "m", "n", "l", "r", "s", "f", "v", "L", "N", "R", "M", "x", "ɣ", "ŋ", "h", "w" 
}


local function determine_consonant_quality_ortho(original_ortho_word, ortho_cons_char_start_idx, ortho_cons_char_end_idx)
    if not original_ortho_word or not ortho_cons_char_start_idx or not ortho_cons_char_end_idx or ortho_cons_char_start_idx <= 0 or ortho_cons_char_end_idx > ulen(original_ortho_word) or ortho_cons_char_start_idx > ortho_cons_char_end_idx then
        debug_print_detailed("DetQual", "Bailing: Invalid indices or word for: ", original_ortho_word, ortho_cons_char_start_idx, ortho_cons_char_end_idx)
        return "nonpalatal" 
    end
    local current_ortho_cons_seq = usub(original_ortho_word, ortho_cons_char_start_idx, ortho_cons_char_end_idx)
    debug_print_detailed("DetQual", "Word:", original_ortho_word, "Cons seq:", current_ortho_cons_seq, "s:", ortho_cons_char_start_idx, "e:", ortho_cons_char_end_idx)

    if current_ortho_cons_seq == "l°" or current_ortho_cons_seq == "n°" then return "nonpalatal" end
    
    if current_ortho_cons_seq == "n" and ortho_cons_char_start_idx > 2 then
        local preceding_ea = usub(original_ortho_word, ortho_cons_char_start_idx - 2, ortho_cons_char_start_idx - 1)
        if preceding_ea == "ea" then
            local is_final_ean = (ortho_cons_char_end_idx == ulen(original_ortho_word))
            local next_char_after_n_idx = ortho_cons_char_end_idx + 1
            local next_char_is_consonant_or_nothing = true 
            if next_char_after_n_idx <= ulen(original_ortho_word) then
                if not umatch(usub(original_ortho_word, next_char_after_n_idx, next_char_after_n_idx), "[" .. CONSONANTS_ORTHO_CHARS_STR .. "]") then
                    next_char_is_consonant_or_nothing = false 
                end
            end
            if is_final_ean or next_char_is_consonant_or_nothing then return "palatal" end
        end
    end

    local prev_v_type_char, next_v_type_char = nil, nil; local next_v_quality_implication, prev_v_quality_implication
    local temp_idx = ortho_cons_char_end_idx + 1
    while temp_idx <= ulen(original_ortho_word) do
        local char = usub(original_ortho_word, temp_idx, temp_idx)
        local next_two_chars = usub(original_ortho_word, temp_idx, temp_idx + 1)
        local next_three_chars = usub(original_ortho_word, temp_idx, temp_idx + 2)

        if next_three_chars == "aoi" then next_v_type_char = "i"; break 
        elseif next_two_chars == "ao" or next_two_chars == "eo" or next_two_chars == "ia" or next_two_chars == "ua" or next_two_chars == "iu" then next_v_type_char = usub(original_ortho_word, temp_idx, temp_idx); break
        elseif umatch(char, ALL_VOWELS_ORTHO_PATTERN) then next_v_type_char = char; break
        elseif (char == "l" or char == "n") and usub(original_ortho_word, temp_idx+1, temp_idx+1) == "°" then next_v_type_char = "a"; break 
        elseif char == 'h' then 
             if temp_idx < ulen(original_ortho_word) then
                local char_after_h = usub(original_ortho_word, temp_idx+1, temp_idx+1)
                if umatch(char_after_h, ALL_VOWELS_ORTHO_PATTERN) then
                    temp_idx = temp_idx + 1; char = usub(original_ortho_word, temp_idx, temp_idx)
                    if umatch(char, ALL_VOWELS_ORTHO_PATTERN) then next_v_type_char = char; break end
                else break end
             else break end
        elseif umatch(char, "[" .. CONSONANTS_ORTHO_CHARS_STR:gsub("h","") .. CONSONANTS_ORTHO_CHARS_STR:upper() .. "°%-]") then break 
        elseif char ~= 'h' then break end
        temp_idx = temp_idx + 1
    end
    
    if next_v_type_char then
        if umatch(next_v_type_char, SLENDER_VOWELS_ORTHO_PATTERN) then next_v_quality_implication = "slender"
        elseif umatch(next_v_type_char, BROAD_VOWELS_ORTHO_PATTERN) then next_v_quality_implication = "broad"
        end
    end
    debug_print_detailed("DetQual", "Next relevant vowel char for quality:", next_v_type_char or "nil", "Next quality implication:", next_v_quality_implication or "nil")

    temp_idx = ortho_cons_char_start_idx - 1
    while temp_idx >= 1 do
        local char = usub(original_ortho_word, temp_idx, temp_idx)
        if umatch(char, ALL_VOWELS_ORTHO_PATTERN) then
            local v_group_end = temp_idx; local v_group_start = temp_idx
            while v_group_start > 1 and umatch(usub(original_ortho_word, v_group_start - 1, v_group_start - 1), ALL_VOWELS_ORTHO_PATTERN) do v_group_start = v_group_start - 1 end
            local preceding_vowel_group = usub(original_ortho_word, v_group_start, v_group_end)
            
            if preceding_vowel_group == "ea" and (current_ortho_cons_seq == "ch" or current_ortho_cons_seq == "g" or current_ortho_cons_seq == "r" or current_ortho_cons_seq == "l" or current_ortho_cons_seq == "_CH_" or current_ortho_cons_seq == "_GH_") then prev_v_type_char = usub(original_ortho_word, v_group_start,v_group_start) 
            elseif preceding_vowel_group == "iu" and (ortho_cons_char_end_idx == ulen(original_ortho_word) or not umatch(usub(original_ortho_word, ortho_cons_char_end_idx + 1, ortho_cons_char_end_idx + 1), "["..ALL_VOWELS_ORTHO_CHARS_STR..CONSONANTS_ORTHO_CHARS_STR..CONSONANTS_ORTHO_CHARS_STR:upper().."%-%_]")) then prev_v_type_char = "i"
            else prev_v_type_char = usub(original_ortho_word, v_group_end, v_group_end) end
            break
        elseif usub(original_ortho_word, temp_idx-1, temp_idx) == "l°" or usub(original_ortho_word, temp_idx-1, temp_idx) == "n°" then if temp_idx == ortho_cons_char_start_idx -1 then prev_v_type_char = "a"; break end
        elseif umatch(char, "[" .. CONSONANTS_ORTHO_CHARS_STR .. CONSONANTS_ORTHO_CHARS_STR:upper() .. "°%-]") then else break end
        temp_idx = temp_idx - 1
    end
    if prev_v_type_char then
        if umatch(prev_v_type_char, SLENDER_VOWELS_ORTHO_PATTERN) then prev_v_quality_implication = "slender"
        elseif umatch(prev_v_type_char, BROAD_VOWELS_ORTHO_PATTERN) then prev_v_quality_implication = "broad"
        end
    end
    debug_print_detailed("DetQual", "Prev relevant vowel char for quality:", prev_v_type_char or "nil", "Prev quality implication:", prev_v_quality_implication or "nil")
    
    local final_quality
    if next_v_quality_implication == "slender" then final_quality = "palatal"
    elseif next_v_quality_implication == "broad" then final_quality = "nonpalatal"
    elseif prev_v_quality_implication == "slender" then final_quality = "palatal"
    elseif prev_v_quality_implication == "broad" then final_quality = "nonpalatal"
    else final_quality = "nonpalatal" end 
    debug_print_detailed("DetQual", "Final determined quality for '", current_ortho_cons_seq, "': ", final_quality)
    return final_quality
end

local function is_likely_monosyllable_phonetic_revised(phon_word_local)
    if not phon_word_local then return false end
    local no_stress_local = ugsub(phon_word_local, "ˈ", "") 
    
    local count_local = 0
    local current_pos_local = 1
    while current_pos_local <= ulen(no_stress_local) do
        local matched_nucleus_this_iter = false
        for _, nucleus_pattern in ipairs(ALL_PHONETIC_NUCLEI_PRIORITY) do
            if usub(no_stress_local, current_pos_local, current_pos_local + ulen(nucleus_pattern) - 1) == nucleus_pattern then
                count_local = count_local + 1
                current_pos_local = current_pos_local + ulen(nucleus_pattern)
                matched_nucleus_this_iter = true
                goto continue_outer_loop_monosyllable_check 
            end
        end
        if not matched_nucleus_this_iter then
            local matched_other_unit_this_iter = false
            for _, cons_pattern in ipairs(ALL_PHONETIC_CONSONANTS_PRIORITY) do 
                 if usub(no_stress_local, current_pos_local, current_pos_local + ulen(cons_pattern) - 1) == cons_pattern then
                    current_pos_local = current_pos_local + ulen(cons_pattern)
                    matched_other_unit_this_iter = true
                    goto continue_outer_loop_monosyllable_check
                end
            end
            if not matched_other_unit_this_iter then 
                if usub(no_stress_local, current_pos_local, current_pos_local) == "'" then 
                    current_pos_local = current_pos_local + 1
                    goto continue_outer_loop_monosyllable_check
                end
                current_pos_local = current_pos_local + 1
            end
        end
        ::continue_outer_loop_monosyllable_check::
    end
    debug_print_detailed("EpenthesisAndStrongSonorants", "is_likely_monosyllable_revised for '", no_stress_local, "' (orig: '", phon_word_local, "') count: ", count_local, " result: ", tostring(count_local == 1))
    return count_local == 1
end


local UNSTRESSED_PREFIXES_ORTHO = {"an%-", "droch%-", "mí%-", "do%-", "ró%-", "dea%-", "fíor%-", "sean%-", "ath%-", "comh%-", "fo%-", "frith%-", "idir%-", "in%-", "réamh%-", "so%-", "tras%-", "mór%-", "ban%-", "cam%-", "fionn%-", "leas%-"}

local function resolve_lenited_consonant(base_phoneme_palatal, base_phoneme_nonpalatal, full_match_marker, o_context_str, original_match_info_tbl, options)
    options = options or {}
    if not original_match_info_tbl or not original_match_info_tbl.ortho_s or not original_match_info_tbl.ortho_e then return base_phoneme_nonpalatal end
    local quality = determine_consonant_quality_ortho(o_context_str, original_match_info_tbl.ortho_s, original_match_info_tbl.ortho_e)
    
    if options.can_be_w and quality == "nonpalatal" then
        local next_v_char_idx = original_match_info_tbl.ortho_e + 1
        if next_v_char_idx <= ulen(o_context_str) then
            local next_char = usub(o_context_str, next_v_char_idx, next_v_char_idx)
            if umatch(next_char, BROAD_VOWELS_ORTHO_PATTERN) then
                local prev_char_idx = original_match_info_tbl.ortho_s - 1
                if prev_char_idx >= 1 then
                    local prev_char = usub(o_context_str, prev_char_idx, prev_char_idx)
                    if not umatch(prev_char, "[rlcsrlnLNRM]'?$") then return "w" end
                else return "w" end 
            end
        end
    end
    
    return quality == 'palatal' and base_phoneme_palatal or base_phoneme_nonpalatal
end

-- ====== RULE STAGES ====== --
irishPhonetics.rules_stage1_preprocess = {
    { pattern = "^%s*(.-)%s*$", replacement = function(captured_string) if captured_string then return ulower(captured_string) else return "" end end },
    { pattern = "%s+", replacement = " " }, { pattern = "�", replacement = "" }, 
    { pattern = "^([^ˈ%-].*)$", replacement = function(word_part_to_stress)
        if not word_part_to_stress or word_part_to_stress == "" then return "" end
        for _, prefix in ipairs(UNSTRESSED_PREFIXES_ORTHO) do
            if usub(word_part_to_stress, 1, ulen(prefix)) == prefix then
                local root = usub(word_part_to_stress, ulen(prefix) + 1)
                if root == "" then return word_part_to_stress end
                if umatch(root, "^" .. ALL_VOWELS_ORTHO_PATTERN) then return prefix .. "ˈ" .. root
                elseif umatch(root, "^(" .. CONSONANTS_ORTHO_CHARS_STR .. "+)(" .. ALL_VOWELS_ORTHO_PATTERN .. ")") then return prefix .. "ˈ" .. root
                else return word_part_to_stress end
            end
        end
        if umatch(word_part_to_stress, "^" .. ALL_VOWELS_ORTHO_PATTERN) then return "ˈ" .. word_part_to_stress
        elseif umatch(word_part_to_stress, "^(" .. CONSONANTS_ORTHO_CHARS_STR .. "+)(" .. ALL_VOWELS_ORTHO_PATTERN .. ")") then return "ˈ" .. word_part_to_stress
        end
        return word_part_to_stress
    end},
}

irishPhonetics.rules_stage2_mark_digraphs_and_vocalisation_triggers = {
    { pattern = "bhf", replacement = "_URUF_", ortho_len = 3 }, { pattern = "bp", replacement = "_URUP_", ortho_len = 2 },
    { pattern = "dt", replacement = "_URUT_", ortho_len = 2 }, { pattern = "gc", replacement = "_URUC_", ortho_len = 2 },
    { pattern = "mb", replacement = "_URUM_", ortho_len = 2 }, { pattern = "nd", replacement = "_URUN_", ortho_len = 2 },
    { pattern = "ng", replacement = "_URUG_", ortho_len = 2 },

    { pattern = "aghaidh(#?)$", replacement = function(m,c1) return "&AGHAIDH_VOC_TARGET&" .. (c1 or "") end, ortho_len = 7 },
    { pattern = "ubh(#?)$", replacement = function(m,c1) return "&U_VOC_B_FINAL&" .. (c1 or "") end, ortho_len = 3}, 
    { pattern = "ámh(#?)$", replacement = function(m,c1) return "&A_ACUTE_LONG_VOC_M_FINAL&" .. (c1 or "") end, ortho_len = 3}, 
    { pattern = "amh(r)", replacement = function(m,c1) return "&A_VOC_M_MEDIAL_R&" .. c1 end, ortho_len = 3}, 
    { pattern = "eabh(r)", replacement = function(m,c1) return "&EA_VOC_B_MEDIAL_R&" .. c1 end, ortho_len = 4}, 
    { pattern = "adh(#?)$", replacement = function(m,c1) return "&A_VOC_D_FINAL&" .. (c1 or "") end, ortho_len = 3}, 
    { pattern = "eadh(#?)$", replacement = function(m,c1) return "&EA_VOC_D_FINAL&" .. (c1 or "") end, ortho_len = 4}, 
    { pattern = "agh(#?)$", replacement = function(m,c1) return "&A_VOC_G_FINAL&" .. (c1 or "") end, ortho_len = 3}, 
    { pattern = "ogh(#?)$", replacement = function(m,c1) return "&O_VOC_G_FINAL&" .. (c1 or "") end, ortho_len = 3},
    { pattern = "obh(#?)$", replacement = function(m,c1) return "&O_VOC_B_FINAL&" .. (c1 or "") end, ortho_len = 3}, 
    { pattern = "omh(#?)$", replacement = function(m,c1) return "&O_VOC_M_FINAL&" .. (c1 or "") end, ortho_len = 3},
    { pattern = "ibh(#?)$", replacement = function(m,c1) return "&I_VOC_B_FINAL&" .. (c1 or "") end, ortho_len = 3}, 
    { pattern = "imh(#?)$", replacement = function(m,c1) return "&I_VOC_M_FINAL&" .. (c1 or "") end, ortho_len = 3}, 
    { pattern = "idh(#?)$", replacement = function(m,c1) return "&I_VOC_D_FINAL&" .. (c1 or "") end, ortho_len = 3}, 
    { pattern = "uidh(#?)$", replacement = function(m,c1) return "&UI_VOC_D_FINAL&" .. (c1 or "") end, ortho_len = 4}, 
    { pattern = "áth(#?)$", replacement = function(m,c1) return "&A_ACUTE_LONG_VOC_TH_SILENT_FINAL&" .. (c1 or "") end, ortho_len = 3}, 
    { pattern = "aidh(#?)$", replacement = function(m,c1) return "&AIDH_FINAL_SCHWA&" .. (c1 or "") end, ortho_len = 4},
    { pattern = "aigh(#?)$", replacement = function(m,c1) return "&AIGH_FINAL_SCHWA&" .. (c1 or "") end, ortho_len = 4},
    
    { pattern = "aoi", replacement = "&AOI_LONG&", ortho_len = 3 }, 
    { pattern = "ao", replacement = "&AO_LONG&", ortho_len = 2 },
    { pattern = "ói", replacement = "&OI_ACUTE_LONG&", ortho_len = 2 },
    { pattern = "aí", replacement = "_A_I_ACUTE_LONG_", ortho_len = 2 },

    { pattern = "^fh", replacement = "_FH_INITIAL_LENITED_", ortho_len = 2 },
    { pattern = "bh", replacement = "_BH_", ortho_len = 2 }, { pattern = "mh", replacement = "_MH_", ortho_len = 2 }, 
    { pattern = "ch", replacement = "_CH_", ortho_len = 2 },
    { pattern = "dh", replacement = "_DH_", ortho_len = 2 }, { pattern = "gh", replacement = "_GH_", ortho_len = 2 },
    { pattern = "ph", replacement = "_PH_", ortho_len = 2 },
    { pattern = "sh", replacement = "_SH_", ortho_len = 2 }, { pattern = "th", replacement = "_TH_", ortho_len = 2 },
    
    { pattern = "ll", replacement = "_LL_", ortho_len = 2 },   { pattern = "nn", replacement = "_NN_", ortho_len = 2 },
    { pattern = "rr", replacement = "_RR_", ortho_len = 2 },   { pattern = "mm", replacement = "_MM_", ortho_len = 2 },
    { pattern = "(ˈ"..SHORT_VOWELS_ORTHO_SINGLE_STR..")l("..ALL_VOWELS_ORTHO_PATTERN..")", replacement = "%1l°%2", ortho_len_func = function(m,c1,c2) return ulen(c1) + 1 + ulen(c2) end},
    { pattern = "(ˈ"..SHORT_VOWELS_ORTHO_SINGLE_STR..")n("..ALL_VOWELS_ORTHO_PATTERN..")", replacement = "%1n°%2", ortho_len_func = function(m,c1,c2) return ulen(c1) + 1 + ulen(c2) end},
}

irishPhonetics.rules_stage3_consonant_resolution = {
    { pattern = "_FH_INITIAL_LENITED_", replacement = "h" }, { pattern = "_FH_SILENT_", replacement = "" }, { pattern = "_TH_", replacement = "h" },
    { pattern = "_URUF_", replacement = "v" }, { pattern = "_URUP_", replacement = "b" }, { pattern = "_URUT_", replacement = "d" }, 
    { pattern = "_URUC_", replacement = "g" }, { pattern = "_URUM_", replacement = "m" }, { pattern = "_URUN_", replacement = "n" }, { pattern = "_URUG_", replacement = "ŋ" },
    { pattern = "_PH_", replacement = function(full_match_marker, o_context_str, original_match_info_tbl) return resolve_lenited_consonant("f'", "f", full_match_marker, o_context_str, original_match_info_tbl) end },
    { pattern = "_SH_", replacement = function(full_match_marker, o_context_str, original_match_info_tbl)
        if not original_match_info_tbl or not original_match_info_tbl.ortho_s or not original_match_info_tbl.ortho_e then return "h" end
        local next_v_start_ortho = original_match_info_tbl.ortho_e + 1; local next_v_is_slender_flag = false
        if next_v_start_ortho <= ulen(o_context_str) then if umatch(usub(o_context_str, next_v_start_ortho, next_v_start_ortho), SLENDER_VOWELS_ORTHO_PATTERN) then next_v_is_slender_flag = true end end
        if umatch(o_context_str, "^[sS][eé][áa]n", original_match_info_tbl.ortho_s -1 ) then return "h'" end 
        return next_v_is_slender_flag and "h'" or "h"
    end },
    { pattern = "_FH_INTERNAL_", replacement = "" }, 
    { pattern = "_BH_", replacement = function(full_match_marker, o_context_str, original_match_info_tbl) return resolve_lenited_consonant("v'", "v", full_match_marker, o_context_str, original_match_info_tbl, {can_be_w = true}) end },
    { pattern = "_DH_", replacement = function(full_match_marker, o_context_str, original_match_info_tbl) return resolve_lenited_consonant("j", "ɣ", full_match_marker, o_context_str, original_match_info_tbl) end },
    { pattern = "_GH_", replacement = function(full_match_marker, o_context_str, original_match_info_tbl) return resolve_lenited_consonant("j", "ɣ", full_match_marker, o_context_str, original_match_info_tbl) end },
    { pattern = "_MH_", replacement = function(full_match_marker, o_context_str, original_match_info_tbl) return resolve_lenited_consonant("v'", "v", full_match_marker, o_context_str, original_match_info_tbl, {can_be_w = true}) end },
    { pattern = "_LL_", replacement = function(full_match_marker, o_context_str, original_match_info_tbl) return resolve_lenited_consonant("L'", "L", full_match_marker, o_context_str, original_match_info_tbl) end },
    { pattern = "_NN_", replacement = function(full_match_marker, o_context_str, original_match_info_tbl) 
        local quality = determine_consonant_quality_ortho(o_context_str, original_match_info_tbl.ortho_s, original_match_info_tbl.ortho_e)
        return quality == "palatal" and "N'" or "N"
    end },
    { pattern = "_RR_", replacement = function(full_match_marker, o_context_str, original_match_info_tbl) return resolve_lenited_consonant("R'", "R", full_match_marker, o_context_str, original_match_info_tbl) end },
    { pattern = "_MM_", replacement = function(full_match_marker, o_context_str, original_match_info_tbl) return resolve_lenited_consonant("M'", "M", full_match_marker, o_context_str, original_match_info_tbl) end },
    { pattern = "l°", replacement = "l_neutral_" }, { pattern = "n°", replacement = "n_neutral_" },
    { pattern = "([bcdfghkmprst])", replacement = function(c_capture, o_context_str, original_match_info_tbl)
        if not c_capture then return "" end; if c_capture == "l_neutral_" or c_capture == "n_neutral_" then return c_capture end 
        local base = c_capture; if c_capture == "c" then base = "k" end
        if not original_match_info_tbl or not original_match_info_tbl.ortho_s or not original_match_info_tbl.ortho_e or not o_context_str then return base == "s" and "s" or base end
        debug_print_detailed("ConsonantResolution", "Single cons rule: c_capture=", c_capture, "o_s=", original_match_info_tbl.ortho_s, "o_e=", original_match_info_tbl.ortho_e)
        local quality = determine_consonant_quality_ortho(o_context_str, original_match_info_tbl.ortho_s, original_match_info_tbl.ortho_e)
        if base == "s" then return quality == "palatal" and "s'" or "s" else return quality == "palatal" and base .. "'" or base end
    end},
}

irishPhonetics.rules_stage4_0_specific_ortho_to_temp_marker = {
    { pattern = "^(ˈ?(?:[^"..ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR.."]*))a(&A_VOC_M_MEDIAL_R&)(s["..ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR.."]?)", replacement = "%1&AU_FROM_AMH&%3" }, 
    { pattern = "^(ˈ?(?:[^"..ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR.."]*))ea(&EA_VOC_B_MEDIAL_R&)(r["..ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR.."]?)", replacement = "%1&EA_PRE_BH_VOC&%3" }, 
    { pattern = "(["..ANY_SHORT_VOWEL_PHONETIC_CHARS_STR.."])(&A_VOC_M_MEDIAL_R&)", replacement = "%1&VOC_AMH_MEDIAL_R&" }, 
    { pattern = "(["..ANY_SHORT_VOWEL_PHONETIC_CHARS_STR.."])(&EA_VOC_B_MEDIAL_R&)", replacement = "%1&VOC_EABH_MEDIAL_R&" }, 
    { pattern = "^(ˈ?)("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)".."ea(_CH_t)$", replacement = "%1%2&EA_BROAD_SHORT_PRE_CHT&%3" }, 
    { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)".."ea(_CH_)", replacement = "%1&EA_SLENDER_PRE_CH&%2" }, 
    { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)".."ea(ŋ)", replacement = function(full_match, c_part, ng_cap, o_context_str, original_match_info_tbl) 
        local ortho_n_start_idx = original_match_info_tbl.ortho_e - ulen(ng_cap) + 1 
        local quality_of_n = determine_consonant_quality_ortho(o_context_str, ortho_n_start_idx, ortho_n_start_idx) 
        if quality_of_n == "palatal" then return (c_part or "") .."&EA_SLENDER_PRE_NG&"..ng_cap 
        else return (c_part or "") .. "&EA_BROAD_PRE_NG&"..ng_cap end 
    end, use_original_context_for_rules = true }, 
    { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)".."ea(N')$", replacement = "%1&EA_SLENDER_PRE_NN&%2" },
    { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)".."ea(N)$", replacement = "%1&EA_BROAD_PRE_NN&%2" }, 
    { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)".."ea(N)([^'])", replacement = "%1&EA_BROAD_PRE_NN&%2%3" }, 
    { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)".."ea(r')", replacement = "%1&EA_SLENDER_PRE_RPRIME&%2" }, 
    { pattern = "((?:["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."]'?)*)iu(_CH_)", replacement = "%1&IU_SLENDER_FINAL_PRE_CH&%2" }, 
    { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)".."ea(r)", replacement = "%1&EA_BROAD_PRE_R&%2" },
    { 
        pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)".."ea(n)$", 
        replacement = function(full_match, c_part, n_cap, o_context_str, original_match_info_tbl)
            return (c_part or "") .. "&EA_SLENDER_PRE_N&" .. (n_cap or "")
        end, 
        use_original_context_for_rules = true 
    },
    { 
        pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)".."ea(n)([^" .. ALL_VOWELS_ORTHO_CHARS_STR .. "°%-bhfpgcdtmls" .. ANY_CONSONANT_PHONETIC_RAW_CHARS_STR .. "'])",
        replacement = function(full_match, c_part, n_cap, next_char_phon, o_context_str, original_match_info_tbl)
            return (c_part or "") .. "&EA_SLENDER_PRE_N&" .. (n_cap or "") .. (next_char_phon or "")
        end, 
        use_original_context_for_rules = true 
    },
    { pattern = "io", replacement = "&IO_SHORT_TARGET&" },
}

irishPhonetics.rules_stage4_0_1_resolve_ch_marker = {
    { pattern = "_CH_", replacement = function(full_match_marker, o_context_str, original_match_info_tbl)
        if not original_match_info_tbl or not original_match_info_tbl.ortho_s or not original_match_info_tbl.ortho_e then return "x" end
        local quality_for_ch = determine_consonant_quality_ortho(o_context_str, original_match_info_tbl.ortho_s, original_match_info_tbl.ortho_e)
        return quality_for_ch == "palatal" and "ç" or "x"
    end },
}

irishPhonetics.rules_stage4_1_vocmark_to_temp_marker = {}

irishPhonetics.rules_stage4_2_long_vowels_ortho_to_temp_marker = {
    { pattern = "éi", replacement = "&E_ACUTE_I_LONG&" }, { pattern = "iú", replacement = "&I_ACUTE_U_LONG&"},
    { pattern = "á", replacement = "&A_ACUTE_LONG&" }, { pattern = "é", replacement = "&E_ACUTE_LONG&" },
    { pattern = "í", replacement = "&I_ACUTE_LONG&" }, { pattern = "ó", replacement = "&O_ACUTE_LONG&" },
    { pattern = "ú", replacement = "&U_ACUTE_LONG&" },
    { pattern = "_A_I_ACUTE_LONG_", replacement = "&A_I_ACUTE_LONG_RESOLVE&" },
}

irishPhonetics.rules_stage4_3_diphthongs_ortho_to_temp_marker = {
    { pattern = "ae", replacement = "&AE_SEQ&" },
    { pattern = "ia", replacement = "&IA_DIPH&" }, { pattern = "ua", replacement = "&UA_DIPH&" },
    { pattern = "ai", replacement = "&AI_DIPH&" }, { pattern = "ei", replacement = "&EI_DIPH&" }, 
    { pattern = "oi", replacement = "&OI_DIPH&" }, { pattern = "ui", replacement = "&UI_DIPH&" }, 
    { pattern = "au", replacement = "&AU_DIPH&" }, { pattern = "ou", replacement = "&OU_DIPH&" },
    { pattern = "eo", replacement = "&EO_SEQ&" },
}

irishPhonetics.rules_stage4_4_resolve_temp_vowel_markers = {
    { pattern = "&&", replacement = "&"}, 
    { pattern = "&U_VOC_B_FINAL&(#?)", replacement = "uː%1"},      
    { pattern = "&A_ACUTE_LONG_VOC_M_FINAL&(#?)", replacement = "ɑːv%1"},     
    { pattern = "&A_VOC_M_MEDIAL_R&(r)", replacement = "&TEMP_CONN_AU&%1"},   
    { pattern = "&EA_VOC_B_MEDIAL_R&(r)", replacement = "&TEMP_CONN_AU&%1"},  
    { pattern = "&A_VOC_D_FINAL&(#?)", replacement = "ə%1"},       
    { pattern = "&EA_VOC_D_FINAL&(#?)", replacement = "uː%1"},     
    { pattern = "&AGHAIDH_VOC_TARGET&(#?)", replacement = "əi%1"}, 
    { pattern = "&A_VOC_G_FINAL&(#?)", replacement = "ə%1"},      
    { pattern = "&O_VOC_G_FINAL&(#?)", replacement = "ə%1"},       
    { pattern = "&O_VOC_B_FINAL&(#?)", replacement = "oː%1"},      
    { pattern = "&O_VOC_M_FINAL&(#?)", replacement = "oː%1"}, 
    { pattern = "&I_VOC_B_FINAL&(#?)", replacement = "iː%1"},      
    { pattern = "&I_VOC_M_FINAL&(#?)", replacement = "iː%1"},      
    { pattern = "&I_VOC_D_FINAL&(#?)", replacement = "iː%1"},      
    { pattern = "&UI_VOC_D_FINAL&(#?)", replacement = "iː%1"},     
    { pattern = "&A_ACUTE_LONG_VOC_TH_SILENT_FINAL&(#?)", replacement = "ɑː%1"},
    { pattern = "&AIDH_FINAL_SCHWA&(#?)", replacement = "ə%1"}, 
    { pattern = "&AIGH_FINAL_SCHWA&(#?)", replacement = "ə%1"}, 
    { pattern = "&AIDH_FINAL_VOC&(#?)", replacement = "ai%1"}, 
    { pattern = "&AIGH_FINAL_VOC&(#?)", replacement = "ai%1"}, 

    { pattern = "&A_I_ACUTE_LONG_RESOLVE&", replacement = "iː" }, 
    { pattern = "&E_ACUTE_I_LONG&", replacement = "eː" }, 
    { pattern = "&I_ACUTE_U_LONG&", replacement = "uː"}, 
    { pattern = "&A_ACUTE_LONG&", replacement = "ɑː" }, 
    { pattern = "&E_ACUTE_LONG&", replacement = "eː" }, 
    { pattern = "&I_ACUTE_LONG&", replacement = "iː" }, 
    { pattern = "&O_ACUTE_LONG&", replacement = "oː" }, 
    { pattern = "&U_ACUTE_LONG&", replacement = "uː" }, 
    { pattern = "&AO_LONG&", replacement = "ɨː"}, 
    { pattern = "&AOI_LONG&", replacement = "iː"},
    { pattern = "&OI_ACUTE_LONG&", replacement = "oː"},

    { pattern = "&AE_SEQ&", replacement = "eː" }, 
    { pattern = "&EO_SEQ&", replacement = "oː" },
    { pattern = "&IA_DIPH&", replacement = "iə" }, 
    { pattern = "&UA_DIPH&", replacement = "ua" }, 
    { pattern = "&AI_DIPH&(nm')", replacement = "a%1"}, 
    { pattern = "&AI_DIPH&", replacement = "ai" }, 
    { pattern = "&EI_DIPH&", replacement = "e" }, 
    { pattern = "&OI_DIPH&("..ANY_CONSONANT_PHONETIC_PATTERN.."*')", replacement = "ɛ%1" }, 
    { pattern = "&OI_DIPH&", replacement = "ɔ" }, 
    { pattern = "&UI_DIPH&", replacement = "ɪ" }, 
    { pattern = "&AU_DIPH&", replacement = "au" }, 
    { pattern = "&OU_DIPH&", replacement = "ou" },

    { pattern = "&VOC_AMH_MEDIAL_R&", replacement = "&TEMP_CONN_AU&"}, 
    { pattern = "&VOC_EABH_MEDIAL_R&", replacement = "&TEMP_CONN_AU&"}, 
    { pattern = "&EA_PRE_BH_VOC&", replacement = "a"}, 
    { pattern = "&IO_SHORT_TARGET&", replacement = "ɪ"},

    { pattern = "&EA_BROAD_SHORT_PRE_CHT&", replacement = "a"}, 
    { pattern = "&EA_SLENDER_PRE_CH&", replacement = "æː"}, 
    { pattern = "&EA_SLENDER_PRE_NG&", replacement = "æ"}, 
    { pattern = "&EA_BROAD_PRE_NG&", replacement = "a"}, 
    { pattern = "&EA_SLENDER_PRE_NN&", replacement = "æ"}, 
    { pattern = "&EA_BROAD_PRE_NN&", replacement = "a"}, 
    { pattern = "&EA_SLENDER_PRE_RPRIME&", replacement = "æ"}, 
    { pattern = "&EA_BROAD_PRE_R&", replacement = "a"}, 
    { pattern = "&IU_SLENDER_FINAL_PRE_CH&", replacement = "ʊ"}, 
    { pattern = "&EA_SLENDER_PRE_N&", replacement = "æ"}, 
    { pattern = "&EA_BROAD_PRE_N&", replacement = "a" },   
}

-- Stage 4.5: Placeholder creation rules
local placeholder_creation_rules_stage4_5 = {
    { pattern = "au", replacement = "&PHON_AU_DIPH&" }, 
    { pattern = "ai", replacement = "&PHON_AI_DIPH&" },
    { pattern = "iə", replacement = "&PHON_IA_DIPH&" }, { pattern = "ua", replacement = "&PHON_UA_DIPH&" },
    { pattern = "ou", replacement = "&PHON_OU_DIPH&" }, { pattern = "ei", replacement = "&PHON_EI_DIPH&" },
    { pattern = "oi", replacement = "&PHON_OI_DIPH&" }, { pattern = "ui", replacement = "&PHON_UI_DIPH&" },
    { pattern = "əu", replacement = "&PHON_SCHWA_U_DIPH&" },
    { pattern = "aw", replacement = "&PHON_AW_SEQ&" }, 
    { pattern = "əi", replacement = "&PHON_SCHWA_I_DIPH&" },
    
    { pattern = "ɑː", replacement = "&PHON_A_LONG&" }, { pattern = "eː", replacement = "&PHON_E_LONG&" },
    { pattern = "iː", replacement = "&PHON_I_LONG&" }, { pattern = "oː", replacement = "&PHON_O_LONG&" },
    { pattern = "uː", replacement = "&PHON_U_LONG&" }, { pattern = "ɨː", replacement = "&PHON_Y_LONG&" },
    { pattern = "æː", replacement = "&PHON_AE_LONG&" },
}

-- Stage 4.5: Core allophony rules (excluding placeholder creation/restoration and final Connacht shift)
local core_allophony_rules_for_stage4_5 = {
    { pattern = "(["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."]['ʲ])(a)", replacement = "%1æ" }, 
    { pattern = "a", replacement = "ɑ" },          
    { pattern = "e(?!ː)", replacement = "ɛ" },     
    { pattern = "i(?!ː)", replacement = "ɪ" },     
    { pattern = "o", replacement = "ɔ" }, 
    { pattern = "u([kgxɣ])", replacement = "ʊ%1" },
    { pattern = "u", replacement = "ɔ" },         
    
    { pattern = "(v')([aæ])", replacement = "%1%2" }, 
    { pattern = "t(æ)", replacement = "tʲ%1"}, 
    { pattern = "l(&PHON_I_LONG&)", replacement = "lʲ%1"},  
    { pattern = "d(lʲ&PHON_I_LONG&)", replacement = "dʲ%1"}, 
    { pattern = "n(iv')", replacement = "nʲ%1"}, 
    { pattern = "&PHON_Y_LONG&(ç)", replacement = "&PHON_I_LONG&%1"}, 
    { pattern = "(dʲa)(r)(h)(&PHON_A_LONG&ɾʲ)", replacement = "%1ɾˠ%4" }, 
    { pattern = "(&PHON_A_LONG&)i(r)$", replacement = "%1iɾʲ"}, 
    { pattern = "d(a)(r)", replacement = "dʲ%1%2"}, 
    { pattern = "k(a)(rt)", replacement = "c%1%2"}, 
    { pattern = "&PHON_I_LONG&ɔ(["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."](?!'))", replacement = "&PHON_I_LONG&%1" }, 
    { pattern = "&PHON_I_LONG&ɔ(["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."]')", replacement = "&PHON_I_LONG&%1" },    
    { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)([ɔʊʌ])(["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."]['ʃçjɟc])", replacement = "%1e%3" },
    { pattern = "([ɾR]')i", replacement = "%1e" }, { pattern = "([ɾR])i", replacement = "%1e" },
    { pattern = "([ɾR]')ɔ", replacement = "%1ɔ" }, { pattern = "([ɾR])ɔ", replacement = "%1ɔ" }, 
    { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."')a(["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."]['ʃçjɟc])", replacement = "%1e%2" },
    { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."')([ɔʊʌ])(["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."]['ʃçjɟc])", replacement = "%1i%3" },
    { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."')e(["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."]['ʃçjɟc])", replacement = "%1e%2" },
    { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."')i(["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."]['ʃçjɟc])", replacement = "%1i%2" },
    { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."')a(["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."](?!'))", replacement = "%1æ%2" },
    { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."')([ʊ])(["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."](?!['kgxɣ]))", replacement = "%1ɔ%3" }, 
    { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."')([ɔʌ])(["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."](?!'))", replacement = "%1ɔ%2" }, 
    { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."')e(["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."](?!'))", replacement = "%1æ%2" },
    { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."')i(["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."](?!'))", replacement = "%1i%2" },
    { pattern = "(["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."ˈ](?!'))a(["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."]['ʃçjɟc])", replacement = "%1e%2" },
    { pattern = "(["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."ˈ](?!'))e(["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."]['ʃçjɟc])", replacement = "%1e%2" },
    { pattern = "(["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."ˈ](?!'))i(["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."]['ʃçjɟc])", replacement = "%1i%2" },
    { pattern = "l_neutral_", replacement = "l"}, {pattern = "n_neutral_", replacement = "n"}, 
}

-- Stage 4.5: Placeholder restoration rules
local placeholder_restoration_rules_stage4_5 = {
    { pattern = "&PHON_A_LONG&", replacement = "ɑː" }, { pattern = "&PHON_E_LONG&", replacement = "eː" },
    { pattern = "&PHON_I_LONG&", replacement = "iː" }, { pattern = "&PHON_O_LONG&", replacement = "oː" },
    { pattern = "&PHON_U_LONG&", replacement = "uː" }, { pattern = "&PHON_Y_LONG&", replacement = "ɨː" },
    { pattern = "&PHON_AE_LONG&", replacement = "æː" },
    { pattern = "&PHON_AU_DIPH&", replacement = "ɑu" }, { pattern = "&PHON_AI_DIPH&", replacement = "ai" },
    { pattern = "&PHON_IA_DIPH&", replacement = "iə" }, { pattern = "&PHON_UA_DIPH&", replacement = "ua" },
    { pattern = "&PHON_OU_DIPH&", replacement = "ou" }, { pattern = "&PHON_EI_DIPH&", replacement = "ei" },
    { pattern = "&PHON_OI_DIPH&", replacement = "oi" }, { pattern = "&PHON_UI_DIPH&", replacement = "ui" },
    { pattern = "&PHON_SCHWA_U_DIPH&", replacement = "əu" },
    { pattern = "&PHON_AW_SEQ&", replacement = "ɑu" }, 
    { pattern = "&PHON_SCHWA_I_DIPH&", replacement = "əi" },
}

-- Stage 4.5: Final Connacht ɑu -> əu shift
local connacht_au_to_schwa_u_shift_rule_stage4_5 = { 
  pattern = "^(ˈ?["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."]*'?)(ɑu)(["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."]*'?)$", 
  replacement = function(full_match, pre_part, au_diph, post_part)
      if is_likely_monosyllable_phonetic_revised(full_match) then
          return (pre_part or "") .. "əu" .. (post_part or "")
      end
      return full_match
  end
}
local temp_conn_au_to_final_au_rule_stage4_5 = {
    pattern = "&TEMP_CONN_AU&", replacement = "əu"
}

irishPhonetics.rules_stage4_5_contextual_allophony_on_phonetic = {}


local function apply_unstressed_vowel_reduction_procedural(phon_word)
    local string_changed_this_major_pass
    repeat 
        string_changed_this_major_pass = false; local phon_word_at_pass_start = phon_word
        for _, rule in ipairs(irishPhonetics.rules_stage4_6_unstressed_vowel_reduction_specific_finals) do
            local new_word, count = ugsub(phon_word, rule.pattern, rule.replacement)
            if count > 0 then phon_word = new_word; string_changed_this_major_pass = true end
        end
        if is_likely_monosyllable_phonetic_revised(phon_word) then goto end_reduction_loop_main end
        local num_vowel_nuclei = 0; local vowel_nuclei_positions = {}
        local temp_for_counting_reduction = ugsub(phon_word, "ˈ","")
        local current_phon_pos_for_nuc_finding = 1
        while current_phon_pos_for_nuc_finding <= ulen(temp_for_counting_reduction) do
            local s_nuc, e_nuc, nuc_match = ufind(temp_for_counting_reduction, PHONETIC_VOWEL_NUCLEUS_PATTERN, current_phon_pos_for_nuc_finding)
            if s_nuc then num_vowel_nuclei = num_vowel_nuclei + 1; table.insert(vowel_nuclei_positions, {s=s_nuc, e=e_nuc, nuc=nuc_match}); current_phon_pos_for_nuc_finding = e_nuc + 1 else break end
        end
        if num_vowel_nuclei > 1 then
            local parts = {}; local stress_char_idx = ufind(phon_word, "ˈ"); local primary_stressed_vowel_s, primary_stressed_vowel_e
            if stress_char_idx then for _, pos_data in ipairs(vowel_nuclei_positions) do if pos_data.s == stress_char_idx + 1 or (pos_data.s == stress_char_idx + 2 and usub(phon_word,stress_char_idx+1,stress_char_idx+1):match(ANY_CONSONANT_PHONETIC_PATTERN)) then primary_stressed_vowel_s = pos_data.s; primary_stressed_vowel_e = pos_data.e; break end end end
            if not primary_stressed_vowel_s and #vowel_nuclei_positions > 0 then primary_stressed_vowel_s = vowel_nuclei_positions[1].s; primary_stressed_vowel_e = vowel_nuclei_positions[1].e end
            local current_build_pos = 1
            for _, pos_data in ipairs(vowel_nuclei_positions) do
                local s_vowel, e_vowel, vowel_nuc = pos_data.s, pos_data.e, pos_data.nuc
                if s_vowel > current_build_pos then table.insert(parts, usub(phon_word, current_build_pos, s_vowel - 1)) end
                local is_this_vowel_stressed = (primary_stressed_vowel_s and s_vowel == primary_stressed_vowel_s and e_vowel == primary_stressed_vowel_e)
                if is_this_vowel_stressed or vowel_nuc:match("ː") or not vowel_nuc:match(SHORT_VOWEL_PHONETIC_PATTERN_FOR_REDUCTION_INPUT) then table.insert(parts, vowel_nuc)
                else
                    local preceding_cons_text = ""; if s_vowel > 1 then local prev_cons_end = s_vowel -1; local prev_cons_start = prev_cons_end; while prev_cons_start > 0 do local char_at_prev_start = usub(phon_word, prev_cons_start, prev_cons_start); if char_at_prev_start:match(ANY_CONSONANT_PHONETIC_PATTERN) or char_at_prev_start == "'" then prev_cons_start = prev_cons_start - 1 else break end end; preceding_cons_text = usub(phon_word, prev_cons_start + 1, prev_cons_end); preceding_cons_text = ugsub(preceding_cons_text, "ˈ","") end
                    local reduced_vowel; if preceding_cons_text:match("'") or preceding_cons_text:match("['ʃçjɟc]$") then reduced_vowel = "i" else reduced_vowel = "ə" end
                    table.insert(parts, reduced_vowel)
                end; current_build_pos = e_vowel + 1
            end
            if current_build_pos <= ulen(phon_word) then table.insert(parts, usub(phon_word, current_build_pos)) end; phon_word = table.concat(parts)
        end
        local temp_phon_word = phon_word
        temp_phon_word = ugsub(temp_phon_word, "ə("..ANY_CONSONANT_PHONETIC_PATTERN.."['ʃçjɟc])$", "i%1"); temp_phon_word = ugsub(temp_phon_word, "ə("..ANY_CONSONANT_PHONETIC_PATTERN..ANY_CONSONANT_PHONETIC_PATTERN.."?')$", "i%1") 
        temp_phon_word = ugsub(temp_phon_word, "("..ANY_CONSONANT_PHONETIC_PATTERN.."['ʃçjɟc])ə$", "%1i"); temp_phon_word = ugsub(temp_phon_word, "("..ANY_CONSONANT_PHONETIC_PATTERN..ANY_CONSONANT_PHONETIC_PATTERN.."?'?)ə$", function(consonants) if consonants:match("'$") or consonants:match("['ʃçjɟc]$") then return consonants .. "i" end return consonants .. "ə" end)
        if temp_phon_word ~= phon_word then phon_word = temp_phon_word; string_changed_this_major_pass = true end
        if phon_word == phon_word_at_pass_start then string_changed_this_major_pass = false else string_changed_this_major_pass = true end
    until not string_changed_this_major_pass
    ::end_reduction_loop_main::
    return phon_word
end

irishPhonetics.rules_stage4_6_unstressed_vowel_reduction_specific_finals = {
    { pattern = "aí$", replacement = "iː" }, { pattern = "ai$", replacement = "iː" }, { pattern = "eiə$", replacement = "iː"}, { pattern = "iːə$", replacement = "iː"}, 
}

irishPhonetics.EPENTHESIS_TARGET_CLUSTERS_BROAD = {
    ["lk"]=true, ["lg"]=true, ["lb"]=true, ["lv"]=true, ["rm"]=true, ["rx"]=true,
    ["rb"]=true, ["rg"]=true, 
}
irishPhonetics.EPENTHESIS_TARGET_CLUSTERS_SLENDER = {
    ["lk"]=true, ["lf"]=true, ["rg"]=true, ["rk"]=true, ["nm"]=true,
}

local PHONETIC_UNITS_PRIORITY_FOR_EPENTHESIS_PARSER = {
    "iə", "ua", "ai", "ei", "oi", "ui", "ɑu", "ou", "əu", "eiə", "aw", "əi",
    "ɑː", "eː", "iː", "oː", "uː", "ɨː", "æː",
    "c", "ɟ", "tʲ", "dʲ", "ʃ", "ç", "j", "ɾˠ", "lˠ", "nˠ", "mˠ", "t̪", "d̪", "n̪", "l̪",
    "k'", "g'", "t'", "d'", "p'", "b'", "m'", "n'", "l'", "r'", "s'", "f'", "v'", "L'", "N'", "R'", "M'",
    "k", "g", "t", "d", "p", "b", "m", "n", "l", "r", "s", "f", "v", "L", "N", "R", "M", "x", "ɣ", "ŋ", "h", "w",
    "a", "æ", "ɔ", "e", "ə", "i", "ɪ", "u", "ʊ", "ʌ"
}

local function parse_phonetic_string_to_units_for_epenthesis(phon_str)
    local units = {}
    local i = 1
    while i <= ulen(phon_str) do
        local stress = ""
        if usub(phon_str, i, i) == "ˈ" then
            stress = "ˈ"
            i = i + 1
        end

        local matched_unit_phon = nil
        local matched_unit_len = 0

        for _, unit_pattern_str in ipairs(PHONETIC_UNITS_PRIORITY_FOR_EPENTHESIS_PARSER) do
            if usub(phon_str, i, i + ulen(unit_pattern_str) - 1) == unit_pattern_str then
                matched_unit_phon = unit_pattern_str
                matched_unit_len = ulen(unit_pattern_str)
                break
            end
        end
        
        local quality = "unknown"
        if matched_unit_phon then
            if umatch(matched_unit_phon, "'$") or 
               umatch(matched_unit_phon, "['ʃçjɟctʲdʲ]$") or 
               umatch(matched_unit_phon, "ʲ$") then
                quality = "palatal"
            elseif umatch(matched_unit_phon, "ˠ$") or umatch(matched_unit_phon, "[̪]$") then 
                quality = "nonpalatal" 
            elseif umatch(matched_unit_phon, "^[" .. ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR .. "]$") or umatch(matched_unit_phon, "^[" .. ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR .. "]ː$") then 
                quality = "vowel" 
            elseif umatch(matched_unit_phon, "^[" .. ANY_CONSONANT_PHONETIC_RAW_CHARS_STR .. "]$") and not umatch(matched_unit_phon, "['ʲˠ̪]") then 
                local is_inherently_palatal_char = umatch(matched_unit_phon, "^[jç]$") or umatch(matched_unit_phon, "^[ʃ]$") 
                if is_inherently_palatal_char then quality = "palatal" else quality = "nonpalatal" end
            elseif matched_unit_phon == "iə" or matched_unit_phon == "ei" or matched_unit_phon == "ui" or matched_unit_phon == "oi" or matched_unit_phon == "əi" then quality = "palatal" 
            elseif matched_unit_phon == "ua" or matched_unit_phon == "ɑu" or matched_unit_phon == "ou" or matched_unit_phon == "əu" or matched_unit_phon == "aw" then quality = "nonpalatal" 
            end

            -- If still unknown after specific checks, and it's a single char from ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR, it's a vowel
            if quality == "unknown" and (umatch(matched_unit_phon, "^[" .. ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR .. "]$") or umatch(matched_unit_phon, "^[" .. ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR .. "]ː$")) then
                quality = "vowel"
            end


            table.insert(units, { phon = matched_unit_phon, stress = stress, quality = quality, original_start = i - ulen(stress), original_end = i + matched_unit_len - 1 - ulen(stress) })
            i = i + matched_unit_len
        elseif stress ~= "" then 
            table.insert(units, { phon = stress, stress = "", quality = "stress_mark", original_start = i - 1, original_end = i - 1})
        else 
            local unknown_char = usub(phon_str,i,i)
            local unknown_quality = "unknown_fallback"
            if umatch(unknown_char, "^[" .. ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR .. "]$") then
                unknown_quality = "vowel" -- Catch single vowels missed by priority list
            end
            table.insert(units, { phon = unknown_char, stress = stress, quality = unknown_quality, original_start = i - ulen(stress), original_end = i - ulen(stress) })
            i = i + 1
        end
    end
    return units
end

function irishPhonetics.apply_procedural_epenthesis(phon_word_input, original_ortho_word_for_context, current_ortho_map_for_context)
    if STAGE_DEBUG_ENABLED["EpenthesisAndStrongSonorants"] then print("  apply_procedural_epenthesis START: In=", phon_word_input) end
    
    local parsed_units = parse_phonetic_string_to_units_for_epenthesis(phon_word_input)
    if not parsed_units or #parsed_units == 0 then return phon_word_input end

    if DETAILED_DEBUG_ENABLED or STAGE_DEBUG_ENABLED["EpenthesisAndStrongSonorants"] then
        local unit_str_parts = {}
        for _, u_data in ipairs(parsed_units) do table.insert(unit_str_parts, (u_data.stress or "") .. u_data.phon .. "("..u_data.quality..")") end
        debug_print_detailed("EpenthesisAndStrongSonorants", "Parsed units for epenthesis: ", table.concat(unit_str_parts, " | "))
    end

    local is_overall_monosyllable = is_likely_monosyllable_phonetic_revised(phon_word_input)

    if not is_overall_monosyllable then 
        if STAGE_DEBUG_ENABLED["EpenthesisAndStrongSonorants"] then print("  apply_procedural_epenthesis END (not monosyllable): Out=", phon_word_input) end
        return phon_word_input 
    end

    local new_units_build = {}
    local i = 1
    local modified_by_epenthesis = false
    while i <= #parsed_units do
        if parsed_units[i].quality == "stress_mark" then 
            table.insert(new_units_build, parsed_units[i])
            i = i + 1
            if i > #parsed_units then break end 
        end

        if i + 2 <= #parsed_units then
            local unit_v = parsed_units[i]
            local unit_c1 = parsed_units[i+1]
            local unit_c2 = parsed_units[i+2]

            local is_vowel_short = unit_v.quality == "vowel" and not umatch(unit_v.phon, "ː$")
            local c1_base_phon = ugsub(unit_c1.phon, "['ˠʲ̪]", "")
            local is_c1_sonorant_type = umatch(c1_base_phon, "^[rlnm]$") 
            local c2_base_phon = ugsub(unit_c2.phon, "['ˠʲ̪]", "")
            local is_c2_obstruent_type = umatch(c2_base_phon, "^[kgptdfbxs]$") 
            
            local c1_quality = unit_c1.quality
            local c2_quality = unit_c2.quality
            
            if is_c1_sonorant_type and (c1_quality == "unknown" or (c1_quality == "nonpalatal" and unit_c1.phon == c1_base_phon)) then
                if (unit_v.quality == "palatal" or (unit_v.quality == "vowel" and umatch(unit_v.phon, "^[eiɛɪ]$"))) and c2_quality == "palatal" then
                    c1_quality = "palatal"
                    unit_c1.phon = c1_base_phon .. "'" 
                    unit_c1.quality = "palatal"       
                    debug_print_detailed("EpenthesisAndStrongSonorants", "Inferred C1 quality to palatal for: ", c1_base_phon, " -> ", unit_c1.phon, " based on V=", unit_v.phon, " and C2=", unit_c2.phon)
                end
            end


            local ep_vowel_to_insert = nil
            if is_vowel_short and is_c1_sonorant_type and is_c2_obstruent_type then
                local cluster_key_for_check = c1_base_phon .. c2_base_phon
                debug_print_detailed("EpenthesisAndStrongSonorants", "Checking V-C1-C2: ", unit_v.stress..unit_v.phon, unit_c1.phon, unit_c2.phon, " | Cluster key: ", cluster_key_for_check, " | C1 Qual: ", c1_quality, " | C2 Qual: ", c2_quality)
                if c1_quality == "palatal" and c2_quality == "palatal" then
                    if irishPhonetics.EPENTHESIS_TARGET_CLUSTERS_SLENDER[cluster_key_for_check] then ep_vowel_to_insert = "i" end
                elseif c1_quality == "nonpalatal" and c2_quality == "nonpalatal" then
                    if irishPhonetics.EPENTHESIS_TARGET_CLUSTERS_BROAD[cluster_key_for_check] then ep_vowel_to_insert = "ə" end
                elseif cluster_key_for_check == "nm" and c2_quality == "palatal" and irishPhonetics.EPENTHESIS_TARGET_CLUSTERS_SLENDER[cluster_key_for_check] then
                    if c1_quality ~= "palatal" then 
                        unit_c1.phon = c1_base_phon .. "'" 
                        unit_c1.quality = "palatal"
                        debug_print_detailed("EpenthesisAndStrongSonorants", "Heuristic: Forcing C1 (", c1_base_phon, ") to palatal for 'nm' cluster before palatal C2 (", unit_c2.phon, ") -> C1 becomes ", unit_c1.phon)
                    end
                    ep_vowel_to_insert = "i"
                end
            end

            if ep_vowel_to_insert then
                debug_print_detailed("EpenthesisAndStrongSonorants", "PROCEDURAL Epenthesis Triggered for: ", unit_v.stress..unit_v.phon, unit_c1.phon, unit_c2.phon, " -> inserting ", ep_vowel_to_insert)
                table.insert(new_units_build, unit_v)
                table.insert(new_units_build, unit_c1)
                table.insert(new_units_build, { phon = ep_vowel_to_insert, stress = "", quality = (ep_vowel_to_insert == "i" and "palatal" or "nonpalatal") })
                table.insert(new_units_build, unit_c2)
                i = i + 3 
                modified_by_epenthesis = true
            else
                table.insert(new_units_build, parsed_units[i])
                i = i + 1
            end
        else
            if i <= #parsed_units then table.insert(new_units_build, parsed_units[i]) end
            i = i + 1
        end
    end

    if modified_by_epenthesis then
        local result_phon_parts = {}
        for _, unit_data in ipairs(new_units_build) do table.insert(result_phon_parts, (unit_data.stress or "") .. unit_data.phon) end
        local final_phon_word = table.concat(result_phon_parts)
        if STAGE_DEBUG_ENABLED["EpenthesisAndStrongSonorants"] then print("  apply_procedural_epenthesis END (modified): Out=", final_phon_word) end
        return final_phon_word
    else
        if STAGE_DEBUG_ENABLED["EpenthesisAndStrongSonorants"] then print("  apply_procedural_epenthesis END (no change): Out=", phon_word_input) end
        return phon_word_input
    end
end

irishPhonetics.rules_stage5_strong_sonorants_only = {
    { pattern = "^(ˈ?)((?:"..ANY_CONSONANT_PHONETIC_PATTERN.."*'?))ɪ([NMnrlLNR]'?)(#?)$", 
      replacement = function(full_match, stress, c_part, sonorant, boundary_marker) 
        return (stress or "") .. (c_part or "") .. "iː" .. sonorant .. (boundary_marker or "") 
      end, use_current_phonetic_for_condition = true, condition_func = is_likely_monosyllable_phonetic_revised},
    { pattern = "^(ˈ?)((?:"..ANY_CONSONANT_PHONETIC_PATTERN.."*'?))ɑ([NMnrlLNR]'?)(#?)$", 
      replacement = function(full_match, stress, c_part, sonorant, boundary_marker) 
        return (stress or "") .. (c_part or "") .. "ɑː" .. sonorant .. (boundary_marker or "") 
      end, use_current_phonetic_for_condition = true, condition_func = is_likely_monosyllable_phonetic_revised},
    { pattern = "^(ˈ?)((?:"..ANY_CONSONANT_PHONETIC_PATTERN.."*'?))(ɔ)("..L_VARIANTS_PHONETIC.."'?)(#?)$", 
      replacement = function(full_match, stress, c_part, vowel, sonorant, boundary_marker) 
        return (stress or "") .. (c_part or "") .. "&TEMP_CONN_AU&" .. sonorant .. (boundary_marker or "") 
      end, use_current_phonetic_for_condition = true, condition_func = is_likely_monosyllable_phonetic_revised},
    { pattern = "^(ˈ?)((?:"..ANY_CONSONANT_PHONETIC_PATTERN.."*'?))(ɔ)("..N_VARIANTS_PHONETIC.."'?)(#?)$", 
      replacement = function(full_match, stress, c_part, vowel, sonorant, boundary_marker) 
        return (stress or "") .. (c_part or "") .. "uː" .. sonorant .. (boundary_marker or "") 
      end, use_current_phonetic_for_condition = true, condition_func = is_likely_monosyllable_phonetic_revised},
    { pattern = "^(ˈ?)((?:"..ANY_CONSONANT_PHONETIC_PATTERN.."*'?))(ɔ)("..R_VARIANTS_PHONETIC.."'?)("..ANY_CONSONANT_PHONETIC_PATTERN.."(?!'))$", 
      replacement = function(full_match, stress, c_part, vowel, sonorant, following_cons) 
        debug_print_detailed("EpenthesisAndStrongSonorants", "Strong Sonorant ɔR+BroadC rule fired for: ", full_match, " -> ", (stress or "") .. (c_part or "") .. "&TEMP_CONN_AU&" .. sonorant .. (following_cons or ""))
        return (stress or "") .. (c_part or "") .. "&TEMP_CONN_AU&" .. sonorant .. (following_cons or "") 
      end, use_current_phonetic_for_condition = true, condition_func = is_likely_monosyllable_phonetic_revised},
    { pattern = "^(ˈ?)((?:"..ANY_CONSONANT_PHONETIC_PATTERN.."*'?))(ɔ)("..R_VARIANTS_PHONETIC.."'?)(#?)$", 
      replacement = function(full_match, stress, c_part, vowel, sonorant, boundary_marker) 
        return (stress or "") .. (c_part or "") .. "oː" .. sonorant .. (boundary_marker or "") 
      end, use_current_phonetic_for_condition = true, condition_func = is_likely_monosyllable_phonetic_revised},
}

local NON_PALATAL_CONSONANT_CHARS_FOR_DIACRITICS = "tdnlsLNRM" 
local NON_PALATAL_CONSONANT_PATTERN_FOR_DIACRITICS = "[" .. NON_PALATAL_CONSONANT_CHARS_FOR_DIACRITICS .. "]"

irishPhonetics.rules_stage6_diacritics = {
    { pattern = "t(?!['ʲ])$", replacement = "t̪" }, { pattern = "t(?!['ʲ])("..NON_PALATAL_CONSONANT_PATTERN_FOR_DIACRITICS..")", replacement = "t̪%1" },
    { pattern = "d(?!['ʲ])$", replacement = "d̪" }, { pattern = "d(?!['ʲ])("..NON_PALATAL_CONSONANT_PATTERN_FOR_DIACRITICS..")", replacement = "d̪%1" },
    { pattern = "n(?!['ʲ])$", replacement = "n̪" }, { pattern = "n(?!['ʲ])("..NON_PALATAL_CONSONANT_PATTERN_FOR_DIACRITICS..")", replacement = "n̪%1" },
    { pattern = "l(?!['ʲ])$", replacement = "l̪" }, { pattern = "l(?!['ʲ])("..NON_PALATAL_CONSONANT_PATTERN_FOR_DIACRITICS..")", replacement = "l̪%1" },
    { pattern = "s(?!['ʲ])$", replacement = "s" },  { pattern = "s(?!['ʲ])("..NON_PALATAL_CONSONANT_PATTERN_FOR_DIACRITICS..")", replacement = "s%1" }, 
    { pattern = "L(?!['ʲ])$", replacement = "lˠ" }, { pattern = "L(?!['ʲ])("..NON_PALATAL_CONSONANT_PATTERN_FOR_DIACRITICS..")", replacement = "lˠ%1" },
    { pattern = "N(?!['ʲ])$", replacement = "nˠ" }, { pattern = "N(?!['ʲ])("..NON_PALATAL_CONSONANT_PATTERN_FOR_DIACRITICS..")", replacement = "nˠ%1" },
    { pattern = "R(?!['ʲ])$", replacement = "ɾˠ" }, { pattern = "R(?!['ʲ])("..NON_PALATAL_CONSONANT_PATTERN_FOR_DIACRITICS..")", replacement = "ɾˠ%1" },
    { pattern = "M(?!['ʲ])$", replacement = "mˠ" }, { pattern = "M(?!['ʲ])("..NON_PALATAL_CONSONANT_PATTERN_FOR_DIACRITICS..")", replacement = "mˠ%1" },
}

irishPhonetics.rules_stage7_final_cleanup = {
    { pattern = "("..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR..")''", replacement = "%1'" }, 
    { pattern = "s'", replacement = "ʃ" }, { pattern = "t'", replacement = "tʲ" }, { pattern = "d'", replacement = "dʲ" },
    { pattern = "k'", replacement = "c" }, { pattern = "g'", replacement = "ɟ" },
    { pattern = "l'", replacement = "lʲ" }, { pattern = "n'", replacement = "nʲ" },
    { pattern = "r'", replacement = "ɾʲ" },
    { pattern = "f'", replacement = "fʲ" }, { pattern = "v'", replacement = "vʲ" },
    { pattern = "b'", replacement = "bʲ" }, { pattern = "p'", replacement = "pʲ" },
    { pattern = "m'", replacement = "mʲ" },
    { pattern = "L'", replacement = "Lʲ" }, { pattern = "N'", replacement = "Nʲ" },
    { pattern = "R'", replacement = "Rʲ" }, { pattern = "M'", replacement = "Mʲ" },
    { pattern = "h'", replacement = "ç" }, 
    { pattern = "h$", replacement = ""}, 
    { pattern = "#", replacement = ""}, { pattern = "^%s*(.-)%s*$", replacement = "%1" }, 
    { pattern = "ˈə", replacement = "ə" },
    { pattern = " ", replacement = " "}, { pattern = "%-", replacement = ""}, { pattern = "&", replacement = ""}, 
}

-- ====== MAIN TRANSCRIBE FUNCTION ====== --
function irishPhonetics.transcribe(orthographic_word)
    local current_word_phonetic = orthographic_word
    if not current_word_phonetic or current_word_phonetic == "" then return "" end
    local original_ortho_for_context = "" 
    local ortho_map = {} 

    local function build_initial_ortho_map(word_str) local new_map = {}; for k=1, ulen(word_str) do table.insert(new_map, {phon_s=k, phon_e=k, ortho_s=k, ortho_e=k}) end; return new_map end
    local function get_original_indices_from_map(phon_s, phon_e, current_map_for_current_phon_str)
        local o_s_final, o_e_final = phon_s, phon_e; local orig_len_final = phon_e - phon_s + 1
        if not current_map_for_current_phon_str or #current_map_for_current_phon_str == 0 then return o_s_final, orig_len_final end
        local first_char_map_entry, last_char_map_entry
        for i = 1, #current_map_for_current_phon_str do local entry = current_map_for_current_phon_str[i]; if entry.phon_s <= phon_s and entry.phon_e >= phon_s then first_char_map_entry = entry; break end end
        for i = #current_map_for_current_phon_str, 1, -1 do local entry = current_map_for_current_phon_str[i]; if entry.phon_s <= phon_e and entry.phon_e >= phon_e then last_char_map_entry = entry; break end end
        if first_char_map_entry then o_s_final = first_char_map_entry.ortho_s + (phon_s - first_char_map_entry.phon_s) end
        if last_char_map_entry then o_e_final = last_char_map_entry.ortho_e - (last_char_map_entry.phon_e - phon_e) elseif first_char_map_entry then o_e_final = o_s_final + (phon_e - phon_s) end
        if o_s_final and o_e_final then orig_len_final = o_e_final - o_s_final + 1; if orig_len_final <= 0 then o_s_final = first_char_map_entry and first_char_map_entry.ortho_s or phon_s; orig_len_final = (phon_e - phon_s + 1); o_e_final = o_s_final + orig_len_final -1 end else o_s_final, o_e_final = phon_s, phon_e; orig_len_final = phon_e - phon_s + 1 end
        return o_s_final, orig_len_final
    end

    local stages = {
        {name = "PreProcess", rules = irishPhonetics.rules_stage1_preprocess, updates_map_from_current = true},
        {name = "MarkDigraphsAndVocalisationTriggers", rules = irishPhonetics.rules_stage2_mark_digraphs_and_vocalisation_triggers, updates_map_from_original_with_priority = true},
        {name = "ConsonantResolution", rules = irishPhonetics.rules_stage3_consonant_resolution, use_original_context_for_rules = true, is_procedural_stage = true, func = function(phon_word_in_stage3, o_context_str_stage3, current_ortho_map_stage3)
            if STAGE_DEBUG_ENABLED["ConsonantResolution"] then print("  ConsonantResolution START (Proc): In=", phon_word_in_stage3) end
            
            debug_print_detailed("ConsonantResolution", "Metathesis Sub-Stage START: ", phon_word_in_stage3)
            local metathesis_phon_parts = {}
            local meta_scan_offset = 1
            while meta_scan_offset <= ulen(phon_word_in_stage3) do
                local stress_marker = ""
                local current_phon_char_for_meta = usub(phon_word_in_stage3, meta_scan_offset, meta_scan_offset)
                if current_phon_char_for_meta == "ˈ" then
                    stress_marker = "ˈ"
                    meta_scan_offset = meta_scan_offset + 1
                    if meta_scan_offset > ulen(phon_word_in_stage3) then table.insert(metathesis_phon_parts, stress_marker); break end
                    current_phon_char_for_meta = usub(phon_word_in_stage3, meta_scan_offset, meta_scan_offset)
                end

                local c_phon_base = current_phon_char_for_meta
                local c_is_palatal = false
                local n_phon_base = ""
                local n_is_palatal = false
                local advance_for_c = 1 

                if usub(phon_word_in_stage3, meta_scan_offset + 1, meta_scan_offset + 1) == "'" then
                    c_is_palatal = true
                    advance_for_c = 2
                end
                
                local n_phon_start_idx_in_phon = meta_scan_offset + advance_for_c
                if n_phon_start_idx_in_phon <= ulen(phon_word_in_stage3) then
                    n_phon_base = usub(phon_word_in_stage3, n_phon_start_idx_in_phon, n_phon_start_idx_in_phon)
                    if usub(phon_word_in_stage3, n_phon_start_idx_in_phon + 1, n_phon_start_idx_in_phon + 1) == "'" then
                        n_is_palatal = true
                    end
                end
                
                debug_print_detailed("ConsonantResolution", "Metathesis Check: c_base=", c_phon_base, "c_pal=",tostring(c_is_palatal), "n_base=", n_phon_base, "n_pal=", tostring(n_is_palatal), "at offset", meta_scan_offset)
                
                local c_is_k_type = (c_phon_base == "k" or c_phon_base == "c") 
                local c_is_g_type = (c_phon_base == "g")

                if ((c_is_k_type) and n_phon_base == "n") or (c_is_g_type and n_phon_base == "n") then
                     if (meta_scan_offset == 1 and stress_marker == "") or (meta_scan_offset == (1 + ulen(stress_marker)) and stress_marker ~= "") then 
                        debug_print_detailed("ConsonantResolution", "Metathesis candidate found: ", stress_marker..c_phon_base..(c_is_palatal and "'" or "")..n_phon_base..(n_is_palatal and "'" or ""))
                        
                        local n_phon_end_idx_in_phon = n_phon_start_idx_in_phon + (n_is_palatal and 1 or 0)
                        local ortho_s_n, ortho_len_n = get_original_indices_from_map(n_phon_start_idx_in_phon, n_phon_end_idx_in_phon, current_ortho_map_stage3)
                        
                        local quality_for_r 
                        local n_ortho_actual_start_idx = ortho_s_n
                        local n_ortho_actual_end_idx = ortho_s_n + ortho_len_n -1
                        
                        quality_for_r = determine_consonant_quality_ortho(o_context_str_stage3, n_ortho_actual_start_idx, n_ortho_actual_end_idx)
                        
                        debug_print_detailed("ConsonantResolution", "Original ortho 'n' (ortho indices " .. n_ortho_actual_start_idx .. "-" .. n_ortho_actual_end_idx .. " in '" .. o_context_str_stage3 .. "') quality was: ", quality_for_r, ". Thus, quality for metathesized 'r': ", quality_for_r)
                        
                        table.insert(metathesis_phon_parts, stress_marker .. c_phon_base .. (c_is_palatal and "'" or "")) 
                        if quality_for_r == "palatal" then table.insert(metathesis_phon_parts, "r'") else table.insert(metathesis_phon_parts, "r") end
                        
                        meta_scan_offset = n_phon_end_idx_in_phon + 1
                    else
                        table.insert(metathesis_phon_parts, stress_marker .. usub(phon_word_in_stage3, meta_scan_offset, meta_scan_offset + advance_for_c -1))
                        meta_scan_offset = meta_scan_offset + advance_for_c
                    end
                else
                    table.insert(metathesis_phon_parts, stress_marker .. usub(phon_word_in_stage3, meta_scan_offset, meta_scan_offset))
                    meta_scan_offset = meta_scan_offset + 1
                end
            end
            phon_word_in_stage3 = table.concat(metathesis_phon_parts)
            debug_print_detailed("ConsonantResolution", "Metathesis Sub-Stage END: ", phon_word_in_stage3)


            local multi_char_rules_stage3 = {}
            local single_char_rule_data_stage3
            for _, rule_data_loop in ipairs(irishPhonetics.rules_stage3_consonant_resolution) do
                if rule_data_loop.pattern ~= "([bcdfghkmprst])" then
                    table.insert(multi_char_rules_stage3, rule_data_loop)
                else
                    single_char_rule_data_stage3 = rule_data_loop
                end
            end

            local pass1_phonetic_parts_stage3 = {}; local pass1_scan_offset_stage3 = 1
            while pass1_scan_offset_stage3 <= ulen(phon_word_in_stage3) do
                local best_match_s_this_iter, best_match_e_this_iter, best_rule_this_iter_idx
                local best_captures_this_iter = {}; local current_best_match_length_this_iter = -1
                
                for rule_idx_loop, rule_data_loop in ipairs(multi_char_rules_stage3) do
                    local s, e, cap1, cap2, cap3, cap4; s, e, cap1, cap2, cap3, cap4 = ufind(phon_word_in_stage3, rule_data_loop.pattern, pass1_scan_offset_stage3)
                    if s then local current_match_len_loop = e - s + 1
                        if not best_match_s_this_iter or s < best_match_s_this_iter or (s == best_match_s_this_iter and current_match_len_loop > current_best_match_length_this_iter) then
                            best_match_s_this_iter = s; best_match_e_this_iter = e; best_rule_this_iter_idx = rule_idx_loop; current_best_match_length_this_iter = current_match_len_loop; best_captures_this_iter = {cap1,cap2,cap3,cap4}
                        end
                    end
                end

                if best_rule_this_iter_idx then
                    if best_match_s_this_iter > pass1_scan_offset_stage3 then table.insert(pass1_phonetic_parts_stage3, usub(phon_word_in_stage3, pass1_scan_offset_stage3, best_match_s_this_iter - 1)) end
                    local rule = multi_char_rules_stage3[best_rule_this_iter_idx]; local full_match_segment = usub(phon_word_in_stage3, best_match_s_this_iter, best_match_e_this_iter)
                    local original_ortho_s, original_ortho_len = get_original_indices_from_map(best_match_s_this_iter, best_match_e_this_iter, current_ortho_map_stage3)
                    local original_match_info = {ortho_s = original_ortho_s, ortho_e = original_ortho_s + original_ortho_len - 1}
                    local actual_captures = {}; if best_captures_this_iter then for _,c_val in ipairs(best_captures_this_iter) do if c_val~=nil then table.insert(actual_captures, c_val) end end end
                    local replacement_text
                    if type(rule.replacement) == "string" then replacement_text = rule.replacement
                    elseif type(rule.replacement) == "function" then replacement_text = rule.replacement(full_match_segment, o_context_str_stage3, original_match_info, table.unpack(actual_captures))
                    end
                    replacement_text = replacement_text or ""; table.insert(pass1_phonetic_parts_stage3, replacement_text)
                    pass1_scan_offset_stage3 = best_match_e_this_iter + 1
                else
                    if pass1_scan_offset_stage3 <= ulen(phon_word_in_stage3) then table.insert(pass1_phonetic_parts_stage3, usub(phon_word_in_stage3, pass1_scan_offset_stage3, pass1_scan_offset_stage3)); pass1_scan_offset_stage3 = pass1_scan_offset_stage3 + 1
                    else break end
                end
            end
            phon_word_in_stage3 = table.concat(pass1_phonetic_parts_stage3)
            debug_print_detailed("ConsonantResolution", "After Pass 1 (markers): ", phon_word_in_stage3)

            if single_char_rule_data_stage3 then
                local pass2_phonetic_parts_stage3 = {}; local pass2_scan_offset_stage3 = 1
                while pass2_scan_offset_stage3 <= ulen(phon_word_in_stage3) do
                    local char_to_check = usub(phon_word_in_stage3, pass2_scan_offset_stage3, pass2_scan_offset_stage3)
                    if char_to_check:match("^[bcdfghkmprst]$") then 
                        local original_ortho_s, original_ortho_len = get_original_indices_from_map(pass2_scan_offset_stage3, pass2_scan_offset_stage3, current_ortho_map_stage3)
                        local original_match_info = {ortho_s = original_ortho_s, ortho_e = original_ortho_s + original_ortho_len -1}
                        debug_print_detailed("ConsonantResolution", "Pass 2: Checking '", char_to_check, "' at phon_idx ", pass2_scan_offset_stage3, " -> ortho_s:", original_ortho_s, "ortho_e:", original_match_info.ortho_e)
                        local replacement_text = single_char_rule_data_stage3.replacement(char_to_check, o_context_str_stage3, original_match_info)
                        replacement_text = replacement_text or char_to_check
                        table.insert(pass2_phonetic_parts_stage3, replacement_text)
                        debug_print_detailed("ConsonantResolution", "Pass 2: Replaced '", char_to_check, "' with '", replacement_text, "'")
                    else
                        table.insert(pass2_phonetic_parts_stage3, char_to_check)
                    end
                    pass2_scan_offset_stage3 = pass2_scan_offset_stage3 + 1
                end
                phon_word_in_stage3 = table.concat(pass2_phonetic_parts_stage3)
            end
            debug_print_detailed("ConsonantResolution", "After Pass 2 (single chars): ", phon_word_in_stage3)
            if STAGE_DEBUG_ENABLED["ConsonantResolution"] then print("  ConsonantResolution END (Proc): Out=", phon_word_in_stage3) end
            return phon_word_in_stage3
        end},
        {name = "Stage4_0_SpecificOrthoToTempMarker", rules = irishPhonetics.rules_stage4_0_specific_ortho_to_temp_marker, use_original_context_for_rules = true}, 
        {name = "Stage4_0_1_Resolve_CH_Marker", rules = irishPhonetics.rules_stage4_0_1_resolve_ch_marker, use_original_context_for_rules = true},
        {name = "Stage4_1_VocmarkToTempMarker", rules = irishPhonetics.rules_stage4_1_vocmark_to_temp_marker, use_original_context_for_rules = false},
        {name = "Stage4_2_LongVowelsOrthoToTempMarker", rules = irishPhonetics.rules_stage4_2_long_vowels_ortho_to_temp_marker, use_original_context_for_rules = false},
        {name = "Stage4_3_DiphthongsOrthoToTempMarker", rules = irishPhonetics.rules_stage4_3_diphthongs_ortho_to_temp_marker, use_original_context_for_rules = false},
        {name = "Stage4_4_ResolveTempVowelMarkers", rules = irishPhonetics.rules_stage4_4_resolve_temp_vowel_markers, use_original_context_for_rules = false, has_internal_loop = true},
        {name = "Stage4_5_ContextualAllophonyOnPhonetic", rules = irishPhonetics.rules_stage4_5_contextual_allophony_on_phonetic, use_original_context_for_rules = false, is_procedural_stage = true, func = function(phon_word) 
            if STAGE_DEBUG_ENABLED["Stage4_5_ContextualAllophonyOnPhonetic"] then print("  Stage4_5_ContextualAllophonyOnPhonetic START: In=", phon_word) end
            
            debug_print_detailed("Stage4_5_ContextualAllophonyOnPhonetic", "Applying placeholder creation rules (ONCE)...")
            for _, rule in ipairs(placeholder_creation_rules_stage4_5) do local old_str = phon_word; phon_word = ugsub(phon_word, rule.pattern, rule.replacement); if old_str ~= phon_word then debug_print_detailed("Stage4_5_ContextualAllophonyOnPhonetic", "Placeholder created: '", rule.pattern, "' -> '", rule.replacement, "'. Result: '", phon_word, "'") end end
            debug_print_detailed("Stage4_5_ContextualAllophonyOnPhonetic", "After placeholder creation: ", phon_word)

            debug_print_detailed("Stage4_5_ContextualAllophonyOnPhonetic", "Applying core allophony rules (iteratively)...")
            local pass_counter_core_loop = 0; local core_loop_changed_string
            repeat
                core_loop_changed_string = false; pass_counter_core_loop = pass_counter_core_loop + 1
                local phonetic_before_this_core_pass = phon_word
                for rule_idx_loop, rule_data_loop in ipairs(core_allophony_rules_for_stage4_5) do 
                    if type(rule_data_loop.pattern) == "string" then
                        local new_phon_string, num_replacements
                        if type(rule_data_loop.replacement) == "function" then
                             new_phon_string, num_replacements = ugsub(phon_word, rule_data_loop.pattern, function(...) local res = rule_data_loop.replacement(...); return res or ufind(phon_word, rule_data_loop.pattern, (...)) end) 
                        else
                            new_phon_string, num_replacements = ugsub(phon_word, rule_data_loop.pattern, rule_data_loop.replacement)
                        end
                        if new_phon_string ~= phon_word then debug_print_detailed("Stage4_5_ContextualAllophonyOnPhonetic", "Core Iter.gsub: Rule '", rule_data_loop.pattern, "' APPLIED to '", phon_word, "' -> '", new_phon_string, "' (", num_replacements, "x)"); phon_word = new_phon_string; core_loop_changed_string = true end
                    end
                end
                if core_loop_changed_string then debug_print_detailed("Stage4_5_ContextualAllophonyOnPhonetic", "Core Iter.gsub Pass "..pass_counter_core_loop.." ended. String changed from '", phonetic_before_this_core_pass, "' to '", phon_word, "'")
                else debug_print_detailed("Stage4_5_ContextualAllophonyOnPhonetic", "Core Iter.gsub Pass "..pass_counter_core_loop.." ended. No changes in this pass. String remains: '", phon_word, "'") end
            until not core_loop_changed_string
            debug_print_detailed("Stage4_5_ContextualAllophonyOnPhonetic", "After core allophony rules: ", phon_word)

            debug_print_detailed("Stage4_5_ContextualAllophonyOnPhonetic", "Applying placeholder restoration rules (ONCE)...")
            for _, rule in ipairs(placeholder_restoration_rules_stage4_5) do local old_str = phon_word; phon_word = ugsub(phon_word, rule.pattern, rule.replacement); if old_str ~= phon_word then debug_print_detailed("Stage4_5_ContextualAllophonyOnPhonetic", "Placeholder restored: '", rule.pattern, "' -> '", rule.replacement, "'. Result: '", phon_word, "'") end end
            debug_print_detailed("Stage4_5_ContextualAllophonyOnPhonetic", "After placeholder restoration: ", phon_word)
            
            debug_print_detailed("Stage4_5_ContextualAllophonyOnPhonetic", "Applying Connacht ɑu -> əu shift (ONCE)...")
            local old_str_au_shift = phon_word
            phon_word = ugsub(phon_word, connacht_au_to_schwa_u_shift_rule_stage4_5.pattern, connacht_au_to_schwa_u_shift_rule_stage4_5.replacement)
            if old_str_au_shift ~= phon_word then debug_print_detailed("Stage4_5_ContextualAllophonyOnPhonetic", "Connacht ɑu->əu shift: '", connacht_au_to_schwa_u_shift_rule_stage4_5.pattern, "'. Result: '", phon_word, "'") end
            debug_print_detailed("Stage4_5_ContextualAllophonyOnPhonetic", "After Connacht ɑu->əu shift: ", phon_word)

            debug_print_detailed("Stage4_5_ContextualAllophonyOnPhonetic", "Applying &TEMP_CONN_AU& -> əu shift (ONCE)...")
            local old_str_temp_au_shift = phon_word
            phon_word = ugsub(phon_word, temp_conn_au_to_final_au_rule_stage4_5.pattern, temp_conn_au_to_final_au_rule_stage4_5.replacement)
            if old_str_temp_au_shift ~= phon_word then debug_print_detailed("Stage4_5_ContextualAllophonyOnPhonetic", "&TEMP_CONN_AU&->əu shift: '", temp_conn_au_to_final_au_rule_stage4_5.pattern, "'. Result: '", phon_word, "'") end
            debug_print_detailed("Stage4_5_ContextualAllophonyOnPhonetic", "After &TEMP_CONN_AU&->əu shift: ", phon_word)


            if STAGE_DEBUG_ENABLED["Stage4_5_ContextualAllophonyOnPhonetic"] then print("  Stage4_5_ContextualAllophonyOnPhonetic END: Out=", phon_word) end
            return phon_word
        end}, 
        {name = "Stage4_6_UnstressedVowelReduction_Procedural", is_procedural_stage = true, func = apply_unstressed_vowel_reduction_procedural},
        {name = "EpenthesisAndStrongSonorants", is_procedural_stage = true, func = function(phon_word_in_stage5, o_context_str_stage5, current_ortho_map_stage5)
            if STAGE_DEBUG_ENABLED["EpenthesisAndStrongSonorants"] then print("  EpenthesisAndStrongSonorants START (Proc): In=", phon_word_in_stage5) end
            
            phon_word_in_stage5 = irishPhonetics.apply_procedural_epenthesis(phon_word_in_stage5, o_context_str_stage5, current_ortho_map_stage5)
            debug_print_detailed("EpenthesisAndStrongSonorants", "After procedural epenthesis: ", phon_word_in_stage5)

            local rules_to_apply_strong_son = irishPhonetics.rules_stage5_strong_sonorants_only
            local iteration_changed_string_strong_son = false 
            local new_phonetic_string_parts_strong_son = {}; local scan_offset_strong_son = 1  
            while scan_offset_strong_son <= ulen(phon_word_in_stage5) do
                local best_match_s_this_iter_ss, best_match_e_this_iter_ss, best_rule_this_iter_idx_ss; local best_captures_this_iter_ss = {}; local current_best_match_length_this_iter_ss = -1 
                for rule_idx_loop_ss, rule_data_loop_ss in ipairs(rules_to_apply_strong_son) do
                    if type(rule_data_loop_ss.pattern) == "string" then
                        local s_ss, e_ss, cap1_ss, cap2_ss, cap3_ss, cap4_ss, cap5_ss; s_ss, e_ss, cap1_ss, cap2_ss, cap3_ss, cap4_ss, cap5_ss = ufind(phon_word_in_stage5, rule_data_loop_ss.pattern, scan_offset_strong_son)
                        if s_ss then local current_match_len_loop_ss = e_ss - s_ss + 1
                            if not best_match_s_this_iter_ss or s_ss < best_match_s_this_iter_ss or (s_ss == best_match_s_this_iter_ss and current_match_len_loop_ss > current_best_match_length_this_iter_ss) then best_match_s_this_iter_ss = s_ss; best_match_e_this_iter_ss = e_ss; best_rule_this_iter_idx_ss = rule_idx_loop_ss; current_best_match_length_this_iter_ss = current_match_len_loop_ss; best_captures_this_iter_ss = {cap1_ss,cap2_ss,cap3_ss,cap4_ss,cap5_ss} end
                        end
                    end
                end
                if best_rule_this_iter_idx_ss then 
                    if best_match_s_this_iter_ss > scan_offset_strong_son then table.insert(new_phonetic_string_parts_strong_son, usub(phon_word_in_stage5, scan_offset_strong_son, best_match_s_this_iter_ss - 1)) end
                    local rule_ss = rules_to_apply_strong_son[best_rule_this_iter_idx_ss]; local full_match_segment_ss = usub(phon_word_in_stage5, best_match_s_this_iter_ss, best_match_e_this_iter_ss)
                    local actual_captures_for_func_current_rule_ss = {}; if best_captures_this_iter_ss then for k_cap_ss, v_cap_ss in ipairs(best_captures_this_iter_ss) do if v_cap_ss ~= nil then table.insert(actual_captures_for_func_current_rule_ss, v_cap_ss) end end end
                    local apply_this_rule_ss = true 
                    if rule_ss.use_current_phonetic_for_condition and rule_ss.condition_func then local condition_is_met_ss = rule_ss.condition_func(full_match_segment_ss); if not condition_is_met_ss then apply_this_rule_ss = false end end
                    local replacement_text_ss
                    if apply_this_rule_ss then
                        if type(rule_ss.replacement) == "string" then replacement_text_ss = rule_ss.replacement; if replacement_text_ss:match("%%[%d]") then local temp_repl_ss = replacement_text_ss; for i_cap_ss = #actual_captures_for_func_current_rule_ss, 1, -1 do temp_repl_ss = ugsub(temp_repl_ss, "%%"..i_cap_ss, actual_captures_for_func_current_rule_ss[i_cap_ss] or "") end; replacement_text_ss = temp_repl_ss end
                        elseif type(rule_ss.replacement) == "function" then local call_params_for_rule_func_ss = {full_match_segment_ss}; for _, cap_val_ss in ipairs(actual_captures_for_func_current_rule_ss) do table.insert(call_params_for_rule_func_ss, cap_val_ss) end; replacement_text_ss = rule_ss.replacement(table.unpack(call_params_for_rule_func_ss)) end
                        replacement_text_ss = replacement_text_ss or ""; if full_match_segment_ss ~= replacement_text_ss then iteration_changed_string_strong_son = true end
                    else replacement_text_ss = full_match_segment_ss end
                    table.insert(new_phonetic_string_parts_strong_son, replacement_text_ss); scan_offset_strong_son = best_match_e_this_iter_ss + 1
                else if scan_offset_strong_son <= ulen(phon_word_in_stage5) then table.insert(new_phonetic_string_parts_strong_son, usub(phon_word_in_stage5, scan_offset_strong_son)) end; break end
            end
            phon_word_in_stage5 = table.concat(new_phonetic_string_parts_strong_son)
            debug_print_detailed("EpenthesisAndStrongSonorants", "After strong sonorant rules: ", phon_word_in_stage5)

            if STAGE_DEBUG_ENABLED["EpenthesisAndStrongSonorants"] then print("  EpenthesisAndStrongSonorants END (Proc): Out=", phon_word_in_stage5) end
            return phon_word_in_stage5
        end},
        {name = "Diacritics", rules = irishPhonetics.rules_stage6_diacritics, use_original_context_for_rules = false},
        {name = "FinalCleanup", rules = irishPhonetics.rules_stage7_final_cleanup, use_original_context_for_rules = false},
    }

    print(string.format("\n--- Transcribing: [%s] ---", ulower(orthographic_word)))

    for i, stage_data in ipairs(stages) do
        local rules_to_apply = stage_data.rules
        if stage_data.is_procedural_stage and type(stage_data.func) == "function" then
            if STAGE_DEBUG_ENABLED[stage_data.name] then print("  " .. stage_data.name .. " START (Proc): In=", current_word_phonetic) end
            if stage_data.name == "ConsonantResolution" or stage_data.name == "EpenthesisAndStrongSonorants" then
                current_word_phonetic = stage_data.func(current_word_phonetic, original_ortho_for_context, ortho_map)
            else
                current_word_phonetic = stage_data.func(current_word_phonetic)
            end
        elseif not rules_to_apply and not stage_data.is_procedural_stage then goto continue_stage end

        if stage_data.name == "PreProcess" then
            for rule_idx, rule in ipairs(rules_to_apply) do
                if type(rule.replacement) == "string" then current_word_phonetic = ugsub(current_word_phonetic, rule.pattern, rule.replacement)
                elseif type(rule.replacement) == "function" then current_word_phonetic = ugsub(current_word_phonetic, rule.pattern, function(...) return rule.replacement(...) or "" end) end
            end
            original_ortho_for_context = current_word_phonetic; ortho_map = build_initial_ortho_map(current_word_phonetic) 
        elseif stage_data.updates_map_from_original_with_priority then 
            local temp_phonetic_string_build = {}; local temp_new_map = {}; local original_cursor = 1; local current_phonetic_len_accumulator = 0
            while original_cursor <= ulen(original_ortho_for_context) do
                local matched_this_pass_at_cursor = false
                for rule_idx, rule in ipairs(rules_to_apply) do
                    local s_match_ortho, e_match_ortho, capture1, capture2, capture3, capture4
                    if rule.pattern:match("%(") then s_match_ortho, e_match_ortho, capture1, capture2, capture3, capture4 = ufind(original_ortho_for_context, rule.pattern, original_cursor) else s_match_ortho, e_match_ortho = ufind(original_ortho_for_context, rule.pattern, original_cursor) end
                    if s_match_ortho and s_match_ortho == original_cursor then
                        local current_ortho_match_len; local full_match_ortho_segment_for_len_func = usub(original_ortho_for_context, s_match_ortho, e_match_ortho)
                        if rule.ortho_len_func then current_ortho_match_len = rule.ortho_len_func(full_match_ortho_segment_for_len_func, capture1, capture2, capture3, capture4) elseif rule.ortho_len then current_ortho_match_len = rule.ortho_len else current_ortho_match_len = e_match_ortho - s_match_ortho + 1 end
                        if rule.ortho_len and current_ortho_match_len > (e_match_ortho - s_match_ortho + 1) then goto continue_rule_loop_stage2 end
                        local full_match_ortho_segment_for_replacement = usub(original_ortho_for_context, s_match_ortho, s_match_ortho + current_ortho_match_len -1); local replacement_text
                        if type(rule.replacement) == "string" then replacement_text = rule.replacement elseif type(rule.replacement) == "function" then replacement_text = rule.replacement(full_match_ortho_segment_for_replacement, capture1, capture2, capture3, capture4) end
                        replacement_text = replacement_text or ""; table.insert(temp_phonetic_string_build, replacement_text)
                        table.insert(temp_new_map, {phon_s = current_phonetic_len_accumulator + 1, phon_e = current_phonetic_len_accumulator + ulen(replacement_text), ortho_s = original_cursor, ortho_e = original_cursor + current_ortho_match_len - 1})
                        current_phonetic_len_accumulator = current_phonetic_len_accumulator + ulen(replacement_text); original_cursor = original_cursor + current_ortho_match_len; matched_this_pass_at_cursor = true; goto restart_rule_scan_for_new_cursor_stage2 
                    end; ::continue_rule_loop_stage2::
                end; ::restart_rule_scan_for_new_cursor_stage2::
                if not matched_this_pass_at_cursor then if original_cursor <= ulen(original_ortho_for_context) then local char = usub(original_ortho_for_context, original_cursor, original_cursor); table.insert(temp_phonetic_string_build, char); table.insert(temp_new_map, {phon_s = current_phonetic_len_accumulator + 1, phon_e = current_phonetic_len_accumulator + 1, ortho_s = original_cursor, ortho_e = original_cursor}); current_phonetic_len_accumulator = current_phonetic_len_accumulator + 1; original_cursor = original_cursor + 1 else break end end
            end
            current_word_phonetic = table.concat(temp_phonetic_string_build); ortho_map = temp_new_map
    elseif not stage_data.is_procedural_stage then 
        if STAGE_DEBUG_ENABLED[stage_data.name] then print("  " .. stage_data.name .. " START: In=", current_word_phonetic) end
        
        if stage_data.has_internal_loop then 
            local pass_counter_this_stage = 0; local iteration_changed_string_this_stage
            repeat
                iteration_changed_string_this_stage = false; pass_counter_this_stage = pass_counter_this_stage + 1
                local phonetic_before_this_gsub_pass = current_word_phonetic
                for rule_idx_loop, rule_data_loop in ipairs(rules_to_apply) do
                    if type(rule_data_loop.pattern) == "string" then
                        local new_phon_string, num_replacements = ugsub(current_word_phonetic, rule_data_loop.pattern, rule_data_loop.replacement)
                        if new_phon_string ~= current_word_phonetic then debug_print_detailed(stage_data.name, "Iter.gsub: Rule '", rule_data_loop.pattern, "' APPLIED to '", current_word_phonetic, "' -> '", new_phon_string, "' (", num_replacements, "x)"); current_word_phonetic = new_phon_string; iteration_changed_string_this_stage = true end
                    end
                end
                if iteration_changed_string_this_stage then debug_print_detailed(stage_data.name, "Iter.gsub Pass "..pass_counter_this_stage.." ended. String changed from '", phonetic_before_this_gsub_pass, "' to '", current_word_phonetic, "'")
                else debug_print_detailed(stage_data.name, "Iter.gsub Pass "..pass_counter_this_stage.." ended. No changes in this pass. String remains: '", current_word_phonetic, "'") end
            until not iteration_changed_string_this_stage
        else 
            local iteration_changed_string_this_stage_non_iter = false 
            local new_phonetic_string_parts = {}; local scan_offset = 1  
            while scan_offset <= ulen(current_word_phonetic) do
                local best_match_s_this_iter, best_match_e_this_iter, best_rule_this_iter_idx; local best_captures_this_iter = {}; local current_best_match_length_this_iter = -1 
                for rule_idx_loop, rule_data_loop in ipairs(rules_to_apply) do
                    if type(rule_data_loop.pattern) == "string" then
                        local s, e, cap1, cap2, cap3, cap4, cap5, cap6, cap7, cap8, cap9, cap10; s, e, cap1, cap2, cap3, cap4, cap5, cap6, cap7, cap8, cap9, cap10 = ufind(current_word_phonetic, rule_data_loop.pattern, scan_offset)
                        if s then local current_match_len_loop = e - s + 1
                            if not best_match_s_this_iter or s < best_match_s_this_iter or (s == best_match_s_this_iter and current_match_len_loop > current_best_match_length_this_iter) then best_match_s_this_iter = s; best_match_e_this_iter = e; best_rule_this_iter_idx = rule_idx_loop; current_best_match_length_this_iter = current_match_len_loop; best_captures_this_iter = {cap1,cap2,cap3,cap4,cap5,cap6,cap7,cap8,cap9,cap10} end
                        end
                    end
                end
                if best_rule_this_iter_idx then 
                    if best_match_s_this_iter > scan_offset then table.insert(new_phonetic_string_parts, usub(current_word_phonetic, scan_offset, best_match_s_this_iter - 1)) end
                    local rule = rules_to_apply[best_rule_this_iter_idx]; local full_match_segment = usub(current_word_phonetic, best_match_s_this_iter, best_match_e_this_iter)
                    local original_ortho_s_for_rule, original_ortho_len_for_rule = get_original_indices_from_map(best_match_s_this_iter, best_match_e_this_iter, ortho_map)
                    local original_match_info_for_func = {ortho_s = original_ortho_s_for_rule, ortho_e = original_ortho_s_for_rule + original_ortho_len_for_rule - 1}
                    local actual_captures_for_func_current_rule = {}; if best_captures_this_iter then for k_cap, v_cap in ipairs(best_captures_this_iter) do if v_cap ~= nil then table.insert(actual_captures_for_func_current_rule, v_cap) end end end
                    local apply_this_rule = true 
                    if rule.use_current_phonetic_for_condition and rule.condition_func then local current_word_phonetic_before_pass_for_cond = current_word_phonetic; local condition_is_met = rule.condition_func(current_word_phonetic_before_pass_for_cond); if not condition_is_met then apply_this_rule = false end end
                    local replacement_text
                    if apply_this_rule then
                        if type(rule.replacement) == "string" then replacement_text = rule.replacement; if replacement_text:match("%%[%d]") then local temp_repl = replacement_text; for i_cap = #actual_captures_for_func_current_rule, 1, -1 do temp_repl = ugsub(temp_repl, "%%"..i_cap, actual_captures_for_func_current_rule[i_cap] or "") end; replacement_text = temp_repl end
                        elseif type(rule.replacement) == "function" then local call_params_for_rule_func = {full_match_segment}; for _, cap_val in ipairs(actual_captures_for_func_current_rule) do table.insert(call_params_for_rule_func, cap_val) end; if stage_data.use_original_context_for_rules then table.insert(call_params_for_rule_func, original_ortho_for_context); table.insert(call_params_for_rule_func, original_match_info_for_func) end; replacement_text = rule.replacement(table.unpack(call_params_for_rule_func)) end
                        replacement_text = replacement_text or ""; if full_match_segment ~= replacement_text then iteration_changed_string_this_stage_non_iter = true end
                    else replacement_text = full_match_segment end
                    table.insert(new_phonetic_string_parts, replacement_text); scan_offset = best_match_e_this_iter + 1
                else if scan_offset <= ulen(current_word_phonetic) then table.insert(new_phonetic_string_parts, usub(current_word_phonetic, scan_offset)) end; break end
            end
            current_word_phonetic = table.concat(new_phonetic_string_parts)
        end
        if STAGE_DEBUG_ENABLED[stage_data.name] then print("  " .. stage_data.name .. " END: Out=", current_word_phonetic) end
    end
    if stage_data.name ~= "PreProcess" and STAGE_DEBUG_ENABLED[stage_data.name] then print(string.format("Af. %s: [%s]", stage_data.name, current_word_phonetic)) end
    ::continue_stage::
end
return current_word_phonetic
end

-- Example Usage:
local RUN_FULL_TEST_SET = false 

local words_to_test_focused_37AM = {
    "cnámh", "cnead", "cnoc", "gnaoi", "gnó", 
    "seilf", "dorcha", "olc", "oilc", "dearc", "feirc",
    "balbh", "garbh", "gorm", "bolg", "ainm"
}


local words_to_test_full_37AB = { 
"fhéach", "fhág", "fhíor", "fhostaigh", "fhuair", "scríobh", "teach", "deartháir", "cat", "bord", "ceann", "poll", "balla", "leabhar", "samhradh", "beannacht", "fonn",
"leagan", "teanga", "seacht", "aghaidh", "suidhe", "nimhe", "bóthar", "oíche", "fear", "glaic", "muc", "fliuch", "fada", "beag", "séimhiú", "úrú", "bacach", 
"isteach", "baile", "duine", "Gaeltacht", "Conamara", "Gaeilge", "aoibhinn", "buí", "caol", "leathan", "drochbhean", "an-mhaith", "fuinneog", "oiliúint", 
"staighre", "fios", "athbhliain", "comhrá", "mícheart", "oícheanta", "codladh", "luigh", "fiche", "duchaise", "saibhir", "deacair", "sláinte", "ceart", "lae", 
"laoch", "aer", "ceo", "ceol", "coir", "coill", "faoi", "gaoth", "bádaí", "capaillí", "foclaí", "brógaí", "dearmad", "seomraí", "doras", "amhrán", "Banríon", 
"dearcadh", "dearfa", "mí-ádh", "droch-obair", "seanbhean", "bhean", "fíoruisce", "athchúrsáil", "an-fear", "an-oíche", "beart", "bean", "geal", "eagla", "muid", "duit", 
"fuil", "goil", "buil", "cuir", "druid", "luibh", "ceist", "ocht", "páiste", "sparán", "scéal", "bláth", "cnoc", "gnó", "dlí", "mná", "trá", "uisce", "obair", 
"imir", "eolas", "athair", "máthair", "deirfiúr", "imirt", "oibre", "ceacht", "ceistneoir", "ceistigh", "arm", "borb", "bolg", "garbh", "gorm", "gairm", "balbh", 
"seilf", "dearg", "fearg", "colm", "ainm", "scrúdaigh", "cónaigh", "beannaigh",
"teann", "trom", "am", "cam", "gall", "tall", "dún", "dubh", "móin"
}

local words_to_test_final
if RUN_FULL_TEST_SET then
words_to_test_final = words_to_test_full_37AB
else
words_to_test_final = words_to_test_focused_37AM
end

print("\n--- Running Test Set for Iteration 37AU (" .. (#words_to_test_final == #words_to_test_full_37AB and "Full" or "Focused") .. ") ---") 
for _, word in ipairs(words_to_test_final) do 
local original = word
local transcribed = irishPhonetics.transcribe(original)
print(string.format("%-15s -> [%s]", original, transcribed))
end

if debug_file then debug_file:close() end
return irishPhonetics


--- Running Test Set for Iteration 37AU (Focused) ---

--- Transcribing: [cnámh] ---
Af. MarkDigraphsAndVocalisationTriggers: [cn&A_ACUTE_LONG_VOC_M_FINAL&]
  ConsonantResolution START (Proc): In=	cn&A_ACUTE_LONG_VOC_M_FINAL&
  ConsonantResolution START (Proc): In=	cn&A_ACUTE_LONG_VOC_M_FINAL&
    DBG (Consonan): Metathesis Sub-Stage START: 	cn&A_ACUTE_LONG_VOC_M_FINAL&
    DBG (Consonan): Metathesis Check: c_base=	c	c_pal=	false	n_base=	n	n_pal=	false	at offset	1
    DBG (Consonan): Metathesis candidate found: 	cn
    DBG (DetQual): Word:	cnámh	Cons seq:	n	s:	2	e:	2
    DBG (DetQual): Next relevant vowel char for quality:	á	Next quality implication:	broad
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	n	': 	nonpalatal
    DBG (Consonan): Original ortho 'n' (ortho indices 2-2 in 'cnámh') quality was: 	nonpalatal	. Thus, quality for metathesized 'r': 	nonpalatal
    DBG (Consonan): Metathesis Check: c_base=	&	c_pal=	false	n_base=	A	n_pal=	false	at offset	3
    DBG (Consonan): Metathesis Check: c_base=	A	c_pal=	false	n_base=	_	n_pal=	false	at offset	4
    DBG (Consonan): Metathesis Check: c_base=	_	c_pal=	false	n_base=	A	n_pal=	false	at offset	5
    DBG (Consonan): Metathesis Check: c_base=	A	c_pal=	false	n_base=	C	n_pal=	false	at offset	6
    DBG (Consonan): Metathesis Check: c_base=	C	c_pal=	false	n_base=	U	n_pal=	false	at offset	7
    DBG (Consonan): Metathesis Check: c_base=	U	c_pal=	false	n_base=	T	n_pal=	false	at offset	8
    DBG (Consonan): Metathesis Check: c_base=	T	c_pal=	false	n_base=	E	n_pal=	false	at offset	9
    DBG (Consonan): Metathesis Check: c_base=	E	c_pal=	false	n_base=	_	n_pal=	false	at offset	10
    DBG (Consonan): Metathesis Check: c_base=	_	c_pal=	false	n_base=	L	n_pal=	false	at offset	11
    DBG (Consonan): Metathesis Check: c_base=	L	c_pal=	false	n_base=	O	n_pal=	false	at offset	12
    DBG (Consonan): Metathesis Check: c_base=	O	c_pal=	false	n_base=	N	n_pal=	false	at offset	13
    DBG (Consonan): Metathesis Check: c_base=	N	c_pal=	false	n_base=	G	n_pal=	false	at offset	14
    DBG (Consonan): Metathesis Check: c_base=	G	c_pal=	false	n_base=	_	n_pal=	false	at offset	15
    DBG (Consonan): Metathesis Check: c_base=	_	c_pal=	false	n_base=	V	n_pal=	false	at offset	16
    DBG (Consonan): Metathesis Check: c_base=	V	c_pal=	false	n_base=	O	n_pal=	false	at offset	17
    DBG (Consonan): Metathesis Check: c_base=	O	c_pal=	false	n_base=	C	n_pal=	false	at offset	18
    DBG (Consonan): Metathesis Check: c_base=	C	c_pal=	false	n_base=	_	n_pal=	false	at offset	19
    DBG (Consonan): Metathesis Check: c_base=	_	c_pal=	false	n_base=	M	n_pal=	false	at offset	20
    DBG (Consonan): Metathesis Check: c_base=	M	c_pal=	false	n_base=	_	n_pal=	false	at offset	21
    DBG (Consonan): Metathesis Check: c_base=	_	c_pal=	false	n_base=	F	n_pal=	false	at offset	22
    DBG (Consonan): Metathesis Check: c_base=	F	c_pal=	false	n_base=	I	n_pal=	false	at offset	23
    DBG (Consonan): Metathesis Check: c_base=	I	c_pal=	false	n_base=	N	n_pal=	false	at offset	24
    DBG (Consonan): Metathesis Check: c_base=	N	c_pal=	false	n_base=	A	n_pal=	false	at offset	25
    DBG (Consonan): Metathesis Check: c_base=	A	c_pal=	false	n_base=	L	n_pal=	false	at offset	26
    DBG (Consonan): Metathesis Check: c_base=	L	c_pal=	false	n_base=	&	n_pal=	false	at offset	27
    DBG (Consonan): Metathesis Check: c_base=	&	c_pal=	false	n_base=		n_pal=	false	at offset	28
    DBG (Consonan): Metathesis Sub-Stage END: 	cr&A_ACUTE_LONG_VOC_M_FINAL&
    DBG (Consonan): After Pass 1 (markers): 	cr&A_ACUTE_LONG_VOC_M_FINAL&
    DBG (Consonan): Pass 2: Checking '	c	' at phon_idx 	1	 -> ortho_s:	1	ortho_e:	1
    DBG (Consonan): Single cons rule: c_capture=	c	o_s=	1	o_e=	1
    DBG (DetQual): Word:	cnámh	Cons seq:	c	s:	1	e:	1
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	c	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	c	' with '	k	'
    DBG (Consonan): Pass 2: Checking '	r	' at phon_idx 	2	 -> ortho_s:	2	ortho_e:	2
    DBG (Consonan): Single cons rule: c_capture=	r	o_s=	2	o_e=	2
    DBG (DetQual): Word:	cnámh	Cons seq:	n	s:	2	e:	2
    DBG (DetQual): Next relevant vowel char for quality:	á	Next quality implication:	broad
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	n	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	r	' with '	r	'
    DBG (Consonan): After Pass 2 (single chars): 	kr&A_ACUTE_LONG_VOC_M_FINAL&
  ConsonantResolution END (Proc): Out=	kr&A_ACUTE_LONG_VOC_M_FINAL&
Af. ConsonantResolution: [kr&A_ACUTE_LONG_VOC_M_FINAL&]
  Stage4_0_SpecificOrthoToTempMarker START: In=	kr&A_ACUTE_LONG_VOC_M_FINAL&
  Stage4_0_SpecificOrthoToTempMarker END: Out=	kr&A_ACUTE_LONG_VOC_M_FINAL&
Af. Stage4_0_SpecificOrthoToTempMarker: [kr&A_ACUTE_LONG_VOC_M_FINAL&]
  Stage4_0_1_Resolve_CH_Marker START: In=	kr&A_ACUTE_LONG_VOC_M_FINAL&
  Stage4_0_1_Resolve_CH_Marker END: Out=	kr&A_ACUTE_LONG_VOC_M_FINAL&
Af. Stage4_0_1_Resolve_CH_Marker: [kr&A_ACUTE_LONG_VOC_M_FINAL&]
  Stage4_2_LongVowelsOrthoToTempMarker START: In=	kr&A_ACUTE_LONG_VOC_M_FINAL&
  Stage4_2_LongVowelsOrthoToTempMarker END: Out=	kr&A_ACUTE_LONG_VOC_M_FINAL&
Af. Stage4_2_LongVowelsOrthoToTempMarker: [kr&A_ACUTE_LONG_VOC_M_FINAL&]
  Stage4_3_DiphthongsOrthoToTempMarker START: In=	kr&A_ACUTE_LONG_VOC_M_FINAL&
  Stage4_3_DiphthongsOrthoToTempMarker END: Out=	kr&A_ACUTE_LONG_VOC_M_FINAL&
Af. Stage4_3_DiphthongsOrthoToTempMarker: [kr&A_ACUTE_LONG_VOC_M_FINAL&]
  Stage4_4_ResolveTempVowelMarkers START: In=	kr&A_ACUTE_LONG_VOC_M_FINAL&
    DBG (Stage4_4): Iter.gsub: Rule '	&A_ACUTE_LONG_VOC_M_FINAL&(#?)	' APPLIED to '	kr&A_ACUTE_LONG_VOC_M_FINAL&	' -> '	krɑːv	' (	1	x)
    DBG (Stage4_4): Iter.gsub Pass 1 ended. String changed from '	kr&A_ACUTE_LONG_VOC_M_FINAL&	' to '	krɑːv	'
    DBG (Stage4_4): Iter.gsub Pass 2 ended. No changes in this pass. String remains: '	krɑːv	'
  Stage4_4_ResolveTempVowelMarkers END: Out=	krɑːv
Af. Stage4_4_ResolveTempVowelMarkers: [krɑːv]
  Stage4_5_ContextualAllophonyOnPhonetic START (Proc): In=	krɑːv
  Stage4_5_ContextualAllophonyOnPhonetic START: In=	krɑːv
    DBG (Stage4_5): Applying placeholder creation rules (ONCE)...
    DBG (Stage4_5): Placeholder created: '	ɑː	' -> '	&PHON_A_LONG&	'. Result: '	kr&PHON_A_LONG&v	'
    DBG (Stage4_5): After placeholder creation: 	kr&PHON_A_LONG&v
    DBG (Stage4_5): Applying core allophony rules (iteratively)...
    DBG (Stage4_5): Core Iter.gsub Pass 1 ended. No changes in this pass. String remains: '	kr&PHON_A_LONG&v	'
    DBG (Stage4_5): After core allophony rules: 	kr&PHON_A_LONG&v
    DBG (Stage4_5): Applying placeholder restoration rules (ONCE)...
    DBG (Stage4_5): Placeholder restored: '	&PHON_A_LONG&	' -> '	ɑː	'. Result: '	krɑːv	'
    DBG (Stage4_5): After placeholder restoration: 	krɑːv
    DBG (Stage4_5): Applying Connacht ɑu -> əu shift (ONCE)...
    DBG (Stage4_5): After Connacht ɑu->əu shift: 	krɑːv
    DBG (Stage4_5): Applying &TEMP_CONN_AU& -> əu shift (ONCE)...
    DBG (Stage4_5): After &TEMP_CONN_AU&->əu shift: 	krɑːv
  Stage4_5_ContextualAllophonyOnPhonetic END: Out=	krɑːv
Af. Stage4_5_ContextualAllophonyOnPhonetic: [krɑːv]
    DBG (Epenthes): is_likely_monosyllable_revised for '	krɑːv	' (orig: '	krɑːv	') count: 	1	 result: 	true
  EpenthesisAndStrongSonorants START (Proc): In=	krɑːv
  EpenthesisAndStrongSonorants START (Proc): In=	krɑːv
  apply_procedural_epenthesis START: In=	krɑːv
    DBG (Epenthes): Parsed units for epenthesis: 	k(nonpalatal) | r(nonpalatal) | ɑː(vowel) | v(unknown)
    DBG (Epenthes): is_likely_monosyllable_revised for '	krɑːv	' (orig: '	krɑːv	') count: 	1	 result: 	true
  apply_procedural_epenthesis END (no change): Out=	krɑːv
    DBG (Epenthes): After procedural epenthesis: 	krɑːv
    DBG (Epenthes): After strong sonorant rules: 	krɑːv
  EpenthesisAndStrongSonorants END (Proc): Out=	krɑːv
Af. EpenthesisAndStrongSonorants: [krɑːv]
  Diacritics START: In=	krɑːv
  Diacritics END: Out=	krɑːv
Af. Diacritics: [krɑːv]
  FinalCleanup START: In=	krɑːv
  FinalCleanup END: Out=	krɑːv
Af. FinalCleanup: [krɑːv]
cnámh          -> [krɑːv]

--- Transcribing: [cnead] ---
Af. MarkDigraphsAndVocalisationTriggers: [cnead]
  ConsonantResolution START (Proc): In=	cnead
  ConsonantResolution START (Proc): In=	cnead
    DBG (Consonan): Metathesis Sub-Stage START: 	cnead
    DBG (Consonan): Metathesis Check: c_base=	c	c_pal=	false	n_base=	n	n_pal=	false	at offset	1
    DBG (Consonan): Metathesis candidate found: 	cn
    DBG (DetQual): Word:	cnead	Cons seq:	n	s:	2	e:	2
    DBG (DetQual): Next relevant vowel char for quality:	e	Next quality implication:	slender
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	n	': 	palatal
    DBG (Consonan): Original ortho 'n' (ortho indices 2-2 in 'cnead') quality was: 	palatal	. Thus, quality for metathesized 'r': 	palatal
    DBG (Consonan): Metathesis Check: c_base=	e	c_pal=	false	n_base=	a	n_pal=	false	at offset	3
    DBG (Consonan): Metathesis Check: c_base=	a	c_pal=	false	n_base=	d	n_pal=	false	at offset	4
    DBG (Consonan): Metathesis Check: c_base=	d	c_pal=	false	n_base=		n_pal=	false	at offset	5
    DBG (Consonan): Metathesis Sub-Stage END: 	cr'ead
    DBG (Consonan): After Pass 1 (markers): 	cr'ead
    DBG (Consonan): Pass 2: Checking '	c	' at phon_idx 	1	 -> ortho_s:	1	ortho_e:	1
    DBG (Consonan): Single cons rule: c_capture=	c	o_s=	1	o_e=	1
    DBG (DetQual): Word:	cnead	Cons seq:	c	s:	1	e:	1
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	c	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	c	' with '	k	'
    DBG (Consonan): Pass 2: Checking '	r	' at phon_idx 	2	 -> ortho_s:	2	ortho_e:	2
    DBG (Consonan): Single cons rule: c_capture=	r	o_s=	2	o_e=	2
    DBG (DetQual): Word:	cnead	Cons seq:	n	s:	2	e:	2
    DBG (DetQual): Next relevant vowel char for quality:	e	Next quality implication:	slender
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	n	': 	palatal
    DBG (Consonan): Pass 2: Replaced '	r	' with '	r'	'
    DBG (Consonan): Pass 2: Checking '	d	' at phon_idx 	6	 -> ortho_s:	6	ortho_e:	6
    DBG (Consonan): Single cons rule: c_capture=	d	o_s=	6	o_e=	6
    DBG (DetQual): Bailing: Invalid indices or word for: 	cnead	6	6
    DBG (Consonan): Pass 2: Replaced '	d	' with '	d	'
    DBG (Consonan): After Pass 2 (single chars): 	kr''ead
  ConsonantResolution END (Proc): Out=	kr''ead
Af. ConsonantResolution: [kr''ead]
  Stage4_0_SpecificOrthoToTempMarker START: In=	kr''ead
  Stage4_0_SpecificOrthoToTempMarker END: Out=	kr''ead
Af. Stage4_0_SpecificOrthoToTempMarker: [kr''ead]
  Stage4_0_1_Resolve_CH_Marker START: In=	kr''ead
  Stage4_0_1_Resolve_CH_Marker END: Out=	kr''ead
Af. Stage4_0_1_Resolve_CH_Marker: [kr''ead]
  Stage4_2_LongVowelsOrthoToTempMarker START: In=	kr''ead
  Stage4_2_LongVowelsOrthoToTempMarker END: Out=	kr''ead
Af. Stage4_2_LongVowelsOrthoToTempMarker: [kr''ead]
  Stage4_3_DiphthongsOrthoToTempMarker START: In=	kr''ead
  Stage4_3_DiphthongsOrthoToTempMarker END: Out=	kr''ead
Af. Stage4_3_DiphthongsOrthoToTempMarker: [kr''ead]
  Stage4_4_ResolveTempVowelMarkers START: In=	kr''ead
    DBG (Stage4_4): Iter.gsub Pass 1 ended. No changes in this pass. String remains: '	kr''ead	'
  Stage4_4_ResolveTempVowelMarkers END: Out=	kr''ead
Af. Stage4_4_ResolveTempVowelMarkers: [kr''ead]
  Stage4_5_ContextualAllophonyOnPhonetic START (Proc): In=	kr''ead
  Stage4_5_ContextualAllophonyOnPhonetic START: In=	kr''ead
    DBG (Stage4_5): Applying placeholder creation rules (ONCE)...
    DBG (Stage4_5): After placeholder creation: 	kr''ead
    DBG (Stage4_5): Applying core allophony rules (iteratively)...
    DBG (Stage4_5): Core Iter.gsub: Rule '	a	' APPLIED to '	kr''ead	' -> '	kr''eɑd	' (	1	x)
    DBG (Stage4_5): Core Iter.gsub Pass 1 ended. String changed from '	kr''ead	' to '	kr''eɑd	'
    DBG (Stage4_5): Core Iter.gsub Pass 2 ended. No changes in this pass. String remains: '	kr''eɑd	'
    DBG (Stage4_5): After core allophony rules: 	kr''eɑd
    DBG (Stage4_5): Applying placeholder restoration rules (ONCE)...
    DBG (Stage4_5): After placeholder restoration: 	kr''eɑd
    DBG (Stage4_5): Applying Connacht ɑu -> əu shift (ONCE)...
    DBG (Stage4_5): After Connacht ɑu->əu shift: 	kr''eɑd
    DBG (Stage4_5): Applying &TEMP_CONN_AU& -> əu shift (ONCE)...
    DBG (Stage4_5): After &TEMP_CONN_AU&->əu shift: 	kr''eɑd
  Stage4_5_ContextualAllophonyOnPhonetic END: Out=	kr''eɑd
Af. Stage4_5_ContextualAllophonyOnPhonetic: [kr''eɑd]
    DBG (Epenthes): is_likely_monosyllable_revised for '	kr''eɑd	' (orig: '	kr''eɑd	') count: 	1	 result: 	true
  EpenthesisAndStrongSonorants START (Proc): In=	kr''eɑd
  EpenthesisAndStrongSonorants START (Proc): In=	kr''eɑd
  apply_procedural_epenthesis START: In=	kr''eɑd
    DBG (Epenthes): Parsed units for epenthesis: 	k(nonpalatal) | r'(palatal) | '(unknown_fallback) | e(vowel) | ɑ(vowel) | d(palatal)
    DBG (Epenthes): is_likely_monosyllable_revised for '	kr''eɑd	' (orig: '	kr''eɑd	') count: 	1	 result: 	true
  apply_procedural_epenthesis END (no change): Out=	kr''eɑd
    DBG (Epenthes): After procedural epenthesis: 	kr''eɑd
    DBG (Epenthes): After strong sonorant rules: 	kr''eɑd
  EpenthesisAndStrongSonorants END (Proc): Out=	kr''eɑd
Af. EpenthesisAndStrongSonorants: [kr''eɑd]
  Diacritics START: In=	kr''eɑd
  Diacritics END: Out=	kr''eɑd
Af. Diacritics: [kr''eɑd]
  FinalCleanup START: In=	kr''eɑd
  FinalCleanup END: Out=	kr''eɑd
Af. FinalCleanup: [kr''eɑd]
cnead           -> [kr''eɑd]

--- Transcribing: [cnoc] ---
Af. MarkDigraphsAndVocalisationTriggers: [cnoc]
  ConsonantResolution START (Proc): In=	cnoc
  ConsonantResolution START (Proc): In=	cnoc
    DBG (Consonan): Metathesis Sub-Stage START: 	cnoc
    DBG (Consonan): Metathesis Check: c_base=	c	c_pal=	false	n_base=	n	n_pal=	false	at offset	1
    DBG (Consonan): Metathesis candidate found: 	cn
    DBG (DetQual): Word:	cnoc	Cons seq:	n	s:	2	e:	2
    DBG (DetQual): Next relevant vowel char for quality:	o	Next quality implication:	broad
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	n	': 	nonpalatal
    DBG (Consonan): Original ortho 'n' (ortho indices 2-2 in 'cnoc') quality was: 	nonpalatal	. Thus, quality for metathesized 'r': 	nonpalatal
    DBG (Consonan): Metathesis Check: c_base=	o	c_pal=	false	n_base=	c	n_pal=	false	at offset	3
    DBG (Consonan): Metathesis Check: c_base=	c	c_pal=	false	n_base=		n_pal=	false	at offset	4
    DBG (Consonan): Metathesis Sub-Stage END: 	croc
    DBG (Consonan): After Pass 1 (markers): 	croc
    DBG (Consonan): Pass 2: Checking '	c	' at phon_idx 	1	 -> ortho_s:	1	ortho_e:	1
    DBG (Consonan): Single cons rule: c_capture=	c	o_s=	1	o_e=	1
    DBG (DetQual): Word:	cnoc	Cons seq:	c	s:	1	e:	1
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	c	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	c	' with '	k	'
    DBG (Consonan): Pass 2: Checking '	r	' at phon_idx 	2	 -> ortho_s:	2	ortho_e:	2
    DBG (Consonan): Single cons rule: c_capture=	r	o_s=	2	o_e=	2
    DBG (DetQual): Word:	cnoc	Cons seq:	n	s:	2	e:	2
    DBG (DetQual): Next relevant vowel char for quality:	o	Next quality implication:	broad
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	n	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	r	' with '	r	'
    DBG (Consonan): Pass 2: Checking '	c	' at phon_idx 	4	 -> ortho_s:	4	ortho_e:	4
    DBG (Consonan): Single cons rule: c_capture=	c	o_s=	4	o_e=	4
    DBG (DetQual): Word:	cnoc	Cons seq:	c	s:	4	e:	4
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	o	Prev quality implication:	broad
    DBG (DetQual): Final determined quality for '	c	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	c	' with '	k	'
    DBG (Consonan): After Pass 2 (single chars): 	krok
  ConsonantResolution END (Proc): Out=	krok
Af. ConsonantResolution: [krok]
  Stage4_0_SpecificOrthoToTempMarker START: In=	krok
  Stage4_0_SpecificOrthoToTempMarker END: Out=	krok
Af. Stage4_0_SpecificOrthoToTempMarker: [krok]
  Stage4_0_1_Resolve_CH_Marker START: In=	krok
  Stage4_0_1_Resolve_CH_Marker END: Out=	krok
Af. Stage4_0_1_Resolve_CH_Marker: [krok]
  Stage4_2_LongVowelsOrthoToTempMarker START: In=	krok
  Stage4_2_LongVowelsOrthoToTempMarker END: Out=	krok
Af. Stage4_2_LongVowelsOrthoToTempMarker: [krok]
  Stage4_3_DiphthongsOrthoToTempMarker START: In=	krok
  Stage4_3_DiphthongsOrthoToTempMarker END: Out=	krok
Af. Stage4_3_DiphthongsOrthoToTempMarker: [krok]
  Stage4_4_ResolveTempVowelMarkers START: In=	krok
    DBG (Stage4_4): Iter.gsub Pass 1 ended. No changes in this pass. String remains: '	krok	'
  Stage4_4_ResolveTempVowelMarkers END: Out=	krok
Af. Stage4_4_ResolveTempVowelMarkers: [krok]
  Stage4_5_ContextualAllophonyOnPhonetic START (Proc): In=	krok
  Stage4_5_ContextualAllophonyOnPhonetic START: In=	krok
    DBG (Stage4_5): Applying placeholder creation rules (ONCE)...
    DBG (Stage4_5): After placeholder creation: 	krok
    DBG (Stage4_5): Applying core allophony rules (iteratively)...
    DBG (Stage4_5): Core Iter.gsub: Rule '	o	' APPLIED to '	krok	' -> '	krɔk	' (	1	x)
    DBG (Stage4_5): Core Iter.gsub Pass 1 ended. String changed from '	krok	' to '	krɔk	'
    DBG (Stage4_5): Core Iter.gsub Pass 2 ended. No changes in this pass. String remains: '	krɔk	'
    DBG (Stage4_5): After core allophony rules: 	krɔk
    DBG (Stage4_5): Applying placeholder restoration rules (ONCE)...
    DBG (Stage4_5): After placeholder restoration: 	krɔk
    DBG (Stage4_5): Applying Connacht ɑu -> əu shift (ONCE)...
    DBG (Stage4_5): After Connacht ɑu->əu shift: 	krɔk
    DBG (Stage4_5): Applying &TEMP_CONN_AU& -> əu shift (ONCE)...
    DBG (Stage4_5): After &TEMP_CONN_AU&->əu shift: 	krɔk
  Stage4_5_ContextualAllophonyOnPhonetic END: Out=	krɔk
Af. Stage4_5_ContextualAllophonyOnPhonetic: [krɔk]
    DBG (Epenthes): is_likely_monosyllable_revised for '	krɔk	' (orig: '	krɔk	') count: 	1	 result: 	true
  EpenthesisAndStrongSonorants START (Proc): In=	krɔk
  EpenthesisAndStrongSonorants START (Proc): In=	krɔk
  apply_procedural_epenthesis START: In=	krɔk
    DBG (Epenthes): Parsed units for epenthesis: 	k(nonpalatal) | r(nonpalatal) | ɔ(vowel) | k(nonpalatal)
    DBG (Epenthes): is_likely_monosyllable_revised for '	krɔk	' (orig: '	krɔk	') count: 	1	 result: 	true
  apply_procedural_epenthesis END (no change): Out=	krɔk
    DBG (Epenthes): After procedural epenthesis: 	krɔk
    DBG (Epenthes): After strong sonorant rules: 	krɔk
  EpenthesisAndStrongSonorants END (Proc): Out=	krɔk
Af. EpenthesisAndStrongSonorants: [krɔk]
  Diacritics START: In=	krɔk
  Diacritics END: Out=	krɔk
Af. Diacritics: [krɔk]
  FinalCleanup START: In=	krɔk
  FinalCleanup END: Out=	krɔk
Af. FinalCleanup: [krɔk]
cnoc            -> [krɔk]

--- Transcribing: [gnaoi] ---
Af. MarkDigraphsAndVocalisationTriggers: [gn&AOI_LONG&]
  ConsonantResolution START (Proc): In=	gn&AOI_LONG&
  ConsonantResolution START (Proc): In=	gn&AOI_LONG&
    DBG (Consonan): Metathesis Sub-Stage START: 	gn&AOI_LONG&
    DBG (Consonan): Metathesis Check: c_base=	g	c_pal=	false	n_base=	n	n_pal=	false	at offset	1
    DBG (Consonan): Metathesis candidate found: 	gn
    DBG (DetQual): Word:	gnaoi	Cons seq:	n	s:	2	e:	2
    DBG (DetQual): Next relevant vowel char for quality:	i	Next quality implication:	slender
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	n	': 	palatal
    DBG (Consonan): Original ortho 'n' (ortho indices 2-2 in 'gnaoi') quality was: 	palatal	. Thus, quality for metathesized 'r': 	palatal
    DBG (Consonan): Metathesis Check: c_base=	&	c_pal=	false	n_base=	A	n_pal=	false	at offset	3
    DBG (Consonan): Metathesis Check: c_base=	A	c_pal=	false	n_base=	O	n_pal=	false	at offset	4
    DBG (Consonan): Metathesis Check: c_base=	O	c_pal=	false	n_base=	I	n_pal=	false	at offset	5
    DBG (Consonan): Metathesis Check: c_base=	I	c_pal=	false	n_base=	_	n_pal=	false	at offset	6
    DBG (Consonan): Metathesis Check: c_base=	_	c_pal=	false	n_base=	L	n_pal=	false	at offset	7
    DBG (Consonan): Metathesis Check: c_base=	L	c_pal=	false	n_base=	O	n_pal=	false	at offset	8
    DBG (Consonan): Metathesis Check: c_base=	O	c_pal=	false	n_base=	N	n_pal=	false	at offset	9
    DBG (Consonan): Metathesis Check: c_base=	N	c_pal=	false	n_base=	G	n_pal=	false	at offset	10
    DBG (Consonan): Metathesis Check: c_base=	G	c_pal=	false	n_base=	&	n_pal=	false	at offset	11
    DBG (Consonan): Metathesis Check: c_base=	&	c_pal=	false	n_base=		n_pal=	false	at offset	12
    DBG (Consonan): Metathesis Sub-Stage END: 	gr'&AOI_LONG&
    DBG (Consonan): After Pass 1 (markers): 	gr'&AOI_LONG&
    DBG (Consonan): Pass 2: Checking '	g	' at phon_idx 	1	 -> ortho_s:	1	ortho_e:	1
    DBG (Consonan): Single cons rule: c_capture=	g	o_s=	1	o_e=	1
    DBG (DetQual): Word:	gnaoi	Cons seq:	g	s:	1	e:	1
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	g	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	g	' with '	g	'
    DBG (Consonan): Pass 2: Checking '	r	' at phon_idx 	2	 -> ortho_s:	2	ortho_e:	2
    DBG (Consonan): Single cons rule: c_capture=	r	o_s=	2	o_e=	2
    DBG (DetQual): Word:	gnaoi	Cons seq:	n	s:	2	e:	2
    DBG (DetQual): Next relevant vowel char for quality:	i	Next quality implication:	slender
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	n	': 	palatal
    DBG (Consonan): Pass 2: Replaced '	r	' with '	r'	'
    DBG (Consonan): After Pass 2 (single chars): 	gr''&AOI_LONG&
  ConsonantResolution END (Proc): Out=	gr''&AOI_LONG&
Af. ConsonantResolution: [gr''&AOI_LONG&]
  Stage4_0_SpecificOrthoToTempMarker START: In=	gr''&AOI_LONG&
  Stage4_0_SpecificOrthoToTempMarker END: Out=	gr''&AOI_LONG&
Af. Stage4_0_SpecificOrthoToTempMarker: [gr''&AOI_LONG&]
  Stage4_0_1_Resolve_CH_Marker START: In=	gr''&AOI_LONG&
  Stage4_0_1_Resolve_CH_Marker END: Out=	gr''&AOI_LONG&
Af. Stage4_0_1_Resolve_CH_Marker: [gr''&AOI_LONG&]
  Stage4_2_LongVowelsOrthoToTempMarker START: In=	gr''&AOI_LONG&
  Stage4_2_LongVowelsOrthoToTempMarker END: Out=	gr''&AOI_LONG&
Af. Stage4_2_LongVowelsOrthoToTempMarker: [gr''&AOI_LONG&]
  Stage4_3_DiphthongsOrthoToTempMarker START: In=	gr''&AOI_LONG&
  Stage4_3_DiphthongsOrthoToTempMarker END: Out=	gr''&AOI_LONG&
Af. Stage4_3_DiphthongsOrthoToTempMarker: [gr''&AOI_LONG&]
  Stage4_4_ResolveTempVowelMarkers START: In=	gr''&AOI_LONG&
    DBG (Stage4_4): Iter.gsub: Rule '	&AOI_LONG&	' APPLIED to '	gr''&AOI_LONG&	' -> '	gr''iː	' (	1	x)
    DBG (Stage4_4): Iter.gsub Pass 1 ended. String changed from '	gr''&AOI_LONG&	' to '	gr''iː	'
    DBG (Stage4_4): Iter.gsub Pass 2 ended. No changes in this pass. String remains: '	gr''iː	'
  Stage4_4_ResolveTempVowelMarkers END: Out=	gr''iː
Af. Stage4_4_ResolveTempVowelMarkers: [gr''iː]
  Stage4_5_ContextualAllophonyOnPhonetic START (Proc): In=	gr''iː
  Stage4_5_ContextualAllophonyOnPhonetic START: In=	gr''iː
    DBG (Stage4_5): Applying placeholder creation rules (ONCE)...
    DBG (Stage4_5): Placeholder created: '	iː	' -> '	&PHON_I_LONG&	'. Result: '	gr''&PHON_I_LONG&	'
    DBG (Stage4_5): After placeholder creation: 	gr''&PHON_I_LONG&
    DBG (Stage4_5): Applying core allophony rules (iteratively)...
    DBG (Stage4_5): Core Iter.gsub Pass 1 ended. No changes in this pass. String remains: '	gr''&PHON_I_LONG&	'
    DBG (Stage4_5): After core allophony rules: 	gr''&PHON_I_LONG&
    DBG (Stage4_5): Applying placeholder restoration rules (ONCE)...
    DBG (Stage4_5): Placeholder restored: '	&PHON_I_LONG&	' -> '	iː	'. Result: '	gr''iː	'
    DBG (Stage4_5): After placeholder restoration: 	gr''iː
    DBG (Stage4_5): Applying Connacht ɑu -> əu shift (ONCE)...
    DBG (Stage4_5): After Connacht ɑu->əu shift: 	gr''iː
    DBG (Stage4_5): Applying &TEMP_CONN_AU& -> əu shift (ONCE)...
    DBG (Stage4_5): After &TEMP_CONN_AU&->əu shift: 	gr''iː
  Stage4_5_ContextualAllophonyOnPhonetic END: Out=	gr''iː
Af. Stage4_5_ContextualAllophonyOnPhonetic: [gr''iː]
    DBG (Epenthes): is_likely_monosyllable_revised for '	gr''iː	' (orig: '	gr''iː	') count: 	1	 result: 	true
  EpenthesisAndStrongSonorants START (Proc): In=	gr''iː
  EpenthesisAndStrongSonorants START (Proc): In=	gr''iː
  apply_procedural_epenthesis START: In=	gr''iː
    DBG (Epenthes): Parsed units for epenthesis: 	g(nonpalatal) | r'(palatal) | '(unknown_fallback) | iː(vowel)
    DBG (Epenthes): is_likely_monosyllable_revised for '	gr''iː	' (orig: '	gr''iː	') count: 	1	 result: 	true
  apply_procedural_epenthesis END (no change): Out=	gr''iː
    DBG (Epenthes): After procedural epenthesis: 	gr''iː
    DBG (Epenthes): After strong sonorant rules: 	gr''iː
  EpenthesisAndStrongSonorants END (Proc): Out=	gr''iː
Af. EpenthesisAndStrongSonorants: [gr''iː]
  Diacritics START: In=	gr''iː
  Diacritics END: Out=	gr''iː
Af. Diacritics: [gr''iː]
  FinalCleanup START: In=	gr''iː
  FinalCleanup END: Out=	gr''iː
Af. FinalCleanup: [gr''iː]
gnaoi           -> [gr''iː]

--- Transcribing: [gnó] ---
Af. MarkDigraphsAndVocalisationTriggers: [gnó]
  ConsonantResolution START (Proc): In=	gnó
  ConsonantResolution START (Proc): In=	gnó
    DBG (Consonan): Metathesis Sub-Stage START: 	gnó
    DBG (Consonan): Metathesis Check: c_base=	g	c_pal=	false	n_base=	n	n_pal=	false	at offset	1
    DBG (Consonan): Metathesis candidate found: 	gn
    DBG (DetQual): Word:	gnó	Cons seq:	n	s:	2	e:	2
    DBG (DetQual): Next relevant vowel char for quality:	ó	Next quality implication:	broad
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	n	': 	nonpalatal
    DBG (Consonan): Original ortho 'n' (ortho indices 2-2 in 'gnó') quality was: 	nonpalatal	. Thus, quality for metathesized 'r': 	nonpalatal
    DBG (Consonan): Metathesis Check: c_base=	ó	c_pal=	false	n_base=		n_pal=	false	at offset	3
    DBG (Consonan): Metathesis Sub-Stage END: 	gró
    DBG (Consonan): After Pass 1 (markers): 	gró
    DBG (Consonan): Pass 2: Checking '	g	' at phon_idx 	1	 -> ortho_s:	1	ortho_e:	1
    DBG (Consonan): Single cons rule: c_capture=	g	o_s=	1	o_e=	1
    DBG (DetQual): Word:	gnó	Cons seq:	g	s:	1	e:	1
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	g	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	g	' with '	g	'
    DBG (Consonan): Pass 2: Checking '	r	' at phon_idx 	2	 -> ortho_s:	2	ortho_e:	2
    DBG (Consonan): Single cons rule: c_capture=	r	o_s=	2	o_e=	2
    DBG (DetQual): Word:	gnó	Cons seq:	n	s:	2	e:	2
    DBG (DetQual): Next relevant vowel char for quality:	ó	Next quality implication:	broad
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	n	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	r	' with '	r	'
    DBG (Consonan): After Pass 2 (single chars): 	gró
  ConsonantResolution END (Proc): Out=	gró
Af. ConsonantResolution: [gró]
  Stage4_0_SpecificOrthoToTempMarker START: In=	gró
  Stage4_0_SpecificOrthoToTempMarker END: Out=	gró
Af. Stage4_0_SpecificOrthoToTempMarker: [gró]
  Stage4_0_1_Resolve_CH_Marker START: In=	gró
  Stage4_0_1_Resolve_CH_Marker END: Out=	gró
Af. Stage4_0_1_Resolve_CH_Marker: [gró]
  Stage4_2_LongVowelsOrthoToTempMarker START: In=	gró
  Stage4_2_LongVowelsOrthoToTempMarker END: Out=	gr&O_ACUTE_LONG&
Af. Stage4_2_LongVowelsOrthoToTempMarker: [gr&O_ACUTE_LONG&]
  Stage4_3_DiphthongsOrthoToTempMarker START: In=	gr&O_ACUTE_LONG&
  Stage4_3_DiphthongsOrthoToTempMarker END: Out=	gr&O_ACUTE_LONG&
Af. Stage4_3_DiphthongsOrthoToTempMarker: [gr&O_ACUTE_LONG&]
  Stage4_4_ResolveTempVowelMarkers START: In=	gr&O_ACUTE_LONG&
    DBG (Stage4_4): Iter.gsub: Rule '	&O_ACUTE_LONG&	' APPLIED to '	gr&O_ACUTE_LONG&	' -> '	groː	' (	1	x)
    DBG (Stage4_4): Iter.gsub Pass 1 ended. String changed from '	gr&O_ACUTE_LONG&	' to '	groː	'
    DBG (Stage4_4): Iter.gsub Pass 2 ended. No changes in this pass. String remains: '	groː	'
  Stage4_4_ResolveTempVowelMarkers END: Out=	groː
Af. Stage4_4_ResolveTempVowelMarkers: [groː]
  Stage4_5_ContextualAllophonyOnPhonetic START (Proc): In=	groː
  Stage4_5_ContextualAllophonyOnPhonetic START: In=	groː
    DBG (Stage4_5): Applying placeholder creation rules (ONCE)...
    DBG (Stage4_5): Placeholder created: '	oː	' -> '	&PHON_O_LONG&	'. Result: '	gr&PHON_O_LONG&	'
    DBG (Stage4_5): After placeholder creation: 	gr&PHON_O_LONG&
    DBG (Stage4_5): Applying core allophony rules (iteratively)...
    DBG (Stage4_5): Core Iter.gsub Pass 1 ended. No changes in this pass. String remains: '	gr&PHON_O_LONG&	'
    DBG (Stage4_5): After core allophony rules: 	gr&PHON_O_LONG&
    DBG (Stage4_5): Applying placeholder restoration rules (ONCE)...
    DBG (Stage4_5): Placeholder restored: '	&PHON_O_LONG&	' -> '	oː	'. Result: '	groː	'
    DBG (Stage4_5): After placeholder restoration: 	groː
    DBG (Stage4_5): Applying Connacht ɑu -> əu shift (ONCE)...
    DBG (Stage4_5): After Connacht ɑu->əu shift: 	groː
    DBG (Stage4_5): Applying &TEMP_CONN_AU& -> əu shift (ONCE)...
    DBG (Stage4_5): After &TEMP_CONN_AU&->əu shift: 	groː
  Stage4_5_ContextualAllophonyOnPhonetic END: Out=	groː
Af. Stage4_5_ContextualAllophonyOnPhonetic: [groː]
    DBG (Epenthes): is_likely_monosyllable_revised for '	groː	' (orig: '	groː	') count: 	1	 result: 	true
  EpenthesisAndStrongSonorants START (Proc): In=	groː
  EpenthesisAndStrongSonorants START (Proc): In=	groː
  apply_procedural_epenthesis START: In=	groː
    DBG (Epenthes): Parsed units for epenthesis: 	g(nonpalatal) | r(nonpalatal) | oː(vowel)
    DBG (Epenthes): is_likely_monosyllable_revised for '	groː	' (orig: '	groː	') count: 	1	 result: 	true
  apply_procedural_epenthesis END (no change): Out=	groː
    DBG (Epenthes): After procedural epenthesis: 	groː
    DBG (Epenthes): After strong sonorant rules: 	groː
  EpenthesisAndStrongSonorants END (Proc): Out=	groː
Af. EpenthesisAndStrongSonorants: [groː]
  Diacritics START: In=	groː
  Diacritics END: Out=	groː
Af. Diacritics: [groː]
  FinalCleanup START: In=	groː
  FinalCleanup END: Out=	groː
Af. FinalCleanup: [groː]
gnó            -> [groː]

--- Transcribing: [seilf] ---
Af. MarkDigraphsAndVocalisationTriggers: [seilf]
  ConsonantResolution START (Proc): In=	seilf
  ConsonantResolution START (Proc): In=	seilf
    DBG (Consonan): Metathesis Sub-Stage START: 	seilf
    DBG (Consonan): Metathesis Check: c_base=	s	c_pal=	false	n_base=	e	n_pal=	false	at offset	1
    DBG (Consonan): Metathesis Check: c_base=	e	c_pal=	false	n_base=	i	n_pal=	false	at offset	2
    DBG (Consonan): Metathesis Check: c_base=	i	c_pal=	false	n_base=	l	n_pal=	false	at offset	3
    DBG (Consonan): Metathesis Check: c_base=	l	c_pal=	false	n_base=	f	n_pal=	false	at offset	4
    DBG (Consonan): Metathesis Check: c_base=	f	c_pal=	false	n_base=		n_pal=	false	at offset	5
    DBG (Consonan): Metathesis Sub-Stage END: 	seilf
    DBG (Consonan): After Pass 1 (markers): 	seilf
    DBG (Consonan): Pass 2: Checking '	s	' at phon_idx 	1	 -> ortho_s:	1	ortho_e:	1
    DBG (Consonan): Single cons rule: c_capture=	s	o_s=	1	o_e=	1
    DBG (DetQual): Word:	seilf	Cons seq:	s	s:	1	e:	1
    DBG (DetQual): Next relevant vowel char for quality:	e	Next quality implication:	slender
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	s	': 	palatal
    DBG (Consonan): Pass 2: Replaced '	s	' with '	s'	'
    DBG (Consonan): Pass 2: Checking '	f	' at phon_idx 	5	 -> ortho_s:	5	ortho_e:	5
    DBG (Consonan): Single cons rule: c_capture=	f	o_s=	5	o_e=	5
    DBG (DetQual): Word:	seilf	Cons seq:	f	s:	5	e:	5
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	i	Prev quality implication:	slender
    DBG (DetQual): Final determined quality for '	f	': 	palatal
    DBG (Consonan): Pass 2: Replaced '	f	' with '	f'	'
    DBG (Consonan): After Pass 2 (single chars): 	s'eilf'
  ConsonantResolution END (Proc): Out=	s'eilf'
Af. ConsonantResolution: [s'eilf']
  Stage4_0_SpecificOrthoToTempMarker START: In=	s'eilf'
  Stage4_0_SpecificOrthoToTempMarker END: Out=	s'eilf'
Af. Stage4_0_SpecificOrthoToTempMarker: [s'eilf']
  Stage4_0_1_Resolve_CH_Marker START: In=	s'eilf'
  Stage4_0_1_Resolve_CH_Marker END: Out=	s'eilf'
Af. Stage4_0_1_Resolve_CH_Marker: [s'eilf']
  Stage4_2_LongVowelsOrthoToTempMarker START: In=	s'eilf'
  Stage4_2_LongVowelsOrthoToTempMarker END: Out=	s'eilf'
Af. Stage4_2_LongVowelsOrthoToTempMarker: [s'eilf']
  Stage4_3_DiphthongsOrthoToTempMarker START: In=	s'eilf'
  Stage4_3_DiphthongsOrthoToTempMarker END: Out=	s'&EI_DIPH&lf'
Af. Stage4_3_DiphthongsOrthoToTempMarker: [s'&EI_DIPH&lf']
  Stage4_4_ResolveTempVowelMarkers START: In=	s'&EI_DIPH&lf'
    DBG (Stage4_4): Iter.gsub: Rule '	&EI_DIPH&	' APPLIED to '	s'&EI_DIPH&lf'	' -> '	s'elf'	' (	1	x)
    DBG (Stage4_4): Iter.gsub Pass 1 ended. String changed from '	s'&EI_DIPH&lf'	' to '	s'elf'	'
    DBG (Stage4_4): Iter.gsub Pass 2 ended. No changes in this pass. String remains: '	s'elf'	'
  Stage4_4_ResolveTempVowelMarkers END: Out=	s'elf'
Af. Stage4_4_ResolveTempVowelMarkers: [s'elf']
  Stage4_5_ContextualAllophonyOnPhonetic START (Proc): In=	s'elf'
  Stage4_5_ContextualAllophonyOnPhonetic START: In=	s'elf'
    DBG (Stage4_5): Applying placeholder creation rules (ONCE)...
    DBG (Stage4_5): After placeholder creation: 	s'elf'
    DBG (Stage4_5): Applying core allophony rules (iteratively)...
    DBG (Stage4_5): Core Iter.gsub Pass 1 ended. No changes in this pass. String remains: '	s'elf'	'
    DBG (Stage4_5): After core allophony rules: 	s'elf'
    DBG (Stage4_5): Applying placeholder restoration rules (ONCE)...
    DBG (Stage4_5): After placeholder restoration: 	s'elf'
    DBG (Stage4_5): Applying Connacht ɑu -> əu shift (ONCE)...
    DBG (Stage4_5): After Connacht ɑu->əu shift: 	s'elf'
    DBG (Stage4_5): Applying &TEMP_CONN_AU& -> əu shift (ONCE)...
    DBG (Stage4_5): After &TEMP_CONN_AU&->əu shift: 	s'elf'
  Stage4_5_ContextualAllophonyOnPhonetic END: Out=	s'elf'
Af. Stage4_5_ContextualAllophonyOnPhonetic: [s'elf']
    DBG (Epenthes): is_likely_monosyllable_revised for '	s'elf'	' (orig: '	s'elf'	') count: 	1	 result: 	true
  EpenthesisAndStrongSonorants START (Proc): In=	s'elf'
  EpenthesisAndStrongSonorants START (Proc): In=	s'elf'
  apply_procedural_epenthesis START: In=	s'elf'
    DBG (Epenthes): Parsed units for epenthesis: 	s'(palatal) | e(vowel) | l(nonpalatal) | f'(palatal)
    DBG (Epenthes): is_likely_monosyllable_revised for '	s'elf'	' (orig: '	s'elf'	') count: 	1	 result: 	true
    DBG (Epenthes): Inferred C1 quality to palatal for: 	l	 -> 	l'	 based on V=	e	 and C2=	f'
    DBG (Epenthes): Checking V-C1-C2: 	e	l'	f'	 | Cluster key: 	lf	 | C1 Qual: 	palatal	 | C2 Qual: 	palatal
    DBG (Epenthes): PROCEDURAL Epenthesis Triggered for: 	e	l'	f'	 -> inserting 	i
  apply_procedural_epenthesis END (modified): Out=	s'el'if'
    DBG (Epenthes): After procedural epenthesis: 	s'el'if'
    DBG (Epenthes): After strong sonorant rules: 	s'el'if'
  EpenthesisAndStrongSonorants END (Proc): Out=	s'el'if'
Af. EpenthesisAndStrongSonorants: [s'el'if']
  Diacritics START: In=	s'el'if'
  Diacritics END: Out=	s'el'if'
Af. Diacritics: [s'el'if']
  FinalCleanup START: In=	s'el'if'
  FinalCleanup END: Out=	s'el'if'
Af. FinalCleanup: [s'el'if']
seilf           -> [s'el'if']

--- Transcribing: [dorcha] ---
Af. MarkDigraphsAndVocalisationTriggers: [dor_CH_a]
  ConsonantResolution START (Proc): In=	dor_CH_a
  ConsonantResolution START (Proc): In=	dor_CH_a
    DBG (Consonan): Metathesis Sub-Stage START: 	dor_CH_a
    DBG (Consonan): Metathesis Check: c_base=	d	c_pal=	false	n_base=	o	n_pal=	false	at offset	1
    DBG (Consonan): Metathesis Check: c_base=	o	c_pal=	false	n_base=	r	n_pal=	false	at offset	2
    DBG (Consonan): Metathesis Check: c_base=	r	c_pal=	false	n_base=	_	n_pal=	false	at offset	3
    DBG (Consonan): Metathesis Check: c_base=	_	c_pal=	false	n_base=	C	n_pal=	false	at offset	4
    DBG (Consonan): Metathesis Check: c_base=	C	c_pal=	false	n_base=	H	n_pal=	false	at offset	5
    DBG (Consonan): Metathesis Check: c_base=	H	c_pal=	false	n_base=	_	n_pal=	false	at offset	6
    DBG (Consonan): Metathesis Check: c_base=	_	c_pal=	false	n_base=	a	n_pal=	false	at offset	7
    DBG (Consonan): Metathesis Check: c_base=	a	c_pal=	false	n_base=		n_pal=	false	at offset	8
    DBG (Consonan): Metathesis Sub-Stage END: 	dor_CH_a
    DBG (Consonan): After Pass 1 (markers): 	dor_CH_a
    DBG (Consonan): Pass 2: Checking '	d	' at phon_idx 	1	 -> ortho_s:	1	ortho_e:	1
    DBG (Consonan): Single cons rule: c_capture=	d	o_s=	1	o_e=	1
    DBG (DetQual): Word:	dorcha	Cons seq:	d	s:	1	e:	1
    DBG (DetQual): Next relevant vowel char for quality:	o	Next quality implication:	broad
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	d	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	d	' with '	d	'
    DBG (Consonan): Pass 2: Checking '	r	' at phon_idx 	3	 -> ortho_s:	3	ortho_e:	3
    DBG (Consonan): Single cons rule: c_capture=	r	o_s=	3	o_e=	3
    DBG (DetQual): Word:	dorcha	Cons seq:	r	s:	3	e:	3
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	o	Prev quality implication:	broad
    DBG (DetQual): Final determined quality for '	r	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	r	' with '	r	'
    DBG (Consonan): After Pass 2 (single chars): 	dor_CH_a
  ConsonantResolution END (Proc): Out=	dor_CH_a
Af. ConsonantResolution: [dor_CH_a]
  Stage4_0_SpecificOrthoToTempMarker START: In=	dor_CH_a
  Stage4_0_SpecificOrthoToTempMarker END: Out=	dor_CH_a
Af. Stage4_0_SpecificOrthoToTempMarker: [dor_CH_a]
  Stage4_0_1_Resolve_CH_Marker START: In=	dor_CH_a
    DBG (DetQual): Word:	dorcha	Cons seq:	ch	s:	4	e:	5
    DBG (DetQual): Next relevant vowel char for quality:	a	Next quality implication:	broad
    DBG (DetQual): Prev relevant vowel char for quality:	o	Prev quality implication:	broad
    DBG (DetQual): Final determined quality for '	ch	': 	nonpalatal
  Stage4_0_1_Resolve_CH_Marker END: Out=	dorxa
Af. Stage4_0_1_Resolve_CH_Marker: [dorxa]
  Stage4_2_LongVowelsOrthoToTempMarker START: In=	dorxa
  Stage4_2_LongVowelsOrthoToTempMarker END: Out=	dorxa
Af. Stage4_2_LongVowelsOrthoToTempMarker: [dorxa]
  Stage4_3_DiphthongsOrthoToTempMarker START: In=	dorxa
  Stage4_3_DiphthongsOrthoToTempMarker END: Out=	dorxa
Af. Stage4_3_DiphthongsOrthoToTempMarker: [dorxa]
  Stage4_4_ResolveTempVowelMarkers START: In=	dorxa
    DBG (Stage4_4): Iter.gsub Pass 1 ended. No changes in this pass. String remains: '	dorxa	'
  Stage4_4_ResolveTempVowelMarkers END: Out=	dorxa
Af. Stage4_4_ResolveTempVowelMarkers: [dorxa]
  Stage4_5_ContextualAllophonyOnPhonetic START (Proc): In=	dorxa
  Stage4_5_ContextualAllophonyOnPhonetic START: In=	dorxa
    DBG (Stage4_5): Applying placeholder creation rules (ONCE)...
    DBG (Stage4_5): After placeholder creation: 	dorxa
    DBG (Stage4_5): Applying core allophony rules (iteratively)...
    DBG (Stage4_5): Core Iter.gsub: Rule '	a	' APPLIED to '	dorxa	' -> '	dorxɑ	' (	1	x)
    DBG (Stage4_5): Core Iter.gsub: Rule '	o	' APPLIED to '	dorxɑ	' -> '	dɔrxɑ	' (	1	x)
    DBG (Stage4_5): Core Iter.gsub Pass 1 ended. String changed from '	dorxa	' to '	dɔrxɑ	'
    DBG (Stage4_5): Core Iter.gsub Pass 2 ended. No changes in this pass. String remains: '	dɔrxɑ	'
    DBG (Stage4_5): After core allophony rules: 	dɔrxɑ
    DBG (Stage4_5): Applying placeholder restoration rules (ONCE)...
    DBG (Stage4_5): After placeholder restoration: 	dɔrxɑ
    DBG (Stage4_5): Applying Connacht ɑu -> əu shift (ONCE)...
    DBG (Stage4_5): After Connacht ɑu->əu shift: 	dɔrxɑ
    DBG (Stage4_5): Applying &TEMP_CONN_AU& -> əu shift (ONCE)...
    DBG (Stage4_5): After &TEMP_CONN_AU&->əu shift: 	dɔrxɑ
  Stage4_5_ContextualAllophonyOnPhonetic END: Out=	dɔrxɑ
Af. Stage4_5_ContextualAllophonyOnPhonetic: [dɔrxɑ]
    DBG (Epenthes): is_likely_monosyllable_revised for '	dɔrxɑ	' (orig: '	dɔrxɑ	') count: 	1	 result: 	true
  EpenthesisAndStrongSonorants START (Proc): In=	dɔrxɑ
  EpenthesisAndStrongSonorants START (Proc): In=	dɔrxɑ
  apply_procedural_epenthesis START: In=	dɔrxɑ
    DBG (Epenthes): Parsed units for epenthesis: 	d(palatal) | ɔ(vowel) | r(nonpalatal) | x(unknown) | ɑ(vowel)
    DBG (Epenthes): is_likely_monosyllable_revised for '	dɔrxɑ	' (orig: '	dɔrxɑ	') count: 	1	 result: 	true
    DBG (Epenthes): Checking V-C1-C2: 	ɔ	r	x	 | Cluster key: 	rx	 | C1 Qual: 	nonpalatal	 | C2 Qual: 	unknown
  apply_procedural_epenthesis END (no change): Out=	dɔrxɑ
    DBG (Epenthes): After procedural epenthesis: 	dɔrxɑ
    DBG (Epenthes): After strong sonorant rules: 	dɔrxɑ
  EpenthesisAndStrongSonorants END (Proc): Out=	dɔrxɑ
Af. EpenthesisAndStrongSonorants: [dɔrxɑ]
  Diacritics START: In=	dɔrxɑ
  Diacritics END: Out=	dɔrxɑ
Af. Diacritics: [dɔrxɑ]
  FinalCleanup START: In=	dɔrxɑ
  FinalCleanup END: Out=	dɔrxɑ
Af. FinalCleanup: [dɔrxɑ]
dorcha          -> [dɔrxɑ]

--- Transcribing: [olc] ---
Af. MarkDigraphsAndVocalisationTriggers: [ˈolc]
  ConsonantResolution START (Proc): In=	ˈolc
  ConsonantResolution START (Proc): In=	ˈolc
    DBG (Consonan): Metathesis Sub-Stage START: 	ˈolc
    DBG (Consonan): Metathesis Check: c_base=	o	c_pal=	false	n_base=	l	n_pal=	false	at offset	2
    DBG (Consonan): Metathesis Check: c_base=	l	c_pal=	false	n_base=	c	n_pal=	false	at offset	3
    DBG (Consonan): Metathesis Check: c_base=	c	c_pal=	false	n_base=		n_pal=	false	at offset	4
    DBG (Consonan): Metathesis Sub-Stage END: 	ˈolc
    DBG (Consonan): After Pass 1 (markers): 	ˈolc
    DBG (Consonan): Pass 2: Checking '	c	' at phon_idx 	4	 -> ortho_s:	4	ortho_e:	4
    DBG (Consonan): Single cons rule: c_capture=	c	o_s=	4	o_e=	4
    DBG (DetQual): Word:	ˈolc	Cons seq:	c	s:	4	e:	4
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	o	Prev quality implication:	broad
    DBG (DetQual): Final determined quality for '	c	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	c	' with '	k	'
    DBG (Consonan): After Pass 2 (single chars): 	ˈolk
  ConsonantResolution END (Proc): Out=	ˈolk
Af. ConsonantResolution: [ˈolk]
  Stage4_0_SpecificOrthoToTempMarker START: In=	ˈolk
  Stage4_0_SpecificOrthoToTempMarker END: Out=	ˈolk
Af. Stage4_0_SpecificOrthoToTempMarker: [ˈolk]
  Stage4_0_1_Resolve_CH_Marker START: In=	ˈolk
  Stage4_0_1_Resolve_CH_Marker END: Out=	ˈolk
Af. Stage4_0_1_Resolve_CH_Marker: [ˈolk]
  Stage4_2_LongVowelsOrthoToTempMarker START: In=	ˈolk
  Stage4_2_LongVowelsOrthoToTempMarker END: Out=	ˈolk
Af. Stage4_2_LongVowelsOrthoToTempMarker: [ˈolk]
  Stage4_3_DiphthongsOrthoToTempMarker START: In=	ˈolk
  Stage4_3_DiphthongsOrthoToTempMarker END: Out=	ˈolk
Af. Stage4_3_DiphthongsOrthoToTempMarker: [ˈolk]
  Stage4_4_ResolveTempVowelMarkers START: In=	ˈolk
    DBG (Stage4_4): Iter.gsub Pass 1 ended. No changes in this pass. String remains: '	ˈolk	'
  Stage4_4_ResolveTempVowelMarkers END: Out=	ˈolk
Af. Stage4_4_ResolveTempVowelMarkers: [ˈolk]
  Stage4_5_ContextualAllophonyOnPhonetic START (Proc): In=	ˈolk
  Stage4_5_ContextualAllophonyOnPhonetic START: In=	ˈolk
    DBG (Stage4_5): Applying placeholder creation rules (ONCE)...
    DBG (Stage4_5): After placeholder creation: 	ˈolk
    DBG (Stage4_5): Applying core allophony rules (iteratively)...
    DBG (Stage4_5): Core Iter.gsub: Rule '	o	' APPLIED to '	ˈolk	' -> '	ˈɔlk	' (	1	x)
    DBG (Stage4_5): Core Iter.gsub Pass 1 ended. String changed from '	ˈolk	' to '	ˈɔlk	'
    DBG (Stage4_5): Core Iter.gsub Pass 2 ended. No changes in this pass. String remains: '	ˈɔlk	'
    DBG (Stage4_5): After core allophony rules: 	ˈɔlk
    DBG (Stage4_5): Applying placeholder restoration rules (ONCE)...
    DBG (Stage4_5): After placeholder restoration: 	ˈɔlk
    DBG (Stage4_5): Applying Connacht ɑu -> əu shift (ONCE)...
    DBG (Stage4_5): After Connacht ɑu->əu shift: 	ˈɔlk
    DBG (Stage4_5): Applying &TEMP_CONN_AU& -> əu shift (ONCE)...
    DBG (Stage4_5): After &TEMP_CONN_AU&->əu shift: 	ˈɔlk
  Stage4_5_ContextualAllophonyOnPhonetic END: Out=	ˈɔlk
Af. Stage4_5_ContextualAllophonyOnPhonetic: [ˈɔlk]
    DBG (Epenthes): is_likely_monosyllable_revised for '	ɔlk	' (orig: '	ˈɔlk	') count: 	1	 result: 	true
  EpenthesisAndStrongSonorants START (Proc): In=	ˈɔlk
  EpenthesisAndStrongSonorants START (Proc): In=	ˈɔlk
  apply_procedural_epenthesis START: In=	ˈɔlk
    DBG (Epenthes): Parsed units for epenthesis: 	ˈɔ(vowel) | l(nonpalatal) | k(nonpalatal)
    DBG (Epenthes): is_likely_monosyllable_revised for '	ɔlk	' (orig: '	ˈɔlk	') count: 	1	 result: 	true
    DBG (Epenthes): Checking V-C1-C2: 	ˈɔ	l	k	 | Cluster key: 	lk	 | C1 Qual: 	nonpalatal	 | C2 Qual: 	nonpalatal
    DBG (Epenthes): PROCEDURAL Epenthesis Triggered for: 	ˈɔ	l	k	 -> inserting 	ə
  apply_procedural_epenthesis END (modified): Out=	ˈɔlək
    DBG (Epenthes): After procedural epenthesis: 	ˈɔlək
    DBG (Epenthes): After strong sonorant rules: 	ˈɔlək
  EpenthesisAndStrongSonorants END (Proc): Out=	ˈɔlək
Af. EpenthesisAndStrongSonorants: [ˈɔlək]
  Diacritics START: In=	ˈɔlək
  Diacritics END: Out=	ˈɔlək
Af. Diacritics: [ˈɔlək]
  FinalCleanup START: In=	ˈɔlək
  FinalCleanup END: Out=	ˈɔlək
Af. FinalCleanup: [ˈɔlək]
olc             -> [ˈɔlək]

--- Transcribing: [oilc] ---
Af. MarkDigraphsAndVocalisationTriggers: [ˈoilc]
  ConsonantResolution START (Proc): In=	ˈoilc
  ConsonantResolution START (Proc): In=	ˈoilc
    DBG (Consonan): Metathesis Sub-Stage START: 	ˈoilc
    DBG (Consonan): Metathesis Check: c_base=	o	c_pal=	false	n_base=	i	n_pal=	false	at offset	2
    DBG (Consonan): Metathesis Check: c_base=	i	c_pal=	false	n_base=	l	n_pal=	false	at offset	3
    DBG (Consonan): Metathesis Check: c_base=	l	c_pal=	false	n_base=	c	n_pal=	false	at offset	4
    DBG (Consonan): Metathesis Check: c_base=	c	c_pal=	false	n_base=		n_pal=	false	at offset	5
    DBG (Consonan): Metathesis Sub-Stage END: 	ˈoilc
    DBG (Consonan): After Pass 1 (markers): 	ˈoilc
    DBG (Consonan): Pass 2: Checking '	c	' at phon_idx 	5	 -> ortho_s:	5	ortho_e:	5
    DBG (Consonan): Single cons rule: c_capture=	c	o_s=	5	o_e=	5
    DBG (DetQual): Word:	ˈoilc	Cons seq:	c	s:	5	e:	5
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	i	Prev quality implication:	slender
    DBG (DetQual): Final determined quality for '	c	': 	palatal
    DBG (Consonan): Pass 2: Replaced '	c	' with '	k'	'
    DBG (Consonan): After Pass 2 (single chars): 	ˈoilk'
  ConsonantResolution END (Proc): Out=	ˈoilk'
Af. ConsonantResolution: [ˈoilk']
  Stage4_0_SpecificOrthoToTempMarker START: In=	ˈoilk'
  Stage4_0_SpecificOrthoToTempMarker END: Out=	ˈoilk'
Af. Stage4_0_SpecificOrthoToTempMarker: [ˈoilk']
  Stage4_0_1_Resolve_CH_Marker START: In=	ˈoilk'
  Stage4_0_1_Resolve_CH_Marker END: Out=	ˈoilk'
Af. Stage4_0_1_Resolve_CH_Marker: [ˈoilk']
  Stage4_2_LongVowelsOrthoToTempMarker START: In=	ˈoilk'
  Stage4_2_LongVowelsOrthoToTempMarker END: Out=	ˈoilk'
Af. Stage4_2_LongVowelsOrthoToTempMarker: [ˈoilk']
  Stage4_3_DiphthongsOrthoToTempMarker START: In=	ˈoilk'
  Stage4_3_DiphthongsOrthoToTempMarker END: Out=	ˈ&OI_DIPH&lk'
Af. Stage4_3_DiphthongsOrthoToTempMarker: [ˈ&OI_DIPH&lk']
  Stage4_4_ResolveTempVowelMarkers START: In=	ˈ&OI_DIPH&lk'
    DBG (Stage4_4): Iter.gsub: Rule '	&OI_DIPH&([kgptdfbmnszrlLNRMçjɣŋhwcʃɟɾ]*')	' APPLIED to '	ˈ&OI_DIPH&lk'	' -> '	ˈɛlk'	' (	1	x)
    DBG (Stage4_4): Iter.gsub Pass 1 ended. String changed from '	ˈ&OI_DIPH&lk'	' to '	ˈɛlk'	'
    DBG (Stage4_4): Iter.gsub Pass 2 ended. No changes in this pass. String remains: '	ˈɛlk'	'
  Stage4_4_ResolveTempVowelMarkers END: Out=	ˈɛlk'
Af. Stage4_4_ResolveTempVowelMarkers: [ˈɛlk']
  Stage4_5_ContextualAllophonyOnPhonetic START (Proc): In=	ˈɛlk'
  Stage4_5_ContextualAllophonyOnPhonetic START: In=	ˈɛlk'
    DBG (Stage4_5): Applying placeholder creation rules (ONCE)...
    DBG (Stage4_5): After placeholder creation: 	ˈɛlk'
    DBG (Stage4_5): Applying core allophony rules (iteratively)...
    DBG (Stage4_5): Core Iter.gsub Pass 1 ended. No changes in this pass. String remains: '	ˈɛlk'	'
    DBG (Stage4_5): After core allophony rules: 	ˈɛlk'
    DBG (Stage4_5): Applying placeholder restoration rules (ONCE)...
    DBG (Stage4_5): After placeholder restoration: 	ˈɛlk'
    DBG (Stage4_5): Applying Connacht ɑu -> əu shift (ONCE)...
    DBG (Stage4_5): After Connacht ɑu->əu shift: 	ˈɛlk'
    DBG (Stage4_5): Applying &TEMP_CONN_AU& -> əu shift (ONCE)...
    DBG (Stage4_5): After &TEMP_CONN_AU&->əu shift: 	ˈɛlk'
  Stage4_5_ContextualAllophonyOnPhonetic END: Out=	ˈɛlk'
Af. Stage4_5_ContextualAllophonyOnPhonetic: [ˈɛlk']
    DBG (Epenthes): is_likely_monosyllable_revised for '	ɛlk'	' (orig: '	ˈɛlk'	') count: 	0	 result: 	false
  EpenthesisAndStrongSonorants START (Proc): In=	ˈɛlk'
  EpenthesisAndStrongSonorants START (Proc): In=	ˈɛlk'
  apply_procedural_epenthesis START: In=	ˈɛlk'
    DBG (Epenthes): Parsed units for epenthesis: 	ˈ(stress_mark) | ɛ(unknown_fallback) | l(nonpalatal) | k'(palatal)
    DBG (Epenthes): is_likely_monosyllable_revised for '	ɛlk'	' (orig: '	ˈɛlk'	') count: 	0	 result: 	false
  apply_procedural_epenthesis END (not monosyllable): Out=	ˈɛlk'
    DBG (Epenthes): After procedural epenthesis: 	ˈɛlk'
    DBG (Epenthes): After strong sonorant rules: 	ˈɛlk'
  EpenthesisAndStrongSonorants END (Proc): Out=	ˈɛlk'
Af. EpenthesisAndStrongSonorants: [ˈɛlk']
  Diacritics START: In=	ˈɛlk'
  Diacritics END: Out=	ˈɛlk'
Af. Diacritics: [ˈɛlk']
  FinalCleanup START: In=	ˈɛlk'
  FinalCleanup END: Out=	ˈɛlk'
Af. FinalCleanup: [ˈɛlk']
oilc            -> [ˈɛlk']

--- Transcribing: [dearc] ---
Af. MarkDigraphsAndVocalisationTriggers: [dearc]
  ConsonantResolution START (Proc): In=	dearc
  ConsonantResolution START (Proc): In=	dearc
    DBG (Consonan): Metathesis Sub-Stage START: 	dearc
    DBG (Consonan): Metathesis Check: c_base=	d	c_pal=	false	n_base=	e	n_pal=	false	at offset	1
    DBG (Consonan): Metathesis Check: c_base=	e	c_pal=	false	n_base=	a	n_pal=	false	at offset	2
    DBG (Consonan): Metathesis Check: c_base=	a	c_pal=	false	n_base=	r	n_pal=	false	at offset	3
    DBG (Consonan): Metathesis Check: c_base=	r	c_pal=	false	n_base=	c	n_pal=	false	at offset	4
    DBG (Consonan): Metathesis Check: c_base=	c	c_pal=	false	n_base=		n_pal=	false	at offset	5
    DBG (Consonan): Metathesis Sub-Stage END: 	dearc
    DBG (Consonan): After Pass 1 (markers): 	dearc
    DBG (Consonan): Pass 2: Checking '	d	' at phon_idx 	1	 -> ortho_s:	1	ortho_e:	1
    DBG (Consonan): Single cons rule: c_capture=	d	o_s=	1	o_e=	1
    DBG (DetQual): Word:	dearc	Cons seq:	d	s:	1	e:	1
    DBG (DetQual): Next relevant vowel char for quality:	e	Next quality implication:	slender
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	d	': 	palatal
    DBG (Consonan): Pass 2: Replaced '	d	' with '	d'	'
    DBG (Consonan): Pass 2: Checking '	r	' at phon_idx 	4	 -> ortho_s:	4	ortho_e:	4
    DBG (Consonan): Single cons rule: c_capture=	r	o_s=	4	o_e=	4
    DBG (DetQual): Word:	dearc	Cons seq:	r	s:	4	e:	4
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	e	Prev quality implication:	slender
    DBG (DetQual): Final determined quality for '	r	': 	palatal
    DBG (Consonan): Pass 2: Replaced '	r	' with '	r'	'
    DBG (Consonan): Pass 2: Checking '	c	' at phon_idx 	5	 -> ortho_s:	5	ortho_e:	5
    DBG (Consonan): Single cons rule: c_capture=	c	o_s=	5	o_e=	5
    DBG (DetQual): Word:	dearc	Cons seq:	c	s:	5	e:	5
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	a	Prev quality implication:	broad
    DBG (DetQual): Final determined quality for '	c	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	c	' with '	k	'
    DBG (Consonan): After Pass 2 (single chars): 	d'ear'k
  ConsonantResolution END (Proc): Out=	d'ear'k
Af. ConsonantResolution: [d'ear'k]
  Stage4_0_SpecificOrthoToTempMarker START: In=	d'ear'k
  Stage4_0_SpecificOrthoToTempMarker END: Out=	d'&EA_SLENDER_PRE_RPRIME&r'k
Af. Stage4_0_SpecificOrthoToTempMarker: [d'&EA_SLENDER_PRE_RPRIME&r'k]
  Stage4_0_1_Resolve_CH_Marker START: In=	d'&EA_SLENDER_PRE_RPRIME&r'k
  Stage4_0_1_Resolve_CH_Marker END: Out=	d'&EA_SLENDER_PRE_RPRIME&r'k
Af. Stage4_0_1_Resolve_CH_Marker: [d'&EA_SLENDER_PRE_RPRIME&r'k]
  Stage4_2_LongVowelsOrthoToTempMarker START: In=	d'&EA_SLENDER_PRE_RPRIME&r'k
  Stage4_2_LongVowelsOrthoToTempMarker END: Out=	d'&EA_SLENDER_PRE_RPRIME&r'k
Af. Stage4_2_LongVowelsOrthoToTempMarker: [d'&EA_SLENDER_PRE_RPRIME&r'k]
  Stage4_3_DiphthongsOrthoToTempMarker START: In=	d'&EA_SLENDER_PRE_RPRIME&r'k
  Stage4_3_DiphthongsOrthoToTempMarker END: Out=	d'&EA_SLENDER_PRE_RPRIME&r'k
Af. Stage4_3_DiphthongsOrthoToTempMarker: [d'&EA_SLENDER_PRE_RPRIME&r'k]
  Stage4_4_ResolveTempVowelMarkers START: In=	d'&EA_SLENDER_PRE_RPRIME&r'k
    DBG (Stage4_4): Iter.gsub: Rule '	&EA_SLENDER_PRE_RPRIME&	' APPLIED to '	d'&EA_SLENDER_PRE_RPRIME&r'k	' -> '	d'ær'k	' (	1	x)
    DBG (Stage4_4): Iter.gsub Pass 1 ended. String changed from '	d'&EA_SLENDER_PRE_RPRIME&r'k	' to '	d'ær'k	'
    DBG (Stage4_4): Iter.gsub Pass 2 ended. No changes in this pass. String remains: '	d'ær'k	'
  Stage4_4_ResolveTempVowelMarkers END: Out=	d'ær'k
Af. Stage4_4_ResolveTempVowelMarkers: [d'ær'k]
  Stage4_5_ContextualAllophonyOnPhonetic START (Proc): In=	d'ær'k
  Stage4_5_ContextualAllophonyOnPhonetic START: In=	d'ær'k
    DBG (Stage4_5): Applying placeholder creation rules (ONCE)...
    DBG (Stage4_5): After placeholder creation: 	d'ær'k
    DBG (Stage4_5): Applying core allophony rules (iteratively)...
    DBG (Stage4_5): Core Iter.gsub Pass 1 ended. No changes in this pass. String remains: '	d'ær'k	'
    DBG (Stage4_5): After core allophony rules: 	d'ær'k
    DBG (Stage4_5): Applying placeholder restoration rules (ONCE)...
    DBG (Stage4_5): After placeholder restoration: 	d'ær'k
    DBG (Stage4_5): Applying Connacht ɑu -> əu shift (ONCE)...
    DBG (Stage4_5): After Connacht ɑu->əu shift: 	d'ær'k
    DBG (Stage4_5): Applying &TEMP_CONN_AU& -> əu shift (ONCE)...
    DBG (Stage4_5): After &TEMP_CONN_AU&->əu shift: 	d'ær'k
  Stage4_5_ContextualAllophonyOnPhonetic END: Out=	d'ær'k
Af. Stage4_5_ContextualAllophonyOnPhonetic: [d'ær'k]
    DBG (Epenthes): is_likely_monosyllable_revised for '	d'ær'k	' (orig: '	d'ær'k	') count: 	1	 result: 	true
  EpenthesisAndStrongSonorants START (Proc): In=	d'ær'k
  EpenthesisAndStrongSonorants START (Proc): In=	d'ær'k
  apply_procedural_epenthesis START: In=	d'ær'k
    DBG (Epenthes): Parsed units for epenthesis: 	d'(palatal) | æ(vowel) | r'(palatal) | k(nonpalatal)
    DBG (Epenthes): is_likely_monosyllable_revised for '	d'ær'k	' (orig: '	d'ær'k	') count: 	1	 result: 	true
    DBG (Epenthes): Checking V-C1-C2: 	æ	r'	k	 | Cluster key: 	rk	 | C1 Qual: 	palatal	 | C2 Qual: 	nonpalatal
  apply_procedural_epenthesis END (no change): Out=	d'ær'k
    DBG (Epenthes): After procedural epenthesis: 	d'ær'k
    DBG (Epenthes): After strong sonorant rules: 	d'ær'k
  EpenthesisAndStrongSonorants END (Proc): Out=	d'ær'k
Af. EpenthesisAndStrongSonorants: [d'ær'k]
  Diacritics START: In=	d'ær'k
  Diacritics END: Out=	d'ær'k
Af. Diacritics: [d'ær'k]
  FinalCleanup START: In=	d'ær'k
  FinalCleanup END: Out=	d'ær'k
Af. FinalCleanup: [d'ær'k]
dearc           -> [d'ær'k]

--- Transcribing: [feirc] ---
Af. MarkDigraphsAndVocalisationTriggers: [feirc]
  ConsonantResolution START (Proc): In=	feirc
  ConsonantResolution START (Proc): In=	feirc
    DBG (Consonan): Metathesis Sub-Stage START: 	feirc
    DBG (Consonan): Metathesis Check: c_base=	f	c_pal=	false	n_base=	e	n_pal=	false	at offset	1
    DBG (Consonan): Metathesis Check: c_base=	e	c_pal=	false	n_base=	i	n_pal=	false	at offset	2
    DBG (Consonan): Metathesis Check: c_base=	i	c_pal=	false	n_base=	r	n_pal=	false	at offset	3
    DBG (Consonan): Metathesis Check: c_base=	r	c_pal=	false	n_base=	c	n_pal=	false	at offset	4
    DBG (Consonan): Metathesis Check: c_base=	c	c_pal=	false	n_base=		n_pal=	false	at offset	5
    DBG (Consonan): Metathesis Sub-Stage END: 	feirc
    DBG (Consonan): After Pass 1 (markers): 	feirc
    DBG (Consonan): Pass 2: Checking '	f	' at phon_idx 	1	 -> ortho_s:	1	ortho_e:	1
    DBG (Consonan): Single cons rule: c_capture=	f	o_s=	1	o_e=	1
    DBG (DetQual): Word:	feirc	Cons seq:	f	s:	1	e:	1
    DBG (DetQual): Next relevant vowel char for quality:	e	Next quality implication:	slender
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	f	': 	palatal
    DBG (Consonan): Pass 2: Replaced '	f	' with '	f'	'
    DBG (Consonan): Pass 2: Checking '	r	' at phon_idx 	4	 -> ortho_s:	4	ortho_e:	4
    DBG (Consonan): Single cons rule: c_capture=	r	o_s=	4	o_e=	4
    DBG (DetQual): Word:	feirc	Cons seq:	r	s:	4	e:	4
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	i	Prev quality implication:	slender
    DBG (DetQual): Final determined quality for '	r	': 	palatal
    DBG (Consonan): Pass 2: Replaced '	r	' with '	r'	'
    DBG (Consonan): Pass 2: Checking '	c	' at phon_idx 	5	 -> ortho_s:	5	ortho_e:	5
    DBG (Consonan): Single cons rule: c_capture=	c	o_s=	5	o_e=	5
    DBG (DetQual): Word:	feirc	Cons seq:	c	s:	5	e:	5
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	i	Prev quality implication:	slender
    DBG (DetQual): Final determined quality for '	c	': 	palatal
    DBG (Consonan): Pass 2: Replaced '	c	' with '	k'	'
    DBG (Consonan): After Pass 2 (single chars): 	f'eir'k'
  ConsonantResolution END (Proc): Out=	f'eir'k'
Af. ConsonantResolution: [f'eir'k']
  Stage4_0_SpecificOrthoToTempMarker START: In=	f'eir'k'
  Stage4_0_SpecificOrthoToTempMarker END: Out=	f'eir'k'
Af. Stage4_0_SpecificOrthoToTempMarker: [f'eir'k']
  Stage4_0_1_Resolve_CH_Marker START: In=	f'eir'k'
  Stage4_0_1_Resolve_CH_Marker END: Out=	f'eir'k'
Af. Stage4_0_1_Resolve_CH_Marker: [f'eir'k']
  Stage4_2_LongVowelsOrthoToTempMarker START: In=	f'eir'k'
  Stage4_2_LongVowelsOrthoToTempMarker END: Out=	f'eir'k'
Af. Stage4_2_LongVowelsOrthoToTempMarker: [f'eir'k']
  Stage4_3_DiphthongsOrthoToTempMarker START: In=	f'eir'k'
  Stage4_3_DiphthongsOrthoToTempMarker END: Out=	f'&EI_DIPH&r'k'
Af. Stage4_3_DiphthongsOrthoToTempMarker: [f'&EI_DIPH&r'k']
  Stage4_4_ResolveTempVowelMarkers START: In=	f'&EI_DIPH&r'k'
    DBG (Stage4_4): Iter.gsub: Rule '	&EI_DIPH&	' APPLIED to '	f'&EI_DIPH&r'k'	' -> '	f'er'k'	' (	1	x)
    DBG (Stage4_4): Iter.gsub Pass 1 ended. String changed from '	f'&EI_DIPH&r'k'	' to '	f'er'k'	'
    DBG (Stage4_4): Iter.gsub Pass 2 ended. No changes in this pass. String remains: '	f'er'k'	'
  Stage4_4_ResolveTempVowelMarkers END: Out=	f'er'k'
Af. Stage4_4_ResolveTempVowelMarkers: [f'er'k']
  Stage4_5_ContextualAllophonyOnPhonetic START (Proc): In=	f'er'k'
  Stage4_5_ContextualAllophonyOnPhonetic START: In=	f'er'k'
    DBG (Stage4_5): Applying placeholder creation rules (ONCE)...
    DBG (Stage4_5): After placeholder creation: 	f'er'k'
    DBG (Stage4_5): Applying core allophony rules (iteratively)...
    DBG (Stage4_5): Core Iter.gsub Pass 1 ended. No changes in this pass. String remains: '	f'er'k'	'
    DBG (Stage4_5): After core allophony rules: 	f'er'k'
    DBG (Stage4_5): Applying placeholder restoration rules (ONCE)...
    DBG (Stage4_5): After placeholder restoration: 	f'er'k'
    DBG (Stage4_5): Applying Connacht ɑu -> əu shift (ONCE)...
    DBG (Stage4_5): After Connacht ɑu->əu shift: 	f'er'k'
    DBG (Stage4_5): Applying &TEMP_CONN_AU& -> əu shift (ONCE)...
    DBG (Stage4_5): After &TEMP_CONN_AU&->əu shift: 	f'er'k'
  Stage4_5_ContextualAllophonyOnPhonetic END: Out=	f'er'k'
Af. Stage4_5_ContextualAllophonyOnPhonetic: [f'er'k']
    DBG (Epenthes): is_likely_monosyllable_revised for '	f'er'k'	' (orig: '	f'er'k'	') count: 	1	 result: 	true
  EpenthesisAndStrongSonorants START (Proc): In=	f'er'k'
  EpenthesisAndStrongSonorants START (Proc): In=	f'er'k'
  apply_procedural_epenthesis START: In=	f'er'k'
    DBG (Epenthes): Parsed units for epenthesis: 	f'(palatal) | e(vowel) | r'(palatal) | k'(palatal)
    DBG (Epenthes): is_likely_monosyllable_revised for '	f'er'k'	' (orig: '	f'er'k'	') count: 	1	 result: 	true
    DBG (Epenthes): Checking V-C1-C2: 	e	r'	k'	 | Cluster key: 	rk	 | C1 Qual: 	palatal	 | C2 Qual: 	palatal
    DBG (Epenthes): PROCEDURAL Epenthesis Triggered for: 	e	r'	k'	 -> inserting 	i
  apply_procedural_epenthesis END (modified): Out=	f'er'ik'
    DBG (Epenthes): After procedural epenthesis: 	f'er'ik'
    DBG (Epenthes): After strong sonorant rules: 	f'er'ik'
  EpenthesisAndStrongSonorants END (Proc): Out=	f'er'ik'
Af. EpenthesisAndStrongSonorants: [f'er'ik']
  Diacritics START: In=	f'er'ik'
  Diacritics END: Out=	f'er'ik'
Af. Diacritics: [f'er'ik']
  FinalCleanup START: In=	f'er'ik'
  FinalCleanup END: Out=	f'er'ik'
Af. FinalCleanup: [f'er'ik']
feirc           -> [f'er'ik']

--- Transcribing: [balbh] ---
Af. MarkDigraphsAndVocalisationTriggers: [bal_BH_]
  ConsonantResolution START (Proc): In=	bal_BH_
  ConsonantResolution START (Proc): In=	bal_BH_
    DBG (Consonan): Metathesis Sub-Stage START: 	bal_BH_
    DBG (Consonan): Metathesis Check: c_base=	b	c_pal=	false	n_base=	a	n_pal=	false	at offset	1
    DBG (Consonan): Metathesis Check: c_base=	a	c_pal=	false	n_base=	l	n_pal=	false	at offset	2
    DBG (Consonan): Metathesis Check: c_base=	l	c_pal=	false	n_base=	_	n_pal=	false	at offset	3
    DBG (Consonan): Metathesis Check: c_base=	_	c_pal=	false	n_base=	B	n_pal=	false	at offset	4
    DBG (Consonan): Metathesis Check: c_base=	B	c_pal=	false	n_base=	H	n_pal=	false	at offset	5
    DBG (Consonan): Metathesis Check: c_base=	H	c_pal=	false	n_base=	_	n_pal=	false	at offset	6
    DBG (Consonan): Metathesis Check: c_base=	_	c_pal=	false	n_base=		n_pal=	false	at offset	7
    DBG (Consonan): Metathesis Sub-Stage END: 	bal_BH_
    DBG (DetQual): Word:	balbh	Cons seq:	bh	s:	4	e:	5
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	a	Prev quality implication:	broad
    DBG (DetQual): Final determined quality for '	bh	': 	nonpalatal
    DBG (Consonan): After Pass 1 (markers): 	balv
    DBG (Consonan): Pass 2: Checking '	b	' at phon_idx 	1	 -> ortho_s:	1	ortho_e:	1
    DBG (Consonan): Single cons rule: c_capture=	b	o_s=	1	o_e=	1
    DBG (DetQual): Word:	balbh	Cons seq:	b	s:	1	e:	1
    DBG (DetQual): Next relevant vowel char for quality:	a	Next quality implication:	broad
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	b	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	b	' with '	b	'
    DBG (Consonan): After Pass 2 (single chars): 	balv
  ConsonantResolution END (Proc): Out=	balv
Af. ConsonantResolution: [balv]
  Stage4_0_SpecificOrthoToTempMarker START: In=	balv
  Stage4_0_SpecificOrthoToTempMarker END: Out=	balv
Af. Stage4_0_SpecificOrthoToTempMarker: [balv]
  Stage4_0_1_Resolve_CH_Marker START: In=	balv
  Stage4_0_1_Resolve_CH_Marker END: Out=	balv
Af. Stage4_0_1_Resolve_CH_Marker: [balv]
  Stage4_2_LongVowelsOrthoToTempMarker START: In=	balv
  Stage4_2_LongVowelsOrthoToTempMarker END: Out=	balv
Af. Stage4_2_LongVowelsOrthoToTempMarker: [balv]
  Stage4_3_DiphthongsOrthoToTempMarker START: In=	balv
  Stage4_3_DiphthongsOrthoToTempMarker END: Out=	balv
Af. Stage4_3_DiphthongsOrthoToTempMarker: [balv]
  Stage4_4_ResolveTempVowelMarkers START: In=	balv
    DBG (Stage4_4): Iter.gsub Pass 1 ended. No changes in this pass. String remains: '	balv	'
  Stage4_4_ResolveTempVowelMarkers END: Out=	balv
Af. Stage4_4_ResolveTempVowelMarkers: [balv]
  Stage4_5_ContextualAllophonyOnPhonetic START (Proc): In=	balv
  Stage4_5_ContextualAllophonyOnPhonetic START: In=	balv
    DBG (Stage4_5): Applying placeholder creation rules (ONCE)...
    DBG (Stage4_5): After placeholder creation: 	balv
    DBG (Stage4_5): Applying core allophony rules (iteratively)...
    DBG (Stage4_5): Core Iter.gsub: Rule '	a	' APPLIED to '	balv	' -> '	bɑlv	' (	1	x)
    DBG (Stage4_5): Core Iter.gsub Pass 1 ended. String changed from '	balv	' to '	bɑlv	'
    DBG (Stage4_5): Core Iter.gsub Pass 2 ended. No changes in this pass. String remains: '	bɑlv	'
    DBG (Stage4_5): After core allophony rules: 	bɑlv
    DBG (Stage4_5): Applying placeholder restoration rules (ONCE)...
    DBG (Stage4_5): After placeholder restoration: 	bɑlv
    DBG (Stage4_5): Applying Connacht ɑu -> əu shift (ONCE)...
    DBG (Stage4_5): After Connacht ɑu->əu shift: 	bɑlv
    DBG (Stage4_5): Applying &TEMP_CONN_AU& -> əu shift (ONCE)...
    DBG (Stage4_5): After &TEMP_CONN_AU&->əu shift: 	bɑlv
  Stage4_5_ContextualAllophonyOnPhonetic END: Out=	bɑlv
Af. Stage4_5_ContextualAllophonyOnPhonetic: [bɑlv]
    DBG (Epenthes): is_likely_monosyllable_revised for '	bɑlv	' (orig: '	bɑlv	') count: 	0	 result: 	false
  EpenthesisAndStrongSonorants START (Proc): In=	bɑlv
  EpenthesisAndStrongSonorants START (Proc): In=	bɑlv
  apply_procedural_epenthesis START: In=	bɑlv
    DBG (Epenthes): Parsed units for epenthesis: 	b(nonpalatal) | ɑ(vowel) | l(nonpalatal) | v(unknown)
    DBG (Epenthes): is_likely_monosyllable_revised for '	bɑlv	' (orig: '	bɑlv	') count: 	0	 result: 	false
  apply_procedural_epenthesis END (not monosyllable): Out=	bɑlv
    DBG (Epenthes): After procedural epenthesis: 	bɑlv
    DBG (Epenthes): After strong sonorant rules: 	bɑlv
  EpenthesisAndStrongSonorants END (Proc): Out=	bɑlv
Af. EpenthesisAndStrongSonorants: [bɑlv]
  Diacritics START: In=	bɑlv
  Diacritics END: Out=	bɑlv
Af. Diacritics: [bɑlv]
  FinalCleanup START: In=	bɑlv
  FinalCleanup END: Out=	bɑlv
Af. FinalCleanup: [bɑlv]
balbh           -> [bɑlv]

--- Transcribing: [garbh] ---
Af. MarkDigraphsAndVocalisationTriggers: [gar_BH_]
  ConsonantResolution START (Proc): In=	gar_BH_
  ConsonantResolution START (Proc): In=	gar_BH_
    DBG (Consonan): Metathesis Sub-Stage START: 	gar_BH_
    DBG (Consonan): Metathesis Check: c_base=	g	c_pal=	false	n_base=	a	n_pal=	false	at offset	1
    DBG (Consonan): Metathesis Check: c_base=	a	c_pal=	false	n_base=	r	n_pal=	false	at offset	2
    DBG (Consonan): Metathesis Check: c_base=	r	c_pal=	false	n_base=	_	n_pal=	false	at offset	3
    DBG (Consonan): Metathesis Check: c_base=	_	c_pal=	false	n_base=	B	n_pal=	false	at offset	4
    DBG (Consonan): Metathesis Check: c_base=	B	c_pal=	false	n_base=	H	n_pal=	false	at offset	5
    DBG (Consonan): Metathesis Check: c_base=	H	c_pal=	false	n_base=	_	n_pal=	false	at offset	6
    DBG (Consonan): Metathesis Check: c_base=	_	c_pal=	false	n_base=		n_pal=	false	at offset	7
    DBG (Consonan): Metathesis Sub-Stage END: 	gar_BH_
    DBG (DetQual): Word:	garbh	Cons seq:	bh	s:	4	e:	5
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	a	Prev quality implication:	broad
    DBG (DetQual): Final determined quality for '	bh	': 	nonpalatal
    DBG (Consonan): After Pass 1 (markers): 	garv
    DBG (Consonan): Pass 2: Checking '	g	' at phon_idx 	1	 -> ortho_s:	1	ortho_e:	1
    DBG (Consonan): Single cons rule: c_capture=	g	o_s=	1	o_e=	1
    DBG (DetQual): Word:	garbh	Cons seq:	g	s:	1	e:	1
    DBG (DetQual): Next relevant vowel char for quality:	a	Next quality implication:	broad
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	g	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	g	' with '	g	'
    DBG (Consonan): Pass 2: Checking '	r	' at phon_idx 	3	 -> ortho_s:	3	ortho_e:	3
    DBG (Consonan): Single cons rule: c_capture=	r	o_s=	3	o_e=	3
    DBG (DetQual): Word:	garbh	Cons seq:	r	s:	3	e:	3
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	a	Prev quality implication:	broad
    DBG (DetQual): Final determined quality for '	r	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	r	' with '	r	'
    DBG (Consonan): After Pass 2 (single chars): 	garv
  ConsonantResolution END (Proc): Out=	garv
Af. ConsonantResolution: [garv]
  Stage4_0_SpecificOrthoToTempMarker START: In=	garv
  Stage4_0_SpecificOrthoToTempMarker END: Out=	garv
Af. Stage4_0_SpecificOrthoToTempMarker: [garv]
  Stage4_0_1_Resolve_CH_Marker START: In=	garv
  Stage4_0_1_Resolve_CH_Marker END: Out=	garv
Af. Stage4_0_1_Resolve_CH_Marker: [garv]
  Stage4_2_LongVowelsOrthoToTempMarker START: In=	garv
  Stage4_2_LongVowelsOrthoToTempMarker END: Out=	garv
Af. Stage4_2_LongVowelsOrthoToTempMarker: [garv]
  Stage4_3_DiphthongsOrthoToTempMarker START: In=	garv
  Stage4_3_DiphthongsOrthoToTempMarker END: Out=	garv
Af. Stage4_3_DiphthongsOrthoToTempMarker: [garv]
  Stage4_4_ResolveTempVowelMarkers START: In=	garv
    DBG (Stage4_4): Iter.gsub Pass 1 ended. No changes in this pass. String remains: '	garv	'
  Stage4_4_ResolveTempVowelMarkers END: Out=	garv
Af. Stage4_4_ResolveTempVowelMarkers: [garv]
  Stage4_5_ContextualAllophonyOnPhonetic START (Proc): In=	garv
  Stage4_5_ContextualAllophonyOnPhonetic START: In=	garv
    DBG (Stage4_5): Applying placeholder creation rules (ONCE)...
    DBG (Stage4_5): After placeholder creation: 	garv
    DBG (Stage4_5): Applying core allophony rules (iteratively)...
    DBG (Stage4_5): Core Iter.gsub: Rule '	a	' APPLIED to '	garv	' -> '	gɑrv	' (	1	x)
    DBG (Stage4_5): Core Iter.gsub Pass 1 ended. String changed from '	garv	' to '	gɑrv	'
    DBG (Stage4_5): Core Iter.gsub Pass 2 ended. No changes in this pass. String remains: '	gɑrv	'
    DBG (Stage4_5): After core allophony rules: 	gɑrv
    DBG (Stage4_5): Applying placeholder restoration rules (ONCE)...
    DBG (Stage4_5): After placeholder restoration: 	gɑrv
    DBG (Stage4_5): Applying Connacht ɑu -> əu shift (ONCE)...
    DBG (Stage4_5): After Connacht ɑu->əu shift: 	gɑrv
    DBG (Stage4_5): Applying &TEMP_CONN_AU& -> əu shift (ONCE)...
    DBG (Stage4_5): After &TEMP_CONN_AU&->əu shift: 	gɑrv
  Stage4_5_ContextualAllophonyOnPhonetic END: Out=	gɑrv
Af. Stage4_5_ContextualAllophonyOnPhonetic: [gɑrv]
    DBG (Epenthes): is_likely_monosyllable_revised for '	gɑrv	' (orig: '	gɑrv	') count: 	0	 result: 	false
  EpenthesisAndStrongSonorants START (Proc): In=	gɑrv
  EpenthesisAndStrongSonorants START (Proc): In=	gɑrv
  apply_procedural_epenthesis START: In=	gɑrv
    DBG (Epenthes): Parsed units for epenthesis: 	g(nonpalatal) | ɑ(vowel) | r(nonpalatal) | v(unknown)
    DBG (Epenthes): is_likely_monosyllable_revised for '	gɑrv	' (orig: '	gɑrv	') count: 	0	 result: 	false
  apply_procedural_epenthesis END (not monosyllable): Out=	gɑrv
    DBG (Epenthes): After procedural epenthesis: 	gɑrv
    DBG (Epenthes): After strong sonorant rules: 	gɑrv
  EpenthesisAndStrongSonorants END (Proc): Out=	gɑrv
Af. EpenthesisAndStrongSonorants: [gɑrv]
  Diacritics START: In=	gɑrv
  Diacritics END: Out=	gɑrv
Af. Diacritics: [gɑrv]
  FinalCleanup START: In=	gɑrv
  FinalCleanup END: Out=	gɑrv
Af. FinalCleanup: [gɑrv]
garbh           -> [gɑrv]

--- Transcribing: [gorm] ---
Af. MarkDigraphsAndVocalisationTriggers: [gorm]
  ConsonantResolution START (Proc): In=	gorm
  ConsonantResolution START (Proc): In=	gorm
    DBG (Consonan): Metathesis Sub-Stage START: 	gorm
    DBG (Consonan): Metathesis Check: c_base=	g	c_pal=	false	n_base=	o	n_pal=	false	at offset	1
    DBG (Consonan): Metathesis Check: c_base=	o	c_pal=	false	n_base=	r	n_pal=	false	at offset	2
    DBG (Consonan): Metathesis Check: c_base=	r	c_pal=	false	n_base=	m	n_pal=	false	at offset	3
    DBG (Consonan): Metathesis Check: c_base=	m	c_pal=	false	n_base=		n_pal=	false	at offset	4
    DBG (Consonan): Metathesis Sub-Stage END: 	gorm
    DBG (Consonan): After Pass 1 (markers): 	gorm
    DBG (Consonan): Pass 2: Checking '	g	' at phon_idx 	1	 -> ortho_s:	1	ortho_e:	1
    DBG (Consonan): Single cons rule: c_capture=	g	o_s=	1	o_e=	1
    DBG (DetQual): Word:	gorm	Cons seq:	g	s:	1	e:	1
    DBG (DetQual): Next relevant vowel char for quality:	o	Next quality implication:	broad
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	g	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	g	' with '	g	'
    DBG (Consonan): Pass 2: Checking '	r	' at phon_idx 	3	 -> ortho_s:	3	ortho_e:	3
    DBG (Consonan): Single cons rule: c_capture=	r	o_s=	3	o_e=	3
    DBG (DetQual): Word:	gorm	Cons seq:	r	s:	3	e:	3
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	o	Prev quality implication:	broad
    DBG (DetQual): Final determined quality for '	r	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	r	' with '	r	'
    DBG (Consonan): Pass 2: Checking '	m	' at phon_idx 	4	 -> ortho_s:	4	ortho_e:	4
    DBG (Consonan): Single cons rule: c_capture=	m	o_s=	4	o_e=	4
    DBG (DetQual): Word:	gorm	Cons seq:	m	s:	4	e:	4
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	o	Prev quality implication:	broad
    DBG (DetQual): Final determined quality for '	m	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	m	' with '	m	'
    DBG (Consonan): After Pass 2 (single chars): 	gorm
  ConsonantResolution END (Proc): Out=	gorm
Af. ConsonantResolution: [gorm]
  Stage4_0_SpecificOrthoToTempMarker START: In=	gorm
  Stage4_0_SpecificOrthoToTempMarker END: Out=	gorm
Af. Stage4_0_SpecificOrthoToTempMarker: [gorm]
  Stage4_0_1_Resolve_CH_Marker START: In=	gorm
  Stage4_0_1_Resolve_CH_Marker END: Out=	gorm
Af. Stage4_0_1_Resolve_CH_Marker: [gorm]
  Stage4_2_LongVowelsOrthoToTempMarker START: In=	gorm
  Stage4_2_LongVowelsOrthoToTempMarker END: Out=	gorm
Af. Stage4_2_LongVowelsOrthoToTempMarker: [gorm]
  Stage4_3_DiphthongsOrthoToTempMarker START: In=	gorm
  Stage4_3_DiphthongsOrthoToTempMarker END: Out=	gorm
Af. Stage4_3_DiphthongsOrthoToTempMarker: [gorm]
  Stage4_4_ResolveTempVowelMarkers START: In=	gorm
    DBG (Stage4_4): Iter.gsub Pass 1 ended. No changes in this pass. String remains: '	gorm	'
  Stage4_4_ResolveTempVowelMarkers END: Out=	gorm
Af. Stage4_4_ResolveTempVowelMarkers: [gorm]
  Stage4_5_ContextualAllophonyOnPhonetic START (Proc): In=	gorm
  Stage4_5_ContextualAllophonyOnPhonetic START: In=	gorm
    DBG (Stage4_5): Applying placeholder creation rules (ONCE)...
    DBG (Stage4_5): After placeholder creation: 	gorm
    DBG (Stage4_5): Applying core allophony rules (iteratively)...
    DBG (Stage4_5): Core Iter.gsub: Rule '	o	' APPLIED to '	gorm	' -> '	gɔrm	' (	1	x)
    DBG (Stage4_5): Core Iter.gsub Pass 1 ended. String changed from '	gorm	' to '	gɔrm	'
    DBG (Stage4_5): Core Iter.gsub Pass 2 ended. No changes in this pass. String remains: '	gɔrm	'
    DBG (Stage4_5): After core allophony rules: 	gɔrm
    DBG (Stage4_5): Applying placeholder restoration rules (ONCE)...
    DBG (Stage4_5): After placeholder restoration: 	gɔrm
    DBG (Stage4_5): Applying Connacht ɑu -> əu shift (ONCE)...
    DBG (Stage4_5): After Connacht ɑu->əu shift: 	gɔrm
    DBG (Stage4_5): Applying &TEMP_CONN_AU& -> əu shift (ONCE)...
    DBG (Stage4_5): After &TEMP_CONN_AU&->əu shift: 	gɔrm
  Stage4_5_ContextualAllophonyOnPhonetic END: Out=	gɔrm
Af. Stage4_5_ContextualAllophonyOnPhonetic: [gɔrm]
    DBG (Epenthes): is_likely_monosyllable_revised for '	gɔrm	' (orig: '	gɔrm	') count: 	1	 result: 	true
  EpenthesisAndStrongSonorants START (Proc): In=	gɔrm
  EpenthesisAndStrongSonorants START (Proc): In=	gɔrm
  apply_procedural_epenthesis START: In=	gɔrm
    DBG (Epenthes): Parsed units for epenthesis: 	g(nonpalatal) | ɔ(vowel) | r(nonpalatal) | m(nonpalatal)
    DBG (Epenthes): is_likely_monosyllable_revised for '	gɔrm	' (orig: '	gɔrm	') count: 	1	 result: 	true
  apply_procedural_epenthesis END (no change): Out=	gɔrm
    DBG (Epenthes): After procedural epenthesis: 	gɔrm
    DBG (Epenthes): After strong sonorant rules: 	gɔrm
  EpenthesisAndStrongSonorants END (Proc): Out=	gɔrm
Af. EpenthesisAndStrongSonorants: [gɔrm]
  Diacritics START: In=	gɔrm
  Diacritics END: Out=	gɔrm
Af. Diacritics: [gɔrm]
  FinalCleanup START: In=	gɔrm
  FinalCleanup END: Out=	gɔrm
Af. FinalCleanup: [gɔrm]
gorm            -> [gɔrm]

--- Transcribing: [bolg] ---
Af. MarkDigraphsAndVocalisationTriggers: [bolg]
  ConsonantResolution START (Proc): In=	bolg
  ConsonantResolution START (Proc): In=	bolg
    DBG (Consonan): Metathesis Sub-Stage START: 	bolg
    DBG (Consonan): Metathesis Check: c_base=	b	c_pal=	false	n_base=	o	n_pal=	false	at offset	1
    DBG (Consonan): Metathesis Check: c_base=	o	c_pal=	false	n_base=	l	n_pal=	false	at offset	2
    DBG (Consonan): Metathesis Check: c_base=	l	c_pal=	false	n_base=	g	n_pal=	false	at offset	3
    DBG (Consonan): Metathesis Check: c_base=	g	c_pal=	false	n_base=		n_pal=	false	at offset	4
    DBG (Consonan): Metathesis Sub-Stage END: 	bolg
    DBG (Consonan): After Pass 1 (markers): 	bolg
    DBG (Consonan): Pass 2: Checking '	b	' at phon_idx 	1	 -> ortho_s:	1	ortho_e:	1
    DBG (Consonan): Single cons rule: c_capture=	b	o_s=	1	o_e=	1
    DBG (DetQual): Word:	bolg	Cons seq:	b	s:	1	e:	1
    DBG (DetQual): Next relevant vowel char for quality:	o	Next quality implication:	broad
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	b	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	b	' with '	b	'
    DBG (Consonan): Pass 2: Checking '	g	' at phon_idx 	4	 -> ortho_s:	4	ortho_e:	4
    DBG (Consonan): Single cons rule: c_capture=	g	o_s=	4	o_e=	4
    DBG (DetQual): Word:	bolg	Cons seq:	g	s:	4	e:	4
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	o	Prev quality implication:	broad
    DBG (DetQual): Final determined quality for '	g	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	g	' with '	g	'
    DBG (Consonan): After Pass 2 (single chars): 	bolg
  ConsonantResolution END (Proc): Out=	bolg
Af. ConsonantResolution: [bolg]
  Stage4_0_SpecificOrthoToTempMarker START: In=	bolg
  Stage4_0_SpecificOrthoToTempMarker END: Out=	bolg
Af. Stage4_0_SpecificOrthoToTempMarker: [bolg]
  Stage4_0_1_Resolve_CH_Marker START: In=	bolg
  Stage4_0_1_Resolve_CH_Marker END: Out=	bolg
Af. Stage4_0_1_Resolve_CH_Marker: [bolg]
  Stage4_2_LongVowelsOrthoToTempMarker START: In=	bolg
  Stage4_2_LongVowelsOrthoToTempMarker END: Out=	bolg
Af. Stage4_2_LongVowelsOrthoToTempMarker: [bolg]
  Stage4_3_DiphthongsOrthoToTempMarker START: In=	bolg
  Stage4_3_DiphthongsOrthoToTempMarker END: Out=	bolg
Af. Stage4_3_DiphthongsOrthoToTempMarker: [bolg]
  Stage4_4_ResolveTempVowelMarkers START: In=	bolg
    DBG (Stage4_4): Iter.gsub Pass 1 ended. No changes in this pass. String remains: '	bolg	'
  Stage4_4_ResolveTempVowelMarkers END: Out=	bolg
Af. Stage4_4_ResolveTempVowelMarkers: [bolg]
  Stage4_5_ContextualAllophonyOnPhonetic START (Proc): In=	bolg
  Stage4_5_ContextualAllophonyOnPhonetic START: In=	bolg
    DBG (Stage4_5): Applying placeholder creation rules (ONCE)...
    DBG (Stage4_5): After placeholder creation: 	bolg
    DBG (Stage4_5): Applying core allophony rules (iteratively)...
    DBG (Stage4_5): Core Iter.gsub: Rule '	o	' APPLIED to '	bolg	' -> '	bɔlg	' (	1	x)
    DBG (Stage4_5): Core Iter.gsub Pass 1 ended. String changed from '	bolg	' to '	bɔlg	'
    DBG (Stage4_5): Core Iter.gsub Pass 2 ended. No changes in this pass. String remains: '	bɔlg	'
    DBG (Stage4_5): After core allophony rules: 	bɔlg
    DBG (Stage4_5): Applying placeholder restoration rules (ONCE)...
    DBG (Stage4_5): After placeholder restoration: 	bɔlg
    DBG (Stage4_5): Applying Connacht ɑu -> əu shift (ONCE)...
    DBG (Stage4_5): After Connacht ɑu->əu shift: 	bɔlg
    DBG (Stage4_5): Applying &TEMP_CONN_AU& -> əu shift (ONCE)...
    DBG (Stage4_5): After &TEMP_CONN_AU&->əu shift: 	bɔlg
  Stage4_5_ContextualAllophonyOnPhonetic END: Out=	bɔlg
Af. Stage4_5_ContextualAllophonyOnPhonetic: [bɔlg]
    DBG (Epenthes): is_likely_monosyllable_revised for '	bɔlg	' (orig: '	bɔlg	') count: 	1	 result: 	true
  EpenthesisAndStrongSonorants START (Proc): In=	bɔlg
  EpenthesisAndStrongSonorants START (Proc): In=	bɔlg
  apply_procedural_epenthesis START: In=	bɔlg
    DBG (Epenthes): Parsed units for epenthesis: 	b(nonpalatal) | ɔ(vowel) | l(nonpalatal) | g(nonpalatal)
    DBG (Epenthes): is_likely_monosyllable_revised for '	bɔlg	' (orig: '	bɔlg	') count: 	1	 result: 	true
    DBG (Epenthes): Checking V-C1-C2: 	ɔ	l	g	 | Cluster key: 	lg	 | C1 Qual: 	nonpalatal	 | C2 Qual: 	nonpalatal
    DBG (Epenthes): PROCEDURAL Epenthesis Triggered for: 	ɔ	l	g	 -> inserting 	ə
  apply_procedural_epenthesis END (modified): Out=	bɔləg
    DBG (Epenthes): After procedural epenthesis: 	bɔləg
    DBG (Epenthes): After strong sonorant rules: 	bɔləg
  EpenthesisAndStrongSonorants END (Proc): Out=	bɔləg
Af. EpenthesisAndStrongSonorants: [bɔləg]
  Diacritics START: In=	bɔləg
  Diacritics END: Out=	bɔləg
Af. Diacritics: [bɔləg]
  FinalCleanup START: In=	bɔləg
  FinalCleanup END: Out=	bɔləg
Af. FinalCleanup: [bɔləg]
bolg            -> [bɔləg]

--- Transcribing: [ainm] ---
Af. MarkDigraphsAndVocalisationTriggers: [ˈainm]
  ConsonantResolution START (Proc): In=	ˈainm
  ConsonantResolution START (Proc): In=	ˈainm
    DBG (Consonan): Metathesis Sub-Stage START: 	ˈainm
    DBG (Consonan): Metathesis Check: c_base=	a	c_pal=	false	n_base=	i	n_pal=	false	at offset	2
    DBG (Consonan): Metathesis Check: c_base=	i	c_pal=	false	n_base=	n	n_pal=	false	at offset	3
    DBG (Consonan): Metathesis Check: c_base=	n	c_pal=	false	n_base=	m	n_pal=	false	at offset	4
    DBG (Consonan): Metathesis Check: c_base=	m	c_pal=	false	n_base=		n_pal=	false	at offset	5
    DBG (Consonan): Metathesis Sub-Stage END: 	ˈainm
    DBG (Consonan): After Pass 1 (markers): 	ˈainm
    DBG (Consonan): Pass 2: Checking '	m	' at phon_idx 	5	 -> ortho_s:	5	ortho_e:	5
    DBG (Consonan): Single cons rule: c_capture=	m	o_s=	5	o_e=	5
    DBG (DetQual): Word:	ˈainm	Cons seq:	m	s:	5	e:	5
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	i	Prev quality implication:	slender
    DBG (DetQual): Final determined quality for '	m	': 	palatal
    DBG (Consonan): Pass 2: Replaced '	m	' with '	m'	'
    DBG (Consonan): After Pass 2 (single chars): 	ˈainm'
  ConsonantResolution END (Proc): Out=	ˈainm'
Af. ConsonantResolution: [ˈainm']
  Stage4_0_SpecificOrthoToTempMarker START: In=	ˈainm'
  Stage4_0_SpecificOrthoToTempMarker END: Out=	ˈainm'
Af. Stage4_0_SpecificOrthoToTempMarker: [ˈainm']
  Stage4_0_1_Resolve_CH_Marker START: In=	ˈainm'
  Stage4_0_1_Resolve_CH_Marker END: Out=	ˈainm'
Af. Stage4_0_1_Resolve_CH_Marker: [ˈainm']
  Stage4_2_LongVowelsOrthoToTempMarker START: In=	ˈainm'
  Stage4_2_LongVowelsOrthoToTempMarker END: Out=	ˈainm'
Af. Stage4_2_LongVowelsOrthoToTempMarker: [ˈainm']
  Stage4_3_DiphthongsOrthoToTempMarker START: In=	ˈainm'
  Stage4_3_DiphthongsOrthoToTempMarker END: Out=	ˈ&AI_DIPH&nm'
Af. Stage4_3_DiphthongsOrthoToTempMarker: [ˈ&AI_DIPH&nm']
  Stage4_4_ResolveTempVowelMarkers START: In=	ˈ&AI_DIPH&nm'
    DBG (Stage4_4): Iter.gsub: Rule '	&AI_DIPH&(nm')	' APPLIED to '	ˈ&AI_DIPH&nm'	' -> '	ˈanm'	' (	1	x)
    DBG (Stage4_4): Iter.gsub Pass 1 ended. String changed from '	ˈ&AI_DIPH&nm'	' to '	ˈanm'	'
    DBG (Stage4_4): Iter.gsub Pass 2 ended. No changes in this pass. String remains: '	ˈanm'	'
  Stage4_4_ResolveTempVowelMarkers END: Out=	ˈanm'
Af. Stage4_4_ResolveTempVowelMarkers: [ˈanm']
  Stage4_5_ContextualAllophonyOnPhonetic START (Proc): In=	ˈanm'
  Stage4_5_ContextualAllophonyOnPhonetic START: In=	ˈanm'
    DBG (Stage4_5): Applying placeholder creation rules (ONCE)...
    DBG (Stage4_5): After placeholder creation: 	ˈanm'
    DBG (Stage4_5): Applying core allophony rules (iteratively)...
    DBG (Stage4_5): Core Iter.gsub: Rule '	a	' APPLIED to '	ˈanm'	' -> '	ˈɑnm'	' (	1	x)
    DBG (Stage4_5): Core Iter.gsub Pass 1 ended. String changed from '	ˈanm'	' to '	ˈɑnm'	'
    DBG (Stage4_5): Core Iter.gsub Pass 2 ended. No changes in this pass. String remains: '	ˈɑnm'	'
    DBG (Stage4_5): After core allophony rules: 	ˈɑnm'
    DBG (Stage4_5): Applying placeholder restoration rules (ONCE)...
    DBG (Stage4_5): After placeholder restoration: 	ˈɑnm'
    DBG (Stage4_5): Applying Connacht ɑu -> əu shift (ONCE)...
    DBG (Stage4_5): After Connacht ɑu->əu shift: 	ˈɑnm'
    DBG (Stage4_5): Applying &TEMP_CONN_AU& -> əu shift (ONCE)...
    DBG (Stage4_5): After &TEMP_CONN_AU&->əu shift: 	ˈɑnm'
  Stage4_5_ContextualAllophonyOnPhonetic END: Out=	ˈɑnm'
Af. Stage4_5_ContextualAllophonyOnPhonetic: [ˈɑnm']
    DBG (Epenthes): is_likely_monosyllable_revised for '	ɑnm'	' (orig: '	ˈɑnm'	') count: 	0	 result: 	false
  EpenthesisAndStrongSonorants START (Proc): In=	ˈɑnm'
  EpenthesisAndStrongSonorants START (Proc): In=	ˈɑnm'
  apply_procedural_epenthesis START: In=	ˈɑnm'
    DBG (Epenthes): Parsed units for epenthesis: 	ˈ(stress_mark) | ɑ(vowel) | n(nonpalatal) | m'(palatal)
    DBG (Epenthes): is_likely_monosyllable_revised for '	ɑnm'	' (orig: '	ˈɑnm'	') count: 	0	 result: 	false
  apply_procedural_epenthesis END (not monosyllable): Out=	ˈɑnm'
    DBG (Epenthes): After procedural epenthesis: 	ˈɑnm'
    DBG (Epenthes): After strong sonorant rules: 	ˈɑnm'
  EpenthesisAndStrongSonorants END (Proc): Out=	ˈɑnm'
Af. EpenthesisAndStrongSonorants: [ˈɑnm']
  Diacritics START: In=	ˈɑnm'
  Diacritics END: Out=	ˈɑnm'
Af. Diacritics: [ˈɑnm']
  FinalCleanup START: In=	ˈɑnm'
  FinalCleanup END: Out=	ˈɑnm'
Af. FinalCleanup: [ˈɑnm']
ainm            -> [ˈɑnm']



--- Running Test Set for Iteration 37AU (Focused) ---

--- Transcribing: [cnámh] ---
Af. MarkDigraphsAndVocalisationTriggers: [cn&A_ACUTE_LONG_VOC_M_FINAL&]
  ConsonantResolution START (Proc): In=	cn&A_ACUTE_LONG_VOC_M_FINAL&
  ConsonantResolution START (Proc): In=	cn&A_ACUTE_LONG_VOC_M_FINAL&
    DBG (Consonan): Metathesis Sub-Stage START: 	cn&A_ACUTE_LONG_VOC_M_FINAL&
    DBG (Consonan): Metathesis Check: c_base=	c	c_pal=	false	n_base=	n	n_pal=	false	at offset	1
    DBG (Consonan): Metathesis candidate found: 	cn
    DBG (DetQual): Word:	cnámh	Cons seq:	n	s:	2	e:	2
    DBG (DetQual): Next relevant vowel char for quality:	á	Next quality implication:	broad
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	n	': 	nonpalatal
    DBG (Consonan): Original ortho 'n' (ortho indices 2-2 in 'cnámh') quality was: 	nonpalatal	. Thus, quality for metathesized 'r': 	nonpalatal
    DBG (Consonan): Metathesis Check: c_base=	&	c_pal=	false	n_base=	A	n_pal=	false	at offset	3
    DBG (Consonan): Metathesis Check: c_base=	A	c_pal=	false	n_base=	_	n_pal=	false	at offset	4
    DBG (Consonan): Metathesis Check: c_base=	_	c_pal=	false	n_base=	A	n_pal=	false	at offset	5
    DBG (Consonan): Metathesis Check: c_base=	A	c_pal=	false	n_base=	C	n_pal=	false	at offset	6
    DBG (Consonan): Metathesis Check: c_base=	C	c_pal=	false	n_base=	U	n_pal=	false	at offset	7
    DBG (Consonan): Metathesis Check: c_base=	U	c_pal=	false	n_base=	T	n_pal=	false	at offset	8
    DBG (Consonan): Metathesis Check: c_base=	T	c_pal=	false	n_base=	E	n_pal=	false	at offset	9
    DBG (Consonan): Metathesis Check: c_base=	E	c_pal=	false	n_base=	_	n_pal=	false	at offset	10
    DBG (Consonan): Metathesis Check: c_base=	_	c_pal=	false	n_base=	L	n_pal=	false	at offset	11
    DBG (Consonan): Metathesis Check: c_base=	L	c_pal=	false	n_base=	O	n_pal=	false	at offset	12
    DBG (Consonan): Metathesis Check: c_base=	O	c_pal=	false	n_base=	N	n_pal=	false	at offset	13
    DBG (Consonan): Metathesis Check: c_base=	N	c_pal=	false	n_base=	G	n_pal=	false	at offset	14
    DBG (Consonan): Metathesis Check: c_base=	G	c_pal=	false	n_base=	_	n_pal=	false	at offset	15
    DBG (Consonan): Metathesis Check: c_base=	_	c_pal=	false	n_base=	V	n_pal=	false	at offset	16
    DBG (Consonan): Metathesis Check: c_base=	V	c_pal=	false	n_base=	O	n_pal=	false	at offset	17
    DBG (Consonan): Metathesis Check: c_base=	O	c_pal=	false	n_base=	C	n_pal=	false	at offset	18
    DBG (Consonan): Metathesis Check: c_base=	C	c_pal=	false	n_base=	_	n_pal=	false	at offset	19
    DBG (Consonan): Metathesis Check: c_base=	_	c_pal=	false	n_base=	M	n_pal=	false	at offset	20
    DBG (Consonan): Metathesis Check: c_base=	M	c_pal=	false	n_base=	_	n_pal=	false	at offset	21
    DBG (Consonan): Metathesis Check: c_base=	_	c_pal=	false	n_base=	F	n_pal=	false	at offset	22
    DBG (Consonan): Metathesis Check: c_base=	F	c_pal=	false	n_base=	I	n_pal=	false	at offset	23
    DBG (Consonan): Metathesis Check: c_base=	I	c_pal=	false	n_base=	N	n_pal=	false	at offset	24
    DBG (Consonan): Metathesis Check: c_base=	N	c_pal=	false	n_base=	A	n_pal=	false	at offset	25
    DBG (Consonan): Metathesis Check: c_base=	A	c_pal=	false	n_base=	L	n_pal=	false	at offset	26
    DBG (Consonan): Metathesis Check: c_base=	L	c_pal=	false	n_base=	&	n_pal=	false	at offset	27
    DBG (Consonan): Metathesis Check: c_base=	&	c_pal=	false	n_base=		n_pal=	false	at offset	28
    DBG (Consonan): Metathesis Sub-Stage END: 	cr&A_ACUTE_LONG_VOC_M_FINAL&
    DBG (Consonan): After Pass 1 (markers): 	cr&A_ACUTE_LONG_VOC_M_FINAL&
    DBG (Consonan): Pass 2: Checking '	c	' at phon_idx 	1	 -> ortho_s:	1	ortho_e:	1
    DBG (Consonan): Single cons rule: c_capture=	c	o_s=	1	o_e=	1
    DBG (DetQual): Word:	cnámh	Cons seq:	c	s:	1	e:	1
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	c	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	c	' with '	k	'
    DBG (Consonan): Pass 2: Checking '	r	' at phon_idx 	2	 -> ortho_s:	2	ortho_e:	2
    DBG (Consonan): Single cons rule: c_capture=	r	o_s=	2	o_e=	2
    DBG (DetQual): Word:	cnámh	Cons seq:	n	s:	2	e:	2
    DBG (DetQual): Next relevant vowel char for quality:	á	Next quality implication:	broad
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	n	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	r	' with '	r	'
    DBG (Consonan): After Pass 2 (single chars): 	kr&A_ACUTE_LONG_VOC_M_FINAL&
  ConsonantResolution END (Proc): Out=	kr&A_ACUTE_LONG_VOC_M_FINAL&
Af. ConsonantResolution: [kr&A_ACUTE_LONG_VOC_M_FINAL&]
  Stage4_0_SpecificOrthoToTempMarker START: In=	kr&A_ACUTE_LONG_VOC_M_FINAL&
  Stage4_0_SpecificOrthoToTempMarker END: Out=	kr&A_ACUTE_LONG_VOC_M_FINAL&
Af. Stage4_0_SpecificOrthoToTempMarker: [kr&A_ACUTE_LONG_VOC_M_FINAL&]
  Stage4_0_1_Resolve_CH_Marker START: In=	kr&A_ACUTE_LONG_VOC_M_FINAL&
  Stage4_0_1_Resolve_CH_Marker END: Out=	kr&A_ACUTE_LONG_VOC_M_FINAL&
Af. Stage4_0_1_Resolve_CH_Marker: [kr&A_ACUTE_LONG_VOC_M_FINAL&]
  Stage4_2_LongVowelsOrthoToTempMarker START: In=	kr&A_ACUTE_LONG_VOC_M_FINAL&
  Stage4_2_LongVowelsOrthoToTempMarker END: Out=	kr&A_ACUTE_LONG_VOC_M_FINAL&
Af. Stage4_2_LongVowelsOrthoToTempMarker: [kr&A_ACUTE_LONG_VOC_M_FINAL&]
  Stage4_3_DiphthongsOrthoToTempMarker START: In=	kr&A_ACUTE_LONG_VOC_M_FINAL&
  Stage4_3_DiphthongsOrthoToTempMarker END: Out=	kr&A_ACUTE_LONG_VOC_M_FINAL&
Af. Stage4_3_DiphthongsOrthoToTempMarker: [kr&A_ACUTE_LONG_VOC_M_FINAL&]
  Stage4_4_ResolveTempVowelMarkers START: In=	kr&A_ACUTE_LONG_VOC_M_FINAL&
    DBG (Stage4_4): Iter.gsub: Rule '	&A_ACUTE_LONG_VOC_M_FINAL&(#?)	' APPLIED to '	kr&A_ACUTE_LONG_VOC_M_FINAL&	' -> '	krɑːv	' (	1	x)
    DBG (Stage4_4): Iter.gsub Pass 1 ended. String changed from '	kr&A_ACUTE_LONG_VOC_M_FINAL&	' to '	krɑːv	'
    DBG (Stage4_4): Iter.gsub Pass 2 ended. No changes in this pass. String remains: '	krɑːv	'
  Stage4_4_ResolveTempVowelMarkers END: Out=	krɑːv
Af. Stage4_4_ResolveTempVowelMarkers: [krɑːv]
  Stage4_5_ContextualAllophonyOnPhonetic START (Proc): In=	krɑːv
  Stage4_5_ContextualAllophonyOnPhonetic START: In=	krɑːv
    DBG (Stage4_5): Applying placeholder creation rules (ONCE)...
    DBG (Stage4_5): Placeholder created: '	ɑː	' -> '	&PHON_A_LONG&	'. Result: '	kr&PHON_A_LONG&v	'
    DBG (Stage4_5): After placeholder creation: 	kr&PHON_A_LONG&v
    DBG (Stage4_5): Applying core allophony rules (iteratively)...
    DBG (Stage4_5): Core Iter.gsub Pass 1 ended. No changes in this pass. String remains: '	kr&PHON_A_LONG&v	'
    DBG (Stage4_5): After core allophony rules: 	kr&PHON_A_LONG&v
    DBG (Stage4_5): Applying placeholder restoration rules (ONCE)...
    DBG (Stage4_5): Placeholder restored: '	&PHON_A_LONG&	' -> '	ɑː	'. Result: '	krɑːv	'
    DBG (Stage4_5): After placeholder restoration: 	krɑːv
    DBG (Stage4_5): Applying Connacht ɑu -> əu shift (ONCE)...
    DBG (Stage4_5): After Connacht ɑu->əu shift: 	krɑːv
    DBG (Stage4_5): Applying &TEMP_CONN_AU& -> əu shift (ONCE)...
    DBG (Stage4_5): After &TEMP_CONN_AU&->əu shift: 	krɑːv
  Stage4_5_ContextualAllophonyOnPhonetic END: Out=	krɑːv
Af. Stage4_5_ContextualAllophonyOnPhonetic: [krɑːv]
    DBG (Epenthes): is_likely_monosyllable_revised for '	krɑːv	' (orig: '	krɑːv	') count: 	1	 result: 	true
  EpenthesisAndStrongSonorants START (Proc): In=	krɑːv
  EpenthesisAndStrongSonorants START (Proc): In=	krɑːv
  apply_procedural_epenthesis START: In=	krɑːv
    DBG (Epenthes): Parsed units for epenthesis: 	k(nonpalatal) | r(nonpalatal) | ɑː(vowel) | v(unknown)
    DBG (Epenthes): is_likely_monosyllable_revised for '	krɑːv	' (orig: '	krɑːv	') count: 	1	 result: 	true
  apply_procedural_epenthesis END (no change): Out=	krɑːv
    DBG (Epenthes): After procedural epenthesis: 	krɑːv
    DBG (Epenthes): After strong sonorant rules: 	krɑːv
  EpenthesisAndStrongSonorants END (Proc): Out=	krɑːv
Af. EpenthesisAndStrongSonorants: [krɑːv]
  Diacritics START: In=	krɑːv
  Diacritics END: Out=	krɑːv
Af. Diacritics: [krɑːv]
  FinalCleanup START: In=	krɑːv
  FinalCleanup END: Out=	krɑːv
Af. FinalCleanup: [krɑːv]
cnámh          -> [krɑːv]

--- Transcribing: [cnead] ---
Af. MarkDigraphsAndVocalisationTriggers: [cnead]
  ConsonantResolution START (Proc): In=	cnead
  ConsonantResolution START (Proc): In=	cnead
    DBG (Consonan): Metathesis Sub-Stage START: 	cnead
    DBG (Consonan): Metathesis Check: c_base=	c	c_pal=	false	n_base=	n	n_pal=	false	at offset	1
    DBG (Consonan): Metathesis candidate found: 	cn
    DBG (DetQual): Word:	cnead	Cons seq:	n	s:	2	e:	2
    DBG (DetQual): Next relevant vowel char for quality:	e	Next quality implication:	slender
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	n	': 	palatal
    DBG (Consonan): Original ortho 'n' (ortho indices 2-2 in 'cnead') quality was: 	palatal	. Thus, quality for metathesized 'r': 	palatal
    DBG (Consonan): Metathesis Check: c_base=	e	c_pal=	false	n_base=	a	n_pal=	false	at offset	3
    DBG (Consonan): Metathesis Check: c_base=	a	c_pal=	false	n_base=	d	n_pal=	false	at offset	4
    DBG (Consonan): Metathesis Check: c_base=	d	c_pal=	false	n_base=		n_pal=	false	at offset	5
    DBG (Consonan): Metathesis Sub-Stage END: 	cr'ead
    DBG (Consonan): After Pass 1 (markers): 	cr'ead
    DBG (Consonan): Pass 2: Checking '	c	' at phon_idx 	1	 -> ortho_s:	1	ortho_e:	1
    DBG (Consonan): Single cons rule: c_capture=	c	o_s=	1	o_e=	1
    DBG (DetQual): Word:	cnead	Cons seq:	c	s:	1	e:	1
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	c	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	c	' with '	k	'
    DBG (Consonan): Pass 2: Checking '	r	' at phon_idx 	2	 -> ortho_s:	2	ortho_e:	2
    DBG (Consonan): Single cons rule: c_capture=	r	o_s=	2	o_e=	2
    DBG (DetQual): Word:	cnead	Cons seq:	n	s:	2	e:	2
    DBG (DetQual): Next relevant vowel char for quality:	e	Next quality implication:	slender
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	n	': 	palatal
    DBG (Consonan): Pass 2: Replaced '	r	' with '	r'	'
    DBG (Consonan): Pass 2: Checking '	d	' at phon_idx 	6	 -> ortho_s:	6	ortho_e:	6
    DBG (Consonan): Single cons rule: c_capture=	d	o_s=	6	o_e=	6
    DBG (DetQual): Bailing: Invalid indices or word for: 	cnead	6	6
    DBG (Consonan): Pass 2: Replaced '	d	' with '	d	'
    DBG (Consonan): After Pass 2 (single chars): 	kr''ead
  ConsonantResolution END (Proc): Out=	kr''ead
Af. ConsonantResolution: [kr''ead]
  Stage4_0_SpecificOrthoToTempMarker START: In=	kr''ead
  Stage4_0_SpecificOrthoToTempMarker END: Out=	kr''ead
Af. Stage4_0_SpecificOrthoToTempMarker: [kr''ead]
  Stage4_0_1_Resolve_CH_Marker START: In=	kr''ead
  Stage4_0_1_Resolve_CH_Marker END: Out=	kr''ead
Af. Stage4_0_1_Resolve_CH_Marker: [kr''ead]
  Stage4_2_LongVowelsOrthoToTempMarker START: In=	kr''ead
  Stage4_2_LongVowelsOrthoToTempMarker END: Out=	kr''ead
Af. Stage4_2_LongVowelsOrthoToTempMarker: [kr''ead]
  Stage4_3_DiphthongsOrthoToTempMarker START: In=	kr''ead
  Stage4_3_DiphthongsOrthoToTempMarker END: Out=	kr''ead
Af. Stage4_3_DiphthongsOrthoToTempMarker: [kr''ead]
  Stage4_4_ResolveTempVowelMarkers START: In=	kr''ead
    DBG (Stage4_4): Iter.gsub Pass 1 ended. No changes in this pass. String remains: '	kr''ead	'
  Stage4_4_ResolveTempVowelMarkers END: Out=	kr''ead
Af. Stage4_4_ResolveTempVowelMarkers: [kr''ead]
  Stage4_5_ContextualAllophonyOnPhonetic START (Proc): In=	kr''ead
  Stage4_5_ContextualAllophonyOnPhonetic START: In=	kr''ead
    DBG (Stage4_5): Applying placeholder creation rules (ONCE)...
    DBG (Stage4_5): After placeholder creation: 	kr''ead
    DBG (Stage4_5): Applying core allophony rules (iteratively)...
    DBG (Stage4_5): Core Iter.gsub: Rule '	a	' APPLIED to '	kr''ead	' -> '	kr''eɑd	' (	1	x)
    DBG (Stage4_5): Core Iter.gsub Pass 1 ended. String changed from '	kr''ead	' to '	kr''eɑd	'
    DBG (Stage4_5): Core Iter.gsub Pass 2 ended. No changes in this pass. String remains: '	kr''eɑd	'
    DBG (Stage4_5): After core allophony rules: 	kr''eɑd
    DBG (Stage4_5): Applying placeholder restoration rules (ONCE)...
    DBG (Stage4_5): After placeholder restoration: 	kr''eɑd
    DBG (Stage4_5): Applying Connacht ɑu -> əu shift (ONCE)...
    DBG (Stage4_5): After Connacht ɑu->əu shift: 	kr''eɑd
    DBG (Stage4_5): Applying &TEMP_CONN_AU& -> əu shift (ONCE)...
    DBG (Stage4_5): After &TEMP_CONN_AU&->əu shift: 	kr''eɑd
  Stage4_5_ContextualAllophonyOnPhonetic END: Out=	kr''eɑd
Af. Stage4_5_ContextualAllophonyOnPhonetic: [kr''eɑd]
    DBG (Epenthes): is_likely_monosyllable_revised for '	kr''eɑd	' (orig: '	kr''eɑd	') count: 	1	 result: 	true
  EpenthesisAndStrongSonorants START (Proc): In=	kr''eɑd
  EpenthesisAndStrongSonorants START (Proc): In=	kr''eɑd
  apply_procedural_epenthesis START: In=	kr''eɑd
    DBG (Epenthes): Parsed units for epenthesis: 	k(nonpalatal) | r'(palatal) | '(unknown_fallback) | e(vowel) | ɑ(vowel) | d(palatal)
    DBG (Epenthes): is_likely_monosyllable_revised for '	kr''eɑd	' (orig: '	kr''eɑd	') count: 	1	 result: 	true
  apply_procedural_epenthesis END (no change): Out=	kr''eɑd
    DBG (Epenthes): After procedural epenthesis: 	kr''eɑd
    DBG (Epenthes): After strong sonorant rules: 	kr''eɑd
  EpenthesisAndStrongSonorants END (Proc): Out=	kr''eɑd
Af. EpenthesisAndStrongSonorants: [kr''eɑd]
  Diacritics START: In=	kr''eɑd
  Diacritics END: Out=	kr''eɑd
Af. Diacritics: [kr''eɑd]
  FinalCleanup START: In=	kr''eɑd
  FinalCleanup END: Out=	kr''eɑd
Af. FinalCleanup: [kr''eɑd]
cnead           -> [kr''eɑd]

--- Transcribing: [cnoc] ---
Af. MarkDigraphsAndVocalisationTriggers: [cnoc]
  ConsonantResolution START (Proc): In=	cnoc
  ConsonantResolution START (Proc): In=	cnoc
    DBG (Consonan): Metathesis Sub-Stage START: 	cnoc
    DBG (Consonan): Metathesis Check: c_base=	c	c_pal=	false	n_base=	n	n_pal=	false	at offset	1
    DBG (Consonan): Metathesis candidate found: 	cn
    DBG (DetQual): Word:	cnoc	Cons seq:	n	s:	2	e:	2
    DBG (DetQual): Next relevant vowel char for quality:	o	Next quality implication:	broad
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	n	': 	nonpalatal
    DBG (Consonan): Original ortho 'n' (ortho indices 2-2 in 'cnoc') quality was: 	nonpalatal	. Thus, quality for metathesized 'r': 	nonpalatal
    DBG (Consonan): Metathesis Check: c_base=	o	c_pal=	false	n_base=	c	n_pal=	false	at offset	3
    DBG (Consonan): Metathesis Check: c_base=	c	c_pal=	false	n_base=		n_pal=	false	at offset	4
    DBG (Consonan): Metathesis Sub-Stage END: 	croc
    DBG (Consonan): After Pass 1 (markers): 	croc
    DBG (Consonan): Pass 2: Checking '	c	' at phon_idx 	1	 -> ortho_s:	1	ortho_e:	1
    DBG (Consonan): Single cons rule: c_capture=	c	o_s=	1	o_e=	1
    DBG (DetQual): Word:	cnoc	Cons seq:	c	s:	1	e:	1
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	c	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	c	' with '	k	'
    DBG (Consonan): Pass 2: Checking '	r	' at phon_idx 	2	 -> ortho_s:	2	ortho_e:	2
    DBG (Consonan): Single cons rule: c_capture=	r	o_s=	2	o_e=	2
    DBG (DetQual): Word:	cnoc	Cons seq:	n	s:	2	e:	2
    DBG (DetQual): Next relevant vowel char for quality:	o	Next quality implication:	broad
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	n	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	r	' with '	r	'
    DBG (Consonan): Pass 2: Checking '	c	' at phon_idx 	4	 -> ortho_s:	4	ortho_e:	4
    DBG (Consonan): Single cons rule: c_capture=	c	o_s=	4	o_e=	4
    DBG (DetQual): Word:	cnoc	Cons seq:	c	s:	4	e:	4
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	o	Prev quality implication:	broad
    DBG (DetQual): Final determined quality for '	c	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	c	' with '	k	'
    DBG (Consonan): After Pass 2 (single chars): 	krok
  ConsonantResolution END (Proc): Out=	krok
Af. ConsonantResolution: [krok]
  Stage4_0_SpecificOrthoToTempMarker START: In=	krok
  Stage4_0_SpecificOrthoToTempMarker END: Out=	krok
Af. Stage4_0_SpecificOrthoToTempMarker: [krok]
  Stage4_0_1_Resolve_CH_Marker START: In=	krok
  Stage4_0_1_Resolve_CH_Marker END: Out=	krok
Af. Stage4_0_1_Resolve_CH_Marker: [krok]
  Stage4_2_LongVowelsOrthoToTempMarker START: In=	krok
  Stage4_2_LongVowelsOrthoToTempMarker END: Out=	krok
Af. Stage4_2_LongVowelsOrthoToTempMarker: [krok]
  Stage4_3_DiphthongsOrthoToTempMarker START: In=	krok
  Stage4_3_DiphthongsOrthoToTempMarker END: Out=	krok
Af. Stage4_3_DiphthongsOrthoToTempMarker: [krok]
  Stage4_4_ResolveTempVowelMarkers START: In=	krok
    DBG (Stage4_4): Iter.gsub Pass 1 ended. No changes in this pass. String remains: '	krok	'
  Stage4_4_ResolveTempVowelMarkers END: Out=	krok
Af. Stage4_4_ResolveTempVowelMarkers: [krok]
  Stage4_5_ContextualAllophonyOnPhonetic START (Proc): In=	krok
  Stage4_5_ContextualAllophonyOnPhonetic START: In=	krok
    DBG (Stage4_5): Applying placeholder creation rules (ONCE)...
    DBG (Stage4_5): After placeholder creation: 	krok
    DBG (Stage4_5): Applying core allophony rules (iteratively)...
    DBG (Stage4_5): Core Iter.gsub: Rule '	o	' APPLIED to '	krok	' -> '	krɔk	' (	1	x)
    DBG (Stage4_5): Core Iter.gsub Pass 1 ended. String changed from '	krok	' to '	krɔk	'
    DBG (Stage4_5): Core Iter.gsub Pass 2 ended. No changes in this pass. String remains: '	krɔk	'
    DBG (Stage4_5): After core allophony rules: 	krɔk
    DBG (Stage4_5): Applying placeholder restoration rules (ONCE)...
    DBG (Stage4_5): After placeholder restoration: 	krɔk
    DBG (Stage4_5): Applying Connacht ɑu -> əu shift (ONCE)...
    DBG (Stage4_5): After Connacht ɑu->əu shift: 	krɔk
    DBG (Stage4_5): Applying &TEMP_CONN_AU& -> əu shift (ONCE)...
    DBG (Stage4_5): After &TEMP_CONN_AU&->əu shift: 	krɔk
  Stage4_5_ContextualAllophonyOnPhonetic END: Out=	krɔk
Af. Stage4_5_ContextualAllophonyOnPhonetic: [krɔk]
    DBG (Epenthes): is_likely_monosyllable_revised for '	krɔk	' (orig: '	krɔk	') count: 	1	 result: 	true
  EpenthesisAndStrongSonorants START (Proc): In=	krɔk
  EpenthesisAndStrongSonorants START (Proc): In=	krɔk
  apply_procedural_epenthesis START: In=	krɔk
    DBG (Epenthes): Parsed units for epenthesis: 	k(nonpalatal) | r(nonpalatal) | ɔ(vowel) | k(nonpalatal)
    DBG (Epenthes): is_likely_monosyllable_revised for '	krɔk	' (orig: '	krɔk	') count: 	1	 result: 	true
  apply_procedural_epenthesis END (no change): Out=	krɔk
    DBG (Epenthes): After procedural epenthesis: 	krɔk
    DBG (Epenthes): After strong sonorant rules: 	krɔk
  EpenthesisAndStrongSonorants END (Proc): Out=	krɔk
Af. EpenthesisAndStrongSonorants: [krɔk]
  Diacritics START: In=	krɔk
  Diacritics END: Out=	krɔk
Af. Diacritics: [krɔk]
  FinalCleanup START: In=	krɔk
  FinalCleanup END: Out=	krɔk
Af. FinalCleanup: [krɔk]
cnoc            -> [krɔk]

--- Transcribing: [gnaoi] ---
Af. MarkDigraphsAndVocalisationTriggers: [gn&AOI_LONG&]
  ConsonantResolution START (Proc): In=	gn&AOI_LONG&
  ConsonantResolution START (Proc): In=	gn&AOI_LONG&
    DBG (Consonan): Metathesis Sub-Stage START: 	gn&AOI_LONG&
    DBG (Consonan): Metathesis Check: c_base=	g	c_pal=	false	n_base=	n	n_pal=	false	at offset	1
    DBG (Consonan): Metathesis candidate found: 	gn
    DBG (DetQual): Word:	gnaoi	Cons seq:	n	s:	2	e:	2
    DBG (DetQual): Next relevant vowel char for quality:	i	Next quality implication:	slender
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	n	': 	palatal
    DBG (Consonan): Original ortho 'n' (ortho indices 2-2 in 'gnaoi') quality was: 	palatal	. Thus, quality for metathesized 'r': 	palatal
    DBG (Consonan): Metathesis Check: c_base=	&	c_pal=	false	n_base=	A	n_pal=	false	at offset	3
    DBG (Consonan): Metathesis Check: c_base=	A	c_pal=	false	n_base=	O	n_pal=	false	at offset	4
    DBG (Consonan): Metathesis Check: c_base=	O	c_pal=	false	n_base=	I	n_pal=	false	at offset	5
    DBG (Consonan): Metathesis Check: c_base=	I	c_pal=	false	n_base=	_	n_pal=	false	at offset	6
    DBG (Consonan): Metathesis Check: c_base=	_	c_pal=	false	n_base=	L	n_pal=	false	at offset	7
    DBG (Consonan): Metathesis Check: c_base=	L	c_pal=	false	n_base=	O	n_pal=	false	at offset	8
    DBG (Consonan): Metathesis Check: c_base=	O	c_pal=	false	n_base=	N	n_pal=	false	at offset	9
    DBG (Consonan): Metathesis Check: c_base=	N	c_pal=	false	n_base=	G	n_pal=	false	at offset	10
    DBG (Consonan): Metathesis Check: c_base=	G	c_pal=	false	n_base=	&	n_pal=	false	at offset	11
    DBG (Consonan): Metathesis Check: c_base=	&	c_pal=	false	n_base=		n_pal=	false	at offset	12
    DBG (Consonan): Metathesis Sub-Stage END: 	gr'&AOI_LONG&
    DBG (Consonan): After Pass 1 (markers): 	gr'&AOI_LONG&
    DBG (Consonan): Pass 2: Checking '	g	' at phon_idx 	1	 -> ortho_s:	1	ortho_e:	1
    DBG (Consonan): Single cons rule: c_capture=	g	o_s=	1	o_e=	1
    DBG (DetQual): Word:	gnaoi	Cons seq:	g	s:	1	e:	1
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	g	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	g	' with '	g	'
    DBG (Consonan): Pass 2: Checking '	r	' at phon_idx 	2	 -> ortho_s:	2	ortho_e:	2
    DBG (Consonan): Single cons rule: c_capture=	r	o_s=	2	o_e=	2
    DBG (DetQual): Word:	gnaoi	Cons seq:	n	s:	2	e:	2
    DBG (DetQual): Next relevant vowel char for quality:	i	Next quality implication:	slender
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	n	': 	palatal
    DBG (Consonan): Pass 2: Replaced '	r	' with '	r'	'
    DBG (Consonan): After Pass 2 (single chars): 	gr''&AOI_LONG&
  ConsonantResolution END (Proc): Out=	gr''&AOI_LONG&
Af. ConsonantResolution: [gr''&AOI_LONG&]
  Stage4_0_SpecificOrthoToTempMarker START: In=	gr''&AOI_LONG&
  Stage4_0_SpecificOrthoToTempMarker END: Out=	gr''&AOI_LONG&
Af. Stage4_0_SpecificOrthoToTempMarker: [gr''&AOI_LONG&]
  Stage4_0_1_Resolve_CH_Marker START: In=	gr''&AOI_LONG&
  Stage4_0_1_Resolve_CH_Marker END: Out=	gr''&AOI_LONG&
Af. Stage4_0_1_Resolve_CH_Marker: [gr''&AOI_LONG&]
  Stage4_2_LongVowelsOrthoToTempMarker START: In=	gr''&AOI_LONG&
  Stage4_2_LongVowelsOrthoToTempMarker END: Out=	gr''&AOI_LONG&
Af. Stage4_2_LongVowelsOrthoToTempMarker: [gr''&AOI_LONG&]
  Stage4_3_DiphthongsOrthoToTempMarker START: In=	gr''&AOI_LONG&
  Stage4_3_DiphthongsOrthoToTempMarker END: Out=	gr''&AOI_LONG&
Af. Stage4_3_DiphthongsOrthoToTempMarker: [gr''&AOI_LONG&]
  Stage4_4_ResolveTempVowelMarkers START: In=	gr''&AOI_LONG&
    DBG (Stage4_4): Iter.gsub: Rule '	&AOI_LONG&	' APPLIED to '	gr''&AOI_LONG&	' -> '	gr''iː	' (	1	x)
    DBG (Stage4_4): Iter.gsub Pass 1 ended. String changed from '	gr''&AOI_LONG&	' to '	gr''iː	'
    DBG (Stage4_4): Iter.gsub Pass 2 ended. No changes in this pass. String remains: '	gr''iː	'
  Stage4_4_ResolveTempVowelMarkers END: Out=	gr''iː
Af. Stage4_4_ResolveTempVowelMarkers: [gr''iː]
  Stage4_5_ContextualAllophonyOnPhonetic START (Proc): In=	gr''iː
  Stage4_5_ContextualAllophonyOnPhonetic START: In=	gr''iː
    DBG (Stage4_5): Applying placeholder creation rules (ONCE)...
    DBG (Stage4_5): Placeholder created: '	iː	' -> '	&PHON_I_LONG&	'. Result: '	gr''&PHON_I_LONG&	'
    DBG (Stage4_5): After placeholder creation: 	gr''&PHON_I_LONG&
    DBG (Stage4_5): Applying core allophony rules (iteratively)...
    DBG (Stage4_5): Core Iter.gsub Pass 1 ended. No changes in this pass. String remains: '	gr''&PHON_I_LONG&	'
    DBG (Stage4_5): After core allophony rules: 	gr''&PHON_I_LONG&
    DBG (Stage4_5): Applying placeholder restoration rules (ONCE)...
    DBG (Stage4_5): Placeholder restored: '	&PHON_I_LONG&	' -> '	iː	'. Result: '	gr''iː	'
    DBG (Stage4_5): After placeholder restoration: 	gr''iː
    DBG (Stage4_5): Applying Connacht ɑu -> əu shift (ONCE)...
    DBG (Stage4_5): After Connacht ɑu->əu shift: 	gr''iː
    DBG (Stage4_5): Applying &TEMP_CONN_AU& -> əu shift (ONCE)...
    DBG (Stage4_5): After &TEMP_CONN_AU&->əu shift: 	gr''iː
  Stage4_5_ContextualAllophonyOnPhonetic END: Out=	gr''iː
Af. Stage4_5_ContextualAllophonyOnPhonetic: [gr''iː]
    DBG (Epenthes): is_likely_monosyllable_revised for '	gr''iː	' (orig: '	gr''iː	') count: 	1	 result: 	true
  EpenthesisAndStrongSonorants START (Proc): In=	gr''iː
  EpenthesisAndStrongSonorants START (Proc): In=	gr''iː
  apply_procedural_epenthesis START: In=	gr''iː
    DBG (Epenthes): Parsed units for epenthesis: 	g(nonpalatal) | r'(palatal) | '(unknown_fallback) | iː(vowel)
    DBG (Epenthes): is_likely_monosyllable_revised for '	gr''iː	' (orig: '	gr''iː	') count: 	1	 result: 	true
  apply_procedural_epenthesis END (no change): Out=	gr''iː
    DBG (Epenthes): After procedural epenthesis: 	gr''iː
    DBG (Epenthes): After strong sonorant rules: 	gr''iː
  EpenthesisAndStrongSonorants END (Proc): Out=	gr''iː
Af. EpenthesisAndStrongSonorants: [gr''iː]
  Diacritics START: In=	gr''iː
  Diacritics END: Out=	gr''iː
Af. Diacritics: [gr''iː]
  FinalCleanup START: In=	gr''iː
  FinalCleanup END: Out=	gr''iː
Af. FinalCleanup: [gr''iː]
gnaoi           -> [gr''iː]

--- Transcribing: [gnó] ---
Af. MarkDigraphsAndVocalisationTriggers: [gnó]
  ConsonantResolution START (Proc): In=	gnó
  ConsonantResolution START (Proc): In=	gnó
    DBG (Consonan): Metathesis Sub-Stage START: 	gnó
    DBG (Consonan): Metathesis Check: c_base=	g	c_pal=	false	n_base=	n	n_pal=	false	at offset	1
    DBG (Consonan): Metathesis candidate found: 	gn
    DBG (DetQual): Word:	gnó	Cons seq:	n	s:	2	e:	2
    DBG (DetQual): Next relevant vowel char for quality:	ó	Next quality implication:	broad
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	n	': 	nonpalatal
    DBG (Consonan): Original ortho 'n' (ortho indices 2-2 in 'gnó') quality was: 	nonpalatal	. Thus, quality for metathesized 'r': 	nonpalatal
    DBG (Consonan): Metathesis Check: c_base=	ó	c_pal=	false	n_base=		n_pal=	false	at offset	3
    DBG (Consonan): Metathesis Sub-Stage END: 	gró
    DBG (Consonan): After Pass 1 (markers): 	gró
    DBG (Consonan): Pass 2: Checking '	g	' at phon_idx 	1	 -> ortho_s:	1	ortho_e:	1
    DBG (Consonan): Single cons rule: c_capture=	g	o_s=	1	o_e=	1
    DBG (DetQual): Word:	gnó	Cons seq:	g	s:	1	e:	1
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	g	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	g	' with '	g	'
    DBG (Consonan): Pass 2: Checking '	r	' at phon_idx 	2	 -> ortho_s:	2	ortho_e:	2
    DBG (Consonan): Single cons rule: c_capture=	r	o_s=	2	o_e=	2
    DBG (DetQual): Word:	gnó	Cons seq:	n	s:	2	e:	2
    DBG (DetQual): Next relevant vowel char for quality:	ó	Next quality implication:	broad
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	n	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	r	' with '	r	'
    DBG (Consonan): After Pass 2 (single chars): 	gró
  ConsonantResolution END (Proc): Out=	gró
Af. ConsonantResolution: [gró]
  Stage4_0_SpecificOrthoToTempMarker START: In=	gró
  Stage4_0_SpecificOrthoToTempMarker END: Out=	gró
Af. Stage4_0_SpecificOrthoToTempMarker: [gró]
  Stage4_0_1_Resolve_CH_Marker START: In=	gró
  Stage4_0_1_Resolve_CH_Marker END: Out=	gró
Af. Stage4_0_1_Resolve_CH_Marker: [gró]
  Stage4_2_LongVowelsOrthoToTempMarker START: In=	gró
  Stage4_2_LongVowelsOrthoToTempMarker END: Out=	gr&O_ACUTE_LONG&
Af. Stage4_2_LongVowelsOrthoToTempMarker: [gr&O_ACUTE_LONG&]
  Stage4_3_DiphthongsOrthoToTempMarker START: In=	gr&O_ACUTE_LONG&
  Stage4_3_DiphthongsOrthoToTempMarker END: Out=	gr&O_ACUTE_LONG&
Af. Stage4_3_DiphthongsOrthoToTempMarker: [gr&O_ACUTE_LONG&]
  Stage4_4_ResolveTempVowelMarkers START: In=	gr&O_ACUTE_LONG&
    DBG (Stage4_4): Iter.gsub: Rule '	&O_ACUTE_LONG&	' APPLIED to '	gr&O_ACUTE_LONG&	' -> '	groː	' (	1	x)
    DBG (Stage4_4): Iter.gsub Pass 1 ended. String changed from '	gr&O_ACUTE_LONG&	' to '	groː	'
    DBG (Stage4_4): Iter.gsub Pass 2 ended. No changes in this pass. String remains: '	groː	'
  Stage4_4_ResolveTempVowelMarkers END: Out=	groː
Af. Stage4_4_ResolveTempVowelMarkers: [groː]
  Stage4_5_ContextualAllophonyOnPhonetic START (Proc): In=	groː
  Stage4_5_ContextualAllophonyOnPhonetic START: In=	groː
    DBG (Stage4_5): Applying placeholder creation rules (ONCE)...
    DBG (Stage4_5): Placeholder created: '	oː	' -> '	&PHON_O_LONG&	'. Result: '	gr&PHON_O_LONG&	'
    DBG (Stage4_5): After placeholder creation: 	gr&PHON_O_LONG&
    DBG (Stage4_5): Applying core allophony rules (iteratively)...
    DBG (Stage4_5): Core Iter.gsub Pass 1 ended. No changes in this pass. String remains: '	gr&PHON_O_LONG&	'
    DBG (Stage4_5): After core allophony rules: 	gr&PHON_O_LONG&
    DBG (Stage4_5): Applying placeholder restoration rules (ONCE)...
    DBG (Stage4_5): Placeholder restored: '	&PHON_O_LONG&	' -> '	oː	'. Result: '	groː	'
    DBG (Stage4_5): After placeholder restoration: 	groː
    DBG (Stage4_5): Applying Connacht ɑu -> əu shift (ONCE)...
    DBG (Stage4_5): After Connacht ɑu->əu shift: 	groː
    DBG (Stage4_5): Applying &TEMP_CONN_AU& -> əu shift (ONCE)...
    DBG (Stage4_5): After &TEMP_CONN_AU&->əu shift: 	groː
  Stage4_5_ContextualAllophonyOnPhonetic END: Out=	groː
Af. Stage4_5_ContextualAllophonyOnPhonetic: [groː]
    DBG (Epenthes): is_likely_monosyllable_revised for '	groː	' (orig: '	groː	') count: 	1	 result: 	true
  EpenthesisAndStrongSonorants START (Proc): In=	groː
  EpenthesisAndStrongSonorants START (Proc): In=	groː
  apply_procedural_epenthesis START: In=	groː
    DBG (Epenthes): Parsed units for epenthesis: 	g(nonpalatal) | r(nonpalatal) | oː(vowel)
    DBG (Epenthes): is_likely_monosyllable_revised for '	groː	' (orig: '	groː	') count: 	1	 result: 	true
  apply_procedural_epenthesis END (no change): Out=	groː
    DBG (Epenthes): After procedural epenthesis: 	groː
    DBG (Epenthes): After strong sonorant rules: 	groː
  EpenthesisAndStrongSonorants END (Proc): Out=	groː
Af. EpenthesisAndStrongSonorants: [groː]
  Diacritics START: In=	groː
  Diacritics END: Out=	groː
Af. Diacritics: [groː]
  FinalCleanup START: In=	groː
  FinalCleanup END: Out=	groː
Af. FinalCleanup: [groː]
gnó            -> [groː]

--- Transcribing: [seilf] ---
Af. MarkDigraphsAndVocalisationTriggers: [seilf]
  ConsonantResolution START (Proc): In=	seilf
  ConsonantResolution START (Proc): In=	seilf
    DBG (Consonan): Metathesis Sub-Stage START: 	seilf
    DBG (Consonan): Metathesis Check: c_base=	s	c_pal=	false	n_base=	e	n_pal=	false	at offset	1
    DBG (Consonan): Metathesis Check: c_base=	e	c_pal=	false	n_base=	i	n_pal=	false	at offset	2
    DBG (Consonan): Metathesis Check: c_base=	i	c_pal=	false	n_base=	l	n_pal=	false	at offset	3
    DBG (Consonan): Metathesis Check: c_base=	l	c_pal=	false	n_base=	f	n_pal=	false	at offset	4
    DBG (Consonan): Metathesis Check: c_base=	f	c_pal=	false	n_base=		n_pal=	false	at offset	5
    DBG (Consonan): Metathesis Sub-Stage END: 	seilf
    DBG (Consonan): After Pass 1 (markers): 	seilf
    DBG (Consonan): Pass 2: Checking '	s	' at phon_idx 	1	 -> ortho_s:	1	ortho_e:	1
    DBG (Consonan): Single cons rule: c_capture=	s	o_s=	1	o_e=	1
    DBG (DetQual): Word:	seilf	Cons seq:	s	s:	1	e:	1
    DBG (DetQual): Next relevant vowel char for quality:	e	Next quality implication:	slender
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	s	': 	palatal
    DBG (Consonan): Pass 2: Replaced '	s	' with '	s'	'
    DBG (Consonan): Pass 2: Checking '	f	' at phon_idx 	5	 -> ortho_s:	5	ortho_e:	5
    DBG (Consonan): Single cons rule: c_capture=	f	o_s=	5	o_e=	5
    DBG (DetQual): Word:	seilf	Cons seq:	f	s:	5	e:	5
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	i	Prev quality implication:	slender
    DBG (DetQual): Final determined quality for '	f	': 	palatal
    DBG (Consonan): Pass 2: Replaced '	f	' with '	f'	'
    DBG (Consonan): After Pass 2 (single chars): 	s'eilf'
  ConsonantResolution END (Proc): Out=	s'eilf'
Af. ConsonantResolution: [s'eilf']
  Stage4_0_SpecificOrthoToTempMarker START: In=	s'eilf'
  Stage4_0_SpecificOrthoToTempMarker END: Out=	s'eilf'
Af. Stage4_0_SpecificOrthoToTempMarker: [s'eilf']
  Stage4_0_1_Resolve_CH_Marker START: In=	s'eilf'
  Stage4_0_1_Resolve_CH_Marker END: Out=	s'eilf'
Af. Stage4_0_1_Resolve_CH_Marker: [s'eilf']
  Stage4_2_LongVowelsOrthoToTempMarker START: In=	s'eilf'
  Stage4_2_LongVowelsOrthoToTempMarker END: Out=	s'eilf'
Af. Stage4_2_LongVowelsOrthoToTempMarker: [s'eilf']
  Stage4_3_DiphthongsOrthoToTempMarker START: In=	s'eilf'
  Stage4_3_DiphthongsOrthoToTempMarker END: Out=	s'&EI_DIPH&lf'
Af. Stage4_3_DiphthongsOrthoToTempMarker: [s'&EI_DIPH&lf']
  Stage4_4_ResolveTempVowelMarkers START: In=	s'&EI_DIPH&lf'
    DBG (Stage4_4): Iter.gsub: Rule '	&EI_DIPH&	' APPLIED to '	s'&EI_DIPH&lf'	' -> '	s'elf'	' (	1	x)
    DBG (Stage4_4): Iter.gsub Pass 1 ended. String changed from '	s'&EI_DIPH&lf'	' to '	s'elf'	'
    DBG (Stage4_4): Iter.gsub Pass 2 ended. No changes in this pass. String remains: '	s'elf'	'
  Stage4_4_ResolveTempVowelMarkers END: Out=	s'elf'
Af. Stage4_4_ResolveTempVowelMarkers: [s'elf']
  Stage4_5_ContextualAllophonyOnPhonetic START (Proc): In=	s'elf'
  Stage4_5_ContextualAllophonyOnPhonetic START: In=	s'elf'
    DBG (Stage4_5): Applying placeholder creation rules (ONCE)...
    DBG (Stage4_5): After placeholder creation: 	s'elf'
    DBG (Stage4_5): Applying core allophony rules (iteratively)...
    DBG (Stage4_5): Core Iter.gsub Pass 1 ended. No changes in this pass. String remains: '	s'elf'	'
    DBG (Stage4_5): After core allophony rules: 	s'elf'
    DBG (Stage4_5): Applying placeholder restoration rules (ONCE)...
    DBG (Stage4_5): After placeholder restoration: 	s'elf'
    DBG (Stage4_5): Applying Connacht ɑu -> əu shift (ONCE)...
    DBG (Stage4_5): After Connacht ɑu->əu shift: 	s'elf'
    DBG (Stage4_5): Applying &TEMP_CONN_AU& -> əu shift (ONCE)...
    DBG (Stage4_5): After &TEMP_CONN_AU&->əu shift: 	s'elf'
  Stage4_5_ContextualAllophonyOnPhonetic END: Out=	s'elf'
Af. Stage4_5_ContextualAllophonyOnPhonetic: [s'elf']
    DBG (Epenthes): is_likely_monosyllable_revised for '	s'elf'	' (orig: '	s'elf'	') count: 	1	 result: 	true
  EpenthesisAndStrongSonorants START (Proc): In=	s'elf'
  EpenthesisAndStrongSonorants START (Proc): In=	s'elf'
  apply_procedural_epenthesis START: In=	s'elf'
    DBG (Epenthes): Parsed units for epenthesis: 	s'(palatal) | e(vowel) | l(nonpalatal) | f'(palatal)
    DBG (Epenthes): is_likely_monosyllable_revised for '	s'elf'	' (orig: '	s'elf'	') count: 	1	 result: 	true
    DBG (Epenthes): Inferred C1 quality to palatal for: 	l	 -> 	l'	 based on V=	e	 and C2=	f'
    DBG (Epenthes): Checking V-C1-C2: 	e	l'	f'	 | Cluster key: 	lf	 | C1 Qual: 	palatal	 | C2 Qual: 	palatal
    DBG (Epenthes): PROCEDURAL Epenthesis Triggered for: 	e	l'	f'	 -> inserting 	i
  apply_procedural_epenthesis END (modified): Out=	s'el'if'
    DBG (Epenthes): After procedural epenthesis: 	s'el'if'
    DBG (Epenthes): After strong sonorant rules: 	s'el'if'
  EpenthesisAndStrongSonorants END (Proc): Out=	s'el'if'
Af. EpenthesisAndStrongSonorants: [s'el'if']
  Diacritics START: In=	s'el'if'
  Diacritics END: Out=	s'el'if'
Af. Diacritics: [s'el'if']
  FinalCleanup START: In=	s'el'if'
  FinalCleanup END: Out=	s'el'if'
Af. FinalCleanup: [s'el'if']
seilf           -> [s'el'if']

--- Transcribing: [dorcha] ---
Af. MarkDigraphsAndVocalisationTriggers: [dor_CH_a]
  ConsonantResolution START (Proc): In=	dor_CH_a
  ConsonantResolution START (Proc): In=	dor_CH_a
    DBG (Consonan): Metathesis Sub-Stage START: 	dor_CH_a
    DBG (Consonan): Metathesis Check: c_base=	d	c_pal=	false	n_base=	o	n_pal=	false	at offset	1
    DBG (Consonan): Metathesis Check: c_base=	o	c_pal=	false	n_base=	r	n_pal=	false	at offset	2
    DBG (Consonan): Metathesis Check: c_base=	r	c_pal=	false	n_base=	_	n_pal=	false	at offset	3
    DBG (Consonan): Metathesis Check: c_base=	_	c_pal=	false	n_base=	C	n_pal=	false	at offset	4
    DBG (Consonan): Metathesis Check: c_base=	C	c_pal=	false	n_base=	H	n_pal=	false	at offset	5
    DBG (Consonan): Metathesis Check: c_base=	H	c_pal=	false	n_base=	_	n_pal=	false	at offset	6
    DBG (Consonan): Metathesis Check: c_base=	_	c_pal=	false	n_base=	a	n_pal=	false	at offset	7
    DBG (Consonan): Metathesis Check: c_base=	a	c_pal=	false	n_base=		n_pal=	false	at offset	8
    DBG (Consonan): Metathesis Sub-Stage END: 	dor_CH_a
    DBG (Consonan): After Pass 1 (markers): 	dor_CH_a
    DBG (Consonan): Pass 2: Checking '	d	' at phon_idx 	1	 -> ortho_s:	1	ortho_e:	1
    DBG (Consonan): Single cons rule: c_capture=	d	o_s=	1	o_e=	1
    DBG (DetQual): Word:	dorcha	Cons seq:	d	s:	1	e:	1
    DBG (DetQual): Next relevant vowel char for quality:	o	Next quality implication:	broad
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	d	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	d	' with '	d	'
    DBG (Consonan): Pass 2: Checking '	r	' at phon_idx 	3	 -> ortho_s:	3	ortho_e:	3
    DBG (Consonan): Single cons rule: c_capture=	r	o_s=	3	o_e=	3
    DBG (DetQual): Word:	dorcha	Cons seq:	r	s:	3	e:	3
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	o	Prev quality implication:	broad
    DBG (DetQual): Final determined quality for '	r	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	r	' with '	r	'
    DBG (Consonan): After Pass 2 (single chars): 	dor_CH_a
  ConsonantResolution END (Proc): Out=	dor_CH_a
Af. ConsonantResolution: [dor_CH_a]
  Stage4_0_SpecificOrthoToTempMarker START: In=	dor_CH_a
  Stage4_0_SpecificOrthoToTempMarker END: Out=	dor_CH_a
Af. Stage4_0_SpecificOrthoToTempMarker: [dor_CH_a]
  Stage4_0_1_Resolve_CH_Marker START: In=	dor_CH_a
    DBG (DetQual): Word:	dorcha	Cons seq:	ch	s:	4	e:	5
    DBG (DetQual): Next relevant vowel char for quality:	a	Next quality implication:	broad
    DBG (DetQual): Prev relevant vowel char for quality:	o	Prev quality implication:	broad
    DBG (DetQual): Final determined quality for '	ch	': 	nonpalatal
  Stage4_0_1_Resolve_CH_Marker END: Out=	dorxa
Af. Stage4_0_1_Resolve_CH_Marker: [dorxa]
  Stage4_2_LongVowelsOrthoToTempMarker START: In=	dorxa
  Stage4_2_LongVowelsOrthoToTempMarker END: Out=	dorxa
Af. Stage4_2_LongVowelsOrthoToTempMarker: [dorxa]
  Stage4_3_DiphthongsOrthoToTempMarker START: In=	dorxa
  Stage4_3_DiphthongsOrthoToTempMarker END: Out=	dorxa
Af. Stage4_3_DiphthongsOrthoToTempMarker: [dorxa]
  Stage4_4_ResolveTempVowelMarkers START: In=	dorxa
    DBG (Stage4_4): Iter.gsub Pass 1 ended. No changes in this pass. String remains: '	dorxa	'
  Stage4_4_ResolveTempVowelMarkers END: Out=	dorxa
Af. Stage4_4_ResolveTempVowelMarkers: [dorxa]
  Stage4_5_ContextualAllophonyOnPhonetic START (Proc): In=	dorxa
  Stage4_5_ContextualAllophonyOnPhonetic START: In=	dorxa
    DBG (Stage4_5): Applying placeholder creation rules (ONCE)...
    DBG (Stage4_5): After placeholder creation: 	dorxa
    DBG (Stage4_5): Applying core allophony rules (iteratively)...
    DBG (Stage4_5): Core Iter.gsub: Rule '	a	' APPLIED to '	dorxa	' -> '	dorxɑ	' (	1	x)
    DBG (Stage4_5): Core Iter.gsub: Rule '	o	' APPLIED to '	dorxɑ	' -> '	dɔrxɑ	' (	1	x)
    DBG (Stage4_5): Core Iter.gsub Pass 1 ended. String changed from '	dorxa	' to '	dɔrxɑ	'
    DBG (Stage4_5): Core Iter.gsub Pass 2 ended. No changes in this pass. String remains: '	dɔrxɑ	'
    DBG (Stage4_5): After core allophony rules: 	dɔrxɑ
    DBG (Stage4_5): Applying placeholder restoration rules (ONCE)...
    DBG (Stage4_5): After placeholder restoration: 	dɔrxɑ
    DBG (Stage4_5): Applying Connacht ɑu -> əu shift (ONCE)...
    DBG (Stage4_5): After Connacht ɑu->əu shift: 	dɔrxɑ
    DBG (Stage4_5): Applying &TEMP_CONN_AU& -> əu shift (ONCE)...
    DBG (Stage4_5): After &TEMP_CONN_AU&->əu shift: 	dɔrxɑ
  Stage4_5_ContextualAllophonyOnPhonetic END: Out=	dɔrxɑ
Af. Stage4_5_ContextualAllophonyOnPhonetic: [dɔrxɑ]
    DBG (Epenthes): is_likely_monosyllable_revised for '	dɔrxɑ	' (orig: '	dɔrxɑ	') count: 	1	 result: 	true
  EpenthesisAndStrongSonorants START (Proc): In=	dɔrxɑ
  EpenthesisAndStrongSonorants START (Proc): In=	dɔrxɑ
  apply_procedural_epenthesis START: In=	dɔrxɑ
    DBG (Epenthes): Parsed units for epenthesis: 	d(palatal) | ɔ(vowel) | r(nonpalatal) | x(unknown) | ɑ(vowel)
    DBG (Epenthes): is_likely_monosyllable_revised for '	dɔrxɑ	' (orig: '	dɔrxɑ	') count: 	1	 result: 	true
    DBG (Epenthes): Checking V-C1-C2: 	ɔ	r	x	 | Cluster key: 	rx	 | C1 Qual: 	nonpalatal	 | C2 Qual: 	unknown
  apply_procedural_epenthesis END (no change): Out=	dɔrxɑ
    DBG (Epenthes): After procedural epenthesis: 	dɔrxɑ
    DBG (Epenthes): After strong sonorant rules: 	dɔrxɑ
  EpenthesisAndStrongSonorants END (Proc): Out=	dɔrxɑ
Af. EpenthesisAndStrongSonorants: [dɔrxɑ]
  Diacritics START: In=	dɔrxɑ
  Diacritics END: Out=	dɔrxɑ
Af. Diacritics: [dɔrxɑ]
  FinalCleanup START: In=	dɔrxɑ
  FinalCleanup END: Out=	dɔrxɑ
Af. FinalCleanup: [dɔrxɑ]
dorcha          -> [dɔrxɑ]

--- Transcribing: [olc] ---
Af. MarkDigraphsAndVocalisationTriggers: [ˈolc]
  ConsonantResolution START (Proc): In=	ˈolc
  ConsonantResolution START (Proc): In=	ˈolc
    DBG (Consonan): Metathesis Sub-Stage START: 	ˈolc
    DBG (Consonan): Metathesis Check: c_base=	o	c_pal=	false	n_base=	l	n_pal=	false	at offset	2
    DBG (Consonan): Metathesis Check: c_base=	l	c_pal=	false	n_base=	c	n_pal=	false	at offset	3
    DBG (Consonan): Metathesis Check: c_base=	c	c_pal=	false	n_base=		n_pal=	false	at offset	4
    DBG (Consonan): Metathesis Sub-Stage END: 	ˈolc
    DBG (Consonan): After Pass 1 (markers): 	ˈolc
    DBG (Consonan): Pass 2: Checking '	c	' at phon_idx 	4	 -> ortho_s:	4	ortho_e:	4
    DBG (Consonan): Single cons rule: c_capture=	c	o_s=	4	o_e=	4
    DBG (DetQual): Word:	ˈolc	Cons seq:	c	s:	4	e:	4
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	o	Prev quality implication:	broad
    DBG (DetQual): Final determined quality for '	c	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	c	' with '	k	'
    DBG (Consonan): After Pass 2 (single chars): 	ˈolk
  ConsonantResolution END (Proc): Out=	ˈolk
Af. ConsonantResolution: [ˈolk]
  Stage4_0_SpecificOrthoToTempMarker START: In=	ˈolk
  Stage4_0_SpecificOrthoToTempMarker END: Out=	ˈolk
Af. Stage4_0_SpecificOrthoToTempMarker: [ˈolk]
  Stage4_0_1_Resolve_CH_Marker START: In=	ˈolk
  Stage4_0_1_Resolve_CH_Marker END: Out=	ˈolk
Af. Stage4_0_1_Resolve_CH_Marker: [ˈolk]
  Stage4_2_LongVowelsOrthoToTempMarker START: In=	ˈolk
  Stage4_2_LongVowelsOrthoToTempMarker END: Out=	ˈolk
Af. Stage4_2_LongVowelsOrthoToTempMarker: [ˈolk]
  Stage4_3_DiphthongsOrthoToTempMarker START: In=	ˈolk
  Stage4_3_DiphthongsOrthoToTempMarker END: Out=	ˈolk
Af. Stage4_3_DiphthongsOrthoToTempMarker: [ˈolk]
  Stage4_4_ResolveTempVowelMarkers START: In=	ˈolk
    DBG (Stage4_4): Iter.gsub Pass 1 ended. No changes in this pass. String remains: '	ˈolk	'
  Stage4_4_ResolveTempVowelMarkers END: Out=	ˈolk
Af. Stage4_4_ResolveTempVowelMarkers: [ˈolk]
  Stage4_5_ContextualAllophonyOnPhonetic START (Proc): In=	ˈolk
  Stage4_5_ContextualAllophonyOnPhonetic START: In=	ˈolk
    DBG (Stage4_5): Applying placeholder creation rules (ONCE)...
    DBG (Stage4_5): After placeholder creation: 	ˈolk
    DBG (Stage4_5): Applying core allophony rules (iteratively)...
    DBG (Stage4_5): Core Iter.gsub: Rule '	o	' APPLIED to '	ˈolk	' -> '	ˈɔlk	' (	1	x)
    DBG (Stage4_5): Core Iter.gsub Pass 1 ended. String changed from '	ˈolk	' to '	ˈɔlk	'
    DBG (Stage4_5): Core Iter.gsub Pass 2 ended. No changes in this pass. String remains: '	ˈɔlk	'
    DBG (Stage4_5): After core allophony rules: 	ˈɔlk
    DBG (Stage4_5): Applying placeholder restoration rules (ONCE)...
    DBG (Stage4_5): After placeholder restoration: 	ˈɔlk
    DBG (Stage4_5): Applying Connacht ɑu -> əu shift (ONCE)...
    DBG (Stage4_5): After Connacht ɑu->əu shift: 	ˈɔlk
    DBG (Stage4_5): Applying &TEMP_CONN_AU& -> əu shift (ONCE)...
    DBG (Stage4_5): After &TEMP_CONN_AU&->əu shift: 	ˈɔlk
  Stage4_5_ContextualAllophonyOnPhonetic END: Out=	ˈɔlk
Af. Stage4_5_ContextualAllophonyOnPhonetic: [ˈɔlk]
    DBG (Epenthes): is_likely_monosyllable_revised for '	ɔlk	' (orig: '	ˈɔlk	') count: 	1	 result: 	true
  EpenthesisAndStrongSonorants START (Proc): In=	ˈɔlk
  EpenthesisAndStrongSonorants START (Proc): In=	ˈɔlk
  apply_procedural_epenthesis START: In=	ˈɔlk
    DBG (Epenthes): Parsed units for epenthesis: 	ˈɔ(vowel) | l(nonpalatal) | k(nonpalatal)
    DBG (Epenthes): is_likely_monosyllable_revised for '	ɔlk	' (orig: '	ˈɔlk	') count: 	1	 result: 	true
    DBG (Epenthes): Checking V-C1-C2: 	ˈɔ	l	k	 | Cluster key: 	lk	 | C1 Qual: 	nonpalatal	 | C2 Qual: 	nonpalatal
    DBG (Epenthes): PROCEDURAL Epenthesis Triggered for: 	ˈɔ	l	k	 -> inserting 	ə
  apply_procedural_epenthesis END (modified): Out=	ˈɔlək
    DBG (Epenthes): After procedural epenthesis: 	ˈɔlək
    DBG (Epenthes): After strong sonorant rules: 	ˈɔlək
  EpenthesisAndStrongSonorants END (Proc): Out=	ˈɔlək
Af. EpenthesisAndStrongSonorants: [ˈɔlək]
  Diacritics START: In=	ˈɔlək
  Diacritics END: Out=	ˈɔlək
Af. Diacritics: [ˈɔlək]
  FinalCleanup START: In=	ˈɔlək
  FinalCleanup END: Out=	ˈɔlək
Af. FinalCleanup: [ˈɔlək]
olc             -> [ˈɔlək]

--- Transcribing: [oilc] ---
Af. MarkDigraphsAndVocalisationTriggers: [ˈoilc]
  ConsonantResolution START (Proc): In=	ˈoilc
  ConsonantResolution START (Proc): In=	ˈoilc
    DBG (Consonan): Metathesis Sub-Stage START: 	ˈoilc
    DBG (Consonan): Metathesis Check: c_base=	o	c_pal=	false	n_base=	i	n_pal=	false	at offset	2
    DBG (Consonan): Metathesis Check: c_base=	i	c_pal=	false	n_base=	l	n_pal=	false	at offset	3
    DBG (Consonan): Metathesis Check: c_base=	l	c_pal=	false	n_base=	c	n_pal=	false	at offset	4
    DBG (Consonan): Metathesis Check: c_base=	c	c_pal=	false	n_base=		n_pal=	false	at offset	5
    DBG (Consonan): Metathesis Sub-Stage END: 	ˈoilc
    DBG (Consonan): After Pass 1 (markers): 	ˈoilc
    DBG (Consonan): Pass 2: Checking '	c	' at phon_idx 	5	 -> ortho_s:	5	ortho_e:	5
    DBG (Consonan): Single cons rule: c_capture=	c	o_s=	5	o_e=	5
    DBG (DetQual): Word:	ˈoilc	Cons seq:	c	s:	5	e:	5
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	i	Prev quality implication:	slender
    DBG (DetQual): Final determined quality for '	c	': 	palatal
    DBG (Consonan): Pass 2: Replaced '	c	' with '	k'	'
    DBG (Consonan): After Pass 2 (single chars): 	ˈoilk'
  ConsonantResolution END (Proc): Out=	ˈoilk'
Af. ConsonantResolution: [ˈoilk']
  Stage4_0_SpecificOrthoToTempMarker START: In=	ˈoilk'
  Stage4_0_SpecificOrthoToTempMarker END: Out=	ˈoilk'
Af. Stage4_0_SpecificOrthoToTempMarker: [ˈoilk']
  Stage4_0_1_Resolve_CH_Marker START: In=	ˈoilk'
  Stage4_0_1_Resolve_CH_Marker END: Out=	ˈoilk'
Af. Stage4_0_1_Resolve_CH_Marker: [ˈoilk']
  Stage4_2_LongVowelsOrthoToTempMarker START: In=	ˈoilk'
  Stage4_2_LongVowelsOrthoToTempMarker END: Out=	ˈoilk'
Af. Stage4_2_LongVowelsOrthoToTempMarker: [ˈoilk']
  Stage4_3_DiphthongsOrthoToTempMarker START: In=	ˈoilk'
  Stage4_3_DiphthongsOrthoToTempMarker END: Out=	ˈ&OI_DIPH&lk'
Af. Stage4_3_DiphthongsOrthoToTempMarker: [ˈ&OI_DIPH&lk']
  Stage4_4_ResolveTempVowelMarkers START: In=	ˈ&OI_DIPH&lk'
    DBG (Stage4_4): Iter.gsub: Rule '	&OI_DIPH&([kgptdfbmnszrlLNRMçjɣŋhwcʃɟɾ]*')	' APPLIED to '	ˈ&OI_DIPH&lk'	' -> '	ˈɛlk'	' (	1	x)
    DBG (Stage4_4): Iter.gsub Pass 1 ended. String changed from '	ˈ&OI_DIPH&lk'	' to '	ˈɛlk'	'
    DBG (Stage4_4): Iter.gsub Pass 2 ended. No changes in this pass. String remains: '	ˈɛlk'	'
  Stage4_4_ResolveTempVowelMarkers END: Out=	ˈɛlk'
Af. Stage4_4_ResolveTempVowelMarkers: [ˈɛlk']
  Stage4_5_ContextualAllophonyOnPhonetic START (Proc): In=	ˈɛlk'
  Stage4_5_ContextualAllophonyOnPhonetic START: In=	ˈɛlk'
    DBG (Stage4_5): Applying placeholder creation rules (ONCE)...
    DBG (Stage4_5): After placeholder creation: 	ˈɛlk'
    DBG (Stage4_5): Applying core allophony rules (iteratively)...
    DBG (Stage4_5): Core Iter.gsub Pass 1 ended. No changes in this pass. String remains: '	ˈɛlk'	'
    DBG (Stage4_5): After core allophony rules: 	ˈɛlk'
    DBG (Stage4_5): Applying placeholder restoration rules (ONCE)...
    DBG (Stage4_5): After placeholder restoration: 	ˈɛlk'
    DBG (Stage4_5): Applying Connacht ɑu -> əu shift (ONCE)...
    DBG (Stage4_5): After Connacht ɑu->əu shift: 	ˈɛlk'
    DBG (Stage4_5): Applying &TEMP_CONN_AU& -> əu shift (ONCE)...
    DBG (Stage4_5): After &TEMP_CONN_AU&->əu shift: 	ˈɛlk'
  Stage4_5_ContextualAllophonyOnPhonetic END: Out=	ˈɛlk'
Af. Stage4_5_ContextualAllophonyOnPhonetic: [ˈɛlk']
    DBG (Epenthes): is_likely_monosyllable_revised for '	ɛlk'	' (orig: '	ˈɛlk'	') count: 	0	 result: 	false
  EpenthesisAndStrongSonorants START (Proc): In=	ˈɛlk'
  EpenthesisAndStrongSonorants START (Proc): In=	ˈɛlk'
  apply_procedural_epenthesis START: In=	ˈɛlk'
    DBG (Epenthes): Parsed units for epenthesis: 	ˈ(stress_mark) | ɛ(unknown_fallback) | l(nonpalatal) | k'(palatal)
    DBG (Epenthes): is_likely_monosyllable_revised for '	ɛlk'	' (orig: '	ˈɛlk'	') count: 	0	 result: 	false
  apply_procedural_epenthesis END (not monosyllable): Out=	ˈɛlk'
    DBG (Epenthes): After procedural epenthesis: 	ˈɛlk'
    DBG (Epenthes): After strong sonorant rules: 	ˈɛlk'
  EpenthesisAndStrongSonorants END (Proc): Out=	ˈɛlk'
Af. EpenthesisAndStrongSonorants: [ˈɛlk']
  Diacritics START: In=	ˈɛlk'
  Diacritics END: Out=	ˈɛlk'
Af. Diacritics: [ˈɛlk']
  FinalCleanup START: In=	ˈɛlk'
  FinalCleanup END: Out=	ˈɛlk'
Af. FinalCleanup: [ˈɛlk']
oilc            -> [ˈɛlk']

--- Transcribing: [dearc] ---
Af. MarkDigraphsAndVocalisationTriggers: [dearc]
  ConsonantResolution START (Proc): In=	dearc
  ConsonantResolution START (Proc): In=	dearc
    DBG (Consonan): Metathesis Sub-Stage START: 	dearc
    DBG (Consonan): Metathesis Check: c_base=	d	c_pal=	false	n_base=	e	n_pal=	false	at offset	1
    DBG (Consonan): Metathesis Check: c_base=	e	c_pal=	false	n_base=	a	n_pal=	false	at offset	2
    DBG (Consonan): Metathesis Check: c_base=	a	c_pal=	false	n_base=	r	n_pal=	false	at offset	3
    DBG (Consonan): Metathesis Check: c_base=	r	c_pal=	false	n_base=	c	n_pal=	false	at offset	4
    DBG (Consonan): Metathesis Check: c_base=	c	c_pal=	false	n_base=		n_pal=	false	at offset	5
    DBG (Consonan): Metathesis Sub-Stage END: 	dearc
    DBG (Consonan): After Pass 1 (markers): 	dearc
    DBG (Consonan): Pass 2: Checking '	d	' at phon_idx 	1	 -> ortho_s:	1	ortho_e:	1
    DBG (Consonan): Single cons rule: c_capture=	d	o_s=	1	o_e=	1
    DBG (DetQual): Word:	dearc	Cons seq:	d	s:	1	e:	1
    DBG (DetQual): Next relevant vowel char for quality:	e	Next quality implication:	slender
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	d	': 	palatal
    DBG (Consonan): Pass 2: Replaced '	d	' with '	d'	'
    DBG (Consonan): Pass 2: Checking '	r	' at phon_idx 	4	 -> ortho_s:	4	ortho_e:	4
    DBG (Consonan): Single cons rule: c_capture=	r	o_s=	4	o_e=	4
    DBG (DetQual): Word:	dearc	Cons seq:	r	s:	4	e:	4
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	e	Prev quality implication:	slender
    DBG (DetQual): Final determined quality for '	r	': 	palatal
    DBG (Consonan): Pass 2: Replaced '	r	' with '	r'	'
    DBG (Consonan): Pass 2: Checking '	c	' at phon_idx 	5	 -> ortho_s:	5	ortho_e:	5
    DBG (Consonan): Single cons rule: c_capture=	c	o_s=	5	o_e=	5
    DBG (DetQual): Word:	dearc	Cons seq:	c	s:	5	e:	5
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	a	Prev quality implication:	broad
    DBG (DetQual): Final determined quality for '	c	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	c	' with '	k	'
    DBG (Consonan): After Pass 2 (single chars): 	d'ear'k
  ConsonantResolution END (Proc): Out=	d'ear'k
Af. ConsonantResolution: [d'ear'k]
  Stage4_0_SpecificOrthoToTempMarker START: In=	d'ear'k
  Stage4_0_SpecificOrthoToTempMarker END: Out=	d'&EA_SLENDER_PRE_RPRIME&r'k
Af. Stage4_0_SpecificOrthoToTempMarker: [d'&EA_SLENDER_PRE_RPRIME&r'k]
  Stage4_0_1_Resolve_CH_Marker START: In=	d'&EA_SLENDER_PRE_RPRIME&r'k
  Stage4_0_1_Resolve_CH_Marker END: Out=	d'&EA_SLENDER_PRE_RPRIME&r'k
Af. Stage4_0_1_Resolve_CH_Marker: [d'&EA_SLENDER_PRE_RPRIME&r'k]
  Stage4_2_LongVowelsOrthoToTempMarker START: In=	d'&EA_SLENDER_PRE_RPRIME&r'k
  Stage4_2_LongVowelsOrthoToTempMarker END: Out=	d'&EA_SLENDER_PRE_RPRIME&r'k
Af. Stage4_2_LongVowelsOrthoToTempMarker: [d'&EA_SLENDER_PRE_RPRIME&r'k]
  Stage4_3_DiphthongsOrthoToTempMarker START: In=	d'&EA_SLENDER_PRE_RPRIME&r'k
  Stage4_3_DiphthongsOrthoToTempMarker END: Out=	d'&EA_SLENDER_PRE_RPRIME&r'k
Af. Stage4_3_DiphthongsOrthoToTempMarker: [d'&EA_SLENDER_PRE_RPRIME&r'k]
  Stage4_4_ResolveTempVowelMarkers START: In=	d'&EA_SLENDER_PRE_RPRIME&r'k
    DBG (Stage4_4): Iter.gsub: Rule '	&EA_SLENDER_PRE_RPRIME&	' APPLIED to '	d'&EA_SLENDER_PRE_RPRIME&r'k	' -> '	d'ær'k	' (	1	x)
    DBG (Stage4_4): Iter.gsub Pass 1 ended. String changed from '	d'&EA_SLENDER_PRE_RPRIME&r'k	' to '	d'ær'k	'
    DBG (Stage4_4): Iter.gsub Pass 2 ended. No changes in this pass. String remains: '	d'ær'k	'
  Stage4_4_ResolveTempVowelMarkers END: Out=	d'ær'k
Af. Stage4_4_ResolveTempVowelMarkers: [d'ær'k]
  Stage4_5_ContextualAllophonyOnPhonetic START (Proc): In=	d'ær'k
  Stage4_5_ContextualAllophonyOnPhonetic START: In=	d'ær'k
    DBG (Stage4_5): Applying placeholder creation rules (ONCE)...
    DBG (Stage4_5): After placeholder creation: 	d'ær'k
    DBG (Stage4_5): Applying core allophony rules (iteratively)...
    DBG (Stage4_5): Core Iter.gsub Pass 1 ended. No changes in this pass. String remains: '	d'ær'k	'
    DBG (Stage4_5): After core allophony rules: 	d'ær'k
    DBG (Stage4_5): Applying placeholder restoration rules (ONCE)...
    DBG (Stage4_5): After placeholder restoration: 	d'ær'k
    DBG (Stage4_5): Applying Connacht ɑu -> əu shift (ONCE)...
    DBG (Stage4_5): After Connacht ɑu->əu shift: 	d'ær'k
    DBG (Stage4_5): Applying &TEMP_CONN_AU& -> əu shift (ONCE)...
    DBG (Stage4_5): After &TEMP_CONN_AU&->əu shift: 	d'ær'k
  Stage4_5_ContextualAllophonyOnPhonetic END: Out=	d'ær'k
Af. Stage4_5_ContextualAllophonyOnPhonetic: [d'ær'k]
    DBG (Epenthes): is_likely_monosyllable_revised for '	d'ær'k	' (orig: '	d'ær'k	') count: 	1	 result: 	true
  EpenthesisAndStrongSonorants START (Proc): In=	d'ær'k
  EpenthesisAndStrongSonorants START (Proc): In=	d'ær'k
  apply_procedural_epenthesis START: In=	d'ær'k
    DBG (Epenthes): Parsed units for epenthesis: 	d'(palatal) | æ(vowel) | r'(palatal) | k(nonpalatal)
    DBG (Epenthes): is_likely_monosyllable_revised for '	d'ær'k	' (orig: '	d'ær'k	') count: 	1	 result: 	true
    DBG (Epenthes): Checking V-C1-C2: 	æ	r'	k	 | Cluster key: 	rk	 | C1 Qual: 	palatal	 | C2 Qual: 	nonpalatal
  apply_procedural_epenthesis END (no change): Out=	d'ær'k
    DBG (Epenthes): After procedural epenthesis: 	d'ær'k
    DBG (Epenthes): After strong sonorant rules: 	d'ær'k
  EpenthesisAndStrongSonorants END (Proc): Out=	d'ær'k
Af. EpenthesisAndStrongSonorants: [d'ær'k]
  Diacritics START: In=	d'ær'k
  Diacritics END: Out=	d'ær'k
Af. Diacritics: [d'ær'k]
  FinalCleanup START: In=	d'ær'k
  FinalCleanup END: Out=	d'ær'k
Af. FinalCleanup: [d'ær'k]
dearc           -> [d'ær'k]

--- Transcribing: [feirc] ---
Af. MarkDigraphsAndVocalisationTriggers: [feirc]
  ConsonantResolution START (Proc): In=	feirc
  ConsonantResolution START (Proc): In=	feirc
    DBG (Consonan): Metathesis Sub-Stage START: 	feirc
    DBG (Consonan): Metathesis Check: c_base=	f	c_pal=	false	n_base=	e	n_pal=	false	at offset	1
    DBG (Consonan): Metathesis Check: c_base=	e	c_pal=	false	n_base=	i	n_pal=	false	at offset	2
    DBG (Consonan): Metathesis Check: c_base=	i	c_pal=	false	n_base=	r	n_pal=	false	at offset	3
    DBG (Consonan): Metathesis Check: c_base=	r	c_pal=	false	n_base=	c	n_pal=	false	at offset	4
    DBG (Consonan): Metathesis Check: c_base=	c	c_pal=	false	n_base=		n_pal=	false	at offset	5
    DBG (Consonan): Metathesis Sub-Stage END: 	feirc
    DBG (Consonan): After Pass 1 (markers): 	feirc
    DBG (Consonan): Pass 2: Checking '	f	' at phon_idx 	1	 -> ortho_s:	1	ortho_e:	1
    DBG (Consonan): Single cons rule: c_capture=	f	o_s=	1	o_e=	1
    DBG (DetQual): Word:	feirc	Cons seq:	f	s:	1	e:	1
    DBG (DetQual): Next relevant vowel char for quality:	e	Next quality implication:	slender
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	f	': 	palatal
    DBG (Consonan): Pass 2: Replaced '	f	' with '	f'	'
    DBG (Consonan): Pass 2: Checking '	r	' at phon_idx 	4	 -> ortho_s:	4	ortho_e:	4
    DBG (Consonan): Single cons rule: c_capture=	r	o_s=	4	o_e=	4
    DBG (DetQual): Word:	feirc	Cons seq:	r	s:	4	e:	4
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	i	Prev quality implication:	slender
    DBG (DetQual): Final determined quality for '	r	': 	palatal
    DBG (Consonan): Pass 2: Replaced '	r	' with '	r'	'
    DBG (Consonan): Pass 2: Checking '	c	' at phon_idx 	5	 -> ortho_s:	5	ortho_e:	5
    DBG (Consonan): Single cons rule: c_capture=	c	o_s=	5	o_e=	5
    DBG (DetQual): Word:	feirc	Cons seq:	c	s:	5	e:	5
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	i	Prev quality implication:	slender
    DBG (DetQual): Final determined quality for '	c	': 	palatal
    DBG (Consonan): Pass 2: Replaced '	c	' with '	k'	'
    DBG (Consonan): After Pass 2 (single chars): 	f'eir'k'
  ConsonantResolution END (Proc): Out=	f'eir'k'
Af. ConsonantResolution: [f'eir'k']
  Stage4_0_SpecificOrthoToTempMarker START: In=	f'eir'k'
  Stage4_0_SpecificOrthoToTempMarker END: Out=	f'eir'k'
Af. Stage4_0_SpecificOrthoToTempMarker: [f'eir'k']
  Stage4_0_1_Resolve_CH_Marker START: In=	f'eir'k'
  Stage4_0_1_Resolve_CH_Marker END: Out=	f'eir'k'
Af. Stage4_0_1_Resolve_CH_Marker: [f'eir'k']
  Stage4_2_LongVowelsOrthoToTempMarker START: In=	f'eir'k'
  Stage4_2_LongVowelsOrthoToTempMarker END: Out=	f'eir'k'
Af. Stage4_2_LongVowelsOrthoToTempMarker: [f'eir'k']
  Stage4_3_DiphthongsOrthoToTempMarker START: In=	f'eir'k'
  Stage4_3_DiphthongsOrthoToTempMarker END: Out=	f'&EI_DIPH&r'k'
Af. Stage4_3_DiphthongsOrthoToTempMarker: [f'&EI_DIPH&r'k']
  Stage4_4_ResolveTempVowelMarkers START: In=	f'&EI_DIPH&r'k'
    DBG (Stage4_4): Iter.gsub: Rule '	&EI_DIPH&	' APPLIED to '	f'&EI_DIPH&r'k'	' -> '	f'er'k'	' (	1	x)
    DBG (Stage4_4): Iter.gsub Pass 1 ended. String changed from '	f'&EI_DIPH&r'k'	' to '	f'er'k'	'
    DBG (Stage4_4): Iter.gsub Pass 2 ended. No changes in this pass. String remains: '	f'er'k'	'
  Stage4_4_ResolveTempVowelMarkers END: Out=	f'er'k'
Af. Stage4_4_ResolveTempVowelMarkers: [f'er'k']
  Stage4_5_ContextualAllophonyOnPhonetic START (Proc): In=	f'er'k'
  Stage4_5_ContextualAllophonyOnPhonetic START: In=	f'er'k'
    DBG (Stage4_5): Applying placeholder creation rules (ONCE)...
    DBG (Stage4_5): After placeholder creation: 	f'er'k'
    DBG (Stage4_5): Applying core allophony rules (iteratively)...
    DBG (Stage4_5): Core Iter.gsub Pass 1 ended. No changes in this pass. String remains: '	f'er'k'	'
    DBG (Stage4_5): After core allophony rules: 	f'er'k'
    DBG (Stage4_5): Applying placeholder restoration rules (ONCE)...
    DBG (Stage4_5): After placeholder restoration: 	f'er'k'
    DBG (Stage4_5): Applying Connacht ɑu -> əu shift (ONCE)...
    DBG (Stage4_5): After Connacht ɑu->əu shift: 	f'er'k'
    DBG (Stage4_5): Applying &TEMP_CONN_AU& -> əu shift (ONCE)...
    DBG (Stage4_5): After &TEMP_CONN_AU&->əu shift: 	f'er'k'
  Stage4_5_ContextualAllophonyOnPhonetic END: Out=	f'er'k'
Af. Stage4_5_ContextualAllophonyOnPhonetic: [f'er'k']
    DBG (Epenthes): is_likely_monosyllable_revised for '	f'er'k'	' (orig: '	f'er'k'	') count: 	1	 result: 	true
  EpenthesisAndStrongSonorants START (Proc): In=	f'er'k'
  EpenthesisAndStrongSonorants START (Proc): In=	f'er'k'
  apply_procedural_epenthesis START: In=	f'er'k'
    DBG (Epenthes): Parsed units for epenthesis: 	f'(palatal) | e(vowel) | r'(palatal) | k'(palatal)
    DBG (Epenthes): is_likely_monosyllable_revised for '	f'er'k'	' (orig: '	f'er'k'	') count: 	1	 result: 	true
    DBG (Epenthes): Checking V-C1-C2: 	e	r'	k'	 | Cluster key: 	rk	 | C1 Qual: 	palatal	 | C2 Qual: 	palatal
    DBG (Epenthes): PROCEDURAL Epenthesis Triggered for: 	e	r'	k'	 -> inserting 	i
  apply_procedural_epenthesis END (modified): Out=	f'er'ik'
    DBG (Epenthes): After procedural epenthesis: 	f'er'ik'
    DBG (Epenthes): After strong sonorant rules: 	f'er'ik'
  EpenthesisAndStrongSonorants END (Proc): Out=	f'er'ik'
Af. EpenthesisAndStrongSonorants: [f'er'ik']
  Diacritics START: In=	f'er'ik'
  Diacritics END: Out=	f'er'ik'
Af. Diacritics: [f'er'ik']
  FinalCleanup START: In=	f'er'ik'
  FinalCleanup END: Out=	f'er'ik'
Af. FinalCleanup: [f'er'ik']
feirc           -> [f'er'ik']

--- Transcribing: [balbh] ---
Af. MarkDigraphsAndVocalisationTriggers: [bal_BH_]
  ConsonantResolution START (Proc): In=	bal_BH_
  ConsonantResolution START (Proc): In=	bal_BH_
    DBG (Consonan): Metathesis Sub-Stage START: 	bal_BH_
    DBG (Consonan): Metathesis Check: c_base=	b	c_pal=	false	n_base=	a	n_pal=	false	at offset	1
    DBG (Consonan): Metathesis Check: c_base=	a	c_pal=	false	n_base=	l	n_pal=	false	at offset	2
    DBG (Consonan): Metathesis Check: c_base=	l	c_pal=	false	n_base=	_	n_pal=	false	at offset	3
    DBG (Consonan): Metathesis Check: c_base=	_	c_pal=	false	n_base=	B	n_pal=	false	at offset	4
    DBG (Consonan): Metathesis Check: c_base=	B	c_pal=	false	n_base=	H	n_pal=	false	at offset	5
    DBG (Consonan): Metathesis Check: c_base=	H	c_pal=	false	n_base=	_	n_pal=	false	at offset	6
    DBG (Consonan): Metathesis Check: c_base=	_	c_pal=	false	n_base=		n_pal=	false	at offset	7
    DBG (Consonan): Metathesis Sub-Stage END: 	bal_BH_
    DBG (DetQual): Word:	balbh	Cons seq:	bh	s:	4	e:	5
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	a	Prev quality implication:	broad
    DBG (DetQual): Final determined quality for '	bh	': 	nonpalatal
    DBG (Consonan): After Pass 1 (markers): 	balv
    DBG (Consonan): Pass 2: Checking '	b	' at phon_idx 	1	 -> ortho_s:	1	ortho_e:	1
    DBG (Consonan): Single cons rule: c_capture=	b	o_s=	1	o_e=	1
    DBG (DetQual): Word:	balbh	Cons seq:	b	s:	1	e:	1
    DBG (DetQual): Next relevant vowel char for quality:	a	Next quality implication:	broad
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	b	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	b	' with '	b	'
    DBG (Consonan): After Pass 2 (single chars): 	balv
  ConsonantResolution END (Proc): Out=	balv
Af. ConsonantResolution: [balv]
  Stage4_0_SpecificOrthoToTempMarker START: In=	balv
  Stage4_0_SpecificOrthoToTempMarker END: Out=	balv
Af. Stage4_0_SpecificOrthoToTempMarker: [balv]
  Stage4_0_1_Resolve_CH_Marker START: In=	balv
  Stage4_0_1_Resolve_CH_Marker END: Out=	balv
Af. Stage4_0_1_Resolve_CH_Marker: [balv]
  Stage4_2_LongVowelsOrthoToTempMarker START: In=	balv
  Stage4_2_LongVowelsOrthoToTempMarker END: Out=	balv
Af. Stage4_2_LongVowelsOrthoToTempMarker: [balv]
  Stage4_3_DiphthongsOrthoToTempMarker START: In=	balv
  Stage4_3_DiphthongsOrthoToTempMarker END: Out=	balv
Af. Stage4_3_DiphthongsOrthoToTempMarker: [balv]
  Stage4_4_ResolveTempVowelMarkers START: In=	balv
    DBG (Stage4_4): Iter.gsub Pass 1 ended. No changes in this pass. String remains: '	balv	'
  Stage4_4_ResolveTempVowelMarkers END: Out=	balv
Af. Stage4_4_ResolveTempVowelMarkers: [balv]
  Stage4_5_ContextualAllophonyOnPhonetic START (Proc): In=	balv
  Stage4_5_ContextualAllophonyOnPhonetic START: In=	balv
    DBG (Stage4_5): Applying placeholder creation rules (ONCE)...
    DBG (Stage4_5): After placeholder creation: 	balv
    DBG (Stage4_5): Applying core allophony rules (iteratively)...
    DBG (Stage4_5): Core Iter.gsub: Rule '	a	' APPLIED to '	balv	' -> '	bɑlv	' (	1	x)
    DBG (Stage4_5): Core Iter.gsub Pass 1 ended. String changed from '	balv	' to '	bɑlv	'
    DBG (Stage4_5): Core Iter.gsub Pass 2 ended. No changes in this pass. String remains: '	bɑlv	'
    DBG (Stage4_5): After core allophony rules: 	bɑlv
    DBG (Stage4_5): Applying placeholder restoration rules (ONCE)...
    DBG (Stage4_5): After placeholder restoration: 	bɑlv
    DBG (Stage4_5): Applying Connacht ɑu -> əu shift (ONCE)...
    DBG (Stage4_5): After Connacht ɑu->əu shift: 	bɑlv
    DBG (Stage4_5): Applying &TEMP_CONN_AU& -> əu shift (ONCE)...
    DBG (Stage4_5): After &TEMP_CONN_AU&->əu shift: 	bɑlv
  Stage4_5_ContextualAllophonyOnPhonetic END: Out=	bɑlv
Af. Stage4_5_ContextualAllophonyOnPhonetic: [bɑlv]
    DBG (Epenthes): is_likely_monosyllable_revised for '	bɑlv	' (orig: '	bɑlv	') count: 	0	 result: 	false
  EpenthesisAndStrongSonorants START (Proc): In=	bɑlv
  EpenthesisAndStrongSonorants START (Proc): In=	bɑlv
  apply_procedural_epenthesis START: In=	bɑlv
    DBG (Epenthes): Parsed units for epenthesis: 	b(nonpalatal) | ɑ(vowel) | l(nonpalatal) | v(unknown)
    DBG (Epenthes): is_likely_monosyllable_revised for '	bɑlv	' (orig: '	bɑlv	') count: 	0	 result: 	false
  apply_procedural_epenthesis END (not monosyllable): Out=	bɑlv
    DBG (Epenthes): After procedural epenthesis: 	bɑlv
    DBG (Epenthes): After strong sonorant rules: 	bɑlv
  EpenthesisAndStrongSonorants END (Proc): Out=	bɑlv
Af. EpenthesisAndStrongSonorants: [bɑlv]
  Diacritics START: In=	bɑlv
  Diacritics END: Out=	bɑlv
Af. Diacritics: [bɑlv]
  FinalCleanup START: In=	bɑlv
  FinalCleanup END: Out=	bɑlv
Af. FinalCleanup: [bɑlv]
balbh           -> [bɑlv]

--- Transcribing: [garbh] ---
Af. MarkDigraphsAndVocalisationTriggers: [gar_BH_]
  ConsonantResolution START (Proc): In=	gar_BH_
  ConsonantResolution START (Proc): In=	gar_BH_
    DBG (Consonan): Metathesis Sub-Stage START: 	gar_BH_
    DBG (Consonan): Metathesis Check: c_base=	g	c_pal=	false	n_base=	a	n_pal=	false	at offset	1
    DBG (Consonan): Metathesis Check: c_base=	a	c_pal=	false	n_base=	r	n_pal=	false	at offset	2
    DBG (Consonan): Metathesis Check: c_base=	r	c_pal=	false	n_base=	_	n_pal=	false	at offset	3
    DBG (Consonan): Metathesis Check: c_base=	_	c_pal=	false	n_base=	B	n_pal=	false	at offset	4
    DBG (Consonan): Metathesis Check: c_base=	B	c_pal=	false	n_base=	H	n_pal=	false	at offset	5
    DBG (Consonan): Metathesis Check: c_base=	H	c_pal=	false	n_base=	_	n_pal=	false	at offset	6
    DBG (Consonan): Metathesis Check: c_base=	_	c_pal=	false	n_base=		n_pal=	false	at offset	7
    DBG (Consonan): Metathesis Sub-Stage END: 	gar_BH_
    DBG (DetQual): Word:	garbh	Cons seq:	bh	s:	4	e:	5
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	a	Prev quality implication:	broad
    DBG (DetQual): Final determined quality for '	bh	': 	nonpalatal
    DBG (Consonan): After Pass 1 (markers): 	garv
    DBG (Consonan): Pass 2: Checking '	g	' at phon_idx 	1	 -> ortho_s:	1	ortho_e:	1
    DBG (Consonan): Single cons rule: c_capture=	g	o_s=	1	o_e=	1
    DBG (DetQual): Word:	garbh	Cons seq:	g	s:	1	e:	1
    DBG (DetQual): Next relevant vowel char for quality:	a	Next quality implication:	broad
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	g	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	g	' with '	g	'
    DBG (Consonan): Pass 2: Checking '	r	' at phon_idx 	3	 -> ortho_s:	3	ortho_e:	3
    DBG (Consonan): Single cons rule: c_capture=	r	o_s=	3	o_e=	3
    DBG (DetQual): Word:	garbh	Cons seq:	r	s:	3	e:	3
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	a	Prev quality implication:	broad
    DBG (DetQual): Final determined quality for '	r	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	r	' with '	r	'
    DBG (Consonan): After Pass 2 (single chars): 	garv
  ConsonantResolution END (Proc): Out=	garv
Af. ConsonantResolution: [garv]
  Stage4_0_SpecificOrthoToTempMarker START: In=	garv
  Stage4_0_SpecificOrthoToTempMarker END: Out=	garv
Af. Stage4_0_SpecificOrthoToTempMarker: [garv]
  Stage4_0_1_Resolve_CH_Marker START: In=	garv
  Stage4_0_1_Resolve_CH_Marker END: Out=	garv
Af. Stage4_0_1_Resolve_CH_Marker: [garv]
  Stage4_2_LongVowelsOrthoToTempMarker START: In=	garv
  Stage4_2_LongVowelsOrthoToTempMarker END: Out=	garv
Af. Stage4_2_LongVowelsOrthoToTempMarker: [garv]
  Stage4_3_DiphthongsOrthoToTempMarker START: In=	garv
  Stage4_3_DiphthongsOrthoToTempMarker END: Out=	garv
Af. Stage4_3_DiphthongsOrthoToTempMarker: [garv]
  Stage4_4_ResolveTempVowelMarkers START: In=	garv
    DBG (Stage4_4): Iter.gsub Pass 1 ended. No changes in this pass. String remains: '	garv	'
  Stage4_4_ResolveTempVowelMarkers END: Out=	garv
Af. Stage4_4_ResolveTempVowelMarkers: [garv]
  Stage4_5_ContextualAllophonyOnPhonetic START (Proc): In=	garv
  Stage4_5_ContextualAllophonyOnPhonetic START: In=	garv
    DBG (Stage4_5): Applying placeholder creation rules (ONCE)...
    DBG (Stage4_5): After placeholder creation: 	garv
    DBG (Stage4_5): Applying core allophony rules (iteratively)...
    DBG (Stage4_5): Core Iter.gsub: Rule '	a	' APPLIED to '	garv	' -> '	gɑrv	' (	1	x)
    DBG (Stage4_5): Core Iter.gsub Pass 1 ended. String changed from '	garv	' to '	gɑrv	'
    DBG (Stage4_5): Core Iter.gsub Pass 2 ended. No changes in this pass. String remains: '	gɑrv	'
    DBG (Stage4_5): After core allophony rules: 	gɑrv
    DBG (Stage4_5): Applying placeholder restoration rules (ONCE)...
    DBG (Stage4_5): After placeholder restoration: 	gɑrv
    DBG (Stage4_5): Applying Connacht ɑu -> əu shift (ONCE)...
    DBG (Stage4_5): After Connacht ɑu->əu shift: 	gɑrv
    DBG (Stage4_5): Applying &TEMP_CONN_AU& -> əu shift (ONCE)...
    DBG (Stage4_5): After &TEMP_CONN_AU&->əu shift: 	gɑrv
  Stage4_5_ContextualAllophonyOnPhonetic END: Out=	gɑrv
Af. Stage4_5_ContextualAllophonyOnPhonetic: [gɑrv]
    DBG (Epenthes): is_likely_monosyllable_revised for '	gɑrv	' (orig: '	gɑrv	') count: 	0	 result: 	false
  EpenthesisAndStrongSonorants START (Proc): In=	gɑrv
  EpenthesisAndStrongSonorants START (Proc): In=	gɑrv
  apply_procedural_epenthesis START: In=	gɑrv
    DBG (Epenthes): Parsed units for epenthesis: 	g(nonpalatal) | ɑ(vowel) | r(nonpalatal) | v(unknown)
    DBG (Epenthes): is_likely_monosyllable_revised for '	gɑrv	' (orig: '	gɑrv	') count: 	0	 result: 	false
  apply_procedural_epenthesis END (not monosyllable): Out=	gɑrv
    DBG (Epenthes): After procedural epenthesis: 	gɑrv
    DBG (Epenthes): After strong sonorant rules: 	gɑrv
  EpenthesisAndStrongSonorants END (Proc): Out=	gɑrv
Af. EpenthesisAndStrongSonorants: [gɑrv]
  Diacritics START: In=	gɑrv
  Diacritics END: Out=	gɑrv
Af. Diacritics: [gɑrv]
  FinalCleanup START: In=	gɑrv
  FinalCleanup END: Out=	gɑrv
Af. FinalCleanup: [gɑrv]
garbh           -> [gɑrv]

--- Transcribing: [gorm] ---
Af. MarkDigraphsAndVocalisationTriggers: [gorm]
  ConsonantResolution START (Proc): In=	gorm
  ConsonantResolution START (Proc): In=	gorm
    DBG (Consonan): Metathesis Sub-Stage START: 	gorm
    DBG (Consonan): Metathesis Check: c_base=	g	c_pal=	false	n_base=	o	n_pal=	false	at offset	1
    DBG (Consonan): Metathesis Check: c_base=	o	c_pal=	false	n_base=	r	n_pal=	false	at offset	2
    DBG (Consonan): Metathesis Check: c_base=	r	c_pal=	false	n_base=	m	n_pal=	false	at offset	3
    DBG (Consonan): Metathesis Check: c_base=	m	c_pal=	false	n_base=		n_pal=	false	at offset	4
    DBG (Consonan): Metathesis Sub-Stage END: 	gorm
    DBG (Consonan): After Pass 1 (markers): 	gorm
    DBG (Consonan): Pass 2: Checking '	g	' at phon_idx 	1	 -> ortho_s:	1	ortho_e:	1
    DBG (Consonan): Single cons rule: c_capture=	g	o_s=	1	o_e=	1
    DBG (DetQual): Word:	gorm	Cons seq:	g	s:	1	e:	1
    DBG (DetQual): Next relevant vowel char for quality:	o	Next quality implication:	broad
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	g	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	g	' with '	g	'
    DBG (Consonan): Pass 2: Checking '	r	' at phon_idx 	3	 -> ortho_s:	3	ortho_e:	3
    DBG (Consonan): Single cons rule: c_capture=	r	o_s=	3	o_e=	3
    DBG (DetQual): Word:	gorm	Cons seq:	r	s:	3	e:	3
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	o	Prev quality implication:	broad
    DBG (DetQual): Final determined quality for '	r	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	r	' with '	r	'
    DBG (Consonan): Pass 2: Checking '	m	' at phon_idx 	4	 -> ortho_s:	4	ortho_e:	4
    DBG (Consonan): Single cons rule: c_capture=	m	o_s=	4	o_e=	4
    DBG (DetQual): Word:	gorm	Cons seq:	m	s:	4	e:	4
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	o	Prev quality implication:	broad
    DBG (DetQual): Final determined quality for '	m	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	m	' with '	m	'
    DBG (Consonan): After Pass 2 (single chars): 	gorm
  ConsonantResolution END (Proc): Out=	gorm
Af. ConsonantResolution: [gorm]
  Stage4_0_SpecificOrthoToTempMarker START: In=	gorm
  Stage4_0_SpecificOrthoToTempMarker END: Out=	gorm
Af. Stage4_0_SpecificOrthoToTempMarker: [gorm]
  Stage4_0_1_Resolve_CH_Marker START: In=	gorm
  Stage4_0_1_Resolve_CH_Marker END: Out=	gorm
Af. Stage4_0_1_Resolve_CH_Marker: [gorm]
  Stage4_2_LongVowelsOrthoToTempMarker START: In=	gorm
  Stage4_2_LongVowelsOrthoToTempMarker END: Out=	gorm
Af. Stage4_2_LongVowelsOrthoToTempMarker: [gorm]
  Stage4_3_DiphthongsOrthoToTempMarker START: In=	gorm
  Stage4_3_DiphthongsOrthoToTempMarker END: Out=	gorm
Af. Stage4_3_DiphthongsOrthoToTempMarker: [gorm]
  Stage4_4_ResolveTempVowelMarkers START: In=	gorm
    DBG (Stage4_4): Iter.gsub Pass 1 ended. No changes in this pass. String remains: '	gorm	'
  Stage4_4_ResolveTempVowelMarkers END: Out=	gorm
Af. Stage4_4_ResolveTempVowelMarkers: [gorm]
  Stage4_5_ContextualAllophonyOnPhonetic START (Proc): In=	gorm
  Stage4_5_ContextualAllophonyOnPhonetic START: In=	gorm
    DBG (Stage4_5): Applying placeholder creation rules (ONCE)...
    DBG (Stage4_5): After placeholder creation: 	gorm
    DBG (Stage4_5): Applying core allophony rules (iteratively)...
    DBG (Stage4_5): Core Iter.gsub: Rule '	o	' APPLIED to '	gorm	' -> '	gɔrm	' (	1	x)
    DBG (Stage4_5): Core Iter.gsub Pass 1 ended. String changed from '	gorm	' to '	gɔrm	'
    DBG (Stage4_5): Core Iter.gsub Pass 2 ended. No changes in this pass. String remains: '	gɔrm	'
    DBG (Stage4_5): After core allophony rules: 	gɔrm
    DBG (Stage4_5): Applying placeholder restoration rules (ONCE)...
    DBG (Stage4_5): After placeholder restoration: 	gɔrm
    DBG (Stage4_5): Applying Connacht ɑu -> əu shift (ONCE)...
    DBG (Stage4_5): After Connacht ɑu->əu shift: 	gɔrm
    DBG (Stage4_5): Applying &TEMP_CONN_AU& -> əu shift (ONCE)...
    DBG (Stage4_5): After &TEMP_CONN_AU&->əu shift: 	gɔrm
  Stage4_5_ContextualAllophonyOnPhonetic END: Out=	gɔrm
Af. Stage4_5_ContextualAllophonyOnPhonetic: [gɔrm]
    DBG (Epenthes): is_likely_monosyllable_revised for '	gɔrm	' (orig: '	gɔrm	') count: 	1	 result: 	true
  EpenthesisAndStrongSonorants START (Proc): In=	gɔrm
  EpenthesisAndStrongSonorants START (Proc): In=	gɔrm
  apply_procedural_epenthesis START: In=	gɔrm
    DBG (Epenthes): Parsed units for epenthesis: 	g(nonpalatal) | ɔ(vowel) | r(nonpalatal) | m(nonpalatal)
    DBG (Epenthes): is_likely_monosyllable_revised for '	gɔrm	' (orig: '	gɔrm	') count: 	1	 result: 	true
  apply_procedural_epenthesis END (no change): Out=	gɔrm
    DBG (Epenthes): After procedural epenthesis: 	gɔrm
    DBG (Epenthes): After strong sonorant rules: 	gɔrm
  EpenthesisAndStrongSonorants END (Proc): Out=	gɔrm
Af. EpenthesisAndStrongSonorants: [gɔrm]
  Diacritics START: In=	gɔrm
  Diacritics END: Out=	gɔrm
Af. Diacritics: [gɔrm]
  FinalCleanup START: In=	gɔrm
  FinalCleanup END: Out=	gɔrm
Af. FinalCleanup: [gɔrm]
gorm            -> [gɔrm]

--- Transcribing: [bolg] ---
Af. MarkDigraphsAndVocalisationTriggers: [bolg]
  ConsonantResolution START (Proc): In=	bolg
  ConsonantResolution START (Proc): In=	bolg
    DBG (Consonan): Metathesis Sub-Stage START: 	bolg
    DBG (Consonan): Metathesis Check: c_base=	b	c_pal=	false	n_base=	o	n_pal=	false	at offset	1
    DBG (Consonan): Metathesis Check: c_base=	o	c_pal=	false	n_base=	l	n_pal=	false	at offset	2
    DBG (Consonan): Metathesis Check: c_base=	l	c_pal=	false	n_base=	g	n_pal=	false	at offset	3
    DBG (Consonan): Metathesis Check: c_base=	g	c_pal=	false	n_base=		n_pal=	false	at offset	4
    DBG (Consonan): Metathesis Sub-Stage END: 	bolg
    DBG (Consonan): After Pass 1 (markers): 	bolg
    DBG (Consonan): Pass 2: Checking '	b	' at phon_idx 	1	 -> ortho_s:	1	ortho_e:	1
    DBG (Consonan): Single cons rule: c_capture=	b	o_s=	1	o_e=	1
    DBG (DetQual): Word:	bolg	Cons seq:	b	s:	1	e:	1
    DBG (DetQual): Next relevant vowel char for quality:	o	Next quality implication:	broad
    DBG (DetQual): Prev relevant vowel char for quality:	nil	Prev quality implication:	nil
    DBG (DetQual): Final determined quality for '	b	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	b	' with '	b	'
    DBG (Consonan): Pass 2: Checking '	g	' at phon_idx 	4	 -> ortho_s:	4	ortho_e:	4
    DBG (Consonan): Single cons rule: c_capture=	g	o_s=	4	o_e=	4
    DBG (DetQual): Word:	bolg	Cons seq:	g	s:	4	e:	4
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	o	Prev quality implication:	broad
    DBG (DetQual): Final determined quality for '	g	': 	nonpalatal
    DBG (Consonan): Pass 2: Replaced '	g	' with '	g	'
    DBG (Consonan): After Pass 2 (single chars): 	bolg
  ConsonantResolution END (Proc): Out=	bolg
Af. ConsonantResolution: [bolg]
  Stage4_0_SpecificOrthoToTempMarker START: In=	bolg
  Stage4_0_SpecificOrthoToTempMarker END: Out=	bolg
Af. Stage4_0_SpecificOrthoToTempMarker: [bolg]
  Stage4_0_1_Resolve_CH_Marker START: In=	bolg
  Stage4_0_1_Resolve_CH_Marker END: Out=	bolg
Af. Stage4_0_1_Resolve_CH_Marker: [bolg]
  Stage4_2_LongVowelsOrthoToTempMarker START: In=	bolg
  Stage4_2_LongVowelsOrthoToTempMarker END: Out=	bolg
Af. Stage4_2_LongVowelsOrthoToTempMarker: [bolg]
  Stage4_3_DiphthongsOrthoToTempMarker START: In=	bolg
  Stage4_3_DiphthongsOrthoToTempMarker END: Out=	bolg
Af. Stage4_3_DiphthongsOrthoToTempMarker: [bolg]
  Stage4_4_ResolveTempVowelMarkers START: In=	bolg
    DBG (Stage4_4): Iter.gsub Pass 1 ended. No changes in this pass. String remains: '	bolg	'
  Stage4_4_ResolveTempVowelMarkers END: Out=	bolg
Af. Stage4_4_ResolveTempVowelMarkers: [bolg]
  Stage4_5_ContextualAllophonyOnPhonetic START (Proc): In=	bolg
  Stage4_5_ContextualAllophonyOnPhonetic START: In=	bolg
    DBG (Stage4_5): Applying placeholder creation rules (ONCE)...
    DBG (Stage4_5): After placeholder creation: 	bolg
    DBG (Stage4_5): Applying core allophony rules (iteratively)...
    DBG (Stage4_5): Core Iter.gsub: Rule '	o	' APPLIED to '	bolg	' -> '	bɔlg	' (	1	x)
    DBG (Stage4_5): Core Iter.gsub Pass 1 ended. String changed from '	bolg	' to '	bɔlg	'
    DBG (Stage4_5): Core Iter.gsub Pass 2 ended. No changes in this pass. String remains: '	bɔlg	'
    DBG (Stage4_5): After core allophony rules: 	bɔlg
    DBG (Stage4_5): Applying placeholder restoration rules (ONCE)...
    DBG (Stage4_5): After placeholder restoration: 	bɔlg
    DBG (Stage4_5): Applying Connacht ɑu -> əu shift (ONCE)...
    DBG (Stage4_5): After Connacht ɑu->əu shift: 	bɔlg
    DBG (Stage4_5): Applying &TEMP_CONN_AU& -> əu shift (ONCE)...
    DBG (Stage4_5): After &TEMP_CONN_AU&->əu shift: 	bɔlg
  Stage4_5_ContextualAllophonyOnPhonetic END: Out=	bɔlg
Af. Stage4_5_ContextualAllophonyOnPhonetic: [bɔlg]
    DBG (Epenthes): is_likely_monosyllable_revised for '	bɔlg	' (orig: '	bɔlg	') count: 	1	 result: 	true
  EpenthesisAndStrongSonorants START (Proc): In=	bɔlg
  EpenthesisAndStrongSonorants START (Proc): In=	bɔlg
  apply_procedural_epenthesis START: In=	bɔlg
    DBG (Epenthes): Parsed units for epenthesis: 	b(nonpalatal) | ɔ(vowel) | l(nonpalatal) | g(nonpalatal)
    DBG (Epenthes): is_likely_monosyllable_revised for '	bɔlg	' (orig: '	bɔlg	') count: 	1	 result: 	true
    DBG (Epenthes): Checking V-C1-C2: 	ɔ	l	g	 | Cluster key: 	lg	 | C1 Qual: 	nonpalatal	 | C2 Qual: 	nonpalatal
    DBG (Epenthes): PROCEDURAL Epenthesis Triggered for: 	ɔ	l	g	 -> inserting 	ə
  apply_procedural_epenthesis END (modified): Out=	bɔləg
    DBG (Epenthes): After procedural epenthesis: 	bɔləg
    DBG (Epenthes): After strong sonorant rules: 	bɔləg
  EpenthesisAndStrongSonorants END (Proc): Out=	bɔləg
Af. EpenthesisAndStrongSonorants: [bɔləg]
  Diacritics START: In=	bɔləg
  Diacritics END: Out=	bɔləg
Af. Diacritics: [bɔləg]
  FinalCleanup START: In=	bɔləg
  FinalCleanup END: Out=	bɔləg
Af. FinalCleanup: [bɔləg]
bolg            -> [bɔləg]

--- Transcribing: [ainm] ---
Af. MarkDigraphsAndVocalisationTriggers: [ˈainm]
  ConsonantResolution START (Proc): In=	ˈainm
  ConsonantResolution START (Proc): In=	ˈainm
    DBG (Consonan): Metathesis Sub-Stage START: 	ˈainm
    DBG (Consonan): Metathesis Check: c_base=	a	c_pal=	false	n_base=	i	n_pal=	false	at offset	2
    DBG (Consonan): Metathesis Check: c_base=	i	c_pal=	false	n_base=	n	n_pal=	false	at offset	3
    DBG (Consonan): Metathesis Check: c_base=	n	c_pal=	false	n_base=	m	n_pal=	false	at offset	4
    DBG (Consonan): Metathesis Check: c_base=	m	c_pal=	false	n_base=		n_pal=	false	at offset	5
    DBG (Consonan): Metathesis Sub-Stage END: 	ˈainm
    DBG (Consonan): After Pass 1 (markers): 	ˈainm
    DBG (Consonan): Pass 2: Checking '	m	' at phon_idx 	5	 -> ortho_s:	5	ortho_e:	5
    DBG (Consonan): Single cons rule: c_capture=	m	o_s=	5	o_e=	5
    DBG (DetQual): Word:	ˈainm	Cons seq:	m	s:	5	e:	5
    DBG (DetQual): Next relevant vowel char for quality:	nil	Next quality implication:	nil
    DBG (DetQual): Prev relevant vowel char for quality:	i	Prev quality implication:	slender
    DBG (DetQual): Final determined quality for '	m	': 	palatal
    DBG (Consonan): Pass 2: Replaced '	m	' with '	m'	'
    DBG (Consonan): After Pass 2 (single chars): 	ˈainm'
  ConsonantResolution END (Proc): Out=	ˈainm'
Af. ConsonantResolution: [ˈainm']
  Stage4_0_SpecificOrthoToTempMarker START: In=	ˈainm'
  Stage4_0_SpecificOrthoToTempMarker END: Out=	ˈainm'
Af. Stage4_0_SpecificOrthoToTempMarker: [ˈainm']
  Stage4_0_1_Resolve_CH_Marker START: In=	ˈainm'
  Stage4_0_1_Resolve_CH_Marker END: Out=	ˈainm'
Af. Stage4_0_1_Resolve_CH_Marker: [ˈainm']
  Stage4_2_LongVowelsOrthoToTempMarker START: In=	ˈainm'
  Stage4_2_LongVowelsOrthoToTempMarker END: Out=	ˈainm'
Af. Stage4_2_LongVowelsOrthoToTempMarker: [ˈainm']
  Stage4_3_DiphthongsOrthoToTempMarker START: In=	ˈainm'
  Stage4_3_DiphthongsOrthoToTempMarker END: Out=	ˈ&AI_DIPH&nm'
Af. Stage4_3_DiphthongsOrthoToTempMarker: [ˈ&AI_DIPH&nm']
  Stage4_4_ResolveTempVowelMarkers START: In=	ˈ&AI_DIPH&nm'
    DBG (Stage4_4): Iter.gsub: Rule '	&AI_DIPH&(nm')	' APPLIED to '	ˈ&AI_DIPH&nm'	' -> '	ˈanm'	' (	1	x)
    DBG (Stage4_4): Iter.gsub Pass 1 ended. String changed from '	ˈ&AI_DIPH&nm'	' to '	ˈanm'	'
    DBG (Stage4_4): Iter.gsub Pass 2 ended. No changes in this pass. String remains: '	ˈanm'	'
  Stage4_4_ResolveTempVowelMarkers END: Out=	ˈanm'
Af. Stage4_4_ResolveTempVowelMarkers: [ˈanm']
  Stage4_5_ContextualAllophonyOnPhonetic START (Proc): In=	ˈanm'
  Stage4_5_ContextualAllophonyOnPhonetic START: In=	ˈanm'
    DBG (Stage4_5): Applying placeholder creation rules (ONCE)...
    DBG (Stage4_5): After placeholder creation: 	ˈanm'
    DBG (Stage4_5): Applying core allophony rules (iteratively)...
    DBG (Stage4_5): Core Iter.gsub: Rule '	a	' APPLIED to '	ˈanm'	' -> '	ˈɑnm'	' (	1	x)
    DBG (Stage4_5): Core Iter.gsub Pass 1 ended. String changed from '	ˈanm'	' to '	ˈɑnm'	'
    DBG (Stage4_5): Core Iter.gsub Pass 2 ended. No changes in this pass. String remains: '	ˈɑnm'	'
    DBG (Stage4_5): After core allophony rules: 	ˈɑnm'
    DBG (Stage4_5): Applying placeholder restoration rules (ONCE)...
    DBG (Stage4_5): After placeholder restoration: 	ˈɑnm'
    DBG (Stage4_5): Applying Connacht ɑu -> əu shift (ONCE)...
    DBG (Stage4_5): After Connacht ɑu->əu shift: 	ˈɑnm'
    DBG (Stage4_5): Applying &TEMP_CONN_AU& -> əu shift (ONCE)...
    DBG (Stage4_5): After &TEMP_CONN_AU&->əu shift: 	ˈɑnm'
  Stage4_5_ContextualAllophonyOnPhonetic END: Out=	ˈɑnm'
Af. Stage4_5_ContextualAllophonyOnPhonetic: [ˈɑnm']
    DBG (Epenthes): is_likely_monosyllable_revised for '	ɑnm'	' (orig: '	ˈɑnm'	') count: 	0	 result: 	false
  EpenthesisAndStrongSonorants START (Proc): In=	ˈɑnm'
  EpenthesisAndStrongSonorants START (Proc): In=	ˈɑnm'
  apply_procedural_epenthesis START: In=	ˈɑnm'
    DBG (Epenthes): Parsed units for epenthesis: 	ˈ(stress_mark) | ɑ(vowel) | n(nonpalatal) | m'(palatal)
    DBG (Epenthes): is_likely_monosyllable_revised for '	ɑnm'	' (orig: '	ˈɑnm'	') count: 	0	 result: 	false
  apply_procedural_epenthesis END (not monosyllable): Out=	ˈɑnm'
    DBG (Epenthes): After procedural epenthesis: 	ˈɑnm'
    DBG (Epenthes): After strong sonorant rules: 	ˈɑnm'
  EpenthesisAndStrongSonorants END (Proc): Out=	ˈɑnm'
Af. EpenthesisAndStrongSonorants: [ˈɑnm']
  Diacritics START: In=	ˈɑnm'
  Diacritics END: Out=	ˈɑnm'
Af. Diacritics: [ˈɑnm']
  FinalCleanup START: In=	ˈɑnm'
  FinalCleanup END: Out=	ˈɑnm'
Af. FinalCleanup: [ˈɑnm']
ainm            -> [ˈɑnm']
"""