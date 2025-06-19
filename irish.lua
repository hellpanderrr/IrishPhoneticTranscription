
-- irish_phonetics_43_lua_p_strict.lua
-- Determine the directory of the current script
local function getScriptDirectory()
    local info = debug.getinfo(1, "S")
    local scriptPath = info.source:sub(2)
    local dir = scriptPath:match("(.*/)")
    if not dir then dir = scriptPath:match("(.*\\)") end
    if not dir then return "" end
    return dir
end

local memoize_module_path
local scriptDir = getScriptDirectory()
if scriptDir == "" then
    memoize_module_path = "memoize"
else
    memoize_module_path = scriptDir .. "memoize"
end

local original_print_func = print

--memoize = require('memoize')
function memoize(f) 
    return f
end
local ustring_module_path = "ustring.ustring"
local status, ustring_lib = pcall(require, ustring_module_path)

if not status then
    local early_print = print
    early_print("ERROR: Failed to load ustring module from path: " ..
        ustring_module_path)
    error("ustring module not found.")
end

local ulower, usub, ulen, ufind, umatch, ugsub, ugmatch, N = ustring_lib.lower,
    ustring_lib.sub,
    ustring_lib.len,
    ustring_lib.find,
    ustring_lib.match,
    ustring_lib.gsub,
    ustring_lib.gmatch,
    ustring_lib.toNFC





print = function(...)
    local msg = table.concat({ ... }, "\t")
    original_print_func(msg)
    if debug_file then
        if msg:match("^%-%-%- Transcribing:") or msg:match("^%-*%s*-> %[%s*%S") or
            (MINIMAL_DEBUG_ENABLED and msg:match("^    MIN_DBG")) or
            msg:match("^PERF:") then
            debug_file:write(msg .. "\n");
            debug_file:flush()
        elseif not MINIMAL_DEBUG_ENABLED then
            debug_file:write(msg .. "\n");
            debug_file:flush()
        end
    end
end

local function debug_print_minimal(stage_name, ...)
    if MINIMAL_DEBUG_ENABLED and STAGE_DEBUG_ENABLED[stage_name] then
        print("    MIN_DBG (" .. stage_name:sub(1, 10) .. "): " ..
            table.concat({ ... }, "\t"))
    end
end

local irishPhonetics = {}

local SLENDER_VOWELS_ORTHO_CHARS_STR = "eéií"
local BROAD_VOWELS_ORTHO_CHARS_STR = "aáoóuú"
local ALL_VOWELS_ORTHO_CHARS_STR = SLENDER_VOWELS_ORTHO_CHARS_STR ..
    BROAD_VOWELS_ORTHO_CHARS_STR
local SLENDER_VOWELS_ORTHO_PATTERN = "[" .. SLENDER_VOWELS_ORTHO_CHARS_STR ..
    "]"
local BROAD_VOWELS_ORTHO_PATTERN = "[" .. BROAD_VOWELS_ORTHO_CHARS_STR .. "]"
local ALL_VOWELS_ORTHO_PATTERN = "[" .. ALL_VOWELS_ORTHO_CHARS_STR .. "]"
local SHORT_VOWELS_ORTHO_SINGLE_STR = "aeiou"
local CONSONANTS_ORTHO_CHARS_STR = "bcdfghlmnprst"
local ANY_CONSONANT_PHONETIC_RAW_CHARS_STR ="kgptdfbmnszrlLNRMçjɣŋhwcʃɟɾx"
local CONSONANT_CLASS_NO_CAPTURE =
    "[" .. ANY_CONSONANT_PHONETIC_RAW_CHARS_STR .. "]"
local ANY_CONSONANT_PHONETIC_PATTERN = "[" ..    ANY_CONSONANT_PHONETIC_RAW_CHARS_STR ..    "]"
local FINAL_CONSONANT_CAPTURE_STRICT = "(" .. CONSONANT_CLASS_NO_CAPTURE ..
    "'?)"
local BROAD_CONSONANT_PHONETIC_CLASS_NO_CAPTURE = "[kgptdfbmnszrlLNRMɣŋhwx]"
local ANY_SHORT_VOWEL_PHONETIC_CHARS_STR = "aæɑɔeɛəiɪuʊʌ"
local ANY_LONG_VOWEL_PHONETIC_CHARS_STR = "ɑeioɨuæ"
local ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR =
    ANY_SHORT_VOWEL_PHONETIC_CHARS_STR .. ANY_LONG_VOWEL_PHONETIC_CHARS_STR

local SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR = "([" ..
    ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR ..
    "]~?ː?)"

local DIPHTHONG_LITERALS_FOR_PRIORITY = {
    "eiə~", "eiə", "iə~", "ua~", "ai~", "ei~", "oi~", "ui~", "ɑu~", "ou~",
    "əu~", "aw~", "əi~", "iə", "ua", "ai", "ei", "oi", "ui", "ɑu", "ou",
    "əu", "aw", "əi"
}
local PHONETIC_VOWEL_NUCLEUS_PATTERN_PARTS = {}
for _, diph_lit in ipairs(DIPHTHONG_LITERALS_FOR_PRIORITY) do
    table.insert(PHONETIC_VOWEL_NUCLEUS_PATTERN_PARTS, "(" ..
        ugsub(diph_lit, "([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1") ..
        ")")
end
table.insert(PHONETIC_VOWEL_NUCLEUS_PATTERN_PARTS,
    SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR)

local SHORT_VOWEL_CAPTURE_FOR_EPENTHESIS = "([" ..
    ANY_SHORT_VOWEL_PHONETIC_CHARS_STR ..
    "]~?)"
local CPART_CAPTURE_STRICT = N("(" .. CONSONANT_CLASS_NO_CAPTURE .. "'?)")
local VOWEL_A_CLASS_CAPTURE_STRICT = N("([aæɑ]~?)")
local VOWEL_E_I_CLASS_CAPTURE_STRICT = N("([eɛiɪ]~?)")
local VOWEL_O_U_CLASS_CAPTURE_STRICT = N("([oɔʊʌ]~?)")
local DIPHTHONG_AI_CAPTURE_STRICT = N("(ai~?)")

local ZZZ_N_STR_BRD_PHON = N("ZZZNSTRBRDZZZ")
local ZZZ_L_STR_BRD_PHON = N("ZZZLSTRBRDZZZ")
local ZZZ_N_SNG_BRD_PHON = N("ZZZNSNGBRDZZZ")
local ZZZ_L_SNG_BRD_PHON = N("ZZZLSNGBRDZZZ")
local ZZZ_N_STR_PAL_PHON = N("ZZZNSTRPALZZZ")
local ZZZ_L_STR_PAL_PHON = N("ZZZLSTRPALZZZ")

local BROAD_LNM_MARKERS_FOR_STAGE5 = {
    ZZZ_N_STR_BRD_PHON, -- From broad 'nn'
    ZZZ_L_STR_BRD_PHON, -- From broad 'll'
    N("m"),             -- Broad 'm' is always treated as strong in this context
    N("M")              -- Broad 'mm' (if used)
}

local PALATAL_LNM_MARKERS_FOR_STAGE5 = {
    ZZZ_N_STR_PAL_PHON, -- From slender 'nn'
    ZZZ_L_STR_PAL_PHON, -- From slender 'll'
    N("m'"),            -- Slender 'm' is always treated as strong
    N("M'")             -- Slender 'mm' (if used)
}
local BROAD_R_MARKERS_FOR_STAGE5 = { N("R"), N("r") }
local PALATAL_R_MARKERS_FOR_STAGE5 = { N("R'"), N("r'") }

ALL_PHONETIC_CONSONANTS_INTERMEDIATE_PRIORITY = {
    N(ZZZ_N_STR_PAL_PHON), N(ZZZ_N_STR_BRD_PHON), N(ZZZ_L_STR_PAL_PHON),
    N(ZZZ_L_STR_BRD_PHON), N(ZZZ_N_SNG_BRD_PHON), N(ZZZ_L_SNG_BRD_PHON),
    N("k'"), N("g'"), N("t'"), N("d'"), N("s'"), N("l'"), N("n'"), N("r'"),
    N("f'"), N("v'"), N("b'"), N("p'"), N("m'"), N("L'"), N("N'"), N("R'"),
    N("M'"), N("h'"), N("lˠ"), N("nˠ"), N("ɾˠ"), N("mˠ"), N("t̪"),
    N("d̪"), N("n̪"), N("l̪"), N("n̠ʲ"), N("l̠ʲ"), N("n̪ˠ"),
    N("l̪ˠ"), N("c"), N("ɟ"), N("ʃ"), N("ç"), N("j"), N("k"), N("g"),
    N("t"), N("d"), N("p"), N("b"), N("m"), N("n"), N("l"), N("r"), N("s"),
    N("f"), N("v"), N("L"), N("N"), N("R"), N("M"), N("x"), N("ɣ"), N("ŋ"),
    N("h"), N("w")
}
ALL_PHONETIC_NUCLEI_PRIORITY = {
    N("eiə~"), N("eiə"), N("ɑ~ː"), N("e~ː"), N("i~ː"), N("o~ː"),
    N("u~ː"), N("ɨ~ː"), N("æ~ː"), N("ɑː"), N("eː"), N("iː"), N("oː"),
    N("uː"), N("ɨː"), N("æː"), N("iə~"), N("ua~"), N("ai~"), N("ei~"),
    N("oi~"), N("ui~"), N("ɑu~"), N("ou~"), N("əu~"), N("aw~"), N("əi~"),
    N("iə"), N("ua"), N("ai"), N("ei"), N("oi"), N("ui"), N("ɑu"), N("ou"),
    N("əu"), N("aw"), N("əi"), N("a~"), N("æ~"), N("ɑ~"), N("ɔ~"), N("e~"),
    N("ɛ~"), N("ə~"), N("i~"), N("ɪ~"), N("u~"), N("ʊ~"), N("ʌ~"), N("a"),
    N("æ"), N("ɑ"), N("ɔ"), N("e"), N("ɛ"), N("ə"), N("i"), N("ɪ"),
    N("u"), N("ʊ"), N("ʌ"), N("ʊ̽")
}
local COMBINED_PHONETIC_UNITS_PRIORITY = {}
do
    local t = {}
    for _, p_str in ipairs(ALL_PHONETIC_NUCLEI_PRIORITY) do
        table.insert(t, { phon = p_str, type = "vowel" })
    end
    for _, p_str in ipairs(ALL_PHONETIC_CONSONANTS_INTERMEDIATE_PRIORITY) do
        table.insert(t, { phon = p_str, type = "consonant" })
    end
    table.sort(t, function(a, b) return ulen(a.phon) > ulen(b.phon) end)
    COMBINED_PHONETIC_UNITS_PRIORITY = t
end

local function build_phonetic_trie()
    local root = {}
    for _, unit_entry in ipairs(COMBINED_PHONETIC_UNITS_PRIORITY) do
        local phon = unit_entry.phon
        local type = unit_entry.type
        local current_node = root

        for i = 1, ulen(phon) do
            local char = usub(phon, i, i)
            if not current_node[char] then
                current_node[char] = {}
            end
            current_node = current_node[char]
        end
        -- Mark the end of a valid unit in the Trie
        current_node.is_unit_end = true
        current_node.phon = phon
        current_node.type = type
    end
    return root
end

-- Build the Trie once when the script loads.
local PHONETIC_TRIE = build_phonetic_trie()

local lexical_exceptions_connacht = {
    [N("ar")] = N("ɛɾʲ"), -- Keep if this is the desired general pronunciation for 'ar'
    [N("ach")] = N("əx"),
    [N("bhur")] = N("ə"),
    [N("am")] = N("əmˠ"),
    -- [N("air")] = N("ɛɾʲ"), -- 'air' is often context-dependent, consider if this is always right
    [N("car")] = N("kɑɾˠ"),
    [N("'sé")] = N("ʃeː"),
    [N("sé")] = N("ʃeː"), -- Add unstressed version too
    [N("Iúr")] = N("ən̠ʲˈtʲuːɾˠ"),
    [N("an tIúr")] = N("ən̠ʲˈtʲuːɾˠ"), -- More explicit form
    [N("gníomhaíocht")] = N("ˈɡɾˠiːwiəxt̪ˠ"),
    [N("shleamhnaigh")] = N("ˈhlʲəun̪ˠə"),
    [N("amharc")] = N("ˈəuɾˠək"),
    [N("oíche")] = N("ˈiːhə"),
    [N("droichead")] = N("ˈd̪ˠɾˠɛhəd̪ˠ"),
    [N("Mhacha")] = N("ˈwaxə"),
    [N("Mhuire")] = N("ˈwɪɾʲə"),
    [N("Taoiseach")] = N("ˈt̪ˠiːʃəx"), -- Target from previous analysis
    [N("abhainn")] = N("ˈəun̠ʲ"),
    [N("Aodh")] = N("ˈiː"),
    [N("Connacht")] = N("ˈkʊn̪ˠəxt̪ˠ"),
    [N("Chonnacht")] = N("ˈxʊn̪ˠəxt̪ˠ"),
    [N("cnuimh")] = N("ˈkɾˠɪvʲ"),
    [N("fheadh")] = N("ˈa"),
    [N("d'fhág")] = N("ˈd̪ˠɑːɡ"),
    [N("Iodáil")] = N("ˈɪd̪ˠɑːlʲ"),
    [N("síofra")] = N("ˈʃiːfˠɾˠə"),
    [N("aonbheannach")] = N("ˈeːnˠvʲan̪ˠəx"),
    [N("Bíobla")] = N("ˈbʲiːbˠl̪ˠə"),
    [N("aríst")] = N("əˈɾʲiːʃtʲ"),
    [N("éiclips")] = N("ˈeːclʲɪpˠsˠ"),
    [N("Luaithrigh")] = N("ˈl̪ˠuəhɾʲi"),
    [N("Nua")] = N("ˈn̪ˠuː"),
    [N("úth")] = N("ˈʊt̪ˠ"),
    [N("Afganastáin")] = N("afˠˈɡan̪ˠəsˠt̪ˠɑːnʲ"),
    [N("Bhaile")] = N("ˈbˠalʲə"),
    [N("Átha")] = N("ˈɑːhə"),
    [N("Cliath")] = N("ˈclʲiə"),
    -- Droichead already added
    [N("Fhranc")] = N("ˈɾˠaŋk"),
    [N("Loch")] = N("ˈl̪ˠɔx"),
    [N("Garman")] = N("ˈɡaɾˠəmˠən̪ˠ"),
    [N("Tiobraid")] = N("ˈtʲʊbˠɾˠədʲ"),
    [N("Árann")] = N("ˈɑːɾˠən̪ˠ"),
    [N("'un")] = N("ən̪ˠ"),
    [N("un")] = N("ən̪ˠ"), -- Add unstressed version
    [N("'ur")] = N("əɾˠ"),
    [N("ur")] = N("əɾˠ"), -- Add unstressed version
    [N("adhmad")] = N("ˈəimˠəd̪ˠ"),
    [N("seachain")] = N("ˈʃaxənʲ")

}

local UNSTRESSED_WORDS_AND_SUFFIXES={["'un"]=true,["un"]=true,["'ur"]=true,["ur"]=true,["-as"]=true,["-sa"]=true,["-se"]=true,["-ne"]=true,["-na"]=true,["-im"]=true,["-fas"]=true,["-fá"]=true,["-fí"]=true,["-tá"]=true,["-ím"]=true,["bhur"]=true,["-óidh"]=true,["-ithe"]=true,["-aimid"]=true,["-aíonn"]=true,["-idís"]=true,["a"]=true,["a'"]=true,["a-"]=true,["ab"]=true,["ach"]=true,["ad"]=true,["ag"]=true,["an"]=true,["ar"]=true,["as"]=true,["ba"]=true,["bh"]=true,["bhf"]=true,["ch"]=true,["de"]=true,["do"]=true,["dh"]=true,["dh'"]=true,["go"]=true,["gh"]=true,["i"]=true,["is"]=true,["le"]=true,["mar"]=true,["mh"]=true,["ní"]=true,["níl"]=true,["os"]=true,["ó"]=true,["ph"]=true,["sa"]=true,["se"]=true,["sh"]=true,["th"]=true,["th'"]=true,["um"]=true}

local function get_original_indices_from_map(phon_s_target, phon_e_target, current_map)
    if not current_map or #current_map == 0 or phon_s_target <= 0 then
        -- Fallback if no map, or invalid phonetic start index
        return phon_s_target, (phon_e_target - phon_s_target + 1)
    end

    -- Check for stress marker special case first
    if phon_s_target == 1 and phon_e_target == 1 and current_map[1] and current_map[1].marker and current_map[1].name == "stress" then
        return 0, 0 -- Stress marker has no direct ortho span
    end

    local relevant_map_entries = {}
    for _, entry in ipairs(current_map) do
        if not entry.marker and -- Ignore special non-ortho markers like stress for this lookup
            math.max(entry.phon_s, phon_s_target) <= math.min(entry.phon_e, phon_e_target) then
            table.insert(relevant_map_entries, entry)
        end
    end

    if #relevant_map_entries == 0 then
        for _, entry in ipairs(current_map) do
            if not entry.marker and entry.phon_s <= phon_s_target and entry.phon_e >= phon_e_target then
                table.insert(relevant_map_entries, entry)
                break
            end
        end
        if #relevant_map_entries == 0 then
            -- More robust fallback: if the map exists but no entry covers the target,
            -- it's likely a new phonetic segment not directly from ortho (e.g. epenthesis not yet mapped)
            -- or a severe map misalignment.
            -- Returning the phonetic indices themselves as if they were orthographic is a last resort.
            -- However, if the map is small (e.g., after a crude rebuild), this might be the best guess.
            if #current_map == 1 and current_map[1].name and current_map[1].name:match("_rebuild_fullspan$") then
                -- If it's a full span rebuild, try to proportionally map
                local map_entry = current_map[1]
                local p_len_total = map_entry.phon_e - map_entry.phon_s + 1
                local o_len_total = map_entry.ortho_e - map_entry.ortho_s + 1
                if p_len_total > 0 and o_len_total > 0 then
                    local rel_phon_s = phon_s_target - map_entry.phon_s
                    local rel_phon_e = phon_e_target - map_entry.phon_s
                    local o_s = map_entry.ortho_s + math.floor(rel_phon_s * (o_len_total / p_len_total))
                    local o_e = map_entry.ortho_s + math.floor(rel_phon_e * (o_len_total / p_len_total))
                    if o_s > o_e then o_e = o_s end -- ensure valid range
                    return o_s, (o_e - o_s + 1)
                end
            end
            return phon_s_target, (phon_e_target - phon_s_target + 1) -- Final fallback
        end
    end

    table.sort(relevant_map_entries, function(a, b) return a.phon_s < b.phon_s end)

    local overall_ortho_s = relevant_map_entries[1].ortho_s
    local overall_ortho_e = relevant_map_entries[#relevant_map_entries].ortho_e

    local first_entry_of_interest = relevant_map_entries[1]
    if phon_s_target > first_entry_of_interest.phon_s then
        local p_len = first_entry_of_interest.phon_e - first_entry_of_interest.phon_s + 1
        local o_len = first_entry_of_interest.ortho_e - first_entry_of_interest.ortho_s + 1
        if p_len > 0 and o_len > 0 then
            local relative_phon_offset = phon_s_target - first_entry_of_interest.phon_s
            local ortho_offset = math.floor(relative_phon_offset * (o_len / p_len))
            overall_ortho_s = first_entry_of_interest.ortho_s + ortho_offset
        end
    end

    local last_entry_of_interest = relevant_map_entries[#relevant_map_entries]
    if phon_e_target < last_entry_of_interest.phon_e then
        local p_len = last_entry_of_interest.phon_e - last_entry_of_interest.phon_s + 1
        local o_len = last_entry_of_interest.ortho_e - last_entry_of_interest.ortho_s + 1
        if p_len > 0 and o_len > 0 then
            local relative_phon_offset_from_end = last_entry_of_interest.phon_e - phon_e_target
            local ortho_offset_from_end = math.floor(relative_phon_offset_from_end * (o_len / p_len))
            overall_ortho_e = last_entry_of_interest.ortho_e - ortho_offset_from_end
        end
    end

    if overall_ortho_s > overall_ortho_e then
        overall_ortho_s = relevant_map_entries[1].ortho_s
        overall_ortho_e = relevant_map_entries[1].ortho_e
    end
    if overall_ortho_s == 0 and overall_ortho_e == -1 then
        return 0, 0
    end

    return overall_ortho_s, (overall_ortho_e - overall_ortho_s + 1)
end

local get_ortho_vowel_quality_implication_from_char_or_group_impl
get_ortho_vowel_quality_implication_from_char_or_group_impl = function(
    v_char_or_group, is_for_preceding_consonant_context, following_cons_cluster)
    if not v_char_or_group or ulen(v_char_or_group) == 0 then return nil end

    -- This function determines the quality a consonant should have *based on* the adjacent vowel group.

    if is_for_preceding_consonant_context then
        -- *** PRECEDING CONSONANT LOGIC ***

        if v_char_or_group == "iú" or v_char_or_group == "iúr" then
            return "broad" -- This will trigger [ç] for preceding sh/th
        end    
        -- Digraphs that make the PRECEDING consonant SLENDER
        if v_char_or_group == "eo" or v_char_or_group == "ia" or v_char_or_group == "ei" or v_char_or_group == "eu" then
            return "slender"
        end

        -- Digraphs that make the PRECEDING consonant BROAD
        if v_char_or_group == "ao" or v_char_or_group == "ua" or v_char_or_group == "ai" or v_char_or_group == "oi" or v_char_or_group == "ui" then
            return "broad"
        end

        -- Special contextual rule for 'ea'
        if v_char_or_group == "ea" then
            if following_cons_cluster then
                if umatch(following_cons_cluster, "^cht") or umatch(following_cons_cluster, "^nn") or
                    umatch(following_cons_cluster, "^ll") or umatch(following_cons_cluster, "^rr") or
                    umatch(following_cons_cluster, "^ng") then
                    return "broad"
                end
            end
            return "slender"
        end

        -- Fallback to the first letter for any other case
        local char_to_check = usub(v_char_or_group, 1, 1)
        if umatch(char_to_check, SLENDER_VOWELS_ORTHO_PATTERN) then
            return "slender"
        elseif umatch(char_to_check, BROAD_VOWELS_ORTHO_PATTERN) then
            return "broad"
        end
    else
        -- *** FOLLOWING CONSONANT LOGIC ***
        -- This is simpler: it's always determined by the last letter of the vowel group.
        local char_to_check = usub(v_char_or_group, ulen(v_char_or_group), ulen(v_char_or_group))
        if umatch(char_to_check, SLENDER_VOWELS_ORTHO_PATTERN) then
            return "slender"
        elseif umatch(char_to_check, BROAD_VOWELS_ORTHO_PATTERN) then
            return "broad"
        end
    end
    debug_print_minimal("ConsonantResolution", string.format(
        "DEBUG DETERMINE_C_QUAL (Fallback): For '%s' in '%s' (idx %d): next_v_group='%s'(%s), prev_v_group='%s'(%s) -> %s",
        current_ortho_cons_seq, original_ortho_word, ortho_cons_char_start_idx,
        next_v_group, tostring(next_qual_implication), prev_v_group, tostring(prev_qual_implication),
        "nil"
    ))
    return nil -- Fallback
end

get_ortho_vowel_quality_implication_from_char_or_group = memoize(
    get_ortho_vowel_quality_implication_from_char_or_group_impl)

local determine_consonant_quality_ortho_impl
-- Replace the entire existing function with this one.
-- Replace the entire existing function with this one.
-- Replace the entire existing function with this one.
determine_consonant_quality_ortho_impl =
    function(original_ortho_word, ortho_cons_char_start_idx, ortho_cons_char_end_idx)
        if not original_ortho_word or not ortho_cons_char_start_idx or
            not ortho_cons_char_end_idx or ortho_cons_char_start_idx <= 0 or
            ortho_cons_char_end_idx > ulen(original_ortho_word) or
            ortho_cons_char_start_idx > ortho_cons_char_end_idx then
            debug_print_minimal("ConsonantResolution",
                string.format(
                    "DEBUG DETERMINE_C_QUAL: Invalid indices for '%s': s=%s, e=%s",
                    tostring(original_ortho_word),
                    tostring(ortho_cons_char_start_idx),
                    tostring(ortho_cons_char_end_idx)))
            return "nonpalatal"
        end
        local current_ortho_cons_seq = usub(original_ortho_word,
            ortho_cons_char_start_idx,
            ortho_cons_char_end_idx)

        local stress_marker_offset = (usub(original_ortho_word, 1, 1) == "ˈ") and 1 or 0

        local cluster_start_idx = ortho_cons_char_start_idx
        while cluster_start_idx > 1 do
            local prev_char = usub(original_ortho_word, cluster_start_idx - 1, cluster_start_idx - 1)
            if umatch(prev_char, "[" .. CONSONANTS_ORTHO_CHARS_STR .. "]") then
                cluster_start_idx = cluster_start_idx - 1
            else
                break
            end
        end

        if cluster_start_idx - stress_marker_offset == 1 then
            if umatch(usub(original_ortho_word, cluster_start_idx, cluster_start_idx), "[sS]") then
                local char_after_s = usub(original_ortho_word, cluster_start_idx + 1, cluster_start_idx + 1)
                if char_after_s and umatch(char_after_s, "[ptkmPTKMm]") then
                    debug_print_minimal("ConsonantResolution",
                        "OVERRIDE (s+Stop/m): For initial '" .. current_ortho_cons_seq .. "', quality is broad.")
                    return "broad"
                end
            end

            local next_v_group = ""
            local following_cons_cluster = ""
            local scan_idx = ortho_cons_char_end_idx + 1
            while scan_idx <= ulen(original_ortho_word) and umatch(usub(original_ortho_word, scan_idx, scan_idx), "[" .. CONSONANTS_ORTHO_CHARS_STR .. "]") do
                scan_idx = scan_idx + 1
            end

            while scan_idx <= ulen(original_ortho_word) do
                local char = usub(original_ortho_word, scan_idx, scan_idx)
                if umatch(char, ALL_VOWELS_ORTHO_PATTERN) then
                    next_v_group = next_v_group .. char
                    scan_idx = scan_idx + 1
                else
                    break
                end
            end

            while scan_idx <= ulen(original_ortho_word) do
                local char = usub(original_ortho_word, scan_idx, scan_idx)
                if umatch(char, "[" .. CONSONANTS_ORTHO_CHARS_STR .. "]") then
                    following_cons_cluster = following_cons_cluster .. char
                    scan_idx = scan_idx + 1
                else
                    break
                end
            end

            -- *** THIS IS THE CORRECTED CALL ***
            local next_qual_implication = get_ortho_vowel_quality_implication_from_char_or_group(next_v_group, true,
                following_cons_cluster)

            debug_print_minimal("ConsonantResolution",
                "OVERRIDE (Initial C): For '" ..
                current_ortho_cons_seq ..
                "', next_v_group '" ..
                next_v_group ..
                "' with following cons '" .. following_cons_cluster .. "' implies -> " .. tostring(next_qual_implication))
            return next_qual_implication or "nonpalatal"
        end

        -- === General Fallback Logic (for medial/final consonants) ===
        -- ... (This part remains the same, but now it correctly only handles non-initial consonants) ...
        local next_v_group = ""
        local scan_idx_next = ortho_cons_char_end_idx + 1
        local temp_scan_idx_next = scan_idx_next
        while temp_scan_idx_next <= ulen(original_ortho_word) do
            local char = usub(original_ortho_word, temp_scan_idx_next, temp_scan_idx_next)
            if umatch(char, ALL_VOWELS_ORTHO_PATTERN) then
                break
            elseif umatch(char, "[" .. CONSONANTS_ORTHO_CHARS_STR .. "]") then
                temp_scan_idx_next = temp_scan_idx_next + 1
            else
                break
            end
        end
        while temp_scan_idx_next <= ulen(original_ortho_word) do
            local char = usub(original_ortho_word, temp_scan_idx_next, temp_scan_idx_next)
            if umatch(char, ALL_VOWELS_ORTHO_PATTERN) then
                next_v_group = next_v_group .. char; temp_scan_idx_next = temp_scan_idx_next + 1
            else
                break
            end
        end
        local prev_v_group = ""
        local scan_idx_prev = ortho_cons_char_start_idx - 1
        local temp_prev_v_chars = {}
        local temp_scan_idx_prev = scan_idx_prev
        while temp_scan_idx_prev >= 1 do
            local char = usub(original_ortho_word, temp_scan_idx_prev, temp_scan_idx_prev)
            if umatch(char, ALL_VOWELS_ORTHO_PATTERN) then
                break
            elseif umatch(char, "[" .. CONSONANTS_ORTHO_CHARS_STR .. "]") or char == "ˈ" then
                temp_scan_idx_prev = temp_scan_idx_prev - 1
            else
                break
            end
        end
        while temp_scan_idx_prev >= 1 do
            local char = usub(original_ortho_word, temp_scan_idx_prev, temp_scan_idx_prev)
            if umatch(char, ALL_VOWELS_ORTHO_PATTERN) then
                table.insert(temp_prev_v_chars, 1, char); temp_scan_idx_prev = temp_scan_idx_prev - 1
            else
                break
            end
        end
        prev_v_group = table.concat(temp_prev_v_chars)

        -- The call here does not need the third argument, as it's for medial/final consonants
        -- where the following consonant context is not part of the vowel quality rule.
        local next_qual_implication = get_ortho_vowel_quality_implication_from_char_or_group(next_v_group, true)
        local prev_qual_implication = get_ortho_vowel_quality_implication_from_char_or_group(prev_v_group, false)

        local determined_quality
        if next_qual_implication == "slender" then
            determined_quality = "slender"
        elseif next_qual_implication == "broad" then
            if prev_qual_implication == "slender" then
                determined_quality = "slender"
            else
                determined_quality = "broad"
            end
        elseif prev_qual_implication == "slender" then
            determined_quality = "slender"
        elseif prev_qual_implication == "broad" then
            determined_quality = "broad"
        else
            determined_quality = "nonpalatal"
        end
        if current_ortho_cons_seq == "s" and (ortho_cons_char_start_idx - stress_marker_offset) > 1 and prev_v_group == "ú" then
            determined_quality = "nonpalatal"
        end
        debug_print_minimal("ConsonantResolution", string.format(
            "DEBUG DETERMINE_C_QUAL (Fallback): For '%s' in '%s' (idx %d): next_v_group='%s'(%s), prev_v_group='%s'(%s) -> %s",
            current_ortho_cons_seq, original_ortho_word, ortho_cons_char_start_idx,
            next_v_group, tostring(next_qual_implication), prev_v_group, tostring(prev_qual_implication),
            determined_quality
        ))
        return determined_quality
    end
determine_consonant_quality_ortho = memoize(
    determine_consonant_quality_ortho_impl)

local parse_phonetic_string_to_units_for_epenthesis_impl
parse_phonetic_string_to_units_for_epenthesis_impl =
    function(phon_str_raw)
        local phon_str = N(phon_str_raw);
        local units = {};
        local i = 1
        while i <= ulen(phon_str) do
            local stress_at_current_pos = "";
            local stress_start_idx = i;
            if usub(phon_str, i, i) == N("ˈ") then
                stress_at_current_pos = N("ˈ");
                i = i + 1;
            end

            local unit_start_idx = i; -- The start index of the potential phonetic unit

            if i > ulen(phon_str) then
                if stress_at_current_pos ~= "" then
                    table.insert(units, {
                        phon = stress_at_current_pos,
                        stress = "",
                        quality = "stress_mark",
                        type = "stress",
                        phon_s = stress_start_idx,
                        phon_e = stress_start_idx
                    });
                end
                break
            end

            local current_node = PHONETIC_TRIE
            local last_match_pos = -1
            local last_match_data = nil

            for j = i, ulen(phon_str) do
                local char = usub(phon_str, j, j)
                if current_node[char] then
                    current_node = current_node[char]
                    if current_node.is_unit_end then
                        last_match_pos = j
                        last_match_data = { phon = current_node.phon, type = current_node.type }
                    end
                else
                    break
                end
            end

            local quality = "unknown";
            if last_match_data then
                local best_overall_match_phon = last_match_data.phon
                local best_overall_match_type = last_match_data.type
                local best_overall_match_len = ulen(best_overall_match_phon)

                if best_overall_match_type == "vowel" then
                    quality = "vowel"
                elseif best_overall_match_type == "consonant" then
                    if umatch(best_overall_match_phon, "ʲ$") or umatch(best_overall_match_phon, "^[ʃçjɟc]$") or umatch(best_overall_match_phon, "'$") then
                        quality = "palatal"
                    else
                        quality = "nonpalatal"
                    end
                end

                if stress_at_current_pos ~= "" then
                    table.insert(units, {
                        phon = stress_at_current_pos,
                        stress = "",
                        quality = "stress_mark",
                        type = "stress",
                        phon_s = stress_start_idx,
                        phon_e = stress_start_idx
                    });
                end

                table.insert(units, {
                    phon = best_overall_match_phon,
                    stress = "",
                    quality = quality,
                    type = best_overall_match_type,
                    phon_s = unit_start_idx,
                    phon_e = unit_start_idx + best_overall_match_len - 1
                });
                i = i + best_overall_match_len
            elseif stress_at_current_pos ~= "" then
                table.insert(units, {
                    phon = stress_at_current_pos,
                    stress = "",
                    quality = "stress_mark",
                    type = "stress",
                    phon_s = stress_start_idx,
                    phon_e = stress_start_idx
                })
            else
                local unknown_char = usub(phon_str, i, i);
                if stress_at_current_pos ~= "" then
                    table.insert(units, {
                        phon = stress_at_current_pos,
                        stress = "",
                        quality = "stress_mark",
                        type = "stress",
                        phon_s = stress_start_idx,
                        phon_e = stress_start_idx
                    });
                end
                table.insert(units, {
                    phon = unknown_char,
                    stress = "",
                    quality = "unknown_fallback",
                    type = "unknown",
                    phon_s = unit_start_idx,
                    phon_e = unit_start_idx
                });
                i = i + 1
            end
        end
        return units
    end
parse_phonetic_string_to_units_for_epenthesis = memoize(
    parse_phonetic_string_to_units_for_epenthesis_impl)

local is_likely_monosyllable_phonetic_revised_impl
is_likely_monosyllable_phonetic_revised_impl =
    function(phon_word_local, pre_parsed_units_input)
        if not phon_word_local then return false end
        local units_to_check = pre_parsed_units_input or
            parse_phonetic_string_to_units_for_epenthesis(
                ugsub(phon_word_local, "ˈ", ""))
        local count_local = 0
        for _, unit_data in ipairs(units_to_check) do
            if unit_data.quality == "vowel" then
                count_local = count_local + 1
            end
        end
        if MINIMAL_DEBUG_ENABLED and
            (umatch(phon_word_local, "^cɑ~N") or
                umatch(phon_word_local, "^ɟɑ~l") or
                umatch(phon_word_local, "^bʲɑ~n") or
                umatch(phon_word_local, "^fɔ~N") or
                umatch(phon_word_local, "^pɔ~L") or
                umatch(phon_word_local, "^t̪rɔ~m") or
                umatch(phon_word_local, "^kɔ~R") or
                umatch(phon_word_local, "^bɔ~rd") or
                umatch(phon_word_local, "^ˈɑ~m")) then
            local unit_details = {};
            for _, u_data_dbg in ipairs(units_to_check) do
                table.insert(unit_details, u_data_dbg.phon .. "(" ..
                    u_data_dbg.quality .. ")")
            end
            debug_print_minimal("EpenthesisAndStrongSonorants",
                "is_likely_monosyllable (TARGETED) for '",
                phon_word_local, "': Units: {",
                table.concat(unit_details, ", "),
                "}, VowelCount: ", count_local, ", Result: ",
                tostring(count_local == 1))
        end
        return count_local == 1
    end
is_likely_monosyllable_phonetic_revised = memoize(
    is_likely_monosyllable_phonetic_revised_impl)

local UNSTRESSED_PREFIXES_ORTHO = {
    "an%-", "droch%-", "mí%-", "do%-", "ró%-", "dea%-", "fíor%-", "sean%-",
    "ath%-", "comh%-", "fo%-", "frith%-", "idir%-", "in%-", "réamh%-", "so%-",
    "tras%-", "mór%-", "ban%-", "cam%-", "fionn%-", "leas%-"
}
local resolve_lenited_consonant_impl -- Declare forward
resolve_lenited_consonant_impl = function(base_phoneme_palatal,
                                          base_phoneme_nonpalatal,
                                          full_match_marker, o_context_str,
                                          original_match_info_tbl, options)
    options = options or {};
    if not original_match_info_tbl or not original_match_info_tbl.ortho_s or
        not original_match_info_tbl.ortho_e then
        debug_print_minimal("ConsonantResolution",
            string.format(
                "DEBUG RLC: Early exit for '%s', no valid omi.",
                full_match_marker))
        -- Fallback to the non-palatal form if context is missing
        return base_phoneme_nonpalatal
    end

    -- Use the powerful, refactored function to determine the quality of the consonant.
    -- This is more robust than doing vowel scanning inside this function.
    local quality_derived = determine_consonant_quality_ortho(o_context_str, original_match_info_tbl.ortho_s,
        original_match_info_tbl.ortho_e)

    debug_print_minimal("ConsonantResolution", string.format(
        "DEBUG RLC for %s in %s (ortho %s): determined quality -> %s",
        full_match_marker, o_context_str,
        usub(o_context_str, original_match_info_tbl.ortho_s, original_match_info_tbl.ortho_e),
        quality_derived))

    -- *** NEW, SIMPLIFIED LOGIC FOR bh/mh/bhf ***
    if options.can_be_w then
        -- This option is passed for MKR_BH, MKR_MH, and MKR_URUF.
        if quality_derived == "slender" then
            -- The slender realization is always vʲ.
            return N("v'") -- base_phoneme_palatal is v'
        else
            -- The broad realization for Connacht is w.
            -- The base_phoneme_nonpalatal passed in from the rules will determine the default.
            -- We now explicitly make it 'w' for all broad bh/mh/bhf.
            return N("w")
        end
    end

    -- Original logic for other lenited consonants (dh, gh, etc.)
    if quality_derived == 'slender' then
        return base_phoneme_palatal
    else
        return base_phoneme_nonpalatal
    end
end
resolve_lenited_consonant = memoize(resolve_lenited_consonant_impl)

irishPhonetics.rules_stage1_preprocess = {
    {
        p = N("^%s*(.-)%s*$"),
        r = function(captured_string)
            if captured_string then
                return ulower(captured_string)
            else
                return ""
            end
        end
    }, { p = N("%s+"), r = " " }, { p = N("�"), r = "" }
}
irishPhonetics.rules_stage1_5_ortho_cluster_simplification = {
    -- Aspirated clusters (already present)
    { p = N("chn"), r = N("chr") },
    { p = N("ghn"), r = N("ghr") },
    { p = N("mhn"), r = N("mhr") },

    -- *** NEW: Add non-aspirated clusters ***
    { p = N("cn"),  r = N("cr") },    -- For cnoc -> croc
    { p = N("gn"),  r = N("gr") },    -- For gnó -> gró
    { p = N("mn"),  r = N("mr") },    -- For mná -> mrá

    -- Existing rules
    { p = N("tn"),  r = N("tr") },
    { p = N("dhg"), r = N("g") },
    { p = N("mhth"),r = N("r") },
    { p = N("bhth"),r = N("r") }   

}
irishPhonetics.rules_stage2_mark_digraphs_and_vocalisation_triggers = {
    {
        p = N("^(d'fh)"), -- Match d'fh only at the beginning of a word
        r = N("MKR_PAST_DFH"),
        ortho_len = 4
    },
    { p = N("eacht"), r = N("MKR_EACHTBRDFX"),     ortho_len = 5 },
    { p = N("eoi"),   r = N("MKR_EOITRIGOLNG"),    ortho_len = 3 },
    { p = N("eói"),   r = N("MKR_EOITRIGOLNGACT"), ortho_len = 3 },
    { p = N("bhf"),   r = N("MKR_URUF"),           ortho_len = 3 },
    { p = N("bp"),    r = N("MKR_URUP"),           ortho_len = 2 },
    { p = N("dt"),    r = N("MKR_URUT"),           ortho_len = 2 },
    { p = N("gc"),    r = N("MKR_URUC"),           ortho_len = 2 },
    { p = N("mb"),    r = N("MKR_URUM"),           ortho_len = 2 },
    { p = N("nd"),    r = N("MKR_URUN"),           ortho_len = 2 },
    { p = N("ng"),    r = N("MKR_URUG"),           ortho_len = 2 },

-- Add these rules to the TOP of the rules_stage2... table

-- Rule for the tsn- cluster
    {
        p = N("^(tsn)"), -- Match 'tsn' only at the beginning of a word
        r = N("MKR_TSN_CLUSTER"),
        ortho_len = 3
    },
    -- Rule for the tsl- cluster
    {
        p = N("^(tsl)"), -- Match 'tsl' only at the beginning of a word
        r = N("MKR_TSL_CLUSTER"),
        ortho_len = 3
    },

    {
        p = N("^(ts)"), -- Match 'ts' only at the beginning of a word.
        r = N("MKR_TS_PREFIX"),
        ortho_len = 2
    },

    {
        p = N("^(MKR_AV_VOC_SLENDER_)(.+)"),
        r = function(m, a, bh_mh, pal_son)
            return N("MKR_AV_VOC_SLENDER_") .. pal_son
        end,
        ortho_len_func = function(m, a, bh_mh, pal_son)
            return ulen(a .. bh_mh .. pal_son)
        end
    },

    { p = N("(" .. ALL_VOWELS_ORTHO_PATTERN .. ")(bh)(" .. ALL_VOWELS_ORTHO_PATTERN .. ")"), r = N("%1MKR_BH_INTERVOCALIC%3"), ortho_len = 2 },
    { p = N("abh"), r = N("MKR_ABH_VOC"), ortho_len = 3 }, -- Existing rule as fallback

    {
        p = N("eidh(#?)$"),
        r = function(m, c1) return N("MKR_EIDHCONNAI") .. (c1 or "") end,
        ortho_len = 4
    }, {
    p = N("aghaidh(#?)$"),
    r = function(m, c1) return N("MKR_AGHAIDHVOCTRGT") .. (c1 or "") end,
    ortho_len = 7
}, {
    p = N("ubh(#?)$"),
    r = function(m, c1) return N("MKR_UVOCBFIN") .. (c1 or "") end,
    ortho_len = 3
}, {
    p = N("ámh(#?)$"),
    r = function(m, c1) return N("MKR_AACTLNGVOCMFIN") .. (c1 or "") end,
    ortho_len = 3
}, { p = N("eabh"), r = N("MKR_EAVOCB"), ortho_len = 4 }, 
{
    p = N("amh(r)"),
    r = function(m, c1) return N("MKR_AVOCMMEDR") .. c1 end,
    ortho_len = 3

}, 

{
    p = N("adh(#?)$"),
    r = function(m, c1) return N("MKR_AVOCDFIN") .. (c1 or "") end,
    ortho_len = 3
}, {
    p = N("eadh(#?)$"),
    r = function(m, c1) return N("MKR_EAVOCDFIN") .. (c1 or "") end,
    ortho_len = 4
}, {
    p = N("agh(#?)$"),
    r = function(m, c1) return N("MKR_AVOCGFIN") .. (c1 or "") end,
    ortho_len = 3
}, {
    p = N("ogh(#?)$"),
    r = function(m, c1) return N("MKR_OVOCGFIN") .. (c1 or "") end,
    ortho_len = 3
}, {
    p = N("obh(#?)$"),
    r = function(m, c1) return N("MKR_OVOCBFIN") .. (c1 or "") end,
    ortho_len = 3
}, {
    p = N("omh(#?)$"),
    r = function(m, c1) return N("MKR_OVOCMFIN") .. (c1 or "") end,
    ortho_len = 3
},
    { p = N("ibh"),   r = N("MKR_IBH_VOCALIZING_ENDING"), ortho_len = 3 }, -- Specific marker
    {
        p = N("imh(e#?)$"),
        r = function(m, c1) return N("MKR_IVOCMMEDEFIN") .. (c1 or "") end,
        ortho_len = 4
    }, {
    p = N("imh(#?)$"),
    r = function(m, c1) return N("MKR_IVOCMFIN") .. (c1 or "") end,
    ortho_len = 3
}, {
    p = N("idh(e#?)$"),
    r = function(m, c1) return N("MKR_IVOCDMEDEFIN") .. (c1 or "") end,
    ortho_len = 4
}, {
    p = N("idh(#?)$"),
    r = function(m, c1) return N("MKR_IVOCDFIN") .. (c1 or "") end,
    ortho_len = 3
}, { p = N("uidh$"), r = N("MKR_UIVOCDFIN"),          ortho_len = 4 }, {
    p = N("uidh(e#?)$"),
    r = function(m, c1) return N("MKR_UIVOCDMEDEFIN") .. (c1 or "") end,
    ortho_len = 5
}, {
    p = N("áth(#?)$"),
    r = function(m, c1)
        return N("MKR_AACTLNGVOCTHSILFIN") .. (c1 or "")
    end,
    ortho_len = 3
}, {
    p = N("aidh(#?)$"),
    r = function(m, c1) return N("MKR_AIDHFINSCHWA") .. (c1 or "") end,
    ortho_len = 4
}, {
    p = N("aigh(#?)$"),
    r = function(m, c1) return N("MKR_AIGHFINSCHWA") .. (c1 or "") end,
    ortho_len = 4
},
    { p = N("eidh"),     r = N("MKR_EIDHVOC"),         ortho_len = 4 }, -- feidhm -> faimʲ
    { p = N("aidh"),     r = N("MKR_AIDHVOC"),         ortho_len = 4 }, -- adhaidh -> ai
    { p = N("amhr"),     r = N("MKR_AMH_R_VOC"),       ortho_len = 4 }, -- amhras -> əuɾˠəsˠ
    { p = N("amha"),     r = N("MKR_AMHAVOC"),         ortho_len = 4 }, -- samhain -> səuɾˠə
    { p = N("ogha"),     r = N("MKR_OGHAVOC"),         ortho_len = 4 }, -- foghlaim -> fəulˠəmʲ
    { p = N("agha"),     r = N("MKR_AGHAVOC"),         ortho_len = 4 }, -- aghaidh -> ai
    { p = N("adha"),     r = N("MKR_ADHAVOC"),         ortho_len = 4 }, -- adharc -> airc
    { p = N("adh(#?)$"), r = N("MKR_ADHFINSCHWA"),     ortho_len = 3 }, -- -adh -> schwa (word-final)
    { p = N("eobh"),     r = N("MKR_EOBH_VOCALIZING"), ortho_len = 4 },

    { p = N("aoi"),      r = N("MKR_AOILNG"),          ortho_len = 3 },
    { p = N("ao"),       r = N("MKR_AOLNG"),           ortho_len = 2 },
    { p = N("ói"),       r = N("MKR_OIACTLNG"),        ortho_len = 2 },
    { p = N("aí"),       r = N("MKR_AIACTLNG"),        ortho_len = 2 },
    { p = N("^fh"),      r = N("MKR_FHINITLEN"),       ortho_len = 2 },
    { p = N("bh"),       r = N("MKR_BH"),              ortho_len = 2 },
    { p = N("mh"),       r = N("MKR_MH"),              ortho_len = 2 },
    { p = N("ch"),       r = N("MKR_CH"),              ortho_len = 2 },
    { p = N("dh"),       r = N("MKR_DH"),              ortho_len = 2 },
    { p = N("gh"),       r = N("MKR_GH"),              ortho_len = 2 },
    { p = N("ph"),       r = N("MKR_PH"),              ortho_len = 2 },
    { p = N("sh"),       r = N("MKR_SH"),              ortho_len = 2 },
    { p = N("th"),       r = N("MKR_TH"),              ortho_len = 2 },
    { p = N("ll"),       r = N("MKR_LL_STR"),          ortho_len = 2 },
    { p = N("nn"),       r = N("MKR_NN_STR"),          ortho_len = 2 },
    { p = N("rr"),       r = N("MKR_RR_STR"),          ortho_len = 2 },
    { p = N("mm"),       r = N("MKR_MM_STR"),          ortho_len = 2 }, {
    p = N("(ˈ" .. SHORT_VOWELS_ORTHO_SINGLE_STR .. ")l(" ..
        ALL_VOWELS_ORTHO_PATTERN .. ")"),
    r = "%1l°%2",
    ortho_len_func = function(m, c1, c2)
        return ulen(c1) + 1 + ulen(c2)
    end
}, {
    p = N("(ˈ" .. SHORT_VOWELS_ORTHO_SINGLE_STR .. ")n(" ..
        ALL_VOWELS_ORTHO_PATTERN .. ")"),
    r = "%1n°%2",
    ortho_len_func = function(m, c1, c2)
        return ulen(c1) + 1 + ulen(c2)
    end

    ,




    -- Special Monophthong/Diphthong Markers
    { p = N("ia"), r = N("MKR_IA_DIPH"),  ortho_len = 2 }, -- bia -> bʲiə
    { p = N("ua"), r = N("MKR_UA_DIPH"),  ortho_len = 2 }, -- fuar -> fˠuəɾˠ
    { p = N("eo"), r = N("MKR_EO_VOWEL"), ortho_len = 2 }, -- beo -> bʲoː
    { p = N("ei"), r = N("MKR_EI_DIPH"),  ortho_len = 2 }, -- ceist -> caiʃtʲ
    { p = N("ai"), r = N("MKR_AI_DIPH"),  ortho_len = 2 }, -- baile -> bˠalʲə
    { p = N("oi"), r = N("MKR_OI_DIPH"),  ortho_len = 2 }, -- oíche -> ai
    { p = N("ui"), r = N("MKR_UI_DIPH"),  ortho_len = 2 }, -- muir -> mˠɪɾʲ
    { p = N("éa"), r = N("MKR_E_ACT_A"),  ortho_len = 2 }, -- béal -> bʲeːlˠ
    { p = N("ío"), r = N("MKR_I_ACT_O"),  ortho_len = 2 }, -- gníomh -> gʲnʲiːvˠ
    { p = N("o"),  r = N("MKR_O_SHT"),    ortho_len = 1 },
    { p = N("u"),  r = N("MKR_U_SHT"),    ortho_len = 1 },
}
}
local palatal_sonorants = { N("n̠ʲ"), N("nʲ"), N("l̠ʲ"), N("lʲ"), N("mʲ") }
local preceding_fricatives = { N("bh"), N("mh") }

-- Helper function to generate the replacement logic
local av_voc_replacement_func = function(m, a, fric, pal_son)
    return N("MKR_AV_VOC_SLENDER_") .. pal_son
end
-- Helper function to generate the ortho_len logic
local av_voc_ortho_len_func = function(m, a, fric, pal_son)
    return ulen(a .. fric .. pal_son)
end

-- Programmatically create a valid rule for each combination
for _, fric in ipairs(preceding_fricatives) do
    for _, sonorant in ipairs(palatal_sonorants) do
        local rule = {
            p = N("(a)(" .. fric .. ")(" .. sonorant .. ")"),
            r = av_voc_replacement_func,
            ortho_len_func = av_voc_ortho_len_func
        }
        table.insert(irishPhonetics.rules_stage2_mark_digraphs_and_vocalisation_triggers, rule)
    end
end

local function process_quality_assignment_on_units(phonetic_units, o_context_str, current_map)
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
            unit.phon = result_consonant -- Modify the unit in place
        end
    end

    return modified_in_pass, phonetic_units
end


irishPhonetics.rules_stage2_5_mark_suffixes = {
    { p = N("(faidh)(#?)$"), r = function(fm, sfx, b) return N("MKR_SUFFIX_FAIDH") .. (b or "") end, ortho_len_func = function(fm, sfx, b) return ulen(sfx) end },
{ p = N("(fad)(#?)$"),   r = function(fm, sfx, b) return N("MKR_SUFFIX_FAD") .. (b or "") end,   ortho_len_func = function(fm, sfx, b) return ulen(sfx) end },
    {
    p = N("(fas)(#?)$"),
    r = function(fm, sfx, b) return N("MKR_SUFFIX_FAS") .. (b or "") end,
    ortho_len_func = function(fm, sfx, b) return ulen(sfx) end
},
    {
        p = N("([" .. CONSONANTS_ORTHO_CHARS_STR .. "])(lainn)(#?)$"),
        r = function(fm, c1, sfx, b)
            return c1 .. N("MKR_SUFFIX_LAINN") .. (b or "")
        end,
        ortho_len_func = function(fm, c1, sfx, b) return ulen(c1 .. sfx) end
    }, {
    p = N("(aigh)(#?)$"),
    r = function(fm, sfx, b) return N("MKR_SUFFIX_IGH") .. (b or "") end,
    ortho_len_func = function(fm, sfx, b) return ulen(sfx) end
}, {
    p = N("(igh)(#?)$"),
    r = function(fm, sfx, b) return N("MKR_SUFFIX_IGH") .. (b or "") end,
    ortho_len_func = function(fm, sfx, b) return ulen(sfx) end
}, {
    p = N("(eoireacht)(a#?)$"),
    r = function(fm, sfx, b)
        return N("MKR_SUFFIX_OIRƏXTA") .. (b or "")
    end,
    ortho_len_func = function(fm, sfx, b) return ulen(sfx) end
}, {
    p = N("(aíocht)(a#?)$"),
    r = function(fm, sfx, b)
        return N("MKR_SUFFIX_IƏXTA") .. (b or "")
    end,
    ortho_len_func = function(fm, sfx, b) return ulen(sfx) end
}, {
    p = N("(úint)(#?)$"),
    r = function(fm, sfx, b)
        return N("MKR_SUFFIX_UUNTJ") .. (b or "")
    end,
    ortho_len_func = function(fm, sfx, b) return ulen(sfx) end
}, {
    p = N("(úil)(#?)$"),
    r = function(fm, sfx, b) return N("MKR_SUFFIX_UULJ") .. (b or "") end,
    ortho_len_func = function(fm, sfx, b) return ulen(sfx) end
}, {
    p = N("(óir)(#?)$"),
    r = function(fm, sfx, b)
        return N("MKR_SUFFIX_OOIRJ") .. (b or "")
    end,
    ortho_len_func = function(fm, sfx, b) return ulen(sfx) end
}, {
    p = N("(ín)(#?)$"),
    r = function(fm, sfx, b) return N("MKR_SUFFIX_IINJ") .. (b or "") end,
    ortho_len_func = function(fm, sfx, b) return ulen(sfx) end
}, {
    p = N("(íonn)(#?)$"),
    r = function(fm, sfx, b)
        return N("MKR_SUFFIX_IIN_VERB") .. (b or "")
    end,
    ortho_len_func = function(fm, sfx, b) return ulen(sfx) end
}, {
    p = N("(eann)(#?)$"),
    r = function(fm, sfx, b)
        return N("MKR_SUFFIX_ƏN_VERB") .. (b or "")
    end,
    ortho_len_func = function(fm, sfx, b) return ulen(sfx) end
}, {
    p = N("(ann)(#?)$"),
    r = function(fm, sfx, b)
        return N("MKR_SUFFIX_ƏN_VERB") .. (b or "")
    end,
    ortho_len_func = function(fm, sfx, b) return ulen(sfx) end
}, {
    p = N("(ach)(#?)$"),
    r = function(fm, sfx, b) return N("MKR_SUFFIX_ƏX") .. (b or "") end,
    ortho_len_func = function(fm, sfx, b) return ulen(sfx) end
}, {
    p = N("(each)(#?)$"),
    r = function(fm, sfx, b) return N("MKR_SUFFIX_ƏX") .. (b or "") end,
    ortho_len_func = function(fm, sfx, b) return ulen(sfx) end
}, {
    p = N("(aidh)(#?)$"),
    r = function(fm, sfx, b) return N("MKR_SUFFIX_IGH") .. (b or "") end,
    ortho_len_func = function(fm, sfx, b) return ulen(sfx) end
}, {
    p = N("(aí)(#?)$"),
    r = function(fm, sfx, b) return N("MKR_SUFFIX_A_II") .. (b or "") end,
    ortho_len_func = function(fm, sfx, b) return ulen(sfx) end
}, {
    p = N("(b[oaá]l)(adh)(#?)$"),    r = function(fm, stem, sfx, b)       return stem .. N("MKR_SUFFIX_ADH_CONN_UU") .. (b or "")    end,
    ortho_len_func = function(fm, stem, sfx, b) return ulen(sfx) end
}, {
    p = N("(adh)(#?)$"),
    r = function(fm, sfx, b)
        return N("MKR_SUFFIX_ADH_VAR") .. (b or "")
    end,
    ortho_len_func = function(fm, sfx, b) return ulen(sfx) end
}, {
    p = N("(eadh)(#?)$"),
    r = function(fm, sfx, b)
        return N("MKR_SUFFIX_ADH_VAR") .. (b or "")
    end,
    ortho_len_func = function(fm, sfx, b) return ulen(sfx) end
}, {
    p = N("(áil)(#?)$"),
    r = function(fm, sfx, b) return N("MKR_SUFFIX_AALJ") .. (b or "") end,
    ortho_len_func = function(fm, sfx, b) return ulen(sfx) end
}, {
    p = N("(fidís)(#?)$"),
    r = function(fm, sfx, b)
        return N("MKR_SUFFIX_FIDIIS") .. (b or "")
    end,
    ortho_len_func = function(fm, sfx, b) return ulen(sfx) end
}, {
    p = N("(fidh)(#?)$"),
    r = function(fm, sfx, b) return N("MKR_SUFFIX_FIDH") .. (b or "") end,
    ortho_len_func = function(fm, sfx, b) return ulen(sfx) end
}, {
    p = N("(fimid)(#?)$"),
    r = function(fm, sfx, b)
        return N("MKR_SUFFIX_FIMID") .. (b or "")
    end,
    ortho_len_func = function(fm, sfx, b) return ulen(sfx) end
}, {
    p = N("(fimis)(#?)$"),
    r = function(fm, sfx, b)
        return N("MKR_SUFFIX_FIMIS") .. (b or "")
    end,
    ortho_len_func = function(fm, sfx, b) return ulen(sfx) end
}, {
    p = N("(ímid)(#?)$"),
    r = function(fm, sfx, b)
        return N("MKR_SUFFIX_IIMID") .. (b or "")
    end,
    ortho_len_func = function(fm, sfx, b) return ulen(sfx) end
}, {
    p = N("(inn)(#?)$"),
    r = function(fm, sfx, b)
        return N("MKR_SUFFIX_INN_VERB") .. (b or "")
    end,
    ortho_len_func = function(fm, sfx, b) return ulen(sfx) end
}, {
    p = N("(mid)(#?)$"),
    r = function(fm, sfx, b)
        return N("MKR_SUFFIX_MID_VERB") .. (b or "")
    end,
    ortho_len_func = function(fm, sfx, b) return ulen(sfx) end
}, {
    p = N("(ós)(#?)$"),
    r = function(fm, sfx, b) return N("MKR_SUFFIX_OOS") .. (b or "") end,
    ortho_len_func = function(fm, sfx, b) return ulen(sfx) end
}, {
    p = N("(ófá)(#?)$"),
    r = function(fm, sfx, b)
        return N("MKR_SUFFIX_OOFAA") .. (b or "")
    end,
    ortho_len_func = function(fm, sfx, b) return ulen(sfx) end
},
{
    p = N("(feá)(#?)$"),
    r = function(fm, sfx, b) return N("MKR_SUFFIX_FEA") .. (b or "") end,
    ortho_len_func = function(fm, sfx, b) return ulen(sfx) end
},

 {
    p = N("(óidh)(#?)$"),
    r = function(fm, sfx, b)
        return N("MKR_SUFFIX_OOIJ_VERB") .. (b or "")
    end,
    ortho_len_func = function(fm, sfx, b) return ulen(sfx) end
}, {
    p = N("(tá)(#?)$"),
    r = function(fm, sfx, b)
        return N("MKR_SUFFIX_TAA_ACT") .. (b or "")
    end,
    ortho_len_func = function(fm, sfx, b) return ulen(sfx) end
}, {
    p = N("(tí)(#?)$"),
    r = function(fm, sfx, b)
        return N("MKR_SUFFIX_TII_ACT") .. (b or "")
    end,
    ortho_len_func = function(fm, sfx, b) return ulen(sfx) end
}, {
    p = N("(fí)(#?)$"),
    r = function(fm, sfx, b)
        return N("MKR_SUFFIX_FII_ACT") .. (b or "")
    end,
    ortho_len_func = function(fm, sfx, b) return ulen(sfx) end
}, {
    p = N("(ui)(gthe)(#?)$"),
    r = function(fm, ui_part, sfx, b)
        return ui_part .. N("MKR_SUFFIX_IGTHE_CONN") .. (b or "")
    end,
    ortho_len_func = function(fm, ui_part, sfx, b) return ulen(sfx) end
}, {
    p = N("(ithe)(#?)$"),
    r = function(fm, sfx, b)
        return N("MKR_SUFFIX_IHƏ_GEN") .. (b or "")
    end,
    ortho_len_func = function(fm, sfx, b) return ulen(sfx) end
}
}

irishPhonetics.rules_stage3_1_marker_resolution = {}
do
    local rules = {

{ p = N("MKR_BH_INTERVOCALIC"), r = N("w") }, -- Realizes as the consonant [w]

        {
            p = N("MKR_CH"),
            r = function(fm, ocs, omi)
                -- This function correctly resolves lenited 'ch'.
        
                -- Robustly find the start of the next vowel group after the 'ch'
                local scan_idx = omi.ortho_e + 1
                
                -- Step 1: Skip over any consonants that are part of the initial cluster (e.g., the 'n' in 'chnáimh')
                while scan_idx <= ulen(ocs) do
                    local char = usub(ocs, scan_idx, scan_idx)
                    if umatch(char, "[" .. CONSONANTS_ORTHO_CHARS_STR .. "]") then
                        scan_idx = scan_idx + 1
                    else
                        break -- Found a vowel or end of string
                    end
                end
        
                -- Step 2: Now that we're at the vowel, extract the full vowel group
                local next_v_group = ""
                while scan_idx <= ulen(ocs) do
                    local char = usub(ocs, scan_idx, scan_idx)
                    if umatch(char, ALL_VOWELS_ORTHO_PATTERN) then
                        next_v_group = next_v_group .. char
                        scan_idx = scan_idx + 1
                    else
                        break -- Stop when we hit the next consonant
                    end
                end
        
                -- Step 3: Extract the following consonant cluster for the 'ea' rule context
                local following_cons_cluster = ""
                while scan_idx <= ulen(ocs) do
                    local char = usub(ocs, scan_idx, scan_idx)
                    if umatch(char, "[" .. CONSONANTS_ORTHO_CHARS_STR .. "]") then
                        following_cons_cluster = following_cons_cluster .. char
                        scan_idx = scan_idx + 1
                    else
                        break
                    end
                end
        
                -- Use your existing, powerful quality determination function
                local quality = get_ortho_vowel_quality_implication_from_char_or_group(next_v_group, true, following_cons_cluster)
                
                debug_print_minimal("ConsonantResolution", string.format("Resolving <ch> in '%s'. Found vowel group: '%s'. Determined quality -> %s",
                    ocs, next_v_group, tostring(quality)))
        
                if quality == 'slender' then
                    return N("ç")
                else
                    -- If quality is broad or nil (e.g., word ends in 'ch'), default to broad.
                    return N("x")
                end
            end
        },


        {
            p = N("MKR_PAST_DFH"),
            r = function(fm, ocs, omi)
                -- This function correctly models the past tense d'fh- prefix.
                -- The 'fh' is silent. The 'd'' is pronounced as /d/.
                -- We determine the quality of the /d/ from the vowel that follows 'd'fh'.
                -- omi.ortho_e points to the 'h' of 'd'fh'. We check the next character.
                local quality = determine_consonant_quality_ortho(ocs, omi.ortho_e + 1, omi.ortho_e + 1)
                
                if quality == 'slender' then
                    -- For slender contexts like d'fheicinn, the result is /dʲ/.
                    -- We return the internal representation 'd''.
                    return N("d'")
                else
                    -- For broad contexts, the result is /d̪ˠ/.
                    -- We return the internal representation 'd'.
                    return N("d")
                end
            end
        },


        -- Eclipsis

        {
            p = N("MKR_URUF"), -- This marker represents orthographic "bhf"
            r = function(fm, ocs, omi)
                -- The 'f' is silent. The 'bh' is pronounced as a lenited 'b'.
                -- We need to determine the quality of this lenited 'b' based on
                -- the vowel that FOLLOWS the "bhf" sequence.
                -- omi.ortho_e points to the 'f' of "bhf". We check the character after it.
                local quality = determine_consonant_quality_ortho(ocs, omi.ortho_e + 1, omi.ortho_e + 1)
                
                if quality == 'slender' then
                    -- Slender context: bhf -> /vʲ/ (internal representation 'v'')
                    return N("v'")
                else
                    -- Broad context: bhf -> /vˠ/ (internal representation 'v')
                    -- The further weakening to [w] before a vowel in Connacht
                    -- should be handled by a LATER, specific rule if desired,
                    -- or by the existing resolve_lenited_consonant logic if called appropriately.
                    -- For now, the core sound is /v/.
                    return N("v")
                end
            end
        },
        {
            p = N("MKR_TSN_CLUSTER"),
            r = function(fm, ocs, omi)
                -- This cluster becomes a /tr/ cluster.
                -- We will output the internal representation 'tr'.
                -- The quality assignment stage will correctly make it 't'r'' or 'tr'.
                return N("tr")
            end
        },
        {
            p = N("MKR_TSL_CLUSTER"),
            r = function(fm, ocs, omi)
                -- This cluster becomes a /tl/ cluster.
                -- We will output the internal representation 'tl'.
                return N("tl")
            end
        },
        {
            p = N("MKR_TS_PREFIX"),
            r = function(fm, ocs, omi)
                -- This function now correctly models the elision of 's' after the t-prefix.
        
                -- To determine the quality of the resulting 't', we must look at the
                -- vowel or consonant that comes AFTER the original 's'.
                -- omi.ortho_e points to the 's' in the original "ts" sequence.
                -- So, we check the quality of the character at the next position.
                local quality = determine_consonant_quality_ortho(ocs, omi.ortho_e + 1, omi.ortho_e + 1)
                
                if quality == 'slender' then
                    -- For slender contexts like 'tsléibh', the result is /tʲ/.
                    -- The 's' is deleted. We return our internal marker for a slender 't'.
                    return N("t'")
                else
                    -- For broad contexts like 'tsá' and 'tsál', the result is /t̪ˠ/.
                    -- The 's' is deleted. We return our internal representation for a broad 't'.
                    return N("t")
                end
            end
        },
        { p = N("MKR_URUP"),      r = N("b") },
        { p = N("MKR_URUT"),      r = N("d") },
        { p = N("MKR_URUC"),      r = N("g") },
        { p = N("MKR_URUM"),      r = N("m") },
        { p = N("MKR_URUN"),      r = N("n") },
        { p = N("MKR_URUG"),      r = N("ŋ") },
        -- Lenition
        { p = N("MKR_FHINITLEN"), r = "" },
        {
            p = N("MKR_BH"),
            r = function(fm, ocs, omi)
                return resolve_lenited_consonant(N("v'"), N("w"), fm, ocs, omi,
                    { can_be_w = true })
            end
        },
        {
            p = N("MKR_MH"),
            r = function(fm, ocs, omi)
                return resolve_lenited_consonant(N("v'"), N("w"), fm, ocs, omi,
                    { can_be_w = true })
            end
        },
        { p = N("MKR_DH"), r = function(fm, ocs, omi) return resolve_lenited_consonant(N("j"), N("ɣ"), fm, ocs, omi) end },
        { p = N("MKR_GH"), r = function(fm, ocs, omi) return resolve_lenited_consonant(N("j"), N("ɣ"), fm, ocs, omi) end },
        { p = N("MKR_PH"), r = function(fm, ocs, omi) return resolve_lenited_consonant(N("f'"), N("f"), fm, ocs, omi) end },
        {
            p = N("MKR_SH"),
            r = function(fm, ocs, omi)
                if not omi or not omi.ortho_e then return N("h") end
                local scan_idx = omi.ortho_e + 1
                local next_v_group = ""
                while scan_idx <= ulen(ocs) do
                    local char = usub(ocs, scan_idx, scan_idx)
                    if umatch(char, "[" .. CONSONANTS_ORTHO_CHARS_STR .. "]") then
                        scan_idx = scan_idx + 1
                    else
                        break
                    end
                end
                while scan_idx <= ulen(ocs) do
                    local char = usub(ocs, scan_idx, scan_idx)
                    if umatch(char, ALL_VOWELS_ORTHO_PATTERN) then
                        next_v_group = next_v_group .. char
                        scan_idx = scan_idx + 1
                    else
                        break
                    end
                end
                local quality = get_ortho_vowel_quality_implication_from_char_or_group(next_v_group, true)
                if quality == 'slender' then
                    return N("h")
                else -- broad or nil
                    return N("ç")
                end
            end
        },
        {
            p = N("MKR_TH"),
            r = function(fm, ocs, omi)
                if not omi or not omi.ortho_e then return N("h") end
                local scan_idx = omi.ortho_e + 1
                local next_v_group = ""
                while scan_idx <= ulen(ocs) do
                    local char = usub(ocs, scan_idx, scan_idx)
                    if umatch(char, "[" .. CONSONANTS_ORTHO_CHARS_STR .. "]") then
                        scan_idx = scan_idx + 1
                    else
                        break
                    end
                end
                while scan_idx <= ulen(ocs) do
                    local char = usub(ocs, scan_idx, scan_idx)
                    if umatch(char, ALL_VOWELS_ORTHO_PATTERN) then
                        next_v_group = next_v_group .. char
                        scan_idx = scan_idx + 1
                    else
                        break
                    end
                end
                local quality = get_ortho_vowel_quality_implication_from_char_or_group(next_v_group, true)
                if quality == 'slender' then
                    return N("h")
                else -- broad or nil
                    return N("ç")
                end
            end
        },
        -- Strong Sonorants
        {
            p = N("MKR_LL_STR"),
            r = function(fm, ocs, omi)
                local q = determine_consonant_quality_ortho(ocs, omi.ortho_s, omi.ortho_e); return q == 'slender' and
                    ZZZ_L_STR_PAL_PHON or ZZZ_L_STR_BRD_PHON
            end
        },
        {
            p = N("MKR_NN_STR"),
            r = function(fm, ocs, omi)
                local q = determine_consonant_quality_ortho(ocs, omi.ortho_s, omi.ortho_e); return q == 'slender' and
                    ZZZ_N_STR_PAL_PHON or ZZZ_N_STR_BRD_PHON
            end
        },
        { p = N("MKR_RR_STR"), r = function(fm, ocs, omi) return resolve_lenited_consonant(N("R'"), N("R"), fm, ocs, omi) end },
        { p = N("MKR_MM_STR"), r = function(fm, ocs, omi) return resolve_lenited_consonant(N("M'"), N("M"), fm, ocs, omi) end },
        -- Neutral Sonorants
        { p = N("l°"),         r = N("l_neutral_") },
        { p = N("n°"),         r = N("n_neutral_") },
        {
            p = N("c"), -- Find the orthographic 'c'
            r = function(fm, ocs, omi)
                -- 1. DECIDE: Check the quality from the original orthography
                local quality = determine_consonant_quality_ortho(ocs, omi.ortho_s, omi.ortho_e)
                -- 2. ACT: Immediately return the correct, unambiguous phonetic symbol
                if quality == 'slender' then
                    return N("k'") -- Return the IPA symbol for a PALATAL stop
                else
                    return N("k")  -- Return the IPA symbol for a VELAR stop
                end
            end
        }
    }
    irishPhonetics.rules_stage3_1_marker_resolution = rules
end

irishPhonetics.rules_stage3_5_consonant_assimilation = {
    { p = N("(d')(f')"), r = N("t'%2") }
}
irishPhonetics.rules_stage4_0_specific_ortho_to_temp_marker = {
    {
        p = N("^(ˈ?(?:[^" .. ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR .. "]*))a(" ..
            N("MKR_AVOCMMEDR") .. ")(s[" ..
            ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR .. "]?)"),
        r = "%1" .. N("MKR_TEMP_CONN_AU") .. "%3"
    }, {
    p = N("^(ˈ?(?:[^" .. ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR ..
        "]*))MKR_EAVOCB(r[" .. ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR ..
        "]?)"),
    r = "%1" .. N("MKR_TEMP_CONN_AU") .. "%2"
}, {
    p = N("(" .. ANY_SHORT_VOWEL_PHONETIC_CHARS_STR .. "])(" ..
        N("MKR_AVOCMMEDR") .. ")"),
    r = "%1" .. N("MKR_VOC_AMH_MED_R")
}, {
    p = N("(" .. ANY_SHORT_VOWEL_PHONETIC_CHARS_STR .. "])(" ..
        N("MKR_EAVOCB") .. ")"),
    r = "%1" .. N("MKR_VOC_EABH_MED_R")
}, {
    p = N("^(ˈ?)(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "*'?)" .. "ea(" ..
        N("MKR_EACHTBRDFX") .. ")$"),
    r = "%1%2" .. N("MKR_EA_BRD_SHT_PRE_CHT") .. "%3"
}, -- In your rules table, REPLACE the existing MKR_CH rule with this one.
{
    p = N("MKR_CH"),
    r = function(fm, ocs, omi)
        -- This function correctly resolves lenited 'ch'.

        -- Robustly find the start of the next vowel group after the 'ch'
        local scan_idx = omi.ortho_e + 1
        
        -- Step 1: Skip over any consonants that are part of the initial cluster (e.g., the 'n' in 'chnáimh')
        while scan_idx <= ulen(ocs) do
            local char = usub(ocs, scan_idx, scan_idx)
            if umatch(char, "[" .. CONSONANTS_ORTHO_CHARS_STR .. "]") then
                scan_idx = scan_idx + 1
            else
                break -- Found a vowel or end of string
            end
        end

        -- Step 2: Now that we're at the vowel, extract the full vowel group
        local next_v_group = ""
        while scan_idx <= ulen(ocs) do
            local char = usub(ocs, scan_idx, scan_idx)
            if umatch(char, ALL_VOWELS_ORTHO_PATTERN) then
                next_v_group = next_v_group .. char
                scan_idx = scan_idx + 1
            else
                break -- Stop when we hit the next consonant
            end
        end

        -- Step 3: Extract the following consonant cluster for the 'ea' rule context
        local following_cons_cluster = ""
        while scan_idx <= ulen(ocs) do
            local char = usub(ocs, scan_idx, scan_idx)
            if umatch(char, "[" .. CONSONANTS_ORTHO_CHARS_STR .. "]") then
                following_cons_cluster = following_cons_cluster .. char
                scan_idx = scan_idx + 1
            else
                break
            end
        end

        -- Use your existing, powerful quality determination function
        local quality = get_ortho_vowel_quality_implication_from_char_or_group(next_v_group, true, following_cons_cluster)
        
        debug_print_minimal("ConsonantResolution", string.format("Resolving <ch> in '%s'. Found vowel group: '%s'. Determined quality -> %s",
            ocs, next_v_group, tostring(quality)))

        if quality == 'slender' then
            return N("ç")
        else
            -- If quality is broad or nil (e.g., word ends in 'ch'), default to broad.
            return N("x")
        end
    end
},

    {
        p = N("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "*'?)" .. "ea(ŋ)"),
        r = function(full_match, c_part, ng_cap, o_context_str,
                     original_match_info_tbl)
            local ortho_n_start_idx = original_match_info_tbl.ortho_e -
                ulen(ng_cap) + 1;
            local quality_of_n = determine_consonant_quality_ortho(
                o_context_str, ortho_n_start_idx,
                ortho_n_start_idx);
            if quality_of_n == "palatal" then
                return (c_part or "") .. N("MKR_EA_SLN_PRE_NG") .. ng_cap
            else
                return (c_part or "") .. N("MKR_EA_BRD_PRE_NG") .. ng_cap
            end
        end,
        use_original_context_for_rules = true
    }, {
    p = N("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "*'?)" .. "ea(" ..
        ZZZ_N_STR_PAL_PHON .. ")$"),
    r = "%1" .. N("MKR_EA_SLN_PRE_NN") .. "%2"
}, {
    p = N("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "*'?)" .. "ea(" ..
        ZZZ_N_STR_BRD_PHON .. ")$"),
    r = "%1" .. N("MKR_EA_BRD_PRE_NN") .. "%2"
}, {
    p = N("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "*'?)" .. "ea(" ..
        ZZZ_N_STR_BRD_PHON .. ")([^'])"),
    r = "%1" .. N("MKR_EA_BRD_PRE_NN") .. "%2%3"
}, {
    p = N("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "*'?)" .. "ea(r')"),
    r = "%1" .. N("MKR_EA_SLN_PRE_RPRIME") .. "%2"
}, {
    p = N("((?:[" .. ANY_CONSONANT_PHONETIC_RAW_CHARS_STR .. "]'?)*)iu(" ..
        N("MKR_CH") .. ")"),
    r = "%1" .. N("MKR_IU_SLN_FIN_PRE_CH") .. "%2"
}, {
    p = N("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "*'?)" .. "ea(r)"),
    r = "%1" .. N("MKR_EA_BRD_PRE_R") .. "%2"
}, {
    p = N("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "*'?)" .. "ea(n)$"),
    r = function(full_match, c_part, n_cap, o_context_str,
                 original_match_info_tbl)
        local n_quality = determine_consonant_quality_ortho(o_context_str,
            original_match_info_tbl.ortho_s +
            ulen(
                c_part or
                "") +
            2,
            original_match_info_tbl.ortho_s +
            ulen(
                c_part or
                "") +
            2);
        if n_quality == "palatal" then
            return (c_part or "") .. N("MKR_EA_SLN_PRE_N") .. (n_cap or "")
        else
            return (c_part or "") .. N("MKR_EA_BRD_PRE_N") .. (n_cap or "")
        end
    end,
    use_original_context_for_rules = true
}, {
    p = N("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "*'?)" .. "ea(n)([^" ..
        ALL_VOWELS_ORTHO_CHARS_STR .. "°%-bhfpgcdtmls" ..
        ANY_CONSONANT_PHONETIC_RAW_CHARS_STR .. "'])"),
    r = function(full_match, c_part, n_cap, next_char_phon, o_context_str,
                 original_match_info_tbl)
        local n_quality = determine_consonant_quality_ortho(o_context_str,
            original_match_info_tbl.ortho_s +
            ulen(
                c_part or
                "") +
            2,
            original_match_info_tbl.ortho_s +
            ulen(
                c_part or
                "") +
            2);
        if n_quality == "palatal" then
            return
                (c_part or "") .. N("MKR_EA_SLN_PRE_N") .. (n_cap or "") ..
                (next_char_phon or "")
        else
            return
                (c_part or "") .. N("MKR_EA_BRD_PRE_N") .. (n_cap or "") ..
                (next_char_phon or "")
        end
    end,
    use_original_context_for_rules = true
}, { p = N("io"), r = N("MKR_IO_SHT_TRGT") }
}
    -- REPLACE your existing rules_stage4_0_1_resolve_ch_marker with this:
irishPhonetics.rules_stage4_0_1_resolve_ch_marker = {
    {
        p = N("MKR_CH"),
        r = function(fm, ocs, omi_ch) -- omi_ch is the original_match_info for "ch"
            if not omi_ch or not omi_ch.ortho_s or not omi_ch.ortho_e then
                debug_print_minimal("Stage4_0_1", "MKR_CH: Missing omi_ch, defaulting to x. ocs: " .. ocs)
                return N("x")
            end

            -- *** START OF ROBUST VOWEL SCANNER (from previous correct answer) ***
            local scan_idx = omi_ch.ortho_e + 1
            
            -- Step 1: Skip over any consonants that are part of the initial cluster
            while scan_idx <= ulen(ocs) do
                local char = usub(ocs, scan_idx, scan_idx)
                if umatch(char, "[" .. CONSONANTS_ORTHO_CHARS_STR .. "]") then
                    scan_idx = scan_idx + 1
                else
                    break -- Found a vowel or end of string
                end
            end

            -- Step 2: Extract the full vowel group
            local next_v_group = ""
            while scan_idx <= ulen(ocs) do
                local char = usub(ocs, scan_idx, scan_idx)
                if umatch(char, ALL_VOWELS_ORTHO_PATTERN) then
                    next_v_group = next_v_group .. char
                    scan_idx = scan_idx + 1
                else
                    break -- Stop when we hit the next consonant
                end
            end

            -- Step 3: Extract the following consonant cluster for the 'ea' rule context
            local following_cons_cluster = ""
            while scan_idx <= ulen(ocs) do
                local char = usub(ocs, scan_idx, scan_idx)
                if umatch(char, "[" .. CONSONANTS_ORTHO_CHARS_STR .. "]") then
                    following_cons_cluster = following_cons_cluster .. char
                    scan_idx = scan_idx + 1
                else
                    break
                end
            end
            -- *** END OF ROBUST VOWEL SCANNER ***

            local quality_ch = get_ortho_vowel_quality_implication_from_char_or_group(next_v_group, true, following_cons_cluster)
            
            debug_print_minimal("Stage4_0_1_Resolve_CH_Marker",
                string.format("Resolving <ch> in '%s'. Found vowel group: '%s'. Determined quality -> %s",
                ocs, next_v_group, tostring(quality_ch)))

            -- Determine if 'ch' is phonetically initial in the original orthographic word
            local is_phonetically_initial_ch = false
            if omi_ch.ortho_s == 1 then
                is_phonetically_initial_ch = true
            elseif omi_ch.ortho_s == 2 and usub(ocs, 1, 1) == N("ˈ") then
                is_phonetically_initial_ch = true
            end

            if quality_ch == 'slender' then
                -- Hickey II.1.9.9.1: Medial /xj/ can debuccalise to /h/ or delete.
                -- For simplicity and general Connacht, initial slender ch is /ç/, medial is /h/.
                return is_phonetically_initial_ch and N("ç") or N("h")
            else
                -- If quality is broad or nil (e.g., word ends in 'ch'), it's /x/.
                return N("x")
            end
        end
    }

}

irishPhonetics.rules_stage4_1_vocmark_to_temp_marker = {}
irishPhonetics.rules_stage4_2_long_vowels_ortho_to_temp_marker = {
      -- NEW: High-priority rules for long vowel digraphs to prevent hiatus errors.
    -- These must run before the single-letter rules.
    { p = N("éa"), r = N("MKR_E_ACT_LNG"), ortho_len = 2 },
    { p = N("ío"), r = N("MKR_I_ACT_LNG"), ortho_len = 2 },
    -- CORRECTED RULE for "iú": It now correctly maps to the long 'u' marker.
    { p = N("iú"), r = N("MKR_U_ACT_LNG"), ortho_len = 2 },
    { p = N("ae"), r = N("MKR_E_ACT_LNG"), ortho_len = 2 },
    { p = N("eo"), r = N("MKR_O_ACT_LNG"), ortho_len = 2 },
    { p = N("uí"), r = N("MKR_UI_LONG"),   ortho_len = 2 },
    { p = N("úi"), r = N("MKR_U_ACT_LNG"),   ortho_len = 2 },


    -- Existing rules for other digraphs and single accented vowels
    { p = N("ái"), r = N("MKR_A_I_ACT_LNG_RSLV") },
    { p = N("éi"), r = N("MKR_E_ACT_I_LNG") },
    { p = N("á"),  r = N("MKR_A_ACT_LNG") },
    { p = N("é"),  r = N("MKR_E_ACT_LNG") },
    { p = N("í"),  r = N("MKR_I_ACT_LNG") },
    { p = N("ó"),  r = N("MKR_O_ACT_LNG") },
    { p = N("ú"),  r = N("MKR_U_ACT_LNG") },
    { p = N("MKR_AIACTLNG"), r = N("MKR_A_I_ACT_LNG_RSLV") }
    -- NOTE: The incorrect rule for "iú" -> "MKR_I_U_SHT" has been removed and replaced above.
}
irishPhonetics.rules_stage4_3_diphthongs_ortho_to_temp_marker = {
    { p = N("MKR_EOITRIGOLNG"),    r = N("MKR_EOI_TRIG_O_LNG") },
    { p = N("MKR_EOITRIGOLNGACT"), r = N("MKR_EOI_TRIG_O_LNG_ACT") }, {
    p = N("(b)(ai)(" .. ZZZ_N_STR_PAL_PHON .. ")(e)"),
    r = function(fm, cap_b, cap_ai, cap_nnn, cap_e)
        return cap_b .. N("MKR_A_FRM_BAINNE") .. cap_nnn .. cap_e
    end
}, { p = N("éa"), r = N("MKR_EA_COMPOUND_LONG_E") },
    { p = N("ae"), r = N("MKR_AE_SEQ") }, { p = N("ia"), r = N("MKR_IA_DIPH") },
    { p = N("ua"), r = N("MKR_UA_DIPH") }, { p = N("ai"),
    r = N("MKR_AI_DIPH") },
    { p = N("ei"), r = N("MKR_EI_DIPH") }, { p = N("oi"), r = N("MKR_OI_DIPH") },
    { p = N("ui"), r = N("MKR_UI_DIPH") }, { p = N("au"), r = N("MKR_AU_DIPH") },
    { p = N("ou"), r = N("MKR_OU_DIPH") }, { p = N("eo"), r = N("MKR_EO_SEQ") }
}
irishPhonetics.rules_stage4_4_resolve_temp_vowel_markers = {
    { p = N("MKR_SUFFIX_FEA"),    r = N("hɑː") },      -- For bheifeá -> [vʲɛhɑː]

    { p = N("MKR_SUFFIX_FAIDH"), r = N("ə") }, -- or [iː] for some dialects
    { p = N("MKR_SUFFIX_FAD"),   r = N("əd̪ˠ") },
    { p = N("MKR_ABH_VOC"), r = N("au") },
    { p = N("MKR_SUFFIX_FAS"), r = N("həsˠ") },
    { p = N("MKR_SUFFIX_LAINN"), r = N("lən̠ʲ") },
    { p = N("MKR_EOBH_VOCALIZING"), r = N("ɔw") },


    { p = N("MKR_SUFFIX_OIRƏXTA"), r = N("oːɾʲəxt̪ə") },
    { p = N("MKR_SUFFIX_IƏXTA"), r = N("iəxt̪ə") },
    { p = N("MKR_SUFFIX_ƏX"), r = N("əx") },
    { p = N("MKR_SUFFIX_IGH"), r = N("iː") },
    { p = N("MKR_SUFFIX_A_II"), r = N("iː") },
    { p = N("MKR_SUFFIX_ADH_VAR"), r = N("ə") },
    { p = N("MKR_SUFFIX_ADH_CONN_UU"), r = N("uː") },
    { p = N("MKR_SUFFIX_AALJ"), r = N("ɑːlʲ") },
    { p = N("MKR_SUFFIX_UULJ"), r = N("uːlʲ") },
    { p = N("MKR_SUFFIX_OOIRJ"), r = N("oːɾʲ") },
    { p = N("MKR_SUFFIX_IINJ"), r = N("iːnʲ") },
    { p = N("MKR_SUFFIX_ƏN_VERB"), r = N("ən̪ˠ") },
    { p = N("MKR_SUFFIX_IIN_VERB"), r = N("iːn̪ˠ") },
    { p = N("MKR_SUFFIX_UUNTJ"), r = N("uːn̠ʲtʲ") },
    { p = N("MKR_SUFFIX_FIDIIS"), r = N("hədʲiːʃ") },
    { p = N("MKR_SUFFIX_FIDH"), r = N("iː") },
    { p = N("MKR_SUFFIX_FIMID"), r = N("həmʲədʲ") },
    { p = N("MKR_SUFFIX_FIMIS"), r = N("həmʲəʃ") },
    { p = N("MKR_SUFFIX_IIMID"), r = N("iːmʲədʲ") },
    { p = N("MKR_SUFFIX_INN_VERB"), r = N("ən̠ʲ") },
    { p = N("MKR_SUFFIX_MID_VERB"), r = N("mʲədʲ") },
    { p = N("MKR_SUFFIX_OOS"), r = N("oːsˠ") },
    { p = N("MKR_SUFFIX_OOFAA"), r = N("oːhɑː") },
    { p = N("MKR_SUFFIX_OOIJ_VERB"), r = N("oːj") },
    { p = N("MKR_SUFFIX_TAA_ACT"), r = N("t̪ˠɑː") },
    { p = N("MKR_SUFFIX_TII_ACT"), r = N("tʲiː") },
    { p = N("MKR_SUFFIX_FII_ACT"), r = N("fʲiː") },
    { p = N("MKR_SUFFIX_IGTHE_CONN"), r = N("ɪctʲçi") },
    { p = N("MKR_SUFFIX_IHƏ_GEN"), r = N("ɪhə") },
    { p = N("MKR_EOI_TRIG_O_LNG"), r = N("oː") },
    { p = N("MKR_EOI_TRIG_O_LNG_ACT"), r = N("oː") },
    { p = N("MKR_EIDHCONNAI(#?)"), r = N("ei%1") }, {
    p = N("^(MKR_AV_VOC_SLENDER_)(.+)"), -- Captures the prefix and the sonorant part
    r = function(m, prefix, pal_son)
        return N("əu") .. pal_son
    end
}, { p = N("MKR_UVOCBFIN(#?)"), r = N("uː%1") },
    { p = N("MKR_AACTLNGVOCMFIN(#?)"), r = N("ɑːv%1") },
    { p = N("MKR_AVOCMMEDR(r)"), r = N("MKR_TEMP_CONN_AU%1") },

    { p = N("MKR_EAVOCB(r)"), r = N("MKR_TEMP_CONN_AU%1") },
    { p = N("MKR_EAVOCB"), r = N("əu") },
    { p = N("MKR_AVOCDFIN(#?)"), r = N("ə%1") },
    { p = N("MKR_EAVOCDFIN(#?)"), r = N("uː%1") },
    { p = N("MKR_AGHAIDHVOCTRGT(#?)"), r = N("əi%1") },
    { p = N("MKR_AVOCGFIN(#?)"), r = N("ə%1") },
    { p = N("MKR_OVOCGFIN(#?)"), r = N("ə%1") },
    { p = N("MKR_OVOCBFIN(#?)"), r = N("oː%1") },
    { p = N("MKR_OVOCMFIN(#?)"), r = N("oː%1") },
    -- {p = N("MKR_IVOCBFIN(#?)"), r = N("iː%1")},
    { p = N("MKR_IVOCMMEDEFIN(#?)"), r = N("ɪv'%1") },

    { p = N("MKR_IVOCMFIN(#?)"), r = N("iː%1") },

    { p = N("MKR_IVOCDMEDEFIN(#?)"), r = N("iː%1") },
    { p = N("MKR_UIVOCDMEDEFIN(#?)"), r = N("iː%1") },
    { p = N("MKR_IVOCDFIN(#?)"), r = N("iː%1") },
    { p = N("MKR_UIVOCDFIN(#?)"), r = N("iː%1") },
    { p = N("MKR_AACTLNGVOCTHSILFIN(#?)"), r = N("ɑː%1") },
    { p = N("MKR_AIDHFINSCHWA(#?)"), r = N("ə%1") },
    { p = N("MKR_AIGHFINSCHWA(#?)"), r = N("ə%1") },
    { p = N("MKR_AIDHFINVOC(#?)"), r = N("ai%1") },
    { p = N("MKR_AIGHFINVOC(#?)"), r = N("ai%1") },
    { p = N("MKR_EA_COMPOUND_LONG_E"), r = N("eː") },
    { p = N("MKR_A_I_ACT_LNG_RSLV"), r = N("ɑː") },

    { p = N("MKR_UI_LONG"), r = N("iː") },


    { p = N("MKR_E_ACT_I_LNG"), r = N("eː") },
    { p = N("MKR_I_ACT_U_LNG"), r = N("uː") },
    { p = N("MKR_A_ACT_LNG"), r = N("ɑː") },
    { p = N("MKR_E_ACT_LNG"), r = N("eː") },
    { p = N("MKR_I_ACT_LNG"), r = N("iː") },
    { p = N("MKR_O_ACT_LNG"), r = N("oː") },
    { p = N("MKR_U_ACT_LNG"), r = N("uː") }, { p = N("MKR_AOLNG"), r = N("iː") },
    { p = N("MKR_AOILNG"), r = N("iː") }, { p = N("MKR_OIACTLNG"), r = N("oː") },
    { p = N("MKR_AE_SEQ"), r = N("eː") }, { p = N("MKR_EO_SEQ"), r = N("oː") },
    { p = N("MKR_IA_DIPH"), r = N("iə") }, { p = N("MKR_UA_DIPH"), r = N("ua") },
    { p = N("MKR_A_FRM_BAINNE"), r = N("a") },
    { p = N("MKR_AI_DIPH(" .. ZZZ_N_STR_PAL_PHON .. ")$"), r = N("a%1") },
    { p = N("MKR_AI_DIPH(nm')"), r = N("a%1") },
   
    { p = N("MKR_AI_DIPH"), r = N("a") },
    { p = N("ei(MKR_MH)"), r = N("MKR_I_ACT_LNG%1") }, -- Force 'ei' before 'mh' to be long 'i'

    { p = N("MKR_EI_DIPH"), r = N("e") }, -- Similarly, 'ei' often represents /e/ or /ɛ/.

    {
    p = N("MKR_OI_DIPH(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "*')"),
    r = N("ɛ%1")
}, { p = N("MKR_OI_DIPH"), r = N("ɔ") },

    { p = N("uMKR_IBH_VOCALIZING_ENDING"), r = N("ɪv'") }, -- This directly outputs the core sound
    { p = N("MKR_IBH_VOCALIZING_ENDING"), r = N("ɪv'") }, -- If 'ibh' occurs without a preceding 'u' (less common as a root)

    { p = N("MKR_UI_DIPH"), r = N("ɪ") },
    { p = N("MKR_AU_DIPH"), r = N("au") }, { p = N("MKR_OU_DIPH"), r = N("ou") },
    { p = N("MKR_VOC_AMH_MED_R"), r = N("MKR_TEMP_CONN_AU") },
    { p = N("MKR_VOC_EABH_MED_R"), r = N("MKR_TEMP_CONN_AU") },
    { p = N("MKR_EA_PRE_BH_VOC"), r = N("a") },
    { p = N("MKR_IO_SHT_TRGT"), r = N("ɪ") },
    { p = N("MKR_EACHTBRDFX"), r = N("əxt") },
    { p = N("MKR_EA_BRD_SHT_PRE_CHT"), r = N("a") },
    { p = N("MKR_EA_SLN_PRE_CH"), r = N("æ") },
    { p = N("MKR_EA_SLN_PRE_NG"), r = N("æ") },
    { p = N("MKR_EA_BRD_PRE_NG"), r = N("a") },
    { p = N("MKR_EA_SLN_PRE_NN"), r = N("æ") },
    { p = N("MKR_EA_BRD_PRE_NN"), r = N("a") },
    { p = N("MKR_EA_SLN_PRE_RPRIME"), r = N("æ") },
    { p = N("MKR_EA_BRD_PRE_R"), r = N("a") },
    { p = N("MKR_IU_SLN_FIN_PRE_CH"), r = N("ʊ") },
    { p = N("MKR_EA_SLN_PRE_N"), r = N("æ") },
    { p = N("MKR_EA_BRD_PRE_N"), r = N("a") }, { p = N("ea"), r = N("a") },



    { p = N("MKR_AMHAVOC"), r = N("əu") }, -- samhain -> səuɾˠə
    { p = N("MKR_AMH_R_VOC"), r = N("əu") }, -- amhras -> əuɾˠəsˠ
    { p = N("MKR_EIDHVOC"), r = N("ai") }, -- feidhm -> faimʲ
    { p = N("MKR_AIDHVOC"), r = N("ai") }, -- adhaidh -> ai
    { p = N("MKR_AGHAVOC"), r = N("ai") }, -- aghaidh -> ai
    { p = N("MKR_ADHAVOC"), r = N("ai") }, -- adharc -> airc
    { p = N("MKR_OGHAVOC"), r = N("əu") }, -- foghlaim -> fəulˠəmʲ

    -- Monophthong/diphthong handling
    { p = N("MKR_EO_VOWEL"), r = N("oː") }, -- beo -> bʲoː
    { p = N("MKR_E_ACT_A"), r = N("eː") }, -- béal -> bʲeːlˠ
    { p = N("MKR_I_ACT_O"), r = N("iː") }, -- gníomh -> gʲnʲiːvˠ
    { p = N("MKR_AI_DIPH"), r = N("ai") }, -- baile -> bˠalʲə
    { p = N("MKR_EI_DIPH"), r = N("ai") }, -- ceist -> caiʃtʲ
    { p = N("MKR_OI_DIPH"), r = N("ai") }, -- oíche -> ai

    -- Suffix handling (new additions)
    { p = N("MKR_SUFFIX_ACH"), r = N("əx") }, -- -ach suffix
    { p = N("MKR_SUFFIX_AIGH"), r = N("iː") }, -- -aigh suffix
    { p = N("MKR_SUFFIX_ANN"), r = N("ən̪ˠ") }, -- -ann suffix
    { p = N("MKR_SUFFIX_AS"), r = N("əsˠ") }, -- -as suffix

    -- Final -adh reduction
    { p = N("MKR_ADHFINSCHWA(#?)"), r = N("ə%1") }
}

placeholder_creation_rules_stage4_5 = {
    { p = N("ɑu"), r = N("MKR_PHON_AU_DIPH") },
    { p = N("ai"), r = N("MKR_PHON_AI_DIPH") },
    { p = N("iə"), r = N("MKR_PHON_IA_DIPH") },
    { p = N("ua"), r = N("MKR_PHON_UA_DIPH") },
    { p = N("ou"), r = N("MKR_PHON_OU_DIPH") },
    { p = N("ei"), r = N("MKR_PHON_EI_DIPH") },
    { p = N("oi"), r = N("MKR_PHON_OI_DIPH") },
    { p = N("ui"), r = N("MKR_PHON_UI_DIPH") },
    { p = N("əu"), r = N("MKR_PHON_SCHWA_U_DIPH") },
    { p = N("aw"), r = N("MKR_PHON_AW_SEQ") },
    { p = N("əi"), r = N("MKR_PHON_SCHWA_I_DIPH") },
    { p = N("ɑː"), r = N("MKR_PHON_A_LONG") },
    { p = N("eː"), r = N("MKR_PHON_E_LONG") },
    { p = N("iː"), r = N("MKR_PHON_I_LONG") },
    { p = N("oː"), r = N("MKR_PHON_O_LONG") },
    { p = N("uː"), r = N("MKR_PHON_U_LONG") },
    { p = N("ɨː"), r = N("MKR_PHON_Y_LONG") },
    { p = N("æː"), r = N("MKR_PHON_AE_LONG") }
}
core_allophony_rules_for_stage4_5 = {
    -- =====================================================================
    -- NEW: Nasal Raising Rules (High Priority)
    -- These rules handle the raising and lengthening of vowels before nasals.
    -- =====================================================================

    -- Case 1: /ɔ/ (from 'o') or /ʌ/ (from 'o'/'u') before broad 'm' -> [uː]
    -- Example: trom -> [t̪ˠɾˠuːmˠ]
    {
        p = N("([ɔʌ])(mˠ)"), -- Matches ɔ or ʌ before a broad m
        r = N("uː%2")
    },

    -- Case 2: /ɔ/ or /ʌ/ before broad 'nn' (represented by our marker) -> [uː]
    -- Example: donn -> [d̪ˠuːn̪ˠ]
    {
        p = N("([ɔʌ])(" .. ZZZ_N_STR_BRD_PHON .. ")"),
        r = N("uː%2")
    },

    -- Case 3: /a/ before broad 'nn' or 'm' -> [ɑː]
    -- Example: crann -> [kɾˠɑːn̪ˠ], am -> [ɑːmˠ] (in some contexts)
    {
        p = N("(a)(mˠ)"),
        r = N("ɑː%2")
    },
    {
        p = N("(a)(" .. ZZZ_N_STR_BRD_PHON .. ")"),
        r = N("ɑː%2")
    },

    -- Case 4: /a/ before broad 'ng' -> [au] diphthong
    -- Example: teanga -> [tʲaŋə] -> [tʲauŋə]
    {
        p = N("(a)(ŋ)"),
        r = N("au%2")
    },

    -- =====================================================================
    -- Existing Allophony Rules (Now run after Nasal Raising)
    -- =====================================================================

    -- Vowel Gradation (a -> ɛ) before specific slender clusters
    { p = N("(a)(l't')"), r = N("ɛ%2") },
    { p = N("(a)(r'd')"), r = N("ɛ%2") },
    { p = N("(a)(l'c)"),  r = N("ɛ%2") },
    { p = N("(a)(r'c)"),  r = N("ɛ%2") },

    -- Broad 'v' (from bh/mh) vocalization to 'w'
    { p = N("^(ˈ?)vˠ([" .. ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR .. "])"), r = N("%1w%2") },

    -- Specific contextual rules
    { p = N("^(ˈ?)o(sp')"), r = "%1ɔ%2" },
    { p = N("(st')i"), r = "%1ʊ" },
    { p = N("MKR_PHON_Y_LONG"), r = N("MKR_PHON_I_LONG") },
    { p = N("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "[']?)([ou])([kgxɣ])"), r = "%1ʊ%3" },
    { p = N("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "['])(a)(r)$"), r = "%1a%3" },
    { p = N("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "['])(a)(R)$"), r = "%1a%3" },
    { p = N("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "['])(a)(" .. BROAD_CONSONANT_PHONETIC_CLASS_NO_CAPTURE:gsub("[rR]", "") .. ")"), r = "%1ɑ%3" },
    { p = N("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "['])(a)(" .. BROAD_CONSONANT_PHONETIC_CLASS_NO_CAPTURE:gsub("[rR]", "") .. ")$"), r = "%1ɑ%3" },
    { p = N("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "['])(a)([^" .. ANY_CONSONANT_PHONETIC_RAW_CHARS_STR .. "rR]?)$"), r = "%1æ%3" },
    { p = N("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "['])(a)"), r = "%1æ" },

    -- Default short vowel realizations (these are now fallbacks)
    { p = N("a"), r = N("a") },
    { p = N("e"), r = N("ɛ") },
    { p = N("i"), r = N("ɪ") },
    { p = N("o"), r = N("ɔ") }, -- Default for 'o' is now ɔ
    { p = N("u"), r = N("ʊ") }, -- Default for 'u' is ʊ

    -- Other specific rules
    { p = N("(v')([aæ])"), r = "%1%2" },
    { p = N("t(æ)"), r = "t'%1" },
    { p = N("l(MKR_PHON_I_LONG)"), r = "l'%1" },
    { p = N("d(l'MKR_PHON_I_LONG)"), r = "d'%1" },
    { p = N("n(iv')"), r = "n'%1" },
    { p = N("(d'a)(r)(h)(MKR_PHON_A_LONGɾ')"), r = "%1ɾˠ%4" },
    { p = N("(MKR_PHON_A_LONG)i(r)$"), r = "%1iɾ'" },
    { p = N("d(a)(r)"), r = "d'%1%2" },
    { p = N("k(a)(rt)"), r = "c%1%2" },
    { p = N("(MKR_PHON_I_LONGɔ)([" .. BROAD_CONSONANT_PHONETIC_CLASS_NO_CAPTURE .. "])"), r = "%1%2" },
    { p = N("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "*'?)([ɔʊʌ])(" ..ANY_CONSONANT_PHONETIC_PATTERN .. "['])"), r = "%1ɛ%3" },
    { p = N("([ɾR]')i"), r = "%1ɛ" },
    { p = N("([ɾR])i"), r = "%1ɛ" },
    { p = N("([ɾR]')ɔ"), r = "%1ɔ" },
    { p = N("([ɾR])ɔ"), r = "%1ɔ" },
    { p = N("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "*')(a)(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "['])"), r = "%1ɛ%3" },
    { p = N("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "*')([ɔʊʌ])(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "['])"), r = "%1ɪ%3" },
    { p = N("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "*')(e)(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "['])"), r = "%1ɛ%3" },
    { p = N("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "*')(i)(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "['])"), r = "%1ɪ%3" },
    { p = N("l_neutral_"), r = N("l") },
    { p = N("n_neutral_"), r = N("n") },
    { p = N("(MKR_PHON_O_LONG)(n[']?)"), r = N("uː%2") }
}

placeholder_restoration_rules_stage4_5 = {
    { p = N("MKR_PHON_A_LONG"), r = N("ɑː") },
    { p = N("MKR_PHON_E_LONG"), r = N("eː") },
    { p = N("MKR_PHON_I_LONG"), r = N("iː") },
    { p = N("MKR_PHON_O_LONG"), r = N("oː") },
    { p = N("MKR_PHON_U_LONG"), r = N("uː") },
    { p = N("MKR_PHON_Y_LONG"), r = N("ɨː") },
    { p = N("MKR_PHON_AE_LONG"), r = N("æː") },
    { p = N("MKR_PHON_AU_DIPH"), r = N("ɑu") },
    { p = N("MKR_PHON_AI_DIPH"), r = N("ai") },
    { p = N("MKR_PHON_IA_DIPH"), r = N("iə") },
    { p = N("MKR_PHON_UA_DIPH"), r = N("ua") },
    { p = N("MKR_PHON_OU_DIPH"), r = N("ou") },
    { p = N("MKR_PHON_EI_DIPH"), r = N("ei") },
    { p = N("MKR_PHON_OI_DIPH"), r = N("oi") },
    { p = N("MKR_PHON_UI_DIPH"), r = N("ui") },
    { p = N("MKR_PHON_SCHWA_U_DIPH"), r = N("əu") },
    { p = N("MKR_PHON_AW_SEQ"), r = N("ɑu") },
    { p = N("MKR_PHON_SCHWA_I_DIPH"), r = N("əi") }
}
connacht_au_to_schwa_u_shift_rule_stage4_5 = {
    p = N("^(ˈ?[" .. ANY_CONSONANT_PHONETIC_RAW_CHARS_STR .. "]*'?)(ɑu)([" ..
        ANY_CONSONANT_PHONETIC_RAW_CHARS_STR .. "]*'?)$"),
    r = function(full_match, pre_part, au_diph, post_part)
        if is_likely_monosyllable_phonetic_revised(full_match) then
            return (pre_part or "") .. N("əu") .. (post_part or "")
        end
        return full_match
    end
}
temp_conn_au_to_final_au_rule_stage4_5 = {
    p = N("MKR_TEMP_CONN_AU"),
    r = N("əu")
}
irishPhonetics.rules_stage4_5_2_connacht_specific_vowel_shifts = {
    { p = N("(oː)(nʲ)"), r = N("uː%2") },
    { p = N("(oː)(" .. ZZZ_N_STR_PAL_PHON .. ")"), r = N("uː%2") }
}

irishPhonetics.rules_stage4_5_contextual_allophony_on_phonetic = {
    -- This stage assumes an input of a phonetic-like string where consonants have quality markers (e.g., k', l, s)
    -- and vowels might be single letters or markers from previous stages.

    -- First, resolve the orthographic <o> and <u> markers to a base phoneme /ʌ/.
    -- This simplifies the subsequent rules.
    { p = N("MKR_U_SHT"), r = N("ʌ") },
    { p = N("MKR_O_SHT"), r = N("ʌ") },
    { p = N("o"), r = N("ʌ") },
    { p = N("u"), r = N("ʌ") },

    -- Now, apply conditioned allophony to /ʌ/.
    -- Rule for /ʌ/ -> [ʊ] before broad velar stops and labial fricatives (from historic <u>).
    -- This is tricky without the marker. A better approach is to do this BEFORE resolving the marker.
    -- Let's adjust the order. The first rules in this stage should be the /ʌ/ allophony.
    -- So, the input will still have MKR_U_SHT.

    -- NEW, CORRECTED ORDER AND RULES:
    -- 1. Allophony of historic <u>
    { p = N("(MKR_U_SHT)([kg][^'])"), r = N("ʊ%2") }, -- e.g., muc -> mʊk
    { p = N("(MKR_U_SHT)([vf][^'])"), r = N("ʊ%2") }, -- e.g., dubh -> dʊv
    -- Any remaining historic <u> or <o> becomes /ʌ/
    { p = N("MKR_U_SHT"), r = N("ʌ") },
    { p = N("MKR_O_SHT"), r = N("ʌ") },
    { p = N("o"), r = N("ʌ") },
    { p = N("u"), r = N("ʌ") },

    -- 2. Vowel Gradation (Assimilation to Coda Quality)
    -- These patterns are complex. Let's define captures carefully.
    -- C_OPT_PAL captures a consonant with an optional palatal marker.
    -- C_PAL captures a consonant that MUST have a palatal marker.
    -- C_BRD captures a consonant that MUST NOT have a palatal marker.
    {
        -- /a/ -> /ɛ/ before a slender coda. e.g., glas -> glais
        p = N("(a)(" .. CPART_CAPTURE_STRICT:gsub("%?'%)", "'%)") .. "$)"), -- Pattern: a + slender_consonant + end-of-word
        r = N("ɛ%2")
    },
    {
        -- /ʌ/ -> /ɪ/ before a slender coda. e.g., cnoc -> cnoic
        p = N("(ʌ)(" .. CPART_CAPTURE_STRICT:gsub("%?'%)", "'%)") .. "$)"),
        r = N("ɪ%2")
    },
    {
        -- /ɛ/ -> /ʌ/ before a broad coda. e.g., troid -> troda
        p = N("(ɛ)(" .. CPART_CAPTURE_STRICT:gsub("%?'%)", "%)") .. ")$"), -- Pattern: ɛ + broad_consonant + end-of-word
        r = N("ʌ%2")
    },
    {
        -- /ɪ/ -> /a/ before a broad coda. e.g., fios -> feasa
        p = N("(ɪ)(" .. CPART_CAPTURE_STRICT:gsub("%?'%)", "%)") .. ")$"),
        r = N("a%2")
    },

    -- 3. Short Low /a/ Allophony (Assimilation to Onset Quality)
    -- /a/ -> [æ] after a slender consonant.
    {
        p = N("(" .. CPART_CAPTURE_STRICT:gsub("%?'%)", "'%)") .. ")(a)"), -- Pattern: slender_consonant + a
        r = N("%1æ")
    },

    -- 4. R-Lowering
    -- /ɪ/ -> [ɛ] in the environment of /r/.
    { p = N("(r'?)ɪ"), r = N("%1ɛ") },
    { p = N("ɪ(r'?)"), r = N("ɛ%1") },

}
local function collect_phons(units_table)
    local phons = {}
    for _, u in ipairs(units_table) do
        table.insert(phons, u.phon)
    end
    return phons
end
local process_vocalization_on_units_impl
process_vocalization_on_units_impl = function(parsed_units, phon_word_input, context)
    if not parsed_units or #parsed_units < 2 then return false, parsed_units end

    -- This map defines the Vowel+Fricative -> NewVowel transformations.
    -- It is the core logic for this procedural stage.
    local vocalization_map = {
        -- Broad contexts (V + [w] or [ɣ])
        [N("o") .. N("w")] = N("oː"),   -- e.g., comhair -> co(mh)air -> [koːrʲ]
        [N("ʊ") .. N("w")] = N("uː"),   -- e.g., from omh/obh
        [N("a") .. N("w")] = N("əu"),   -- e.g., amhras -> [əuɾˠəsˠ]
        [N("a") .. N("ɣ")] = N("ai"),   -- e.g., adharc -> [airk]
        [N("ʊ") .. N("ɣ")] = N("uː"),   -- e.g., chugham -> [xuːmˠ]
        [N("u") .. N("ɣ")] = N("uː"),
        -- Slender contexts (V + [vʲ] or [j])
        [N("ɛ") .. N("j")] = N("eː"),   -- e.g., théigh -> [heːj]
        [N("ɪ") .. N("vʲ")] = N("iː"),  -- e.g., nimh -> [nʲiː]
        [N("a") .. N("vʲ")] = N("ai")    -- e.g., saibhir -> [saiwɾʲ] (w is a variant)
        -- Note: The output can be a diphthong or a long vowel.
    }

    local modified_in_pass = false
    local new_units_build = {}
    local i = 1
    while i <= #parsed_units do
        local current_unit = parsed_units[i]
        debug_print_minimal("Stage4_4_1_VocalizeLenitedFricatives", string.format("  Loop %d: Current unit: '%s'", i, current_unit.phon))
        debug_print_minimal("Stage4_4_1_VocalizeLenitedFricatives", "    new_units_build before: " .. table.concat(collect_phons(new_units_build), ""))

        if i > 1 and current_unit.type == "consonant" then
            local prev_unit = new_units_build[#new_units_build] -- Get the last unit added
            if prev_unit and prev_unit.type == "vowel" then
                local fricative_to_check = current_unit.phon
                -- Normalize w to vˠ for lookup consistency if needed, but direct match is better
                if fricative_to_check == N("w") then fricative_to_check = N("vˠ") end

                local lookup_key = prev_unit.phon .. fricative_to_check
                local replacement_vowel = vocalization_map[lookup_key]

                if replacement_vowel then
                    debug_print_minimal("Stage4_4_1_VocalizeLenitedFricatives",
                        "PROCEDURAL Vocalization: Replacing '",
                        prev_unit.phon .. current_unit.phon, "' with '",
                        replacement_vowel, "'")

                    -- Modify the last unit added (the vowel) instead of removing and re-adding
                    prev_unit.phon = replacement_vowel
                    -- We have now consumed the current fricative, so we skip it.
                    i = i + 1
                    modified_in_pass = true
                    goto continue_vocalization_loop -- Skip adding the fricative
                end
            end
        end

        -- If no rule applied, just add the current unit
        table.insert(new_units_build, current_unit)
        debug_print_minimal("Stage4_4_1_VocalizeLenitedFricatives", "    new_units_build after add: " .. table.concat(collect_phons(new_units_build), ""))

        i = i + 1
        ::continue_vocalization_loop::
    end

    if modified_in_pass then
        -- The function now returns a boolean and the modified table
        return true, new_units_build
    else
        return false, parsed_units -- Return original if no change
    end
end
local process_vocalization_on_units =
    memoize(process_vocalization_on_units_impl)

local function process_phonetic_units_procedurally(phon_word_input,
    stage_name_for_debug,
    unit_processor_func,
    context_params)
if STAGE_DEBUG_ENABLED[stage_name_for_debug] then
debug_print_minimal(stage_name_for_debug,
"  " .. stage_name_for_debug ..
" START (Proc Helper): In=", phon_word_input)
end
if not phon_word_input or phon_word_input == "" then
return phon_word_input
end
    local parsed_units = parse_phonetic_string_to_units_for_epenthesis(
        phon_word_input)
    if not parsed_units or #parsed_units == 0 then
        if STAGE_DEBUG_ENABLED[stage_name_for_debug] then
            debug_print_minimal(stage_name_for_debug,
                " END (no units): Out=", phon_word_input)
        end
        return phon_word_input
    end

    -- *** CRITICAL FIX HERE: Capture both return values ***
    local was_modified_by_processor, returned_units_table = unit_processor_func(parsed_units,
        phon_word_input, -- Pass original phon_word_input if needed by processor
        context_params)
    -- The table to use for rebuilding is the one explicitly returned by the processor.
    local final_units_to_rebuild = returned_units_table

    if was_modified_by_processor then
        local rebuilt_phon_word_parts = {}
        for _, unit_data in ipairs(final_units_to_rebuild) do
            table.insert(rebuilt_phon_word_parts,
                (unit_data.stress or "") .. unit_data.phon)
        end
        local new_phon_word = table.concat(rebuilt_phon_word_parts)
        if STAGE_DEBUG_ENABLED[stage_name_for_debug] then
            debug_print_minimal(stage_name_for_debug,
                " END (modified by unit_processor): Out=",
                new_phon_word, " (Actual content of returned units)") -- Added clarification for debug
        end
        return new_phon_word
    else
        if STAGE_DEBUG_ENABLED[stage_name_for_debug] then
            debug_print_minimal(stage_name_for_debug,
                " END (no change by unit_processor): Out=",
                phon_word_input)
        end
        return phon_word_input
    end
end

process_phonetic_units_procedurally = memoize(
    process_phonetic_units_procedurally)

local process_disyllabic_raising_on_units_impl
process_disyllabic_raising_on_units_impl =
function(parsed_units, phon_word_input, context)
    -- FIX 1: Correct return signature for early exits
    if not parsed_units or #parsed_units < 2 then return false, parsed_units end

    local vowel_units_data, primary_stress_vowel_original_index,
    explicit_stress_mark_found = {}, -1, false
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
            if not explicit_stress_mark_found and
                primary_stress_vowel_original_index == -1 then
                primary_stress_vowel_original_index = k
            end
        end
    end

    -- FIX 1: Correct return signature
    if #vowel_units_data ~= 2 then return false, parsed_units end

    local v1_data, v2_data = vowel_units_data[1], vowel_units_data[2];
    local v1_original_idx = v1_data.original_idx
    local v1_is_stressed = (v1_original_idx == primary_stress_vowel_original_index)

    -- FIX 1: Correct return signature
    if not v1_is_stressed then return false, parsed_units end

    local v1_phon, v2_phon = v1_data.phon, v2_data.phon;
    local v1_is_short, v2_is_long = not umatch(v1_phon, "ː$"), umatch(v2_phon, "ː$")

    -- FIX 1: Correct return signature
    if not (v1_is_stressed and v1_is_short and v2_is_long) then
        return false, parsed_units
    end

    -- FIX 2: Add more specific conditions for the rule to fire
    local can_raise = false
    -- Condition 1: The second vowel must be the long low back vowel /ɑː/.
    if v2_phon == N("ɑː") then
        -- Condition 2: The first vowel must be a low or mid-back vowel.
        if umatch(v1_phon, "^[aɑɔʌʊ]$") then
             -- Condition 3: The syllable containing V2 should be closed.
             -- We check if there is a consonant after V2.
            if v2_data.original_idx < #parsed_units then
                can_raise = true
            end
        end
    end

    -- If the specific conditions are not met, exit without making changes.
    if not can_raise then
        return false, parsed_units
    end

    -- The rest of the logic only runs if can_raise is true.
    local c_after_v1_quality, c_after_v1_phon = "neutral", ""
    if v1_original_idx + 1 < v2_data.original_idx then
        local cons_idx = v1_original_idx + 1;
        while cons_idx < v2_data.original_idx and
            parsed_units[cons_idx].type ~= "vowel" do
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
            v1_phon == N("e") or v1_phon == N("ai")) and c_after_v1_quality ==
        "palatal" then
        new_v1_phon = N("ɪ")
    end

    if new_v1_phon ~= v1_phon then
        debug_print_minimal("Stage4_5_1_DisyllabicShortLongRaising",
            "Applying raising: V1 '", v1_phon, "' -> '",
            new_v1_phon, "'");
        parsed_units[v1_original_idx].phon = new_v1_phon;
        -- FIX 1: Return true AND the modified table
        return true, parsed_units
    end

    -- FIX 1: Return false AND the original table
    return false, parsed_units
end
local process_disyllabic_raising_on_units = memoize(
    process_disyllabic_raising_on_units_impl)

local process_nasalization_on_units_impl
process_nasalization_on_units_impl = function(parsed_units, phon_word_input,
                                              context)
    debug_print_minimal("Nasalization",
        "NO.")
    return false
end
local process_nasalization_on_units =
    memoize(process_nasalization_on_units_impl)

local function get_preceding_consonant_quality(new_units)
    for i = #new_units, 1, -1 do
        local unit = new_units[i]
        -- We are looking for a unit that is a consonant.
        -- The 'type' field, added during the Trie parser implementation, is perfect for this.
        if unit.type == "consonant" then
            -- The 'quality' field was assigned during parsing.
            return unit.quality -- Returns "palatal" or "nonpalatal"
        end
        -- If we hit a vowel before finding a consonant, the consonant context is neutral.
        if unit.type == "vowel" then
            return "neutral"
        end
    end
    -- If no preceding consonant or vowel is found (e.g., at the start of a word), context is neutral.
    return "neutral"
end

-- This function looks forwards from a given index `vowel_idx` in the `all_units` table
-- to find the quality of the next consonant.
local function get_following_consonant_quality(all_units, vowel_idx)
    for i = vowel_idx + 1, #all_units do
        local unit = all_units[i]
        if unit.type == "consonant" then
            return unit.quality -- Returns "palatal" or "nonpalatal"
        end
        if unit.type == "vowel" then
            return "neutral"
        end
    end
    -- If no following consonant or vowel is found (e.g., at the end of a word), context is neutral.
    return "neutral"
end

-- Replace your existing process_unstressed_reduction_on_units_impl function with this one.

process_unstressed_reduction_on_units_impl = function(parsed_units, phon_word_input, context)
    if not parsed_units or #parsed_units < 2 then return false, parsed_units end

    local SHORT_VOWELS_TO_NEUTRALIZE_PATTERN = N("[aæɑɔeɛiɪuʊʌ]")
    local modified_in_pass = false
    local stressed_vowel_index = -1
    local syllable_count = 0

    -- First pass to count syllables and find the primary stress index accurately.
    for i = 1, #parsed_units do
        local unit = parsed_units[i]
        if unit.type == "vowel" then
            syllable_count = syllable_count + 1
            -- Check for preceding stress marker
            if i > 1 and parsed_units[i-1].type == "stress" then
                stressed_vowel_index = i
            end
        end
    end
    -- If no explicit stress marker was found, assume first vowel is stressed.
    if stressed_vowel_index == -1 then
        for i = 1, #parsed_units do
            if parsed_units[i].type == "vowel" then
                stressed_vowel_index = i
                break
            end
        end
    end
    -- If still no vowel or only one syllable, no reduction is needed.
    if stressed_vowel_index == -1 or syllable_count <= 1 then
        return false, parsed_units
    end

    -- == STEP A: NEUTRALIZE all unstressed short vowels to 'ə' ==
    for i = 1, #parsed_units do
        local current_unit = parsed_units[i]
        if current_unit.type == "vowel" and i ~= stressed_vowel_index then
            -- Check if it's a short vowel that needs neutralizing
            if not umatch(current_unit.phon, "ː") and umatch(current_unit.phon, SHORT_VOWELS_TO_NEUTRALIZE_PATTERN) then
                debug_print_minimal("Stage4_6_U", "NEUTRALIZE: Reducing unstressed '", current_unit.phon, "' to 'ə'")
                current_unit.phon = N("ə")
                modified_in_pass = true
            end
        end
    end

    if not modified_in_pass then
        return false, parsed_units -- No short unstressed vowels were found to neutralize
    end

    -- == STEP B: REALIZE 'ə' as its correct allophone ([ə] or [ɪ]) based on context ==
    for i = 1, #parsed_units do
        local current_unit = parsed_units[i]
        if current_unit.phon == N("ə") then
            -- Determine quality of flanking consonants
            local prec_c_quality = get_preceding_consonant_quality(parsed_units, i)
            local foll_c_quality = get_following_consonant_quality(parsed_units, i)

            -- Apply the allophonic change
            if prec_c_quality == "palatal" or foll_c_quality == "palatal" then
                debug_print_minimal("Stage4_6_U", "ALLOPHONY: Realizing 'ə' as 'ɪ' in slender context.")
                current_unit.phon = N("ɪ")
            else
                debug_print_minimal("Stage4_6_U", "ALLOPHONY: 'ə' remains 'ə' in broad context.")
                -- No change needed, it's already the broad allophone 'ə'
            end
        end
    end

    return true, parsed_units
end
local process_unstressed_reduction_on_units = memoize(
    process_unstressed_reduction_on_units_impl)

irishPhonetics.rules_stage4_6_unstressed_vowel_reduction_specific_finals = {
    { p = N("aí$"), r = N("iː") }, { p = N("eiə$"), r = N("iː") },
    { p = N("iːə$"), r = N("iː") }
}
irishPhonetics.EPENTHESIS_TARGET_CLUSTERS_BROAD = {
    -- Sonorant + Voiced Stop (Heterorganic)
    [N("rg")] = true,
    [N("rb")] = true,
    [N("lg")] = true,
    [N("lb")] = true,
    -- Sonorant + Voiced Fricative
    [N("lv")] = true,
    -- Sonorant + Sonorant
    [N("rm")] = true,
    [N("rn")] = true, -- Though often simplified, can trigger epenthesis
    [N("lm")] = true
    -- NOTE: Clusters with voiceless stops like 'lk', 'rk', 'rp' are intentionally OMITTED.
}
irishPhonetics.EPENTHESIS_TARGET_CLUSTERS_SLENDER = {
    -- Sonorant + Voiced Stop (Heterorganic)
    [N("rg")] = true,
    [N("rb")] = true,
    -- Sonorant + Voiced Fricative
    [N("lv")] = true,
    [N("rv")] = true,
    -- Sonorant + Sonorant
    [N("rm")] = true,
    [N("rn")] = true,
    [N("lm")] = true,
    [N("nm")] = true
    -- NOTE: Clusters with voiceless stops like 'lk', 'rk', 'rp' are intentionally OMITTED.
}

local function process_epenthesis_on_units(parsed_units, phon_word_input,
                                           context)
    local is_overall_monosyllable = is_likely_monosyllable_phonetic_revised(
        phon_word_input, parsed_units)

    if not is_overall_monosyllable then return false end

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
        return false
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
                    if irishPhonetics.EPENTHESIS_TARGET_CLUSTERS_SLENDER[cluster_key] then
                        ep_v_insert = N("i")
                    end
                elseif c1_qual == "nonpalatal" and c2_qual == "nonpalatal" then
                    if irishPhonetics.EPENTHESIS_TARGET_CLUSTERS_BROAD[cluster_key] then
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
                        "nonpalatal")
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

local process_epenthesis_on_units = memoize(process_epenthesis_on_units)

irishPhonetics.rules_stage5_strong_sonorants_only = {}
do
    local CPART_CAPTURE = CPART_CAPTURE_STRICT;
    local FINAL_CONS_CAPTURE = FINAL_CONSONANT_CAPTURE_STRICT
    local vowel_effects_map_ss_connacht = {
        {
            input_v_class_str = VOWEL_A_CLASS_CAPTURE_STRICT,
            broad_lnm = N("ɑː"),
            broad_r = N("ɑː"),
            pal_lnm_N_target = N("a"),
            pal_lnm_L_target = N("a"),
            pal_lnm_M_target = N("a"),
            pal_r = N("a"),
            sonorant_triggers_special_diphthong = {}
        }, {
        input_v_class_str = VOWEL_E_I_CLASS_CAPTURE_STRICT,
        broad_lnm = N("iː"),
        broad_r = N("a"),
        pal_lnm_N_target = N("iː"),
        pal_lnm_L_target = N("iː"),
        pal_lnm_M_target = N("iː"),
        pal_r = N("əi"),
        sonorant_triggers_special_diphthong = {}
    }, {
        input_v_class_str = VOWEL_O_U_CLASS_CAPTURE_STRICT,
        broad_lnm = N("uː"),
        broad_r = N("ɔ"),
        pal_lnm_N_target = N("iː"),
        pal_lnm_L_target = N("oi"),
        pal_lnm_M_target = N("uː"),
        pal_r = N("ai"),
        sonorant_triggers_special_diphthong = {
            [ZZZ_L_STR_BRD_PHON] = N("ɑu"),
            [ZZZ_L_SNG_BRD_PHON] = N("ɑu")
        }
    }, {
        input_v_class_str = DIPHTHONG_AI_CAPTURE_STRICT,
        broad_lnm = N("ɑː"),
        broad_r = N("ɑː"),
        pal_lnm_N_target = N("ai"),
        pal_lnm_L_target = N("ai"),
        pal_lnm_M_target = N("ai"),
        pal_r = N("ɑː"),
        sonorant_triggers_special_diphthong = {}
    }
    }

    local function create_rules_for_specific_sonorant(rules_table,
                                                      vowel_class_capture_str_arg,
                                                      specific_son_marker_literal,
                                                      son_type_key_base_str_arg,
                                                      veffect_entry_arg,
                                                      is_palatal_arg)
        local actual_repl_v_base
        if veffect_entry_arg.sonorant_triggers_special_diphthong[specific_son_marker_literal] and
            not is_palatal_arg then
            actual_repl_v_base =
                veffect_entry_arg.sonorant_triggers_special_diphthong[specific_son_marker_literal]
        elseif is_palatal_arg then
            if son_type_key_base_str_arg == "PalR" then
                actual_repl_v_base = veffect_entry_arg.pal_r
            elseif son_type_key_base_str_arg == "PalN" then
                actual_repl_v_base = veffect_entry_arg.pal_lnm_N_target
            elseif son_type_key_base_str_arg == "PalL" then
                actual_repl_v_base = veffect_entry_arg.pal_lnm_L_target
            elseif son_type_key_base_str_arg == "PalM" then
                actual_repl_v_base = veffect_entry_arg.pal_lnm_M_target
            else
                actual_repl_v_base = veffect_entry_arg.pal_lnm_N_target
            end
        else
            if son_type_key_base_str_arg == "BroadN" or
                son_type_key_base_str_arg == "BroadL" or
                son_type_key_base_str_arg == "BroadM" then
                actual_repl_v_base = veffect_entry_arg.broad_lnm
            elseif son_type_key_base_str_arg == "BroadR" then
                actual_repl_v_base = veffect_entry_arg.broad_r
            else
                actual_repl_v_base =
                    veffect_entry_arg[son_type_key_base_str_arg:lower()]
            end
        end
        if not actual_repl_v_base then
            debug_print_minimal("EpenthesisAndStrongSonorants",
                "SS Rule WARNING: No r vowel for VClass='",
                veffect_entry_arg.input_v_class_str:sub(1, 10),
                "' SonKey='", son_type_key_base_str_arg,
                "' Pal=", tostring(is_palatal_arg));
            return
        end

        local ps_to_generate = {
            {
                ptn = "^(ˈ?)" .. CPART_CAPTURE .. vowel_class_capture_str_arg ..
                    "(" .. specific_son_marker_literal .. ")" ..
                    FINAL_CONS_CAPTURE .. "(#?)$",
                caps = {
                    s = true,
                    cp = true,
                    v = true,
                    son = true,
                    fc = true,
                    b = true
                }
            }, {
            ptn = "^(ˈ?)" .. CPART_CAPTURE .. vowel_class_capture_str_arg ..
                "(" .. specific_son_marker_literal .. ")" .. "(#?)$",
            caps = {
                s = true,
                cp = true,
                v = true,
                son = true,
                fc = false,
                b = true
            }
        }, {
            ptn = "^(ˈ?)" .. vowel_class_capture_str_arg .. "(" ..
                specific_son_marker_literal .. ")" .. FINAL_CONS_CAPTURE ..
                "(#?)$",
            caps = {
                s = true,
                cp = false,
                v = true,
                son = true,
                fc = true,
                b = true
            }
        }, {
            ptn = "^(ˈ?)" .. vowel_class_capture_str_arg .. "(" ..
                specific_son_marker_literal .. ")" .. "(#?)$",
            caps = {
                s = true,
                cp = false,
                v = true,
                son = true,
                fc = false,
                b = true
            }
        }
        }
        for _, ptn_data in ipairs(ps_to_generate) do
            table.insert(rules_table, {
                p = ptn_data.ptn,
                r = function(...)
                    local all_captures = { ... };
                    local fm = all_captures[1];
                    local stress, c_part, vowel_cap, son_cap, final_cons_cap,
                    boundary_cap;
                    local current_cap_idx = 2
                    if ptn_data.caps.s then
                        stress = all_captures[current_cap_idx];
                        current_cap_idx = current_cap_idx + 1;
                    end
                    if ptn_data.caps.cp then
                        c_part = all_captures[current_cap_idx];
                        current_cap_idx = current_cap_idx + 1;
                    end
                    if ptn_data.caps.v then
                        vowel_cap = all_captures[current_cap_idx];
                        current_cap_idx = current_cap_idx + 1;
                    end
                    if ptn_data.caps.son then
                        son_cap = all_captures[current_cap_idx];
                        current_cap_idx = current_cap_idx + 1;
                    end
                    if ptn_data.caps.fc then
                        final_cons_cap = all_captures[current_cap_idx];
                        current_cap_idx = current_cap_idx + 1;
                    end
                    if ptn_data.caps.b then
                        boundary_cap = all_captures[current_cap_idx];
                    end
                    local final_r_vowel = actual_repl_v_base
                    debug_print_minimal("EpenthesisAndStrongSonorants",
                        "SS Rule EXEC (Helper): PtnKey='",
                        son_type_key_base_str_arg,
                        veffect_entry_arg.input_v_class_str,
                        "' Ptn='", ptn_data.ptn, "' Full='", fm,
                        "' VIn='", vowel_cap or "", "' VOut='",
                        final_r_vowel or "nil", "'.")
                    return (stress or "") .. (c_part or "") ..
                        (final_r_vowel or vowel_cap or "") ..
                        (son_cap or "") .. (final_cons_cap or "") ..
                        (boundary_cap or "")
                end,
                use_current_phonetic_for_condition = true,
                condition_func = function(fm, pu)
                    return is_likely_monosyllable_phonetic_revised(fm, pu)
                end
            })
        end
    end
    for _, veffect in ipairs(vowel_effects_map_ss_connacht) do
        for _, son_mkr in ipairs(BROAD_LNM_MARKERS_FOR_STAGE5) do
            local son_type_key = "BroadLNM";
            if umatch(son_mkr, "ZZZN") then
                son_type_key = "BroadN"
            elseif umatch(son_mkr, "ZZZL") then
                son_type_key = "BroadL"
            elseif umatch(son_mkr, "^[mM]$") then
                son_type_key = "BroadM"
            end
            create_rules_for_specific_sonorant(
                irishPhonetics.rules_stage5_strong_sonorants_only,
                veffect.input_v_class_str, son_mkr, son_type_key, veffect, false)
        end
        for _, son_mkr in ipairs(BROAD_R_MARKERS_FOR_STAGE5) do
            create_rules_for_specific_sonorant(
                irishPhonetics.rules_stage5_strong_sonorants_only,
                veffect.input_v_class_str, son_mkr, "BroadR", veffect, false)
        end
        for _, son_mkr in ipairs(PALATAL_LNM_MARKERS_FOR_STAGE5) do
            local son_type_key = "PalLNM";
            if umatch(son_mkr, "ZZZN") then
                son_type_key = "PalN"
            elseif umatch(son_mkr, "ZZZL") then
                son_type_key = "PalL"
            elseif umatch(son_mkr, "^[mM]'") then
                son_type_key = "PalM"
            elseif umatch(son_mkr, "^[nNlL]'") then
                son_type_key = "PalLNM"
            end
            create_rules_for_specific_sonorant(
                irishPhonetics.rules_stage5_strong_sonorants_only,
                veffect.input_v_class_str, son_mkr, son_type_key, veffect, true)
        end
        for _, son_mkr in ipairs(PALATAL_R_MARKERS_FOR_STAGE5) do
            create_rules_for_specific_sonorant(
                irishPhonetics.rules_stage5_strong_sonorants_only,
                veffect.input_v_class_str, son_mkr, "PalR", veffect, true)
        end
    end
end

irishPhonetics.rules_stage6_diacritics = {

    { p = N("n(x)"), r = N("nˠ%1") }, { p = N("s$"), r = N("sˠ") },
    { p = N("s(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])"), r = N("sˠ%1") },
    {
        p = N("s(" .. SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR .. ")"),
        r = N("sˠ%1")
    }, { p = N("t$"), r = N("t̪ˠ") },
    { p = N("t(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])"), r = N("t̪ˠ%1") }, {
    p = N("t(" .. SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR .. ")"),
    r = N("t̪ˠ%1")
}, { p = N("d$"), r = N("d̪ˠ") },
    { p = N("d(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])"), r = N("d̪ˠ%1") }, {
    p = N("d(" .. SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR .. ")"),
    r = N("d̪ˠ%1")
},

    -- Default broad n, l to just velarized. Add dental marker specifically if needed.
    { p = N("n$"), r = N("nˠ") },
    { p = N("n(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])"), r = N("nˠ%1") },
    {
        p = N("n(" .. SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR .. ")"),
        r = N("nˠ%1")
    }, { p = N("l$"), r = N("lˠ") },
    { p = N("l(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])"), r = N("lˠ%1") },
    {
        p = N("l(" .. SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR .. ")"),
        r = N("lˠ%1")
    },

    -- Specific rule for dental n/l if needed (example, not fully implemented here)
    -- { p = N("(VOWEL_CONTEXT_FOR_DENTAL)(n)"), r = "%1n̪ˠ" },

    { p = N("r$"), r = N("ɾˠ") },
    { p = N("r(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])"), r = N("ɾˠ%1") },
    {
        p = N("r(" .. SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR .. ")"),
        r = N("ɾˠ%1")
    }, { p = N("m$"), r = N("mˠ") },
    { p = N("m(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])"), r = N("mˠ%1") },
    {
        p = N("m(" .. SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR .. ")"),
        r = N("mˠ%1")
    }, { p = N("b$"), r = N("bˠ") },
    { p = N("b(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])"), r = N("bˠ%1") },
    {
        p = N("b(" .. SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR .. ")"),
        r = N("bˠ%1")
    }, { p = N("p$"), r = N("pˠ") },
    { p = N("p(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])"), r = N("pˠ%1") },
    {
        p = N("p(" .. SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR .. ")"),
        r = N("pˠ%1")
    }, { p = N("f$"), r = N("fˠ") },
    { p = N("f(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])"), r = N("fˠ%1") },
    {
        p = N("f(" .. SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR .. ")"),
        r = N("fˠ%1")
    }

}
irishPhonetics.rules_stage7_final_cleanup = {
    { p = N("([ɑeiou]ː)[ɣçh]$"), r = N("%1") }, -- Delete final h/ç/ɣ after a long vowel

    { p = ZZZ_N_STR_PAL_PHON, r = N("n̠ʲ") },
    { p = ZZZ_N_STR_BRD_PHON, r = N("n̪ˠ") },
    { p = ZZZ_L_STR_PAL_PHON, r = N("l̠ʲ") },
    { p = ZZZ_L_STR_BRD_PHON, r = N("l̪ˠ") },
    { p = ZZZ_N_SNG_BRD_PHON, r = N("n̪ˠ") },
    { p = ZZZ_L_SNG_BRD_PHON, r = N("l̪ˠ") },
    { p = N("(n̠ʲ)t̪$"), r = "%1tʲ" },
    { p = N("(n̠ʲ)t̪(" .. CONSONANT_CLASS_NO_CAPTURE .. ")"), r = "%1tʲ%2" },
    { p = N("(lʲ)t̪$"), r = "%1tʲ" }, { p = N("(ɾʲ)j$"), r = "%1h" },
    { p = N("j$"), r = N("h") }, { p = N("MKR_SCHWA_U_TINT"), r = N("ʊ̽") },
    { p = N("(" .. ANY_CONSONANT_PHONETIC_RAW_CHARS_STR .. ")''"), r = "%1'" },
    { p = N("^st'"), r = N("ʃtʲ") }, { p = N("s'"), r = N("ʃ") },
    { p = N("t'"), r = N("tʲ") }, { p = N("d'"), r = N("dʲ") },

    { p = N("k'"), r = N("c") },

    { p = N("g'"), r = N("ɟ") },
    { p = N("l'"), r = N("lʲ") }, { p = N("n'"), r = N("nʲ") },
    { p = N("R'"), r = N("ɾʲ") }, { p = N("r'"), r = N("ɾʲ") },
    { p = N("f'"), r = N("fʲ") }, { p = N("v'"), r = N("vʲ") },
    { p = N("b'"), r = N("bʲ") }, { p = N("p'"), r = N("pʲ") },
    { p = N("M'"), r = N("mʲ") }, { p = N("m'"), r = N("mʲ") },
    { p = N("h'"), r = N("ç") }, { p = N("L"), r = N("lˠ") },
    { p = N("N"), r = N("nˠ") }, { p = N("R"), r = N("ɾˠ") },
    { p = N("M"), r = N("mˠ") }, { p = N("h$"), r = "" }, { p = N("#"), r = "" },
    { p = N("^%s*(.-)%s*$"), r = "%1" }, { p = N("ˈə"), r = N("ə") },
    { p = N(" "),   r = N(" ") }, { p = N("%-"), r = "" }, { p = N("MKR_"), r = "" },
    { p = N("ZZZ"), r = "" }, { p = N("&"), r = "" }, { p = N("g"), r = N("ɡ") }
}


--[[
    process_sandhi
    Applies word-boundary phonetic changes (sandhi) to a sequence of transcribed words.
    This function is designed to be called AFTER individual word transcription but BEFORE
    the final string is joined. It modifies the phonetic strings within the `words_data` table.

    @param words_data (table): An array of tables, where each inner table contains:
                              { ortho = "original_word", phon = "transcribed_phonetics" }
    @return (table): The modified words_data table.
]]
local sandhi_enabled = false
function irishPhonetics.process_sandhi(words_data)
    if not sandhi_enabled then
        return words_data -- Sandhi requires at least two words.
    end

    if not words_data or #words_data < 2 then
        return words_data -- Sandhi requires at least two words.
    end

    -- We iterate up to the second-to-last word, as each rule looks ahead.
    for i = 1, #words_data - 1 do
        local current_word = words_data[i]
        local next_word = words_data[i+1]

        -- Ensure we don't process across punctuation or major breaks.
        if not current_word.phon or not next_word.phon or current_word.phon == "" or next_word.phon == "" then
            goto continue_loop -- Lua's equivalent of 'continue'
        end

        --=====================================================================
        -- Rule 1: t-Prefix Assimilation before /s/ or /ʃ/
        -- Handles cases like "an tsúil" and "an tseilbh".
        -- The t-prefix is phonetically /t̪ˠ/ or /tʲ/.
        --=====================================================================
        if umatch(current_word.phon, "[t̪ˠtʲ]$") and umatch(next_word.phon, "^[sˠʃ]") then
            local original_phon = current_word.phon
            -- The 't' is completely assimilated and disappears phonetically.
            current_word.phon = usub(current_word.phon, 1, ulen(current_word.phon) - 1)
            
            debug_print_minimal("Sandhi", string.format("SANDHI (t-s Assimilation): Word '%s' [%s] -> [%s] before '%s'",
                current_word.ortho, original_phon, current_word.phon, next_word.ortho))
        end

        --=====================================================================
        -- Rule 2: Initial Cluster Shift (sn->sr, tn->tr)
        -- This is a very common feature in Connacht Irish.
        --=====================================================================
        if umatch(next_word.phon, "^[sˠʃ]n") then
            local original_phon = next_word.phon
            -- Replace 'n' with 'r' of the same quality.
            if umatch(next_word.phon, "^ʃn") then -- Slender case
                next_word.phon = ugsub(next_word.phon, "^ʃn", "ʃɾʲ", 1)
            else -- Broad case
                next_word.phon = ugsub(next_word.phon, "^sˠn", "sˠɾˠ", 1)
            end
            debug_print_minimal("Sandhi", string.format("SANDHI (sn->sr): Word '%s' [%s] -> [%s]",
                next_word.ortho, original_phon, next_word.phon))
        end
        if umatch(next_word.phon, "^[t̪ˠtʲ]n") then
            local original_phon = next_word.phon
            if umatch(next_word.phon, "^tʲn") then -- Slender case
                next_word.phon = ugsub(next_word.phon, "^tʲn", "tʲɾʲ", 1)
            else -- Broad case
                next_word.phon = ugsub(next_word.phon, "^t̪ˠn", "t̪ˠɾˠ", 1)
            end
            debug_print_minimal("Sandhi", string.format("SANDHI (tn->tr): Word '%s' [%s] -> [%s]",
                next_word.ortho, original_phon, next_word.phon))
        end

        --=====================================================================
        -- Rule 3: General Final/Initial Consonant Assimilation
        -- A final consonant of one word takes on the quality of the initial
        -- sound of the next word.
        --=====================================================================
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
                -- Assimilate to slender
                local base_cons = usub(final_cons, 1, 1)
                -- Simple mapping for palatalization
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
                -- Assimilate to broad (de-palatalize)
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

local apply_rules_to_string_generic_impl
apply_rules_to_string_generic_impl = function(current_string_input,
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
                elseif #current_ortho_map_local > 0 then -- Try to use the first entry of the input map if o_context is empty
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
        -- This mode builds the map from o_context_str_for_func (original orthography)
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
        -- This mode transforms current_string_local (phonetic) and updates the map
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
                -- Part 1: Handle segment before the match
                if best_match_s_phon > scan_offset_phon then
                    local unmatched_segment = usub(current_string_local, scan_offset_phon, best_match_s_phon - 1)
                    table.insert(new_string_parts, unmatched_segment)
                    -- Transfer map entries for this unmatched segment
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

                -- Part 2: Handle the matched segment
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
                -- Part 3: Handle segment after the last match (or if no matches at all)
                if scan_offset_phon <= ulen(current_string_local) then
                    local remaining_segment = usub(current_string_local, scan_offset_phon)
                    table.insert(new_string_parts, remaining_segment)
                    -- Transfer map entries for this remaining segment
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
                    -- current_new_phon_pos_accumulator = current_new_phon_pos_accumulator + ulen(remaining_segment) -- Not strictly needed as it's the end
                end
                break
            end
        end
        current_string_local = table.concat(new_string_parts)
        -- If new_ortho_map_for_output is empty but current_string_local is not (e.g. no rules matched at all)
        -- then the original map should be preserved, adjusted for the new phonetic positions (which should be 1-to-1 in this case)
        if #new_ortho_map_for_output == 0 and ulen(current_string_local) > 0 and #current_ortho_map_local > 0 then
            if ulen(current_string_local) == ulen(current_string_input) then -- No length change, means no rules applied
                new_ortho_map_for_output = current_ortho_map_local
            else                                                             -- Length changed but no rules applied? This case should be rare. Rebuild crudely.
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
    -- Fallback if mode is not recognized, return inputs (should not happen with current design)
    return current_string_local, current_ortho_map_local
end
apply_rules_to_string_generic = apply_rules_to_string_generic_impl
-- apply_rules_to_string_generic = memoize(apply_rules_to_string_generic_impl) -- Memoization with table return (map) needs careful handling or custom memoize function. For now, disable for this complex function.
-- Add this new helper function to your script, replacing the previous version.
local function process_contextual_allophony_procedurally(phon_word)
    local parsed_units = parse_phonetic_string_to_units_for_epenthesis(phon_word)
    if not parsed_units or #parsed_units == 0 then return phon_word end

    local modified_in_pass = false
    local i = 1
    while i <= #parsed_units do
        local unit = parsed_units[i]
        local rule_applied = false

        -- This block only processes simple, single-letter orthographic vowels.
        -- Placeholders for long vowels/diphthongs (e.g., MKR_PHON_A_LONG) are ignored.
        if unit.type == "vowel" and umatch(unit.phon, "^[aeiou]$") then
            local current_vowel_letter = unit.phon
            local phonetic_vowel = current_vowel_letter -- Start with the letter itself

            -- =====================================================================
            -- STEP 1: Set the DEFAULT phonetic value based on the letter.
            -- This is the fallback if no contextual rules match.
            -- =====================================================================
            if current_vowel_letter == "a" then phonetic_vowel = "a"
            elseif current_vowel_letter == "e" then phonetic_vowel = "ɛ"
            elseif current_vowel_letter == "i" then phonetic_vowel = "ɪ"
            elseif current_vowel_letter == "o" then phonetic_vowel = "ɔ" -- Default for 'o' is ɔ
            elseif current_vowel_letter == "u" then phonetic_vowel = "ʊ" -- Default for 'u' is ʊ
            end

            -- =====================================================================
            -- STEP 2: Check for CONTEXTUAL OVERRIDES in order of priority.
            -- =====================================================================

            -- BLOCK 2.1: NASAL RAISING (e.g., trom, bonn, fón, seomra)
            if i < #parsed_units then
                local next_unit = parsed_units[i+1]
                if next_unit.type == "consonant" and umatch(next_unit.phon, "^[mˠn̪ˠŋ]") then
                    if (phonetic_vowel == "ɔ" or phonetic_vowel == "ʊ") and (next_unit.phon == "mˠ" or next_unit.phon == "n̪ˠ") then
                        phonetic_vowel = "uː"
                        rule_applied = true
                        debug_print_minimal("Stage4_5", "NASAL RAISING: Applying 'ɔ/ʊ' -> 'uː' before '", next_unit.phon, "'")
                    -- This handles long vowels like in 'fón' which are passed through as placeholders
                    elseif unit.phon == "MKR_PHON_O_LONG" and (next_unit.phon == "mˠ" or next_unit.phon == "nˠ" or next_unit.phon == "n̪ˠ") then
                        phonetic_vowel = "uː"
                        rule_applied = true
                        debug_print_minimal("Stage4_5", "NASAL RAISING: Applying 'oː' -> 'uː' before '", next_unit.phon, "'")
                    end
                end
            end

            -- BLOCK 2.2: VELAR RAISING (e.g., cnoc)
            if not rule_applied and phonetic_vowel == "ɔ" and i < #parsed_units then
                local next_unit = parsed_units[i+1]
                if next_unit.type == "consonant" and umatch(next_unit.phon, "[kgx][^']?$") then
                    phonetic_vowel = "ʊ"
                    rule_applied = true
                    debug_print_minimal("Stage4_5", "VELAR RAISING: 'ɔ' -> 'ʊ' before '", next_unit.phon, "'")
                end
            end

            -- BLOCK 2.3: VOWEL GRADATION (e.g., ailt)
            if not rule_applied and phonetic_vowel == "a" and i + 2 <= #parsed_units then
                local c1 = parsed_units[i+1]
                local c2 = parsed_units[i+2]
                if c1.type == "consonant" and c2.type == "consonant" and c1.phon == "lʲ" and c2.phon == "tʲ" then
                    phonetic_vowel = "ɛ"
                    rule_applied = true
                    debug_print_minimal("Stage4_5", "VOWEL GRADATION: 'a' -> 'ɛ' before 'lʲtʲ'")
                end
            end

            -- =====================================================================
            -- STEP 3: Commit the final vowel sound to the unit.
            -- =====================================================================
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
function irishPhonetics.transcribe_single_word(orthographic_word_input)
    

    local initial_cleaned_ortho_word = N(orthographic_word_input)
    local current_word_phonetic
    local ortho_map = {}

    -- Stage 1: PreProcess (Initial Cleaning)
    current_word_phonetic, ortho_map = apply_rules_to_string_generic(
        initial_cleaned_ortho_word,
        irishPhonetics.rules_stage1_preprocess,
        "PreProcess",
        "single_pass_priority_match_build_map",
        initial_cleaned_ortho_word, -- o_context_str_for_func
        {}                          -- input_ortho_map
    )
    if STAGE_DEBUG_ENABLED["PreProcess"] then
        debug_print_minimal("PreProcess", "  END: Out=", current_word_phonetic)
    end

    -- *** NEW: STAGE 1.5 - ORTHOGRAPHIC CLUSTER SIMPLIFICATION ***
    -- This stage runs directly on the orthography before any phonetic conversion.
    local processed_ortho_word = current_word_phonetic
    local stage_name_1_5 = "Stage1_5_Ortho_Cluster_Simplification"
    if STAGE_DEBUG_ENABLED[stage_name_1_5] then
        debug_print_minimal(stage_name_1_5, "  START: In=", processed_ortho_word)
    end
    for _, rule in ipairs(irishPhonetics.rules_stage1_5_ortho_cluster_simplification) do
        processed_ortho_word = ugsub(processed_ortho_word, rule.p, rule.r)
    end
    if STAGE_DEBUG_ENABLED[stage_name_1_5] then
        debug_print_minimal(stage_name_1_5, "  END: Out=", processed_ortho_word)
    end
    -- The result of this stage becomes the new orthographic context for all subsequent stages.
    local original_ortho_for_context = processed_ortho_word


    if not current_word_phonetic or current_word_phonetic == "" then return "" end

    -- Lexical Lookup (uses the *original* cleaned word for matching)
    local exception_key_direct = current_word_phonetic
    local exception_key_no_apostrophe = ugsub(current_word_phonetic, "^'", "")
    if lexical_exceptions_connacht[exception_key_direct] then
        if STAGE_DEBUG_ENABLED["LexicalLookup"] then
            debug_print_minimal("LexicalLookup", " Found '",
                exception_key_direct, "' -> [", lexical_exceptions_connacht[exception_key_direct], "]")
        end
        return lexical_exceptions_connacht[exception_key_direct]
    elseif lexical_exceptions_connacht[exception_key_no_apostrophe] and exception_key_no_apostrophe ~= exception_key_direct then
        if STAGE_DEBUG_ENABLED["LexicalLookup"] then
            debug_print_minimal("LexicalLookup", " Found (no apostrophe) '",
                exception_key_no_apostrophe, "' -> [", lexical_exceptions_connacht[exception_key_no_apostrophe], "]")
        end
        return lexical_exceptions_connacht[exception_key_no_apostrophe]
    end

    local stages = {
        {
            name = "Stage2_5_MarkSuffixes",
            rules = irishPhonetics.rules_stage2_5_mark_suffixes,
            mode = "single_pass_priority_match_build_map"
        },
        {
            name = "MarkDigraphsAndVocalisationTriggers",
            rules = irishPhonetics.rules_stage2_mark_digraphs_and_vocalisation_triggers,
            mode = "single_pass_priority_match"
        },
        {
            name = "Stage3_1_MarkerResolution",
            rules = irishPhonetics.rules_stage3_1_marker_resolution,
            mode = "single_pass_priority_match",
            use_original_context_for_rules = true
        },
        {
            name = "Stage3_2_QualityAssignment",
            is_procedural_stage = true,
            func = function(phon_word, o_context, current_map)
                -- Parse the string from the PREVIOUS stage to get units with positional info
                local parsed_units = parse_phonetic_string_to_units_for_epenthesis(phon_word)

                -- Process these units, modifying them in place
                local modified, modified_units = process_quality_assignment_on_units(parsed_units, o_context, current_map)

                -- If any unit was changed, rebuild the string from the modified units
                if modified then
                    local rebuilt_parts = {}
                    for _, u in ipairs(modified_units) do table.insert(rebuilt_parts, u.phon) end
                    local new_phon_word = table.concat(rebuilt_parts)

                    -- The map is now invalid because string lengths have changed (e.g., c -> c').
                    -- We must return an empty/approximate map.
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
                                name =
                                "s32_rebuild"
                            })
                    end
                    return new_phon_word, new_map
                else
                    -- If no changes, pass the original string and map through
                    return phon_word, current_map
                end
            end
        },
        {
            name = "Stage3_5_ConsonantAssimilation",
            rules = irishPhonetics.rules_stage3_5_consonant_assimilation,
            mode = "iterative_gsub"
        },
        {
            name = "Stage3_2_ApplyStress",
            is_procedural_stage = true,
            func = function(phon_word, o_word_context, current_map_before_stress)
                if STAGE_DEBUG_ENABLED["Stage3_2_ApplyStress"] then
                    debug_print_minimal("Stage3_2_ApplyStress",
                        "  ApplyStress START: In=", phon_word, " (Original Ortho: '", o_word_context, "') Map size: ",
                        #current_map_before_stress)
                end
                local word_to_check_stress = o_word_context
                local should_have_stress = true
                if UNSTRESSED_WORDS_AND_SUFFIXES[word_to_check_stress] then
                    should_have_stress = false
                    debug_print_minimal("Stage3_2_ApplyStress", "ApplyStress: Word '", word_to_check_stress,
                        "' found in UNSTRESSED list.")
                else
                    for _, prefix in ipairs(UNSTRESSED_PREFIXES_ORTHO) do
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
                if STAGE_DEBUG_ENABLED["Stage3_2_ApplyStress"] then
                    debug_print_minimal("Stage3_2_ApplyStress",
                        " END: Out=", new_phon_word, " Map size: ", #new_map_after_stress)
                end
                return new_phon_word, new_map_after_stress
            end
        },
        { name = "Stage4_0_SpecificOrthoToTempMarker",   rules = irishPhonetics.rules_stage4_0_specific_ortho_to_temp_marker,    mode = "single_pass_priority_match" },
        { name = "Stage4_0_1_Resolve_CH_Marker",         rules = irishPhonetics.rules_stage4_0_1_resolve_ch_marker,              mode = "single_pass_priority_match" },
        { name = "Stage4_1_VocmarkToTempMarker",         rules = irishPhonetics.rules_stage4_1_vocmarkToTempMarker,              mode = "single_pass_priority_match" },
        { name = "Stage4_2_LongVowelsOrthoToTempMarker", rules = irishPhonetics.rules_stage4_2_long_vowels_ortho_to_temp_marker, mode = "single_pass_priority_match" },
        { name = "Stage4_3_DiphthongsOrthoToTempMarker", rules = irishPhonetics.rules_stage4_3_diphthongs_ortho_to_temp_marker,  mode = "single_pass_priority_match" },
        { name = "Stage4_4_ResolveTempVowelMarkers",     rules = irishPhonetics.rules_stage4_4_resolve_temp_vowel_markers,       mode = "iterative_gsub" },
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
                                name =
                                "s441_rebuild"
                            })
                    end
                end
                return new_phon, new_map
            end
        },
        -- In the `stages` table inside `transcribe_single_word`, replace this entire block.
        -- In the `stages` table inside `transcribe_single_word`, replace this entire block.
{
    name = "Stage4_5_ContextualAllophonyOnPhonetic",
    is_procedural_stage = true,
    func = function(phon_word, o_context, current_map)
        if STAGE_DEBUG_ENABLED["Stage4_5_ContextualAllophonyOnPhonetic"] then
            debug_print_minimal("Stage4_5_ContextualAllophonyOnPhonetic", "  START: In=", phon_word)
        end

        -- =====================================================================
        -- STEP 1: Placeholder Creation (No Change)
        -- Protects long vowels and diphthongs from being processed by the allophony rules.
        -- =====================================================================
        local temp_phon, temp_map = apply_rules_to_string_generic(phon_word, placeholder_creation_rules_stage4_5,
            "Stage4_5_P1_PlaceholderCreation", "iterative_gsub", o_context, current_map);
        debug_print_minimal("Stage4_5", "  After P1 (Placeholder): ", temp_phon)

        -- =====================================================================
        -- STEP 2: The CORRECTED Allophony Application
        -- We use a single_pass_priority_match which respects the order of the rules table.
        -- This is the key to fixing the precedence issue.
        -- =====================================================================
        temp_phon, temp_map = apply_rules_to_string_generic(temp_phon, core_allophony_rules_for_stage4_5,
            "Stage4_5_P2_CoreAllophony", "single_pass_priority_match", o_context, temp_map);
        debug_print_minimal("Stage4_5", "  After P2 (Core Allophony): ", temp_phon)

        -- =====================================================================
        -- STEP 3: Restore Placeholders (No Change)
        -- =====================================================================
        temp_phon, temp_map = apply_rules_to_string_generic(temp_phon, placeholder_restoration_rules_stage4_5,
            "Stage4_5_P3_PlaceholderRestoration", "iterative_gsub", o_context, temp_map);
        debug_print_minimal("Stage4_5", "  After P3 (Restore): ", temp_phon)

        -- =====================================================================
        -- STEP 4 (Optional but kept): Connacht-specific diphthong shift.
        -- =====================================================================
        temp_phon, temp_map = apply_rules_to_string_generic(temp_phon,
            { connacht_au_to_schwa_u_shift_rule_stage4_5 }, "Stage4_5_P4_ConnachtShift", "single_pass_priority_match",
            o_context, temp_map);
        temp_phon, temp_map = apply_rules_to_string_generic(temp_phon, { temp_conn_au_to_final_au_rule_stage4_5 },
            "Stage4_5_P5_ConnachtShiftRestore", "single_pass_priority_match", o_context, temp_map);

        if STAGE_DEBUG_ENABLED["Stage4_5_ContextualAllophonyOnPhonetic"] then
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
                                name =
                                "s451_rebuild"
                            })
                    end
                end
                return new_phon, new_map
            end
        },
        { name = "Stage4_5_2_ConnachtSpecificVowelShifts", rules = irishPhonetics.rules_stage4_5_2_connacht_specific_vowel_shifts, mode = "iterative_gsub" },
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
                if STAGE_DEBUG_ENABLED["Stage4_6_UnstressedVowelReduction_Procedural"] then
                    debug_print_minimal(
                        "Stage4_6_UnstressedVowelReduction_Procedural", "  START (Outer): In=", phon_word)
                end
                local parsed_units_for_mono_check = parse_phonetic_string_to_units_for_epenthesis(phon_word)
                if is_likely_monosyllable_phonetic_revised(phon_word, parsed_units_for_mono_check) then
                    debug_print_minimal("Stage4_6_UnstressedVowelReduction_Procedural", "Word '", phon_word, "' is monosyllabic, SKIPPING.");
                    if STAGE_DEBUG_ENABLED["Stage4_6_U"] then
                        debug_print_minimal("Stage4_6_UnstressedVowelReduction_Procedural",
                            "  END (monosyllable): Out=", phon_word)
                    end
                    return phon_word, current_map
                end
                local temp_phon, temp_map = phon_word, current_map
                temp_phon, temp_map = apply_rules_to_string_generic(temp_phon,
                    irishPhonetics.rules_stage4_6_unstressed_vowel_reduction_specific_finals, "Stage4_6_U_S1",
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
                                name =
                                "s46_rebuild"
                            })
                    end
                end
                if STAGE_DEBUG_ENABLED["Stage4_6_U"] then
                    debug_print_minimal("Stage4_6_U", "  END (Outer): Out=",
                        phon_after_proc)
                end
                return phon_after_proc, temp_map
            end
        },
        {
            name = "EpenthesisAndStrongSonorants",
            is_procedural_stage = true,
            func = function(phon_word_in_stage5, o_context_str_stage5, current_ortho_map_stage5)
                if STAGE_DEBUG_ENABLED["EpenthesisAndStrongSonorants"] then
                    debug_print_minimal(
                        "EpenthesisAndStrongSonorants", "  START (Proc): In=", phon_word_in_stage5)
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
                                ortho_e = ulen(
                                    o_context_str_stage5),
                                name = "epent_rebuild"
                            })
                    end
                end
                debug_print_minimal("EpenthesisAndStrongSonorants", "After procedural epenthesis: ",
                    phon_after_epenthesis)
                local phon_after_strong_son, map_after_strong_son = apply_rules_to_string_generic(phon_after_epenthesis,
                    irishPhonetics.rules_stage5_strong_sonorants_only, "EpenthesisAndStrongSonorants_StrongSon",
                    "single_pass_priority_match", o_context_str_stage5, map_after_epenthesis)
                debug_print_minimal("EpenthesisAndStrongSonorants", "After strong sonorant rules: ",
                    phon_after_strong_son)
                if STAGE_DEBUG_ENABLED["EpenthesisAndStrongSonorants"] then
                    debug_print_minimal(
                        "EpenthesisAndStrongSonorants", " END (Proc): Out=", phon_after_strong_son)
                end
                return phon_after_strong_son, map_after_strong_son
            end
        },
        { name = "Diacritics",                             rules = irishPhonetics.rules_stage6_diacritics,                         mode = "iterative_gsub" },
        { name = "FinalCleanup",                           rules = irishPhonetics.rules_stage7_final_cleanup,                      mode = "iterative_gsub" }
    }

    current_word_phonetic = original_ortho_for_context
    ortho_map = {}

    if STAGE_DEBUG_ENABLED["PreProcess"] then
        debug_print_minimal("PreProcess",
            string.format("Start of main stages loop. Input to MarkDigraphs: [%s]", current_word_phonetic))
    end

    for i, stage_data in ipairs(stages) do
        local stage_start_time = os.clock()
        local stage_name = stage_data.name
        local string_before_stage = current_word_phonetic
        local map_before_stage_size = #ortho_map

        if STAGE_DEBUG_ENABLED[stage_name] and not stage_data.is_procedural_stage then
            debug_print_minimal(stage_name, "  " .. stage_name .. " START: In=", current_word_phonetic, " Map size: ",
                map_before_stage_size)
        end

        if stage_data.is_procedural_stage and type(stage_data.func) == "function" then
            current_word_phonetic, ortho_map = stage_data.func(current_word_phonetic, original_ortho_for_context,
                ortho_map)
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
        if STAGE_DEBUG_ENABLED[stage_name] then
            if not stage_data.is_procedural_stage then
                debug_print_minimal(stage_name, " END: Out=", current_word_phonetic, " Map size: ", #ortho_map)
            end
            if STAGE_DEBUG_ENABLED.Performance then
                debug_print_minimal(stage_name,
                    string.format("PERF: Stage %s took %.6f seconds for input: %s", stage_name,
                        stage_end_time - stage_start_time, orthographic_word_input))
            end
        end
        if string_before_stage ~= current_word_phonetic or map_before_stage_size ~= #ortho_map then
            if STAGE_DEBUG_ENABLED[stage_name] then
                debug_print_minimal(stage_name, string.format("Af. %s: [%s]", stage_name, current_word_phonetic))
            end
        end
    end
    return current_word_phonetic
end

function irishPhonetics.transcribe(orthographic_phrase)
    -- 1. Split the input phrase into a table of words and spaces.
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

    -- 2. Transcribe only the 'word' components.
    for i, component in ipairs(components) do
        if component.type == "word" then
            component.phon = irishPhonetics.transcribe_single_word(component.ortho)
        else
            component.phon = component.ortho -- Spaces remain as they are.
        end
    end

    -- 3. *** APPLY THE SANDHI STAGE ***
    -- The sandhi function operates on the table of transcribed components.
    components = irishPhonetics.process_sandhi(components)

    -- 4. Join the final phonetic parts into a single string.
    local final_phonetic_parts = {}
    for _, component in ipairs(components) do
        table.insert(final_phonetic_parts, component.phon)
    end
    
    return table.concat(final_phonetic_parts, "")
end

local RUN_DEFAULT_TESTS_IF_NO_INPUT = true

-- Check for command-line argument first
local input = arg[1]
if arg[1] ~= "--d" then
    input = arg[1]
else
    input = nil
end
local showDebug = arg[2] == "--d" or arg[1] == "--d"
if showDebug then
    MINIMAL_DEBUG_ENABLED = true
else
    MINIMAL_DEBUG_ENABLED = false
end

-- Debug Flags
if MINIMAL_DEBUG_ENABLED then
    -- Debug output file setup
    local debug_file_path = "irish_debug_43_lua_p_strict.txt"
    debug_file = io.open(debug_file_path, "w")
    if debug_file then
        debug_file:write("\239\187\191")
    else
        original_print("WARN: Could not open debug_file " .. debug_file_path)
    end
    local original_print_func = print
    STAGE_DEBUG_ENABLED = {
        PreProcess = false,
        MarkDigraphsAndVocalisationTriggers = true,
        Stage2_5_MarkSuffixes = true,
        Stage3_1_MarkerResolution = true,
        ConsonantResolution = true,
        Stage3_2_ApplyStress = true,
        Stage4_0_SpecificOrthoToTempMarker = true,
        Stage4_0_1_Resolve_CH_Marker = true,
        Stage4_1_VocmarkToTempMarker = true,
        Stage4_2_LongVowelsOrthoToTempMarker = true,
        Stage4_3_DiphthongsOrthoToTempMarker = true,
        Stage4_4_ResolveTempVowelMarkers = true,
        Stage4_4_1_VocalizeLenitedFricatives = true,
        Stage4_5_ContextualAllophonyOnPhonetic = true,
        Stage4_5_1_DisyllabicShortLongRaising = true,
        Stage4_5_2_ConnachtSpecificVowelShifts = true,
        Nasalization = true,
        Stage4_6_UnstressedVowelReduction_Procedural = true,
        EpenthesisAndStrongSonorants = true,
        Diacritics = true,
        FinalCleanup = true,
        Parser = false,
        ParserSetup = false,
        LexicalLookup = false,
        Performance = false
    }
else
    STAGE_DEBUG_ENABLED = {
        PreProcess = false,
        MarkDigraphsAndVocalisationTriggers = false,
        Stage2_5_MarkSuffixes = false,
        ConsonantResolution = false,
        Stage4_0_SpecificOrthoToTempMarker = false,
        Stage4_0_1_Resolve_CH_Marker = false,
        Stage4_1_VocmarkToTempMarker = false,
        Stage4_2_LongVowelsOrthoToTempMarker = false,
        Stage4_3_DiphthongsOrthoToTempMarker = false,
        Stage4_4_ResolveTempVowelMarkers = false,
        Stage4_4_1_VocalizeLenitedFricatives = false,
        Stage4_5_ContextualAllophonyOnPhonetic = false,
        Stage4_5_1_DisyllabicShortLongRaising = false,
        Stage4_5_2_ConnachtSpecificVowelShifts = false,
        Nasalization = false,
        Stage4_6_UnstressedVowelReduction_Procedural = false,
        EpenthesisAndStrongSonorants = false,
        Diacritics = false,
        FinalCleanup = false,
        Parser = false,
        ParserSetup = false,
        LexicalLookup = false,
        Performance = false
    }
    
end
-- If no command-line argument, check if there's anything being piped in
if not input then
    -- io.stdin:seek("end") gets the current size of the stdin buffer.
    -- If it's greater than 0, it means there's data waiting to be read (from a pipe).
    -- If it's 0, it means the script was run without arguments and without a pipe.
    if io.stdin:seek("end") then
        io.stdin:seek("set")  -- Rewind the buffer to the beginning to read it
        input = io.read("*a") -- Read all available input
    end
end

-- Now, decide what to do based on whether we have input or not
if input then
    -- Behavior 1 & 2: We have input from either an argument or a pipe
    original_print_func(irishPhonetics.transcribe(N(input)))
else
    -- Behavior 3: No input was provided, so run the default tests if the flag is set
    if RUN_DEFAULT_TESTS_IF_NO_INPUT then
        local words_to_test_focused = {
            "Caitliceach", "Déardaoin", "Gaeltacht", "bhFranc", "leabhar",
            "goib", "mhairbh", "cheird", "ghníomh", "Gaeil"
        }

        local words_to_test_focused = {
            'gainne', 'tchí', 'teith', 'tarraingt', 'gceárta', 'snátha',
            'héis', 'féich', 'mhair', 'comhair', 'ais', 'gaire', 'caillim',
            'coisreacaim', 'luibh', 'duibh', 'shín', 'laistigh', '-ófaí',
            'ghníomh', 'claidh', 'uath', 'croíthe', 'láimh', 'bhoid',
            'gach uile', 'ts', 'bhfichidí', 'feadha', 'chonaic', 'Eoghan',
            'leá', 'libh', 'cóireáil', 'Eoghan', 'h', 'fiodh', 'cnogaí',
            'caife', 'leath', 'bhuí', 'bhfir', 'cainte', 'chomhair', 'bhainc',
            'hois', 'theo', 'ciumhaise', 'éan', 'colbha', 'déanamh', 'guí',
            'sh', 'éad', 'seabhac', 'India', 'áibhirseoir', 'sábh', 'séimh',
            'chirt', 'díomhaoin', 'cairéalaí', 'mhaidin', 'sheaicéad',
            'cnó Brasaíleach', 'úim', 'scairt', 'ailm', 'dhíobháil',
            'airgead', 'téigh', 'ail', 'dtiocfainn', 'Airméanach', 'héin',
            'th', 'leith', 'buíon', 'cailceanna', 'chéasta', 'chath',
            'go raibh maith agaibh', 'íosfaidh', 'fhéar', 'naíonda', 'hÍ',
            'chnáimh', 'guíonna', 'chéanna', 'culaith', 'bhuíoch',
            'gcéadta', 'Nás', 'bhfeirm', 'uafás', 'mhaith', 'faigh',
            'Dubhghall', 'Méabh', 'caithfidh'
        }

        local words_to_test_focused = { "Indiacha", "leabhar", "Eoghan", "luibh", "bhfir", "bhfearthainn" }

        local words_to_test_focused_from_errors = {
            -- Suffix / Grammatical Word Issues
            "'ur",   -- Expected: ə, Script: əɾˠ (final r handling in unstressed word)
            "-fas",  -- Expected: həsˠ, Script: fˠasˠ (lenition of f in suffix)
            "-fidh", -- Expected: iː, ə, Script: ˈfʲiː (dh vocalization/deletion in suffix)
            "-igh",  -- Expected: j, Script: ˈɪç (gh realization in suffix)
            "-íonn", -- Expected: iːn̪ˠ, Script: ˈiːʊn̪ˠ (spurious vowel in suffix)

            -- Vowel Quality & Diphthongization (especially initial 'a' vs 'ai')
            "Airméanach", -- Expected: ˈaɾʲəmʲeːnˠəx, Script: ˈaiɾʲmʲeːanˠax
            "Albain",     -- Expected: ˈalˠəbˠənʲ, Script: ˈalʲbʲainʲ
            "Caiseal",    -- Expected: ˈkaʃəlˠ, Script: ˈcaiʃɑlˠ
            "abhaile",    -- Expected: əˈwalʲə, Script: ˈavʲailʲɛ (initial schwa, a vs ai)

            -- Lenited Consonants (bh, mh, dh, gh, fh) Vocalization/Realization
            "Aodh",      -- Expected: eː, iː, Script: ˈiːɣ (gh not fully vocalized)
            "Dubhghall", -- Expected: ˈd̪ˠʊwəl̪ˠ, Script: ˈd̪ˠʊvˠɣal̪ˠ (bh/gh as w vs v/ɣ)
            "Eoghan",    -- Expected: oːnˠ, Script: ˈoːɣanˠ (gh vocalization)
            "fheadha",   -- Expected: ɑː, Script: ˈaɣa (fh silent, dh vocalization)
            "mhac",      -- Expected: wak, Script: ˈvˠak (initial mh as w vs v)
            "bhfuil",    -- Expected: bˠilʲ, Script: ˈwiːlʲ (eclipsed f, but target shows b) - This target is interesting, might be a typo or specific context.

            -- Proper Nouns / Highly Irregular
            "Iúr",       -- Expected: ən̠ʲˈtʲuːɾˠ, Script: ˈɔɾˠ (major lexical error)
            "Laoghaire", -- Expected: ˈl̪ˠiːɾʲə, Script: ˈl̪ˠiːjaiɾʲɛ (gh vocalization, ao vowel)
            "Mumhain",   -- Expected: mˠuːnʲ, Script: ˈmˠʊvʲainʲ (mh vocalization affecting vowel)

            -- Broad/Slender Consonant Quality Mismatches
            -- (Albain also fits here, but already included)
            "anglais", -- Expected: ˈaŋɡlˠəʃ, Script: ˈaŋlʲaiʃ (l quality)

            -- Nasal Raising / Sonorant Interactions
            "amhrán", -- Expected: ˈoːɾˠɑːnˠ, Script: əuɾˠɾˠɑːnˠ (amh -> əu, target might be different dialect)
            "seomra", -- (Not in your list, but from Hickey, good for nasal raising: o -> u)
            -- Add if you want to test nasal raising specifically: "seomra",

            -- Epenthesis or lack thereof
            "ailm", -- Expected: ˈa.lʲəmʲ, Script: ˈailʲmʲ (epenthesis expected vs. not by script)

            -- Specific Consonant Clusters / Other
            "Sh",             -- Expected: h, Script: "" (Handling of isolated lenited s)
            "Th",             -- Expected: h, Script: "" (Handling of isolated lenited t)
            "Tadhg",          -- Expected: t̪ˠai(ə)ɡ, Script: ˈt̪ˠaɣɡ (dhg cluster)
            "Toirdhealbhach", -- Expected: ˈtʲɾʲɛl̪ˠax, Script: ˈtʲɛɾʲjalvˠax (complex internal changes)

            -- Words where map degradation after iterative_gsub might become an issue for later stages
            -- (though the current errors might be from rules before map degradation)
            "Gaedhilge" -- Expected: ˈɡeːlʲɟə, Script: ˈɟeːjɪlʲɟɛ
        }
        words_to_test_focused_from_errors = {"thua","thug","thugainn","thuig","thur","thángthas","théigh","thóg","thóir","thú","thúis","tuíodóireacht","tá a fhios ag","téigh","téigh","uafás","uaigh","uaigh","uaigh","uaimh","uainn","uath","umhal","veigeán","vác","yé","Ó Cathasaigh","áibhirseoir","áith","áitithe","áitithe","átha","éagrábhadh","éilítear","ógfhear","úth",}
        words_to_test_focused_from_errors = {"sheol","thug","shúil","Sheáin","théigh","a theach","chugham","Eoghan","Laoghaire","beirbhiughadh","láimh","comhairle","chnáimh","ghníomh","tnúth","Tadhg","comhartha","Airméanach","mairbh","cailc","feirm","íocfaidh","abhaile","ailm","mairc","dearg","Iúr","Toirdhealbhach","suaimhneas","ríomhleabhar","lonnaithe",
        }
        local sh_th_test_set = {
            -- =====================================================================
            -- 1. sh/th + SLENDER VOWEL (Expected: [h])
            -- =====================================================================
        
            -- sh + slender vowel
            { word = "shíl",    target = "hiːlʲ",   comment = "sh + í (slender) -> [h]" },
            { word = "shinn",   target = "hɪnʲ",    comment = "sh + i (slender) -> [h]" },
            { word = "sheinn",  target = "hɛnʲ",    comment = "sh + ei (slender) -> [h]" },
            { word = "sheoladh",target = "hɛlˠə",   comment = "sh + eo (slender) -> [h] (eo can be slender context)" },
            { word = "shleamhain", target = "hlʲəunʲ", comment = "sh + l + ea (slender) -> [h]" }, -- Complex cluster
        
            -- th + slender vowel
            { word = "thit",    target = "hɪtʲ",    comment = "th + i (slender) -> [h]" },
            { word = "théigh",  target = "heːj",    comment = "th + é (slender) -> [h]" },
            { word = "theas",   target = "hæsˠ",    comment = "th + ea (slender) -> [h]" },
            { word = "thine",   target = "hɪnʲə",   comment = "th + i (slender) -> [h]" },
        
            -- =====================================================================
            -- 2. sh/th + BROAD VOWEL (Expected: [ç])
            -- =====================================================================
        
            -- sh + broad vowel
            { word = "shábháil",target = "çɑːvˠɑːlʲ", comment = "sh + á (broad) -> [ç]" },
            { word = "shocair", target = "çɔkəɾʲ",   comment = "sh + o (broad) -> [ç]" },
            { word = "shúile",  target = "çuːlʲə",   comment = "sh + ú (broad) -> [ç]" },
            { word = "shaoil",  target = "çiːlʲ",    comment = "sh + ao (broad) -> [ç]" }, -- ao is broad context
            { word = "shuan",   target = "çuənˠ",    comment = "sh + ua (broad) -> [ç]" },
        
            -- th + broad vowel
            { word = "thóg",    target = "çoːɡ",    comment = "th + ó (broad) -> [ç]" },
            { word = "thuaidh", target = "çuəj",    comment = "th + ua (broad) -> [ç]" },
            { word = "tháinig", target = "çɑːnʲɪɟ",  comment = "th + á (broad) -> [ç]" },
            { word = "thogha",  target = "çɔɣə",    comment = "th + o (broad) -> [ç]" },
            { word = "thú",     target = "çuː",     comment = "th + ú (broad) -> [ç]" },
        
            -- =====================================================================
            -- 3. Edge Cases / Specific Contexts
            -- =====================================================================
        
            -- Isolated sh/th (should default to [h] as no following vowel)
            { word = "Sh",      target = "h",       comment = "Isolated Sh -> [h] (no following vowel)" },
            { word = "Th",      target = "h",       comment = "Isolated Th -> [h] (no following vowel)" },
        
            -- Medial sh/th (should follow the same rules as initial)
            { word = "aithrí",  target = "ahɾʲiː",  comment = "Medial th + i (slender) -> [h]" },
            { word = "fáthach", target = "fɑːhəx",  comment = "Medial th + a (slender) -> [h]" },
            { word = "oíche",   target = "iːhə",    comment = "Medial ch (from th) + e (slender) -> [h]" }, -- Assuming ch is from th
            { word = "cathaoir",target = "kahiːɾʲ",  comment = "Medial th + a (slender) -> [h]" },
        
            -- Words that previously caused issues (re-test for regression)
            { word = "Sheáin",  target = "çɑːnʲ",   comment = "sh + á (broad) -> [ç] (regression test)" },
            { word = "a theach",target = "əhæx",   comment = "th + ea (slender) -> [h] (regression test)" },
            { word = "thúis",   target = "çuːʃ",    comment = "th + ú (broad) -> [ç] (regression test)" },
        }
        original_print_func(
            "\n--- Running Default Test Set (No Input Provided) ---")
        if debug_file then
            debug_file:write(
                "\n--- Running Default Test Set (No Input Provided) ---\n")
        end

        STAGE_DEBUG_ENABLED.Parser = false;
        STAGE_DEBUG_ENABLED.ParserSetup = false

        for _, word_or_phrase in ipairs(words_to_test_focused_from_errors) do
            if word_or_phrase.word ~= nil then
                word_or_phrase = word_or_phrase.word
            end
            local original = word_or_phrase
            original_print_func("\n--- Transcribing:", original, "---")
            if debug_file then
                debug_file:write(string.format("\n--- Transcribing: %s ---\n",
                    original))
            end
            local transcribed = irishPhonetics.transcribe(original)
            original_print_func(string.format("%-30s -> [%s]", original,
                transcribed))
            if debug_file then
                debug_file:write(string.format("%-30s -> [%s]\n", original,
                    transcribed))
            end
        end
    else
        original_print_func(
            "No input provided. To run tests, set RUN_DEFAULT_TESTS_IF_NO_INPUT to true.")
        original_print_func("Usage: lua your_script.lua \"text to transcribe\"")
        original_print_func(
            "   or: echo \"text to transcribe\" | lua your_script.lua")
    end
end

return irishPhonetics

