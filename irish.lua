
-- irish_phonetics_37P_lua_pattern_strict.lua

-- Determine the directory of the current script
local function getScriptDirectory()
    local info = debug.getinfo(1, "S")
    local scriptPath = info.source:sub(2)
    local dir = scriptPath:match("(.*/)")
    if not dir then
        -- Handle Windows paths
        dir = scriptPath:match("(.*\\)")
    end
    return dir
end

-- Get the script's directory
local scriptDir = getScriptDirectory()

-- Update package.path to include the script's directory
package.path = package.path .. ";" .. scriptDir .. "?.lua"

ustring_lib = require('ustring.ustring')

local ulower, usub, ulen, ufind, umatch, ugsub, ugmatch, toNFC = 
    ustring_lib.lower, ustring_lib.sub, ustring_lib.len, ustring_lib.find, 
    ustring_lib.match, ustring_lib.gsub, ustring_lib.gmatch, ustring_lib.toNFC

-- Debug output file setup
local debug_file_path = "irish_debug_37P_lua_pattern_strict.txt"
local debug_file = io.open(debug_file_path, "w")
if debug_file then debug_file:write("\239\187\191") else original_print("WARN: Could not open debug_file " .. debug_file_path) end
local original_print_func = print

-- Debug Flags
local MINIMAL_DEBUG_ENABLED = true 
if MINIMAL_DEBUG_ENABLED then
    STAGE_DEBUG_ENABLED = {
        PreProcess = false, MarkDigraphsAndVocalisationTriggers = false, Stage2_5_MarkSuffixes = false, ConsonantResolution = false,
        Stage4_0_SpecificOrthoToTempMarker = false, Stage4_0_1_Resolve_CH_Marker = false, Stage4_1_VocmarkToTempMarker = false,
        Stage4_2_LongVowelsOrthoToTempMarker = false, Stage4_3_DiphthongsOrthoToTempMarker = false,
        Stage4_4_ResolveTempVowelMarkers = false, Stage4_4_1_VocalizeLenitedFricatives = false,
        Stage4_5_ContextualAllophonyOnPhonetic = false, Stage4_5_1_DisyllabicShortLongRaising = false,
        Nasalization = false, Stage4_6_UnstressedVowelReduction_Procedural = false,
        EpenthesisAndStrongSonorants = false, Diacritics = false, FinalCleanup = false,
        Parser = false, ParserSetup = false, LexicalLookup = false,
    }
else 
    STAGE_DEBUG_ENABLED = {
        PreProcess = true, MarkDigraphsAndVocalisationTriggers = true, Stage2_5_MarkSuffixes = true, ConsonantResolution = true,
        Stage4_0_SpecificOrthoToTempMarker = true, Stage4_0_1_Resolve_CH_Marker = true, Stage4_1_VocmarkToTempMarker = true,
        Stage4_2_LongVowelsOrthoToTempMarker = true, Stage4_3_DiphthongsOrthoToTempMarker = true,
        Stage4_4_ResolveTempVowelMarkers = true, Stage4_4_1_VocalizeLenitedFricatives = true,
        Stage4_5_ContextualAllophonyOnPhonetic = true, Stage4_5_1_DisyllabicShortLongRaising = true,
        Nasalization = true, Stage4_6_UnstressedVowelReduction_Procedural = true,
        EpenthesisAndStrongSonorants = true, Diacritics = true, FinalCleanup = true,
        Parser = false, ParserSetup = false, LexicalLookup = true,
    }
end
print = function(...)
    local msg = table.concat({...}, "\t")
    original_print_func(msg)
    if debug_file then
        if msg:match("^%-%-%- Transcribing:") or msg:match("^%-*%s*-> %[%s*%S") or (MINIMAL_DEBUG_ENABLED and msg:match("^    MIN_DBG")) then
            debug_file:write(msg .. "\n"); debug_file:flush()
        elseif not MINIMAL_DEBUG_ENABLED then
             debug_file:write(msg .. "\n"); debug_file:flush()
        end
    end
end

local function debug_print_minimal(stage_name, ...)
    if MINIMAL_DEBUG_ENABLED and STAGE_DEBUG_ENABLED[stage_name] then 
        print("    MIN_DBG (" .. stage_name:sub(1,10) .. "): " .. table.concat({...}, "\t"))
    end
end

local irishPhonetics = {}

local SLENDER_VOWELS_ORTHO_CHARS_STR = "eéií"
local BROAD_VOWELS_ORTHO_CHARS_STR = "aáoóuú"
local ALL_VOWELS_ORTHO_CHARS_STR = SLENDER_VOWELS_ORTHO_CHARS_STR .. BROAD_VOWELS_ORTHO_CHARS_STR
local SLENDER_VOWELS_ORTHO_PATTERN = "[" .. SLENDER_VOWELS_ORTHO_CHARS_STR .. "]"
local BROAD_VOWELS_ORTHO_PATTERN = "[" .. BROAD_VOWELS_ORTHO_CHARS_STR .. "]"
local ALL_VOWELS_ORTHO_PATTERN = "[" .. ALL_VOWELS_ORTHO_CHARS_STR .. "]"
local SHORT_VOWELS_ORTHO_SINGLE_STR = "aeiou"
local CONSONANTS_ORTHO_CHARS_STR = "bcdfghlmnprst"
local ANY_CONSONANT_PHONETIC_RAW_CHARS_STR = "kgptdfbmnszrlLNRMçjɣŋhwcʃɟɾx" 
local CONSONANT_CLASS_NO_CAPTURE = "[" .. ANY_CONSONANT_PHONETIC_RAW_CHARS_STR .. "]"
local ANY_CONSONANT_PHONETIC_PATTERN = "[" .. ANY_CONSONANT_PHONETIC_RAW_CHARS_STR .. "]"
local FINAL_CONSONANT_CAPTURE_STRICT = "(" .. CONSONANT_CLASS_NO_CAPTURE .. "'?)"
local BROAD_CONSONANT_PHONETIC_CLASS_NO_CAPTURE = "[kgptdfbmnszrlLNRMɣŋhwx]"
local ANY_SHORT_VOWEL_PHONETIC_CHARS_STR = "aæɑɔeɛəiɪuʊʌ"
local ANY_LONG_VOWEL_PHONETIC_CHARS_STR = "ɑeioɨuæ"
local ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR = ANY_SHORT_VOWEL_PHONETIC_CHARS_STR .. ANY_LONG_VOWEL_PHONETIC_CHARS_STR

local SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR = "([" .. ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR .. "]~?ː?)"

local DIPHTHONG_LITERALS_FOR_PRIORITY = {"eiə~","eiə","iə~","ua~","ai~","ei~","oi~","ui~","ɑu~","ou~","əu~","aw~","əi~","iə","ua","ai","ei","oi","ui","ɑu","ou","əu","aw","əi"}
local PHONETIC_VOWEL_NUCLEUS_PATTERN_PARTS = {}
for _, diph_lit in ipairs(DIPHTHONG_LITERALS_FOR_PRIORITY) do
    table.insert(PHONETIC_VOWEL_NUCLEUS_PATTERN_PARTS, "(" .. ugsub(diph_lit, "([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1") .. ")")
end
table.insert(PHONETIC_VOWEL_NUCLEUS_PATTERN_PARTS, SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR)

local SHORT_VOWEL_CAPTURE_FOR_EPENTHESIS = "([" .. ANY_SHORT_VOWEL_PHONETIC_CHARS_STR .. "]~?)"
local CPART_CAPTURE_STRICT = toNFC("(" .. CONSONANT_CLASS_NO_CAPTURE .. "'?)") 
local VOWEL_A_CLASS_CAPTURE_STRICT = toNFC("([aæɑ]~?)")
local VOWEL_E_I_CLASS_CAPTURE_STRICT = toNFC("([eɛiɪ]~?)")
local VOWEL_O_U_CLASS_CAPTURE_STRICT = toNFC("([oɔʊʌ]~?)")
local DIPHTHONG_AI_CAPTURE_STRICT = toNFC("(ai~?)")

local ZZZ_N_STR_BRD_PHON = toNFC("ZZZNSTRBRDZZZ")
local ZZZ_L_STR_BRD_PHON = toNFC("ZZZLSTRBRDZZZ")
local ZZZ_N_SNG_BRD_PHON = toNFC("ZZZNSNGBRDZZZ")
local ZZZ_L_SNG_BRD_PHON = toNFC("ZZZLSNGBRDZZZ")
local ZZZ_N_STR_PAL_PHON = toNFC("ZZZNSTRPALZZZ")
local ZZZ_L_STR_PAL_PHON = toNFC("ZZZLSTRPALZZZ")

local BROAD_LNM_MARKERS_FOR_STAGE5 = {ZZZ_N_STR_BRD_PHON, ZZZ_L_STR_BRD_PHON, ZZZ_N_SNG_BRD_PHON, ZZZ_L_SNG_BRD_PHON, toNFC("m"), toNFC("M")}
local PALATAL_LNM_MARKERS_FOR_STAGE5 = {ZZZ_N_STR_PAL_PHON, ZZZ_L_STR_PAL_PHON, toNFC("n'"), toNFC("N'"), toNFC("l'"), toNFC("L'"), toNFC("m'"), toNFC("M'")}
local BROAD_R_MARKERS_FOR_STAGE5 = {toNFC("R"), toNFC("r")}
local PALATAL_R_MARKERS_FOR_STAGE5 = {toNFC("R'"), toNFC("r'")}

ALL_PHONETIC_CONSONANTS_INTERMEDIATE_PRIORITY = {
    toNFC(ZZZ_N_STR_PAL_PHON), toNFC(ZZZ_N_STR_BRD_PHON), toNFC(ZZZ_L_STR_PAL_PHON), toNFC(ZZZ_L_STR_BRD_PHON), 
    toNFC(ZZZ_N_SNG_BRD_PHON), toNFC(ZZZ_L_SNG_BRD_PHON), 
    toNFC("k'"), toNFC("g'"), toNFC("t'"), toNFC("d'"), toNFC("s'"), toNFC("l'"), toNFC("n'"), toNFC("r'"), 
    toNFC("f'"), toNFC("v'"), toNFC("b'"), toNFC("p'"), toNFC("m'"), toNFC("L'"), toNFC("N'"), toNFC("R'"), toNFC("M'"),
    toNFC("h'"), toNFC("lˠ"), toNFC("nˠ"), toNFC("ɾˠ"), toNFC("mˠ"), toNFC("t̪"), toNFC("d̪"), toNFC("n̪"), toNFC("l̪"), 
    toNFC("n̠ʲ"), toNFC("l̠ʲ"), toNFC("n̪ˠ"), toNFC("l̪ˠ"),
    toNFC("c"), toNFC("ɟ"), toNFC("ʃ"), toNFC("ç"), toNFC("j"), toNFC("k"), toNFC("g"), toNFC("t"), toNFC("d"), toNFC("p"), toNFC("b"),
    toNFC("m"), toNFC("n"), toNFC("l"), toNFC("r"), toNFC("s"), toNFC("f"), toNFC("v"), toNFC("L"), toNFC("N"), toNFC("R"), toNFC("M"),
    toNFC("x"), toNFC("ɣ"), toNFC("ŋ"), toNFC("h"), toNFC("w")
}
ALL_PHONETIC_NUCLEI_PRIORITY = { toNFC("eiə~"), toNFC("eiə"), toNFC("ɑ~ː"), toNFC("e~ː"), toNFC("i~ː"), toNFC("o~ː"), toNFC("u~ː"), toNFC("ɨ~ː"), toNFC("æ~ː"), toNFC("ɑː"), toNFC("eː"), toNFC("iː"), toNFC("oː"), toNFC("uː"), toNFC("ɨː"), toNFC("æː"), toNFC("iə~"), toNFC("ua~"), toNFC("ai~"), toNFC("ei~"), toNFC("oi~"), toNFC("ui~"), toNFC("ɑu~"), toNFC("ou~"), toNFC("əu~"), toNFC("aw~"), toNFC("əi~"), toNFC("iə"), toNFC("ua"), toNFC("ai"), toNFC("ei"), toNFC("oi"), toNFC("ui"), toNFC("ɑu"), toNFC("ou"), toNFC("əu"), toNFC("aw"), toNFC("əi"), toNFC("a~"), toNFC("æ~"), toNFC("ɑ~"), toNFC("ɔ~"), toNFC("e~"), toNFC("ɛ~"), toNFC("ə~"), toNFC("i~"), toNFC("ɪ~"), toNFC("u~"), toNFC("ʊ~"), toNFC("ʌ~"), toNFC("a"), toNFC("æ"), toNFC("ɑ"), toNFC("ɔ"), toNFC("e"), toNFC("ɛ"), toNFC("ə"), toNFC("i"), toNFC("ɪ"), toNFC("u"), toNFC("ʊ"), toNFC("ʌ") }
local COMBINED_PHONETIC_UNITS_PRIORITY = {}
do 
    local t = {}
    for _, p_str in ipairs(ALL_PHONETIC_NUCLEI_PRIORITY) do table.insert(t, {phon=p_str, type="vowel"}) end
    for _, p_str in ipairs(ALL_PHONETIC_CONSONANTS_INTERMEDIATE_PRIORITY) do table.insert(t, {phon=p_str, type="consonant"}) end
    table.sort(t, function(a,b) return ulen(a.phon) > ulen(b.phon) end)
    COMBINED_PHONETIC_UNITS_PRIORITY = t
end

local lexical_exceptions_connacht = {
    [toNFC("abhainn")] = toNFC("əun̠ʲ"),
    [toNFC("Aodh")] = toNFC("iː"),
    [toNFC("Connacht")] = toNFC("ˈkʊn̪ˠəxt̪ˠ"),
    [toNFC("cnuimh")] = toNFC("knˠevʲ"),
    [toNFC("fheadh")] = toNFC("a"), -- as in "ar fheadh"
    [toNFC("d'fhág")] = toNFC("d̪ˠɑːɡ"),
}

local function get_original_indices_from_map(phon_s, phon_e, current_map)
    local o_s_final, o_e_final = phon_s, phon_e; local orig_len_final = phon_e - phon_s + 1
    if not current_map or #current_map == 0 then return o_s_final, orig_len_final end
    local first_char_map_entry, last_char_map_entry
    for i = 1, #current_map do local entry = current_map[i]; if entry.phon_s <= phon_s and entry.phon_e >= phon_s then first_char_map_entry = entry; break end end
    for i = #current_map, 1, -1 do local entry = current_map[i]; if entry.phon_s <= phon_e and entry.phon_e >= phon_e then last_char_map_entry = entry; break end end
    if first_char_map_entry then o_s_final = first_char_map_entry.ortho_s + (phon_s - first_char_map_entry.phon_s) end
    if last_char_map_entry then o_e_final = last_char_map_entry.ortho_e - (last_char_map_entry.phon_e - phon_e) elseif first_char_map_entry then o_e_final = o_s_final + (phon_e - phon_s) end
    if o_s_final and o_e_final then orig_len_final = o_e_final - o_s_final + 1; if orig_len_final <= 0 then o_s_final = first_char_map_entry and first_char_map_entry.ortho_s or phon_s; orig_len_final = (phon_e - phon_s + 1); o_e_final = o_s_final + orig_len_final -1 end
    else o_s_final, o_e_final = phon_s, phon_e; orig_len_final = phon_e - phon_s + 1 end
    return o_s_final, orig_len_final
end

local function apply_rules_to_string_generic(current_string_input,
                                             rules_to_apply_list,
                                             stage_name_str, mode_str,
                                             use_orig_context_flag,
                                             o_context_str_for_func,
                                             current_ortho_map_for_func)
    local current_string_local = current_string_input

    if mode_str == "iterative_gsub" then
        local iteration_changed_this_pass;
        repeat
            iteration_changed_this_pass = false
            local string_before_this_gsub_pass = current_string_local
            for _, rule_data in ipairs(rules_to_apply_list) do
                if type(rule_data.pattern) == "string" then
                    local new_str, num_repl =
                        ugsub(current_string_local, rule_data.pattern,
                              rule_data.replacement)
                    if new_str ~= current_string_local then
                        debug_print_minimal(stage_name_str, "Iter.gsub: Rule '",
                                            rule_data.pattern, "' APPLIED to '",
                                            current_string_local, "' -> '",
                                            new_str, "' (", num_repl, "x)");
                        current_string_local = new_str;
                        iteration_changed_this_pass = true
                    end
                end
            end
        until not iteration_changed_this_pass
    elseif mode_str == "single_pass_priority_match" then
        local new_string_parts = {};
        local scan_offset = 1
        while scan_offset <= ulen(current_string_local) do
            local best_match_s, best_match_e, best_rule_idx;
            local best_captures = {};
            local current_best_match_len = -1
            for rule_idx, rule_data in ipairs(rules_to_apply_list) do
                if type(rule_data.pattern) == "string" then
                    local s, e, cap1, cap2, cap3, cap4, cap5, cap6, cap7, cap8,
                          cap9, cap10 = ufind(current_string_local,
                                              rule_data.pattern, scan_offset)
                    if s then
                        local current_match_len = e - s + 1;
                        if not best_match_s or s < best_match_s or
                            (s == best_match_s and current_match_len >
                                current_best_match_len) then
                            best_match_s = s;
                            best_match_e = e;
                            best_rule_idx = rule_idx;
                            current_best_match_len = current_match_len;
                            best_captures = {
                                cap1, cap2, cap3, cap4, cap5, cap6, cap7, cap8,
                                cap9, cap10
                            }
                        end
                    end
                end
            end
            if best_rule_idx then
                if best_match_s > scan_offset then
                    table.insert(new_string_parts, usub(current_string_local,
                                                        scan_offset,
                                                        best_match_s - 1))
                end
                local rule = rules_to_apply_list[best_rule_idx];
                local full_match_seg = usub(current_string_local, best_match_s,
                                            best_match_e)
                local actual_caps_for_func = {};
                if best_captures then
                    for _, c_val in ipairs(best_captures) do
                        if c_val ~= nil then
                            table.insert(actual_caps_for_func, c_val)
                        end
                    end
                end
                local apply_this_rule_now = true
                if rule.use_current_phonetic_for_condition and
                    rule.condition_func then
                    local parsed_units_for_cond_generic =
                        parse_phonetic_string_to_units_for_epenthesis(
                            full_match_seg);
                    if not rule.condition_func(full_match_seg,
                                               parsed_units_for_cond_generic) then
                        apply_this_rule_now = false
                    end
                end
                local replacement_val
                if apply_this_rule_now then
                    if type(rule.replacement) == "string" then
                        replacement_val = rule.replacement;
                        if replacement_val:match("%%[%d]") then
                            local temp_r = replacement_val;
                            for i_c = #actual_caps_for_func, 1, -1 do
                                temp_r =
                                    ugsub(temp_r, "%%" .. i_c,
                                          actual_caps_for_func[i_c] or "")
                            end
                            replacement_val = temp_r
                        end
                    elseif type(rule.replacement) == "function" then
                        local call_params = {full_match_seg};
                        for _, cap_v in ipairs(actual_caps_for_func) do
                            table.insert(call_params, cap_v)
                        end
                        if use_orig_context_flag then
                            local o_s, o_l =
                                get_original_indices_from_map(best_match_s,
                                                              best_match_e,
                                                              current_ortho_map_for_func);
                            local o_match_info = {
                                ortho_s = o_s,
                                ortho_e = o_s + o_l - 1
                            };
                            table.insert(call_params, o_context_str_for_func);
                            table.insert(call_params, o_match_info)
                        end
                        replacement_val =
                            rule.replacement(table.unpack(call_params))
                    end
                    replacement_val = replacement_val or ""
                else
                    replacement_val = full_match_seg
                end
                table.insert(new_string_parts, replacement_val);
                scan_offset = best_match_e + 1
            else
                if scan_offset <= ulen(current_string_local) then
                    table.insert(new_string_parts,
                                 usub(current_string_local, scan_offset))
                end
                break
            end
        end
        current_string_local = table.concat(new_string_parts)
    end
    return current_string_local
end

local function get_ortho_vowel_quality_implication_from_char_or_group(v_char_or_group, is_for_preceding_consonant_context)
    if not v_char_or_group or ulen(v_char_or_group) == 0 then return nil end
    
    if is_for_preceding_consonant_context then
        if v_char_or_group == "ui" then return "broad" end 
        if v_char_or_group == "ea" then return "slender" end 
        if v_char_or_group == "eo" or v_char_or_group == "ia" or v_char_or_group == "iu" or v_char_or_group == "ei" or v_char_or_group == "eu" then
            local first_char_of_group = usub(v_char_or_group, 1, 1)
            if umatch(first_char_of_group, SLENDER_VOWELS_ORTHO_PATTERN) then return "slender"
            elseif umatch(first_char_of_group, BROAD_VOWELS_ORTHO_PATTERN) then return "broad"
            end
        end
    end

    local last_char_of_group = usub(v_char_or_group, ulen(v_char_or_group), ulen(v_char_or_group))
    if v_char_or_group == "aoi" then return "slender" end 
    if v_char_or_group == "ao" or v_char_or_group == "ua" then return "broad" end

    if ulen(v_char_or_group) > 1 then
        if umatch(last_char_of_group, SLENDER_VOWELS_ORTHO_PATTERN) then return "slender" end
    end

    if umatch(last_char_of_group, SLENDER_VOWELS_ORTHO_PATTERN) then return "slender"
    elseif umatch(last_char_of_group, BROAD_VOWELS_ORTHO_PATTERN) then return "broad"
    end
    return nil 
end

local function determine_consonant_quality_ortho(original_ortho_word, ortho_cons_char_start_idx, ortho_cons_char_end_idx)
    if not original_ortho_word or not ortho_cons_char_start_idx or not ortho_cons_char_end_idx or ortho_cons_char_start_idx <= 0 or ortho_cons_char_end_idx > ulen(original_ortho_word) or ortho_cons_char_start_idx > ortho_cons_char_end_idx then return "nonpalatal" end
    local current_ortho_cons_seq = usub(original_ortho_word, ortho_cons_char_start_idx, ortho_cons_char_end_idx)
    
    local stress_marker_offset = 0
    if usub(original_ortho_word, 1, 1) == "ˈ" then stress_marker_offset = 1 end

    if current_ortho_cons_seq == "b" and (ortho_cons_char_start_idx - stress_marker_offset) == 1 then
        if usub(original_ortho_word, ortho_cons_char_end_idx + 1, ortho_cons_char_end_idx + 2) == "ai" and
           usub(original_ortho_word, ortho_cons_char_end_idx + 3, ortho_cons_char_end_idx + 4) == "nn" then
            debug_print_minimal("ConsonantResolution", "Special case: 'bainne' initial b -> nonpalatal")
            return "nonpalatal"
        end
    end
    if current_ortho_cons_seq == "r" and (ortho_cons_char_start_idx - stress_marker_offset) == 1 then
         if usub(original_ortho_word, ortho_cons_char_end_idx + 1, ortho_cons_char_end_idx + 2) == "oi" and
            usub(original_ortho_word, ortho_cons_char_end_idx + 3, ortho_cons_char_end_idx + 4) == "nn" then
             debug_print_minimal("ConsonantResolution", "Special case: 'roinnt' initial r -> nonpalatal")
             return "nonpalatal"
         end
    end
    if current_ortho_cons_seq == "l°" or current_ortho_cons_seq == "n°" then return "nonpalatal" end
    
    local next_v_quality_implication, prev_v_quality_implication
    
    local temp_idx = ortho_cons_char_end_idx + 1
    local next_v_group_str_build = {}
    local next_v_first_char_idx = -1
    while temp_idx <= ulen(original_ortho_word) do
        local char = usub(original_ortho_word, temp_idx, temp_idx)
        if umatch(char, ALL_VOWELS_ORTHO_PATTERN) then 
            if next_v_first_char_idx == -1 then next_v_first_char_idx = temp_idx end
            table.insert(next_v_group_str_build, char)
        elseif char == 'h' and temp_idx + 1 <= ulen(original_ortho_word) and umatch(usub(original_ortho_word, temp_idx+1, temp_idx+1), ALL_VOWELS_ORTHO_PATTERN) then 
        elseif umatch(char, "[" .. CONSONANTS_ORTHO_CHARS_STR:gsub("h","") .. CONSONANTS_ORTHO_CHARS_STR:upper() .. "°%-]") or char == 'h' then break
        else break
        end; temp_idx = temp_idx + 1
    end
    local next_v_group_str = table.concat(next_v_group_str_build)
    if ulen(next_v_group_str) > 0 then next_v_quality_implication = get_ortho_vowel_quality_implication_from_char_or_group(next_v_group_str, true) end

    temp_idx = ortho_cons_char_start_idx - 1
    local prev_v_group_str_build = {}
    while temp_idx >= 1 do
        local char = usub(original_ortho_word, temp_idx, temp_idx)
        if char == "ˈ" then break end 
        if umatch(char, ALL_VOWELS_ORTHO_PATTERN) then table.insert(prev_v_group_str_build, 1, char)
        else break
        end; temp_idx = temp_idx - 1
    end
    local prev_v_group_str = table.concat(prev_v_group_str_build)
    if ulen(prev_v_group_str) > 0 then prev_v_quality_implication = get_ortho_vowel_quality_implication_from_char_or_group(prev_v_group_str, false) end

    local final_quality
    if current_ortho_cons_seq == "s" and ortho_cons_char_start_idx > (1 + stress_marker_offset) and prev_v_group_str == "ú" then
      final_quality = "nonpalatal" 
    elseif not next_v_quality_implication then final_quality = (prev_v_quality_implication == "slender" and "palatal") or "nonpalatal"
    else final_quality = (next_v_quality_implication == "slender" and "palatal") or (next_v_quality_implication == "broad" and "nonpalatal") or (prev_v_quality_implication == "slender" and "palatal") or "nonpalatal"
    end
    debug_print_minimal("ConsonantResolution", "determine_cons_qual_ortho for '", current_ortho_cons_seq, "' in '", original_ortho_word, "' (idx:", ortho_cons_char_start_idx, "): NextVQual=", next_v_quality_implication or "nil", ", PrevVQual=", prev_v_quality_implication or "nil", " -> FinalQual=", final_quality)
    return final_quality
end

local function parse_phonetic_string_to_units_for_epenthesis(phon_str_raw)
    local phon_str = toNFC(phon_str_raw); local units = {}; local i = 1
    while i <= ulen(phon_str) do
        local stress_at_current_pos = ""; if usub(phon_str, i, i) == toNFC("ˈ") then stress_at_current_pos = toNFC("ˈ"); i = i + 1; end
        if i > ulen(phon_str) then if stress_at_current_pos ~= "" then table.insert(units, { phon = stress_at_current_pos, stress = "", quality = "stress_mark"}); end; break end
        local best_overall_match_phon, best_overall_match_len, best_overall_match_type = nil, 0, nil
        for _, unit_entry in ipairs(COMBINED_PHONETIC_UNITS_PRIORITY) do local unit_pattern_str = unit_entry.phon; local pattern_len_val = ulen(unit_pattern_str); if i + pattern_len_val - 1 <= ulen(phon_str) then local sub_to_test = usub(phon_str, i, i + pattern_len_val - 1); if sub_to_test == unit_pattern_str and pattern_len_val > best_overall_match_len then best_overall_match_phon = unit_pattern_str; best_overall_match_len = pattern_len_val; best_overall_match_type = unit_entry.type; end end end
        local quality = "unknown"; if best_overall_match_phon then if best_overall_match_type == "vowel" then quality = "vowel" elseif best_overall_match_type == "consonant" then if umatch(best_overall_match_phon, "ʲ$") or umatch(best_overall_match_phon, "^[ʃçjɟc]$") or umatch(best_overall_match_phon, "'$") then quality = "palatal" elseif umatch(best_overall_match_phon, "ˠ$") or umatch(best_overall_match_phon, "[̪]$") or umatch(best_overall_match_phon, "[̠]$") then quality = "nonpalatal" else quality = "nonpalatal" end end; table.insert(units, { phon = best_overall_match_phon, stress = stress_at_current_pos, quality = quality }); i = i + best_overall_match_len
        elseif stress_at_current_pos ~= "" then table.insert(units, { phon = stress_at_current_pos, stress = "", quality = "stress_mark"})
        else local unknown_char = usub(phon_str, i, i); local unknown_quality = "unknown_fallback"; for _, unit_entry in ipairs(COMBINED_PHONETIC_UNITS_PRIORITY) do if unit_entry.phon == unknown_char then if unit_entry.type == "vowel" then unknown_quality = "vowel" elseif unit_entry.type == "consonant" then if umatch(unknown_char, "ʲ$") or umatch(unknown_char, "^[ʃçjɟc]$") or umatch(unknown_char, "'$") then unknown_quality = "palatal" else unknown_quality = "nonpalatal" end end; goto add_fallback_unit_generic_parser end end; ::add_fallback_unit_generic_parser:: table.insert(units, { phon = unknown_char, stress = stress_at_current_pos, quality = unknown_quality }); i = i + 1 end
    end; return units
end

local function is_likely_monosyllable_phonetic_revised(phon_word_local, pre_parsed_units_input)
    if not phon_word_local then return false end
    local units_to_check = pre_parsed_units_input or parse_phonetic_string_to_units_for_epenthesis(ugsub(phon_word_local, "ˈ", ""))
    local count_local = 0
    for _, unit_data in ipairs(units_to_check) do if unit_data.quality == "vowel" then count_local = count_local + 1 end end
    if MINIMAL_DEBUG_ENABLED and (umatch(phon_word_local, "^cɑ~N") or umatch(phon_word_local, "^ɟɑ~l") or umatch(phon_word_local, "^bʲɑ~n") or umatch(phon_word_local, "^fɔ~N") or umatch(phon_word_local, "^pɔ~L") or umatch(phon_word_local, "^t̪rɔ~m") or umatch(phon_word_local, "^kɔ~R") or umatch(phon_word_local, "^bɔ~rd") or umatch(phon_word_local, "^ˈɑ~m")) then
        local unit_details = {}; for _, u_data_dbg in ipairs(units_to_check) do table.insert(unit_details, u_data_dbg.phon .. "(" .. u_data_dbg.quality .. ")") end
        debug_print_minimal("EpenthesisAndStrongSonorants", "is_likely_monosyllable (TARGETED) for '", phon_word_local, "': Units: {", table.concat(unit_details, ", "), "}, VowelCount: ", count_local, ", Result: ", tostring(count_local == 1))
    end
    return count_local == 1
end

local UNSTRESSED_PREFIXES_ORTHO = {"an%-", "droch%-", "mí%-", "do%-", "ró%-", "dea%-", "fíor%-", "sean%-", "ath%-", "comh%-", "fo%-", "frith%-", "idir%-", "in%-", "réamh%-", "so%-", "tras%-", "mór%-", "ban%-", "cam%-", "fionn%-", "leas%-"}
local function resolve_lenited_consonant(base_phoneme_palatal, base_phoneme_nonpalatal, full_match_marker, o_context_str, original_match_info_tbl, options)
    options = options or {}; if not original_match_info_tbl or not original_match_info_tbl.ortho_s or not original_match_info_tbl.ortho_e then return base_phoneme_nonpalatal end; local quality = determine_consonant_quality_ortho(o_context_str, original_match_info_tbl.ortho_s, original_match_info_tbl.ortho_e)
    if options.can_be_w and quality == "nonpalatal" then local next_v_char_idx = original_match_info_tbl.ortho_e + 1; if next_v_char_idx <= ulen(o_context_str) then local next_char = usub(o_context_str, next_v_char_idx, next_v_char_idx); if umatch(next_char, BROAD_VOWELS_ORTHO_PATTERN) then local prev_char_idx = original_match_info_tbl.ortho_s - 1; if prev_char_idx >= 1 then local prev_char = usub(o_context_str, prev_char_idx, prev_char_idx); if not umatch(prev_char, "[rlcsrlnLNRM]'?$") then return toNFC("w") end else return toNFC("w") end end end end
    return quality == 'palatal' and base_phoneme_palatal or base_phoneme_nonpalatal
end

irishPhonetics.rules_stage1_preprocess = { { pattern = toNFC("^%s*(.-)%s*$"), replacement = function(captured_string) if captured_string then return ulower(captured_string) else return "" end end }, { pattern = toNFC("%s+"), replacement = " " }, { pattern = toNFC("�"), replacement = "" }, { pattern = toNFC("^([^ˈ%-].*)$"), replacement = function(word_part_to_stress) debug_print_minimal("PreProcess", "Word for stress: '", word_part_to_stress, "'"); if not word_part_to_stress or word_part_to_stress == "" then return "" end; for _, prefix in ipairs(UNSTRESSED_PREFIXES_ORTHO) do local prefix_pattern_for_match = ugsub(prefix, "%-", ""); if usub(word_part_to_stress, 1, ulen(prefix_pattern_for_match)) == prefix_pattern_for_match then local root = usub(word_part_to_stress, ulen(prefix_pattern_for_match) + 1); debug_print_minimal("PreProcess", "Checking prefix '", prefix_pattern_for_match, "' against '", word_part_to_stress, "'. Root: '", root, "'"); if root == "" then return word_part_to_stress end; if umatch(root, "^" .. ALL_VOWELS_ORTHO_PATTERN) then return prefix_pattern_for_match .. toNFC("ˈ") .. root elseif umatch(root, "^(" .. CONSONANTS_ORTHO_CHARS_STR .. "+)(" .. ALL_VOWELS_ORTHO_PATTERN .. ")") then return prefix_pattern_for_match .. toNFC("ˈ") .. root else return word_part_to_stress end end end; debug_print_minimal("PreProcess", "Attempting direct stress on '", word_part_to_stress, "'. Vowel match: ", tostring(umatch(word_part_to_stress, "^" .. ALL_VOWELS_ORTHO_PATTERN)), ". CV match: ", tostring(umatch(word_part_to_stress, "^(" .. CONSONANTS_ORTHO_CHARS_STR .. "+)(" .. ALL_VOWELS_ORTHO_PATTERN .. ")"))); if umatch(word_part_to_stress, "^" .. ALL_VOWELS_ORTHO_PATTERN) then return toNFC("ˈ") .. word_part_to_stress elseif umatch(word_part_to_stress, "^(" .. CONSONANTS_ORTHO_CHARS_STR .. "+)(" .. ALL_VOWELS_ORTHO_PATTERN .. ")") then return toNFC("ˈ") .. word_part_to_stress end; return word_part_to_stress end },}
irishPhonetics.rules_stage2_mark_digraphs_and_vocalisation_triggers = {
    { pattern = toNFC("eacht"), replacement = toNFC("MKR_EACHTBRDFX"), ortho_len = 5 },
    { pattern = toNFC("eoi"), replacement = toNFC("MKR_EOITRIGOLNG"), ortho_len = 3 }, { pattern = toNFC("eói"), replacement = toNFC("MKR_EOITRIGOLNGACT"), ortho_len = 3 },
    { pattern = toNFC("bhf"), replacement = toNFC("MKR_URUF"), ortho_len = 3 }, { pattern = toNFC("bp"), replacement = toNFC("MKR_URUP"), ortho_len = 2 }, { pattern = toNFC("dt"), replacement = toNFC("MKR_URUT"), ortho_len = 2 }, { pattern = toNFC("gc"), replacement = toNFC("MKR_URUC"), ortho_len = 2 }, { pattern = toNFC("mb"), replacement = toNFC("MKR_URUM"), ortho_len = 2 }, { pattern = toNFC("nd"), replacement = toNFC("MKR_URUN"), ortho_len = 2 }, { pattern = toNFC("ng"), replacement = toNFC("MKR_URUG"), ortho_len = 2 },
    { pattern = toNFC("eidh(#?)$"), replacement = function(m,c1) return toNFC("MKR_EIDHCONNAI") .. (c1 or "") end, ortho_len = 4 },
    { pattern = toNFC("aghaidh(#?)$"), replacement = function(m,c1) return toNFC("MKR_AGHAIDHVOCTRGT") .. (c1 or "") end, ortho_len = 7 }, { pattern = toNFC("ubh(#?)$"), replacement = function(m,c1) return toNFC("MKR_UVOCBFIN") .. (c1 or "") end, ortho_len = 3}, { pattern = toNFC("ámh(#?)$"), replacement = function(m,c1) return toNFC("MKR_AACTLNGVOCMFIN") .. (c1 or "") end, ortho_len = 3}, { pattern = toNFC("amh(r)"), replacement = function(m,c1) return toNFC("MKR_AVOCMMEDR") .. c1 end, ortho_len = 3}, { pattern = toNFC("eabh(r)"), replacement = function(m,c1) return toNFC("MKR_EAVOCBMEDR") .. c1 end, ortho_len = 4}, { pattern = toNFC("adh(#?)$"), replacement = function(m,c1) return toNFC("MKR_AVOCDFIN") .. (c1 or "") end, ortho_len = 3}, { pattern = toNFC("eadh(#?)$"), replacement = function(m,c1) return toNFC("MKR_EAVOCDFIN") .. (c1 or "") end, ortho_len = 4}, { pattern = toNFC("agh(#?)$"), replacement = function(m,c1) return toNFC("MKR_AVOCGFIN") .. (c1 or "") end, ortho_len = 3}, { pattern = toNFC("ogh(#?)$"), replacement = function(m,c1) return toNFC("MKR_OVOCGFIN") .. (c1 or "") end, ortho_len = 3}, { pattern = toNFC("obh(#?)$"), replacement = function(m,c1) return toNFC("MKR_OVOCBFIN") .. (c1 or "") end, ortho_len = 3}, { pattern = toNFC("omh(#?)$"), replacement = function(m,c1) return toNFC("MKR_OVOCMFIN") .. (c1 or "") end, ortho_len = 3}, { pattern = toNFC("ibh(#?)$"), replacement = function(m,c1) return toNFC("MKR_IVOCBFIN") .. (c1 or "") end, ortho_len = 3}, { pattern = toNFC("imh(e#?)$"), replacement = function(m,c1) return toNFC("MKR_IVOCMMEDEFIN") .. (c1 or "") end, ortho_len = 4 }, { pattern = toNFC("imh(#?)$"), replacement = function(m,c1) return toNFC("MKR_IVOCMFIN") .. (c1 or "") end, ortho_len = 3}, { pattern = toNFC("idh(e#?)$"), replacement = function(m,c1) return toNFC("MKR_IVOCDMEDEFIN") .. (c1 or "") end, ortho_len = 4 }, { pattern = toNFC("idh(#?)$"), replacement = function(m,c1) return toNFC("MKR_IVOCDFIN") .. (c1 or "") end, ortho_len = 3}, 
    { pattern = toNFC("uidh$"), replacement = toNFC("MKR_UIVOCDFIN"), ortho_len = 4}, 
    { pattern = toNFC("uidh(e#?)$"), replacement = function(m,c1) return toNFC("MKR_UIVOCDMEDEFIN") .. (c1 or "") end, ortho_len = 5 }, 
    { pattern = toNFC("áth(#?)$"), replacement = function(m,c1) return toNFC("MKR_AACTLNGVOCTHSILFIN") .. (c1 or "") end, ortho_len = 3}, { pattern = toNFC("aidh(#?)$"), replacement = function(m,c1) return toNFC("MKR_AIDHFINSCHWA") .. (c1 or "") end, ortho_len = 4}, { pattern = toNFC("aigh(#?)$"), replacement = function(m,c1) return toNFC("MKR_AIGHFINSCHWA") .. (c1 or "") end, ortho_len = 4},
    { pattern = toNFC("aoi"), replacement = toNFC("MKR_AOILNG"), ortho_len = 3 }, { pattern = toNFC("ao"), replacement = toNFC("MKR_AOLNG"), ortho_len = 2 }, { pattern = toNFC("ói"), replacement = toNFC("MKR_OIACTLNG"), ortho_len = 2 }, { pattern = toNFC("aí"), replacement = toNFC("MKR_AIACTLNG"), ortho_len = 2 },
    { pattern = toNFC("^fh"), replacement = toNFC("MKR_FHINITLEN"), ortho_len = 2 }, { pattern = toNFC("bh"), replacement = toNFC("MKR_BH"), ortho_len = 2 }, { pattern = toNFC("mh"), replacement = toNFC("MKR_MH"), ortho_len = 2 }, { pattern = toNFC("ch"), replacement = toNFC("MKR_CH"), ortho_len = 2 }, { pattern = toNFC("dh"), replacement = toNFC("MKR_DH"), ortho_len = 2 }, { pattern = toNFC("gh"), replacement = toNFC("MKR_GH"), ortho_len = 2 }, { pattern = toNFC("ph"), replacement = toNFC("MKR_PH"), ortho_len = 2 }, { pattern = toNFC("sh"), replacement = toNFC("MKR_SH"), ortho_len = 2 }, { pattern = toNFC("th"), replacement = toNFC("MKR_TH"), ortho_len = 2 },
    { pattern = toNFC("ll"), replacement = toNFC("MKR_LL_STR"), ortho_len = 2 },   { pattern = toNFC("nn"), replacement = toNFC("MKR_NN_STR"), ortho_len = 2 }, { pattern = toNFC("rr"), replacement = toNFC("MKR_RR_STR"), ortho_len = 2 },   { pattern = toNFC("mm"), replacement = toNFC("MKR_MM_STR"), ortho_len = 2 },
    { pattern = toNFC("(ˈ"..SHORT_VOWELS_ORTHO_SINGLE_STR..")l("..ALL_VOWELS_ORTHO_PATTERN..")"), replacement = "%1l°%2", ortho_len_func = function(m,c1,c2) return ulen(c1) + 1 + ulen(c2) end}, { pattern = toNFC("(ˈ"..SHORT_VOWELS_ORTHO_SINGLE_STR..")n("..ALL_VOWELS_ORTHO_PATTERN..")"), replacement = "%1n°%2", ortho_len_func = function(m,c1,c2) return ulen(c1) + 1 + ulen(c2) end},}
irishPhonetics.rules_stage2_5_mark_suffixes = {
    { pattern = toNFC("eoireachta(#?)$"), replacement = toNFC("MKR_SUFFIX_OIRƏXTA").."%1", ortho_len = 10 },
    { pattern = toNFC("aíochta(#?)$"), replacement = toNFC("MKR_SUFFIX_IƏXTA").."%1", ortho_len = 7 },
    { pattern = toNFC("úint(#?)$"), replacement = toNFC("MKR_SUFFIX_UUNTJ").."%1", ortho_len = 5 },
    { pattern = toNFC("úil(#?)$"), replacement = toNFC("MKR_SUFFIX_UULJ").."%1", ortho_len = 3 },
    { pattern = toNFC("óir(#?)$"), replacement = toNFC("MKR_SUFFIX_OOIRJ").."%1", ortho_len = 3 },
    { pattern = toNFC("ín(#?)$"), replacement = toNFC("MKR_SUFFIX_IINJ").."%1", ortho_len = 2 },
    { pattern = toNFC("íonn(#?)$"), replacement = toNFC("MKR_SUFFIX_IIN_VERB").."%1", ortho_len = 4 },
    { pattern = toNFC("eann(#?)$"), replacement = toNFC("MKR_SUFFIX_ƏN_VERB").."%1", ortho_len = 4 },
    { pattern = toNFC("ann(#?)$"), replacement = toNFC("MKR_SUFFIX_ƏN_VERB").."%1", ortho_len = 3 },
    { pattern = toNFC("ach(#?)$"), replacement = toNFC("MKR_SUFFIX_ƏX").."%1", ortho_len = 3 },
    { pattern = toNFC("each(#?)$"), replacement = toNFC("MKR_SUFFIX_ƏX").."%1", ortho_len = 4 },
    { pattern = toNFC("aigh(#?)$"), replacement = toNFC("MKR_SUFFIX_VERB_IHI").."%1", ortho_len = 4 },
    { pattern = toNFC("aidh(#?)$"), replacement = toNFC("MKR_SUFFIX_VERB_IHI").."%1", ortho_len = 4 },
    { pattern = toNFC("aí(#?)$"), replacement = toNFC("MKR_SUFFIX_A_II").."%1", ortho_len = 2 },
    { pattern = toNFC("adh(#?)$"), replacement = toNFC("MKR_SUFFIX_ADH_VAR").."%1", ortho_len = 3 },
    { pattern = toNFC("eadh(#?)$"), replacement = toNFC("MKR_SUFFIX_ADH_VAR").."%1", ortho_len = 4 },
    { pattern = toNFC("áil(#?)$"), replacement = toNFC("MKR_SUFFIX_AALJ").."%1", ortho_len = 3 },
}
irishPhonetics.rules_stage3_consonant_resolution = {
    { pattern = toNFC("MKR_FH_INIT_LEN"), replacement = toNFC("h") }, { pattern = toNFC("MKR_FH_SILENT"), replacement = "" }, { pattern = toNFC("MKR_TH"), replacement = toNFC("h") }, { pattern = toNFC("MKR_URUF"), replacement = toNFC("v") }, { pattern = toNFC("MKR_URUP"), replacement = toNFC("b") }, { pattern = toNFC("MKR_URUT"), replacement = toNFC("d") }, { pattern = toNFC("MKR_URUC"), replacement = toNFC("g") }, { pattern = toNFC("MKR_URUM"), replacement = toNFC("m") }, { pattern = toNFC("MKR_URUN"), replacement = toNFC("n") }, { pattern = toNFC("MKR_URUG"), replacement = toNFC("ŋ") }, { pattern = toNFC("MKR_PH"), replacement = function(fm, ocs, omi) return resolve_lenited_consonant(toNFC("f'"), toNFC("f"), fm, ocs, omi) end }, { pattern = toNFC("MKR_SH"), replacement = function(fm, ocs, omi) if not omi or not omi.ortho_s or not omi.ortho_e then return toNFC("h") end; local next_v_start_ortho = omi.ortho_e + 1; local next_v_is_slender_flag = false; if next_v_start_ortho <= ulen(ocs) then if umatch(usub(ocs, next_v_start_ortho, next_v_start_ortho), SLENDER_VOWELS_ORTHO_PATTERN) then next_v_is_slender_flag = true end end; if umatch(ocs, "^[sS][eé][áa]n", omi.ortho_s -1 ) then return toNFC("h'") end; return next_v_is_slender_flag and toNFC("h'") or toNFC("h") end }, { pattern = toNFC("MKR_FH_INTERNAL"), replacement = "" }, { pattern = toNFC("MKR_BH"), replacement = function(fm, ocs, omi) return resolve_lenited_consonant(toNFC("v'"), toNFC("v"), fm, ocs, omi, {can_be_w = true}) end }, { pattern = toNFC("MKR_MH"), replacement = function(fm, ocs, omi) return resolve_lenited_consonant(toNFC("v'"), toNFC("v"), fm, ocs, omi, {can_be_w = true}) end }, { pattern = toNFC("MKR_DH"), replacement = function(fm, ocs, omi) return resolve_lenited_consonant(toNFC("j"), toNFC("ɣ"), fm, ocs, omi) end }, { pattern = toNFC("MKR_GH"), replacement = function(fm, ocs, omi) return resolve_lenited_consonant(toNFC("j"), toNFC("ɣ"), fm, ocs, omi) end },
    { pattern = toNFC("MKR_LL_STR"), replacement = function(fm, ocs, omi) local quality = determine_consonant_quality_ortho(ocs, omi.ortho_s, omi.ortho_e); return quality == "palatal" and ZZZ_L_STR_PAL_PHON or ZZZ_L_STR_BRD_PHON end },
    { pattern = toNFC("MKR_NN_STR"), replacement = function(fm, ocs, omi) local quality = determine_consonant_quality_ortho(ocs, omi.ortho_s, omi.ortho_e); debug_print_minimal("ConsonantResolution", "For MKR_NN_STR in '", ocs, "', determined quality: ", quality); return quality == "palatal" and ZZZ_N_STR_PAL_PHON or ZZZ_N_STR_BRD_PHON end },
    { pattern = toNFC("MKR_RR_STR"), replacement = function(fm, ocs, omi) return resolve_lenited_consonant(toNFC("R'"), toNFC("R"), fm, ocs, omi) end }, { pattern = toNFC("MKR_MM_STR"), replacement = function(fm, ocs, omi) return resolve_lenited_consonant(toNFC("M'"), toNFC("M"), fm, ocs, omi) end },
    { pattern = toNFC("l°"), replacement = toNFC("l_neutral_") }, { pattern = toNFC("n°"), replacement = toNFC("n_neutral_") },
    { pattern = toNFC("([bcdfghkmprst])"), replacement = function(c_capture, ocs, omi)
        if not c_capture then return "" end
        if c_capture == toNFC("l_neutral_") or c_capture == toNFC("n_neutral_") then return c_capture end
        local base = c_capture;
        if c_capture == toNFC("c") then base = toNFC("k") end
        if not omi or not omi.ortho_s or not omi.ortho_e or not ocs then return base == toNFC("s") and toNFC("s") or base end
        local quality = determine_consonant_quality_ortho(ocs, omi.ortho_s, omi.ortho_e);
        local is_truly_initial_in_ortho = (omi.ortho_s == 1);
        if omi.ortho_s == 2 and usub(ocs, 1, 1) == toNFC("ˈ") then is_truly_initial_in_ortho = true end
        
        if is_truly_initial_in_ortho and quality == "nonpalatal" then
            if base == toNFC("n") then return ZZZ_N_SNG_BRD_PHON
            elseif base == toNFC("l") then return ZZZ_L_SNG_BRD_PHON
            elseif not umatch(base, "^[srl]$") then debug_print_minimal("ConsonantResolution", "Initial non-palatal '", base, "' for '", c_capture, "' in '", ocs, "' -> returning base"); return base end
        end
        if base == toNFC("s") then return quality == "palatal" and toNFC("s'") or toNFC("s") else return quality == "palatal" and base .. toNFC("'") or base end
    end },
}
irishPhonetics.rules_stage4_0_specific_ortho_to_temp_marker = { { pattern = toNFC("^(ˈ?(?:[^"..ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR.."]*))a("..toNFC("MKR_AVOCMMEDR")..")(s["..ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR.."]?)"), replacement = "%1"..toNFC("MKR_TEMP_CONN_AU").."%3" }, { pattern = toNFC("^(ˈ?(?:[^"..ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR.."]*))ea("..toNFC("MKR_EAVOCBMEDR")..")(r["..ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR.."]?)"), replacement = "%1"..toNFC("MKR_TEMP_CONN_AU").."%3" }, { pattern = toNFC("("..ANY_SHORT_VOWEL_PHONETIC_CHARS_STR.."])("..toNFC("MKR_AVOCMMEDR")..")"), replacement = "%1"..toNFC("MKR_VOC_AMH_MED_R") }, { pattern = toNFC("("..ANY_SHORT_VOWEL_PHONETIC_CHARS_STR.."])("..toNFC("MKR_EAVOCBMEDR")..")"), replacement = "%1"..toNFC("MKR_VOC_EABH_MED_R") }, { pattern = toNFC("^(ˈ?)("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)".."ea("..toNFC("MKR_EACHTBRDFX")..")$"), replacement = "%1%2"..toNFC("MKR_EA_BRD_SHT_PRE_CHT").."%3" }, { pattern = toNFC("("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)".."ea("..toNFC("MKR_CH")..")"), replacement = "%1"..toNFC("MKR_EA_SLN_PRE_CH").."%2" }, { pattern = toNFC("("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)".."ea(ŋ)"), replacement = function(full_match, c_part, ng_cap, o_context_str, original_match_info_tbl) local ortho_n_start_idx = original_match_info_tbl.ortho_e - ulen(ng_cap) + 1; local quality_of_n = determine_consonant_quality_ortho(o_context_str, ortho_n_start_idx, ortho_n_start_idx); if quality_of_n == "palatal" then return (c_part or "") ..toNFC("MKR_EA_SLN_PRE_NG")..ng_cap else return (c_part or "") .. toNFC("MKR_EA_BRD_PRE_NG")..ng_cap end end, use_original_context_for_rules = true }, 
    { pattern = toNFC("("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)".."ea("..ZZZ_N_STR_PAL_PHON..")$"), replacement = "%1"..toNFC("MKR_EA_SLN_PRE_NN").."%2" }, 
    { pattern = toNFC("("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)".."ea("..ZZZ_N_STR_BRD_PHON..")$"), replacement = "%1"..toNFC("MKR_EA_BRD_PRE_NN").."%2" }, 
    { pattern = toNFC("("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)".."ea("..ZZZ_N_STR_BRD_PHON..")([^'])"), replacement = "%1"..toNFC("MKR_EA_BRD_PRE_NN").."%2%3" }, 
    { pattern = toNFC("("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)".."ea(r')"), replacement = "%1"..toNFC("MKR_EA_SLN_PRE_RPRIME").."%2" }, { pattern = toNFC("((?:["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."]'?)*)iu("..toNFC("MKR_CH")..")"), replacement = "%1"..toNFC("MKR_IU_SLN_FIN_PRE_CH").."%2" }, { pattern = toNFC("("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)".."ea(r)"), replacement = "%1"..toNFC("MKR_EA_BRD_PRE_R").."%2" }, { pattern = toNFC("("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)".."ea(n)$"), replacement = function(full_match, c_part, n_cap, o_context_str, original_match_info_tbl) local n_quality = determine_consonant_quality_ortho(o_context_str, original_match_info_tbl.ortho_s + ulen(c_part or "") + 2, original_match_info_tbl.ortho_s + ulen(c_part or "") + 2 ); if n_quality == "palatal" then return (c_part or "") .. toNFC("MKR_EA_SLN_PRE_N") .. (n_cap or "") else return (c_part or "") .. toNFC("MKR_EA_BRD_PRE_N") .. (n_cap or "") end end, use_original_context_for_rules = true }, { pattern = toNFC("("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)".."ea(n)([^" .. ALL_VOWELS_ORTHO_CHARS_STR .. "°%-bhfpgcdtmls" .. ANY_CONSONANT_PHONETIC_RAW_CHARS_STR .. "'])"), replacement = function(full_match, c_part, n_cap, next_char_phon, o_context_str, original_match_info_tbl) local n_quality = determine_consonant_quality_ortho(o_context_str, original_match_info_tbl.ortho_s + ulen(c_part or "") + 2, original_match_info_tbl.ortho_s + ulen(c_part or "") + 2 ); if n_quality == "palatal" then return (c_part or "") .. toNFC("MKR_EA_SLN_PRE_N") .. (n_cap or "") .. (next_char_phon or "") else return (c_part or "") .. toNFC("MKR_EA_BRD_PRE_N") .. (n_cap or "") .. (next_char_phon or "") end end, use_original_context_for_rules = true }, { pattern = toNFC("io"), replacement = toNFC("MKR_IO_SHT_TRGT") },}
irishPhonetics.rules_stage4_0_1_resolve_ch_marker = { { pattern = toNFC("MKR_CH"), replacement = function(full_match_marker, o_context_str, original_match_info_tbl) if not original_match_info_tbl or not original_match_info_tbl.ortho_s or not original_match_info_tbl.ortho_e then return toNFC("x") end; local quality_for_ch = determine_consonant_quality_ortho(o_context_str, original_match_info_tbl.ortho_s, original_match_info_tbl.ortho_e); return quality_for_ch == "palatal" and toNFC("ç") or toNFC("x") end },}
irishPhonetics.rules_stage4_1_vocmark_to_temp_marker = {}
irishPhonetics.rules_stage4_2_long_vowels_ortho_to_temp_marker = { { pattern = toNFC("éi"), replacement = toNFC("MKR_E_ACT_I_LNG") }, { pattern = toNFC("iú"), replacement = toNFC("MKR_I_ACT_U_LNG")}, { pattern = toNFC("á"), replacement = toNFC("MKR_A_ACT_LNG") }, { pattern = toNFC("é"), replacement = toNFC("MKR_E_ACT_LNG") }, { pattern = toNFC("í"), replacement = toNFC("MKR_I_ACT_LNG") }, { pattern = toNFC("ó"), replacement = toNFC("MKR_O_ACT_LNG") }, { pattern = toNFC("ú"), replacement = toNFC("MKR_U_ACT_LNG") }, { pattern = toNFC("MKR_AIACTLNG"), replacement = toNFC("MKR_A_I_ACT_LNG_RSLV") },}
irishPhonetics.rules_stage4_3_diphthongs_ortho_to_temp_marker = { 
    { pattern = toNFC("MKR_EOITRIGOLNG"), replacement = toNFC("MKR_EOI_TRIG_O_LNG")}, { pattern = toNFC("MKR_EOITRIGOLNGACT"), replacement = toNFC("MKR_EOI_TRIG_O_LNG_ACT")}, 
    { pattern = toNFC("b(ai)("..ZZZ_N_STR_PAL_PHON..")e"), replacement = "%1"..toNFC("MKR_A_FRM_BAINNE").."%2%3" }, 
    { pattern = toNFC("ae"), replacement = toNFC("MKR_AE_SEQ") }, { pattern = toNFC("ia"), replacement = toNFC("MKR_IA_DIPH") }, { pattern = toNFC("ua"), replacement = toNFC("MKR_UA_DIPH") }, { pattern = toNFC("ai"), replacement = toNFC("MKR_AI_DIPH") }, { pattern = toNFC("ei"), replacement = toNFC("MKR_EI_DIPH") }, { pattern = toNFC("oi"), replacement = toNFC("MKR_OI_DIPH") }, { pattern = toNFC("ui"), replacement = toNFC("MKR_UI_DIPH") }, { pattern = toNFC("au"), replacement = toNFC("MKR_AU_DIPH") }, { pattern = toNFC("ou"), replacement = toNFC("MKR_OU_DIPH") }, { pattern = toNFC("eo"), replacement = toNFC("MKR_EO_SEQ") },}
irishPhonetics.rules_stage4_4_resolve_temp_vowel_markers = {
    { pattern = toNFC("MKR_SUFFIX_ƏX"), replacement = toNFC("əx") }, { pattern = toNFC("MKR_SUFFIX_VERB_IHI"), replacement = toNFC("iː") }, { pattern = toNFC("MKR_SUFFIX_A_II"), replacement = toNFC("iː") }, { pattern = toNFC("MKR_SUFFIX_ADH_VAR"), replacement = toNFC("ə") }, { pattern = toNFC("MKR_SUFFIX_AALJ"), replacement = toNFC("ɑːlʲ") }, { pattern = toNFC("MKR_SUFFIX_UULJ"), replacement = toNFC("uːlʲ") }, { pattern = toNFC("MKR_SUFFIX_OOIRJ"), replacement = toNFC("oːɾʲ") }, { pattern = toNFC("MKR_SUFFIX_IINJ"), replacement = toNFC("iːnʲ") }, { pattern = toNFC("MKR_SUFFIX_ƏN_VERB"), replacement = toNFC("ən̪ˠ") }, { pattern = toNFC("MKR_SUFFIX_IIN_VERB"), replacement = toNFC("iːn̪ˠ") }, { pattern = toNFC("MKR_SUFFIX_UUNTJ"), replacement = toNFC("uːn̠ʲtʲ") },
    { pattern = toNFC("MKR_EOI_TRIG_O_LNG"), replacement = toNFC("oː") }, { pattern = toNFC("MKR_EOI_TRIG_O_LNG_ACT"), replacement = toNFC("oː") },
    { pattern = toNFC("MKR_EIDHCONNAI(#?)"), replacement = toNFC("ai%1")},
    { pattern = toNFC("MKR_UVOCBFIN(#?)"), replacement = toNFC("uː%1")}, { pattern = toNFC("MKR_AACTLNGVOCMFIN(#?)"), replacement = toNFC("ɑːv%1")}, { pattern = toNFC("MKR_AVOCMMEDR(r)"), replacement = toNFC("MKR_TEMP_CONN_AU%1")}, { pattern = toNFC("MKR_EAVOCBMEDR(r)"), replacement = toNFC("MKR_TEMP_CONN_AU%1")}, { pattern = toNFC("MKR_AVOCDFIN(#?)"), replacement = toNFC("ə%1")}, { pattern = toNFC("MKR_EAVOCDFIN(#?)"), replacement = toNFC("uː%1")}, { pattern = toNFC("MKR_AGHAIDHVOCTRGT(#?)"), replacement = toNFC("əi%1")}, { pattern = toNFC("MKR_AVOCGFIN(#?)"), replacement = toNFC("ə%1")}, { pattern = toNFC("MKR_OVOCGFIN(#?)"), replacement = toNFC("ə%1")}, { pattern = toNFC("MKR_OVOCBFIN(#?)"), replacement = toNFC("oː%1")}, { pattern = toNFC("MKR_OVOCMFIN(#?)"), replacement = toNFC("oː%1")}, { pattern = toNFC("MKR_IVOCBFIN(#?)"), replacement = toNFC("iː%1")}, 
    { pattern = toNFC("MKR_IVOCMMEDEFIN(#?)"), replacement = toNFC("ɪv'%1")}, { pattern = toNFC("MKR_IVOCMFIN(#?)"), replacement = toNFC("iː%1")}, 
    { pattern = toNFC("MKR_IVOCDMEDEFIN(#?)"), replacement = toNFC("iː%1")}, { pattern = toNFC("MKR_UIVOCDMEDEFIN(#?)"), replacement = toNFC("iː%1")}, 
    { pattern = toNFC("MKR_IVOCDFIN(#?)"), replacement = toNFC("iː%1")}, { pattern = toNFC("MKR_UIVOCDFIN(#?)"), replacement = toNFC("iː%1")}, 
    { pattern = toNFC("MKR_AACTLNGVOCTHSILFIN(#?)"), replacement = toNFC("ɑː%1")}, { pattern = toNFC("MKR_AIDHFINSCHWA(#?)"), replacement = toNFC("ə%1")}, { pattern = toNFC("MKR_AIGHFINSCHWA(#?)"), replacement = toNFC("ə%1")}, { pattern = toNFC("MKR_AIDHFINVOC(#?)"), replacement = toNFC("ai%1")}, { pattern = toNFC("MKR_AIGHFINVOC(#?)"), replacement = toNFC("ai%1")}, { pattern = toNFC("MKR_A_I_ACT_LNG_RSLV"), replacement = toNFC("iː") }, { pattern = toNFC("MKR_E_ACT_I_LNG"), replacement = toNFC("eː") }, { pattern = toNFC("MKR_I_ACT_U_LNG"), replacement = toNFC("uː")}, { pattern = toNFC("MKR_A_ACT_LNG"), replacement = toNFC("ɑː") }, { pattern = toNFC("MKR_E_ACT_LNG"), replacement = toNFC("eː") }, { pattern = toNFC("MKR_I_ACT_LNG"), replacement = toNFC("iː") }, { pattern = toNFC("MKR_O_ACT_LNG"), replacement = toNFC("oː") }, { pattern = toNFC("MKR_U_ACT_LNG"), replacement = toNFC("uː") }, { pattern = toNFC("MKR_AOLNG"), replacement = toNFC("iː")}, { pattern = toNFC("MKR_AOILNG"), replacement = toNFC("iː")}, { pattern = toNFC("MKR_OIACTLNG"), replacement = toNFC("oː")}, { pattern = toNFC("MKR_AE_SEQ"), replacement = toNFC("eː") }, { pattern = toNFC("MKR_EO_SEQ"), replacement = toNFC("oː") }, { pattern = toNFC("MKR_IA_DIPH"), replacement = toNFC("iə") }, { pattern = toNFC("MKR_UA_DIPH"), replacement = toNFC("ua") }, 
    { pattern = toNFC("MKR_A_FRM_BAINNE"), replacement = toNFC("a") }, 
    { pattern = toNFC("MKR_AI_DIPH("..ZZZ_N_STR_PAL_PHON..")$"), replacement = toNFC("a%1")}, 
    { pattern = toNFC("MKR_AI_DIPH(nm')"), replacement = toNFC("a%1")}, 
    { pattern = toNFC("MKR_AI_DIPH"), replacement = toNFC("ai") }, 
    { pattern = toNFC("MKR_EI_DIPH"), replacement = toNFC("e") }, { pattern = toNFC("MKR_OI_DIPH("..ANY_CONSONANT_PHONETIC_PATTERN.."*')"), replacement = toNFC("ɛ%1") }, { pattern = toNFC("MKR_OI_DIPH"), replacement = toNFC("ɔ") }, { pattern = toNFC("MKR_UI_DIPH"), replacement = toNFC("ɪ") }, { pattern = toNFC("MKR_AU_DIPH"), replacement = toNFC("au") }, { pattern = toNFC("MKR_OU_DIPH"), replacement = toNFC("ou") }, { pattern = toNFC("MKR_VOC_AMH_MED_R"), replacement = toNFC("MKR_TEMP_CONN_AU")}, { pattern = toNFC("MKR_VOC_EABH_MED_R"), replacement = toNFC("MKR_TEMP_CONN_AU")}, { pattern = toNFC("MKR_EA_PRE_BH_VOC"), replacement = toNFC("a")}, { pattern = toNFC("MKR_IO_SHT_TRGT"), replacement = toNFC("ɪ")},
    { pattern = toNFC("MKR_EACHTBRDFX"), replacement = toNFC("axt") },
    { pattern = toNFC("MKR_EA_BRD_SHT_PRE_CHT"), replacement = toNFC("a")},
    { pattern = toNFC("MKR_EA_SLN_PRE_CH"), replacement = toNFC("æ")},
    { pattern = toNFC("MKR_EA_SLN_PRE_NG"), replacement = toNFC("æ")}, { pattern = toNFC("MKR_EA_BRD_PRE_NG"), replacement = toNFC("a")}, { pattern = toNFC("MKR_EA_SLN_PRE_NN"), replacement = toNFC("æ")}, { pattern = toNFC("MKR_EA_BRD_PRE_NN"), replacement = toNFC("a")}, { pattern = toNFC("MKR_EA_SLN_PRE_RPRIME"), replacement = toNFC("æ")}, { pattern = toNFC("MKR_EA_BRD_PRE_R"), replacement = toNFC("a")}, { pattern = toNFC("MKR_IU_SLN_FIN_PRE_CH"), replacement = toNFC("ʊ")}, { pattern = toNFC("MKR_EA_SLN_PRE_N"), replacement = toNFC("æ")}, { pattern = toNFC("MKR_EA_BRD_PRE_N"), replacement = toNFC("a") },
    { pattern = toNFC("ea"), replacement = toNFC("a") }, 
}

-- Split rules for ($|#|CONSONANT_CLASS_NO_CAPTURE)
local vocalize_fric_rules = {}
local base_vocalize_rules_data = {
    {vowel_cap_str = SHORT_VOWEL_CAPTURE_FOR_EPENTHESIS, fric_in_str = toNFC("(v')"), fric_out_long_str = toNFC("MKR_TEMP_I_LONG_VOC"), fric_out_short_str = toNFC("v'")},
    {vowel_cap_str = SHORT_VOWEL_CAPTURE_FOR_EPENTHESIS, fric_in_str = toNFC("(j)"), fric_out_long_str = toNFC("MKR_TEMP_I_LONG_VOC"), fric_out_short_str = toNFC("j")}
}
for _, base_rule_data in ipairs(base_vocalize_rules_data) do
    table.insert(vocalize_fric_rules, {
        pattern = base_rule_data.vowel_cap_str .. base_rule_data.fric_in_str .. "$",
        replacement = function(fm, v_cap, fr_cap) 
            if umatch(v_cap, "^[eɛiɪ]") then return base_rule_data.fric_out_long_str 
            else return v_cap .. base_rule_data.fric_out_short_str end 
    end})
    table.insert(vocalize_fric_rules, {
        pattern = base_rule_data.vowel_cap_str .. base_rule_data.fric_in_str .. "#",
        replacement = function(fm, v_cap, fr_cap) 
            if umatch(v_cap, "^[eɛiɪ]") then return base_rule_data.fric_out_long_str .. "#"
            else return v_cap .. base_rule_data.fric_out_short_str .. "#" end
    end})
    table.insert(vocalize_fric_rules, {
        pattern = base_rule_data.vowel_cap_str .. base_rule_data.fric_in_str .. "(" .. CONSONANT_CLASS_NO_CAPTURE .. ")",
        replacement = function(fm, v_cap, fr_cap, after_fric_cap) 
            local char_after_fric = after_fric_cap
            local is_vowel_after = false; for _, p_part in ipairs(PHONETIC_VOWEL_NUCLEUS_PATTERN_PARTS) do if umatch(char_after_fric, "^"..p_part) then is_vowel_after = true; break; end end
            if umatch(v_cap, "^[eɛiɪ]") and not is_vowel_after then 
                return base_rule_data.fric_out_long_str .. (after_fric_cap or "")
            else return v_cap .. base_rule_data.fric_out_short_str .. (after_fric_cap or "") end
        end
    })
end

irishPhonetics.rules_stage4_4_1_vocalize_lenited_fricatives = vocalize_fric_rules
table.insert(irishPhonetics.rules_stage4_4_1_vocalize_lenited_fricatives, { pattern = toNFC("(" .. SHORT_VOWEL_CAPTURE_FOR_EPENTHESIS .. "v)$"), replacement = toNFC("MKR_TEMP_SCHWA_U_DIPH_VOC") })
table.insert(irishPhonetics.rules_stage4_4_1_vocalize_lenited_fricatives, { pattern = toNFC("(" .. SHORT_VOWEL_CAPTURE_FOR_EPENTHESIS .. "v)([^'])"), replacement = toNFC("MKR_TEMP_SCHWA_U_DIPH_VOC%2") })
table.insert(irishPhonetics.rules_stage4_4_1_vocalize_lenited_fricatives, { pattern = toNFC("(" .. SHORT_VOWEL_CAPTURE_FOR_EPENTHESIS .. "w)"), replacement = toNFC("MKR_TEMP_SCHWA_U_DIPH_VOC") })
table.insert(irishPhonetics.rules_stage4_4_1_vocalize_lenited_fricatives, { pattern = toNFC("(" .. SHORT_VOWEL_CAPTURE_FOR_EPENTHESIS .. "[ɣ])"), replacement = toNFC("MKR_TEMP_SCHWA_I_DIPH_VOC") })
table.insert(irishPhonetics.rules_stage4_4_1_vocalize_lenited_fricatives, { pattern = toNFC("MKR_TEMP_SCHWA_U_DIPH_VOC"), replacement = toNFC("əu") })
table.insert(irishPhonetics.rules_stage4_4_1_vocalize_lenited_fricatives, { pattern = toNFC("MKR_TEMP_SCHWA_I_DIPH_VOC"), replacement = toNFC("əi") })
table.insert(irishPhonetics.rules_stage4_4_1_vocalize_lenited_fricatives, { pattern = toNFC("MKR_TEMP_E_LONG_VOC"), replacement = toNFC("eː") })
table.insert(irishPhonetics.rules_stage4_4_1_vocalize_lenited_fricatives, { pattern = toNFC("MKR_TEMP_I_LONG_VOC"), replacement = toNFC("iː") })
table.insert(irishPhonetics.rules_stage4_4_1_vocalize_lenited_fricatives, { pattern = toNFC("MKR_TEMP_U_LONG_VOC"), replacement = toNFC("uː") })


placeholder_creation_rules_stage4_5 = { { pattern = toNFC("au"), replacement = toNFC("MKR_PHON_AU_DIPH") }, { pattern = toNFC("ai"), replacement = toNFC("MKR_PHON_AI_DIPH") }, { pattern = toNFC("iə"), replacement = toNFC("MKR_PHON_IA_DIPH") }, { pattern = toNFC("ua"), replacement = toNFC("MKR_PHON_UA_DIPH") }, { pattern = toNFC("ou"), replacement = toNFC("MKR_PHON_OU_DIPH") }, { pattern = toNFC("ei"), replacement = toNFC("MKR_PHON_EI_DIPH") }, { pattern = toNFC("oi"), replacement = toNFC("MKR_PHON_OI_DIPH") }, { pattern = toNFC("ui"), replacement = toNFC("MKR_PHON_UI_DIPH") }, { pattern = toNFC("əu"), replacement = toNFC("MKR_PHON_SCHWA_U_DIPH") }, { pattern = toNFC("aw"), replacement = toNFC("MKR_PHON_AW_SEQ") }, { pattern = toNFC("əi"), replacement = toNFC("MKR_PHON_SCHWA_I_DIPH") }, { pattern = toNFC("ɑː"), replacement = toNFC("MKR_PHON_A_LONG") }, { pattern = toNFC("eː"), replacement = toNFC("MKR_PHON_E_LONG") }, { pattern = toNFC("iː"), replacement = toNFC("MKR_PHON_I_LONG") }, { pattern = toNFC("oː"), replacement = toNFC("MKR_PHON_O_LONG") }, { pattern = toNFC("uː"), replacement = toNFC("MKR_PHON_U_LONG") }, { pattern = toNFC("ɨː"), replacement = toNFC("MKR_PHON_Y_LONG") }, { pattern = toNFC("æː"), replacement = toNFC("MKR_PHON_AE_LONG") },}
core_allophony_rules_for_stage4_5 = {
    { pattern = toNFC("MKR_PHON_Y_LONG"), replacement = toNFC("MKR_PHON_I_LONG") },
    { pattern = toNFC("("..ANY_CONSONANT_PHONETIC_PATTERN.."['])([ou])([kgxɣ])"), replacement = "%1ʊ%3" }, -- o/u -> ʊ / C'_Velar
    { pattern = toNFC("([kgptdfbmnszrlLNRMɣŋhwx]'?)([ou])([kgxɣ])"), replacement = "%1ʊ%3" }, -- o/u -> ʊ / C_Velar (broad initial C)
    { pattern = toNFC("("..ANY_CONSONANT_PHONETIC_PATTERN.."['])(a)(r)$"), replacement = "%1æ%3" }, 
    { pattern = toNFC("("..ANY_CONSONANT_PHONETIC_PATTERN.."['])(a)(R)$"), replacement = "%1æ%3" }, 
    { pattern = toNFC("("..ANY_CONSONANT_PHONETIC_PATTERN.."['])(a)("..BROAD_CONSONANT_PHONETIC_CLASS_NO_CAPTURE:gsub("[rR]","")..")"), replacement = "%1ɑ%3" }, 
    { pattern = toNFC("("..ANY_CONSONANT_PHONETIC_PATTERN.."['])(a)("..BROAD_CONSONANT_PHONETIC_CLASS_NO_CAPTURE:gsub("[rR]","")..")$"), replacement = "%1ɑ%3" }, 
    { pattern = toNFC("("..ANY_CONSONANT_PHONETIC_PATTERN.."['])(a)"), replacement = "%1æ" },
    { pattern = toNFC("a"), replacement = toNFC("ɑ") }, { pattern = toNFC("e"), replacement = toNFC("ɛ") }, { pattern = toNFC("i"), replacement = toNFC("ɪ") }, 
    { pattern = toNFC("o"), replacement = toNFC("ɔ") }, 
    -- { pattern = toNFC("u([kgxɣ])"), replacement = "ʊ%1" }, -- Covered by broader o/u rule above
    { pattern = toNFC("u"), replacement = toNFC("ɔ") },         
    { pattern = toNFC("(v')([aæ])"), replacement = "%1%2" }, { pattern = toNFC("t(æ)"), replacement = "t'%1"}, { pattern = toNFC("l(MKR_PHON_I_LONG)"), replacement = "l'%1"}, { pattern = toNFC("d(l'MKR_PHON_I_LONG)"), replacement = "d'%1"}, { pattern = toNFC("n(iv')"), replacement = "n'%1"}, { pattern = toNFC("(d'a)(r)(h)(MKR_PHON_A_LONGɾ')"), replacement = "%1ɾˠ%4" }, { pattern = toNFC("(MKR_PHON_A_LONG)i(r)$"), replacement = "%1iɾ'"}, { pattern = toNFC("d(a)(r)"), replacement = "d'%1%2"}, { pattern = toNFC("k(a)(rt)"), replacement = "c%1%2"}, 
    { pattern = toNFC("(MKR_PHON_I_LONGɔ)(["..BROAD_CONSONANT_PHONETIC_CLASS_NO_CAPTURE.."])"), replacement = "%1%2" }, 
    { pattern = toNFC("("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)([ɔʊʌ])("..ANY_CONSONANT_PHONETIC_PATTERN.."['])"), replacement = "%1ɛ%3" }, 
    { pattern = toNFC("([ɾR]')i"), replacement = "%1ɛ" }, { pattern = toNFC("([ɾR])i"), replacement = "%1ɛ" },  
    { pattern = toNFC("([ɾR]')ɔ"), replacement = "%1ɔ" }, { pattern = toNFC("([ɾR])ɔ"), replacement = "%1ɔ" },
    { pattern = toNFC("("..ANY_CONSONANT_PHONETIC_PATTERN.."*')(a)("..ANY_CONSONANT_PHONETIC_PATTERN.."['])"), replacement = "%1ɛ%3" }, 
    { pattern = toNFC("("..ANY_CONSONANT_PHONETIC_PATTERN.."*')([ɔʊʌ])("..ANY_CONSONANT_PHONETIC_PATTERN.."['])"), replacement = "%1ɪ%3" }, 
    { pattern = toNFC("("..ANY_CONSONANT_PHONETIC_PATTERN.."*')(e)("..ANY_CONSONANT_PHONETIC_PATTERN.."['])"), replacement = "%1ɛ%3" }, 
    { pattern = toNFC("("..ANY_CONSONANT_PHONETIC_PATTERN.."*')(i)("..ANY_CONSONANT_PHONETIC_PATTERN.."['])"), replacement = "%1ɪ%3" }, 
    { pattern = toNFC("l_neutral_"), replacement = toNFC("l")}, {pattern = toNFC("n_neutral_"), replacement = toNFC("n")},
}
placeholder_restoration_rules_stage4_5 = { { pattern = toNFC("MKR_PHON_A_LONG"), replacement = toNFC("ɑː") }, { pattern = toNFC("MKR_PHON_E_LONG"), replacement = toNFC("eː") }, { pattern = toNFC("MKR_PHON_I_LONG"), replacement = toNFC("iː") }, { pattern = toNFC("MKR_PHON_O_LONG"), replacement = toNFC("oː") }, { pattern = toNFC("MKR_PHON_U_LONG"), replacement = toNFC("uː") }, { pattern = toNFC("MKR_PHON_Y_LONG"), replacement = toNFC("ɨː") }, { pattern = toNFC("MKR_PHON_AE_LONG"), replacement = toNFC("æː") }, { pattern = toNFC("MKR_PHON_AU_DIPH"), replacement = toNFC("ɑu") }, { pattern = toNFC("MKR_PHON_AI_DIPH"), replacement = toNFC("ai") }, { pattern = toNFC("MKR_PHON_IA_DIPH"), replacement = toNFC("iə") }, { pattern = toNFC("MKR_PHON_UA_DIPH"), replacement = toNFC("ua") }, { pattern = toNFC("MKR_PHON_OU_DIPH"), replacement = toNFC("ou") }, { pattern = toNFC("MKR_PHON_EI_DIPH"), replacement = toNFC("ei") }, { pattern = toNFC("MKR_PHON_OI_DIPH"), replacement = toNFC("oi") }, { pattern = toNFC("MKR_PHON_UI_DIPH"), replacement = toNFC("ui") }, { pattern = toNFC("MKR_PHON_SCHWA_U_DIPH"), replacement = toNFC("əu") }, { pattern = toNFC("MKR_PHON_AW_SEQ"), replacement = toNFC("ɑu") }, { pattern = toNFC("MKR_PHON_SCHWA_I_DIPH"), replacement = toNFC("əi") },}
connacht_au_to_schwa_u_shift_rule_stage4_5 = { pattern = toNFC("^(ˈ?["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."]*'?)(ɑu)(["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."]*'?)$"), replacement = function(full_match, pre_part, au_diph, post_part) if is_likely_monosyllable_phonetic_revised(full_match) then return (pre_part or "") .. toNFC("əu") .. (post_part or "") end; return full_match end }
temp_conn_au_to_final_au_rule_stage4_5 = { pattern = toNFC("MKR_TEMP_CONN_AU"), replacement = toNFC("əu") }
irishPhonetics.rules_stage4_5_contextual_allophony_on_phonetic = {} -- Populated by helper

local function process_phonetic_units_procedurally(phon_word_input, stage_name_for_debug, unit_processor_func, context_params)
    if STAGE_DEBUG_ENABLED[stage_name_for_debug] then print("  " .. stage_name_for_debug .. " START (Proc Helper): In=", phon_word_input) end
    if not phon_word_input or phon_word_input == "" then return phon_word_input end

    local parsed_units = parse_phonetic_string_to_units_for_epenthesis(phon_word_input)
    if not parsed_units or #parsed_units == 0 then 
        if STAGE_DEBUG_ENABLED[stage_name_for_debug] then print("  " .. stage_name_for_debug .. " END (no units): Out=", phon_word_input) end
        return phon_word_input 
    end
    
    local modified_units_or_flag = unit_processor_func(parsed_units, phon_word_input, context_params)
    
    local final_units_to_rebuild
    local was_modified_by_processor = false

    if type(modified_units_or_flag) == "table" then
        final_units_to_rebuild = modified_units_or_flag
        if final_units_to_rebuild ~= parsed_units then was_modified_by_processor = true end
    elseif type(modified_units_or_flag) == "boolean" then
        final_units_to_rebuild = parsed_units 
        was_modified_by_processor = modified_units_or_flag
    else 
        final_units_to_rebuild = parsed_units
    end

    if was_modified_by_processor then
        local rebuilt_phon_word_parts = {}
        for _, unit_data in ipairs(final_units_to_rebuild) do
            table.insert(rebuilt_phon_word_parts, (unit_data.stress or "") .. unit_data.phon)
        end
        local new_phon_word = table.concat(rebuilt_phon_word_parts)
        if STAGE_DEBUG_ENABLED[stage_name_for_debug] then print("  " .. stage_name_for_debug .. " END (modified by unit_processor): Out=", new_phon_word) end
        return new_phon_word
    else
        if STAGE_DEBUG_ENABLED[stage_name_for_debug] then print("  " .. stage_name_for_debug .. " END (no change by unit_processor): Out=", phon_word_input) end
        return phon_word_input
    end
end

local function process_disyllabic_raising_on_units(parsed_units, phon_word_input, context)
    if not parsed_units or #parsed_units < 2 then return false end
    local vowel_units_data, primary_stress_vowel_original_index, explicit_stress_mark_found = {}, -1, false
    for k, unit_data in ipairs(parsed_units) do if unit_data.stress == toNFC("ˈ") then explicit_stress_mark_found = true; if k + 1 <= #parsed_units and parsed_units[k+1].quality == "vowel" then primary_stress_vowel_original_index = k + 1 end
        elseif unit_data.quality == "vowel" then table.insert(vowel_units_data, {phon=unit_data.phon, stress=unit_data.stress, quality=unit_data.quality, original_idx = k}); if not explicit_stress_mark_found and primary_stress_vowel_original_index == -1 then primary_stress_vowel_original_index = k end end
    end
    if #vowel_units_data ~= 2 then return false end
    local v1_data, v2_data = vowel_units_data[1], vowel_units_data[2]; local v1_original_idx = v1_data.original_idx
    local v1_is_stressed = (v1_original_idx == primary_stress_vowel_original_index)
    if not v1_is_stressed then return false end
    local v1_phon, v2_phon = v1_data.phon, v2_data.phon; local v1_is_short, v2_is_long = not umatch(v1_phon, "ː$"), umatch(v2_phon, "ː$")
    if not (v1_is_stressed and v1_is_short and v2_is_long) then return false end
    local c_after_v1_quality, c_after_v1_phon = "neutral", ""
    if v1_original_idx + 1 < v2_data.original_idx then local cons_idx = v1_original_idx + 1; while cons_idx < v2_data.original_idx and parsed_units[cons_idx].quality ~= "vowel" do if parsed_units[cons_idx].quality ~= "stress_mark" then c_after_v1_quality = parsed_units[cons_idx].quality; c_after_v1_phon = parsed_units[cons_idx].phon; break end; cons_idx = cons_idx + 1 end end
    debug_print_minimal("Stage4_5_1_DisyllabicShortLongRaising", "V1='",v1_phon,"', C_after_V1_qual='",c_after_v1_quality,"', C_after_V1_phon='",c_after_v1_phon,"', V2='",v2_phon,"'")
    local new_v1_phon = v1_phon
    if (v1_phon == toNFC("ɑ") or v1_phon == toNFC("ɔ") or v1_phon == toNFC("ʌ")) and c_after_v1_quality == "nonpalatal" then new_v1_phon = toNFC("ʊ")
    elseif (v1_phon == toNFC("ɛ") or v1_phon == toNFC("ɪ") or v1_phon == toNFC("i") or v1_phon == toNFC("e") or v1_phon == toNFC("ai")) and c_after_v1_quality == "palatal" then new_v1_phon = toNFC("ɪ") end
    if new_v1_phon ~= v1_phon then debug_print_minimal("Stage4_5_1_DisyllabicShortLongRaising", "Applying raising: V1 '", v1_phon, "' -> '", new_v1_phon, "'"); parsed_units[v1_original_idx].phon = new_v1_phon; return true end
    return false
end

local function process_nasalization_on_units(parsed_units, phon_word_input, context)
    debug_print_minimal("Nasalization", "General nasal spreading TEMPORARILY MINIMIZED/DISABLED for 37M testing.")
    return false 
end

local function process_unstressed_reduction_on_units(parsed_units, phon_word_input, context)
    if not parsed_units or #parsed_units == 0 then return false end
    local modified_in_pass = false
    local primary_stress_found, primary_stress_vowel_index = false, -1
    for k, unit_data in ipairs(parsed_units) do if unit_data.stress == toNFC("ˈ") then if k + 1 <= #parsed_units and parsed_units[k+1].quality == "vowel" then primary_stress_found = true; primary_stress_vowel_index = k + 1; break elseif unit_data.quality == "vowel" then primary_stress_found = true; primary_stress_vowel_index = k; break end end end
    if not primary_stress_found then for k, unit_data in ipairs(parsed_units) do if unit_data.quality == "vowel" then primary_stress_vowel_index = k; primary_stress_found = true; debug_print_minimal("Stage4_6_UnstressedVowelReduction_Procedural", "No explicit stress, first vowel '", unit_data.phon, "' at unit ", k, " is stressed."); break end end end
    
    for k, unit_data in ipairs(parsed_units) do
        if unit_data.quality == "vowel" then local is_stressed = (k == primary_stress_vowel_index); local v_phon = unit_data.phon; local is_eligible = not is_stressed and not umatch(v_phon, "ː$") and v_phon ~= toNFC("ə") and v_phon ~= toNFC("i")
            if is_eligible then
                local prec_c_qual, foll_c_qual = "neutral", "neutral"
                if k > 1 then local prev_actual_c_idx = k - 1; while prev_actual_c_idx > 0 and parsed_units[prev_actual_c_idx].quality == "stress_mark" do prev_actual_c_idx = prev_actual_c_idx - 1 end; if prev_actual_c_idx > 0 and (parsed_units[prev_actual_c_idx].quality == "palatal" or parsed_units[prev_actual_c_idx].quality == "nonpalatal") then prec_c_qual = parsed_units[prev_actual_c_idx].quality end end
                if k < #parsed_units then local next_actual_c_idx = k + 1; if next_actual_c_idx <= #parsed_units and parsed_units[next_actual_c_idx].quality ~= "stress_mark" then if parsed_units[next_actual_c_idx].quality == "palatal" or parsed_units[next_actual_c_idx].quality == "nonpalatal" then foll_c_qual = parsed_units[next_actual_c_idx].quality end end end
                
                local reduced_v = toNFC("ə") 
                if foll_c_qual == "palatal" then reduced_v = toNFC("i")
                elseif foll_c_qual == "nonpalatal" then reduced_v = toNFC("ə")
                elseif prec_c_qual == "palatal" then reduced_v = toNFC("i")
                end

                if v_phon == toNFC("ɛ") and k > 1 and parsed_units[k-1].phon == toNFC("v'") and k == #parsed_units then 
                    reduced_v = toNFC("ə")
                end

                if reduced_v ~= unit_data.phon then debug_print_minimal("Stage4_6_UnstressedVowelReduction_Procedural", "Reducing '", unit_data.phon, "' to '", reduced_v, "'. Prec: ", prec_c_qual, " Foll: ", foll_c_qual); parsed_units[k].phon = reduced_v; modified_in_pass = true end
            end
        end
    end
    return modified_in_pass
end

irishPhonetics.rules_stage4_6_unstressed_vowel_reduction_specific_finals = { { pattern = toNFC("aí$"), replacement = toNFC("iː") }, { pattern = toNFC("eiə$"), replacement = toNFC("iː")}, { pattern = toNFC("iːə$"), replacement = toNFC("iː")}, }
irishPhonetics.EPENTHESIS_TARGET_CLUSTERS_BROAD = { [toNFC("lk")]=true, [toNFC("lg")]=true, [toNFC("lb")]=true, [toNFC("lv")]=true, [toNFC("rm")]=true, [toNFC("rx")]=true, [toNFC("rb")]=true, [toNFC("rg")]=true, }
irishPhonetics.EPENTHESIS_TARGET_CLUSTERS_SLENDER = { [toNFC("lk")]=true, [toNFC("lf")]=true, [toNFC("rg")]=true, [toNFC("rk")]=true, [toNFC("nm")]=true, }

local function process_epenthesis_on_units(parsed_units, phon_word_input, context)
    local is_overall_monosyllable = is_likely_monosyllable_phonetic_revised(phon_word_input, parsed_units)
    if not is_overall_monosyllable then return false end 
    local new_units_build, i, modified_by_epenthesis = {}, 1, false
    while i <= #parsed_units do
        if parsed_units[i].quality == "stress_mark" then table.insert(new_units_build, parsed_units[i]); i = i + 1; if i > #parsed_units then break end end
        if i + 2 <= #parsed_units then
            local unit_v, unit_c1, unit_c2 = parsed_units[i], parsed_units[i+1], parsed_units[i+2]
            local is_v_short = unit_v.quality == "vowel" and not umatch(unit_v.phon, "ː$")
            local c1_base = ugsub(unit_c1.phon, "['ˠʲ̪]", ""); local is_c1_son = umatch(c1_base, "^[rlnm]$")
            local c2_base = ugsub(unit_c2.phon, "['ˠʲ̪]", ""); local is_c2_valid = umatch(c2_base, "^[kgptdfbxs]$") or (is_c1_son and umatch(c2_base, "^[rlnm]$"))
            local c1_qual, c2_qual = unit_c1.quality, unit_c2.quality
            local cluster_key = c1_base .. c2_base; local ep_v_insert = nil
            if is_v_short and is_c1_son and is_c2_valid then
                if c1_qual == "palatal" and c2_qual == "palatal" then if irishPhonetics.EPENTHESIS_TARGET_CLUSTERS_SLENDER[cluster_key] then ep_v_insert = toNFC("i") end
                elseif c1_qual == "nonpalatal" and c2_qual == "nonpalatal" then if irishPhonetics.EPENTHESIS_TARGET_CLUSTERS_BROAD[cluster_key] then ep_v_insert = toNFC("ə") end
                end
            end
            if ep_v_insert then
                debug_print_minimal("EpenthesisAndStrongSonorants", "PROCEDURAL Epenthesis: ", unit_v.stress..unit_v.phon, unit_c1.phon, unit_c2.phon, " -> inserting ", ep_v_insert)
                table.insert(new_units_build, unit_v); table.insert(new_units_build, unit_c1); table.insert(new_units_build, { phon = ep_v_insert, stress = "", quality = (ep_v_insert == toNFC("i") and "palatal" or "nonpalatal") }); table.insert(new_units_build, unit_c2)
                i = i + 3; modified_by_epenthesis = true
            else table.insert(new_units_build, parsed_units[i]); i = i + 1 end
        else if i <= #parsed_units then table.insert(new_units_build, parsed_units[i]) end; i = i + 1 end
    end
    if modified_by_epenthesis then return new_units_build else return false end 
end

irishPhonetics.rules_stage5_strong_sonorants_only = {}
do
    local CPART_CAPTURE = CPART_CAPTURE_STRICT; local FINAL_CONS_CAPTURE = FINAL_CONSONANT_CAPTURE_STRICT
    local vowel_effects_map_ss_connacht = {
        {input_v_class_str=VOWEL_A_CLASS_CAPTURE_STRICT,    broad_lnm=toNFC("ɑː"), broad_r=toNFC("ɑː"), pal_lnm_N_target=toNFC("a"), pal_lnm_L_target=toNFC("a"), pal_lnm_M_target=toNFC("a"), pal_r=toNFC("ɑː"), sonorant_triggers_special_diphthong = {}},
        {input_v_class_str=VOWEL_E_I_CLASS_CAPTURE_STRICT,  broad_lnm=toNFC("iː"), broad_r=toNFC("a"), pal_lnm_N_target=toNFC("iː"), pal_lnm_L_target=toNFC("iː"), pal_lnm_M_target=toNFC("iː"), pal_r=toNFC("əi"), sonorant_triggers_special_diphthong = {}},
        {input_v_class_str=VOWEL_O_U_CLASS_CAPTURE_STRICT,  broad_lnm=toNFC("uː"), broad_r=toNFC("əu"), pal_lnm_N_target=toNFC("iː"), pal_lnm_L_target=toNFC("oi"), pal_lnm_M_target=toNFC("uː"), pal_r=toNFC("ai"), sonorant_triggers_special_diphthong = {[ZZZ_L_STR_BRD_PHON]=toNFC("ɑu"), [ZZZ_L_SNG_BRD_PHON]=toNFC("ɑu")}}, 
        {input_v_class_str=DIPHTHONG_AI_CAPTURE_STRICT,   broad_lnm=toNFC("ɑː"), broad_r=toNFC("ɑː"), pal_lnm_N_target=toNFC("ai"), pal_lnm_L_target=toNFC("ai"), pal_lnm_M_target=toNFC("ai"), pal_r=toNFC("ɑː"), sonorant_triggers_special_diphthong = {}}
    }
    
    local function create_rules_for_specific_sonorant(rules_table, vowel_class_capture_str_arg, specific_son_marker_literal, son_type_key_base_str_arg, veffect_entry_arg, is_palatal_arg)
        local actual_repl_v_base
        if veffect_entry_arg.sonorant_triggers_special_diphthong[specific_son_marker_literal] and not is_palatal_arg then
            actual_repl_v_base = veffect_entry_arg.sonorant_triggers_special_diphthong[specific_son_marker_literal]
        elseif is_palatal_arg then
            if son_type_key_base_str_arg == "PalR" then actual_repl_v_base = veffect_entry_arg.pal_r
            elseif son_type_key_base_str_arg == "PalN" then actual_repl_v_base = veffect_entry_arg.pal_lnm_N_target
            elseif son_type_key_base_str_arg == "PalL" then actual_repl_v_base = veffect_entry_arg.pal_lnm_L_target
            elseif son_type_key_base_str_arg == "PalM" then actual_repl_v_base = veffect_entry_arg.pal_lnm_M_target
            else actual_repl_v_base = veffect_entry_arg.pal_lnm_N_target 
            end
        else 
            if son_type_key_base_str_arg == "BroadN" or son_type_key_base_str_arg == "BroadL" or son_type_key_base_str_arg == "BroadM" then
                actual_repl_v_base = veffect_entry_arg.broad_lnm
            elseif son_type_key_base_str_arg == "BroadR" then
                actual_repl_v_base = veffect_entry_arg.broad_r
            else 
                 actual_repl_v_base = veffect_entry_arg[son_type_key_base_str_arg:lower()] 
            end
        end
        if not actual_repl_v_base then debug_print_minimal("EpenthesisAndStrongSonorants", "SS Rule WARNING: No replacement vowel for VClass='", veffect_entry_arg.input_v_class_str:sub(1,10), "' SonKey='", son_type_key_base_str_arg, "' Pal=", tostring(is_palatal_arg)); return end

        local patterns_to_generate = {
            {ptn="^(ˈ?)" .. CPART_CAPTURE .. vowel_class_capture_str_arg .. "("..specific_son_marker_literal..")" .. FINAL_CONS_CAPTURE .. "(#?)$", caps={s=true, cp=true, v=true, son=true, fc=true, b=true}}, 
            {ptn="^(ˈ?)" .. CPART_CAPTURE .. vowel_class_capture_str_arg .. "("..specific_son_marker_literal..")" .. "(#?)$", caps={s=true, cp=true, v=true, son=true, fc=false, b=true}},
            {ptn="^(ˈ?)" .. vowel_class_capture_str_arg .. "("..specific_son_marker_literal..")" .. FINAL_CONS_CAPTURE .. "(#?)$", caps={s=true, cp=false, v=true, son=true, fc=true, b=true}}, 
            {ptn="^(ˈ?)" .. vowel_class_capture_str_arg .. "("..specific_son_marker_literal..")" .. "(#?)$", caps={s=true, cp=false, v=true, son=true, fc=false, b=true}}
        }
        for _, ptn_data in ipairs(patterns_to_generate) do
            table.insert(rules_table, { pattern = ptn_data.ptn, replacement = function(...)
                    local all_captures = {...}; local fm = all_captures[1]; local stress, c_part, vowel_cap, son_cap, final_cons_cap, boundary_cap; local current_cap_idx = 2 
                    if ptn_data.caps.s then stress = all_captures[current_cap_idx]; current_cap_idx = current_cap_idx + 1; end; if ptn_data.caps.cp then c_part = all_captures[current_cap_idx]; current_cap_idx = current_cap_idx + 1; end; if ptn_data.caps.v then vowel_cap = all_captures[current_cap_idx]; current_cap_idx = current_cap_idx + 1; end; if ptn_data.caps.son then son_cap = all_captures[current_cap_idx]; current_cap_idx = current_cap_idx + 1; end; if ptn_data.caps.fc then final_cons_cap = all_captures[current_cap_idx]; current_cap_idx = current_cap_idx + 1; end; if ptn_data.caps.b then boundary_cap = all_captures[current_cap_idx]; end
                    local final_replacement_vowel = actual_repl_v_base
                    debug_print_minimal("EpenthesisAndStrongSonorants", "SS Rule EXEC (Helper): PtnKey='",son_type_key_base_str_arg, veffect_entry_arg.input_v_class_str,"' Ptn='",ptn_data.ptn,"' Full='",fm,"' VIn='",vowel_cap or "","' VOut='",final_replacement_vowel or "nil","'.")
                    return (stress or "") .. (c_part or "") .. (final_replacement_vowel or vowel_cap or "") .. (son_cap or "") .. (final_cons_cap or "") .. (boundary_cap or "")
                end, use_current_phonetic_for_condition = true, condition_func = function(fm, pu) return is_likely_monosyllable_phonetic_revised(fm, pu) end })
        end
    end
    for _, veffect in ipairs(vowel_effects_map_ss_connacht) do
        for _, son_mkr in ipairs(BROAD_LNM_MARKERS_FOR_STAGE5) do 
            local son_type_key = "BroadLNM"; if umatch(son_mkr, "ZZZN") then son_type_key = "BroadN" elseif umatch(son_mkr, "ZZZL") then son_type_key = "BroadL" elseif umatch(son_mkr, "^[mM]$") then son_type_key = "BroadM" end
            create_rules_for_specific_sonorant(irishPhonetics.rules_stage5_strong_sonorants_only, veffect.input_v_class_str, son_mkr, son_type_key, veffect, false) 
        end
        for _, son_mkr in ipairs(BROAD_R_MARKERS_FOR_STAGE5) do create_rules_for_specific_sonorant(irishPhonetics.rules_stage5_strong_sonorants_only, veffect.input_v_class_str, son_mkr, "BroadR", veffect, false) end
        for _, son_mkr in ipairs(PALATAL_LNM_MARKERS_FOR_STAGE5) do 
            local son_type_key = "PalLNM"; if umatch(son_mkr, "ZZZN") then son_type_key = "PalN" elseif umatch(son_mkr, "ZZZL") then son_type_key = "PalL" elseif umatch(son_mkr, "^[mM]'") then son_type_key = "PalM" elseif umatch(son_mkr, "^[nNlL]'") then son_type_key = "PalLNM" end
            create_rules_for_specific_sonorant(irishPhonetics.rules_stage5_strong_sonorants_only, veffect.input_v_class_str, son_mkr, son_type_key, veffect, true) 
        end
        for _, son_mkr in ipairs(PALATAL_R_MARKERS_FOR_STAGE5) do create_rules_for_specific_sonorant(irishPhonetics.rules_stage5_strong_sonorants_only, veffect.input_v_class_str, son_mkr, "PalR", veffect, true) end
    end
end

irishPhonetics.rules_stage6_diacritics = { 
    { pattern = toNFC("n̪(x)"), replacement = toNFC("nˠ%1") }, 
    { pattern = toNFC("s$"), replacement = toNFC("sˠ") }, { pattern = toNFC("s(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])"), replacement = toNFC("sˠ%1") }, { pattern = toNFC("s(" .. SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR .. ")"), replacement = toNFC("sˠ%1") }, { pattern = toNFC("t$"), replacement = toNFC("t̪") }, { pattern = toNFC("t(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])"), replacement = toNFC("t̪%1") }, { pattern = toNFC("t(" .. SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR .. ")"), replacement = toNFC("t̪%1") }, { pattern = toNFC("d$"), replacement = toNFC("d̪") }, { pattern = toNFC("d(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])"), replacement = toNFC("d̪%1") }, { pattern = toNFC("d(" .. SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR .. ")"), replacement = toNFC("d̪%1") }, { pattern = toNFC("n$"), replacement = toNFC("n̪") }, { pattern = toNFC("n(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])"), replacement = toNFC("n̪%1") }, { pattern = toNFC("n(" .. SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR .. ")"), replacement = toNFC("n̪%1") }, { pattern = toNFC("l$"), replacement = toNFC("l̪") }, { pattern = toNFC("l(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])"), replacement = toNFC("l̪%1") }, { pattern = toNFC("l(" .. SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR .. ")"), replacement = toNFC("l̪%1") }, { pattern = toNFC("r$"), replacement = toNFC("ɾˠ") }, { pattern = toNFC("r(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])"), replacement = toNFC("ɾˠ%1") }, { pattern = toNFC("r(" .. SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR .. ")"), replacement = toNFC("ɾˠ%1") }, { pattern = toNFC("m$"), replacement = toNFC("mˠ") }, { pattern = toNFC("m(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])"), replacement = toNFC("mˠ%1") }, { pattern = toNFC("m(" .. SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR .. ")"), replacement = toNFC("mˠ%1") }, { pattern = toNFC("b$"), replacement = toNFC("bˠ") }, { pattern = toNFC("b(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])"), replacement = toNFC("bˠ%1") }, { pattern = toNFC("b(" .. SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR .. ")"), replacement = toNFC("bˠ%1") }, { pattern = toNFC("p$"), replacement = toNFC("pˠ") }, { pattern = toNFC("p(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])"), replacement = toNFC("pˠ%1") }, { pattern = toNFC("p(" .. SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR .. ")"), replacement = toNFC("pˠ%1") }, { pattern = toNFC("f$"), replacement = toNFC("fˠ") }, { pattern = toNFC("f(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])"), replacement = toNFC("fˠ%1") }, { pattern = toNFC("f(" .. SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR .. ")"), replacement = toNFC("fˠ%1") }, }
irishPhonetics.rules_stage7_final_cleanup = { 
    { pattern = ZZZ_N_STR_PAL_PHON, replacement = toNFC("n̠ʲ") }, { pattern = ZZZ_N_STR_BRD_PHON, replacement = toNFC("n̪ˠ") }, 
    { pattern = ZZZ_L_STR_PAL_PHON, replacement = toNFC("l̠ʲ") }, { pattern = ZZZ_L_STR_BRD_PHON, replacement = toNFC("l̪ˠ") }, 
    { pattern = ZZZ_N_SNG_BRD_PHON, replacement = toNFC("n̪ˠ")}, { pattern = ZZZ_L_SNG_BRD_PHON, replacement = toNFC("l̪ˠ")}, 
    { pattern = toNFC("(n̠ʲ)t̪$"), replacement = "%1tʲ" }, { pattern = toNFC("(n̠ʲ)t̪(" .. CONSONANT_CLASS_NO_CAPTURE .. ")"), replacement = "%1tʲ%2" },
    { pattern = toNFC("("..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR..")''"), replacement = "%1'" }, 
    { pattern = toNFC("s'"), replacement = toNFC("ʃ") }, { pattern = toNFC("t'"), replacement = toNFC("tʲ") }, { pattern = toNFC("d'"), replacement = toNFC("dʲ") }, 
    { pattern = toNFC("k'"), replacement = toNFC("c") }, { pattern = toNFC("g'"), replacement = toNFC("ɟ") }, 
    { pattern = toNFC("l'"), replacement = toNFC("lʲ") }, { pattern = toNFC("n'"), replacement = toNFC("nʲ") }, 
    { pattern = toNFC("R'"), replacement = toNFC("ɾʲ") }, { pattern = toNFC("r'"), replacement = toNFC("ɾʲ") }, 
    { pattern = toNFC("f'"), replacement = toNFC("fʲ") }, { pattern = toNFC("v'"), replacement = toNFC("vʲ") }, 
    { pattern = toNFC("b'"), replacement = toNFC("bʲ") }, { pattern = toNFC("p'"), replacement = toNFC("pʲ") }, 
    { pattern = toNFC("M'"), replacement = toNFC("mʲ") }, { pattern = toNFC("m'"), replacement = toNFC("mʲ") }, 
    { pattern = toNFC("h'"), replacement = toNFC("ç") }, 
    { pattern = toNFC("L"), replacement = toNFC("lˠ") }, { pattern = toNFC("N"), replacement = toNFC("nˠ") }, 
    { pattern = toNFC("R"), replacement = toNFC("ɾˠ") }, { pattern = toNFC("M"), replacement = toNFC("mˠ") }, 
    { pattern = toNFC("h$"), replacement = ""}, { pattern = toNFC("#"), replacement = ""}, 
    { pattern = toNFC("^%s*(.-)%s*$"), replacement = "%1" }, { pattern = toNFC("ˈə"), replacement = toNFC("ə") }, 
    { pattern = toNFC(" "), replacement = toNFC(" ")}, { pattern = toNFC("%-"), replacement = ""}, 
    { pattern = toNFC("MKR_"), replacement = ""}, 
    { pattern = toNFC("ZZZ"), replacement = ""}, 
    { pattern = toNFC("&"), replacement = ""}, 
}

local function apply_rules_to_string_generic(current_string_input, rules_to_apply_list, stage_name_str, mode_str, 
                                            use_orig_context_flag, o_context_str_for_func, current_ortho_map_for_func, full_phon_word_for_func_repl)
    local current_string_local = current_string_input
    
    if mode_str == "iterative_gsub" then
        local iteration_changed_this_pass; repeat iteration_changed_this_pass = false
            local string_before_this_gsub_pass = current_string_local
            for _, rule_data in ipairs(rules_to_apply_list) do
                if type(rule_data.pattern) == "string" then
                    local replacement_target = rule_data.replacement
                    if type(rule_data.replacement) == "function" and rule_data.needs_full_context_in_func then
                        replacement_target = function(...) return rule_data.replacement(..., current_string_local, ufind(current_string_local, rule_data.pattern, (...))) end
                    end
                    local new_str, num_repl = ugsub(current_string_local, rule_data.pattern, replacement_target)
                    if new_str ~= current_string_local then debug_print_minimal(stage_name_str, "Iter.gsub: Rule '", rule_data.pattern, "' APPLIED to '", current_string_local, "' -> '", new_str, "' (", num_repl, "x)"); current_string_local = new_str; iteration_changed_this_pass = true end
                end
            end
        until not iteration_changed_this_pass
    elseif mode_str == "single_pass_priority_match" then
        local new_string_parts = {}; local scan_offset = 1
        while scan_offset <= ulen(current_string_local) do
            local best_match_s, best_match_e, best_rule_idx; local best_captures = {}; local current_best_match_len = -1
            for rule_idx, rule_data in ipairs(rules_to_apply_list) do
                if type(rule_data.pattern) == "string" then
                    local s, e, cap1,cap2,cap3,cap4,cap5,cap6,cap7,cap8,cap9,cap10 = ufind(current_string_local, rule_data.pattern, scan_offset)
                    if s then local current_match_len = e - s + 1; if not best_match_s or s < best_match_s or (s == best_match_s and current_match_len > current_best_match_len) then best_match_s = s; best_match_e = e; best_rule_idx = rule_idx; current_best_match_len = current_match_len; best_captures = {cap1,cap2,cap3,cap4,cap5,cap6,cap7,cap8,cap9,cap10} end end
                end
            end
            if best_rule_idx then
                if best_match_s > scan_offset then table.insert(new_string_parts, usub(current_string_local, scan_offset, best_match_s - 1)) end
                local rule = rules_to_apply_list[best_rule_idx]; local full_match_seg = usub(current_string_local, best_match_s, best_match_e)
                local actual_caps_for_func = {}; if best_captures then for _,c_val in ipairs(best_captures) do if c_val~=nil then table.insert(actual_caps_for_func, c_val) end end end
                local apply_this_rule_now = true
                if rule.use_current_phonetic_for_condition and rule.condition_func then local parsed_units_for_cond_generic = parse_phonetic_string_to_units_for_epenthesis(full_match_seg); if not rule.condition_func(full_match_seg, parsed_units_for_cond_generic) then apply_this_rule_now = false end end
                local replacement_val
                if apply_this_rule_now then
                    if type(rule.replacement) == "string" then replacement_val = rule.replacement; if replacement_val:match("%%[%d]") then local temp_r = replacement_val; for i_c = #actual_caps_for_func, 1, -1 do temp_r = ugsub(temp_r, "%%"..i_c, actual_caps_for_func[i_c] or "") end; replacement_val = temp_r end
                    elseif type(rule.replacement) == "function" then
                        local call_params = {full_match_seg}; for _, cap_v in ipairs(actual_caps_for_func) do table.insert(call_params, cap_v) end
                        if use_orig_context_flag then local o_s, o_l = get_original_indices_from_map(best_match_s, best_match_e, current_ortho_map_for_func); local o_match_info = {ortho_s = o_s, ortho_e = o_s + o_l - 1}; table.insert(call_params, o_context_str_for_func); table.insert(call_params, o_match_info) 
                        elseif rule.needs_full_context_in_func then table.insert(call_params, current_string_local); table.insert(call_params, best_match_s); table.insert(call_params, best_match_e)
                        end
                        replacement_val = rule.replacement(table.unpack(call_params))
                    end; replacement_val = replacement_val or ""
                else replacement_val = full_match_seg end
                table.insert(new_string_parts, replacement_val); scan_offset = best_match_e + 1
            else if scan_offset <= ulen(current_string_local) then table.insert(new_string_parts, usub(current_string_local, scan_offset)) end; break end
        end; current_string_local = table.concat(new_string_parts)
    end
    return current_string_local
end

function irishPhonetics.transcribe_single_word(orthographic_word_input)
    local current_word_phonetic = toNFC(orthographic_word_input); 
    if not current_word_phonetic or current_word_phonetic == "" then return "" end
    
    if lexical_exceptions_connacht[current_word_phonetic] then
        if STAGE_DEBUG_ENABLED["LexicalLookup"] then print("  LexicalLookup: Found '", current_word_phonetic, "' -> [", lexical_exceptions_connacht[current_word_phonetic], "]") end
        return lexical_exceptions_connacht[current_word_phonetic]
    end

    local original_ortho_for_context = ""; local ortho_map = {}
    local function build_initial_ortho_map(word_str) local new_map = {}; for k=1, ulen(word_str) do table.insert(new_map, {phon_s=k, phon_e=k, ortho_s=k, ortho_e=k}) end; return new_map end
    
    local stages = {
        {name = "PreProcess", rules = irishPhonetics.rules_stage1_preprocess, mode = "single_pass_priority_match"}, 
        {name = "MarkDigraphsAndVocalisationTriggers", rules = irishPhonetics.rules_stage2_mark_digraphs_and_vocalisation_triggers, updates_map_from_original_with_priority = true},
        {name = "Stage2_5_MarkSuffixes", rules = irishPhonetics.rules_stage2_5_mark_suffixes, updates_map_from_original_with_priority = true},
        {name = "ConsonantResolution", rules = irishPhonetics.rules_stage3_consonant_resolution, use_original_context_for_rules = true, is_procedural_stage = true, func = function(phon_word_in_stage3, o_context_str_stage3, current_ortho_map_stage3) if STAGE_DEBUG_ENABLED["ConsonantResolution"] then print("  ConsonantResolution START (Proc): In=", phon_word_in_stage3) end; local metathesis_phon_parts = {}; local meta_scan_offset = 1; while meta_scan_offset <= ulen(phon_word_in_stage3) do local stress_marker = ""; local current_phon_char_for_meta = usub(phon_word_in_stage3, meta_scan_offset, meta_scan_offset); if current_phon_char_for_meta == toNFC("ˈ") then stress_marker = toNFC("ˈ"); meta_scan_offset = meta_scan_offset + 1; if meta_scan_offset > ulen(phon_word_in_stage3) then table.insert(metathesis_phon_parts, stress_marker); break end; current_phon_char_for_meta = usub(phon_word_in_stage3, meta_scan_offset, meta_scan_offset) end; local c_phon_base = current_phon_char_for_meta; local c_is_palatal = false; local n_phon_base = ""; local n_is_palatal = false; local advance_for_c = 1; if usub(phon_word_in_stage3, meta_scan_offset + 1, meta_scan_offset + 1) == toNFC("'") then c_is_palatal = true; advance_for_c = 2 end; local n_phon_start_idx_in_phon = meta_scan_offset + advance_for_c; if n_phon_start_idx_in_phon <= ulen(phon_word_in_stage3) then n_phon_base = usub(phon_word_in_stage3, n_phon_start_idx_in_phon, n_phon_start_idx_in_phon); if usub(phon_word_in_stage3, n_phon_start_idx_in_phon + 1, n_phon_start_idx_in_phon + 1) == toNFC("'") then n_is_palatal = true end end; local c_is_k_type = (c_phon_base == toNFC("k") or c_phon_base == toNFC("c")); local c_is_g_type = (c_phon_base == toNFC("g")); if ((c_is_k_type) and n_phon_base == toNFC("n")) or (c_is_g_type and n_phon_base == toNFC("n")) then if (meta_scan_offset == 1 and stress_marker == "") or (meta_scan_offset == (1 + ulen(stress_marker)) and stress_marker ~= "") then debug_print_minimal("ConsonantResolution", "Metathesis candidate found: ", stress_marker..c_phon_base..(c_is_palatal and "'" or "")..n_phon_base..(n_is_palatal and "'" or "")); local n_phon_end_idx_in_phon = n_phon_start_idx_in_phon + (n_is_palatal and 1 or 0); local ortho_s_n, ortho_len_n = get_original_indices_from_map(n_phon_start_idx_in_phon, n_phon_end_idx_in_phon, current_ortho_map_stage3); local quality_for_r; local n_ortho_actual_start_idx = ortho_s_n; local n_ortho_actual_end_idx = ortho_s_n + ortho_len_n -1; quality_for_r = determine_consonant_quality_ortho(o_context_str_stage3, n_ortho_actual_start_idx, n_ortho_actual_end_idx); table.insert(metathesis_phon_parts, stress_marker .. c_phon_base .. (c_is_palatal and toNFC("'") or "")); if quality_for_r == "palatal" then table.insert(metathesis_phon_parts, toNFC("r'")) else table.insert(metathesis_phon_parts, toNFC("r")) end; meta_scan_offset = n_phon_end_idx_in_phon + 1 else table.insert(metathesis_phon_parts, stress_marker .. usub(phon_word_in_stage3, meta_scan_offset, meta_scan_offset + advance_for_c -1)); meta_scan_offset = meta_scan_offset + advance_for_c end else table.insert(metathesis_phon_parts, stress_marker .. usub(phon_word_in_stage3, meta_scan_offset, meta_scan_offset)); meta_scan_offset = meta_scan_offset + 1 end end; phon_word_in_stage3 = table.concat(metathesis_phon_parts); local multi_char_rules_stage3 = {}; local single_char_rule_data_stage3; for _, rule_data_loop in ipairs(irishPhonetics.rules_stage3_consonant_resolution) do if rule_data_loop.pattern ~= toNFC("([bcdfghkmprst])") then table.insert(multi_char_rules_stage3, rule_data_loop) else single_char_rule_data_stage3 = rule_data_loop end end; local pass1_phonetic_parts_stage3 = {}; local pass1_scan_offset_stage3 = 1; while pass1_scan_offset_stage3 <= ulen(phon_word_in_stage3) do local best_match_s_this_iter, best_match_e_this_iter, best_rule_this_iter_idx; local best_captures_this_iter = {}; local current_best_match_length_this_iter = -1; for rule_idx_loop, rule_data_loop in ipairs(multi_char_rules_stage3) do local s, e, cap1, cap2, cap3, cap4; s, e, cap1, cap2, cap3, cap4 = ufind(phon_word_in_stage3, rule_data_loop.pattern, pass1_scan_offset_stage3); if s then local current_match_len_loop = e - s + 1; if not best_match_s_this_iter or s < best_match_s_this_iter or (s == best_match_s_this_iter and current_match_len_loop > current_best_match_length_this_iter) then best_match_s_this_iter = s; best_match_e_this_iter = e; best_rule_this_iter_idx = rule_idx_loop; current_best_match_length_this_iter = current_match_len_loop; best_captures_this_iter = {cap1,cap2,cap3,cap4} end end end; if best_rule_this_iter_idx then if best_match_s_this_iter > pass1_scan_offset_stage3 then table.insert(pass1_phonetic_parts_stage3, usub(phon_word_in_stage3, pass1_scan_offset_stage3, best_match_s_this_iter - 1)) end; local rule = multi_char_rules_stage3[best_rule_this_iter_idx]; local full_match_segment = usub(phon_word_in_stage3, best_match_s_this_iter, best_match_e_this_iter); local original_ortho_s, original_ortho_len = get_original_indices_from_map(best_match_s_this_iter, best_match_e_this_iter, current_ortho_map_stage3); local original_match_info = {ortho_s = original_ortho_s, ortho_e = original_ortho_s + original_ortho_len - 1}; local actual_captures = {}; if best_captures_this_iter then for _,c_val in ipairs(best_captures_this_iter) do if c_val~=nil then table.insert(actual_captures, c_val) end end end; local replacement_text; if type(rule.replacement) == "string" then replacement_text = rule.replacement elseif type(rule.replacement) == "function" then replacement_text = rule.replacement(full_match_segment, o_context_str_stage3, original_match_info, table.unpack(actual_captures)) end; replacement_text = replacement_text or ""; table.insert(pass1_phonetic_parts_stage3, replacement_text); pass1_scan_offset_stage3 = best_match_e_this_iter + 1 else if pass1_scan_offset_stage3 <= ulen(phon_word_in_stage3) then table.insert(pass1_phonetic_parts_stage3, usub(phon_word_in_stage3, pass1_scan_offset_stage3, pass1_scan_offset_stage3)); pass1_scan_offset_stage3 = pass1_scan_offset_stage3 + 1 else break end end end; phon_word_in_stage3 = table.concat(pass1_phonetic_parts_stage3); if single_char_rule_data_stage3 then local pass2_phonetic_parts_stage3 = {}; local pass2_scan_offset_stage3 = 1; while pass2_scan_offset_stage3 <= ulen(phon_word_in_stage3) do local char_to_check = usub(phon_word_in_stage3, pass2_scan_offset_stage3, pass2_scan_offset_stage3); if char_to_check:match("^[bcdfghkmprst]$") or umatch(char_to_check, "^MKR_[LN]_SNG_BRD$") or umatch(char_to_check, "^MKR_[LN]_STR_PAL$") or umatch(char_to_check, "^MKR_[LN]_STR_BRD$") then local original_ortho_s, original_ortho_len = get_original_indices_from_map(pass2_scan_offset_stage3, pass2_scan_offset_stage3, current_ortho_map_stage3); local original_match_info = {ortho_s = original_ortho_s, ortho_e = original_ortho_s + original_ortho_len -1}; local replacement_text = single_char_rule_data_stage3.replacement(char_to_check, o_context_str_stage3, original_match_info); replacement_text = replacement_text or char_to_check; table.insert(pass2_phonetic_parts_stage3, replacement_text) else table.insert(pass2_phonetic_parts_stage3, char_to_check) end; pass2_scan_offset_stage3 = pass2_scan_offset_stage3 + 1 end; phon_word_in_stage3 = table.concat(pass2_phonetic_parts_stage3) end; if STAGE_DEBUG_ENABLED["ConsonantResolution"] then print("  ConsonantResolution END (Proc): Out=", phon_word_in_stage3) end; return phon_word_in_stage3 end},
        {name = "Stage4_0_SpecificOrthoToTempMarker", rules = irishPhonetics.rules_stage4_0_specific_ortho_to_temp_marker, mode = "single_pass_priority_match", use_original_context_for_rules = true}, 
        {name = "Stage4_0_1_Resolve_CH_Marker", rules = irishPhonetics.rules_stage4_0_1_resolve_ch_marker, mode = "single_pass_priority_match", use_original_context_for_rules = true}, 
        {name = "Stage4_1_VocmarkToTempMarker", rules = irishPhonetics.rules_stage4_1_vocmarkToTempMarker, mode = "single_pass_priority_match"}, 
        {name = "Stage4_2_LongVowelsOrthoToTempMarker", rules = irishPhonetics.rules_stage4_2_long_vowels_ortho_to_temp_marker, mode = "single_pass_priority_match"}, 
        {name = "Stage4_3_DiphthongsOrthoToTempMarker", rules = irishPhonetics.rules_stage4_3_diphthongs_ortho_to_temp_marker, mode = "single_pass_priority_match", use_original_context_for_rules = true}, 
        {name = "Stage4_4_ResolveTempVowelMarkers", rules = irishPhonetics.rules_stage4_4_resolve_temp_vowel_markers, mode = "iterative_gsub"}, 
        {name = "Stage4_4_1_VocalizeLenitedFricatives", rules = irishPhonetics.rules_stage4_4_1_vocalize_lenited_fricatives, mode = "iterative_gsub", needs_full_context_in_func_repl = true},
        {name = "Stage4_5_ContextualAllophonyOnPhonetic", is_procedural_stage = true, func = function(phon_word) if STAGE_DEBUG_ENABLED["Stage4_5_ContextualAllophonyOnPhonetic"] then print("  Stage4_5_ContextualAllophonyOnPhonetic START: In=", phon_word) end; phon_word = apply_rules_to_string_generic(phon_word, placeholder_creation_rules_stage4_5, "Stage4_5_ContextualAllophonyOnPhonetic", "single_pass_priority_match", false); phon_word = apply_rules_to_string_generic(phon_word, core_allophony_rules_for_stage4_5, "Stage4_5_ContextualAllophonyOnPhonetic", "iterative_gsub", false); phon_word = apply_rules_to_string_generic(phon_word, placeholder_restoration_rules_stage4_5, "Stage4_5_ContextualAllophonyOnPhonetic", "single_pass_priority_match", false); phon_word = apply_rules_to_string_generic(phon_word, {connacht_au_to_schwa_u_shift_rule_stage4_5}, "Stage4_5_ContextualAllophonyOnPhonetic", "single_pass_priority_match", false); phon_word = apply_rules_to_string_generic(phon_word, {temp_conn_au_to_final_au_rule_stage4_5}, "Stage4_5_ContextualAllophonyOnPhonetic", "single_pass_priority_match", false); if STAGE_DEBUG_ENABLED["Stage4_5_ContextualAllophonyOnPhonetic"] then print("  Stage4_5_ContextualAllophonyOnPhonetic END: Out=", phon_word) end; return phon_word end},
        {name = "Stage4_5_1_DisyllabicShortLongRaising", is_procedural_stage = true, func = function(phon_word) return process_phonetic_units_procedurally(phon_word, "Stage4_5_1_DisyllabicShortLongRaising", process_disyllabic_raising_on_units) end},
        {name = "Nasalization", is_procedural_stage = true, func = function(phon_word) return process_phonetic_units_procedurally(phon_word, "Nasalization", process_nasalization_on_units) end}, 
        {name = "Stage4_6_UnstressedVowelReduction_Procedural", is_procedural_stage = true, func = function(phon_word) 
            if STAGE_DEBUG_ENABLED["Stage4_6_UnstressedVowelReduction_Procedural"] then print("  Stage4_6_UnstressedVowelReduction_Procedural START (Outer): In=", phon_word) end
            local parsed_units_for_mono_check = parse_phonetic_string_to_units_for_epenthesis(phon_word)
            if is_likely_monosyllable_phonetic_revised(phon_word, parsed_units_for_mono_check) then debug_print_minimal("Stage4_6_UnstressedVowelReduction_Procedural", "Word '", phon_word, "' is monosyllabic, SKIPPING."); if STAGE_DEBUG_ENABLED["Stage4_6_UnstressedVowelReduction_Procedural"] then print("  Stage4_6_UnstressedVowelReduction_Procedural END (monosyllable): Out=", phon_word) end; return phon_word end
            phon_word = apply_rules_to_string_generic(phon_word, irishPhonetics.rules_stage4_6_unstressed_vowel_reduction_specific_finals, "Stage4_6_UnstressedVowelReduction_Procedural", "iterative_gsub")
            phon_word = process_phonetic_units_procedurally(phon_word, "Stage4_6_UnstressedVowelReduction_Procedural", process_unstressed_reduction_on_units)
            if STAGE_DEBUG_ENABLED["Stage4_6_UnstressedVowelReduction_Procedural"] then print("  Stage4_6_UnstressedVowelReduction_Procedural END (Outer): Out=", phon_word) end
            return phon_word
        end},
        {name = "EpenthesisAndStrongSonorants", is_procedural_stage = true, func = function(phon_word_in_stage5, o_context_str_stage5, current_ortho_map_stage5) 
            if STAGE_DEBUG_ENABLED["EpenthesisAndStrongSonorants"] then print("  EpenthesisAndStrongSonorants START (Proc): In=", phon_word_in_stage5) end
            phon_word_in_stage5 = process_phonetic_units_procedurally(phon_word_in_stage5, "EpenthesisAndStrongSonorants_EpenthesisPart", process_epenthesis_on_units, {original_ortho_for_context = o_context_str_stage5, current_ortho_map = current_ortho_map_stage5})
            debug_print_minimal("EpenthesisAndStrongSonorants", "After procedural epenthesis: ", phon_word_in_stage5)
            phon_word_in_stage5 = apply_rules_to_string_generic(phon_word_in_stage5, irishPhonetics.rules_stage5_strong_sonorants_only, "EpenthesisAndStrongSonorants", "single_pass_priority_match", true, o_context_str_stage5, current_ortho_map_stage5)
            debug_print_minimal("EpenthesisAndStrongSonorants", "After strong sonorant rules: ", phon_word_in_stage5)
            if STAGE_DEBUG_ENABLED["EpenthesisAndStrongSonorants"] then print("  EpenthesisAndStrongSonorants END (Proc): Out=", phon_word_in_stage5) end
            return phon_word_in_stage5 
        end},
        {name = "Diacritics", rules = irishPhonetics.rules_stage6_diacritics, mode = "iterative_gsub"}, 
        {name = "FinalCleanup", rules = irishPhonetics.rules_stage7_final_cleanup, mode = "iterative_gsub"},
    }

    for i, stage_data in ipairs(stages) do
        local stage_name = stage_data.name
        if STAGE_DEBUG_ENABLED[stage_name] and not stage_data.is_procedural_stage then print("  " .. stage_name .. " START: In=", current_word_phonetic) end

        if stage_data.is_procedural_stage and type(stage_data.func) == "function" then
            current_word_phonetic = stage_data.func(current_word_phonetic, original_ortho_for_context, ortho_map)
        elseif stage_data.name == "PreProcess" then
            current_word_phonetic = apply_rules_to_string_generic(current_word_phonetic, stage_data.rules, stage_name, stage_data.mode, false)
            original_ortho_for_context = current_word_phonetic
            ortho_map = build_initial_ortho_map(current_word_phonetic)
        elseif stage_data.updates_map_from_original_with_priority then
            local temp_phonetic_string_build, temp_new_map, original_cursor, current_phonetic_len_accumulator = {}, {}, 1, 0
            while original_cursor <= ulen(original_ortho_for_context) do
                local matched_this_pass_at_cursor = false
                for rule_idx, rule in ipairs(stage_data.rules) do
                    local s_match_ortho, e_match_ortho, cap1, cap2, cap3, cap4 = ufind(original_ortho_for_context, rule.pattern, original_cursor)
                    if s_match_ortho and s_match_ortho == original_cursor then
                        local current_ortho_match_len = rule.ortho_len_func and rule.ortho_len_func(usub(original_ortho_for_context, s_match_ortho, e_match_ortho), cap1, cap2, cap3, cap4) or rule.ortho_len or (e_match_ortho - s_match_ortho + 1)
                        if rule.ortho_len and current_ortho_match_len > (e_match_ortho - s_match_ortho + 1) then goto continue_map_update_rule_loop_compacted_37h end
                        local full_match_ortho_segment_for_replacement = usub(original_ortho_for_context, s_match_ortho, s_match_ortho + current_ortho_match_len -1)
                        local replacement_text = type(rule.replacement) == "string" and rule.replacement or type(rule.replacement) == "function" and rule.replacement(full_match_ortho_segment_for_replacement, cap1, cap2, cap3, cap4) or "" 
                        table.insert(temp_phonetic_string_build, replacement_text)
                        table.insert(temp_new_map, {phon_s = current_phonetic_len_accumulator + 1, phon_e = current_phonetic_len_accumulator + ulen(replacement_text), ortho_s = original_cursor, ortho_e = original_cursor + current_ortho_match_len - 1})
                        current_phonetic_len_accumulator = current_phonetic_len_accumulator + ulen(replacement_text)
                        original_cursor = original_cursor + current_ortho_match_len
                        matched_this_pass_at_cursor = true; goto restart_map_update_rule_scan_compacted_37h
                    end; ::continue_map_update_rule_loop_compacted_37h::
                end; ::restart_map_update_rule_scan_compacted_37h::
                if not matched_this_pass_at_cursor then if original_cursor <= ulen(original_ortho_for_context) then local char = usub(original_ortho_for_context, original_cursor, original_cursor); table.insert(temp_phonetic_string_build, char); table.insert(temp_new_map, {phon_s = current_phonetic_len_accumulator + 1, phon_e = current_phonetic_len_accumulator + 1, ortho_s = original_cursor, ortho_e = original_cursor}); current_phonetic_len_accumulator = current_phonetic_len_accumulator + 1; original_cursor = original_cursor + 1 else break end end
            end
            current_word_phonetic = table.concat(temp_phonetic_string_build); ortho_map = temp_new_map
        elseif stage_data.rules then
            current_word_phonetic = apply_rules_to_string_generic(current_word_phonetic, stage_data.rules, stage_name, stage_data.mode or "single_pass_priority_match", stage_data.use_original_context_for_rules, original_ortho_for_context, ortho_map, current_word_phonetic)
        end
        
        if STAGE_DEBUG_ENABLED[stage_name] and not stage_data.is_procedural_stage then print("  " .. stage_name .. " END: Out=", current_word_phonetic) end
        if stage_name ~= "PreProcess" and STAGE_DEBUG_ENABLED[stage_name] then print(string.format("Af. %s: [%s]", stage_name, current_word_phonetic)) end
    end
    return current_word_phonetic
end

function irishPhonetics.transcribe(orthographic_phrase)
    local words = {}
    local current_pos = 1
    while current_pos <= ulen(orthographic_phrase) do
        local next_space_s, next_space_e = ufind(orthographic_phrase, "%s+", current_pos)
        if next_space_s then
            if next_space_s > current_pos then 
                table.insert(words, irishPhonetics.transcribe_single_word(usub(orthographic_phrase, current_pos, next_space_s - 1)))
            end
            table.insert(words, usub(orthographic_phrase, next_space_s, next_space_e)) 
            current_pos = next_space_e + 1
        else 
            table.insert(words, irishPhonetics.transcribe_single_word(usub(orthographic_phrase, current_pos)))
            break
        end
    end
    return table.concat(words, "")
end


local RUN_TESTS = false
local CSV_FILE_NAME = "wiki_sample_for_llm.csv" 

if RUN_TESTS then
        -- targets 
    --     [[['ceann', 'Galway', 'cɑːn̪ˠ'], ['ceann', 'Mayo', 'can̪ˠ'], ['ceann', 'Munster', 'cɑun̪ˠ'], ['ceann', 'Ulster', 'cɨ̞n̪ˠ']], [['am', '', 'əmˠ'], ['am' 
    -- , 'Galway', 'ɑːmˠ'], ['am', 'Galway; Ulster; Mayo', 'amˠ'], ['am', 'Munster', 'aumˠ']], [['fonn', 'Galway; Cork', 'fˠuːn̪ˠ'], ['fonn', 'Kerry', 'fˠɑun
    -- lway', 't̪ˠɾˠuːmˠ'], ['trom', 'Mayo', 't̪ˠɾˠʊmˠ'], ['trom', 'Munster', 't̪ˠɾˠoumˠ, t̪ˠɾˠɑumˠ'], ['trom', 'Ulster', 't̪ˠɾˠʌmˠ']], [['corr', 'Cois-Fharra
    -- aige', 'kəuɾˠ'], ['corr', 'Ulster', 'kɔɾˠ']], [['bord', '', 'bˠoːɾˠd̪ˠ'], ['bord', 'Aran', 'bˠɑuɾˠd̪ˠ'], ['bord', 'Connemara', 'bˠəuɾˠd̪ˠ']], [['im', 
    -- '', 'imˠ'], ['im', 'Galway; Kerry; Cork', 'iːmʲ'], ['im', 'Mayo', 'imʲ'], ['im', 'Ulster', 'ɨmʲ'], ['im', 'Waterford', 'aimʲ']], [['roinnt', 'Galway', 'ɾˠiːn̠ʲtʲ'], ['roinnt', 'Mayo; Ulster', 'ɾˠɪn̠ʲtʲ'], ['roinnt', 'Munster', 'ɾˠəɪn̠ʲtʲ']], [['caill', 'Galway', 'kɑːl̠ʲ'], ['caill', 'Mayo; Ulster', ay','kal̠ʲ'], ['caill', 'Munster', 'kailʲ']], [['coill', 'Connacht', 'kail̠ʲ, kɞl̠ʲ'], ['coill', 'Galway; Connacht', 'koil̠ʲ'], ['coill', 'Mayo; Connacht'
    -- , 'kel̠ʲ'], ['coill', 'Kerry; Munster; Cork', 'kiːlʲ'], ['coill', 'Waterford; Munster', 'kəilʲ'], ['coill', 'Ulster', 'kɪl̠ʲ']], [['cill', 'Galway', '
    -- ciːl̠ʲ'], ['cill', 'Kerry', 'ciːlʲ'], ['cill', 'Mayo; Ulster', 'cɪl̠ʲ']], [['nimhe', 'Connacht', 'ˈn̠ʲivʲə'], ['nimhe', 'Munster', 'nʲĩː'], ['nimhe', '
    -- 'Ulster', 'ˈn̠ʲɨ̃vʲə']], [], [['úsáideoirí', 'Connacht', 'ˈuːsˠɑːdʲoːɾʲiː'], ['úsáideoirí', 'Munster', 'uːˈsˠɑːdʲoːɾʲiː'], ['úsáideoirí', 'Ulster', 'ˈ
    -- uːsˠædʲɔɾʲi']], [['bainne', 'Connacht', 'ˈbˠan̠ʲə'], ['bainne', 'Ulster; Connacht', 'ˈbˠæn̠ʲə'], ['bainne', 'Waterford; Cork', 'ˈbˠaɲə'], ['bainne', '
    -- Kerry', 'ˈbˠɑnʲə']], [['seanchas', '', 'ˈʃanˠəxəsˠ, ˈʃan̪ˠəxəsˠ'], ['seanchas', 'Ulster', 'ˈʃanˠəxəsˠk, ˈʃan̪ˠəxəsˠk']], [['fear', '', 'fʲaɾˠ'], ['fea
    -- r', 'Cois-Fharraige', 'fʲæɾˠ']], [['leaba', 'Cois-Fharraige', 'ˈl̠ʲæːbˠə'], ['leaba', 'Munster', 'ˈlʲabˠɪɟ'], ['leaba', 'Ulster', 'ˈl̠ʲabˠiː']], [['te
    -- oiric chinnteoireachta', 'Connacht', 'ˌtʲoːɾʲəc ˈçɪn̠ʲtʲoːɾʲəxt̪ˠ']], [['Céadaoin an Luaithrigh', 'Ulster', 'ˌcɛd̪ˠinʲ ə ˈl̪ˠuəhɾʲi']], [['níl a bhuíote
    -- chas oraibh', 'Cois-Fharraige', 'ˈn̠ʲiːlʲ ə ˈwiəxəsˠ ɔɾˠiː']]]
    local words_to_test_focused = {
        "ceann", "am", "fonn", "poll", "trom", "corr", "bord", 
        "im", "roinnt", "caill", "coill", "cill", 
        "nimhe", "suidhe", 
        "úsáideoirí", 
        "bainne", "seanchas", 
        "fear", "leaba", 
        "teoiric chinnteoireachta" , "Céadaoin an Luaithrigh", "níl a bhuíochas oraibh"
    }
    original_print_func("\n--- Running Focused Test Set for Connacht (Iteration 37N - CSV Targets) ---")
    if debug_file then debug_file:write("\n--- Running Focused Test Set for Connacht (Iteration 37N - CSV Targets) ---\n") end

    STAGE_DEBUG_ENABLED.Parser = false; STAGE_DEBUG_ENABLED.ParserSetup = false

    for _, word_or_phrase in ipairs(words_to_test_focused) do
        local original = word_or_phrase
        original_print_func("\n--- Transcribing:", original, "---")
        if debug_file then debug_file:write(string.format("\n--- Transcribing: %s ---\n", original)) end
        local transcribed = irishPhonetics.transcribe(original)
        original_print_func(string.format("%-30s -> [%s]", original, transcribed))
        if debug_file then debug_file:write(string.format("%-30s -> [%s]\n", original, transcribed)) end
    end
end




print(irishPhonetics.transcribe(toNFC(arg[1])))
return irishPhonetics
