--[[
    Phonetic Transcription Script for Modern Irish (Iteration 37P)
    Focus: 
           1. Refine vocalization of _BH_ and _MH_ based on preceding short vowel and position (final/medial).
           2. Introduce new temp markers in Stage 4.0 and resolve them in Stage 4.4.
           3. Test with relevant words: samhradh, gabhar, leabhar, cnámh, snámh, damhsa, amharc, lámh, dubh, abhainn.
]]

-- Debug output file setup
local debug_file_path = "irish_debug_37P_targeted.txt" 
local debug_file = io.open(debug_file_path, "w")
if debug_file then
    debug_file:write("\239\187\191") -- UTF-8 BOM
else
    local original_print_func_early = print
    original_print_func_early("WARN: No debug_file " .. debug_file_path)
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
    Stage4_1_VocmarkToTempMarker = true,    
    Stage4_2_LongVowelsOrthoToTempMarker = true, 
    Stage4_3_DiphthongsOrthoToTempMarker = true, 
    Stage4_4_ResolveTempVowelMarkers = true, 
    Stage4_5_ContextualAllophonyOnPhonetic = true, 
    Stage4_6_UnstressedVowelReduction_Procedural = true, 
    EpenthesisThenStrongSonorants = true, 
    Diacritics = true,                
    FinalCleanup = true,
}

-- Overridden print for general stage boundaries and final output
print = function(...) 
    local args = {...}
    local str_args = {}
    for i, v in ipairs(args) do
        str_args[i] = tostring(v)
    end
    local msg = table.concat(str_args, "\t")
    original_print_func(msg) 
    if debug_file then
        debug_file:write(msg .. "\n")
        debug_file:flush()
    end
end

-- Helper for detailed, conditional debug printing
local function debug_print_detailed(stage_name_for_flag_check, ...)
    if DETAILED_DEBUG_ENABLED or (STAGE_DEBUG_ENABLED[stage_name_for_flag_check]) then
        local args = {...}
        local str_args = {}
        for i, v in ipairs(args) do
            str_args[i] = tostring(v)
        end
        local msg = "    DBG (" .. stage_name_for_flag_check:sub(1,8) .. "): " .. table.concat(str_args, "\t") 
        original_print_func(msg) 
        if debug_file then
            debug_file:write(msg .. "\n")
            debug_file:flush()
        end
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
local ANY_CONSONANT_PHONETIC_OR_STRESS_PATTERN = "[" .. ANY_CONSONANT_PHONETIC_RAW_CHARS_STR .. "ˈ]"


local ANY_SHORT_VOWEL_PHONETIC_CHARS_STR = "aæɔeəiɪuʊʌ" 
local ANY_LONG_VOWEL_PHONETIC_CHARS_STR = "ɑeioɨuæ" 
local ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR = ANY_SHORT_VOWEL_PHONETIC_CHARS_STR .. ANY_LONG_VOWEL_PHONETIC_CHARS_STR

local ANY_DIPHTHONG_PHONETIC_STR_NO_CAPTURE = "(?:ia)|(?:ua)|(?:ai)|(?:ei)|(?:oi)|(?:ui)|(?:ɑu)|(?:ou)|(?:əu)|(?:eiə)" 
local SINGLE_VOWEL_WITH_OPT_LONG_STR_NO_CAPTURE = "(?:[" .. ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR .. "]ː?)" 

local PHONETIC_VOWEL_NUCLEUS_STRING_FOR_CAPTURE = ANY_DIPHTHONG_PHONETIC_STR_NO_CAPTURE .. "|" .. SINGLE_VOWEL_WITH_OPT_LONG_STR_NO_CAPTURE
local PHONETIC_VOWEL_NUCLEUS_PATTERN = "(" .. PHONETIC_VOWEL_NUCLEUS_STRING_FOR_CAPTURE .. ")"
debug_print_detailed("Setup", "PHONETIC_VOWEL_NUCLEUS_PATTERN:", PHONETIC_VOWEL_NUCLEUS_PATTERN)

local SHORT_VOWEL_PHONETIC_PATTERN_FOR_REDUCTION_INPUT = "["..ANY_SHORT_VOWEL_PHONETIC_CHARS_STR:gsub("[əɪi]", "").."]" 
local SHORT_VOWEL_CAPTURE_FOR_EPENTHESIS = "([" .. ANY_SHORT_VOWEL_PHONETIC_CHARS_STR .. "])"


-- Helper functions
local function determine_consonant_quality_ortho(original_ortho_word, ortho_cons_char_start_idx, ortho_cons_char_end_idx)
    debug_print_detailed("ConsonantResolution", "  determine_consonant_quality_ortho: word='", original_ortho_word, "', s_idx=", ortho_cons_char_start_idx, ", e_idx=", ortho_cons_char_end_idx)
    if not original_ortho_word or not ortho_cons_char_start_idx or not ortho_cons_char_end_idx or ortho_cons_char_start_idx <= 0 or ortho_cons_char_end_idx > #original_ortho_word or ortho_cons_char_start_idx > ortho_cons_char_end_idx then
        debug_print_detailed("ConsonantResolution", "  determine_consonant_quality_ortho: Invalid indices or word. Returning nonpalatal.")
        return "nonpalatal" 
    end
    local current_ortho_cons_seq = original_ortho_word:sub(ortho_cons_char_start_idx, ortho_cons_char_end_idx)
    debug_print_detailed("ConsonantResolution", "  determine_consonant_quality_ortho: current_ortho_cons_seq='", current_ortho_cons_seq, "'")

    if current_ortho_cons_seq == "l°" or current_ortho_cons_seq == "n°" then
        debug_print_detailed("ConsonantResolution", "  determine_consonant_quality_ortho: l°/n° marker. Returning nonpalatal.")
        return "nonpalatal"
    end

    if current_ortho_cons_seq == "n" and ortho_cons_char_start_idx > 2 then
        local preceding_ea = original_ortho_word:sub(ortho_cons_char_start_idx - 2, ortho_cons_char_start_idx - 1)
        debug_print_detailed("ConsonantResolution", "  determine_consonant_quality_ortho: Checking 'ean' for 'n'. Preceding bigram: '", preceding_ea, "'")
        if preceding_ea == "ea" then
            local is_final_ean = (ortho_cons_char_end_idx == #original_ortho_word)
            local next_char_after_n_idx = ortho_cons_char_end_idx + 1
            local next_char_is_consonant_or_nothing = true 
            if next_char_after_n_idx <= #original_ortho_word then
                if not original_ortho_word:sub(next_char_after_n_idx, next_char_after_n_idx):match("[" .. CONSONANTS_ORTHO_CHARS_STR .. "]") then
                    next_char_is_consonant_or_nothing = false 
                end
            end

            if is_final_ean or next_char_is_consonant_or_nothing then
                debug_print_detailed("ConsonantResolution", "  determine_consonant_quality_ortho: Special 'ean' case for 'n' (final or before C). Returning palatal.")
                return "palatal"
            end
        end
    end


    local prev_v_type_char, next_v_type_char = nil, nil
    local temp_idx = ortho_cons_char_end_idx + 1
    while temp_idx <= #original_ortho_word do
        local char = original_ortho_word:sub(temp_idx, temp_idx)
        if char:match(ALL_VOWELS_ORTHO_PATTERN) then next_v_type_char = char; break
        elseif (char == "l" or char == "n") and original_ortho_word:sub(temp_idx+1, temp_idx+1) == "°" then next_v_type_char = "a"; break
        elseif char:match("[" .. CONSONANTS_ORTHO_CHARS_STR .. CONSONANTS_ORTHO_CHARS_STR:upper() .. "°%-]") then else break end
        temp_idx = temp_idx + 1
    end
    local next_v_quality_implication = next_v_type_char and (next_v_type_char:match(SLENDER_VOWELS_ORTHO_PATTERN) and "slender" or "broad") or nil
    debug_print_detailed("ConsonantResolution", "  determine_consonant_quality_ortho: next_v_type_char='", next_v_type_char or "nil", "', next_v_quality_implication='", next_v_quality_implication or "nil", "'")

    temp_idx = ortho_cons_char_start_idx - 1
    while temp_idx >= 1 do
        local char = original_ortho_word:sub(temp_idx, temp_idx)
        if char:match(ALL_VOWELS_ORTHO_PATTERN) then
            local v_group_end = temp_idx; local v_group_start = temp_idx
            while v_group_start > 1 and original_ortho_word:sub(v_group_start - 1, v_group_start - 1):match(ALL_VOWELS_ORTHO_PATTERN) do v_group_start = v_group_start - 1 end
            local preceding_vowel_group = original_ortho_word:sub(v_group_start, v_group_end)
            local is_final_cons_in_word = ortho_cons_char_end_idx == #original_ortho_word or not original_ortho_word:sub(ortho_cons_char_end_idx + 1, ortho_cons_char_end_idx + 1):match("["..ALL_VOWELS_ORTHO_CHARS_STR..CONSONANTS_ORTHO_CHARS_STR..CONSONANTS_ORTHO_CHARS_STR:upper().."]")
            if preceding_vowel_group == "ea" and (current_ortho_cons_seq == "ch" or current_ortho_cons_seq == "g" or current_ortho_cons_seq == "r" or current_ortho_cons_seq == "_CH_" or current_ortho_cons_seq == "_GH_") then prev_v_type_char = original_ortho_word:sub(v_group_start,v_group_start) 
            elseif preceding_vowel_group == "iu" and is_final_cons_in_word then prev_v_type_char = "i"
            else prev_v_type_char = original_ortho_word:sub(v_group_end, v_group_end) end
            break
        elseif original_ortho_word:sub(temp_idx-1, temp_idx) == "l°" or original_ortho_word:sub(temp_idx-1, temp_idx) == "n°" then if temp_idx == ortho_cons_char_start_idx -1 then prev_v_type_char = "a"; break end
        elseif char:match("[" .. CONSONANTS_ORTHO_CHARS_STR .. CONSONANTS_ORTHO_CHARS_STR:upper() .. "°%-]") then else break end
        temp_idx = temp_idx - 1
    end
    local prev_v_quality_implication = prev_v_type_char and (prev_v_type_char:match(SLENDER_VOWELS_ORTHO_PATTERN) and "slender" or "broad") or nil
    debug_print_detailed("ConsonantResolution", "  determine_consonant_quality_ortho: prev_v_type_char='", prev_v_type_char or "nil", "', prev_v_quality_implication='", prev_v_quality_implication or "nil", "'")
    
    local final_quality
    if next_v_quality_implication == "slender" then final_quality = "palatal"
    elseif next_v_quality_implication == "broad" then final_quality = "nonpalatal"
    elseif prev_v_quality_implication == "slender" then final_quality = "palatal"
    elseif prev_v_quality_implication == "broad" then final_quality = "nonpalatal"
    else final_quality = "nonpalatal" end
    debug_print_detailed("ConsonantResolution", "  determine_consonant_quality_ortho: FINAL DECISION for '", current_ortho_cons_seq, "' in '", original_ortho_word, "' is: ", final_quality)
    return final_quality
end

local function is_likely_monosyllable_phonetic(phon_word)
    if not phon_word then debug_print_detailed("EpenthesisThenStrongSonorants", "is_likely_monosyllable_phonetic: input nil, returning false"); return false end
    local no_stress = phon_word:gsub("ˈ", "")
    local count = 0
    local i = 1
    while i <= #no_stress do
        local matched_nucleus = false
        -- Check for diphthongs first
        for diph in ANY_DIPHTHONG_PHONETIC_STR_NO_CAPTURE:gsub("%(%?:(.-)%)", "%1"):gmatch("[^|]+") do
            if no_stress:sub(i, i + #diph - 1) == diph then
                count = count + 1
                i = i + #diph
                matched_nucleus = true
                break
            end
        end
        if matched_nucleus then goto continue_loop end

        -- Check for single vowels (long or short)
        local char = no_stress:sub(i, i)
        if char:match("[" .. ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR .. "]") then
            count = count + 1
            if i + 1 <= #no_stress and no_stress:sub(i + 1, i + 1) == "ː" then
                i = i + 2 
            else
                i = i + 1 
            end
            matched_nucleus = true
        end
        
        if not matched_nucleus then
            i = i + 1 -- Skip consonant or other char
        end
        ::continue_loop::
    end
    debug_print_detailed("EpenthesisThenStrongSonorants", "is_likely_monosyllable_phonetic: Word='", phon_word, "', NoStress='", no_stress, "', NucleiCount=", count, ", Result=", (count == 1))
    return count == 1
end


local function is_stressed_monosyllable_phonetic(phon_word)
    if not is_likely_monosyllable_phonetic(phon_word) then return false end
    if phon_word:match("^ˈ") then return true end
    if not phon_word:match("ˈ") and #phon_word > 1 and not (phon_word:match("^"..PHONETIC_VOWEL_NUCLEUS_PATTERN.."$") and #phon_word == 1) then return true end
    return false
end

local UNSTRESSED_PREFIXES_ORTHO = {"an%-", "droch%-", "mí%-", "do%-", "ró%-", "dea%-", "fíor%-", "sean%-", "ath%-", "comh%-", "fo%-", "frith%-", "idir%-", "in%-", "réamh%-", "so%-", "tras%-", "mór%-", "ban%-", "cam%-", "fionn%-", "leas%-"}

-- Refactored helper for Stage 3 consonant resolution
local function resolve_lenited_consonant(base_phoneme_palatal, base_phoneme_nonpalatal, full_match_marker, o_context_str, original_match_info_tbl, options)
    options = options or {}
    debug_print_detailed("ConsonantResolution", "  ENTER resolve_lenited_consonant for marker: ", full_match_marker, " palatal_opt: ", base_phoneme_palatal, " nonpal_opt: ", base_phoneme_nonpalatal)
    if not original_match_info_tbl or not original_match_info_tbl.ortho_s or not original_match_info_tbl.ortho_e then 
        debug_print_detailed("ConsonantResolution", "    resolve_lenited_consonant: no original_match_info_tbl, returning nonpalatal: ", base_phoneme_nonpalatal)
        return base_phoneme_nonpalatal 
    end
    local quality = determine_consonant_quality_ortho(o_context_str, original_match_info_tbl.ortho_s, original_match_info_tbl.ortho_e)
    debug_print_detailed("ConsonantResolution", "    resolve_lenited_consonant: Quality determined as: ", quality)
    
    if options.can_be_w and quality == "nonpalatal" then
        local next_v_char_idx = original_match_info_tbl.ortho_e + 1
        if next_v_char_idx <= #o_context_str then
            local next_char = o_context_str:sub(next_v_char_idx, next_v_char_idx)
            if next_char:match(BROAD_VOWELS_ORTHO_PATTERN) then
                local prev_char_idx = original_match_info_tbl.ortho_s - 1
                if prev_char_idx >= 1 then
                    local prev_char = o_context_str:sub(prev_char_idx, prev_char_idx)
                    if not prev_char:match("[rlcsrlnLNRM]'?$") then 
                        debug_print_detailed("ConsonantResolution", "    resolve_lenited_consonant: can_be_w, nonpalatal, next is broad, prev not sonorant. Returning 'w'")
                        return "w" 
                    end
                else 
                    debug_print_detailed("ConsonantResolution", "    resolve_lenited_consonant: can_be_w, nonpalatal, next is broad, at word start. Returning 'w'")
                    return "w" 
                end 
            end
        end
    end
    
    local result_phoneme
    if quality == 'palatal' then
        result_phoneme = base_phoneme_palatal
    else
        result_phoneme = base_phoneme_nonpalatal
    end
    debug_print_detailed("ConsonantResolution", "    resolve_lenited_consonant for marker: ", full_match_marker, " determined quality: ", quality, ". base_pal: '", base_phoneme_palatal, "', base_nonpal: '", base_phoneme_nonpalatal, "'. Returning: '", result_phoneme, "'")
    return result_phoneme
end

-- ====== RULE STAGES ====== --
irishPhonetics.rules_stage1_preprocess = {
    { pattern = "^%s*(.-)%s*$", replacement = function(captured_string) if captured_string then return captured_string:lower() else return "" end end },
    { pattern = "%s+", replacement = " " }, { pattern = "�", replacement = "" }, 
    { pattern = "^([^ˈ%-].*)$", replacement = function(word_part_to_stress)
        if not word_part_to_stress or word_part_to_stress == "" then return "" end
        for _, prefix in ipairs(UNSTRESSED_PREFIXES_ORTHO) do
            if word_part_to_stress:sub(1, #prefix) == prefix then
                local root = word_part_to_stress:sub(#prefix + 1)
                if root == "" then return word_part_to_stress end
                if root:match("^" .. ALL_VOWELS_ORTHO_PATTERN) then return prefix .. "ˈ" .. root
                elseif root:match("^(" .. CONSONANTS_ORTHO_CHARS_STR .. "+)(" .. ALL_VOWELS_ORTHO_PATTERN .. ")") then return prefix .. "ˈ" .. root
                else return word_part_to_stress end
            end
        end
        if word_part_to_stress:match("^" .. ALL_VOWELS_ORTHO_PATTERN) then return "ˈ" .. word_part_to_stress
        elseif word_part_to_stress:match("^(" .. CONSONANTS_ORTHO_CHARS_STR .. "+)(" .. ALL_VOWELS_ORTHO_PATTERN .. ")") then return "ˈ" .. word_part_to_stress
        end
        return word_part_to_stress
    end},
}

irishPhonetics.rules_stage2_mark_digraphs_and_vocalisation_triggers = {
    { pattern = "bhf", replacement = "_URUF_", ortho_len = 3 }, { pattern = "bp", replacement = "_URUP_", ortho_len = 2 },
    { pattern = "dt", replacement = "_URUT_", ortho_len = 2 }, { pattern = "gc", replacement = "_URUC_", ortho_len = 2 },
    { pattern = "mb", replacement = "_URUM_", ortho_len = 2 }, { pattern = "nd", replacement = "_URUN_", ortho_len = 2 },
    { pattern = "ng", replacement = "_URUG_", ortho_len = 2 },
    { pattern = "^fh", replacement = "_FH_INITIAL_LENITED_", ortho_len = 2 },
    -- Keep general bh/mh marking, vocalization will be handled in Stage 4.0 based on phonetic context
    { pattern = "bh", replacement = "_BH_", ortho_len = 2 }, { pattern = "mh", replacement = "_MH_", ortho_len = 2 }, 
    { pattern = "ch", replacement = "_CH_", ortho_len = 2 },
    { pattern = "dh", replacement = "_DH_", ortho_len = 2 }, { pattern = "gh", replacement = "_GH_", ortho_len = 2 },
    { pattern = "ph", replacement = "_PH_", ortho_len = 2 },
    { pattern = "sh", replacement = "_SH_", ortho_len = 2 }, { pattern = "th", replacement = "_TH_", ortho_len = 2 },
    { pattern = "aí", replacement = "_A_I_ACUTE_LONG_", ortho_len = 2 },
    { pattern = "ll", replacement = "_LL_", ortho_len = 2 },   { pattern = "nn", replacement = "_NN_", ortho_len = 2 },
    { pattern = "rr", replacement = "_RR_", ortho_len = 2 },   { pattern = "mm", replacement = "_MM_", ortho_len = 2 },
    { pattern = "(ˈ"..SHORT_VOWELS_ORTHO_SINGLE_STR..")l("..ALL_VOWELS_ORTHO_PATTERN..")", replacement = "%1l°%2", ortho_len_func = function(m,c1,c2) return #c1 + 1 + #c2 end},
    { pattern = "(ˈ"..SHORT_VOWELS_ORTHO_SINGLE_STR..")n("..ALL_VOWELS_ORTHO_PATTERN..")", replacement = "%1n°%2", ortho_len_func = function(m,c1,c2) return #c1 + 1 + #c2 end},
}

irishPhonetics.rules_stage3_consonant_resolution = {
    { pattern = "_FH_INITIAL_LENITED_", replacement = "h" }, { pattern = "_FH_SILENT_", replacement = "" }, { pattern = "_TH_", replacement = "h" },
    { pattern = "_URUF_", replacement = "v" }, { pattern = "_URUP_", replacement = "b" }, { pattern = "_URUT_", replacement = "d" }, 
    { pattern = "_URUC_", replacement = "g" }, { pattern = "_URUM_", replacement = "m" }, { pattern = "_URUN_", replacement = "n" }, { pattern = "_URUG_", replacement = "ŋ" },
    { pattern = "_PH_", replacement = function(full_match_marker, o_context_str, original_match_info_tbl) return resolve_lenited_consonant("f'", "f", full_match_marker, o_context_str, original_match_info_tbl) end },
    { pattern = "_SH_", replacement = function(full_match_marker, o_context_str, original_match_info_tbl)
        if not original_match_info_tbl or not original_match_info_tbl.ortho_s or not original_match_info_tbl.ortho_e then return "h" end
        local next_v_start_ortho = original_match_info_tbl.ortho_e + 1; local next_v_is_slender_flag = false
        if next_v_start_ortho <= #o_context_str then if o_context_str:sub(next_v_start_ortho, next_v_start_ortho):match(SLENDER_VOWELS_ORTHO_PATTERN) then next_v_is_slender_flag = true end end
        if o_context_str:match("^[sS][eé][áa]n", original_match_info_tbl.ortho_s -1 ) then return "h'" end 
        return next_v_is_slender_flag and "h'" or "h"
    end },
    { pattern = "_FH_INTERNAL_", replacement = "" }, 
    { pattern = "_BH_", replacement = function(full_match_marker, o_context_str, original_match_info_tbl) return resolve_lenited_consonant("v'", "v", full_match_marker, o_context_str, original_match_info_tbl, {can_be_w = true}) end },
    { pattern = "_DH_", replacement = function(full_match_marker, o_context_str, original_match_info_tbl) return resolve_lenited_consonant("j", "ɣ", full_match_marker, o_context_str, original_match_info_tbl) end },
    { pattern = "_GH_", replacement = function(full_match_marker, o_context_str, original_match_info_tbl) return resolve_lenited_consonant("j", "ɣ", full_match_marker, o_context_str, original_match_info_tbl) end },
    { pattern = "_MH_", replacement = function(full_match_marker, o_context_str, original_match_info_tbl) return resolve_lenited_consonant("v'", "v", full_match_marker, o_context_str, original_match_info_tbl, {can_be_w = true}) end },
    { pattern = "_LL_", replacement = function(full_match_marker, o_context_str, original_match_info_tbl) return resolve_lenited_consonant("L'", "L", full_match_marker, o_context_str, original_match_info_tbl) end },
    { pattern = "_NN_", replacement = function(full_match_marker, o_context_str, original_match_info_tbl) return resolve_lenited_consonant("N'", "N", full_match_marker, o_context_str, original_match_info_tbl) end },
    { pattern = "_RR_", replacement = function(full_match_marker, o_context_str, original_match_info_tbl) return resolve_lenited_consonant("R'", "R", full_match_marker, o_context_str, original_match_info_tbl) end },
    { pattern = "_MM_", replacement = function(full_match_marker, o_context_str, original_match_info_tbl) return resolve_lenited_consonant("M'", "M", full_match_marker, o_context_str, original_match_info_tbl) end },
    { pattern = "l°", replacement = "l_neutral_" }, { pattern = "n°", replacement = "n_neutral_" },
    { pattern = "([bcdfghkmprst])", replacement = function(c_capture, o_context_str, original_match_info_tbl)
        if not c_capture then return "" end; if c_capture == "l_neutral_" or c_capture == "n_neutral_" then return c_capture end 
        local base = c_capture; if c_capture == "c" then base = "k" end
        if not original_match_info_tbl or not original_match_info_tbl.ortho_s or not original_match_info_tbl.ortho_e or not o_context_str then return base == "s" and "s" or base end
        local quality = determine_consonant_quality_ortho(o_context_str, original_match_info_tbl.ortho_s, original_match_info_tbl.ortho_e)
        if base == "s" then return quality == "palatal" and "s'" or "s" else return quality == "palatal" and base .. "'" or base end
    end},
}

irishPhonetics.rules_stage4_0_specific_ortho_to_temp_marker = {
    -- Vocalization rules for bh/mh after short vowel and word-final
    { pattern = "(["..ANY_SHORT_VOWEL_PHONETIC_CHARS_STR.."])(_BH_)(#?)$", replacement = "%1&VOC_BH_MH_FINAL&%3" },
    { pattern = "(["..ANY_SHORT_VOWEL_PHONETIC_CHARS_STR.."])(_MH_)(#?)$", replacement = "%1&VOC_BH_MH_FINAL&%3" },
    
    -- Vocalization for medial amh/abh before certain consonants (needs to be specific)
    -- Example for damhsa: (d)a(_MH_)(s)a -> d&AU_FROM_AMH&sa
    { pattern = "^(ˈ?(?:[^"..ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR.."]*))a(_MH_)(s["..ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR.."]?)", replacement = "%1&AU_FROM_AMH&%3" }, 
    -- Example for gabhar: (g)a(_BH_)(r) -> g&AI_FROM_ABH&r
    { pattern = "^(ˈ?(?:[^"..ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR.."]*))a(_BH_)(r["..ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR.."]?)", replacement = "%1&AI_FROM_ABH&%3" }, 
    -- Example for samhradh: (s)a(_MH_)(r...) -> s&AU_FROM_AMH&r... (more general amh/abh -> au/əu before r)
    { pattern = "(["..ANY_SHORT_VOWEL_PHONETIC_CHARS_STR.."])(_MH_)(r)", replacement = "%1&VOC_AMH_MEDIAL_R&%3" }, 
    { pattern = "(["..ANY_SHORT_VOWEL_PHONETIC_CHARS_STR.."])(_BH_)(r)", replacement = "%1&VOC_ABH_MEDIAL_R&%3" }, 

    -- Existing ea rules
    { pattern = "^(ˈ?)("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)".."ea(_CH_t)$", replacement = "%1%2&EA_BROAD_SHORT_PRE_CHT&%3" }, 
    { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)".."ea(_CH_)", replacement = "%1&EA_SLENDER_PRE_CH&%2" }, 
    { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)".."ea(ŋ)", replacement = function(full_match, c_part, ng_cap, o_context_str, original_match_info_tbl) 
        local ortho_n_start_idx = original_match_info_tbl.ortho_e - #ng_cap + 1 
        local quality_of_n = determine_consonant_quality_ortho(o_context_str, ortho_n_start_idx, ortho_n_start_idx) 
        debug_print_detailed("Stage4_0_SpecificOrthoToTempMarker", "ea(ŋ) rule: ortho_word='", o_context_str, "', n_ortho_idx=", ortho_n_start_idx, ", quality_of_n JUST DETERMINED AS: '", quality_of_n, "' for match: ", full_match)
        if quality_of_n == "palatal" then return (c_part or "") .."&EA_SLENDER_PRE_NG&"..ng_cap 
        else return (c_part or "") .. "&EA_BROAD_PRE_NG&"..ng_cap end 
    end, use_original_context_for_rules = true }, 
    { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)".."ea(N)$", replacement = "%1&EA_BROAD_PRE_NN&%2" }, 
    { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)".."ea(N)([^'])", replacement = "%1&EA_BROAD_PRE_NN&%2%3" }, 
    { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)".."ea(r')", replacement = "%1&EA_SLENDER_PRE_RPRIME&%2" }, 
    { pattern = "((?:["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."]'?)*)iu(_CH_)", replacement = "%1&IU_SLENDER_FINAL_PRE_CH&%2" }, 
    { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)".."ea(r)", replacement = "%1&EA_BROAD_PRE_R&%2" },
    { 
        pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)".."ea(n)$", 
        replacement = function(full_match, c_part, n_cap, o_context_str, original_match_info_tbl)
            debug_print_detailed("Stage4_0_SpecificOrthoToTempMarker", "Heuristic 'ean$' rule: Using &EA_SLENDER_PRE_N& for: ", full_match)
            return (c_part or "") .. "&EA_SLENDER_PRE_N&" .. (n_cap or "")
        end, 
        use_original_context_for_rules = true 
    },
    { 
        pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)".."ea(n)([^" .. ALL_VOWELS_ORTHO_CHARS_STR .. "°%-bhfpgcdtmls" .. ANY_CONSONANT_PHONETIC_RAW_CHARS_STR .. "'])",
        replacement = function(full_match, c_part, n_cap, next_char_phon, o_context_str, original_match_info_tbl)
            debug_print_detailed("Stage4_0_SpecificOrthoToTempMarker", "Heuristic 'eanC' rule: Using &EA_SLENDER_PRE_N& for: ", full_match)
            return (c_part or "") .. "&EA_SLENDER_PRE_N&" .. (n_cap or "") .. (next_char_phon or "")
        end, 
        use_original_context_for_rules = true 
    },
}

irishPhonetics.rules_stage4_0_1_resolve_ch_marker = {
    { pattern = "_CH_", replacement = function(full_match_marker, o_context_str, original_match_info_tbl)
        if not original_match_info_tbl or not original_match_info_tbl.ortho_s or not original_match_info_tbl.ortho_e then return "x" end
        local quality_for_ch = determine_consonant_quality_ortho(o_context_str, original_match_info_tbl.ortho_s, original_match_info_tbl.ortho_e)
        return quality_for_ch == "palatal" and "ç" or "x"
    end },
}

irishPhonetics.rules_stage4_1_vocmark_to_temp_marker = {
    -- These are now for -aidh, -aigh etc. and should be kept for those specific cases.
    { pattern = "_VOCMARK_EABH_", replacement = "&VOC_EABH_AMH&" }, { pattern = "_VOCMARK_EAMH_", replacement = "&VOC_EABH_AMH&" },
    { pattern = "_VOCMARK_ABH_", replacement = "&VOC_ABH_AMH&" },  { pattern = "_VOCMARK_AMH_", replacement = "&VOC_ABH_AMH&" },
    { pattern = "_VOCMARK_OBH_", replacement = "&VOC_OBH_OMH&" },  { pattern = "_VOCMARK_OMH_", replacement = "&VOC_OBH_OMH&" },
    { pattern = "_VOCMARK_UBH_", replacement = "&VOC_UBH_UMH&" },  { pattern = "_VOCMARK_UMH_", replacement = "&VOC_UBH_UMH&" },
    { pattern = "_VOCMARK_AIDH_", replacement = "&VOC_AI_OI_GH_DH&" }, { pattern = "_VOCMARK_AIGH_", replacement = "&VOC_AI_OI_GH_DH&" },
    { pattern = "_VOCMARK_OIDH_", replacement = "&VOC_AI_OI_GH_DH&" }, { pattern = "_VOCMARK_OIGH_", replacement = "&VOC_AI_OI_GH_DH&" },
    { pattern = "_VOCMARK_EIDH_", replacement = "&VOC_EI_GH_DH_SCHWA&" }, { pattern = "_VOCMARK_EIGH_", replacement = "&VOC_EI_GH_DH_SCHWA&" },
    { pattern = "_VOCMARK_UIDH_", replacement = "&VOC_UI_GH_DH&" }, { pattern = "_VOCMARK_UIGH_", replacement = "&VOC_UI_GH_DH&" },
}

irishPhonetics.rules_stage4_2_long_vowels_ortho_to_temp_marker = {
    { pattern = "éi", replacement = "&E_ACUTE_I_LONG&" }, { pattern = "iú", replacement = "&I_ACUTE_U_LONG&"},
    { pattern = "á", replacement = "&A_ACUTE_LONG&" }, { pattern = "é", replacement = "&E_ACUTE_LONG&" },
    { pattern = "í", replacement = "&I_ACUTE_LONG&" }, { pattern = "ó", replacement = "&O_ACUTE_LONG&" },
    { pattern = "ú", replacement = "&U_ACUTE_LONG&" },
    { pattern = "ao", replacement = "&AO_OI_LONG&" }, { pattern = "oí", replacement = "&AO_OI_LONG&" },
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
    { pattern = "&VOC_BH_MH_FINAL&", replacement = "əu"}, -- New
    { pattern = "&AU_FROM_AMH&", replacement = "au"},   -- New
    { pattern = "&AI_FROM_ABH&", replacement = "ai"},   -- New
    { pattern = "&VOC_AMH_MEDIAL_R&", replacement = "əu"}, -- New (samhradh -> səur...)
    { pattern = "&VOC_ABH_MEDIAL_R&", replacement = "əu"}, -- New (gabhar -> gəur... if not ai)


    { pattern = "&A_I_ACUTE_LONG_RESOLVE&", replacement = "iː" }, { pattern = "&E_ACUTE_I_LONG&", replacement = "eː" }, { pattern = "&I_ACUTE_U_LONG&", replacement = "uː"}, 
    { pattern = "&VOC_EABH_AMH&", replacement = "əu"}, { pattern = "&VOC_ABH_AMH&", replacement = "əu"}, { pattern = "&VOC_OBH_OMH&", replacement = "ou"}, 
    { pattern = "&VOC_UBH_UMH&", replacement = "uː"}, { pattern = "&VOC_AI_OI_GH_DH&", replacement = "ai"}, { pattern = "&VOC_EI_GH_DH_SCHWA&", replacement = "eiə"},
    { pattern = "&VOC_UI_GH_DH&", replacement = "iː"},
    { pattern = "&A_ACUTE_LONG&", replacement = "ɑː" }, { pattern = "&E_ACUTE_LONG&", replacement = "eː" }, { pattern = "&I_ACUTE_LONG&", replacement = "iː" }, 
    { pattern = "&O_ACUTE_LONG&", replacement = "oː" }, { pattern = "&U_ACUTE_LONG&", replacement = "uː" }, { pattern = "&AO_OI_LONG&", replacement = "ɨː"},
    { pattern = "&AE_SEQ&", replacement = "eː" }, { pattern = "&EO_SEQ&", replacement = "oː" },
    { pattern = "&IA_DIPH&", replacement = "ia" }, { pattern = "&UA_DIPH&", replacement = "ua" }, { pattern = "&AI_DIPH&(nm')", replacement = "a%1"}, 
    { pattern = "&AI_DIPH&", replacement = "ai" }, { pattern = "&EI_DIPH&", replacement = "e" }, { pattern = "&OI_DIPH&", replacement = "ɔ" }, 
    { pattern = "&UI_DIPH&", replacement = "i" }, { pattern = "&AU_DIPH&", replacement = "ɑu" }, { pattern = "&OU_DIPH&", replacement = "ou" },
    { pattern = "&EA_BROAD_SHORT_PRE_CHT&", replacement = "a"}, { pattern = "&EA_SLENDER_PRE_CH&", replacement = "æː"}, { pattern = "&EA_SLENDER_PRE_NG&", replacement = "æ"}, 
    { pattern = "&EA_BROAD_PRE_NG&", replacement = "a"}, { pattern = "&EA_BROAD_PRE_NN&", replacement = "ɑː"}, { pattern = "&EA_SLENDER_PRE_RPRIME&", replacement = "æ"}, 
    { pattern = "&EA_BROAD_PRE_R&", replacement = "a"}, { pattern = "&IU_SLENDER_FINAL_PRE_CH&", replacement = "ʊ"}, { pattern = "&EA_SLENDER_PRE_N&", replacement = "æ"}, 
    { pattern = "&EA_BROAD_PRE_N&", replacement = "a" },   
}

irishPhonetics.rules_stage4_5_contextual_allophony_on_phonetic = {
    { pattern = "o(?!ː)", replacement = "ɔ" }, 
    { pattern = "u(?!ː)([kgxɣ])", replacement = "ʊ%1" },
    { pattern = "u(?!ː)", replacement = "ɔ" }, 
    { pattern = "(v')(a)(?!ː)", replacement = "%1ʲ%2" }, 
    { pattern = "(v')(æ)", replacement = "%1ʲ%2" }, 
    { pattern = "(v')(e)(?!ː)", replacement = "%1ʲ%2" }, 
    
    { pattern = "ou$", replacement = "uː" }, 
    { pattern = "^(ˈ?)("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?')oː(m)", replacement = "%1%2uː%3" }, 
    { pattern = "t(æː)", replacement = "tʲ%1"}, 
    { pattern = "l(iː)", replacement = "lʲ%1"},   
    { pattern = "d(lʲiː)", replacement = "dʲ%1"}, 
    { pattern = "n(iv')", replacement = "nʲ%1"}, 
    { pattern = "ɨː(ç)", replacement = "iː%1"}, 
    { pattern = "(dʲa)(r)(h)(ɑːiɾʲ)", replacement = "%1ɾˠ%4" }, 
    { pattern = "(ɑː)i(r)$", replacement = "%1iɾʲ"}, 
    { pattern = "d(a)(r)", replacement = "dʲ%1%2"}, 
    { pattern = "k(a)(rt)", replacement = "c%1%2"}, 
    { pattern = "^(ˈ?["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."]*'?)(ou)(r'ɑː)$", replacement = "%1oː%3" }, 
    { pattern = "iːo(["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."](?!'))", replacement = "iː%1" }, 
    { pattern = "iːo(["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."]')", replacement = "iː%1" },    
    { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)([oɔʊʌ])(?!ː)(["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."]['ʃçjɟc])", replacement = "%1e%3" },
    { pattern = "([ɾR]')i(?!ː)", replacement = "%1e" }, { pattern = "([ɾR])i(?!ː)", replacement = "%1e" },
    { pattern = "([ɾR]')u(?!ː)", replacement = "%1ɔ" }, { pattern = "([ɾR])u(?!ː)", replacement = "%1ɔ" },
    { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."')a(?!ː)(["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."]['ʃçjɟc])", replacement = "%1e%2" },
    { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."')([oɔʊʌ])(?!ː)(["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."]['ʃçjɟc])", replacement = "%1i%3" },
    { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."')e(?!ː)(["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."]['ʃçjɟc])", replacement = "%1e%2" },
    { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."')i(?!ː)(["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."]['ʃçjɟc])", replacement = "%1i%2" },
    { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."')a(?!ː)(["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."](?!'))", replacement = "%1æ%2" },
    { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."')([uʊ])(?!ː)(["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."](?!['kgxɣ]))", replacement = "%1ɔ%3" },
    { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."')([oɔʌ])(?!ː)(["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."](?!'))", replacement = "%1ɔ%2" },
    { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."')e(?!ː)(["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."](?!'))", replacement = "%1æ%2" },
    { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."')i(?!ː)(["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."](?!'))", replacement = "%1i%2" },
    { pattern = "(["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."ˈ](?!'))a(?!ː)(["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."]['ʃçjɟc])", replacement = "%1e%2" },
    { pattern = "(["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."ˈ](?!'))e(?!ː)(["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."]['ʃçjɟc])", replacement = "%1e%2" },
    { pattern = "(["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."ˈ](?!'))i(?!ː)(["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."]['ʃçjɟc])", replacement = "%1i%2" },
    { pattern = "l_neutral_", replacement = "l"}, {pattern = "n_neutral_", replacement = "n"}, 
    { pattern = "a(?!ː)", replacement = "a" }, { pattern = "e(?!ː)", replacement = "e" }, { pattern = "i(?!ː)", replacement = "i" }, 
    { pattern = "ɔ(?!ː)", replacement = "ɔ" }, { pattern = "ʊ(?!ː)", replacement = "ʊ" }, { pattern = "ʌ(?!ː)", replacement = "ʌ" }, 
}

local function apply_unstressed_vowel_reduction_procedural(phon_word)
    debug_print_detailed("Stage4_6_UnstressedVowelReduction_Procedural", "PROC START: In=", phon_word)
    local string_changed_this_major_pass
    repeat 
        string_changed_this_major_pass = false; local phon_word_at_pass_start = phon_word
        for _, rule in ipairs(irishPhonetics.rules_stage4_6_unstressed_vowel_reduction_specific_finals) do
            local new_word, count = phon_word:gsub(rule.pattern, rule.replacement)
            if count > 0 then debug_print_detailed("Stage4_6_UnstressedVowelReduction_Procedural", "(SpecFinal):", rule.pattern, "->", rule.replacement, "Res:", new_word); phon_word = new_word; string_changed_this_major_pass = true end
        end
        if is_stressed_monosyllable_phonetic(phon_word) then debug_print_detailed("Stage4_6_UnstressedVowelReduction_Procedural", "SKIP (StressMono after SpecFinal):", phon_word); goto end_reduction_loop_main end
        local num_vowel_nuclei = 0; local vowel_nuclei_positions = {}
        
        local temp_for_counting_reduction = phon_word:gsub("ˈ","")
        local current_phon_pos_for_nuc_finding = 1
        while current_phon_pos_for_nuc_finding <= #temp_for_counting_reduction do
            local s_nuc, e_nuc, nuc_match = string.find(temp_for_counting_reduction, PHONETIC_VOWEL_NUCLEUS_PATTERN, current_phon_pos_for_nuc_finding)
            if s_nuc then
                num_vowel_nuclei = num_vowel_nuclei + 1
                table.insert(vowel_nuclei_positions, {s=s_nuc, e=e_nuc, nuc=nuc_match})
                current_phon_pos_for_nuc_finding = e_nuc + 1
            else
                break 
            end
        end
        
        debug_print_detailed("Stage4_6_UnstressedVowelReduction_Procedural", "Found", num_vowel_nuclei, "vowel nuclei for:", phon_word)
        if num_vowel_nuclei > 1 then
            local parts = {}; local stress_char_idx = string.find(phon_word, "ˈ"); local primary_stressed_vowel_s, primary_stressed_vowel_e
            if stress_char_idx then for _, pos_data in ipairs(vowel_nuclei_positions) do if pos_data.s == stress_char_idx + 1 or (pos_data.s == stress_char_idx + 2 and phon_word:sub(stress_char_idx+1,stress_char_idx+1):match(ANY_CONSONANT_PHONETIC_PATTERN)) then primary_stressed_vowel_s = pos_data.s; primary_stressed_vowel_e = pos_data.e; break end end end
            if not primary_stressed_vowel_s and #vowel_nuclei_positions > 0 then primary_stressed_vowel_s = vowel_nuclei_positions[1].s; primary_stressed_vowel_e = vowel_nuclei_positions[1].e end
            local current_build_pos = 1
            for _, pos_data in ipairs(vowel_nuclei_positions) do
                local s_vowel, e_vowel, vowel_nuc = pos_data.s, pos_data.e, pos_data.nuc
                if s_vowel > current_build_pos then table.insert(parts, phon_word:sub(current_build_pos, s_vowel - 1)) end
                local is_this_vowel_stressed = (primary_stressed_vowel_s and s_vowel == primary_stressed_vowel_s and e_vowel == primary_stressed_vowel_e)
                if is_this_vowel_stressed or vowel_nuc:match("ː") or not vowel_nuc:match(SHORT_VOWEL_PHONETIC_PATTERN_FOR_REDUCTION_INPUT) then table.insert(parts, vowel_nuc)
                else
                    local preceding_cons_text = ""; if s_vowel > 1 then local prev_cons_end = s_vowel -1; local prev_cons_start = prev_cons_end; while prev_cons_start > 0 do local char_at_prev_start = phon_word:sub(prev_cons_start, prev_cons_start); if char_at_prev_start:match(ANY_CONSONANT_PHONETIC_PATTERN) or char_at_prev_start == "'" then prev_cons_start = prev_cons_start - 1 else break end end; preceding_cons_text = phon_word:sub(prev_cons_start + 1, prev_cons_end); preceding_cons_text = preceding_cons_text:gsub("ˈ","") end
                    local reduced_vowel; if preceding_cons_text:match("'") or preceding_cons_text:match("['ʃçjɟc]$") then reduced_vowel = "i" else reduced_vowel = "ə" end
                    debug_print_detailed("Stage4_6_UnstressedVowelReduction_Procedural", "(PolyRed): Word:", phon_word, "V:", vowel_nuc, "at", s_vowel, "PrecCons: >"..preceding_cons_text.."<", "RedTo:", reduced_vowel); table.insert(parts, reduced_vowel)
                end; current_build_pos = e_vowel + 1
            end
            if current_build_pos <= #phon_word then table.insert(parts, phon_word:sub(current_build_pos)) end; phon_word = table.concat(parts)
        end
        local temp_phon_word = phon_word
        temp_phon_word = temp_phon_word:gsub("ə("..ANY_CONSONANT_PHONETIC_PATTERN.."['ʃçjɟc])$", "i%1"); temp_phon_word = temp_phon_word:gsub("ə("..ANY_CONSONANT_PHONETIC_PATTERN..ANY_CONSONANT_PHONETIC_PATTERN.."?')$", "i%1") 
        temp_phon_word = temp_phon_word:gsub("("..ANY_CONSONANT_PHONETIC_PATTERN.."['ʃçjɟc])ə$", "%1i"); temp_phon_word = temp_phon_word:gsub("("..ANY_CONSONANT_PHONETIC_PATTERN..ANY_CONSONANT_PHONETIC_PATTERN.."?'?)ə$", function(consonants) if consonants:match("'$") or consonants:match("['ʃçjɟc]$") then return consonants .. "i" end return consonants .. "ə" end)
        if temp_phon_word ~= phon_word then debug_print_detailed("Stage4_6_UnstressedVowelReduction_Procedural", "(SchwaAllo): Old:", phon_word, "New:", temp_phon_word); phon_word = temp_phon_word; string_changed_this_major_pass = true end
        if phon_word == phon_word_at_pass_start then string_changed_this_major_pass = false else string_changed_this_major_pass = true end
    until not string_changed_this_major_pass
    ::end_reduction_loop_main::
    debug_print_detailed("Stage4_6_UnstressedVowelReduction_Procedural", "PROC END: Out=", phon_word)
    return phon_word
end

irishPhonetics.rules_stage4_6_unstressed_vowel_reduction_specific_finals = {
    { pattern = "aí$", replacement = "iː" }, { pattern = "ai$", replacement = "iː" }, { pattern = "eiə$", replacement = "iː"}, { pattern = "iːə$", replacement = "iː"}, 
}

local S1_CORONAL_SONORANT_PHONETIC_CHARS = "rRlLNn"; local C2_NON_CORONAL_VOICED_OBSTRUENT_OR_SONORANT_PHONETIC_CHARS_CORRECTED = "bBvVmMɡGɣ" 
local L_VARIANTS_PHONETIC = "[lL]"; local N_VARIANTS_PHONETIC = "[nNmM]"; local R_VARIANTS_PHONETIC = "[rR]"
local function epenthesis_logic_func(vowel_nuc, s1_cons, s2_cons) local ep_vowel = (s2_cons:match("'") or s2_cons:match("['ʃçjɟc]$")) and "i" or "ə"; return vowel_nuc .. s1_cons .. ep_vowel .. s2_cons end

irishPhonetics.rules_stage5_epenthesis_then_strong_sonorants = {
    { pattern = "^(ˈ?)(a)(r)(m)$", replacement = function(full_match, stress_marker_opt, vowel_a, r_son, m_son) 
        debug_print_detailed("EpenthesisThenStrongSonorants", "arm-like rule FIRING for mono: ", full_match); return (stress_marker_opt or "") .. epenthesis_logic_func(vowel_a, r_son, m_son) end, use_current_phonetic_for_condition = true, condition_func = is_likely_monosyllable_phonetic },
    { pattern = "^(ˈ?)()(" .. SHORT_VOWEL_CAPTURE_FOR_EPENTHESIS .. ")([" .. S1_CORONAL_SONORANT_PHONETIC_CHARS .. "]'?)([" .. C2_NON_CORONAL_VOICED_OBSTRUENT_OR_SONORANT_PHONETIC_CHARS_CORRECTED .. "]'?)$", replacement = function(full_match, stress_marker, initial_consonants_empty, vowel_nuc, s1_cons, s2_cons) 
        debug_print_detailed("EpenthesisThenStrongSonorants", "GenEp V-initial for mono: ", full_match); return stress_marker .. epenthesis_logic_func(vowel_nuc, s1_cons, s2_cons) end, use_current_phonetic_for_condition = true, condition_func = is_likely_monosyllable_phonetic },
    { pattern = "^(ˈ?)((?:"..ANY_CONSONANT_PHONETIC_PATTERN.."*'?))?(" .. SHORT_VOWEL_CAPTURE_FOR_EPENTHESIS .. ")([" .. S1_CORONAL_SONORANT_PHONETIC_CHARS .. "]'?)([" .. C2_NON_CORONAL_VOICED_OBSTRUENT_OR_SONORANT_PHONETIC_CHARS_CORRECTED .. "]'?)$", replacement = function(full_match, stress_marker_opt, initial_consonants, vowel_nuc, s1_cons, s2_cons)
        initial_consonants = initial_consonants or ""; stress_marker_opt = stress_marker_opt or ""; debug_print_detailed("EpenthesisThenStrongSonorants", "GenEp C-initial for mono: ", full_match); return stress_marker_opt .. initial_consonants .. epenthesis_logic_func(vowel_nuc, s1_cons, s2_cons) end, use_current_phonetic_for_condition = true, condition_func = is_likely_monosyllable_phonetic },
    
    -- New/Modified Lengthening/Diphthongization rules for MONOSYLLABLES:
    { pattern = "^(ˈ?)((?:"..ANY_CONSONANT_PHONETIC_PATTERN.."*'?))i([NMnrlLNR]'?)(#?)$", 
      replacement = function(full_match, stress, c_part, sonorant, boundary_marker) 
        debug_print_detailed("EpenthesisThenStrongSonorants", "i+Son -> iː+Son for mono: ", full_match); 
        return (stress or "") .. (c_part or "") .. "iː" .. sonorant .. (boundary_marker or "") 
      end, use_current_phonetic_for_condition = true, condition_func = is_likely_monosyllable_phonetic},
    { pattern = "^(ˈ?)((?:"..ANY_CONSONANT_PHONETIC_PATTERN.."*'?))æ([NMnrlLNR]'?)(#?)$", 
      replacement = function(full_match, stress, c_part, sonorant, boundary_marker) 
        debug_print_detailed("EpenthesisThenStrongSonorants", "æ+Son -> ɑː+Son for mono: ", full_match); 
        return (stress or "") .. (c_part or "") .. "ɑː" .. sonorant .. (boundary_marker or "") 
      end, use_current_phonetic_for_condition = true, condition_func = is_likely_monosyllable_phonetic},
    { pattern = "^(ˈ?)((?:"..ANY_CONSONANT_PHONETIC_PATTERN.."*'?))a([NMnrlLNR]'?)(#?)$", replacement = function(full_match, stress, c_part, sonorant, boundary_marker) 
        debug_print_detailed("EpenthesisThenStrongSonorants", "a+Son -> ɑː+Son for mono: ", full_match); return (stress or "") .. (c_part or "") .. "ɑː" .. sonorant .. (boundary_marker or "") end, use_current_phonetic_for_condition = true, condition_func = is_likely_monosyllable_phonetic},
    { pattern = "^(ˈ?)((?:"..ANY_CONSONANT_PHONETIC_PATTERN.."*'?))(ɔ)("..L_VARIANTS_PHONETIC.."'?)(#?)$", replacement = function(full_match, stress, c_part, vowel, sonorant, boundary_marker) 
        debug_print_detailed("EpenthesisThenStrongSonorants", "ɔ+L -> əu+L for mono: ", full_match); return (stress or "") .. (c_part or "") .. "əu" .. sonorant .. (boundary_marker or "") end, use_current_phonetic_for_condition = true, condition_func = is_likely_monosyllable_phonetic},
    { pattern = "^(ˈ?)((?:"..ANY_CONSONANT_PHONETIC_PATTERN.."*'?))(ɔ)("..N_VARIANTS_PHONETIC.."'?)(#?)$", replacement = function(full_match, stress, c_part, vowel, sonorant, boundary_marker) 
        debug_print_detailed("EpenthesisThenStrongSonorants", "ɔ+N/M -> uː+N/M for mono: ", full_match); return (stress or "") .. (c_part or "") .. "uː" .. sonorant .. (boundary_marker or "") end, use_current_phonetic_for_condition = true, condition_func = is_likely_monosyllable_phonetic},
    { pattern = "^(ˈ?)((?:"..ANY_CONSONANT_PHONETIC_PATTERN.."*'?))(ɔ)("..R_VARIANTS_PHONETIC.."'?)(#?)$", replacement = function(full_match, stress, c_part, vowel, sonorant, boundary_marker) 
        debug_print_detailed("EpenthesisThenStrongSonorants", "ɔ+R -> oː+R for mono: ", full_match); return (stress or "") .. (c_part or "") .. "oː" .. sonorant .. (boundary_marker or "") end, use_current_phonetic_for_condition = true, condition_func = is_likely_monosyllable_phonetic},
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

    local function build_initial_ortho_map(word_str) local new_map = {}; for k=1, #word_str do table.insert(new_map, {phon_s=k, phon_e=k, ortho_s=k, ortho_e=k}) end; return new_map end
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
        {name = "ConsonantResolution", rules = irishPhonetics.rules_stage3_consonant_resolution, use_original_context_for_rules = true},
        {name = "Stage4_0_SpecificOrthoToTempMarker", rules = irishPhonetics.rules_stage4_0_specific_ortho_to_temp_marker, use_original_context_for_rules = true}, 
        {name = "Stage4_0_1_Resolve_CH_Marker", rules = irishPhonetics.rules_stage4_0_1_resolve_ch_marker, use_original_context_for_rules = true},
        {name = "Stage4_1_VocmarkToTempMarker", rules = irishPhonetics.rules_stage4_1_vocmark_to_temp_marker, use_original_context_for_rules = false},
        {name = "Stage4_2_LongVowelsOrthoToTempMarker", rules = irishPhonetics.rules_stage4_2_long_vowels_ortho_to_temp_marker, use_original_context_for_rules = false},
        {name = "Stage4_3_DiphthongsOrthoToTempMarker", rules = irishPhonetics.rules_stage4_3_diphthongs_ortho_to_temp_marker, use_original_context_for_rules = false},
        {name = "Stage4_4_ResolveTempVowelMarkers", rules = irishPhonetics.rules_stage4_4_resolve_temp_vowel_markers, use_original_context_for_rules = false, has_internal_loop = true},
        {name = "Stage4_5_ContextualAllophonyOnPhonetic", rules = irishPhonetics.rules_stage4_5_contextual_allophony_on_phonetic, use_original_context_for_rules = false, has_internal_loop = true}, 
        {name = "Stage4_6_UnstressedVowelReduction_Procedural", is_procedural_stage = true, func = apply_unstressed_vowel_reduction_procedural},
        {name = "EpenthesisThenStrongSonorants", rules = irishPhonetics.rules_stage5_epenthesis_then_strong_sonorants, use_original_context_for_rules = false},
        {name = "Diacritics", rules = irishPhonetics.rules_stage6_diacritics, use_original_context_for_rules = false},
        {name = "FinalCleanup", rules = irishPhonetics.rules_stage7_final_cleanup, use_original_context_for_rules = false},
    }

    print(string.format("\n--- Transcribing: [%s] ---", orthographic_word:lower()))

    for i, stage_data in ipairs(stages) do
        local rules_to_apply = stage_data.rules
        if stage_data.is_procedural_stage and type(stage_data.func) == "function" then
            print("  " .. stage_data.name .. " START (Proc): In=", current_word_phonetic)
            current_word_phonetic = stage_data.func(current_word_phonetic)
        elseif not rules_to_apply and not stage_data.is_procedural_stage then goto continue_stage end

        if stage_data.name == "PreProcess" then
            for rule_idx, rule in ipairs(rules_to_apply) do
                if type(rule.replacement) == "string" then current_word_phonetic = current_word_phonetic:gsub(rule.pattern, rule.replacement)
                elseif type(rule.replacement) == "function" then current_word_phonetic = current_word_phonetic:gsub(rule.pattern, function(...) return rule.replacement(...) or "" end) end
            end
            original_ortho_for_context = current_word_phonetic; ortho_map = build_initial_ortho_map(current_word_phonetic) 
        elseif stage_data.updates_map_from_original_with_priority then 
            local temp_phonetic_string_build = {}; local temp_new_map = {}; local original_cursor = 1; local current_phonetic_len_accumulator = 0
            while original_cursor <= #original_ortho_for_context do
                local matched_this_pass_at_cursor = false
                for rule_idx, rule in ipairs(rules_to_apply) do
                    local s_match_ortho, e_match_ortho, capture1, capture2, capture3, capture4
                    if rule.pattern:match("%(") then s_match_ortho, e_match_ortho, capture1, capture2, capture3, capture4 = string.find(original_ortho_for_context, rule.pattern, original_cursor) else s_match_ortho, e_match_ortho = string.find(original_ortho_for_context, rule.pattern, original_cursor) end
                    if s_match_ortho and s_match_ortho == original_cursor then
                        local current_ortho_match_len; local full_match_ortho_segment_for_len_func = original_ortho_for_context:sub(s_match_ortho, e_match_ortho)
                        if rule.ortho_len_func then current_ortho_match_len = rule.ortho_len_func(full_match_ortho_segment_for_len_func, capture1, capture2, capture3, capture4) elseif rule.ortho_len then current_ortho_match_len = rule.ortho_len else current_ortho_match_len = e_match_ortho - s_match_ortho + 1 end
                        if rule.ortho_len and current_ortho_match_len > (e_match_ortho - s_match_ortho + 1) then goto continue_rule_loop_stage2 end
                        local full_match_ortho_segment_for_replacement = original_ortho_for_context:sub(s_match_ortho, s_match_ortho + current_ortho_match_len -1); local replacement_text
                        if type(rule.replacement) == "string" then replacement_text = rule.replacement elseif type(rule.replacement) == "function" then replacement_text = rule.replacement(full_match_ortho_segment_for_replacement, capture1, capture2, capture3, capture4) end
                        replacement_text = replacement_text or ""; table.insert(temp_phonetic_string_build, replacement_text)
                        table.insert(temp_new_map, {phon_s = current_phonetic_len_accumulator + 1, phon_e = current_phonetic_len_accumulator + #replacement_text, ortho_s = original_cursor, ortho_e = original_cursor + current_ortho_match_len - 1})
                        current_phonetic_len_accumulator = current_phonetic_len_accumulator + #replacement_text; original_cursor = original_cursor + current_ortho_match_len; matched_this_pass_at_cursor = true; goto restart_rule_scan_for_new_cursor_stage2 
                    end; ::continue_rule_loop_stage2::
                end; ::restart_rule_scan_for_new_cursor_stage2::
                if not matched_this_pass_at_cursor then if original_cursor <= #original_ortho_for_context then local char = original_ortho_for_context:sub(original_cursor, original_cursor); table.insert(temp_phonetic_string_build, char); table.insert(temp_new_map, {phon_s = current_phonetic_len_accumulator + 1, phon_e = current_phonetic_len_accumulator + 1, ortho_s = original_cursor, ortho_e = original_cursor}); current_phonetic_len_accumulator = current_phonetic_len_accumulator + 1; original_cursor = original_cursor + 1 else break end end
            end
            current_word_phonetic = table.concat(temp_phonetic_string_build); ortho_map = temp_new_map
        elseif not stage_data.is_procedural_stage then 
            print("  " .. stage_data.name .. " START: In=", current_word_phonetic)
            if stage_data.has_internal_loop then 
                local pass_counter_this_stage = 0
                local iteration_changed_string_this_stage
                repeat
                    iteration_changed_string_this_stage = false
                    pass_counter_this_stage = pass_counter_this_stage + 1
                    for rule_idx_loop, rule_data_loop in ipairs(rules_to_apply) do
                        if type(rule_data_loop.pattern) == "string" then
                            local new_phon_string, num_replacements = current_word_phonetic:gsub(rule_data_loop.pattern, rule_data_loop.replacement)
                            if num_replacements > 0 then
                                debug_print_detailed(stage_data.name, "Iter.gsub: Rule '", rule_data_loop.pattern, "' APPLIED to '", current_word_phonetic, "' -> '", new_phon_string, "' (", num_replacements, "x)")
                                current_word_phonetic = new_phon_string
                                iteration_changed_string_this_stage = true
                            end
                        end
                    end
                    if iteration_changed_string_this_stage then
                        debug_print_detailed(stage_data.name, "Iter.gsub Pass "..pass_counter_this_stage..": out='", current_word_phonetic, "'")
                    end
                until not iteration_changed_string_this_stage
            else 
                local iteration_changed_string_this_stage_non_iter = false 
                local new_phonetic_string_parts = {}; local scan_offset = 1  
                while scan_offset <= #current_word_phonetic do
                    local best_match_s_this_iter, best_match_e_this_iter, best_rule_this_iter_idx; local best_captures_this_iter = {}; local current_best_match_length_this_iter = -1 
                    for rule_idx_loop, rule_data_loop in ipairs(rules_to_apply) do
                        if type(rule_data_loop.pattern) == "string" then
                            local s, e, cap1, cap2, cap3, cap4, cap5, cap6, cap7, cap8, cap9, cap10; s, e, cap1, cap2, cap3, cap4, cap5, cap6, cap7, cap8, cap9, cap10 = string.find(current_word_phonetic, rule_data_loop.pattern, scan_offset)
                            if s then local current_match_len_loop = e - s + 1
                                if not best_match_s_this_iter or s < best_match_s_this_iter or (s == best_match_s_this_iter and current_match_len_loop > current_best_match_length_this_iter) then 
                                    best_match_s_this_iter = s; best_match_e_this_iter = e; best_rule_this_iter_idx = rule_idx_loop; current_best_match_length_this_iter = current_match_len_loop; best_captures_this_iter = {cap1,cap2,cap3,cap4,cap5,cap6,cap7,cap8,cap9,cap10}
                                end
                            end
                        end
                    end

                    if best_rule_this_iter_idx then 
                        if best_match_s_this_iter > scan_offset then table.insert(new_phonetic_string_parts, current_word_phonetic:sub(scan_offset, best_match_s_this_iter - 1)) end
                        local rule = rules_to_apply[best_rule_this_iter_idx]; local full_match_segment = current_word_phonetic:sub(best_match_s_this_iter, best_match_e_this_iter)
                        local original_ortho_s_for_rule, original_ortho_len_for_rule = get_original_indices_from_map(best_match_s_this_iter, best_match_e_this_iter, ortho_map)
                        local original_match_info_for_func = {ortho_s = original_ortho_s_for_rule, ortho_e = original_ortho_s_for_rule + original_ortho_len_for_rule - 1}
                        local actual_captures_for_func_current_rule = {}; if best_captures_this_iter then for k_cap, v_cap in ipairs(best_captures_this_iter) do if v_cap ~= nil then table.insert(actual_captures_for_func_current_rule, v_cap) end end end
                        
                        local apply_this_rule = true 
                        if rule.use_current_phonetic_for_condition and rule.condition_func then
                            local current_word_phonetic_before_pass_for_cond = current_word_phonetic 
                            local condition_is_met = rule.condition_func(current_word_phonetic_before_pass_for_cond) 
                            if not condition_is_met then
                                apply_this_rule = false
                                debug_print_detailed(stage_data.name, "Rule '", rule.pattern, "' CONDITION FAILED for '", full_match_segment, "' (orig str for cond: '", current_word_phonetic_before_pass_for_cond, "'). Skipping replacement.")
                            else
                                debug_print_detailed(stage_data.name, "Rule '", rule.pattern, "' CONDITION MET for '", full_match_segment, "' (orig str for cond: '", current_word_phonetic_before_pass_for_cond, "'). Proceeding.")
                            end
                        end

                        local replacement_text
                        if apply_this_rule then
                            if type(rule.replacement) == "string" then 
                                replacement_text = rule.replacement
                                if replacement_text:match("%%[%d]") then 
                                    local temp_repl = replacement_text
                                    for i_cap = #actual_captures_for_func_current_rule, 1, -1 do 
                                        temp_repl = temp_repl:gsub("%%"..i_cap, actual_captures_for_func_current_rule[i_cap] or "") 
                                    end
                                    replacement_text = temp_repl 
                                end
                            elseif type(rule.replacement) == "function" then
                                local call_params_for_rule_func = {full_match_segment} 
                                for _, cap_val in ipairs(actual_captures_for_func_current_rule) do table.insert(call_params_for_rule_func, cap_val) end
                                if stage_data.use_original_context_for_rules then 
                                    table.insert(call_params_for_rule_func, original_ortho_for_context)
                                    table.insert(call_params_for_rule_func, original_match_info_for_func)
                                end
                                replacement_text = rule.replacement(table.unpack(call_params_for_rule_func))
                            end
                            replacement_text = replacement_text or ""
                            if full_match_segment ~= replacement_text then 
                                debug_print_detailed(stage_data.name, "Rule '", rule.pattern, "' APPLIED to '", full_match_segment, "' -> '", replacement_text, "'")
                                iteration_changed_string_this_stage_non_iter = true 
                            end
                        else
                            replacement_text = full_match_segment 
                        end
                        table.insert(new_phonetic_string_parts, replacement_text)
                        scan_offset = best_match_e_this_iter + 1
                    else 
                        if scan_offset <= #current_word_phonetic then table.insert(new_phonetic_string_parts, current_word_phonetic:sub(scan_offset)) end
                        break 
                    end
                end
                current_word_phonetic = table.concat(new_phonetic_string_parts)
            end
            print("  " .. stage_data.name .. " END: Out=", current_word_phonetic)
        end
        if stage_data.name ~= "PreProcess" then print(string.format("Af. %s: [%s]", stage_data.name, current_word_phonetic)) end
        ::continue_stage::
    end
    return current_word_phonetic
end

-- Example Usage:
local RUN_FULL_TEST_SET = false 

local words_to_test_focused_37O = {
    "bord", "poll", "fonn", 
    "drochbhean", "seanbhean", "bhean",
    "arm", 
    "ceann", "binn", "teann", "trom", "am", "cam", "gall", "tall"
}

local words_to_test_full_37O = {
    "fhéach", "fhág", "fhíor", "fhostaigh", "fhuair", "scríobh", "teach", "deartháir", "cat", "bord", "ceann", "poll", "balla", "leabhar", "samhradh", "beannacht", "fonn",
    "leagan", "teanga", "seacht", "aghaidh", "suidhe", "nimhe", "bóthar", "oíche", "fear", "glaic", "muc", "fliuch", "fada", "beag", "séimhiú", "úrú", "bacach", 
    "isteach", "baile", "duine", "Gaeltacht", "Conamara", "Gaeilge", "aoibhinn", "buí", "caol", "leathan", "drochbhean", "an-mhaith", "fuinneog", "oiliúint", 
    "staighre", "fios", "athbhliain", "comhrá", "mícheart", "oícheanta", "codladh", "luigh", "fiche", "duchaise", "saibhir", "deacair", "sláinte", "ceart", "lae", 
    "laoch", "aer", "ceo", "ceol", "coir", "coill", "faoi", "gaoth", "bádaí", "capaillí", "foclaí", "brógaí", "dearmad", "seomraí", "doras", "amhrán", "Banríon", 
    "dearcadh", "dearfa", "mí-ádh", "droch-obair", "seanbhean", "bhean", "fíoruisce", "athchúrsáil", "an-fear", "an-oíche", "beart", "bean", "geal", "eagla", "muid", "duit", 
    "fuil", "goil", "buil", "cuir", "druid", "luibh", "ceist", "ocht", "páiste", "sparán", "scéal", "bláth", "cnoc", "gnó", "dlí", "mná", "trá", "uisce", "obair", 
    "imir", "eolas", "athair", "máthair", "deirfiúr", "imirt", "oibre", "ceacht", "ceistneoir", "ceistigh", "arm", "borb", "bolg", "garbh", "gorm", "gairm", "balbh", 
    "seilbh", "dearg", "fearg", "colm", "ainm", "scrúdaigh", "cónaigh", "beannaigh",
    "teann", "trom", "am", "cam", "gall", "tall" 
}

local words_to_test_final
if RUN_FULL_TEST_SET then
    words_to_test_final = words_to_test_full_37O
else
    words_to_test_final = words_to_test_focused_37O
end

print("\n--- Running Test Set for Iteration 37O (" .. (#words_to_test_final == #words_to_test_full_37O and "Full" or "Focused") .. ") ---") 
for _, word in ipairs(words_to_test_final) do 
    local original = word
    local transcribed = irishPhonetics.transcribe(original)
    print(string.format("%-15s -> [%s]", original, transcribed))
end

if debug_file then debug_file:close() end
return irishPhonetics