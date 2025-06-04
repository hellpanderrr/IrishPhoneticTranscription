
-- irish_phonetics_37J_planning.lua

local ustring_module_path = "ustring.ustring"
local status, ustring_lib = pcall(require, ustring_module_path)

if not status then
    local early_print = print
    early_print("ERROR: Failed to load ustring module from path: " .. ustring_module_path)
    error("ustring module not found.")
end

local ulower, usub, ulen, ufind, umatch, ugsub, ugmatch, toNFC = 
    ustring_lib.lower, ustring_lib.sub, ustring_lib.len, ustring_lib.find, 
    ustring_lib.match, ustring_lib.gsub, ustring_lib.gmatch, ustring_lib.toNFC

-- Debug output file setup
local debug_file_path = "irish_debug_37J_planning.txt"
local debug_file = io.open(debug_file_path, "w")
if debug_file then debug_file:write("\239\187\191") else original_print("WARN: Could not open debug_file " .. debug_file_path) end
local original_print_func = print

-- Debug Flags
local MINIMAL_DEBUG_ENABLED = false
local STAGE_DEBUG_ENABLED = {
    PreProcess = true, MarkDigraphsAndVocalisationTriggers = true, ConsonantResolution = true,
    Stage4_0_SpecificOrthoToTempMarker = true, Stage4_0_1_Resolve_CH_Marker = true, Stage4_1_VocmarkToTempMarker = true,
    Stage4_2_LongVowelsOrthoToTempMarker = true, Stage4_3_DiphthongsOrthoToTempMarker = true,
    Stage4_4_ResolveTempVowelMarkers = true, Stage4_4_1_VocalizeLenitedFricatives = true,
    Stage4_5_ContextualAllophonyOnPhonetic = true, Stage4_5_1_DisyllabicShortLongRaising = true,
    Nasalization = true, Stage4_6_UnstressedVowelReduction_Procedural = true,
    EpenthesisAndStrongSonorants = true, Diacritics = true, FinalCleanup = true,
    Parser = false, ParserSetup = false,
}

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
local SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE = "([" .. ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR .. "]~?ː?)"
local DIPHTHONG_WITH_OPT_NASAL_CAPTURE = "(iə~?|ua~?|ai~?|ei~?|oi~?|ui~?|ɑu~?|ou~?|əu~?|eiə~?)"
local PHONETIC_VOWEL_NUCLEUS_PATTERN = "(" .. DIPHTHONG_WITH_OPT_NASAL_CAPTURE .. ")|(" .. SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE .. ")"
local SHORT_VOWEL_CAPTURE_FOR_EPENTHESIS = "([" .. ANY_SHORT_VOWEL_PHONETIC_CHARS_STR .. "]~?)"
local CPART_CAPTURE_STRICT = "(" .. CONSONANT_CLASS_NO_CAPTURE .. "'?)"
local VOWEL_A_CLASS_CAPTURE_STRICT = "([aæɑ]~?)"
local VOWEL_E_I_CLASS_CAPTURE_STRICT = "([eɛiɪ]~?)"
local VOWEL_O_U_CLASS_CAPTURE_STRICT = "([oɔʊʌ]~?)"
local DIPHTHONG_AI_CAPTURE_STRICT = "(ai~?)"

-- Updated capture for strong sonorants to include new markers
local STRONG_BROAD_LNM_CAPTURE = "(N_STRONG_BROAD|L_STRONG_BROAD|N_SINGLE_BROAD|L_SINGLE_BROAD|[mM])"
local STRONG_PAL_LNM_CAPTURE = "(N_STRONG_PAL|L_STRONG_PAL|[nN]'|[lL]'|[mM]')" -- Includes existing palatal markers for now
local STRONG_BROAD_R_CAPTURE = "([Rr])"
local STRONG_PAL_R_CAPTURE = "([Rr]')"


ALL_PHONETIC_CONSONANTS_INTERMEDIATE_PRIORITY = {
    toNFC("N_STRONG_PAL"), toNFC("N_STRONG_BROAD"), toNFC("L_STRONG_PAL"), toNFC("L_STRONG_BROAD"), 
    toNFC("N_SINGLE_BROAD"), toNFC("L_SINGLE_BROAD"), 
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
        if v_char_or_group == "ea" or v_char_or_group == "eo" or v_char_or_group == "ia" or v_char_or_group == "iu" or v_char_or_group == "ei" or v_char_or_group == "eu" then -- Added eu
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
    if current_ortho_cons_seq == "s" and ortho_cons_char_start_idx > 1 and usub(original_ortho_word, ortho_cons_char_start_idx-1, ortho_cons_char_start_idx-1) == "ú" then
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
    if options.can_be_w and quality == "nonpalatal" then local next_v_char_idx = original_match_info_tbl.ortho_e + 1; if next_v_char_idx <= ulen(o_context_str) then local next_char = usub(o_context_str, next_v_char_idx, next_v_char_idx); if umatch(next_char, BROAD_VOWELS_ORTHO_PATTERN) then local prev_char_idx = original_match_info_tbl.ortho_s - 1; if prev_char_idx >= 1 then local prev_char = usub(o_context_str, prev_char_idx, prev_char_idx); if not umatch(prev_char, "[rlcsrlnLNRM]'?$") then return "w" end else return "w" end end end end
    return quality == 'palatal' and base_phoneme_palatal or base_phoneme_nonpalatal
end

irishPhonetics.rules_stage1_preprocess = { { pattern = "^%s*(.-)%s*$", replacement = function(captured_string) if captured_string then return ulower(captured_string) else return "" end end }, { pattern = "%s+", replacement = " " }, { pattern = "�", replacement = "" }, { pattern = "^([^ˈ%-].*)$", replacement = function(word_part_to_stress) debug_print_minimal("PreProcess", "Word for stress: '", word_part_to_stress, "'"); if not word_part_to_stress or word_part_to_stress == "" then return "" end; for _, prefix in ipairs(UNSTRESSED_PREFIXES_ORTHO) do local prefix_pattern_for_match = ugsub(prefix, "%-", ""); if usub(word_part_to_stress, 1, ulen(prefix_pattern_for_match)) == prefix_pattern_for_match then local root = usub(word_part_to_stress, ulen(prefix_pattern_for_match) + 1); debug_print_minimal("PreProcess", "Checking prefix '", prefix_pattern_for_match, "' against '", word_part_to_stress, "'. Root: '", root, "'"); if root == "" then return word_part_to_stress end; if umatch(root, "^" .. ALL_VOWELS_ORTHO_PATTERN) then return prefix_pattern_for_match .. "ˈ" .. root elseif umatch(root, "^(" .. CONSONANTS_ORTHO_CHARS_STR .. "+)(" .. ALL_VOWELS_ORTHO_PATTERN .. ")") then return prefix_pattern_for_match .. "ˈ" .. root else return word_part_to_stress end end end; debug_print_minimal("PreProcess", "Attempting direct stress on '", word_part_to_stress, "'. Vowel match: ", tostring(umatch(word_part_to_stress, "^" .. ALL_VOWELS_ORTHO_PATTERN)), ". CV match: ", tostring(umatch(word_part_to_stress, "^(" .. CONSONANTS_ORTHO_CHARS_STR .. "+)(" .. ALL_VOWELS_ORTHO_PATTERN .. ")"))); if umatch(word_part_to_stress, "^" .. ALL_VOWELS_ORTHO_PATTERN) then return "ˈ" .. word_part_to_stress elseif umatch(word_part_to_stress, "^(" .. CONSONANTS_ORTHO_CHARS_STR .. "+)(" .. ALL_VOWELS_ORTHO_PATTERN .. ")") then return "ˈ" .. word_part_to_stress end; return word_part_to_stress end },}
irishPhonetics.rules_stage2_mark_digraphs_and_vocalisation_triggers = {
    { pattern = "eacht", replacement = "&EACHT_BROAD_FIX_TAG&", ortho_len = 5 },
    { pattern = "eoi", replacement = "&EOI_TRIGRAPH_O_LONG_TAG&", ortho_len = 3 }, { pattern = "eói", replacement = "&EOI_TRIGRAPH_O_LONG_ACUTE_TAG&", ortho_len = 3 },
    { pattern = "bhf", replacement = "_URUF_", ortho_len = 3 }, { pattern = "bp", replacement = "_URUP_", ortho_len = 2 }, { pattern = "dt", replacement = "_URUT_", ortho_len = 2 }, { pattern = "gc", replacement = "_URUC_", ortho_len = 2 }, { pattern = "mb", replacement = "_URUM_", ortho_len = 2 }, { pattern = "nd", replacement = "_URUN_", ortho_len = 2 }, { pattern = "ng", replacement = "_URUG_", ortho_len = 2 },
    { pattern = "eidh(#?)$", replacement = function(m,c1) return "&EIDH_CONN_AI_TAG&" .. (c1 or "") end, ortho_len = 4 },
    { pattern = "aghaidh(#?)$", replacement = function(m,c1) return "&AGHAIDH_VOC_TARGET_TAG&" .. (c1 or "") end, ortho_len = 7 }, { pattern = "ubh(#?)$", replacement = function(m,c1) return "&U_VOC_B_FINAL_TAG&" .. (c1 or "") end, ortho_len = 3}, { pattern = "ámh(#?)$", replacement = function(m,c1) return "&A_ACUTE_LONG_VOC_M_FINAL_TAG&" .. (c1 or "") end, ortho_len = 3}, { pattern = "amh(r)", replacement = function(m,c1) return "&A_VOC_M_MEDIAL_R_TAG&" .. c1 end, ortho_len = 3}, { pattern = "eabh(r)", replacement = function(m,c1) return "&EA_VOC_B_MEDIAL_R_TAG&" .. c1 end, ortho_len = 4}, { pattern = "adh(#?)$", replacement = function(m,c1) return "&A_VOC_D_FINAL_TAG&" .. (c1 or "") end, ortho_len = 3}, { pattern = "eadh(#?)$", replacement = function(m,c1) return "&EA_VOC_D_FINAL_TAG&" .. (c1 or "") end, ortho_len = 4}, { pattern = "agh(#?)$", replacement = function(m,c1) return "&A_VOC_G_FINAL_TAG&" .. (c1 or "") end, ortho_len = 3}, { pattern = "ogh(#?)$", replacement = function(m,c1) return "&O_VOC_G_FINAL_TAG&" .. (c1 or "") end, ortho_len = 3}, { pattern = "obh(#?)$", replacement = function(m,c1) return "&O_VOC_B_FINAL_TAG&" .. (c1 or "") end, ortho_len = 3}, { pattern = "omh(#?)$", replacement = function(m,c1) return "&O_VOC_M_FINAL_TAG&" .. (c1 or "") end, ortho_len = 3}, { pattern = "ibh(#?)$", replacement = function(m,c1) return "&I_VOC_B_FINAL_TAG&" .. (c1 or "") end, ortho_len = 3}, { pattern = "imh(e#?)$", replacement = function(m,c1) return "&I_VOC_M_MEDIAL_E_FINAL_TAG&" .. (c1 or "") end, ortho_len = 4 }, { pattern = "imh(#?)$", replacement = function(m,c1) return "&I_VOC_M_FINAL_TAG&" .. (c1 or "") end, ortho_len = 3}, { pattern = "idh(e#?)$", replacement = function(m,c1) return "&I_VOC_D_MEDIAL_E_FINAL_TAG&" .. (c1 or "") end, ortho_len = 4 }, { pattern = "idh(#?)$", replacement = function(m,c1) return "&I_VOC_D_FINAL_TAG&" .. (c1 or "") end, ortho_len = 3}, { pattern = "uidh(e#?)$", replacement = function(m,c1) return "&UI_VOC_D_MEDIAL_E_FINAL_TAG&" .. (c1 or "") end, ortho_len = 5 }, { pattern = "uidh(#?)$", replacement = function(m,c1) return "&UI_VOC_D_FINAL_TAG&" .. (c1 or "") end, ortho_len = 4}, { pattern = "áth(#?)$", replacement = function(m,c1) return "&A_ACUTE_LONG_VOC_TH_SILENT_FINAL_TAG&" .. (c1 or "") end, ortho_len = 3}, { pattern = "aidh(#?)$", replacement = function(m,c1) return "&AIDH_FINAL_SCHWA_TAG&" .. (c1 or "") end, ortho_len = 4}, { pattern = "aigh(#?)$", replacement = function(m,c1) return "&AIGH_FINAL_SCHWA_TAG&" .. (c1 or "") end, ortho_len = 4},
    { pattern = "aoi", replacement = "&AOI_LONG_TAG&", ortho_len = 3 }, { pattern = "ao", replacement = "&AO_LONG_TAG&", ortho_len = 2 }, { pattern = "ói", replacement = "&OI_ACUTE_LONG_TAG&", ortho_len = 2 }, { pattern = "aí", replacement = "_A_I_ACUTE_LONG_TAG_", ortho_len = 2 },
    { pattern = "^fh", replacement = "_FH_INITIAL_LENITED_TAG_", ortho_len = 2 }, { pattern = "bh", replacement = "_BH_TAG_", ortho_len = 2 }, { pattern = "mh", replacement = "_MH_TAG_", ortho_len = 2 }, { pattern = "ch", replacement = "_CH_TAG_", ortho_len = 2 }, { pattern = "dh", replacement = "_DH_TAG_", ortho_len = 2 }, { pattern = "gh", replacement = "_GH_TAG_", ortho_len = 2 }, { pattern = "ph", replacement = "_PH_TAG_", ortho_len = 2 }, { pattern = "sh", replacement = "_SH_TAG_", ortho_len = 2 }, { pattern = "th", replacement = "_TH_TAG_", ortho_len = 2 },
    { pattern = "ll", replacement = "_LL_TAG_", ortho_len = 2 },   { pattern = "nn", replacement = "_NN_TAG_", ortho_len = 2 }, { pattern = "rr", replacement = "_RR_TAG_", ortho_len = 2 },   { pattern = "mm", replacement = "_MM_TAG_", ortho_len = 2 },
    { pattern = "(ˈ"..SHORT_VOWELS_ORTHO_SINGLE_STR..")l("..ALL_VOWELS_ORTHO_PATTERN..")", replacement = "%1l°%2", ortho_len_func = function(m,c1,c2) return ulen(c1) + 1 + ulen(c2) end}, { pattern = "(ˈ"..SHORT_VOWELS_ORTHO_SINGLE_STR..")n("..ALL_VOWELS_ORTHO_PATTERN..")", replacement = "%1n°%2", ortho_len_func = function(m,c1,c2) return ulen(c1) + 1 + ulen(c2) end},}
irishPhonetics.rules_stage3_consonant_resolution = {
    { pattern = "_FH_INITIAL_LENITED_TAG_", replacement = "h" }, { pattern = "_FH_SILENT_TAG_", replacement = "" }, { pattern = "_TH_TAG_", replacement = "h" }, { pattern = "_URUF_", replacement = "v" }, { pattern = "_URUP_", replacement = "b" }, { pattern = "_URUT_", replacement = "d" }, { pattern = "_URUC_", replacement = "g" }, { pattern = "_URUM_", replacement = "m" }, { pattern = "_URUN_", replacement = "n" }, { pattern = "_URUG_", replacement = "ŋ" }, { pattern = "_PH_TAG_", replacement = function(fm, ocs, omi) return resolve_lenited_consonant("f'", "f", fm, ocs, omi) end }, { pattern = "_SH_TAG_", replacement = function(fm, ocs, omi) if not omi or not omi.ortho_s or not omi.ortho_e then return "h" end; local next_v_start_ortho = omi.ortho_e + 1; local next_v_is_slender_flag = false; if next_v_start_ortho <= ulen(ocs) then if umatch(usub(ocs, next_v_start_ortho, next_v_start_ortho), SLENDER_VOWELS_ORTHO_PATTERN) then next_v_is_slender_flag = true end end; if umatch(ocs, "^[sS][eé][áa]n", omi.ortho_s -1 ) then return "h'" end; return next_v_is_slender_flag and "h'" or "h" end }, { pattern = "_FH_INTERNAL_TAG_", replacement = "" }, { pattern = "_BH_TAG_", replacement = function(fm, ocs, omi) return resolve_lenited_consonant("v'", "v", fm, ocs, omi, {can_be_w = true}) end }, { pattern = "_MH_TAG_", replacement = function(fm, ocs, omi) return resolve_lenited_consonant("v'", "v", fm, ocs, omi, {can_be_w = true}) end }, { pattern = "_DH_TAG_", replacement = function(fm, ocs, omi) return resolve_lenited_consonant("j", "ɣ", fm, ocs, omi) end }, { pattern = "_GH_TAG_", replacement = function(fm, ocs, omi) return resolve_lenited_consonant("j", "ɣ", fm, ocs, omi) end },
    { pattern = "_LL_TAG_", replacement = function(fm, ocs, omi) local quality = determine_consonant_quality_ortho(ocs, omi.ortho_s, omi.ortho_e); return quality == "palatal" and "L_STRONG_PAL" or "L_STRONG_BROAD" end },
    { pattern = "_NN_TAG_", replacement = function(fm, ocs, omi) local quality = determine_consonant_quality_ortho(ocs, omi.ortho_s, omi.ortho_e); debug_print_minimal("ConsonantResolution", "For _NN_TAG_ in '", ocs, "', determined quality: ", quality); return quality == "palatal" and "N_STRONG_PAL" or "N_STRONG_BROAD" end },
    { pattern = "_RR_TAG_", replacement = function(fm, ocs, omi) return resolve_lenited_consonant("R'", "R", fm, ocs, omi) end }, { pattern = "_MM_TAG_", replacement = function(fm, ocs, omi) return resolve_lenited_consonant("M'", "M", fm, ocs, omi) end },
    { pattern = "l°", replacement = "l_neutral_" }, { pattern = "n°", replacement = "n_neutral_" },
    { pattern = "([bcdfghkmprst])", replacement = function(c_capture, ocs, omi)
        if not c_capture then return "" end
        if c_capture == "l_neutral_" or c_capture == "n_neutral_" then return c_capture end
        local base = c_capture;
        if c_capture == "c" then base = "k" end
        if not omi or not omi.ortho_s or not omi.ortho_e or not ocs then return base == "s" and "s" or base end
        local quality = determine_consonant_quality_ortho(ocs, omi.ortho_s, omi.ortho_e);
        local is_truly_initial_in_ortho = (omi.ortho_s == 1);
        if omi.ortho_s == 2 and usub(ocs, 1, 1) == "ˈ" then is_truly_initial_in_ortho = true end
        
        if is_truly_initial_in_ortho and quality == "nonpalatal" then
            if base == "n" then return "N_SINGLE_BROAD"
            elseif base == "l" then return "L_SINGLE_BROAD"
            elseif not umatch(base, "^[srl]$") then debug_print_minimal("ConsonantResolution", "Initial non-palatal '", base, "' for '", c_capture, "' in '", ocs, "' -> returning base"); return base end
        end
        if base == "s" then return quality == "palatal" and "s'" or "s" else return quality == "palatal" and base .. "'" or base end
    end },
}
irishPhonetics.rules_stage4_0_specific_ortho_to_temp_marker = {
    { pattern = "^(ˈ?(?:[^"..ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR.."]*))a(&A_VOC_M_MEDIAL_R_TAG&)(s["..ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR.."]?)", replacement = "%1&TEMP_CONN_AU_TAG&%3" }, { pattern = "^(ˈ?(?:[^"..ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR.."]*))ea(&EA_VOC_B_MEDIAL_R_TAG&)(r["..ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR.."]?)", replacement = "%1&TEMP_CONN_AU_TAG&%3" }, { pattern = "(["..ANY_SHORT_VOWEL_PHONETIC_CHARS_STR.."])(&A_VOC_M_MEDIAL_R_TAG&)", replacement = "%1&VOC_AMH_MEDIAL_R_TAG&" }, { pattern = "(["..ANY_SHORT_VOWEL_PHONETIC_CHARS_STR.."])(&EA_VOC_B_MEDIAL_R_TAG&)", replacement = "%1&VOC_EABH_MEDIAL_R_TAG&" }, { pattern = "^(ˈ?)("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)".."ea(_CH_TAG_t)$", replacement = "%1%2&EA_BROAD_SHORT_PRE_CHT_TAG&%3" }, { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)".."ea(_CH_TAG_)", replacement = "%1&EA_SLENDER_PRE_CH_TAG&%2" }, { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)".."ea(ŋ)", replacement = function(full_match, c_part, ng_cap, o_context_str, original_match_info_tbl) local ortho_n_start_idx = original_match_info_tbl.ortho_e - ulen(ng_cap) + 1; local quality_of_n = determine_consonant_quality_ortho(o_context_str, ortho_n_start_idx, ortho_n_start_idx); if quality_of_n == "palatal" then return (c_part or "") .."&EA_SLENDER_PRE_NG_TAG&"..ng_cap else return (c_part or "") .. "&EA_BROAD_PRE_NG_TAG&"..ng_cap end end, use_original_context_for_rules = true }, { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)".."ea(N_STRONG_PAL)$", replacement = "%1&EA_SLENDER_PRE_NN_TAG&%2" }, { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)".."ea(N_STRONG_BROAD)$", replacement = "%1&EA_BROAD_PRE_NN_TAG&%2" }, { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)".."ea(N_STRONG_BROAD)([^'])", replacement = "%1&EA_BROAD_PRE_NN_TAG&%2%3" }, { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)".."ea(r')", replacement = "%1&EA_SLENDER_PRE_RPRIME_TAG&%2" }, { pattern = "((?:["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."]'?)*)iu(_CH_TAG_)", replacement = "%1&IU_SLENDER_FINAL_PRE_CH_TAG&%2" }, { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)".."ea(r)", replacement = "%1&EA_BROAD_PRE_R_TAG&%2" }, { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)".."ea(n)$", replacement = function(full_match, c_part, n_cap, o_context_str, original_match_info_tbl) local n_quality = determine_consonant_quality_ortho(o_context_str, original_match_info_tbl.ortho_s + ulen(c_part or "") + 2, original_match_info_tbl.ortho_s + ulen(c_part or "") + 2 ); if n_quality == "palatal" then return (c_part or "") .. "&EA_SLENDER_PRE_N_TAG&" .. (n_cap or "") else return (c_part or "") .. "&EA_BROAD_PRE_N_TAG&" .. (n_cap or "") end end, use_original_context_for_rules = true }, { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)".."ea(n)([^" .. ALL_VOWELS_ORTHO_CHARS_STR .. "°%-bhfpgcdtmls" .. ANY_CONSONANT_PHONETIC_RAW_CHARS_STR .. "'])", replacement = function(full_match, c_part, n_cap, next_char_phon, o_context_str, original_match_info_tbl) local n_quality = determine_consonant_quality_ortho(o_context_str, original_match_info_tbl.ortho_s + ulen(c_part or "") + 2, original_match_info_tbl.ortho_s + ulen(c_part or "") + 2 ); if n_quality == "palatal" then return (c_part or "") .. "&EA_SLENDER_PRE_N_TAG&" .. (n_cap or "") .. (next_char_phon or "") else return (c_part or "") .. "&EA_BROAD_PRE_N_TAG&" .. (n_cap or "") .. (next_char_phon or "") end end, use_original_context_for_rules = true }, { pattern = "io", replacement = "&IO_SHORT_TARGET_TAG&" },}
irishPhonetics.rules_stage4_0_1_resolve_ch_marker = { { pattern = "_CH_TAG_", replacement = function(full_match_marker, o_context_str, original_match_info_tbl) if not original_match_info_tbl or not original_match_info_tbl.ortho_s or not original_match_info_tbl.ortho_e then return "x" end; local quality_for_ch = determine_consonant_quality_ortho(o_context_str, original_match_info_tbl.ortho_s, original_match_info_tbl.ortho_e); return quality_for_ch == "palatal" and "ç" or "x" end },}
irishPhonetics.rules_stage4_1_vocmark_to_temp_marker = {}
irishPhonetics.rules_stage4_2_long_vowels_ortho_to_temp_marker = { { pattern = "éi", replacement = "&E_ACUTE_I_LONG_TAG&" }, { pattern = "iú", replacement = "&I_ACUTE_U_LONG_TAG&"}, { pattern = "á", replacement = "&A_ACUTE_LONG_TAG&" }, { pattern = "é", replacement = "&E_ACUTE_LONG_TAG&" }, { pattern = "í", replacement = "&I_ACUTE_LONG_TAG&" }, { pattern = "ó", replacement = "&O_ACUTE_LONG_TAG&" }, { pattern = "ú", replacement = "&U_ACUTE_LONG_TAG&" }, { pattern = "_A_I_ACUTE_LONG_TAG_", replacement = "&A_I_ACUTE_LONG_RESOLVE_TAG&" },}
irishPhonetics.rules_stage4_3_diphthongs_ortho_to_temp_marker = { { pattern = "&EOI_TRIGRAPH_O_LONG_TAG&", replacement = "&EOI_TRIGRAPH_O_LONG_TAG&"}, { pattern = "&EOI_TRIGRAPH_O_LONG_ACUTE_TAG&", replacement = "&EOI_TRIGRAPH_O_LONG_ACUTE_TAG&"}, { pattern = "ae", replacement = "&AE_SEQ_TAG&" }, { pattern = "ia", replacement = "&IA_DIPH_TAG&" }, { pattern = "ua", replacement = "&UA_DIPH_TAG&" }, 
    { pattern = "b(&AI_DIPH_TAG&)(N_STRONG_PAL)e", replacement = "b&A_FROM_BAINNE_TAG&%2e" }, -- bainne specific ortho 'ai' to 'a'
    { pattern = "ai", replacement = "&AI_DIPH_TAG&" }, 
    { pattern = "ei", replacement = "&EI_DIPH_TAG&" }, { pattern = "oi", replacement = "&OI_DIPH_TAG&" }, { pattern = "ui", replacement = "&UI_DIPH_TAG&" }, { pattern = "au", replacement = "&AU_DIPH_TAG&" }, { pattern = "ou", replacement = "&OU_DIPH_TAG&" }, { pattern = "eo", replacement = "&EO_SEQ_TAG&" },}
irishPhonetics.rules_stage4_4_resolve_temp_vowel_markers = {
    { pattern = "&EOI_TRIGRAPH_O_LONG_TAG&", replacement = "oː" }, { pattern = "&EOI_TRIGRAPH_O_LONG_ACUTE_TAG&", replacement = "oː" },
    { pattern = "&EIDH_CONN_AI_TAG&(#?)", replacement = "ai%1"},
    { pattern = "&U_VOC_B_FINAL_TAG&(#?)", replacement = "uː%1"}, { pattern = "&A_ACUTE_LONG_VOC_M_FINAL_TAG&(#?)", replacement = "ɑːv%1"}, { pattern = "&A_VOC_M_MEDIAL_R_TAG&(r)", replacement = "&TEMP_CONN_AU_TAG&%1"}, { pattern = "&EA_VOC_B_MEDIAL_R_TAG&(r)", replacement = "&TEMP_CONN_AU_TAG&%1"}, { pattern = "&A_VOC_D_FINAL_TAG&(#?)", replacement = "ə%1"}, { pattern = "&EA_VOC_D_FINAL_TAG&(#?)", replacement = "uː%1"}, { pattern = "&AGHAIDH_VOC_TARGET_TAG&(#?)", replacement = "əi%1"}, { pattern = "&A_VOC_G_FINAL_TAG&(#?)", replacement = "ə%1"}, { pattern = "&O_VOC_G_FINAL_TAG&(#?)", replacement = "ə%1"}, { pattern = "&O_VOC_B_FINAL_TAG&(#?)", replacement = "oː%1"}, { pattern = "&O_VOC_M_FINAL_TAG&(#?)", replacement = "oː%1"}, { pattern = "&I_VOC_B_FINAL_TAG&(#?)", replacement = "iː%1"}, 
    { pattern = "&I_VOC_M_MEDIAL_E_FINAL_TAG&(#?)", replacement = "ɪv'%1"}, { pattern = "&I_VOC_M_FINAL_TAG&(#?)", replacement = "iː%1"}, 
    { pattern = "&I_VOC_D_MEDIAL_E_FINAL_TAG&(#?)", replacement = "iː%1"}, { pattern = "&UI_VOC_D_MEDIAL_E_FINAL_TAG&(#?)", replacement = "iː%1"}, 
    { pattern = "&I_VOC_D_FINAL_TAG&(#?)", replacement = "iː%1"}, { pattern = "&UI_VOC_D_FINAL_TAG&(#?)", replacement = "iː%1"}, 
    { pattern = "&A_ACUTE_LONG_VOC_TH_SILENT_FINAL_TAG&(#?)", replacement = "ɑː%1"}, { pattern = "&AIDH_FINAL_SCHWA_TAG&(#?)", replacement = "ə%1"}, { pattern = "&AIGH_FINAL_SCHWA_TAG&(#?)", replacement = "ə%1"}, { pattern = "&AIDH_FINAL_VOC_TAG&(#?)", replacement = "ai%1"}, { pattern = "&AIGH_FINAL_VOC_TAG&(#?)", replacement = "ai%1"}, { pattern = "&A_I_ACUTE_LONG_RESOLVE_TAG&", replacement = "iː" }, { pattern = "&E_ACUTE_I_LONG_TAG&", replacement = "eː" }, { pattern = "&I_ACUTE_U_LONG_TAG&", replacement = "uː"}, { pattern = "&A_ACUTE_LONG_TAG&", replacement = "ɑː" }, { pattern = "&E_ACUTE_LONG_TAG&", replacement = "eː" }, { pattern = "&I_ACUTE_LONG_TAG&", replacement = "iː" }, { pattern = "&O_ACUTE_LONG_TAG&", replacement = "oː" }, { pattern = "&U_ACUTE_LONG_TAG&", replacement = "uː" }, { pattern = "&AO_LONG_TAG&", replacement = "ɨː"}, { pattern = "&AOI_LONG_TAG&", replacement = "iː"}, { pattern = "&OI_ACUTE_LONG_TAG&", replacement = "oː"}, { pattern = "&AE_SEQ_TAG&", replacement = "eː" }, { pattern = "&EO_SEQ_TAG&", replacement = "oː" }, { pattern = "&IA_DIPH_TAG&", replacement = "iə" }, { pattern = "&UA_DIPH_TAG&", replacement = "ua" }, 
    { pattern = "&A_FROM_BAINNE_TAG&", replacement = "a" }, -- For bainne
    { pattern = "&AI_DIPH_TAG&(N_STRONG_PAL)$", replacement = "a%1"}, 
    { pattern = "&AI_DIPH_TAG&(nm')", replacement = "a%1"}, 
    { pattern = "&AI_DIPH_TAG&", replacement = "ai" }, 
    { pattern = "&EI_DIPH_TAG&", replacement = "e" }, { pattern = "&OI_DIPH_TAG&("..ANY_CONSONANT_PHONETIC_PATTERN.."*')", replacement = "ɛ%1" }, { pattern = "&OI_DIPH_TAG&", replacement = "ɔ" }, { pattern = "&UI_DIPH_TAG&", replacement = "ɪ" }, { pattern = "&AU_DIPH_TAG&", replacement = "au" }, { pattern = "&OU_DIPH_TAG&", replacement = "ou" }, { pattern = "&VOC_AMH_MEDIAL_R_TAG&", replacement = "&TEMP_CONN_AU_TAG&"}, { pattern = "&VOC_EABH_MEDIAL_R_TAG&", replacement = "&TEMP_CONN_AU_TAG&"}, { pattern = "&EA_PRE_BH_VOC_TAG&", replacement = "a"}, { pattern = "&IO_SHORT_TARGET_TAG&", replacement = "ɪ"},
    { pattern = "&EACHT_BROAD_FIX_TAG&", replacement = "axt" },
    { pattern = "&EA_BROAD_SHORT_PRE_CHT_TAG&", replacement = "a"},
    { pattern = "&EA_SLENDER_PRE_CH_TAG&", replacement = "æ"},
    { pattern = "&EA_SLENDER_PRE_NG_TAG&", replacement = "æ"}, { pattern = "&EA_BROAD_PRE_NG_TAG&", replacement = "a"}, { pattern = "&EA_SLENDER_PRE_NN_TAG&", replacement = "æ"}, { pattern = "&EA_BROAD_PRE_NN_TAG&", replacement = "a"}, { pattern = "&EA_SLENDER_PRE_RPRIME_TAG&", replacement = "æ"}, { pattern = "&EA_BROAD_PRE_R_TAG&", replacement = "a"}, { pattern = "&IU_SLENDER_FINAL_PRE_CH_TAG&", replacement = "ʊ"}, { pattern = "&EA_SLENDER_PRE_N_TAG&", replacement = "æ"}, { pattern = "&EA_BROAD_PRE_N_TAG&", replacement = "a" },
    { pattern = "ea", replacement = "a" }, { pattern = "&", replacement = ""}, 
}

irishPhonetics.rules_stage4_4_1_vocalize_lenited_fricatives = {
    { pattern = "(" .. SHORT_VOWEL_CAPTURE_FOR_EPENTHESIS .. ")(v')($|#|" .. CONSONANT_CLASS_NO_CAPTURE .. ")", replacement = function(fm, vowel_cap, fric_cap, after_fric_cap, current_phon_word, s_match, e_match)
        local char_after_fric = ""; if e_match < ulen(current_phon_word) then char_after_fric = usub(current_phon_word, e_match + 1, e_match + 1) end
        if umatch(vowel_cap, "^[eɛiɪ]") and not umatch(char_after_fric, PHONETIC_VOWEL_NUCLEUS_PATTERN) then debug_print_minimal("Stage4_4_1_VocalizeLenitedFricatives", "Vocalizing '", fm, "' to iː because char_after_fric ('", char_after_fric, "') is not a vowel."); return "&TEMP_I_LONG_VOC_TAG&" .. (after_fric_cap or "")
        else debug_print_minimal("Stage4_4_1_VocalizeLenitedFricatives", "NOT vocalizing '", fm, "' because char_after_fric ('", char_after_fric, "') is a vowel or input vowel not eligible."); return fm end
    end, needs_full_context_in_func = true },
    { pattern = "(" .. SHORT_VOWEL_CAPTURE_FOR_EPENTHESIS .. ")(j)($|#|" .. CONSONANT_CLASS_NO_CAPTURE .. ")", replacement = function(fm, vowel_cap, fric_cap, after_fric_cap, current_phon_word, s_match, e_match)
        local char_after_fric = ""; if e_match < ulen(current_phon_word) then char_after_fric = usub(current_phon_word, e_match + 1, e_match + 1) end
        if umatch(vowel_cap, "^[eɛiɪ]") and not umatch(char_after_fric, PHONETIC_VOWEL_NUCLEUS_PATTERN) then debug_print_minimal("Stage4_4_1_VocalizeLenitedFricatives", "Vocalizing '", fm, "' to iː because char_after_fric ('", char_after_fric, "') is not a vowel."); return "&TEMP_I_LONG_VOC_TAG&" .. (after_fric_cap or "")
        else debug_print_minimal("Stage4_4_1_VocalizeLenitedFricatives", "NOT vocalizing '", fm, "' because char_after_fric ('", char_after_fric, "') is a vowel or input vowel not eligible."); return fm end
    end, needs_full_context_in_func = true },
    { pattern = "(" .. SHORT_VOWEL_CAPTURE_FOR_EPENTHESIS .. "v)$", replacement = "&TEMP_SCHWA_U_DIPH_VOC_TAG&" },
    { pattern = "(" .. SHORT_VOWEL_CAPTURE_FOR_EPENTHESIS .. "v)([^'])", replacement = "&TEMP_SCHWA_U_DIPH_VOC_TAG&%2" },
    { pattern = "(" .. SHORT_VOWEL_CAPTURE_FOR_EPENTHESIS .. "w)", replacement = "&TEMP_SCHWA_U_DIPH_VOC_TAG&" },
    { pattern = "(" .. SHORT_VOWEL_CAPTURE_FOR_EPENTHESIS .. "[ɣ])", replacement = "&TEMP_SCHWA_I_DIPH_VOC_TAG&" },
    { pattern = "&TEMP_SCHWA_U_DIPH_VOC_TAG&", replacement = "əu" },
    { pattern = "&TEMP_SCHWA_I_DIPH_VOC_TAG&", replacement = "əi" },
    { pattern = "&TEMP_E_LONG_VOC_TAG&", replacement = "eː" },
    { pattern = "&TEMP_I_LONG_VOC_TAG&", replacement = "iː" },
    { pattern = "&TEMP_U_LONG_VOC_TAG&", replacement = "uː" },
}

placeholder_creation_rules_stage4_5 = { { pattern = "au", replacement = "&PHON_AU_DIPH_TAG&" }, { pattern = "ai", replacement = "&PHON_AI_DIPH_TAG&" }, { pattern = "iə", replacement = "&PHON_IA_DIPH_TAG&" }, { pattern = "ua", replacement = "&PHON_UA_DIPH_TAG&" }, { pattern = "ou", replacement = "&PHON_OU_DIPH_TAG&" }, { pattern = "ei", replacement = "&PHON_EI_DIPH_TAG&" }, { pattern = "oi", replacement = "&PHON_OI_DIPH_TAG&" }, { pattern = "ui", replacement = "&PHON_UI_DIPH_TAG&" }, { pattern = "əu", replacement = "&PHON_SCHWA_U_DIPH_TAG&" }, { pattern = "aw", replacement = "&PHON_AW_SEQ_TAG&" }, { pattern = "əi", replacement = "&PHON_SCHWA_I_DIPH_TAG&" }, { pattern = "ɑː", replacement = "&PHON_A_LONG_TAG&" }, { pattern = "eː", replacement = "&PHON_E_LONG_TAG&" }, { pattern = "iː", replacement = "&PHON_I_LONG_TAG&" }, { pattern = "oː", replacement = "&PHON_O_LONG_TAG&" }, { pattern = "uː", replacement = "&PHON_U_LONG_TAG&" }, { pattern = "ɨː", replacement = "&PHON_Y_LONG_TAG&" }, { pattern = "æː", replacement = "&PHON_AE_LONG_TAG&" },}
core_allophony_rules_for_stage4_5 = {
    { pattern = "&PHON_Y_LONG_TAG&", replacement = "&PHON_I_LONG_TAG&" },
    { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."['])(a)("..BROAD_CONSONANT_PHONETIC_CLASS_NO_CAPTURE:gsub("[rR]","")..")", replacement = "%1ɑ%3" }, -- Refined to not change a->ɑ before r/R if C' precedes
    { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."['])(a)("..BROAD_CONSONANT_PHONETIC_CLASS_NO_CAPTURE:gsub("[rR]","")..")$", replacement = "%1ɑ%3" }, -- Refined
    { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."['])(a)", replacement = "%1æ" },
    { pattern = "a", replacement = "ɑ" }, { pattern = "e", replacement = "ɛ" }, { pattern = "i", replacement = "ɪ" }, 
    { pattern = "o", replacement = "ɔ" }, { pattern = "u([kgxɣ])", replacement = "ʊ%1" }, { pattern = "u", replacement = "ɔ" },         
    { pattern = "(v')([aæ])", replacement = "%1%2" }, { pattern = "t(æ)", replacement = "t'%1"}, { pattern = "l(&PHON_I_LONG_TAG&)", replacement = "l'%1"}, { pattern = "d(l'&PHON_I_LONG_TAG&)", replacement = "d'%1"}, { pattern = "n(iv')", replacement = "n'%1"}, { pattern = "(d'a)(r)(h)(&PHON_A_LONG_TAG&ɾ')", replacement = "%1ɾˠ%4" }, { pattern = "(&PHON_A_LONG_TAG&)i(r)$", replacement = "%1iɾ'"}, { pattern = "d(a)(r)", replacement = "d'%1%2"}, { pattern = "k(a)(rt)", replacement = "c%1%2"}, 
    { pattern = "(&PHON_I_LONG_TAG&ɔ)(["..BROAD_CONSONANT_PHONETIC_CLASS_NO_CAPTURE.."])", replacement = "%1%2" }, 
    { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."*'?)([ɔʊʌ])("..ANY_CONSONANT_PHONETIC_PATTERN.."['])", replacement = "%1ɛ%3" }, 
    { pattern = "([ɾR]')i", replacement = "%1ɛ" }, { pattern = "([ɾR])i", replacement = "%1ɛ" },  
    { pattern = "([ɾR]')ɔ", replacement = "%1ɔ" }, { pattern = "([ɾR])ɔ", replacement = "%1ɔ" },
    { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."*')(a)("..ANY_CONSONANT_PHONETIC_PATTERN.."['])", replacement = "%1ɛ%3" }, 
    { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."*')([ɔʊʌ])("..ANY_CONSONANT_PHONETIC_PATTERN.."['])", replacement = "%1ɪ%3" }, 
    { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."*')(e)("..ANY_CONSONANT_PHONETIC_PATTERN.."['])", replacement = "%1ɛ%3" }, 
    { pattern = "("..ANY_CONSONANT_PHONETIC_PATTERN.."*')(i)("..ANY_CONSONANT_PHONETIC_PATTERN.."['])", replacement = "%1ɪ%3" }, 
    { pattern = "l_neutral_", replacement = "l"}, {pattern = "n_neutral_", replacement = "n"},
}
placeholder_restoration_rules_stage4_5 = { { pattern = "&PHON_A_LONG_TAG&", replacement = "ɑː" }, { pattern = "&PHON_E_LONG_TAG&", replacement = "eː" }, { pattern = "&PHON_I_LONG_TAG&", replacement = "iː" }, { pattern = "&PHON_O_LONG_TAG&", replacement = "oː" }, { pattern = "&PHON_U_LONG_TAG&", replacement = "uː" }, { pattern = "&PHON_Y_LONG_TAG&", replacement = "ɨː" }, { pattern = "&PHON_AE_LONG_TAG&", replacement = "æː" }, { pattern = "&PHON_AU_DIPH_TAG&", replacement = "ɑu" }, { pattern = "&PHON_AI_DIPH_TAG&", replacement = "ai" }, { pattern = "&PHON_IA_DIPH_TAG&", replacement = "iə" }, { pattern = "&PHON_UA_DIPH_TAG&", replacement = "ua" }, { pattern = "&PHON_OU_DIPH_TAG&", replacement = "ou" }, { pattern = "&PHON_EI_DIPH_TAG&", replacement = "ei" }, { pattern = "&PHON_OI_DIPH_TAG&", replacement = "oi" }, { pattern = "&PHON_UI_DIPH_TAG&", replacement = "ui" }, { pattern = "&PHON_SCHWA_U_DIPH_TAG&", replacement = "əu" }, { pattern = "&PHON_AW_SEQ_TAG&", replacement = "ɑu" }, { pattern = "&PHON_SCHWA_I_DIPH_TAG&", replacement = "əi" },}
connacht_au_to_schwa_u_shift_rule_stage4_5 = { pattern = "^(ˈ?["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."]*'?)(ɑu)(["..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR.."]*'?)$", replacement = function(full_match, pre_part, au_diph, post_part) if is_likely_monosyllable_phonetic_revised(full_match) then return (pre_part or "") .. "əu" .. (post_part or "") end; return full_match end }
temp_conn_au_to_final_au_rule_stage4_5 = { pattern = "&TEMP_CONN_AU_TAG&", replacement = "əu" }
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
    for k, unit_data in ipairs(parsed_units) do
        if unit_data.stress == "ˈ" then explicit_stress_mark_found = true; if k + 1 <= #parsed_units and parsed_units[k+1].quality == "vowel" then primary_stress_vowel_original_index = k + 1 end
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
    if (v1_phon == "ɑ" or v1_phon == "ɔ" or v1_phon == "ʌ") and c_after_v1_quality == "nonpalatal" then new_v1_phon = "ʊ"
    elseif (v1_phon == "ɛ" or v1_phon == "ɪ" or v1_phon == "i" or v1_phon == "e" or v1_phon == "ai") and c_after_v1_quality == "palatal" then new_v1_phon = "ɪ" end
    if new_v1_phon ~= v1_phon then debug_print_minimal("Stage4_5_1_DisyllabicShortLongRaising", "Applying raising: V1 '", v1_phon, "' -> '", new_v1_phon, "'"); parsed_units[v1_original_idx].phon = new_v1_phon; return true end
    return false
end

local function process_nasalization_on_units(parsed_units, phon_word_input, context)
    debug_print_minimal("Nasalization", "General nasal spreading TEMPORARILY MINIMIZED/DISABLED for 37J testing.")
    return false -- Indicate no changes made by general spreading
end

local function process_unstressed_reduction_on_units(parsed_units, phon_word_input, context)
    if not parsed_units or #parsed_units == 0 then return false end
    local modified_in_pass = false
    local primary_stress_found, primary_stress_vowel_index = false, -1
    for k, unit_data in ipairs(parsed_units) do if unit_data.stress == "ˈ" then if k + 1 <= #parsed_units and parsed_units[k+1].quality == "vowel" then primary_stress_found = true; primary_stress_vowel_index = k + 1; break elseif unit_data.quality == "vowel" then primary_stress_found = true; primary_stress_vowel_index = k; break end end end
    if not primary_stress_found then for k, unit_data in ipairs(parsed_units) do if unit_data.quality == "vowel" then primary_stress_vowel_index = k; primary_stress_found = true; debug_print_minimal("Stage4_6_UnstressedVowelReduction_Procedural", "No explicit stress, first vowel '", unit_data.phon, "' at unit ", k, " is stressed."); break end end end
    
    for k, unit_data in ipairs(parsed_units) do
        if unit_data.quality == "vowel" then local is_stressed = (k == primary_stress_vowel_index); local v_phon = unit_data.phon; local is_eligible = not is_stressed and not umatch(v_phon, "ː$") and v_phon ~= "ə" and v_phon ~= "i"
            if is_eligible then
                local prec_c_qual, foll_c_qual = "neutral", "neutral"
                if k > 1 then local prev_actual_c_idx = k - 1; while prev_actual_c_idx > 0 and parsed_units[prev_actual_c_idx].quality == "stress_mark" do prev_actual_c_idx = prev_actual_c_idx - 1 end; if prev_actual_c_idx > 0 and (parsed_units[prev_actual_c_idx].quality == "palatal" or parsed_units[prev_actual_c_idx].quality == "nonpalatal") then prec_c_qual = parsed_units[prev_actual_c_idx].quality end end
                if k < #parsed_units then local next_actual_c_idx = k + 1; if next_actual_c_idx <= #parsed_units and parsed_units[next_actual_c_idx].quality ~= "stress_mark" then if parsed_units[next_actual_c_idx].quality == "palatal" or parsed_units[next_actual_c_idx].quality == "nonpalatal" then foll_c_qual = parsed_units[next_actual_c_idx].quality end end end
                local reduced_v = (foll_c_qual == "palatal" and "i") or (foll_c_qual == "nonpalatal" and "ə") or (prec_c_qual == "palatal" and "i") or "ə"
                if reduced_v ~= unit_data.phon then debug_print_minimal("Stage4_6_UnstressedVowelReduction_Procedural", "Reducing '", unit_data.phon, "' to '", reduced_v, "'. Prec: ", prec_c_qual, " Foll: ", foll_c_qual); parsed_units[k].phon = reduced_v; modified_in_pass = true end
            end
        end
    end
    return modified_in_pass
end

irishPhonetics.rules_stage4_6_unstressed_vowel_reduction_specific_finals = { { pattern = "aí$", replacement = "iː" }, { pattern = "eiə$", replacement = "iː"}, { pattern = "iːə$", replacement = "iː"},}
irishPhonetics.EPENTHESIS_TARGET_CLUSTERS_BROAD = { ["lk"]=true, ["lg"]=true, ["lb"]=true, ["lv"]=true, ["rm"]=true, ["rx"]=true, ["rb"]=true, ["rg"]=true, }
irishPhonetics.EPENTHESIS_TARGET_CLUSTERS_SLENDER = { ["lk"]=true, ["lf"]=true, ["rg"]=true, ["rk"]=true, ["nm"]=true, }

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
                if c1_qual == "palatal" and c2_qual == "palatal" then if irishPhonetics.EPENTHESIS_TARGET_CLUSTERS_SLENDER[cluster_key] then ep_v_insert = "i" end
                elseif c1_qual == "nonpalatal" and c2_qual == "nonpalatal" then if irishPhonetics.EPENTHESIS_TARGET_CLUSTERS_BROAD[cluster_key] then ep_v_insert = "ə" end
                end
            end
            if ep_v_insert then
                debug_print_minimal("EpenthesisAndStrongSonorants", "PROCEDURAL Epenthesis: ", unit_v.stress..unit_v.phon, unit_c1.phon, unit_c2.phon, " -> inserting ", ep_v_insert)
                table.insert(new_units_build, unit_v); table.insert(new_units_build, unit_c1); table.insert(new_units_build, { phon = ep_v_insert, stress = "", quality = (ep_v_insert == "i" and "palatal" or "nonpalatal") }); table.insert(new_units_build, unit_c2)
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
        {input_v_class_str=VOWEL_A_CLASS_CAPTURE_STRICT,    broad_lnm="ɑː", broad_r="ɑː", pal_lnm_ei="a", pal_lnm_i="ɑː", pal_r="ɑː", sonorant_triggers_special_diphthong = {}}, -- bainne: ai -> a before N'
        {input_v_class_str=VOWEL_E_I_CLASS_CAPTURE_STRICT,  broad_lnm="iː", broad_r="əu", pal_lnm_ei="CONDITIONAL_PAL_LNM_FOR_EI", pal_lnm_i="iː", pal_r="əi", sonorant_triggers_special_diphthong = {}},
        {input_v_class_str=VOWEL_O_U_CLASS_CAPTURE_STRICT,  broad_lnm="uː", broad_r="əu", pal_lnm_ei="CONDITIONAL_PAL_LNM_FOR_OU", pal_lnm_i="CONDITIONAL_PAL_LNM_FOR_OU", pal_r="ai", sonorant_triggers_special_diphthong = {L_STRONG_BROAD="ɑu", L_SINGLE_BROAD="ɑu"}}, 
        {input_v_class_str=DIPHTHONG_AI_CAPTURE_STRICT,   broad_lnm="ɑː", broad_r="ɑː", pal_lnm_ei="ai", pal_lnm_i="ɑː", pal_r="ɑː", sonorant_triggers_special_diphthong = {}} -- caill: ai -> ai before L'
    }
    local palatal_son_literals_map_ss = { L_prime = "(L_STRONG_PAL)", N_prime = "(N_STRONG_PAL)", M_prime = "([mM]')", R_prime = "([rR]')" }
    
    local function create_strong_sonorant_rule_variants(rules_table, vowel_class_capture_str_arg, son_capture_str_arg, son_type_key_base_str_arg, veffect_entry_arg, is_palatal_arg)
        local base_replacement_vowel_for_this_set
        local son_base_for_special_check = ugsub(son_capture_str_arg, "[()']", "") 
        son_base_for_special_check = ugsub(son_base_for_special_check, "_STRONG_PAL", "")
        son_base_for_special_check = ugsub(son_base_for_special_check, "_STRONG_BROAD", "")
        son_base_for_special_check = ugsub(son_base_for_special_check, "_SINGLE_BROAD", "")


        if veffect_entry_arg.sonorant_triggers_special_diphthong[son_capture_str_arg:gsub("[()]","")] and not is_palatal_arg then -- Use full marker for special check
             base_replacement_vowel_for_this_set = veffect_entry_arg.sonorant_triggers_special_diphthong[son_capture_str_arg:gsub("[()]","")]
             debug_print_minimal("EpenthesisAndStrongSonorants", "SS Special Diphthong Triggered: Vowel class '", veffect_entry_arg.input_v_class_str, "' + Sonorant '", son_capture_str_arg:gsub("[()]",""), "' -> ", base_replacement_vowel_for_this_set)
        elseif is_palatal_arg then 
            if son_type_key_base_str_arg == "PalR" then base_replacement_vowel_for_this_set = veffect_entry_arg.pal_r 
            else base_replacement_vowel_for_this_set = veffect_entry_arg.pal_lnm_ei end 
        else base_replacement_vowel_for_this_set = veffect_entry_arg[son_type_key_base_str_arg:lower()] 
        end
        if not base_replacement_vowel_for_this_set then return end

        local patterns_to_generate = {
            {ptn="^(ˈ?)" .. CPART_CAPTURE .. vowel_class_capture_str_arg .. son_capture_str_arg .. FINAL_CONS_CAPTURE .. "(#?)$", caps={s=true, cp=true, v=true, son=true, fc=true, b=true}}, {ptn="^(ˈ?)" .. CPART_CAPTURE .. vowel_class_capture_str_arg .. son_capture_str_arg .. "(#?)$", caps={s=true, cp=true, v=true, son=true, fc=false, b=true}},
            {ptn="^(ˈ?)" .. vowel_class_capture_str_arg .. son_capture_str_arg .. FINAL_CONS_CAPTURE .. "(#?)$", caps={s=true, cp=false, v=true, son=true, fc=true, b=true}}, {ptn="^(ˈ?)" .. vowel_class_capture_str_arg .. son_capture_str_arg .. "(#?)$", caps={s=true, cp=false, v=true, son=true, fc=false, b=true}}
        }
        for _, ptn_data in ipairs(patterns_to_generate) do
            table.insert(rules_table, { pattern = ptn_data.ptn, replacement = function(...)
                    local all_captures = {...}; local fm = all_captures[1]; local stress, c_part, vowel_cap, son_cap, final_cons_cap, boundary_cap; local current_cap_idx = 2 
                    if ptn_data.caps.s then stress = all_captures[current_cap_idx]; current_cap_idx = current_cap_idx + 1; end; if ptn_data.caps.cp then c_part = all_captures[current_cap_idx]; current_cap_idx = current_cap_idx + 1; end; if ptn_data.caps.v then vowel_cap = all_captures[current_cap_idx]; current_cap_idx = current_cap_idx + 1; end; if ptn_data.caps.son then son_cap = all_captures[current_cap_idx]; current_cap_idx = current_cap_idx + 1; end; if ptn_data.caps.fc then final_cons_cap = all_captures[current_cap_idx]; current_cap_idx = current_cap_idx + 1; end; if ptn_data.caps.b then boundary_cap = all_captures[current_cap_idx]; end
                    local input_vowel_base = ugsub(vowel_cap or "", "~", "")
                    local actual_repl_v_base = base_replacement_vowel_for_this_set
                    if base_replacement_vowel_for_this_set == "CONDITIONAL_PAL_LNM_FOR_EI" then
                        local son_cap_base_for_cond = ugsub(son_cap, "[()']", ""); son_cap_base_for_cond = ugsub(son_cap_base_for_cond, "_STRONG_PAL", "")
                        if umatch(son_cap_base_for_cond, "^N$") then -- For N_STRONG_PAL
                            if input_vowel_base == "ɛ" then actual_repl_v_base = "iː" else actual_repl_v_base = veffect_entry_arg.pal_lnm_i end 
                        elseif umatch(son_cap_base_for_cond, "^L$") then -- For L_STRONG_PAL
                            if input_vowel_base == "ɛ" then actual_repl_v_base = "oi" else actual_repl_v_base = veffect_entry_arg.pal_lnm_i end
                        else actual_repl_v_base = veffect_entry_arg.pal_lnm_i end
                    elseif base_replacement_vowel_for_this_set == "CONDITIONAL_PAL_LNM_FOR_OU" then
                         actual_repl_v_base = veffect_entry_arg.pal_lnm_ei 
                    end
                    local final_replacement_vowel = actual_repl_v_base 
                    debug_print_minimal("EpenthesisAndStrongSonorants", "SS Rule EXEC (Helper): PtnKey='",son_type_key_base_str_arg, veffect_entry_arg.input_v_class_str,"' Ptn='",ptn_data.ptn,"' Full='",fm,"' VIn='",vowel_cap or "","' VOut='",final_replacement_vowel or "nil","'.")
                    return (stress or "") .. (c_part or "") .. (final_replacement_vowel or vowel_cap or "") .. (son_cap or "") .. (final_cons_cap or "") .. (boundary_cap or "")
                end, use_current_phonetic_for_condition = true, condition_func = function(fm, pu) return is_likely_monosyllable_phonetic_revised(fm, pu) end })
        end
    end
    for _, veffect in ipairs(vowel_effects_map_ss_connacht) do
        create_strong_sonorant_rule_variants(irishPhonetics.rules_stage5_strong_sonorants_only, veffect.input_v_class_str, "(N_STRONG_BROAD)", "BroadLNM", veffect, false)
        create_strong_sonorant_rule_variants(irishPhonetics.rules_stage5_strong_sonorants_only, veffect.input_v_class_str, "(L_STRONG_BROAD)", "BroadLNM", veffect, false)
        create_strong_sonorant_rule_variants(irishPhonetics.rules_stage5_strong_sonorants_only, veffect.input_v_class_str, "(N_SINGLE_BROAD)", "BroadLNM", veffect, false)
        create_strong_sonorant_rule_variants(irishPhonetics.rules_stage5_strong_sonorants_only, veffect.input_v_class_str, "(L_SINGLE_BROAD)", "BroadLNM", veffect, false)
        create_strong_sonorant_rule_variants(irishPhonetics.rules_stage5_strong_sonorants_only, veffect.input_v_class_str, "([mM])", "BroadLNM", veffect, false) -- Single broad M
        create_strong_sonorant_rule_variants(irishPhonetics.rules_stage5_strong_sonorants_only, veffect.input_v_class_str, STRONG_BROAD_R_CAPTURE, "BroadR", veffect, false)
        
        create_strong_sonorant_rule_variants(irishPhonetics.rules_stage5_strong_sonorants_only, veffect.input_v_class_str, "(N_STRONG_PAL)", "PalLNM", veffect, true)
        create_strong_sonorant_rule_variants(irishPhonetics.rules_stage5_strong_sonorants_only, veffect.input_v_class_str, "(L_STRONG_PAL)", "PalLNM", veffect, true)
        create_strong_sonorant_rule_variants(irishPhonetics.rules_stage5_strong_sonorants_only, veffect.input_v_class_str, "([nN]')", "PalLNM", veffect, true) -- Single palatal n'
        create_strong_sonorant_rule_variants(irishPhonetics.rules_stage5_strong_sonorants_only, veffect.input_v_class_str, "([lL]')", "PalLNM", veffect, true) -- Single palatal l'
        create_strong_sonorant_rule_variants(irishPhonetics.rules_stage5_strong_sonorants_only, veffect.input_v_class_str, "([mM]')", "PalLNM", veffect, true) -- Single palatal m'
        create_strong_sonorant_rule_variants(irishPhonetics.rules_stage5_strong_sonorants_only, veffect.input_v_class_str, STRONG_PAL_R_CAPTURE, "PalR", veffect, true)
    end
end

irishPhonetics.rules_stage6_diacritics = { { pattern = "s$", replacement = "sˠ" }, { pattern = "s(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])", replacement = "sˠ%1" }, { pattern = "s(" .. PHONETIC_VOWEL_NUCLEUS_PATTERN .. ")", replacement = "sˠ%1" }, { pattern = "t$", replacement = "t̪" }, { pattern = "t(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])", replacement = "t̪%1" }, { pattern = "t(" .. PHONETIC_VOWEL_NUCLEUS_PATTERN .. ")", replacement = "t̪%1" }, { pattern = "d$", replacement = "d̪" }, { pattern = "d(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])", replacement = "d̪%1" }, { pattern = "d(" .. PHONETIC_VOWEL_NUCLEUS_PATTERN .. ")", replacement = "d̪%1" }, { pattern = "n$", replacement = "n̪" }, { pattern = "n(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])", replacement = "n̪%1" }, { pattern = "n(" .. PHONETIC_VOWEL_NUCLEUS_PATTERN .. ")", replacement = "n̪%1" }, { pattern = "l$", replacement = "l̪" }, { pattern = "l(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])", replacement = "l̪%1" }, { pattern = "l(" .. PHONETIC_VOWEL_NUCLEUS_PATTERN .. ")", replacement = "l̪%1" }, { pattern = "R$", replacement = "ɾˠ" }, { pattern = "R(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])", replacement = "ɾˠ%1" }, { pattern = "R(" .. PHONETIC_VOWEL_NUCLEUS_PATTERN .. ")", replacement = "ɾˠ%1" }, { pattern = "r$", replacement = "ɾˠ" }, { pattern = "r(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])", replacement = "ɾˠ%1" }, { pattern = "r(" .. PHONETIC_VOWEL_NUCLEUS_PATTERN .. ")", replacement = "ɾˠ%1" }, { pattern = "M$", replacement = "mˠ" }, { pattern = "M(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])", replacement = "mˠ%1" }, { pattern = "M(" .. PHONETIC_VOWEL_NUCLEUS_PATTERN .. ")", replacement = "mˠ%1" }, { pattern = "m$", replacement = "mˠ" }, { pattern = "m(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])", replacement = "mˠ%1" }, { pattern = "m(" .. PHONETIC_VOWEL_NUCLEUS_PATTERN .. ")", replacement = "mˠ%1" }, { pattern = "b$", replacement = "bˠ" }, { pattern = "b(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])", replacement = "bˠ%1" }, { pattern = "b(" .. PHONETIC_VOWEL_NUCLEUS_PATTERN .. ")", replacement = "bˠ%1" }, { pattern = "p$", replacement = "pˠ" }, { pattern = "p(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])", replacement = "pˠ%1" }, { pattern = "p(" .. PHONETIC_VOWEL_NUCLEUS_PATTERN .. ")", replacement = "pˠ%1" }, { pattern = "f$", replacement = "fˠ" }, { pattern = "f(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])", replacement = "fˠ%1" }, { pattern = "f(" .. PHONETIC_VOWEL_NUCLEUS_PATTERN .. ")", replacement = "fˠ%1" }, }
irishPhonetics.rules_stage7_final_cleanup = { { pattern = "("..ANY_CONSONANT_PHONETIC_RAW_CHARS_STR..")''", replacement = "%1'" }, { pattern = "s'", replacement = "ʃ" }, { pattern = "t'", replacement = "tʲ" }, { pattern = "d'", replacement = "dʲ" }, { pattern = "k'", replacement = "c" }, { pattern = "g'", replacement = "ɟ" }, { pattern = "N_STRONG_PAL", replacement = "n̠ʲ" }, { pattern = "N_STRONG_BROAD", replacement = "n̪ˠ" }, { pattern = "L_STRONG_PAL", replacement = "l̠ʲ" }, { pattern = "L_STRONG_BROAD", replacement = "l̪ˠ" }, { pattern = "N_SINGLE_BROAD", replacement = "n̪ˠ"}, { pattern = "L_SINGLE_BROAD", replacement = "l̪ˠ"}, { pattern = "l'", replacement = "lʲ" }, { pattern = "n'", replacement = "nʲ" }, { pattern = "R'", replacement = "ɾʲ" }, { pattern = "r'", replacement = "ɾʲ" }, { pattern = "f'", replacement = "fʲ" }, { pattern = "v'", replacement = "vʲ" }, { pattern = "b'", replacement = "bʲ" }, { pattern = "p'", replacement = "pʲ" }, { pattern = "M'", replacement = "mʲ" }, { pattern = "m'", replacement = "mʲ" }, { pattern = "h'", replacement = "ç" }, { pattern = "L", replacement = "lˠ" }, { pattern = "N", replacement = "nˠ" }, { pattern = "R", replacement = "ɾˠ" }, { pattern = "M", replacement = "mˠ" }, { pattern = "h$", replacement = ""}, { pattern = "#", replacement = ""}, { pattern = "^%s*(.-)%s*$", replacement = "%1" }, { pattern = "ˈə", replacement = "ə" }, { pattern = " ", replacement = " "}, { pattern = "%-", replacement = ""}, { pattern = "_TAG_", replacement = ""}, { pattern = "&", replacement = ""},}

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

function irishPhonetics.transcribe(orthographic_word)
    local current_word_phonetic = orthographic_word; if not current_word_phonetic or current_word_phonetic == "" then return "" end
    local original_ortho_for_context = ""; local ortho_map = {}
    local function build_initial_ortho_map(word_str) local new_map = {}; for k=1, ulen(word_str) do table.insert(new_map, {phon_s=k, phon_e=k, ortho_s=k, ortho_e=k}) end; return new_map end
    
    original_print_func(string.format("\n--- Transcribing: [%s] ---", ulower(orthographic_word)))
    if debug_file then debug_file:write(string.format("\n--- Transcribing: [%s] ---\n", ulower(orthographic_word))) end

    local stages = {
        {name = "PreProcess", rules = irishPhonetics.rules_stage1_preprocess, mode = "single_pass_priority_match"}, 
        {name = "MarkDigraphsAndVocalisationTriggers", rules = irishPhonetics.rules_stage2_mark_digraphs_and_vocalisation_triggers, updates_map_from_original_with_priority = true},
        {name = "ConsonantResolution", rules = irishPhonetics.rules_stage3_consonant_resolution, use_original_context_for_rules = true, is_procedural_stage = true, func = function(phon_word_in_stage3, o_context_str_stage3, current_ortho_map_stage3) if STAGE_DEBUG_ENABLED["ConsonantResolution"] then print("  ConsonantResolution START (Proc): In=", phon_word_in_stage3) end; local metathesis_phon_parts = {}; local meta_scan_offset = 1; while meta_scan_offset <= ulen(phon_word_in_stage3) do local stress_marker = ""; local current_phon_char_for_meta = usub(phon_word_in_stage3, meta_scan_offset, meta_scan_offset); if current_phon_char_for_meta == "ˈ" then stress_marker = "ˈ"; meta_scan_offset = meta_scan_offset + 1; if meta_scan_offset > ulen(phon_word_in_stage3) then table.insert(metathesis_phon_parts, stress_marker); break end; current_phon_char_for_meta = usub(phon_word_in_stage3, meta_scan_offset, meta_scan_offset) end; local c_phon_base = current_phon_char_for_meta; local c_is_palatal = false; local n_phon_base = ""; local n_is_palatal = false; local advance_for_c = 1; if usub(phon_word_in_stage3, meta_scan_offset + 1, meta_scan_offset + 1) == "'" then c_is_palatal = true; advance_for_c = 2 end; local n_phon_start_idx_in_phon = meta_scan_offset + advance_for_c; if n_phon_start_idx_in_phon <= ulen(phon_word_in_stage3) then n_phon_base = usub(phon_word_in_stage3, n_phon_start_idx_in_phon, n_phon_start_idx_in_phon); if usub(phon_word_in_stage3, n_phon_start_idx_in_phon + 1, n_phon_start_idx_in_phon + 1) == "'" then n_is_palatal = true end end; local c_is_k_type = (c_phon_base == "k" or c_phon_base == "c"); local c_is_g_type = (c_phon_base == "g"); if ((c_is_k_type) and n_phon_base == "n") or (c_is_g_type and n_phon_base == "n") then if (meta_scan_offset == 1 and stress_marker == "") or (meta_scan_offset == (1 + ulen(stress_marker)) and stress_marker ~= "") then debug_print_minimal("ConsonantResolution", "Metathesis candidate found: ", stress_marker..c_phon_base..(c_is_palatal and "'" or "")..n_phon_base..(n_is_palatal and "'" or "")); local n_phon_end_idx_in_phon = n_phon_start_idx_in_phon + (n_is_palatal and 1 or 0); local ortho_s_n, ortho_len_n = get_original_indices_from_map(n_phon_start_idx_in_phon, n_phon_end_idx_in_phon, current_ortho_map_stage3); local quality_for_r; local n_ortho_actual_start_idx = ortho_s_n; local n_ortho_actual_end_idx = ortho_s_n + ortho_len_n -1; quality_for_r = determine_consonant_quality_ortho(o_context_str_stage3, n_ortho_actual_start_idx, n_ortho_actual_end_idx); table.insert(metathesis_phon_parts, stress_marker .. c_phon_base .. (c_is_palatal and "'" or "")); if quality_for_r == "palatal" then table.insert(metathesis_phon_parts, "r'") else table.insert(metathesis_phon_parts, "r") end; meta_scan_offset = n_phon_end_idx_in_phon + 1 else table.insert(metathesis_phon_parts, stress_marker .. usub(phon_word_in_stage3, meta_scan_offset, meta_scan_offset + advance_for_c -1)); meta_scan_offset = meta_scan_offset + advance_for_c end else table.insert(metathesis_phon_parts, stress_marker .. usub(phon_word_in_stage3, meta_scan_offset, meta_scan_offset)); meta_scan_offset = meta_scan_offset + 1 end end; phon_word_in_stage3 = table.concat(metathesis_phon_parts); local multi_char_rules_stage3 = {}; local single_char_rule_data_stage3; for _, rule_data_loop in ipairs(irishPhonetics.rules_stage3_consonant_resolution) do if rule_data_loop.pattern ~= "([bcdfghkmprst])" then table.insert(multi_char_rules_stage3, rule_data_loop) else single_char_rule_data_stage3 = rule_data_loop end end; local pass1_phonetic_parts_stage3 = {}; local pass1_scan_offset_stage3 = 1; while pass1_scan_offset_stage3 <= ulen(phon_word_in_stage3) do local best_match_s_this_iter, best_match_e_this_iter, best_rule_this_iter_idx; local best_captures_this_iter = {}; local current_best_match_length_this_iter = -1; for rule_idx_loop, rule_data_loop in ipairs(multi_char_rules_stage3) do local s, e, cap1, cap2, cap3, cap4; s, e, cap1, cap2, cap3, cap4 = ufind(phon_word_in_stage3, rule_data_loop.pattern, pass1_scan_offset_stage3); if s then local current_match_len_loop = e - s + 1; if not best_match_s_this_iter or s < best_match_s_this_iter or (s == best_match_s_this_iter and current_match_len_loop > current_best_match_length_this_iter) then best_match_s_this_iter = s; best_match_e_this_iter = e; best_rule_this_iter_idx = rule_idx_loop; current_best_match_length_this_iter = current_match_len_loop; best_captures_this_iter = {cap1,cap2,cap3,cap4} end end end; if best_rule_this_iter_idx then if best_match_s_this_iter > pass1_scan_offset_stage3 then table.insert(pass1_phonetic_parts_stage3, usub(phon_word_in_stage3, pass1_scan_offset_stage3, best_match_s_this_iter - 1)) end; local rule = multi_char_rules_stage3[best_rule_this_iter_idx]; local full_match_segment = usub(phon_word_in_stage3, best_match_s_this_iter, best_match_e_this_iter); local original_ortho_s, original_ortho_len = get_original_indices_from_map(best_match_s_this_iter, best_match_e_this_iter, current_ortho_map_stage3); local original_match_info = {ortho_s = original_ortho_s, ortho_e = original_ortho_s + original_ortho_len - 1}; local actual_captures = {}; if best_captures_this_iter then for _,c_val in ipairs(best_captures_this_iter) do if c_val~=nil then table.insert(actual_captures, c_val) end end end; local replacement_text; if type(rule.replacement) == "string" then replacement_text = rule.replacement elseif type(rule.replacement) == "function" then replacement_text = rule.replacement(full_match_segment, o_context_str_stage3, original_match_info, table.unpack(actual_captures)) end; replacement_text = replacement_text or ""; table.insert(pass1_phonetic_parts_stage3, replacement_text); pass1_scan_offset_stage3 = best_match_e_this_iter + 1 else if pass1_scan_offset_stage3 <= ulen(phon_word_in_stage3) then table.insert(pass1_phonetic_parts_stage3, usub(phon_word_in_stage3, pass1_scan_offset_stage3, pass1_scan_offset_stage3)); pass1_scan_offset_stage3 = pass1_scan_offset_stage3 + 1 else break end end end; phon_word_in_stage3 = table.concat(pass1_phonetic_parts_stage3); if single_char_rule_data_stage3 then local pass2_phonetic_parts_stage3 = {}; local pass2_scan_offset_stage3 = 1; while pass2_scan_offset_stage3 <= ulen(phon_word_in_stage3) do local char_to_check = usub(phon_word_in_stage3, pass2_scan_offset_stage3, pass2_scan_offset_stage3); if char_to_check:match("^[bcdfghkmprst&LN]$") or umatch(char_to_check, "^[LN]_SINGLE_BROAD$") then local original_ortho_s, original_ortho_len = get_original_indices_from_map(pass2_scan_offset_stage3, pass2_scan_offset_stage3, current_ortho_map_stage3); local original_match_info = {ortho_s = original_ortho_s, ortho_e = original_ortho_s + original_ortho_len -1}; local replacement_text = single_char_rule_data_stage3.replacement(char_to_check, o_context_str_stage3, original_match_info); replacement_text = replacement_text or char_to_check; table.insert(pass2_phonetic_parts_stage3, replacement_text) else table.insert(pass2_phonetic_parts_stage3, char_to_check) end; pass2_scan_offset_stage3 = pass2_scan_offset_stage3 + 1 end; phon_word_in_stage3 = table.concat(pass2_phonetic_parts_stage3) end; if STAGE_DEBUG_ENABLED["ConsonantResolution"] then print("  ConsonantResolution END (Proc): Out=", phon_word_in_stage3) end; return phon_word_in_stage3 end},
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
                        local replacement_text = type(rule.replacement) == "string" and rule.replacement or type(rule.replacement) == "function" and rule.replacement(full_match_ortho_segment_for_replacement, cap1, cap2, cap3, capture4) or ""
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

-- Example Usage (at the very end of the file):
local RUN_CSV_TESTS = false
local CSV_FILE_NAME = "wiki_sample_for_llm.csv" -- or "connacht.csv"

if RUN_CSV_TESTS then
    -- irishPhonetics.run_csv_test_suite(CSV_FILE_NAME) 
else
    local words_to_test_focused = {
        "ceann", "am", "fonn", "poll", "trom", "corr", "bord", 
        "im", "roinnt", "caill", "coill", "cill", 
        "nimhe", "suidhe", -- For vocalization constraint
        "úsáideoirí", -- For eoi and stress/diacritics
        "bainne", "seanchas", -- For consonant qualities
        "fear", "leaba" -- General checks
    }
    original_print_func("\n--- Running Focused Test Set for Connacht (Iteration 37J - CSV Targets) ---")
    if debug_file then debug_file:write("\n--- Running Focused Test Set for Connacht (Iteration 37J - CSV Targets) ---\n") end

    STAGE_DEBUG_ENABLED.Parser = false; STAGE_DEBUG_ENABLED.ParserSetup = false

    for _, word in ipairs(words_to_test_focused) do
        local original = word
        original_print_func("\n--- Testing word:", original, "---")
        if debug_file then debug_file:write(string.format("\n--- Testing word: %s ---\n", original)) end
        local transcribed = irishPhonetics.transcribe(original)
        original_print_func(string.format("%-15s -> [%s]", original, transcribed))
        if debug_file then debug_file:write(string.format("%-15s -> [%s]\n", original, transcribed)) end
    end
end

return irishPhonetics
