-- irish_engine.lua
-- Rules application engine and G2P orchestration pipeline.

local core = require("irish_core")
local rules = require("irish_rules")
local processors = require("irish_processors")

local N = core.N
local ulen = core.ulen
local usub = core.usub
local ufind = core.ufind
local umatch = core.umatch
local ugsub = core.ugsub
local memoize = core.memoize
local debug_print_minimal = core.debug_print_minimal

local lexical_exceptions_connacht = core.lexical_exceptions_connacht
local UNSTRESSED_WORDS_AND_SUFFIXES = core.UNSTRESSED_WORDS_AND_SUFFIXES
local UNSTRESSED_PREFIXES_ORTHO = core.UNSTRESSED_PREFIXES_ORTHO
local get_original_indices_from_map = core.get_original_indices_from_map
local parse_phonetic_string_to_units_for_epenthesis = core.parse_phonetic_string_to_units_for_epenthesis
local is_likely_monosyllable_phonetic_revised = core.is_likely_monosyllable_phonetic_revised

local process_quality_assignment_on_units = processors.process_quality_assignment_on_units
local process_vocalization_on_units = processors.process_vocalization_on_units
local process_phonetic_units_procedurally = processors.process_phonetic_units_procedurally
local process_disyllabic_raising_on_units = processors.process_disyllabic_raising_on_units
local process_nasalization_on_units = processors.process_nasalization_on_units
local process_unstressed_reduction_on_units = processors.process_unstressed_reduction_on_units
local process_epenthesis_on_units = processors.process_epenthesis_on_units
local process_sandhi = processors.process_sandhi

local placeholder_creation_rules_stage4_5 = rules.placeholder_creation_rules_stage4_5
local core_allophony_rules_for_stage4_5 = rules.core_allophony_rules_for_stage4_5
local placeholder_restoration_rules_stage4_5 = rules.placeholder_restoration_rules_stage4_5
local connacht_au_to_schwa_u_shift_rule_stage4_5 = rules.connacht_au_to_schwa_u_shift_rule_stage4_5
local temp_conn_au_to_final_au_rule_stage4_5 = rules.temp_conn_au_to_final_au_rule_stage4_5

local irish_engine = {}

local function apply_rules_to_string_generic_impl(current_string_input,
                                              rules_to_apply_list,
                                              stage_name_str, mode_str,
                                              o_context_str_for_func,
                                              input_ortho_map)
    local current_string_local = current_string_input
    local current_ortho_map_local = input_ortho_map or {}
    local new_ortho_map_for_output = {}

    if mode_str == "iterative_gsub" then
        local string_at_start_of_iter_gsub = current_string_local
        local iteration_changed_this_pass;
        repeat
            iteration_changed_this_pass = false
            for _, rule_data in ipairs(rules_to_apply_list) do
                if type(rule_data.p) == "string" then
                    local r_target = rule_data.r
                    local new_str, num_repl = ugsub(current_string_local, rule_data.p, r_target)
                    if new_str ~= current_string_local then
                        debug_print_minimal(stage_name_str, "Iter.gsub: Rule '", rule_data.p, "' APPLIED to '",
                            current_string_local, "' -> '", new_str, "' (", num_repl, "x)");
                        current_string_local = new_str; iteration_changed_this_pass = true
                    end
                end
            end
        until not iteration_changed_this_pass
        if current_string_local ~= string_at_start_of_iter_gsub then
            debug_print_minimal(stage_name_str,
                "WARN: Ortho map may be misaligned after iterative_gsub. Rebuilding basic map for stage: " ..
                stage_name_str);
            new_ortho_map_for_output = {}
            if ulen(current_string_local) > 0 then
                if ulen(o_context_str_for_func) > 0 then
                    table.insert(new_ortho_map_for_output, {
                        phon_s = 1,
                        phon_e = ulen(current_string_local),
                        ortho_s = 1,
                        ortho_e = ulen(o_context_str_for_func),
                        name = stage_name_str .. "_iter_rebuild_fullspan"
                    })
                elseif #current_ortho_map_local > 0 then
                    table.insert(new_ortho_map_for_output, {
                        phon_s = 1,
                        phon_e = ulen(current_string_local),
                        ortho_s = current_ortho_map_local[1].ortho_s,
                        ortho_e = current_ortho_map_local[1].ortho_e,
                        name = stage_name_str .. "_iter_rebuild_from_input_map"
                    })
                end
            end
        else
            new_ortho_map_for_output = current_ortho_map_local
        end
        return current_string_local, new_ortho_map_for_output
    elseif mode_str == "single_pass_priority_match_build_map" then
        new_ortho_map_for_output = {}
        local new_string_parts = {};
        local original_ortho_cursor = 1
        local current_phonetic_pos_accumulator = 0
        while original_ortho_cursor <= ulen(o_context_str_for_func) do
            local best_match_s_ortho, best_match_e_ortho, best_rule_idx;
            local best_captures = {}; local current_best_match_len_ortho = -1
            for rule_idx, rule_data in ipairs(rules_to_apply_list) do
                if type(rule_data.p) == "string" then
                    local s, e, cap1, cap2, cap3, cap4, cap5, cap6, cap7, cap8, cap9, cap10 = ufind(
                        o_context_str_for_func, rule_data.p, original_ortho_cursor)
                    if s and s == original_ortho_cursor then
                        local ortho_len_for_this_rule = rule_data.ortho_len
                        if rule_data.ortho_len_func then
                            ortho_len_for_this_rule = rule_data.ortho_len_func(usub(o_context_str_for_func, s, e), cap1,
                                cap2, cap3, cap4, cap5, cap6, cap7, cap8, cap9, cap10) or ortho_len_for_this_rule
                        elseif not ortho_len_for_this_rule then
                            ortho_len_for_this_rule = (e - s + 1)
                        end
                        if ortho_len_for_this_rule > current_best_match_len_ortho then
                            current_best_match_len_ortho = ortho_len_for_this_rule; best_match_s_ortho = s; best_match_e_ortho =
                                s + ortho_len_for_this_rule - 1;
                            best_rule_idx = rule_idx; best_captures = { cap1, cap2, cap3, cap4, cap5, cap6, cap7, cap8,
                                cap9, cap10 }
                        end
                    end
                end
            end
            if best_rule_idx then
                local rule = rules_to_apply_list[best_rule_idx]; local full_ortho_match_seg = usub(
                    o_context_str_for_func, best_match_s_ortho, best_match_e_ortho)
                local actual_caps_for_func = {}; if best_captures then
                    for _, c_val in ipairs(best_captures) do
                        if c_val ~= nil then
                            table.insert(actual_caps_for_func, c_val)
                        end
                    end
                end
                local r_val_phonetic;
                if type(rule.r) == "string" then
                    r_val_phonetic = rule.r; if r_val_phonetic:match("%%[%d]") then
                        local temp_r = r_val_phonetic; for i_c = #actual_caps_for_func, 1, -1 do
                            temp_r = ugsub(temp_r,
                                "%%" .. i_c, actual_caps_for_func[i_c] or "")
                        end; r_val_phonetic = temp_r
                    end
                elseif type(rule.r) == "function" then
                    local call_params = { full_ortho_match_seg }; for _, cap_v in ipairs(actual_caps_for_func) do
                        table
                            .insert(call_params, cap_v)
                    end; r_val_phonetic = rule.r(table.unpack(call_params))
                end
                r_val_phonetic = r_val_phonetic or ""; table.insert(new_string_parts, r_val_phonetic);
                local phonetic_segment_len = ulen(r_val_phonetic)
                if phonetic_segment_len > 0 then
                    table.insert(new_ortho_map_for_output, {
                        phon_s = current_phonetic_pos_accumulator + 1,
                        phon_e = current_phonetic_pos_accumulator + phonetic_segment_len,
                        ortho_s = best_match_s_ortho,
                        ortho_e = best_match_e_ortho,
                        name = rule.p
                    })
                end
                current_phonetic_pos_accumulator = current_phonetic_pos_accumulator + phonetic_segment_len; original_ortho_cursor =
                    best_match_e_ortho + 1
            else
                if original_ortho_cursor <= ulen(o_context_str_for_func) then
                    local single_char_ortho = usub(o_context_str_for_func, original_ortho_cursor, original_ortho_cursor)
                    table.insert(new_string_parts, single_char_ortho)
                    table.insert(new_ortho_map_for_output, {
                        phon_s = current_phonetic_pos_accumulator + 1,
                        phon_e = current_phonetic_pos_accumulator + 1,
                        ortho_s = original_ortho_cursor,
                        ortho_e = original_ortho_cursor,
                        name = "char:" .. single_char_ortho
                    })
                    current_phonetic_pos_accumulator = current_phonetic_pos_accumulator + 1; original_ortho_cursor =
                        original_ortho_cursor + 1
                else
                    break
                end
            end
        end
        current_string_local = table.concat(new_string_parts)
        return current_string_local, new_ortho_map_for_output
    elseif mode_str == "single_pass_priority_match" then
        new_ortho_map_for_output = {}
        local new_string_parts = {};
        local scan_offset_phon = 1
        local current_new_phon_pos_accumulator = 0

        while scan_offset_phon <= ulen(current_string_local) do
            local best_match_s_phon, best_match_e_phon, best_rule_idx;
            local best_captures = {}; local current_best_match_len_phon = -1
            for rule_idx, rule_data in ipairs(rules_to_apply_list) do
                if type(rule_data.p) == "string" then
                    local s, e, cap1, cap2, cap3, cap4, cap5, cap6, cap7, cap8, cap9, cap10 = ufind(current_string_local,
                        rule_data.p, scan_offset_phon)
                    if s then
                        local current_match_len = e - s + 1;
                        if not best_match_s_phon or s < best_match_s_phon or (s == best_match_s_phon and current_match_len > current_best_match_len_phon) then
                            best_match_s_phon = s; best_match_e_phon = e; best_rule_idx = rule_idx; current_best_match_len_phon =
                                current_match_len;
                            best_captures = { cap1, cap2, cap3, cap4, cap5, cap6, cap7, cap8, cap9, cap10 }
                        end
                    end
                end
            end

            if best_rule_idx then
                if best_match_s_phon > scan_offset_phon then
                    local unmatched_segment = usub(current_string_local, scan_offset_phon, best_match_s_phon - 1)
                    table.insert(new_string_parts, unmatched_segment)
                    for _, entry in ipairs(current_ortho_map_local) do
                        if entry.phon_s >= scan_offset_phon and entry.phon_e < best_match_s_phon then
                            table.insert(new_ortho_map_for_output, {
                                phon_s = current_new_phon_pos_accumulator + (entry.phon_s - scan_offset_phon) + 1,
                                phon_e = current_new_phon_pos_accumulator + (entry.phon_e - scan_offset_phon) + 1,
                                ortho_s = entry.ortho_s,
                                ortho_e = entry.ortho_e,
                                name = entry.name .. "_unmatched_pass"
                            })
                        end
                    end
                    current_new_phon_pos_accumulator = current_new_phon_pos_accumulator + ulen(unmatched_segment)
                end

                local rule = rules_to_apply_list[best_rule_idx];
                local full_match_phon_seg = usub(current_string_local, best_match_s_phon, best_match_e_phon)
                local actual_caps_for_func = {}; if best_captures then
                    for _, c_val in ipairs(best_captures) do
                        if c_val ~= nil then
                            table.insert(actual_caps_for_func, c_val)
                        end
                    end
                end
                local apply_this_rule_now = true
                if rule.use_current_phonetic_for_condition and rule.condition_func then
                    local parsed_units_for_cond_generic = parse_phonetic_string_to_units_for_epenthesis(
                        full_match_phon_seg);
                    if not rule.condition_func(full_match_phon_seg, parsed_units_for_cond_generic) then apply_this_rule_now = false end
                end
                local r_val_phonetic;
                if apply_this_rule_now then
                    if type(rule.r) == "string" then
                        r_val_phonetic = rule.r; if r_val_phonetic:match("%%[%d]") then
                            local temp_r = r_val_phonetic; for i_c = #actual_caps_for_func, 1, -1 do
                                temp_r = ugsub(
                                    temp_r, "%%" .. i_c, actual_caps_for_func[i_c] or "")
                            end; r_val_phonetic = temp_r
                        end
                    elseif type(rule.r) == "function" then
                        local call_params = { full_match_phon_seg }; for _, cap_v in ipairs(actual_caps_for_func) do
                            table.insert(call_params, cap_v)
                        end
                        local o_s, o_l = get_original_indices_from_map(best_match_s_phon, best_match_e_phon,
                            current_ortho_map_local);
                        local o_match_info = { ortho_s = o_s, ortho_e = o_s + o_l - 1 };
                        table.insert(call_params, o_context_str_for_func); table.insert(call_params, o_match_info);
                        r_val_phonetic = rule.r(table.unpack(call_params))
                    end
                    r_val_phonetic = r_val_phonetic or ""
                else
                    r_val_phonetic = full_match_phon_seg
                end

                table.insert(new_string_parts, r_val_phonetic);
                local phonetic_replacement_len = ulen(r_val_phonetic)
                if phonetic_replacement_len > 0 then
                    local orig_s, orig_l = get_original_indices_from_map(best_match_s_phon, best_match_e_phon,
                        current_ortho_map_local)
                    table.insert(new_ortho_map_for_output, {
                        phon_s = current_new_phon_pos_accumulator + 1,
                        phon_e = current_new_phon_pos_accumulator + phonetic_replacement_len,
                        ortho_s = orig_s,
                        ortho_e = orig_s + orig_l - 1,
                        name = rule.p .. (apply_this_rule_now and "" or "_cond_false")
                    })
                end
                current_new_phon_pos_accumulator = current_new_phon_pos_accumulator + phonetic_replacement_len
                scan_offset_phon = best_match_e_phon + 1
            else
                if scan_offset_phon <= ulen(current_string_local) then
                    local remaining_segment = usub(current_string_local, scan_offset_phon)
                    table.insert(new_string_parts, remaining_segment)
                    for _, entry in ipairs(current_ortho_map_local) do
                        if entry.phon_s >= scan_offset_phon then
                            table.insert(new_ortho_map_for_output, {
                                phon_s = current_new_phon_pos_accumulator + (entry.phon_s - scan_offset_phon) + 1,
                                phon_e = current_new_phon_pos_accumulator + (entry.phon_e - scan_offset_phon) + 1,
                                ortho_s = entry.ortho_s,
                                ortho_e = entry.ortho_e,
                                name = entry.name .. "_remaining_pass"
                            })
                        end
                    end
                end
                break
            end
        end
        current_string_local = table.concat(new_string_parts)
        if #new_ortho_map_for_output == 0 and ulen(current_string_local) > 0 and #current_ortho_map_local > 0 then
            if ulen(current_string_local) == ulen(current_string_input) then
                new_ortho_map_for_output = current_ortho_map_local
            else
                debug_print_minimal(stage_name_str,
                    "WARN: String length changed in single_pass_priority_match but no rules seemed to build a new map. Rebuilding map for stage: " ..
                    stage_name_str);
                if ulen(o_context_str_for_func) > 0 then
                    table.insert(new_ortho_map_for_output, {
                        phon_s = 1,
                        phon_e = ulen(current_string_local),
                        ortho_s = 1,
                        ortho_e = ulen(o_context_str_for_func),
                        name = stage_name_str .. "_sppm_rebuild_fullspan"
                    })
                end
            end
        end
        return current_string_local, new_ortho_map_for_output
    end
    return current_string_local, current_ortho_map_local
end
local apply_rules_to_string_generic = apply_rules_to_string_generic_impl
irish_engine.apply_rules_to_string_generic = apply_rules_to_string_generic

local function process_contextual_allophony_procedurally(phon_word)
    local parsed_units = parse_phonetic_string_to_units_for_epenthesis(phon_word)
    if not parsed_units or #parsed_units == 0 then return phon_word end

    local modified_in_pass = false
    local i = 1
    while i <= #parsed_units do
        local unit = parsed_units[i]
        local rule_applied = false

        if unit.type == "vowel" and umatch(unit.phon, "^[aeiou]$") then
            local current_vowel_letter = unit.phon
            local phonetic_vowel = current_vowel_letter

            if current_vowel_letter == "a" then phonetic_vowel = "a"
            elseif current_vowel_letter == "e" then phonetic_vowel = "ɛ"
            elseif current_vowel_letter == "i" then phonetic_vowel = "ɪ"
            elseif current_vowel_letter == "o" then phonetic_vowel = "ɔ"
            elseif current_vowel_letter == "u" then phonetic_vowel = "ʊ"
            end

            if i < #parsed_units then
                local next_unit = parsed_units[i+1]
                if next_unit.type == "consonant" and umatch(next_unit.phon, "^[mˠn̪ˠŋ]") then
                    if (phonetic_vowel == "ɔ" or phonetic_vowel == "ʊ") and (next_unit.phon == "mˠ" or next_unit.phon == "n̪ˠ") then
                        phonetic_vowel = "uː"
                        rule_applied = true
                        debug_print_minimal("Stage4_5", "NASAL RAISING: Applying 'ɔ/ʊ' -> 'uː' before '", next_unit.phon, "'")
                    elseif unit.phon == "MKR_PHON_O_LONG" and (next_unit.phon == "mˠ" or next_unit.phon == "nˠ" or next_unit.phon == "n̪ˠ") then
                        phonetic_vowel = "uː"
                        rule_applied = true
                        debug_print_minimal("Stage4_5", "NASAL RAISING: Applying 'oː' -> 'uː' before '", next_unit.phon, "'")
                    end
                end
            end

            if not rule_applied and phonetic_vowel == "ɔ" and i < #parsed_units then
                local next_unit = parsed_units[i+1]
                if next_unit.type == "consonant" and umatch(next_unit.phon, "[kgx][^']?$") then
                    phonetic_vowel = "ʊ"
                    rule_applied = true
                    debug_print_minimal("Stage4_5", "VELAR RAISING: 'ɔ' -> 'ʊ' before '", next_unit.phon, "'")
                end
            end

            if not rule_applied and phonetic_vowel == "a" and i + 2 <= #parsed_units then
                local c1 = parsed_units[i+1]
                local c2 = parsed_units[i+2]
                if c1.type == "consonant" and c2.type == "consonant" and c1.phon == "lʲ" and c2.phon == "tʲ" then
                    phonetic_vowel = "ɛ"
                    rule_applied = true
                    debug_print_minimal("Stage4_5", "VOWEL GRADATION: 'a' -> 'ɛ' before 'lʲtʲ'")
                end
            end

            if unit.phon ~= phonetic_vowel then
                unit.phon = phonetic_vowel
                modified_in_pass = true
            end
        end
        i = i + 1
    end

    if modified_in_pass then
        local rebuilt_parts = {}
        for _, u in ipairs(parsed_units) do table.insert(rebuilt_parts, u.phon) end
        return table.concat(rebuilt_parts)
    else
        return phon_word
    end
end

function irish_engine.transcribe_single_word(orthographic_word_input)
    local initial_cleaned_ortho_word = N(orthographic_word_input)
    local current_word_phonetic
    local ortho_map = {}

    current_word_phonetic, ortho_map = apply_rules_to_string_generic(
        initial_cleaned_ortho_word,
        rules.rules_stage1_preprocess,
        "PreProcess",
        "single_pass_priority_match_build_map",
        initial_cleaned_ortho_word,
        {}
    )
    if core.STAGE_DEBUG_ENABLED["PreProcess"] then
        debug_print_minimal("PreProcess", "  END: Out=", current_word_phonetic)
    end

    local processed_ortho_word = current_word_phonetic
    local stage_name_1_5 = "Stage1_5_Ortho_Cluster_Simplification"
    if core.STAGE_DEBUG_ENABLED[stage_name_1_5] then
        debug_print_minimal(stage_name_1_5, "  START: In=", processed_ortho_word)
    end
    for _, rule in ipairs(rules.rules_stage1_5_ortho_cluster_simplification) do
        processed_ortho_word = ugsub(processed_ortho_word, rule.p, rule.r)
    end
    if core.STAGE_DEBUG_ENABLED[stage_name_1_5] then
        debug_print_minimal(stage_name_1_5, "  END: Out=", processed_ortho_word)
    end
    local original_ortho_for_context = processed_ortho_word

    if not current_word_phonetic or current_word_phonetic == "" then return "" end

    local exception_key_direct = current_word_phonetic
    local exception_key_no_apostrophe = ugsub(current_word_phonetic, "^'", "")
    if lexical_exceptions_connacht[exception_key_direct] then
        if core.STAGE_DEBUG_ENABLED["LexicalLookup"] then
            debug_print_minimal("LexicalLookup", " Found '",
                exception_key_direct, "' -> [", lexical_exceptions_connacht[exception_key_direct], "]")
        end
        return lexical_exceptions_connacht[exception_key_direct]
    elseif lexical_exceptions_connacht[exception_key_no_apostrophe] and exception_key_no_apostrophe ~= exception_key_direct then
        if core.STAGE_DEBUG_ENABLED["LexicalLookup"] then
            debug_print_minimal("LexicalLookup", " Found (no apostrophe) '",
                exception_key_no_apostrophe, "' -> [", lexical_exceptions_connacht[exception_key_no_apostrophe], "]")
        end
        return lexical_exceptions_connacht[exception_key_no_apostrophe]
    end

    local stages = {
        {
            name = "Stage2_5_MarkSuffixes",
            rules = rules.rules_stage2_5_mark_suffixes,
            mode = "single_pass_priority_match_build_map"
        },
        {
            name = "MarkDigraphsAndVocalisationTriggers",
            rules = rules.rules_stage2_mark_digraphs_and_vocalisation_triggers,
            mode = "single_pass_priority_match"
        },
        {
            name = "Stage3_1_MarkerResolution",
            rules = rules.rules_stage3_1_marker_resolution,
            mode = "single_pass_priority_match",
            use_original_context_for_rules = true
        },
        {
            name = "Stage3_2_QualityAssignment",
            is_procedural_stage = true,
            func = function(phon_word, o_context, current_map)
                local parsed_units = parse_phonetic_string_to_units_for_epenthesis(phon_word)
                local modified, modified_units = process_quality_assignment_on_units(parsed_units, o_context, current_map)
                if modified then
                    local rebuilt_parts = {}
                    for _, u in ipairs(modified_units) do table.insert(rebuilt_parts, u.phon) end
                    local new_phon_word = table.concat(rebuilt_parts)
                    debug_print_minimal("Stage3_2_QualityAssignment",
                        "WARN: Quality assignment changed string. Map is now approximate.")
                    local new_map = {}
                    if ulen(new_phon_word) > 0 then
                        table.insert(new_map,
                            {
                                phon_s = 1,
                                phon_e = ulen(new_phon_word),
                                ortho_s = 1,
                                ortho_e = ulen(o_context),
                                name = "s32_rebuild"
                            })
                    end
                    return new_phon_word, new_map
                else
                    return phon_word, current_map
                end
            end
        },
        {
            name = "Stage3_5_ConsonantAssimilation",
            rules = rules.rules_stage3_5_consonant_assimilation,
            mode = "iterative_gsub"
        },
        {
            name = "Stage3_2_ApplyStress",
            is_procedural_stage = true,
            func = function(phon_word, o_word_context, current_map_before_stress)
                if core.STAGE_DEBUG_ENABLED["Stage3_2_ApplyStress"] then
                    debug_print_minimal("Stage3_2_ApplyStress",
                        "  ApplyStress START: In=", phon_word, " (Original Ortho: '", o_word_context, "') Map size: ",
                        #current_map_before_stress)
                end
                local word_to_check_stress = o_word_context
                local should_have_stress = true
                -- Monosyllabic words don't take inflectional stress
                if core.is_monosyllabic and core.is_monosyllabic(word_to_check_stress) then
                    should_have_stress = false
                    debug_print_minimal("Stage3_2_ApplyStress", "ApplyStress: Word '", word_to_check_stress,
                        "' is monosyllabic, skipping stress.")
                elseif UNSTRESSED_WORDS_AND_SUFFIXES[word_to_check_stress] then
                    should_have_stress = false
                    debug_print_minimal("Stage3_2_ApplyStress", "ApplyStress: Word '", word_to_check_stress,
                        "' found in UNSTRESSED list.")
                else
                    for _, prefix in ipairs(core.UNSTRESSED_PREFIXES_ORTHO) do
                        local prefix_p_for_match = ugsub(prefix, "%-", "")
                        if usub(word_to_check_stress, 1, ulen(prefix_p_for_match)) == prefix_p_for_match then
                            should_have_stress = false; debug_print_minimal("Stage3_2_ApplyStress", "ApplyStress: Word '",
                                word_to_check_stress, "' has unstressed prefix '", prefix_p_for_match, "'."); break
                        end
                    end
                end
                local new_phon_word = phon_word
                local new_map_after_stress = current_map_before_stress
                if should_have_stress and not umatch(phon_word, "^ˈ") then
                    new_phon_word = "ˈ" .. phon_word
                    debug_print_minimal("Stage3_2_ApplyStress", "ApplyStress: Adding stress to '", new_phon_word, "'.")
                    local temp_map = {}
                    table.insert(temp_map,
                        { phon_s = 1, phon_e = 1, ortho_s = 0, ortho_e = -1, marker = true, name = "stress" })
                    for _, entry in ipairs(current_map_before_stress) do
                        table.insert(temp_map, {
                            phon_s = entry.phon_s + 1,
                            phon_e = entry.phon_e + 1,
                            ortho_s = entry.ortho_s,
                            ortho_e = entry.ortho_e,
                            name = entry.name,
                            marker = entry.marker
                        })
                    end
                    new_map_after_stress = temp_map
                    debug_print_minimal("Stage3_2_ApplyStress",
                        "Ortho map updated after stress application. Old map size: " ..
                        #current_map_before_stress .. ' -> New map size: ' .. #new_map_after_stress)
                end
                if core.STAGE_DEBUG_ENABLED["Stage3_2_ApplyStress"] then
                    debug_print_minimal("Stage3_2_ApplyStress",
                        " END: Out=", new_phon_word, " Map size: ", #new_map_after_stress)
                end
                return new_phon_word, new_map_after_stress
            end
        },
        { name = "Stage4_0_SpecificOrthoToTempMarker",   rules = rules.rules_stage4_0_specific_ortho_to_temp_marker,    mode = "single_pass_priority_match" },
        { name = "Stage4_0_1_Resolve_CH_Marker",         rules = rules.rules_stage4_0_1_resolve_ch_marker,              mode = "single_pass_priority_match" },
        { name = "Stage4_1_VocmarkToTempMarker",         rules = rules.rules_stage4_1_vocmark_to_temp_marker,           mode = "single_pass_priority_match" },
        { name = "Stage4_2_LongVowelsOrthoToTempMarker", rules = rules.rules_stage4_2_long_vowels_ortho_to_temp_marker, mode = "single_pass_priority_match" },
        { name = "Stage4_3_DiphthongsOrthoToTempMarker", rules = rules.rules_stage4_3_diphthongs_ortho_to_temp_marker,  mode = "single_pass_priority_match" },
        { name = "Stage4_4_ResolveTempVowelMarkers",     rules = rules.rules_stage4_4_resolve_temp_vowel_markers,       mode = "iterative_gsub" },
        {
            name = "Stage4_4_1_VocalizeLenitedFricatives",
            is_procedural_stage = true,
            func = function(phon_word, o_context, current_map)
                local new_phon = process_phonetic_units_procedurally(phon_word, "Stage4_4_1_VocalizeLenitedFricatives",
                    process_vocalization_on_units)
                local new_map = current_map
                if new_phon ~= phon_word then
                    debug_print_minimal("Stage4_4_1_VocalizeLenitedFricatives",
                        "WARN: String changed, map may be approx."); new_map = {}; if ulen(new_phon) > 0 and ulen(o_context) > 0 then
                        table.insert(new_map,
                            {
                                phon_s = 1,
                                phon_e = ulen(new_phon),
                                ortho_s = 1,
                                ortho_e = ulen(o_context),
                                name = "s441_rebuild"
                            })
                    end
                end
                return new_phon, new_map
            end
        },
        {
            name = "Stage4_5_ContextualAllophonyOnPhonetic",
            is_procedural_stage = true,
            func = function(phon_word, o_context, current_map)
                if core.STAGE_DEBUG_ENABLED["Stage4_5_ContextualAllophonyOnPhonetic"] then
                    debug_print_minimal("Stage4_5_ContextualAllophonyOnPhonetic", "  START: In=", phon_word)
                end
                local temp_phon, temp_map = apply_rules_to_string_generic(phon_word, placeholder_creation_rules_stage4_5,
                    "Stage4_5_P1_PlaceholderCreation", "iterative_gsub", o_context, current_map);
                debug_print_minimal("Stage4_5", "  After P1 (Placeholder): ", temp_phon)

                temp_phon, temp_map = apply_rules_to_string_generic(temp_phon, core_allophony_rules_for_stage4_5,
                    "Stage4_5_P2_CoreAllophony", "single_pass_priority_match", o_context, temp_map);
                debug_print_minimal("Stage4_5", "  After P2 (Core Allophony): ", temp_phon)

                temp_phon, temp_map = apply_rules_to_string_generic(temp_phon, placeholder_restoration_rules_stage4_5,
                    "Stage4_5_P3_PlaceholderRestoration", "iterative_gsub", o_context, temp_map);
                debug_print_minimal("Stage4_5", "  After P3 (Restore): ", temp_phon)

                temp_phon, temp_map = apply_rules_to_string_generic(temp_phon,
                    { connacht_au_to_schwa_u_shift_rule_stage4_5 }, "Stage4_5_P4_ConnachtShift", "single_pass_priority_match",
                    o_context, temp_map);
                temp_phon, temp_map = apply_rules_to_string_generic(temp_phon, { temp_conn_au_to_final_au_rule_stage4_5 },
                    "Stage4_5_P5_ConnachtShiftRestore", "single_pass_priority_match", o_context, temp_map);

                if core.STAGE_DEBUG_ENABLED["Stage4_5_ContextualAllophonyOnPhonetic"] then
                    debug_print_minimal("Stage4_5_ContextualAllophonyOnPhonetic", " END: Out=", temp_phon)
                end
                return temp_phon, temp_map
            end
        },
        {
            name = "Stage4_5_1_DisyllabicShortLongRaising",
            is_procedural_stage = true,
            func = function(phon_word, o_context, current_map)
                local new_phon = process_phonetic_units_procedurally(phon_word, "Stage4_5_1_DisyllabicShortLongRaising",
                    process_disyllabic_raising_on_units)
                local new_map = current_map; if new_phon ~= phon_word then
                    debug_print_minimal("Stage4_5_1", "WARN: String changed, map may be approx."); new_map = {}; if ulen(new_phon) > 0 and ulen(o_context) > 0 then
                        table.insert(new_map,
                            {
                                phon_s = 1,
                                phon_e = ulen(new_phon),
                                ortho_s = 1,
                                ortho_e = ulen(o_context),
                                name = "s451_rebuild"
                            })
                    end
                end
                return new_phon, new_map
            end
        },
        { name = "Stage4_5_2_ConnachtSpecificVowelShifts", rules = rules.rules_stage4_5_2_connacht_specific_vowel_shifts, mode = "iterative_gsub" },
        {
            name = "Nasalization",
            is_procedural_stage = true,
            func = function(phon_word, o_context, current_map)
                local new_phon = process_phonetic_units_procedurally(phon_word, "Nasalization",
                    process_nasalization_on_units)
                return new_phon, current_map
            end
        },
        {
            name = "Stage4_6_UnstressedVowelReduction_Procedural",
            is_procedural_stage = true,
            func = function(phon_word, o_context, current_map)
                if core.STAGE_DEBUG_ENABLED["Stage4_6_UnstressedVowelReduction_Procedural"] then
                    debug_print_minimal("Stage4_6_UnstressedVowelReduction_Procedural", "  START (Outer): In=", phon_word)
                end
                local parsed_units_for_mono_check = parse_phonetic_string_to_units_for_epenthesis(phon_word)
                if is_likely_monosyllable_phonetic_revised(phon_word, parsed_units_for_mono_check) then
                    debug_print_minimal("Stage4_6_UnstressedVowelReduction_Procedural", "Word '", phon_word, "' is monosyllabic, SKIPPING.");
                    if core.STAGE_DEBUG_ENABLED["Stage4_6_U"] then
                        debug_print_minimal("Stage4_6_UnstressedVowelReduction_Procedural", "  END (monosyllable): Out=", phon_word)
                    end
                    return phon_word, current_map
                end
                local temp_phon, temp_map = phon_word, current_map
                temp_phon, temp_map = apply_rules_to_string_generic(temp_phon,
                    rules.rules_stage4_6_unstressed_vowel_reduction_specific_finals, "Stage4_6_U_S1",
                    "iterative_gsub", o_context, temp_map)
                local phon_after_proc = process_phonetic_units_procedurally(temp_phon, "Stage4_6_U_S2",
                    process_unstressed_reduction_on_units)
                if phon_after_proc ~= temp_phon then
                    debug_print_minimal("Stage4_6_U", "WARN: String changed by proc, map may be approx."); temp_map = {}; if ulen(phon_after_proc) > 0 and ulen(o_context) > 0 then
                        table.insert(temp_map,
                            {
                                phon_s = 1,
                                phon_e = ulen(phon_after_proc),
                                ortho_s = 1,
                                ortho_e = ulen(o_context),
                                name = "s46_rebuild"
                            })
                    end
                end
                if core.STAGE_DEBUG_ENABLED["Stage4_6_U"] then
                    debug_print_minimal("Stage4_6_U", "  END (Outer): Out=", phon_after_proc)
                end
                return phon_after_proc, temp_map
            end
        },
        {
            name = "EpenthesisAndStrongSonorants",
            is_procedural_stage = true,
            func = function(phon_word_in_stage5, o_context_str_stage5, current_ortho_map_stage5)
                if core.STAGE_DEBUG_ENABLED["EpenthesisAndStrongSonorants"] then
                    debug_print_minimal("EpenthesisAndStrongSonorants", "  START (Proc): In=", phon_word_in_stage5)
                end
                local phon_after_epenthesis = process_phonetic_units_procedurally(phon_word_in_stage5,
                    "EpenthesisAndStrongSonorants_EpenthesisPart", process_epenthesis_on_units,
                    { original_ortho_for_context = o_context_str_stage5, current_ortho_map = current_ortho_map_stage5 })
                local map_after_epenthesis = current_ortho_map_stage5
                if phon_after_epenthesis ~= phon_word_in_stage5 then
                    debug_print_minimal("EpenthesisAndStrongSonorants",
                        "WARN: Epenthesis changed string, map may be approx."); map_after_epenthesis = {}; if ulen(phon_after_epenthesis) > 0 and ulen(o_context_str_stage5) > 0 then
                        table.insert(map_after_epenthesis,
                            {
                                phon_s = 1,
                                phon_e = ulen(phon_after_epenthesis),
                                ortho_s = 1,
                                ortho_e = ulen(o_context_str_stage5),
                                name = "epent_rebuild"
                            })
                    end
                end
                debug_print_minimal("EpenthesisAndStrongSonorants", "After procedural epenthesis: ", phon_after_epenthesis)
                local phon_after_strong_son, map_after_strong_son = apply_rules_to_string_generic(phon_after_epenthesis,
                    rules.rules_stage5_strong_sonorants_only, "EpenthesisAndStrongSonorants_StrongSon",
                    "single_pass_priority_match", o_context_str_stage5, map_after_epenthesis)
                debug_print_minimal("EpenthesisAndStrongSonorants", "After strong sonorant rules: ", phon_after_strong_son)
                if core.STAGE_DEBUG_ENABLED["EpenthesisAndStrongSonorants"] then
                    debug_print_minimal("EpenthesisAndStrongSonorants", " END (Proc): Out=", phon_after_strong_son)
                end
                return phon_after_strong_son, map_after_strong_son
            end
        },
        { name = "Diacritics",   rules = rules.rules_stage6_diacritics,         mode = "iterative_gsub" },
        { name = "FinalCleanup", rules = rules.rules_stage7_final_cleanup,      mode = "iterative_gsub" }
    }

    current_word_phonetic = original_ortho_for_context
    ortho_map = {}

    if core.STAGE_DEBUG_ENABLED["PreProcess"] then
        debug_print_minimal("PreProcess", string.format("Start of main stages loop. Input to MarkDigraphs: [%s]", current_word_phonetic))
    end

    for i, stage_data in ipairs(stages) do
        local stage_start_time = os.clock()
        local stage_name = stage_data.name
        local string_before_stage = current_word_phonetic
        local map_before_stage_size = #ortho_map

        if core.STAGE_DEBUG_ENABLED[stage_name] and not stage_data.is_procedural_stage then
            debug_print_minimal(stage_name, "  " .. stage_name .. " START: In=", current_word_phonetic, " Map size: ", map_before_stage_size)
        end

        if stage_data.is_procedural_stage and type(stage_data.func) == "function" then
            current_word_phonetic, ortho_map = stage_data.func(current_word_phonetic, original_ortho_for_context, ortho_map)
        elseif stage_data.rules then
            local mode_to_use = stage_data.mode
            local input_str_for_stage = current_word_phonetic
            local map_for_stage = ortho_map

            if mode_to_use == "single_pass_priority_match_build_map" then
                input_str_for_stage = original_ortho_for_context
                map_for_stage = {}
            end

            current_word_phonetic, ortho_map = apply_rules_to_string_generic(
                input_str_for_stage,
                stage_data.rules, stage_name,
                mode_to_use,
                original_ortho_for_context,
                map_for_stage)
        end

        local stage_end_time = os.clock()
        if core.STAGE_DEBUG_ENABLED[stage_name] then
            if not stage_data.is_procedural_stage then
                debug_print_minimal(stage_name, " END: Out=", current_word_phonetic, " Map size: ", #ortho_map)
            end
            if core.STAGE_DEBUG_ENABLED.Performance then
                debug_print_minimal(stage_name, string.format("PERF: Stage %s took %.6f seconds for input: %s", stage_name, stage_end_time - stage_start_time, orthographic_word_input))
            end
        end
        if string_before_stage ~= current_word_phonetic or map_before_stage_size ~= #ortho_map then
            if core.STAGE_DEBUG_ENABLED[stage_name] then
                debug_print_minimal(stage_name, string.format("Af. %s: [%s]", stage_name, current_word_phonetic))
            end
        end
    end
    return current_word_phonetic
end


function irish_engine.transcribe(orthographic_phrase)
    local components = {}
    local current_pos = 1
    while current_pos <= ulen(orthographic_phrase) do
        local next_space_s, next_space_e = ufind(orthographic_phrase, "%s+", current_pos)
        if next_space_s then
            if next_space_s > current_pos then
                table.insert(components, {
                    ortho = usub(orthographic_phrase, current_pos, next_space_s - 1),
                    type = "word"
                })
            end
            table.insert(components, {
                ortho = usub(orthographic_phrase, next_space_s, next_space_e),
                type = "space"
            })
            current_pos = next_space_e + 1
        else
            table.insert(components, {
                ortho = usub(orthographic_phrase, current_pos),
                type = "word"
            })
            break
        end
    end

    for i, component in ipairs(components) do
        if component.type == "word" then
            component.phon = irish_engine.transcribe_single_word(component.ortho)
        else
            component.phon = component.ortho
        end
    end

    components = process_sandhi(components)

    local final_phonetic_parts = {}
    for _, component in ipairs(components) do
        table.insert(final_phonetic_parts, component.phon)
    end
    
    return table.concat(final_phonetic_parts, "")
end

return irish_engine
