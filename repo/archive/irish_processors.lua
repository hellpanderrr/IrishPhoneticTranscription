-- irish_processors.lua
-- Procedural processing functions for G2P pipeline stages (quality, vocalization, raising, epenthesis, sandhi, unstressed reduction).

local core = require("irish_core")
local rules = require("irish_rules")

local N = core.N
local ulen = core.ulen
local usub = core.usub
local ufind = core.ufind
local umatch = core.umatch
local ugsub = core.ugsub
local memoize = core.memoize
local debug_print_minimal = core.debug_print_minimal

local CONSONANTS_ORTHO_CHARS_STR = core.CONSONANTS_ORTHO_CHARS_STR
local get_original_indices_from_map = core.get_original_indices_from_map
local determine_consonant_quality_ortho = core.determine_consonant_quality_ortho
local parse_phonetic_string_to_units_for_epenthesis = core.parse_phonetic_string_to_units_for_epenthesis
local is_likely_monosyllable_phonetic_revised = core.is_likely_monosyllable_phonetic_revised

local irish_processors = {}

-- 1. quality assignment
function irish_processors.process_quality_assignment_on_units(phonetic_units, o_context_str, current_map)
    local modified_in_pass = false

    for i, unit in ipairs(phonetic_units) do
        local char_to_check = unit.phon

        if ulen(char_to_check) == 1 and umatch(char_to_check, "[" .. CONSONANTS_ORTHO_CHARS_STR .. "]") and not umatch(char_to_check, "[hŋ]") then
            local original_ortho_s, original_ortho_len = get_original_indices_from_map(unit.phon_s, unit.phon_e,
                current_map)

            local quality = determine_consonant_quality_ortho(o_context_str, original_ortho_s,
                original_ortho_s + original_ortho_len - 1)

            local result_consonant = char_to_check
            if quality == "slender" then
                if char_to_check == N("s") then
                    result_consonant = N("s'")
                else
                    result_consonant = char_to_check .. "'"
                end
            end

            if result_consonant ~= char_to_check then
                modified_in_pass = true
            end
            unit.phon = result_consonant
        end
    end

    return modified_in_pass, phonetic_units
end

-- Helper for collecting phons (used in vocalization debug)
local function collect_phons(units_table)
    local phons = {}
    for _, u in ipairs(units_table) do
        table.insert(phons, u.phon)
    end
    return phons
end

-- 2. vocalization
local process_vocalization_on_units_impl = function(parsed_units, phon_word_input, context)
    if not parsed_units or #parsed_units < 2 then return false, parsed_units end

    local vocalization_map = {
        [N("o") .. N("w")] = N("oː"),
        [N("ʊ") .. N("w")] = N("uː"),
        [N("a") .. N("w")] = N("əu"),
        [N("a") .. N("ɣ")] = N("ai"),
        [N("ʊ") .. N("ɣ")] = N("uː"),
        [N("u") .. N("ɣ")] = N("uː"),
        [N("ɛ") .. N("j")] = N("eː"),
        [N("ɪ") .. N("vʲ")] = N("iː"),
        [N("a") .. N("vʲ")] = N("ai")
    }

    local modified_in_pass = false
    local new_units_build = {}
    local i = 1
    while i <= #parsed_units do
        local current_unit = parsed_units[i]
        debug_print_minimal("Stage4_4_1_VocalizeLenitedFricatives", string.format("  Loop %d: Current unit: '%s'", i, current_unit.phon))
        debug_print_minimal("Stage4_4_1_VocalizeLenitedFricatives", "    new_units_build before: " .. table.concat(collect_phons(new_units_build), ""))

        if i > 1 and current_unit.type == "consonant" then
            local prev_unit = new_units_build[#new_units_build]
            if prev_unit and prev_unit.type == "vowel" then
                local fricative_to_check = current_unit.phon
                if fricative_to_check == N("w") then fricative_to_check = N("vˠ") end

                local lookup_key = prev_unit.phon .. fricative_to_check
                local replacement_vowel = vocalization_map[lookup_key]

                if replacement_vowel then
                    debug_print_minimal("Stage4_4_1_VocalizeLenitedFricatives",
                        "PROCEDURAL Vocalization: Replacing '",
                        prev_unit.phon .. current_unit.phon, "' with '",
                        replacement_vowel, "'")

                    prev_unit.phon = replacement_vowel
                    i = i + 1
                    modified_in_pass = true
                    goto continue_vocalization_loop
                end
            end
        end

        table.insert(new_units_build, current_unit)
        debug_print_minimal("Stage4_4_1_VocalizeLenitedFricatives", "    new_units_build after add: " .. table.concat(collect_phons(new_units_build), ""))

        i = i + 1
        ::continue_vocalization_loop::
    end

    if modified_in_pass then
        return true, new_units_build
    else
        return false, parsed_units
    end
end
irish_processors.process_vocalization_on_units = memoize(process_vocalization_on_units_impl)

-- 3. procedural runner
local process_phonetic_units_procedurally_impl = function(phon_word_input, stage_name_for_debug, unit_processor_func, context_params)
    if core.STAGE_DEBUG_ENABLED[stage_name_for_debug] then
        debug_print_minimal(stage_name_for_debug, "  " .. stage_name_for_debug .. " START (Proc Helper): In=", phon_word_input)
    end
    if not phon_word_input or phon_word_input == "" then
        return phon_word_input
    end
    local parsed_units = parse_phonetic_string_to_units_for_epenthesis(phon_word_input)
    if not parsed_units or #parsed_units == 0 then
        if core.STAGE_DEBUG_ENABLED[stage_name_for_debug] then
            debug_print_minimal(stage_name_for_debug, " END (no units): Out=", phon_word_input)
        end
        return phon_word_input
    end

    local was_modified_by_processor, returned_units_table = unit_processor_func(parsed_units, phon_word_input, context_params)
    local final_units_to_rebuild = returned_units_table

    if was_modified_by_processor then
        local rebuilt_phon_word_parts = {}
        for _, unit_data in ipairs(final_units_to_rebuild) do
            table.insert(rebuilt_phon_word_parts, (unit_data.stress or "") .. unit_data.phon)
        end
        local new_phon_word = table.concat(rebuilt_phon_word_parts)
        if core.STAGE_DEBUG_ENABLED[stage_name_for_debug] then
            debug_print_minimal(stage_name_for_debug, " END (modified by unit_processor): Out=", new_phon_word, " (Actual content of returned units)")
        end
        return new_phon_word
    else
        if core.STAGE_DEBUG_ENABLED[stage_name_for_debug] then
            debug_print_minimal(stage_name_for_debug, " END (no change by unit_processor): Out=", phon_word_input)
        end
        return phon_word_input
    end
end
irish_processors.process_phonetic_units_procedurally = memoize(process_phonetic_units_procedurally_impl)

-- 4. disyllabic raising
local process_disyllabic_raising_on_units_impl = function(parsed_units, phon_word_input, context)
    if not parsed_units or #parsed_units < 2 then return false, parsed_units end

    local vowel_units_data, primary_stress_vowel_original_index, explicit_stress_mark_found = {}, -1, false
    for k, unit_data in ipairs(parsed_units) do
        if unit_data.stress == N("ˈ") then
            explicit_stress_mark_found = true;
            if k + 1 <= #parsed_units and parsed_units[k + 1].type == "vowel" then
                primary_stress_vowel_original_index = k + 1
            end
        elseif unit_data.quality == "vowel" then
            table.insert(vowel_units_data, {
                phon = unit_data.phon,
                stress = unit_data.stress,
                quality = unit_data.quality,
                original_idx = k
            });
            if not explicit_stress_mark_found and primary_stress_vowel_original_index == -1 then
                primary_stress_vowel_original_index = k
            end
        end
    end

    if #vowel_units_data ~= 2 then return false, parsed_units end

    local v1_data, v2_data = vowel_units_data[1], vowel_units_data[2];
    local v1_original_idx = v1_data.original_idx
    local v1_is_stressed = (v1_original_idx == primary_stress_vowel_original_index)

    if not v1_is_stressed then return false, parsed_units end

    local v1_phon, v2_phon = v1_data.phon, v2_data.phon;
    local v1_is_short, v2_is_long = not umatch(v1_phon, "ː$"), umatch(v2_phon, "ː$")

    if not (v1_is_stressed and v1_is_short and v2_is_long) then
        return false, parsed_units
    end

    local can_raise = false
    if v2_phon == N("ɑː") then
        if umatch(v1_phon, "^[aɑɔʌʊ]$") then
            if v2_data.original_idx < #parsed_units then
                can_raise = true
            end
        end
    end

    if not can_raise then
        return false, parsed_units
    end

    local c_after_v1_quality, c_after_v1_phon = "neutral", ""
    if v1_original_idx + 1 < v2_data.original_idx then
        local cons_idx = v1_original_idx + 1;
        while cons_idx < v2_data.original_idx and parsed_units[cons_idx].type ~= "vowel" do
            if parsed_units[cons_idx].type ~= "stress" then
                c_after_v1_quality = parsed_units[cons_idx].quality;
                c_after_v1_phon = parsed_units[cons_idx].phon;
                break
            end
            cons_idx = cons_idx + 1
        end
    end

    debug_print_minimal("Stage4_5_1_DisyllabicShortLongRaising", "V1='",
        v1_phon, "', C_after_V1_qual='", c_after_v1_quality,
        "', C_after_V1_phon='", c_after_v1_phon, "', V2='",
        v2_phon, "'")

    local new_v1_phon = v1_phon
    if (v1_phon == N("ɑ") or v1_phon == N("a") or v1_phon == N("ɔ") or v1_phon == N("ʌ")) and
        c_after_v1_quality == "nonpalatal" then
        new_v1_phon = N("ʊ")
    elseif (v1_phon == N("ɛ") or v1_phon == N("ɪ") or v1_phon == N("i") or
            v1_phon == N("e") or v1_phon == N("ai")) and c_after_v1_quality == "palatal" then
        new_v1_phon = N("ɪ")
    end

    if new_v1_phon ~= v1_phon then
        debug_print_minimal("Stage4_5_1_DisyllabicShortLongRaising",
            "Applying raising: V1 '", v1_phon, "' -> '",
            new_v1_phon, "'");
        parsed_units[v1_original_idx].phon = new_v1_phon;
        return true, parsed_units
    end

    return false, parsed_units
end
irish_processors.process_disyllabic_raising_on_units = memoize(process_disyllabic_raising_on_units_impl)

-- 5. nasalization
local process_nasalization_on_units_impl = function(parsed_units, phon_word_input, context)
    debug_print_minimal("Nasalization", "NO.")
    return false, parsed_units
end
irish_processors.process_nasalization_on_units = memoize(process_nasalization_on_units_impl)

-- 6. unstressed reduction helpers
local function get_preceding_consonant_quality(new_units, vowel_idx)
    for i = vowel_idx - 1, 1, -1 do
        local unit = new_units[i]
        if unit.type == "consonant" then
            return unit.quality
        end
        if unit.type == "vowel" then
            return "neutral"
        end
    end
    return "neutral"
end

local function get_following_consonant_quality(all_units, vowel_idx)
    for i = vowel_idx + 1, #all_units do
        local unit = all_units[i]
        if unit.type == "consonant" then
            return unit.quality
        end
        if unit.type == "vowel" then
            return "neutral"
        end
    end
    return "neutral"
end

-- 7. unstressed reduction
local process_unstressed_reduction_on_units_impl = function(parsed_units, phon_word_input, context)
    if not parsed_units or #parsed_units < 2 then return false, parsed_units end

    local SHORT_VOWELS_TO_NEUTRALIZE_PATTERN = N("[aæɑɔeɛiɪuʊʌ]")
    local modified_in_pass = false
    local stressed_vowel_index = -1
    local syllable_count = 0

    for i = 1, #parsed_units do
        local unit = parsed_units[i]
        if unit.type == "vowel" then
            syllable_count = syllable_count + 1
            if i > 1 and parsed_units[i-1].type == "stress" then
                stressed_vowel_index = i
            end
        end
    end
    if stressed_vowel_index == -1 then
        for i = 1, #parsed_units do
            if parsed_units[i].type == "vowel" then
                stressed_vowel_index = i
                break
            end
        end
    end
    if stressed_vowel_index == -1 or syllable_count <= 1 then
        return false, parsed_units
    end

    for i = 1, #parsed_units do
        local current_unit = parsed_units[i]
        if current_unit.type == "vowel" and i ~= stressed_vowel_index then
            if not umatch(current_unit.phon, "ː") and umatch(current_unit.phon, SHORT_VOWELS_TO_NEUTRALIZE_PATTERN) then
                debug_print_minimal("Stage4_6_U", "NEUTRALIZE: Reducing unstressed '", current_unit.phon, "' to 'ə'")
                current_unit.phon = N("ə")
                modified_in_pass = true
            end
        end
    end

    if not modified_in_pass then
        return false, parsed_units
    end

    for i = 1, #parsed_units do
        local current_unit = parsed_units[i]
        if current_unit.phon == N("ə") then
            local prec_c_quality = get_preceding_consonant_quality(parsed_units, i)
            local foll_c_quality = get_following_consonant_quality(parsed_units, i)

            if prec_c_quality == "palatal" or foll_c_quality == "palatal" then
                debug_print_minimal("Stage4_6_U", "ALLOPHONY: Realizing 'ə' as 'ɪ' in slender context.")
                current_unit.phon = N("ɪ")
            else
                debug_print_minimal("Stage4_6_U", "ALLOPHONY: 'ə' remains 'ə' in broad context.")
            end
        end
    end

    return true, parsed_units
end
irish_processors.process_unstressed_reduction_on_units = memoize(process_unstressed_reduction_on_units_impl)

-- 8. epenthesis
local process_epenthesis_on_units_impl = function(parsed_units, phon_word_input, context)
    local is_overall_monosyllable = is_likely_monosyllable_phonetic_revised(phon_word_input, parsed_units)

    if not is_overall_monosyllable then return false, parsed_units end

    local vowel_count_for_epenthesis = 0
    for _, unit in ipairs(parsed_units) do
        if unit.quality == "vowel" then
            vowel_count_for_epenthesis = vowel_count_for_epenthesis + 1
        end
    end

    if vowel_count_for_epenthesis >= 3 then
        debug_print_minimal("EpenthesisAndStrongSonorants",
            "PROCEDURAL Epenthesis: Word '", phon_word_input,
            "' has >=3 syllables, SKIPPING epenthesis.")
        return false, parsed_units
    end

    local new_units_build, i, modified_by_epenthesis = {}, 1, false
    while i <= #parsed_units do
        if parsed_units[i].quality == "stress_mark" then
            table.insert(new_units_build, parsed_units[i]);
            i = i + 1;
            if i > #parsed_units then break end
        end
        if i + 2 <= #parsed_units then
            local unit_v, unit_c1, unit_c2 = parsed_units[i],
                parsed_units[i + 1],
                parsed_units[i + 2]
            local is_v_short = unit_v.quality == "vowel" and
                not umatch(unit_v.phon, "ː$")
            local c1_base = ugsub(unit_c1.phon, "['ˠʲ̪]", "");
            local is_c1_son = umatch(c1_base, "^[rlnm]$")
            local c2_base = ugsub(unit_c2.phon, "['ˠʲ̪]", "");
            local is_c2_valid = umatch(c2_base, "^[kgptdfbxs]$") or
                (is_c1_son and umatch(c2_base, "^[rlnm]$"))
            local c1_qual, c2_qual = unit_c1.quality, unit_c2.quality
            local cluster_key = c1_base .. c2_base;
            local ep_v_insert = nil
            if is_v_short and is_c1_son and is_c2_valid then
                if c1_qual == "palatal" and c2_qual == "palatal" then
                    if rules.EPENTHESIS_TARGET_CLUSTERS_SLENDER[cluster_key] then
                        ep_v_insert = N("i")
                    end
                elseif c1_qual == "nonpalatal" and c2_qual == "nonpalatal" then
                    if rules.EPENTHESIS_TARGET_CLUSTERS_BROAD[cluster_key] then
                        ep_v_insert = N("ə")
                    end
                end
            end
            if ep_v_insert then
                debug_print_minimal("EpenthesisAndStrongSonorants",
                    "PROCEDURAL Epenthesis: ",
                    unit_v.stress .. unit_v.phon, unit_c1.phon,
                    unit_c2.phon, " -> inserting ", ep_v_insert)
                table.insert(new_units_build, unit_v);
                table.insert(new_units_build, unit_c1);
                table.insert(new_units_build, {
                    phon = ep_v_insert,
                    stress = "",
                    quality = (ep_v_insert == N("i") and "palatal" or
                        "nonpalatal"),
                    type = "vowel"
                });
                table.insert(new_units_build, unit_c2)
                i = i + 3;
                modified_by_epenthesis = true
            else
                table.insert(new_units_build, parsed_units[i]);
                i = i + 1
            end
        else
            if i <= #parsed_units then
                table.insert(new_units_build, parsed_units[i])
            end
            i = i + 1
        end
    end
    if modified_by_epenthesis then
        return true, new_units_build
    else
        return false, parsed_units
    end
end
irish_processors.process_epenthesis_on_units = memoize(process_epenthesis_on_units_impl)

-- 9. sandhi processing
local sandhi_enabled = false
function irish_processors.process_sandhi(words_data)
    if not sandhi_enabled then
        return words_data
    end

    if not words_data or #words_data < 2 then
        return words_data
    end

    for i = 1, #words_data - 1 do
        local current_word = words_data[i]
        local next_word = words_data[i+1]

        if not current_word.phon or not next_word.phon or current_word.phon == "" or next_word.phon == "" then
            goto continue_loop
        end

        if umatch(current_word.phon, "[t̪ˠtʲ]$") and umatch(next_word.phon, "^[sˠʃ]") then
            local original_phon = current_word.phon
            current_word.phon = usub(current_word.phon, 1, ulen(current_word.phon) - 1)
            debug_print_minimal("Sandhi", string.format("SANDHI (t-s Assimilation): Word '%s' [%s] -> [%s] before '%s'",
                current_word.ortho, original_phon, current_word.phon, next_word.ortho))
        end

        if umatch(next_word.phon, "^[sˠʃ]n") then
            local original_phon = next_word.phon
            if umatch(next_word.phon, "^ʃn") then
                next_word.phon = ugsub(next_word.phon, "^ʃn", "ʃɾʲ", 1)
            else
                next_word.phon = ugsub(next_word.phon, "^sˠn", "sˠɾˠ", 1)
            end
            debug_print_minimal("Sandhi", string.format("SANDHI (sn->sr): Word '%s' [%s] -> [%s]",
                next_word.ortho, original_phon, next_word.phon))
        end
        if umatch(next_word.phon, "^[t̪ˠtʲ]n") then
            local original_phon = next_word.phon
            if umatch(next_word.phon, "^tʲn") then
                next_word.phon = ugsub(next_word.phon, "^tʲn", "tʲɾʲ", 1)
            else
                next_word.phon = ugsub(next_word.phon, "^t̪ˠn", "t̪ˠɾˠ", 1)
            end
            debug_print_minimal("Sandhi", string.format("SANDHI (tn->tr): Word '%s' [%s] -> [%s]",
                next_word.ortho, original_phon, next_word.phon))
        end

        local final_cons_s, final_cons_e = ufind(current_word.phon, "([kɡpbt̪d̪fvmˠnˠlˠɾˠsˠxɣ][ˠ]?)$")
        local initial_sound_s, initial_sound_e = ufind(next_word.phon, "^(.)")

        if final_cons_s and initial_sound_s then
            local final_cons = usub(current_word.phon, final_cons_s, final_cons_e)
            local initial_sound = usub(next_word.phon, initial_sound_s, initial_sound_e)

            local is_final_cons_slender = umatch(final_cons, "[ʲcɟʃçj]$")
            local is_initial_sound_slender = umatch(initial_sound, "[ʲcɟʃçjɛeɪi]")

            local original_final_cons = final_cons
            local modified = false

            if is_initial_sound_slender and not is_final_cons_slender then
                local base_cons = usub(final_cons, 1, 1)
                local palatalized_map = {
                    ["k"]="c", ["ɡ"]="ɟ", ["p"]="pʲ", ["b"]="bʲ", ["t"]="tʲ", ["d"]="dʲ",
                    ["f"]="fʲ", ["v"]="vʲ", ["m"]="mʲ", ["n"]="nʲ", ["l"]="lʲ", ["ɾ"]="ɾʲ",
                    ["s"]="ʃ", ["x"]="ç", ["ɣ"]="j"
                }
                local new_final_cons = palatalized_map[base_cons] or final_cons .. "ʲ"
                
                if new_final_cons ~= final_cons then
                    current_word.phon = usub(current_word.phon, 1, final_cons_s - 1) .. new_final_cons
                    modified = true
                end

            elseif not is_initial_sound_slender and is_final_cons_slender then
                local base_cons = usub(final_cons, 1, 1)
                local depalatalized_map = {
                    ["c"]="k", ["ɟ"]="ɡ", ["pʲ"]="p", ["bʲ"]="b", ["tʲ"]="t̪", ["dʲ"]="d̪",
                    ["fʲ"]="f", ["vʲ"]="v", ["mʲ"]="m", ["nʲ"]="n", ["lʲ"]="l", ["ɾʲ"]="ɾ",
                    ["ʃ"]="sˠ", ["ç"]="x", ["j"]="ɣ"
                }
                local new_final_cons = depalatalized_map[base_cons] or base_cons

                if new_final_cons ~= final_cons then
                    current_word.phon = usub(current_word.phon, 1, final_cons_s - 1) .. new_final_cons
                    modified = true
                end
            end

            if modified then
                debug_print_minimal("Sandhi", string.format("SANDHI (Assimilation): Final '%s' of '%s' -> '%s' before initial '%s' of '%s'",
                    original_final_cons, current_word.ortho, current_word.phon, initial_sound, next_word.ortho))
            end
        end

        ::continue_loop::
    end

    return words_data
end

return irish_processors
