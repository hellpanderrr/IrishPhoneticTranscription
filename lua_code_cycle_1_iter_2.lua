-- irish_phonetics_37AU.lua

local ustring_module_path = "ustring.ustring" -- Adjust if your path is different
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
local debug_file_path = "irish_debug_37AU_nasalization_rerun.txt" -- Changed for this iteration to indicate re-run
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
    Nasalization = true, -- New Stage Flag
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

-- Orthographic Patterns (same as before)
local SLENDER_VOWELS_ORTHO_CHARS_STR = "eéií"
local BROAD_VOWELS_ORTHO_CHARS_STR = "aáoóuú"
local ALL_VOWELS_ORTHO_CHARS_STR = SLENDER_VOWELS_ORTHO_CHARS_STR .. BROAD_VOWELS_ORTHO_CHARS_STR
local SLENDER_VOWELS_ORTHO_PATTERN = "[" .. SLENDER_VOWELS_ORTHO_CHARS_STR .. "]"
local BROAD_VOWELS_ORTHO_PATTERN = "[" .. BROAD_VOWELS_ORTHO_CHARS_STR .. "]"
local ALL_VOWELS_ORTHO_PATTERN = "[" .. ALL_VOWELS_ORTHO_CHARS_STR .. "]"
local SHORT_VOWELS_ORTHO_SINGLE_STR = "aeiou"
local CONSONANTS_ORTHO_CHARS_STR = "bcdfghlmnprst"

-- Phonetic Patterns (same as before)
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
    -- (Same as provided in the prompt)
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
    -- (Same as provided in the prompt)
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
    -- (Same as provided in the prompt)
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

-- ====== RULE STAGES (Mostly same as before, Nasalization stage added) ====== --
irishPhonetics.rules_stage1_preprocess = { -- (Same as provided)
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
irishPhonetics.rules_stage2_mark_digraphs_and_vocalisation_triggers = { -- (Same as provided)
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
irishPhonetics.rules_stage3_consonant_resolution = { -- (Same as provided)
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
irishPhonetics.rules_stage4_0_specific_ortho_to_temp_marker = { -- (Same as provided)
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
irishPhonetics.rules_stage4_0_1_resolve_ch_marker = { -- (Same as provided)
    { pattern = "_CH_", replacement = function(full_match_marker, o_context_str, original_match_info_tbl)
        if not original_match_info_tbl or not original_match_info_tbl.ortho_s or not original_match_info_tbl.ortho_e then return "x" end
        local quality_for_ch = determine_consonant_quality_ortho(o_context_str, original_match_info_tbl.ortho_s, original_match_info_tbl.ortho_e)
        return quality_for_ch == "palatal" and "ç" or "x"
    end },
}
irishPhonetics.rules_stage4_1_vocmark_to_temp_marker = {} -- (Same as provided)
irishPhonetics.rules_stage4_2_long_vowels_ortho_to_temp_marker = { -- (Same as provided)
    { pattern = "éi", replacement = "&E_ACUTE_I_LONG&" }, { pattern = "iú", replacement = "&I_ACUTE_U_LONG&"},
    { pattern = "á", replacement = "&A_ACUTE_LONG&" }, { pattern = "é", replacement = "&E_ACUTE_LONG&" },
    { pattern = "í", replacement = "&I_ACUTE_LONG&" }, { pattern = "ó", replacement = "&O_ACUTE_LONG&" },
    { pattern = "ú", replacement = "&U_ACUTE_LONG&" },
    { pattern = "_A_I_ACUTE_LONG_", replacement = "&A_I_ACUTE_LONG_RESOLVE&" },
}
irishPhonetics.rules_stage4_3_diphthongs_ortho_to_temp_marker = { -- (Same as provided)
    { pattern = "ae", replacement = "&AE_SEQ&" },
    { pattern = "ia", replacement = "&IA_DIPH&" }, { pattern = "ua", replacement = "&UA_DIPH&" },
    { pattern = "ai", replacement = "&AI_DIPH&" }, { pattern = "ei", replacement = "&EI_DIPH&" },
    { pattern = "oi", replacement = "&OI_DIPH&" }, { pattern = "ui", replacement = "&UI_DIPH&" },
    { pattern = "au", replacement = "&AU_DIPH&" }, { pattern = "ou", replacement = "&OU_DIPH&" },
    { pattern = "eo", replacement = "&EO_SEQ&" },
}
irishPhonetics.rules_stage4_4_resolve_temp_vowel_markers = { -- (Same as provided)
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
    { pattern = "&AI_DIPH&(nm')", replacement = "a%1"}, -- Potential refinement needed for 'a' vs 'æ' here
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
local placeholder_creation_rules_stage4_5 = { -- (Same as provided)
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
local core_allophony_rules_for_stage4_5 = { -- (Same as provided)
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
local placeholder_restoration_rules_stage4_5 = { -- (Same as provided)
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
local connacht_au_to_schwa_u_shift_rule_stage4_5 = { -- (Same as provided)
  pattern = "^(ˈ?["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."]*'?)(ɑu)(["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."]*'?)$",
  replacement = function(full_match, pre_part, au_diph, post_part)
      if is_likely_monosyllable_phonetic_revised(full_match) then
          return (pre_part or "") .. "əu" .. (post_part or "")
      end
      return full_match
  end
}
local temp_conn_au_to_final_au_rule_stage4_5 = { -- (Same as provided)
    pattern = "&TEMP_CONN_AU&", replacement = "əu"
}
irishPhonetics.rules_stage4_5_contextual_allophony_on_phonetic = {} -- (Same as provided, will be populated in transcribe function)
local function apply_unstressed_vowel_reduction_procedural(phon_word) -- (Same as provided)
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
irishPhonetics.rules_stage4_6_unstressed_vowel_reduction_specific_finals = { -- (Same as provided)
    { pattern = "aí$", replacement = "iː" }, { pattern = "ai$", replacement = "iː" }, { pattern = "eiə$", replacement = "iː"}, { pattern = "iːə$", replacement = "iː"},
}
irishPhonetics.EPENTHESIS_TARGET_CLUSTERS_BROAD = { -- (Same as provided)
    ["lk"]=true, ["lg"]=true, ["lb"]=true, ["lv"]=true, ["rm"]=true, ["rx"]=true,
    ["rb"]=true, ["rg"]=true,
    ["ln"]=true, ["lr"]=true, ["lm"]=true, -- Added from analysis
}
irishPhonetics.EPENTHESIS_TARGET_CLUSTERS_SLENDER = { -- (Same as provided)
    ["lk"]=true, ["lf"]=true, ["rg"]=true, ["rk"]=true, ["nm"]=true,
    ["ln"]=true, ["lr"]=true, ["lm"]=true, -- Added from analysis
}
local PHONETIC_UNITS_PRIORITY_FOR_EPENTHESIS_PARSER = { -- (Same as provided)
    "iə", "ua", "ai", "ei", "oi", "ui", "ɑu", "ou", "əu", "eiə", "aw", "əi",
    "ɑː", "eː", "iː", "oː", "uː", "ɨː", "æː",
    "c", "ɟ", "tʲ", "dʲ", "ʃ", "ç", "j", "ɾˠ", "lˠ", "nˠ", "mˠ", "t̪", "d̪", "n̪", "l̪",
    "k'", "g'", "t'", "d'", "p'", "b'", "m'", "n'", "l'", "r'", "s'", "f'", "v'", "L'", "N'", "R'", "M'",
    "k", "g", "t", "d", "p", "b", "m", "n", "l", "r", "s", "f", "v", "L", "N", "R", "M", "x", "ɣ", "ŋ", "h", "w",
    "a", "æ", "ɔ", "e", "ə", "i", "ɪ", "u", "ʊ", "ʌ"
}
local function parse_phonetic_string_to_units_for_epenthesis(phon_str) -- (Same as provided, with critical fix)
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
            elseif umatch(matched_unit_phon, "^[" .. ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR .. "]ː?$") then -- Corrected pattern for vowels
                quality = "vowel"
            elseif umatch(matched_unit_phon, "^[" .. ANY_CONSONANT_PHONETIC_RAW_CHARS_STR .. "]$") and not umatch(matched_unit_phon, "['ʲˠ̪]") then
                local is_inherently_palatal_char = umatch(matched_unit_phon, "^[jç]$") or umatch(matched_unit_phon, "^[ʃ]$")
                if is_inherently_palatal_char then quality = "palatal" else quality = "nonpalatal" end
            elseif matched_unit_phon == "iə" or matched_unit_phon == "ei" or matched_unit_phon == "ui" or matched_unit_phon == "oi" or matched_unit_phon == "əi" then quality = "palatal"
            elseif matched_unit_phon == "ua" or matched_unit_phon == "ɑu" or matched_unit_phon == "ou" or matched_unit_phon == "əu" or matched_unit_phon == "aw" then quality = "nonpalatal"
            end

            if quality == "unknown" and (umatch(matched_unit_phon, "^[" .. ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR .. "]ː?$")) then -- Fallback for vowels
                quality = "vowel"
            end


            table.insert(units, { phon = matched_unit_phon, stress = stress, quality = quality, original_start = i - ulen(stress), original_end = i + matched_unit_len - 1 - ulen(stress) })
            i = i + matched_unit_len
        elseif stress ~= "" then
            table.insert(units, { phon = stress, stress = "", quality = "stress_mark", original_start = i - 1, original_end = i - 1})
        else
            local unknown_char = usub(phon_str,i,i)
            local unknown_quality = "unknown_fallback"
            if umatch(unknown_char, "^[" .. ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR .. "]") then -- Catch single vowels missed by priority list
                unknown_quality = "vowel"
            end
            table.insert(units, { phon = unknown_char, stress = stress, quality = unknown_quality, original_start = i - ulen(stress), original_end = i - ulen(stress) })
            i = i + 1
        end
    end
    return units
end
function irishPhonetics.apply_procedural_epenthesis(phon_word_input, original_ortho_word_for_context, current_ortho_map_for_context) -- (Same as provided, with C2 condition refined)
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
            -- Refined C2 condition:
            local is_c2_valid_for_epenthesis = umatch(c2_base_phon, "^[kgptdfbxs]$") or (is_c1_sonorant_type and umatch(c2_base_phon, "^[rlnm]$"))


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
            if is_vowel_short and is_c1_sonorant_type and is_c2_valid_for_epenthesis then -- Use refined C2 condition
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
irishPhonetics.rules_stage5_strong_sonorants_only = { -- (Same as provided)
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
local NON_PALATAL_CONSONANT_CHARS_FOR_DIACRITICS = "tdnlsLNRM" -- (Same as provided)
local NON_PALATAL_CONSONANT_PATTERN_FOR_DIACRITICS = "[" .. NON_PALATAL_CONSONANT_CHARS_FOR_DIACRITICS .. "]"
irishPhonetics.rules_stage6_diacritics = { -- (Same as provided)
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
irishPhonetics.rules_stage7_final_cleanup = { -- (Same as provided)
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

-- ====== NEW NASALIZATION STAGE FUNCTION ====== --
function irishPhonetics.apply_vowel_nasalization(phon_word, original_ortho_word_for_context)
    if STAGE_DEBUG_ENABLED["Nasalization"] then print("  Nasalization START: In=", phon_word) end
    if not phon_word or phon_word == "" then return "" end

    local parsed_units = parse_phonetic_string_to_units_for_epenthesis(phon_word)
    if not parsed_units or #parsed_units == 0 then
        if STAGE_DEBUG_ENABLED["Nasalization"] then print("  Nasalization END (no units): Out=", phon_word) end
        return phon_word
    end

    -- Phonetic representations of nasal consonants (after Stage 4.5, before Stage 7 cleanup)
    local NASAL_CONSONANTS_PHONETIC = {
        ["m"]=true, ["n"]=true, ["ŋ"]=true, ["N"]=true, ["M"]=true,
        ["m'"]=true, ["n'"]=true, ["N'"]=true, ["M'"]=true, -- Prime notation from earlier stages
        ["mʲ"]=true, ["nʲ"]=true, ["Nʲ"]=true, ["Mʲ"]=true, -- Fully resolved palatal nasals
        ["n̪"]=true, ["mˠ"]=true, ["nˠ"]=true, ["Mˠ"]=true, ["Nˠ"]=true, -- Diacritic-marked nasals
    }

    local words_exempt_from_nasalization_in_connacht_csv_for_now = {
        ["am"]=true, ["cam"]=true, ["ainm"]=true, ["rámh"]=true, ["lámh"]=true,
        ["mná"]=true, ["snámh"]=true, -- Mn and Sn are often not nasalized
    }
    -- Use original_ortho_word_for_context for exemption check
    local ortho_for_exempt_check = ulower(original_ortho_word_for_context)
    if words_exempt_from_nasalization_in_connacht_csv_for_now[ortho_for_exempt_check] then
         debug_print_detailed("Nasalization", "Word '", original_ortho_word_for_context, "' is explicitly exempt from nasalization per CSV/Hickey Connacht data.")
         return phon_word
    end


    local new_phon_units = {}
    for i, unit_data in ipairs(parsed_units) do
        local current_phon = unit_data.phon
        local current_stress = unit_data.stress or ""
        local current_quality = unit_data.quality
        local original_phon_for_debug = current_phon

        if current_quality == "vowel" and not umatch(current_phon, "̃") then -- Only nasalize if not already nasalized
            local nasalize_this_vowel = false
            local reason_for_nasalization = ""

            -- Check regressive nasalization (Vowel *before* Nasal)
            if i < #parsed_units then
                local next_unit = parsed_units[i+1]
                if NASAL_CONSONANTS_PHONETIC[next_unit.phon] then
                    nasalize_this_vowel = true
                    reason_for_nasalization = "Regressive: Vowel '" .. current_phon .. "' before nasal '" .. next_unit.phon .. "'"
                end
            end

            -- Check progressive nasalization (Vowel *after* Nasal)
            -- Only if not already marked for regressive, to avoid double processing logic here
            if not nasalize_this_vowel and i > 1 then
                local prev_unit = parsed_units[i-1]
                if NASAL_CONSONANTS_PHONETIC[prev_unit.phon] then
                    nasalize_this_vowel = true
                    reason_for_nasalization = "Progressive: Vowel '" .. current_phon .. "' after nasal '" .. prev_unit.phon .. "'"
                end
            end

            if nasalize_this_vowel then
                debug_print_detailed("Nasalization", reason_for_nasalization)
                if umatch(current_phon, "ː$") then -- Ends with length mark
                    -- Place tilde before the length mark
                    current_phon = ugsub(current_phon, "(.)(ː)$", "%1̃%2") -- IPA combining tilde above (U+0303)
                else
                    current_phon = current_phon .. "̃" -- IPA combining tilde above (U+0303)
                end
                debug_print_detailed("Nasalization", "Nasalized '", original_phon_for_debug, "' to '", current_phon, "'")
            end
        end
        table.insert(new_phon_units, { phon = current_phon, stress = current_stress, quality = current_quality})
    end

    local result_phon_parts = {}
    for _, unit_data in ipairs(new_phon_units) do
        table.insert(result_phon_parts, (unit_data.stress or "") .. unit_data.phon)
    end
    local final_phon_word = table.concat(result_phon_parts)

    if STAGE_DEBUG_ENABLED["Nasalization"] then print("  Nasalization END: Out=", final_phon_word) end
    return final_phon_word
end


-- ====== MAIN TRANSCRIBE FUNCTION (Updated Pipeline) ====== --
function irishPhonetics.transcribe(orthographic_word)
    local current_word_phonetic = orthographic_word
    if not current_word_phonetic or current_word_phonetic == "" then return "" end
    local original_ortho_for_context = orthographic_word -- Store original for context
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
            -- (Procedural Consonant Resolution including Metathesis - same as provided)
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
                
                -- Check for existing multi-char phonetic units first (like 'r'', 'n'')
                local parsed_sub_units = parse_phonetic_string_to_units_for_epenthesis(usub(phon_word_in_stage3, pass1_scan_offset_stage3))
                if parsed_sub_units and #parsed_sub_units > 0 and parsed_sub_units[1].quality ~= "unknown_fallback" then
                    local unit_phon = parsed_sub_units[1].phon
                    local unit_len = ulen(unit_phon)
                    
                    -- Check if this parsed unit itself is a key for a multi-char rule that needs to apply at this point
                    local rule_found_for_parsed_unit = false
                    for rule_idx_loop, rule_data_loop in ipairs(multi_char_rules_stage3) do
                        if rule_data_loop.pattern == unit_phon then
                            best_match_s_this_iter = pass1_scan_offset_stage3
                            best_match_e_this_iter = pass1_scan_offset_stage3 + unit_len - 1
                            best_rule_this_iter_idx = rule_idx_loop
                            current_best_match_length_this_iter = unit_len
                            best_captures_this_iter = {} -- No captures for direct match pattern
                            rule_found_for_parsed_unit = true
                            break
                        end
                    end
                    
                    if not rule_found_for_parsed_unit then
                        -- If no rule explicitly matches the multi-char unit, keep it as is for now
                        table.insert(pass1_phonetic_parts_stage3, unit_phon)
                        pass1_scan_offset_stage3 = pass1_scan_offset_stage3 + unit_len
                        goto continue_pass1_scan_offset_stage3
                    end
                end

                -- If not handled by multi-char phonetic unit directly, or if it's a new match
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
                ::continue_pass1_scan_offset_stage3::
            end
            phon_word_in_stage3 = table.concat(pass1_phonetic_parts_stage3)
            debug_print_detailed("ConsonantResolution", "After Pass 1 (markers): ", phon_word_in_stage3)

            if single_char_rule_data_stage3 then
                local pass2_phonetic_parts_stage3 = {}; local pass2_scan_offset_stage3 = 1
                while pass2_scan_offset_stage3 <= ulen(phon_word_in_stage3) do
                    local char_to_check = usub(phon_word_in_stage3, pass2_scan_offset_stage3, pass2_scan_offset_stage3)
                    local processed_this_char = false
                    -- Only apply single character rule if it's actually a single orthographic consonant
                    local original_ortho_s, original_ortho_len = get_original_indices_from_map(pass2_scan_offset_stage3, pass2_scan_offset_stage3, current_ortho_map_stage3)
                    if original_ortho_len == 1 then -- Ensure it maps to a single original orthographic character
                        if char_to_check:match("^[bcdfghkmprst]$") then
                            local original_match_info = {ortho_s = original_ortho_s, ortho_e = original_ortho_s + original_ortho_len -1}
                            debug_print_detailed("ConsonantResolution", "Pass 2: Checking '", char_to_check, "' at phon_idx ", pass2_scan_offset_stage3, " -> ortho_s:", original_ortho_s, "ortho_e:", original_match_info.ortho_e)
                            local replacement_text = single_char_rule_data_stage3.replacement(char_to_check, o_context_str_stage3, original_match_info)
                            replacement_text = replacement_text or char_to_check
                            table.insert(pass2_phonetic_parts_stage3, replacement_text)
                            debug_print_detailed("ConsonantResolution", "Pass 2: Replaced '", char_to_check, "' with '", replacement_text, "'")
                            processed_this_char = true
                        end
                    end
                    if not processed_this_char then
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
            -- (Procedural Contextual Allophony - same as provided)
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
        {name = "EpenthesisAndStrongSonorants", is_procedural_stage = true, func = function(phon_word_in_stage5, o_context_str_stage5, current_ortho_map_stage5)
            -- (Procedural Epenthesis and Strong Sonorants - same as provided, now uses refined C2 condition internally)
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
        {name = "Nasalization", is_procedural_stage = true, func = function(phon_word_in_stage_nasal, o_context_str_nasal) -- Pass original context for exemptions
            return irishPhonetics.apply_vowel_nasalization(phon_word_in_stage_nasal, o_context_str_nasal)
        end},
        {name = "Stage4_6_UnstressedVowelReduction_Procedural", is_procedural_stage = true, func = apply_unstressed_vowel_reduction_procedural},
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
            elseif stage_data.name == "Nasalization" then -- Special handling for Nasalization to pass original_ortho_word
                 current_word_phonetic = stage_data.func(current_word_phonetic, original_ortho_for_context)
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

local words_to_test_nasalization = {
    "ainm", "mná", "rámh", "snámh", "fonn", "ceann", "am", "cam", "trom", "lámh",
    "cnámh", "cnead", "cnoc", "gnaoi", "gnó",
    "seilf", "dorcha", "olc", "oilc", "dearc", "feirc",
    "balbh", "garbh", "gorm", "bolg"
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
    local temp_full_set = {}
    local seen_in_full = {}
    for _,w in ipairs(words_to_test_full_37AB or {}) do if not seen_in_full[w] then table.insert(temp_full_set, w); seen_in_full[w]=true end end
    for _,w in ipairs(words_to_test_nasalization) do if not seen_in_full[w] then table.insert(temp_full_set, w); seen_in_full[w]=true end end
    words_to_test_final = temp_full_set
else
    words_to_test_final = words_to_test_nasalization
end


print("\n--- Running Test Set for Iteration 37AU (Nasalization Focus - RERUN) ---")
for _, word in ipairs(words_to_test_final) do
    local original = word
    local transcribed = irishPhonetics.transcribe(original)
    print(string.format("%-15s -> [%s]", original, transcribed))
end

if debug_file then debug_file:close() end
return irishPhonetics