-- irish_phonetics_43_lua_p_strict.lua

-- Determine the directory of the current script
local function getScriptDirectory()
    local info = debug.getinfo(1, "S")
    local scriptPath = info.source:sub(2)
    local dir = scriptPath:match("(.*/)")
    if not dir then
        dir = scriptPath:match("(.*\\)")
    end
    if not dir then
        return ""
    end
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

memoize = require('memoize')


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
local debug_file_path = "irish_debug_43_lua_p_strict.txt"
local debug_file = io.open(debug_file_path, "w")
if debug_file then debug_file:write("\239\187\191") else original_print("WARN: Could not open debug_file " ..
    debug_file_path) end
local original_print_func = print

-- Debug Flags
local MINIMAL_DEBUG_ENABLED = true
if MINIMAL_DEBUG_ENABLED then
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
        Performance = false,
    }
else
    STAGE_DEBUG_ENABLED = {
        PreProcess = true,
        MarkDigraphsAndVocalisationTriggers = true,
        Stage2_5_MarkSuffixes = true,
        ConsonantResolution = true,
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
        LexicalLookup = true,
        Performance = true,
    }
end
print = function(...)
    local msg = table.concat({ ... }, "\t")
    original_print_func(msg)
    if debug_file then
        if msg:match("^%-%-%- Transcribing:") or msg:match("^%-*%s*-> %[%s*%S") or (MINIMAL_DEBUG_ENABLED and msg:match("^    MIN_DBG")) or msg:match("^PERF:") then
            debug_file:write(msg .. "\n"); debug_file:flush()
        elseif not MINIMAL_DEBUG_ENABLED then
            debug_file:write(msg .. "\n"); debug_file:flush()
        end
    end
end

local function debug_print_minimal(stage_name, ...)
    if MINIMAL_DEBUG_ENABLED and STAGE_DEBUG_ENABLED[stage_name] then
        print("    MIN_DBG (" .. stage_name:sub(1, 10) .. "): " .. table.concat({ ... }, "\t"))
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

local DIPHTHONG_LITERALS_FOR_PRIORITY = { "eiə~", "eiə", "iə~", "ua~", "ai~", "ei~", "oi~", "ui~", "ɑu~", "ou~", "əu~",
    "aw~", "əi~", "iə", "ua", "ai", "ei", "oi", "ui", "ɑu", "ou", "əu", "aw", "əi" }
local PHONETIC_VOWEL_NUCLEUS_PATTERN_PARTS = {}
for _, diph_lit in ipairs(DIPHTHONG_LITERALS_FOR_PRIORITY) do
    table.insert(PHONETIC_VOWEL_NUCLEUS_PATTERN_PARTS,
        "(" .. ugsub(diph_lit, "([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1") .. ")")
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

local BROAD_LNM_MARKERS_FOR_STAGE5 = { ZZZ_N_STR_BRD_PHON, ZZZ_L_STR_BRD_PHON, ZZZ_N_SNG_BRD_PHON, ZZZ_L_SNG_BRD_PHON,
    toNFC("m"), toNFC("M") }
local PALATAL_LNM_MARKERS_FOR_STAGE5 = { ZZZ_N_STR_PAL_PHON, ZZZ_L_STR_PAL_PHON, toNFC("n'"), toNFC("N'"), toNFC("l'"),
    toNFC("L'"), toNFC("m'"), toNFC("M'") }
local BROAD_R_MARKERS_FOR_STAGE5 = { toNFC("R"), toNFC("r") }
local PALATAL_R_MARKERS_FOR_STAGE5 = { toNFC("R'"), toNFC("r'") }

ALL_PHONETIC_CONSONANTS_INTERMEDIATE_PRIORITY = {
    toNFC(ZZZ_N_STR_PAL_PHON), toNFC(ZZZ_N_STR_BRD_PHON), toNFC(ZZZ_L_STR_PAL_PHON), toNFC(ZZZ_L_STR_BRD_PHON),
    toNFC(ZZZ_N_SNG_BRD_PHON), toNFC(ZZZ_L_SNG_BRD_PHON),
    toNFC("k'"), toNFC("g'"), toNFC("t'"), toNFC("d'"), toNFC("s'"), toNFC("l'"), toNFC("n'"), toNFC("r'"),
    toNFC("f'"), toNFC("v'"), toNFC("b'"), toNFC("p'"), toNFC("m'"), toNFC("L'"), toNFC("N'"), toNFC("R'"), toNFC("M'"),
    toNFC("h'"), toNFC("lˠ"), toNFC("nˠ"), toNFC("ɾˠ"), toNFC("mˠ"), toNFC("t̪"), toNFC("d̪"), toNFC("n̪"), toNFC("l̪"),
    toNFC("n̠ʲ"), toNFC("l̠ʲ"), toNFC("n̪ˠ"), toNFC("l̪ˠ"),
    toNFC("c"), toNFC("ɟ"), toNFC("ʃ"), toNFC("ç"), toNFC("j"), toNFC("k"), toNFC("g"), toNFC("t"), toNFC("d"), toNFC(
"p"), toNFC("b"),
    toNFC("m"), toNFC("n"), toNFC("l"), toNFC("r"), toNFC("s"), toNFC("f"), toNFC("v"), toNFC("L"), toNFC("N"), toNFC(
"R"), toNFC("M"),
    toNFC("x"), toNFC("ɣ"), toNFC("ŋ"), toNFC("h"), toNFC("w")
}
ALL_PHONETIC_NUCLEI_PRIORITY = { toNFC("eiə~"), toNFC("eiə"), toNFC("ɑ~ː"), toNFC("e~ː"), toNFC("i~ː"), toNFC("o~ː"),
    toNFC("u~ː"), toNFC("ɨ~ː"), toNFC("æ~ː"), toNFC("ɑː"), toNFC("eː"), toNFC("iː"), toNFC("oː"), toNFC("uː"), toNFC(
"ɨː"), toNFC("æː"), toNFC("iə~"), toNFC("ua~"), toNFC("ai~"), toNFC("ei~"), toNFC("oi~"), toNFC("ui~"), toNFC("ɑu~"),
    toNFC("ou~"), toNFC("əu~"), toNFC("aw~"), toNFC("əi~"), toNFC("iə"), toNFC("ua"), toNFC("ai"), toNFC("ei"), toNFC(
"oi"), toNFC("ui"), toNFC("ɑu"), toNFC("ou"), toNFC("əu"), toNFC("aw"), toNFC("əi"), toNFC("a~"), toNFC("æ~"), toNFC(
"ɑ~"), toNFC("ɔ~"), toNFC("e~"), toNFC("ɛ~"), toNFC("ə~"), toNFC("i~"), toNFC("ɪ~"), toNFC("u~"), toNFC("ʊ~"), toNFC(
"ʌ~"), toNFC("a"), toNFC("æ"), toNFC("ɑ"), toNFC("ɔ"), toNFC("e"), toNFC("ɛ"), toNFC("ə"), toNFC("i"), toNFC("ɪ"), toNFC(
"u"), toNFC("ʊ"), toNFC("ʌ"), toNFC("ʊ̽") }
local COMBINED_PHONETIC_UNITS_PRIORITY = {}
do
    local t = {}
    for _, p_str in ipairs(ALL_PHONETIC_NUCLEI_PRIORITY) do table.insert(t, { phon = p_str, type = "vowel" }) end
    for _, p_str in ipairs(ALL_PHONETIC_CONSONANTS_INTERMEDIATE_PRIORITY) do table.insert(t,
            { phon = p_str, type = "consonant" }) end
    table.sort(t, function(a, b) return ulen(a.phon) > ulen(b.phon) end)
    COMBINED_PHONETIC_UNITS_PRIORITY = t
end

local lexical_exceptions_connacht = {
    [toNFC("ar")] = toNFC("ɛɾʲ"), -- Keep if this is the desired general pronunciation for 'ar'
    [toNFC("ach")] = toNFC("əx"),
    [toNFC("am")] = toNFC("əmˠ"),
    -- [toNFC("air")] = toNFC("ɛɾʲ"), -- 'air' is often context-dependent, consider if this is always right
    [toNFC("car")] = toNFC("kɑɾˠ"),
    [toNFC("'sé")] = toNFC("ʃeː"),
    [toNFC("sé")] = toNFC("ʃeː"), -- Add unstressed version too
    [toNFC("Iúr")] = toNFC("ən̠ʲˈtʲuːɾˠ"),
    [toNFC("an tIúr")] = toNFC("ən̠ʲˈtʲuːɾˠ"), -- More explicit form
    [toNFC("gníomhaíocht")] = toNFC("ˈɡɾˠiːwiəxt̪ˠ"),
    [toNFC("shleamhnaigh")] = toNFC("ˈhlʲəun̪ˠə"),
    [toNFC("amharc")] = toNFC("ˈəuɾˠək"),
    [toNFC("oíche")] = toNFC("ˈiːhə"),
    [toNFC("droichead")] = toNFC("ˈd̪ˠɾˠɛhəd̪ˠ"),
    [toNFC("Mhacha")] = toNFC("ˈwaxə"),
    [toNFC("Mhuire")] = toNFC("ˈwɪɾʲə"),
    [toNFC("Taoiseach")] = toNFC("ˈt̪ˠiːʃəx"), -- Target from previous analysis
    [toNFC("abhainn")] = toNFC("ˈəun̠ʲ"),
    [toNFC("Aodh")] = toNFC("ˈiː"),
    [toNFC("Connacht")] = toNFC("ˈkʊn̪ˠəxt̪ˠ"),
    [toNFC("Chonnacht")] = toNFC("ˈxʊn̪ˠəxt̪ˠ"),
    [toNFC("cnuimh")] = toNFC("ˈkɾˠɪvʲ"),
    [toNFC("fheadh")] = toNFC("ˈa"),
    [toNFC("d'fhág")] = toNFC("ˈd̪ˠɑːɡ"),
    [toNFC("Iodáil")] = toNFC("ˈɪd̪ˠɑːlʲ"),
    [toNFC("síofra")] = toNFC("ˈʃiːfˠɾˠə"),
    [toNFC("aonbheannach")] = toNFC("ˈeːnˠvʲan̪ˠəx"),
    [toNFC("Bíobla")] = toNFC("ˈbʲiːbˠl̪ˠə"),
    [toNFC("aríst")] = toNFC("əˈɾʲiːʃtʲ"),
    [toNFC("éiclips")] = toNFC("ˈeːclʲɪpˠsˠ"),
    [toNFC("Luaithrigh")] = toNFC("ˈl̪ˠuəhɾʲi"),
    [toNFC("Nua")] = toNFC("ˈn̪ˠuː"),
    [toNFC("úth")] = toNFC("ˈʊt̪ˠ"),
    [toNFC("Afganastáin")] = toNFC("afˠˈɡan̪ˠəsˠt̪ˠɑːnʲ"),
    [toNFC("Bhaile")] = toNFC("ˈbˠalʲə"),
    [toNFC("Átha")] = toNFC("ˈɑːhə"),
    [toNFC("Cliath")] = toNFC("ˈclʲiə"),
    -- Droichead already added
    [toNFC("Fhranc")] = toNFC("ˈɾˠaŋk"),
    [toNFC("Loch")] = toNFC("ˈl̪ˠɔx"),
    [toNFC("Garman")] = toNFC("ˈɡaɾˠəmˠən̪ˠ"),
    [toNFC("Tiobraid")] = toNFC("ˈtʲʊbˠɾˠədʲ"),
    [toNFC("Árann")] = toNFC("ˈɑːɾˠən̪ˠ"),
    [toNFC("'un")] = toNFC("ən̪ˠ"),
    [toNFC("un")] = toNFC("ən̪ˠ"), -- Add unstressed version
    [toNFC("'ur")] = toNFC("əɾˠ"),
    [toNFC("ur")] = toNFC("əɾˠ"), -- Add unstressed version
    [toNFC("adhmad")] = toNFC("ˈəimˠəd̪ˠ"),
}

local UNSTRESSED_WORDS_AND_SUFFIXES = {
    ["'un"]=true, ["un"]=true, ["'ur"]=true, ["ur"]=true,
    ["-as"]=true, ["-sa"]=true, ["-se"]=true, ["-ne"]=true, ["-na"]=true, ["-im"]=true, 
    ["-fas"]=true, ["-fá"]=true, ["-fí"]=true, ["-tá"]=true, ["-ím"]=true, ["-óidh"]=true, 
    ["-ithe"]=true, ["-aimid"]=true, ["-aíonn"]=true, ["-idís"]=true, -- Added from new JSON
    ["a"]=true, ["a'"]=true, ["a-"]=true,
    ["ab"]=true, ["ach"]=true, ["ad"]=true, ["ag"]=true, ["an"]=true, ["ar"]=true, ["as"]=true,
    ["ba"]=true, ["bh"]=true, ["bhf"]=true,
    ["ch"]=true,
    ["de"]=true, ["do"]=true, ["dh"]=true, ["dh'"]=true,
    ["go"]=true, ["gh"]=true,
    ["i"]=true, ["is"]=true,
    ["le"]=true,
    ["mar"]=true, ["mh"]=true,
    ["ní"]=true, ["níl"]=true,
    ["os"]=true, ["ó"]=true,
    ["ph"]=true,
    ["sa"]=true, ["se"]=true, ["sh"]=true,
    ["th"]=true, ["th'"]=true,
    ["um"]=true,
}


local function get_original_indices_from_map(phon_s, phon_e, current_map)
    local o_s_final, o_e_final = phon_s, phon_e; local orig_len_final = phon_e - phon_s + 1
    if not current_map or #current_map == 0 then return o_s_final, orig_len_final end
    local first_char_map_entry, last_char_map_entry
    for i = 1, #current_map do
        local entry = current_map[i]; if entry.phon_s <= phon_s and entry.phon_e >= phon_s then
            first_char_map_entry = entry; break
        end
    end
    for i = #current_map, 1, -1 do
        local entry = current_map[i]; if entry.phon_s <= phon_e and entry.phon_e >= phon_e then
            last_char_map_entry = entry; break
        end
    end
    if first_char_map_entry then o_s_final = first_char_map_entry.ortho_s + (phon_s - first_char_map_entry.phon_s) end
    if last_char_map_entry then o_e_final = last_char_map_entry.ortho_e - (last_char_map_entry.phon_e - phon_e) elseif first_char_map_entry then o_e_final =
        o_s_final + (phon_e - phon_s) end
    if o_s_final and o_e_final then
        orig_len_final = o_e_final - o_s_final + 1; if orig_len_final <= 0 then
            o_s_final = first_char_map_entry and first_char_map_entry.ortho_s or phon_s; orig_len_final = (phon_e - phon_s + 1); o_e_final =
            o_s_final + orig_len_final - 1
        end
    else
        o_s_final, o_e_final = phon_s, phon_e; orig_len_final = phon_e - phon_s + 1
    end
    return o_s_final, orig_len_final
end




local get_ortho_vowel_quality_implication_from_char_or_group_impl
get_ortho_vowel_quality_implication_from_char_or_group_impl = function(v_char_or_group,
                                                                       is_for_preceding_consonant_context)
    if not v_char_or_group or ulen(v_char_or_group) == 0 then return nil end

    -- Normalize common acute accents to their base for group matching
    local normalized_v_group = v_char_or_group
    normalized_v_group = ugsub(normalized_v_group, "á", "a")
    normalized_v_group = ugsub(normalized_v_group, "é", "e")
    normalized_v_group = ugsub(normalized_v_group, "í", "i")
    normalized_v_group = ugsub(normalized_v_group, "ó", "o")
    normalized_v_group = ugsub(normalized_v_group, "ú", "u")

    local first_char_of_group = usub(v_char_or_group, 1, 1)
    local last_char_of_group = usub(v_char_or_group, ulen(v_char_or_group), ulen(v_char_or_group))

    if is_for_preceding_consonant_context then -- Quality determined by the START of the following vowel group
        -- Explicit slenderizing digraphs/trigraphs
        if normalized_v_group == "ei" or normalized_v_group == "eu" or normalized_v_group == "eo" or
            normalized_v_group == "ea" or normalized_v_group == "ia" or normalized_v_group == "io" or
            normalized_v_group == "iu" or normalized_v_group == "ae" or normalized_v_group == "ai" or -- ai can be broad if final, but slender if initial for preceding C
            normalized_v_group == "oi" or                                                            -- oi can be broad if final, but slender if initial for preceding C
            v_char_or_group == "aoi" or v_char_or_group == "aei" or v_char_or_group == "uai" then    -- Keep accents for these specific trigraphs
            return "slender"
        end
        -- Explicit broad digraphs
        if normalized_v_group == "ui" then return "broad" end -- ui is broad for preceding C
        if normalized_v_group == "ao" or normalized_v_group == "ua" or normalized_v_group == "ou" then
            return "broad"
        end

        -- Fallback to first character
        if umatch(first_char_of_group, SLENDER_VOWELS_ORTHO_PATTERN) then
            return "slender"
        elseif umatch(first_char_of_group, BROAD_VOWELS_ORTHO_PATTERN) then
            return "broad"
        end
    else -- Quality determined by the END of the preceding vowel group
        -- Explicit slenderizing digraphs/trigraphs
        if v_char_or_group == "aoi" or v_char_or_group == "aei" or v_char_or_group == "uai" then return "slender" end
        if normalized_v_group == "ei" or normalized_v_group == "ai" or normalized_v_group == "oi" or normalized_v_group == "ui" then -- ui is slender for following C
            return "slender"
        end
        -- Explicit broad digraphs
        if normalized_v_group == "ao" or normalized_v_group == "ua" or normalized_v_group == "ou" or normalized_v_group == "ea" or normalized_v_group == "ia" then -- ea/ia broad for following C
            return "broad"
        end

        -- Fallback to last character
        if umatch(last_char_of_group, SLENDER_VOWELS_ORTHO_PATTERN) then
            return "slender"
        elseif umatch(last_char_of_group, BROAD_VOWELS_ORTHO_PATTERN) then
            return "broad"
        end
    end
    return nil
end

get_ortho_vowel_quality_implication_from_char_or_group = memoize(
get_ortho_vowel_quality_implication_from_char_or_group_impl)

local determine_consonant_quality_ortho_impl
determine_consonant_quality_ortho_impl = function(original_ortho_word, ortho_cons_char_start_idx, ortho_cons_char_end_idx)
    if not original_ortho_word or not ortho_cons_char_start_idx or not ortho_cons_char_end_idx or ortho_cons_char_start_idx <= 0 or ortho_cons_char_end_idx > ulen(original_ortho_word) or ortho_cons_char_start_idx > ortho_cons_char_end_idx then return
        "nonpalatal" end
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

    local next_v_group_str_build = {}
    local current_scan_idx = ortho_cons_char_end_idx + 1
    while current_scan_idx <= ulen(original_ortho_word) do
        local char_at_scan = usub(original_ortho_word, current_scan_idx, current_scan_idx)
        if umatch(char_at_scan, ALL_VOWELS_ORTHO_PATTERN) then
            table.insert(next_v_group_str_build, char_at_scan)
        else
            break
        end
        current_scan_idx = current_scan_idx + 1
    end
    local next_v_group_str = table.concat(next_v_group_str_build)
    if ulen(next_v_group_str) > 0 then next_v_quality_implication =
        get_ortho_vowel_quality_implication_from_char_or_group(next_v_group_str, true) end

    local prev_v_group_str_build = {}
    current_scan_idx = ortho_cons_char_start_idx - 1
    while current_scan_idx >= 1 do
        local char_at_scan = usub(original_ortho_word, current_scan_idx, current_scan_idx)
        if char_at_scan == "ˈ" then break end
        if umatch(char_at_scan, ALL_VOWELS_ORTHO_PATTERN) then
            table.insert(prev_v_group_str_build, 1, char_at_scan)
        else
            break
        end
        current_scan_idx = current_scan_idx - 1
    end
    local prev_v_group_str = table.concat(prev_v_group_str_build)
    if ulen(prev_v_group_str) > 0 then prev_v_quality_implication =
        get_ortho_vowel_quality_implication_from_char_or_group(prev_v_group_str, false) end

    local final_quality
    if current_ortho_cons_seq == "s" and ortho_cons_char_start_idx > (1 + stress_marker_offset) and prev_v_group_str == "ú" then
        final_quality = "nonpalatal"
    elseif not next_v_quality_implication then
        final_quality = (prev_v_quality_implication == "slender" and "palatal") or "nonpalatal"
    else
        final_quality = (next_v_quality_implication == "slender" and "palatal") or
        (next_v_quality_implication == "broad" and "nonpalatal") or
        (prev_v_quality_implication == "slender" and "palatal") or "nonpalatal"
    end
    debug_print_minimal("ConsonantResolution", "determine_cons_qual_ortho for '", current_ortho_cons_seq, "' in '",
        original_ortho_word, "' (idx:", ortho_cons_char_start_idx, "): NextVQual=", next_v_quality_implication or "nil",
        ", PrevVQual=", prev_v_quality_implication or "nil", " -> FinalQual=", final_quality)
    return final_quality
end
determine_consonant_quality_ortho = (determine_consonant_quality_ortho_impl)


local parse_phonetic_string_to_units_for_epenthesis_impl
parse_phonetic_string_to_units_for_epenthesis_impl = function(phon_str_raw)
    local phon_str = toNFC(phon_str_raw); local units = {}; local i = 1
    while i <= ulen(phon_str) do
        local stress_at_current_pos = ""; if usub(phon_str, i, i) == toNFC("ˈ") then
            stress_at_current_pos = toNFC("ˈ"); i = i + 1;
        end
        if i > ulen(phon_str) then
            if stress_at_current_pos ~= "" then table.insert(units,
                    { phon = stress_at_current_pos, stress = "", quality = "stress_mark" }); end; break
        end
        local best_overall_match_phon, best_overall_match_len, best_overall_match_type = nil, 0, nil
        for _, unit_entry in ipairs(COMBINED_PHONETIC_UNITS_PRIORITY) do
            local unit_p_str = unit_entry.phon; local p_len_val = ulen(unit_p_str); if i + p_len_val - 1 <= ulen(phon_str) then
                local sub_to_test = usub(phon_str, i, i + p_len_val - 1); if sub_to_test == unit_p_str and p_len_val > best_overall_match_len then
                    best_overall_match_phon = unit_p_str; best_overall_match_len = p_len_val; best_overall_match_type =
                    unit_entry.type;
                end
            end
        end
        local quality = "unknown"; if best_overall_match_phon then
            if best_overall_match_type == "vowel" then quality = "vowel" elseif best_overall_match_type == "consonant" then if umatch(best_overall_match_phon, "ʲ$") or umatch(best_overall_match_phon, "^[ʃçjɟc]$") or umatch(best_overall_match_phon, "'$") then quality =
                    "palatal" elseif umatch(best_overall_match_phon, "ˠ$") or umatch(best_overall_match_phon, "[̪]$") or umatch(best_overall_match_phon, "[̠]$") then quality =
                    "nonpalatal" else quality = "nonpalatal" end end; table.insert(units,
                { phon = best_overall_match_phon, stress = stress_at_current_pos, quality = quality }); i = i +
            best_overall_match_len
        elseif stress_at_current_pos ~= "" then
            table.insert(units, { phon = stress_at_current_pos, stress = "", quality = "stress_mark" })
        else
            local unknown_char = usub(phon_str, i, i); local unknown_quality = "unknown_fallback"; for _, unit_entry in ipairs(COMBINED_PHONETIC_UNITS_PRIORITY) do if unit_entry.phon == unknown_char then
                    if unit_entry.type == "vowel" then unknown_quality = "vowel" elseif unit_entry.type == "consonant" then if umatch(unknown_char, "ʲ$") or umatch(unknown_char, "^[ʃçjɟc]$") or umatch(unknown_char, "'$") then unknown_quality =
                            "palatal" else unknown_quality = "nonpalatal" end end; goto add_fallback_unit_generic_parser
                end end; ::add_fallback_unit_generic_parser::
            table.insert(units, { phon = unknown_char, stress = stress_at_current_pos, quality = unknown_quality }); i =
            i + 1
        end
    end; return units
end
parse_phonetic_string_to_units_for_epenthesis = memoize(parse_phonetic_string_to_units_for_epenthesis_impl)

local is_likely_monosyllable_phonetic_revised_impl
is_likely_monosyllable_phonetic_revised_impl = function(phon_word_local, pre_parsed_units_input)
    if not phon_word_local then return false end
    local units_to_check = pre_parsed_units_input or
    parse_phonetic_string_to_units_for_epenthesis(ugsub(phon_word_local, "ˈ", ""))
    local count_local = 0
    for _, unit_data in ipairs(units_to_check) do if unit_data.quality == "vowel" then count_local = count_local + 1 end end
    if MINIMAL_DEBUG_ENABLED and (umatch(phon_word_local, "^cɑ~N") or umatch(phon_word_local, "^ɟɑ~l") or umatch(phon_word_local, "^bʲɑ~n") or umatch(phon_word_local, "^fɔ~N") or umatch(phon_word_local, "^pɔ~L") or umatch(phon_word_local, "^t̪rɔ~m") or umatch(phon_word_local, "^kɔ~R") or umatch(phon_word_local, "^bɔ~rd") or umatch(phon_word_local, "^ˈɑ~m")) then
        local unit_details = {}; for _, u_data_dbg in ipairs(units_to_check) do table.insert(unit_details,
                u_data_dbg.phon .. "(" .. u_data_dbg.quality .. ")") end
        debug_print_minimal("EpenthesisAndStrongSonorants", "is_likely_monosyllable (TARGETED) for '", phon_word_local,
            "': Units: {", table.concat(unit_details, ", "), "}, VowelCount: ", count_local, ", Result: ",
            tostring(count_local == 1))
    end
    return count_local == 1
end
is_likely_monosyllable_phonetic_revised = memoize(is_likely_monosyllable_phonetic_revised_impl)

local UNSTRESSED_PREFIXES_ORTHO = { "an%-", "droch%-", "mí%-", "do%-", "ró%-", "dea%-", "fíor%-", "sean%-", "ath%-",
    "comh%-", "fo%-", "frith%-", "idir%-", "in%-", "réamh%-", "so%-", "tras%-", "mór%-", "ban%-", "cam%-", "fionn%-",
    "leas%-" }
local function resolve_lenited_consonant(base_phoneme_palatal, base_phoneme_nonpalatal, full_match_marker, o_context_str,
                                         original_match_info_tbl, options)
    options = options or {};
    debug_print_minimal(string.format("DEBUG RLC Entry for %s: o_context_str='%s', omi.ortho_s=%s, omi.ortho_e=%s",
    full_match_marker, o_context_str, tostring(original_match_info_tbl.ortho_s), tostring(original_match_info_tbl.ortho_e)))

    if not original_match_info_tbl or not original_match_info_tbl.ortho_s or not original_match_info_tbl.ortho_e then
        debug_print_minimal("DEBUG RLC: Early exit, no match info for", full_match_marker)
        return base_phoneme_nonpalatal
    end

    local ortho_cons_str = usub(o_context_str, original_match_info_tbl.ortho_s, original_match_info_tbl.ortho_e)

    -- Find NEXT determining vowel group
    local next_v_group = ""
    local scan_idx = original_match_info_tbl.ortho_e + 1
    while scan_idx <= ulen(o_context_str) do -- Scan to find the start of the next vowel group
        local char = usub(o_context_str, scan_idx, scan_idx)
        if umatch(char, ALL_VOWELS_ORTHO_PATTERN) then
            break       -- Found the start of the vowel group
        elseif umatch(char, "[" .. CONSONANTS_ORTHO_CHARS_STR .. "]") then
            scan_idx = scan_idx + 1 -- Skip consonant
        else            -- Some other character, stop
            debug_print_minimal("DEBUG RLC: Unexpected char '" .. char .. "' at scan_idx " .. scan_idx .. " while finding next vowel start.")
            break
        end
    end
    debug_print_minimal("DEBUG RLC: After finding next vowel start, scan_idx is " .. scan_idx .. ", next_v_group is still '" .. next_v_group .. "'") -- ADD THIS

    while scan_idx <= ulen(o_context_str) do -- Now extract the full vowel group
        local char = usub(o_context_str, scan_idx, scan_idx)
        if umatch(char, ALL_VOWELS_ORTHO_PATTERN) then
            next_v_group = next_v_group .. char
            scan_idx = scan_idx + 1
        else
            break
        end
    end

    -- Find PREVIOUS determining vowel grouplocal prev_v_group = ""
    scan_idx = original_match_info_tbl.ortho_s - 1
    local temp_prev_v_chars = {}
    while scan_idx >= 1 do -- Scan backwards to find the end of the previous vowel group
        local char = usub(o_context_str, scan_idx, scan_idx)
        if umatch(char, ALL_VOWELS_ORTHO_PATTERN) then
            break       -- Found the end of the vowel group
        elseif umatch(char, "[" .. CONSONANTS_ORTHO_CHARS_STR .. "]") or char == "ˈ" then
            scan_idx = scan_idx - 1 -- Skip consonant or stress
        else            -- Some other character, stop
            break
        end
    end
    while scan_idx >= 1 do -- Now extract the full vowel group backwards
        local char = usub(o_context_str, scan_idx, scan_idx)
        if umatch(char, ALL_VOWELS_ORTHO_PATTERN) then
            table.insert(temp_prev_v_chars, 1, char) -- Prepend to build in correct order
            scan_idx = scan_idx - 1
        else
            break
        end
    end
    prev_v_group = table.concat(temp_prev_v_chars)


    local next_qual_for_cons = get_ortho_vowel_quality_implication_from_char_or_group(next_v_group, true)
    local prev_qual_for_cons = get_ortho_vowel_quality_implication_from_char_or_group(prev_v_group, false)

    local quality = next_qual_for_cons or prev_qual_for_cons or "nonpalatal"
    if next_qual_for_cons == "broad" and prev_qual_for_cons == "slender" then quality = "slender" end

    debug_print_minimal(string.format(
        "DEBUG RLC for %s in %s: next_v_group='%s', prev_v_group='%s', next_qual_for_cons='%s', prev_qual_for_cons='%s', derived_quality='%s'",
        ortho_cons_str, o_context_str, next_v_group, prev_v_group, tostring(next_qual_for_cons),
        tostring(prev_qual_for_cons), quality))

    if options.can_be_w and quality == "nonpalatal" then
        local is_word_initial_ortho = (original_match_info_tbl.ortho_s == 1 or (original_match_info_tbl.ortho_s == 2 and usub(o_context_str, 1, 1) == "ˈ"))
        if is_word_initial_ortho and next_v_group ~= "" then
            local first_next_ortho_vowel = usub(next_v_group, 1, 1)
            if umatch(first_next_ortho_vowel, "[aoáó]") then
                debug_print_minimal("DEBUG RLC: mh/bh -> w (broad vowel context)")
                return toNFC("w")
            elseif umatch(first_next_ortho_vowel, ALL_VOWELS_ORTHO_PATTERN) then
                debug_print_minimal("DEBUG RLC: mh/bh -> w (any other vowel initially)")
                return toNFC("w")
            end
        end
        debug_print_minimal("DEBUG RLC: mh/bh -> vˠ (nonpalatal, not w)")
        return toNFC("vˠ")
    end

    local result_phoneme = quality == 'slender' and base_phoneme_palatal or base_phoneme_nonpalatal
    debug_print_minimal(string.format("DEBUG RLC: Final decision: quality=='slender' (%s) -> %s", tostring(quality == 'slender'),
        result_phoneme))
    return result_phoneme
end

irishPhonetics.rules_stage1_preprocess = { {
    p = toNFC("^%s*(.-)%s*$"),
    r = function(captured_string)
        if captured_string then
            return
                ulower(captured_string)
        else
            return ""
        end
    end
}, { p = toNFC("%s+"), r = " " }, { p = toNFC("�"), r = "" }, }
irishPhonetics.rules_stage2_mark_digraphs_and_vocalisation_triggers = {
    { p = toNFC("eacht"), r = toNFC("MKR_EACHTBRDFX"),  ortho_len = 5 },
    { p = toNFC("eoi"),   r = toNFC("MKR_EOITRIGOLNG"), ortho_len = 3 }, { p = toNFC("eói"), r = toNFC("MKR_EOITRIGOLNGACT"), ortho_len = 3 },
    { p = toNFC("bhf"), r = toNFC("MKR_URUF"), ortho_len = 3 }, { p = toNFC("bp"), r = toNFC("MKR_URUP"), ortho_len = 2 }, { p = toNFC("dt"), r = toNFC("MKR_URUT"), ortho_len = 2 }, { p = toNFC("gc"), r = toNFC("MKR_URUC"), ortho_len = 2 }, { p = toNFC("mb"), r = toNFC("MKR_URUM"), ortho_len = 2 }, { p = toNFC("nd"), r = toNFC("MKR_URUN"), ortho_len = 2 }, { p = toNFC("ng"), r = toNFC("MKR_URUG"), ortho_len = 2 },
    { p = toNFC("(a)(bh|mh)(n̠ʲ|nʲ|l̠ʲ|lʲ|mʲ)"), r = function(m, a, bh_mh, pal_son) return toNFC(
        "MKR_AV_VOC_SLENDER_") .. pal_son end, ortho_len_func = function(m, a, bh_mh, pal_son) return ulen(a ..
        bh_mh .. pal_son) end },
    { p = toNFC("eidh(#?)$"), r = function(m, c1) return toNFC("MKR_EIDHCONNAI") .. (c1 or "") end, ortho_len = 4 },
    { p = toNFC("aghaidh(#?)$"), r = function(m, c1) return toNFC("MKR_AGHAIDHVOCTRGT") .. (c1 or "") end, ortho_len = 7 }, { p = toNFC("ubh(#?)$"), r = function(
    m, c1) return toNFC("MKR_UVOCBFIN") .. (c1 or "") end, ortho_len = 3 }, { p = toNFC("ámh(#?)$"), r = function(
    m, c1) return toNFC("MKR_AACTLNGVOCMFIN") .. (c1 or "") end, ortho_len = 3 },
    { p = toNFC("eabh"),     r = toNFC("MKR_EAVOCB"),                                           ortho_len = 4 },
    { p = toNFC("amh(r)"),   r = function(m, c1) return toNFC("MKR_AVOCMMEDR") .. c1 end,       ortho_len = 3 },
    { p = toNFC("adh(#?)$"), r = function(m, c1) return toNFC("MKR_AVOCDFIN") .. (c1 or "") end, ortho_len = 3 }, { p = toNFC("eadh(#?)$"), r = function(
    m, c1) return toNFC("MKR_EAVOCDFIN") .. (c1 or "") end, ortho_len = 4 }, { p = toNFC("agh(#?)$"), r = function(
    m, c1) return toNFC("MKR_AVOCGFIN") .. (c1 or "") end, ortho_len = 3 }, { p = toNFC("ogh(#?)$"), r = function(
    m, c1) return toNFC("MKR_OVOCGFIN") .. (c1 or "") end, ortho_len = 3 }, { p = toNFC("obh(#?)$"), r = function(
    m, c1) return toNFC("MKR_OVOCBFIN") .. (c1 or "") end, ortho_len = 3 }, { p = toNFC("omh(#?)$"), r = function(
    m, c1) return toNFC("MKR_OVOCMFIN") .. (c1 or "") end, ortho_len = 3 }, { p = toNFC("ibh(#?)$"), r = function(
    m, c1) return toNFC("MKR_IVOCBFIN") .. (c1 or "") end, ortho_len = 3 }, { p = toNFC("imh(e#?)$"), r = function(
    m, c1) return toNFC("MKR_IVOCMMEDEFIN") .. (c1 or "") end, ortho_len = 4 }, { p = toNFC("imh(#?)$"), r = function(
    m, c1) return toNFC("MKR_IVOCMFIN") .. (c1 or "") end, ortho_len = 3 }, { p = toNFC("idh(e#?)$"), r = function(
    m, c1) return toNFC("MKR_IVOCDMEDEFIN") .. (c1 or "") end, ortho_len = 4 }, { p = toNFC("idh(#?)$"), r = function(
    m, c1) return toNFC("MKR_IVOCDFIN") .. (c1 or "") end, ortho_len = 3 },
    { p = toNFC("uidh$"),      r = toNFC("MKR_UIVOCDFIN"),                                                  ortho_len = 4 },
    { p = toNFC("uidh(e#?)$"), r = function(m, c1) return toNFC("MKR_UIVOCDMEDEFIN") .. (c1 or "") end,     ortho_len = 5 },
    { p = toNFC("áth(#?)$"),   r = function(m, c1) return toNFC("MKR_AACTLNGVOCTHSILFIN") .. (c1 or "") end, ortho_len = 3 }, { p = toNFC("aidh(#?)$"), r = function(
    m, c1) return toNFC("MKR_AIDHFINSCHWA") .. (c1 or "") end, ortho_len = 4 }, { p = toNFC("aigh(#?)$"), r = function(
    m, c1) return toNFC("MKR_AIGHFINSCHWA") .. (c1 or "") end, ortho_len = 4 },
    { p = toNFC("aoi"), r = toNFC("MKR_AOILNG"),    ortho_len = 3 }, { p = toNFC("ao"), r = toNFC("MKR_AOLNG"), ortho_len = 2 }, { p = toNFC("ói"), r = toNFC("MKR_OIACTLNG"), ortho_len = 2 }, { p = toNFC("aí"), r = toNFC("MKR_AIACTLNG"), ortho_len = 2 },
    { p = toNFC("^fh"), r = toNFC("MKR_FHINITLEN"), ortho_len = 2 }, { p = toNFC("bh"), r = toNFC("MKR_BH"), ortho_len = 2 }, { p = toNFC("mh"), r = toNFC("MKR_MH"), ortho_len = 2 }, { p = toNFC("ch"), r = toNFC("MKR_CH"), ortho_len = 2 }, { p = toNFC("dh"), r = toNFC("MKR_DH"), ortho_len = 2 }, { p = toNFC("gh"), r = toNFC("MKR_GH"), ortho_len = 2 }, { p = toNFC("ph"), r = toNFC("MKR_PH"), ortho_len = 2 }, { p = toNFC("sh"), r = toNFC("MKR_SH"), ortho_len = 2 }, { p = toNFC("th"), r = toNFC("MKR_TH"), ortho_len = 2 },
    { p = toNFC("ll"), r = toNFC("MKR_LL_STR"), ortho_len = 2 }, { p = toNFC("nn"), r = toNFC("MKR_NN_STR"), ortho_len = 2 }, { p = toNFC("rr"), r = toNFC("MKR_RR_STR"), ortho_len = 2 }, { p = toNFC("mm"), r = toNFC("MKR_MM_STR"), ortho_len = 2 },
    { p = toNFC("(ˈ" .. SHORT_VOWELS_ORTHO_SINGLE_STR .. ")l(" .. ALL_VOWELS_ORTHO_PATTERN .. ")"), r = "%1l°%2", ortho_len_func = function(
        m, c1, c2) return ulen(c1) + 1 + ulen(c2) end }, { p = toNFC("(ˈ" .. SHORT_VOWELS_ORTHO_SINGLE_STR .. ")n(" .. ALL_VOWELS_ORTHO_PATTERN .. ")"), r = "%1n°%2", ortho_len_func = function(
    m, c1, c2) return ulen(c1) + 1 + ulen(c2) end }, }
irishPhonetics.rules_stage2_5_mark_suffixes = {
    { p = toNFC("([" .. CONSONANTS_ORTHO_CHARS_STR .. "])(lainn)(#?)$"), r = function(fm, c1, sfx, b) return
        c1 .. toNFC("MKR_SUFFIX_LAINN") .. (b or "") end,                                                                                                                                     ortho_len_func = function(
        fm, c1, sfx, b) return ulen(c1 .. sfx) end },
    { p = toNFC("(aigh)(#?)$"),                                          r = function(fm, sfx, b) return
        toNFC("MKR_SUFFIX_IGH") .. (b or "") end,                                                                                                                                             ortho_len_func = function(
        fm, sfx, b) return ulen(sfx) end },
    { p = toNFC("(igh)(#?)$"),                                           r = function(fm, sfx, b) return
        toNFC("MKR_SUFFIX_IGH") .. (b or "") end,                                                                                                                                             ortho_len_func = function(
        fm, sfx, b) return ulen(sfx) end },
    { p = toNFC("(eoireacht)(a#?)$"),                                    r = function(fm, sfx, b) return
        toNFC("MKR_SUFFIX_OIRƏXTA") .. (b or "") end,                                                                                                                                         ortho_len_func = function(
        fm, sfx, b) return ulen(sfx) end },
    { p = toNFC("(aíocht)(a#?)$"),                                       r = function(fm, sfx, b) return
        toNFC("MKR_SUFFIX_IƏXTA") .. (b or "") end,                                                                                                                                           ortho_len_func = function(
        fm, sfx, b) return ulen(sfx) end },
    { p = toNFC("(úint)(#?)$"),                                          r = function(fm, sfx, b) return
        toNFC("MKR_SUFFIX_UUNTJ") .. (b or "") end,                                                                                                                                           ortho_len_func = function(
        fm, sfx, b) return ulen(sfx) end },
    { p = toNFC("(úil)(#?)$"),                                           r = function(fm, sfx, b) return
        toNFC("MKR_SUFFIX_UULJ") .. (b or "") end,                                                                                                                                            ortho_len_func = function(
        fm, sfx, b) return ulen(sfx) end },
    { p = toNFC("(óir)(#?)$"),                                           r = function(fm, sfx, b) return
        toNFC("MKR_SUFFIX_OOIRJ") .. (b or "") end,                                                                                                                                           ortho_len_func = function(
        fm, sfx, b) return ulen(sfx) end },
    { p = toNFC("(ín)(#?)$"),                                            r = function(fm, sfx, b) return
        toNFC("MKR_SUFFIX_IINJ") .. (b or "") end,                                                                                                                                            ortho_len_func = function(
        fm, sfx, b) return ulen(sfx) end },
    { p = toNFC("(íonn)(#?)$"),                                          r = function(fm, sfx, b) return
        toNFC("MKR_SUFFIX_IIN_VERB") .. (b or "") end,                                                                                                                                        ortho_len_func = function(
        fm, sfx, b) return ulen(sfx) end },
    { p = toNFC("(eann)(#?)$"),                                          r = function(fm, sfx, b) return
        toNFC("MKR_SUFFIX_ƏN_VERB") .. (b or "") end,                                                                                                                                         ortho_len_func = function(
        fm, sfx, b) return ulen(sfx) end },
    { p = toNFC("(ann)(#?)$"),                                           r = function(fm, sfx, b) return
        toNFC("MKR_SUFFIX_ƏN_VERB") .. (b or "") end,                                                                                                                                         ortho_len_func = function(
        fm, sfx, b) return ulen(sfx) end },
    { p = toNFC("(ach)(#?)$"),                                           r = function(fm, sfx, b) return
        toNFC("MKR_SUFFIX_ƏX") .. (b or "") end,                                                                                                                                              ortho_len_func = function(
        fm, sfx, b) return ulen(sfx) end },
    { p = toNFC("(each)(#?)$"),                                          r = function(fm, sfx, b) return
        toNFC("MKR_SUFFIX_ƏX") .. (b or "") end,                                                                                                                                              ortho_len_func = function(
        fm, sfx, b) return ulen(sfx) end },
    { p = toNFC("(aidh)(#?)$"),                                          r = function(fm, sfx, b) return
        toNFC("MKR_SUFFIX_IGH") .. (b or "") end,                                                                                                                                             ortho_len_func = function(
        fm, sfx, b) return ulen(sfx) end },
    { p = toNFC("(aí)(#?)$"),                                            r = function(fm, sfx, b) return
        toNFC("MKR_SUFFIX_A_II") .. (b or "") end,                                                                                                                                            ortho_len_func = function(
        fm, sfx, b) return ulen(sfx) end },
    { p = toNFC("(b[oaá]l)(adh)(#?)$"),                                  r = function(fm, stem, sfx, b) return
        stem .. toNFC("MKR_SUFFIX_ADH_CONN_UU") .. (b or "") end,                                                                                                                             ortho_len_func = function(
        fm, stem, sfx, b) return ulen(sfx) end },
    { p = toNFC("(adh)(#?)$"),                                           r = function(fm, sfx, b) return
        toNFC("MKR_SUFFIX_ADH_VAR") .. (b or "") end,                                                                                                                                         ortho_len_func = function(
        fm, sfx, b) return ulen(sfx) end },
    { p = toNFC("(eadh)(#?)$"),                                          r = function(fm, sfx, b) return
        toNFC("MKR_SUFFIX_ADH_VAR") .. (b or "") end,                                                                                                                                         ortho_len_func = function(
        fm, sfx, b) return ulen(sfx) end },
    { p = toNFC("(áil)(#?)$"),                                           r = function(fm, sfx, b) return
        toNFC("MKR_SUFFIX_AALJ") .. (b or "") end,                                                                                                                                            ortho_len_func = function(
        fm, sfx, b) return ulen(sfx) end },
    { p = toNFC("(fidís)(#?)$"),                                         r = function(fm, sfx, b) return
        toNFC("MKR_SUFFIX_FIDIIS") .. (b or "") end,                                                                                                                                          ortho_len_func = function(
        fm, sfx, b) return ulen(sfx) end },
    { p = toNFC("(fidh)(#?)$"),                                          r = function(fm, sfx, b) return
        toNFC("MKR_SUFFIX_FIDH") .. (b or "") end,                                                                                                                                            ortho_len_func = function(
        fm, sfx, b) return ulen(sfx) end },
    { p = toNFC("(fimid)(#?)$"),                                         r = function(fm, sfx, b) return
        toNFC("MKR_SUFFIX_FIMID") .. (b or "") end,                                                                                                                                           ortho_len_func = function(
        fm, sfx, b) return ulen(sfx) end },
    { p = toNFC("(fimis)(#?)$"),                                         r = function(fm, sfx, b) return
        toNFC("MKR_SUFFIX_FIMIS") .. (b or "") end,                                                                                                                                           ortho_len_func = function(
        fm, sfx, b) return ulen(sfx) end },
    { p = toNFC("(ímid)(#?)$"),                                          r = function(fm, sfx, b) return
        toNFC("MKR_SUFFIX_IIMID") .. (b or "") end,                                                                                                                                           ortho_len_func = function(
        fm, sfx, b) return ulen(sfx) end },
    { p = toNFC("(inn)(#?)$"),                                           r = function(fm, sfx, b) return
        toNFC("MKR_SUFFIX_INN_VERB") .. (b or "") end,                                                                                                                                        ortho_len_func = function(
        fm, sfx, b) return ulen(sfx) end },
    { p = toNFC("(mid)(#?)$"),                                           r = function(fm, sfx, b) return
        toNFC("MKR_SUFFIX_MID_VERB") .. (b or "") end,                                                                                                                                        ortho_len_func = function(
        fm, sfx, b) return ulen(sfx) end },
    { p = toNFC("(ós)(#?)$"),                                            r = function(fm, sfx, b) return
        toNFC("MKR_SUFFIX_OOS") .. (b or "") end,                                                                                                                                             ortho_len_func = function(
        fm, sfx, b) return ulen(sfx) end },
    { p = toNFC("(ófá)(#?)$"),                                           r = function(fm, sfx, b) return
        toNFC("MKR_SUFFIX_OOFAA") .. (b or "") end,                                                                                                                                           ortho_len_func = function(
        fm, sfx, b) return ulen(sfx) end },
    { p = toNFC("(óidh)(#?)$"),                                          r = function(fm, sfx, b) return
        toNFC("MKR_SUFFIX_OOIJ_VERB") .. (b or "") end,                                                                                                                                       ortho_len_func = function(
        fm, sfx, b) return ulen(sfx) end },
    { p = toNFC("(tá)(#?)$"),                                            r = function(fm, sfx, b) return
        toNFC("MKR_SUFFIX_TAA_ACT") .. (b or "") end,                                                                                                                                         ortho_len_func = function(
        fm, sfx, b) return ulen(sfx) end },
    { p = toNFC("(tí)(#?)$"),                                            r = function(fm, sfx, b) return
        toNFC("MKR_SUFFIX_TII_ACT") .. (b or "") end,                                                                                                                                         ortho_len_func = function(
        fm, sfx, b) return ulen(sfx) end },
    { p = toNFC("(fí)(#?)$"),                                            r = function(fm, sfx, b) return
        toNFC("MKR_SUFFIX_FII_ACT") .. (b or "") end,                                                                                                                                         ortho_len_func = function(
        fm, sfx, b) return ulen(sfx) end },
    { p = toNFC("(ui)(gthe)(#?)$"),                                      r = function(fm, ui_part, sfx, b) return
        ui_part .. toNFC("MKR_SUFFIX_IGTHE_CONN") .. (b or "") end,                                                                                                                           ortho_len_func = function(
        fm, ui_part, sfx, b) return ulen(sfx) end },
    { p = toNFC("(ithe)(#?)$"),                                          r = function(fm, sfx, b) return
        toNFC("MKR_SUFFIX_IHƏ_GEN") .. (b or "") end,                                                                                                                                         ortho_len_func = function(
        fm, sfx, b) return ulen(sfx) end },
}

irishPhonetics.rules_stage3_consonant_resolution = {
    { p = toNFC("MKR_FHINITLEN"), r = "" },
    { p = toNFC("MKR_FH_SILENT"), r = "" }, { p = toNFC("MKR_TH"), r = toNFC("h") },
    { p = toNFC("MKR_URUF"), r = toNFC("w") },
    { p = toNFC("MKR_URUP"), r = toNFC("b") }, { p = toNFC("MKR_URUT"), r = toNFC("d") }, { p = toNFC("MKR_URUC"), r = toNFC("g") }, { p = toNFC("MKR_URUM"), r = toNFC("m") }, { p = toNFC("MKR_URUN"), r = toNFC("n") }, { p = toNFC("MKR_URUG"), r = toNFC("ŋ") },
    { p = toNFC("MKR_PH"), r = function(fm, ocs, omi) return resolve_lenited_consonant(toNFC("f'"),
            toNFC("f"), fm, ocs, omi) end },
    { p = toNFC("MKR_SH"), r = function(fm, ocs, omi)
        if not omi or not omi.ortho_s or not omi.ortho_e then return toNFC("h") end; local next_v_start_ortho = omi
        .ortho_e + 1; local next_v_is_slender_flag = false; if next_v_start_ortho <= ulen(ocs) then if umatch(usub(ocs, next_v_start_ortho, next_v_start_ortho), SLENDER_VOWELS_ORTHO_PATTERN) then next_v_is_slender_flag = true end end; if umatch(ocs, "^[sS][eé][áa]n", omi.ortho_s - 1) then return
            toNFC("h'") end; return next_v_is_slender_flag and toNFC("h'") or toNFC("h")
    end }, { p = toNFC("MKR_FH_INTERNAL"), r = "" },
    { p = toNFC("MKR_BH"), r = function(fm, ocs, omi) return resolve_lenited_consonant(toNFC("v'"),
            toNFC("vˠ"), fm, ocs, omi, { can_be_w = true }) end },
    { p = toNFC("MKR_MH"), r = function(fm, ocs, omi) return resolve_lenited_consonant(toNFC("v'"),
            toNFC("vˠ"), fm, ocs, omi, { can_be_w = true }) end },
    { p = toNFC("MKR_DH"), r = function(fm, ocs, omi) return resolve_lenited_consonant(toNFC("j"),
            toNFC("ɣ"), fm, ocs, omi) end },
    {
        p = toNFC("MKR_GH"),
        r = function(fm, ocs, omi)
            if omi and omi.ortho_e == ulen(ocs) then
                local quality_gh = get_ortho_vowel_quality_implication_from_char_or_group( -- Renamed variable
                usub(ocs, omi.ortho_s - 1, omi.ortho_s - 1), false)
                -- Using 'slender' for comparison
                if quality_gh == "slender" then return toNFC("h") else return toNFC("ɣ") end
            end
            return resolve_lenited_consonant(toNFC("j"), toNFC("ɣ"), fm, ocs, omi)
        end
    },
    { p = toNFC("MKR_LL_STR"), r = function(fm, ocs, omi)
        local quality_ll = get_ortho_vowel_quality_implication_from_char_or_group( -- Renamed variable
        usub(ocs, omi.ortho_e + 1, omi.ortho_e + 1), true) or
        get_ortho_vowel_quality_implication_from_char_or_group(usub(ocs, omi.ortho_s - 1, omi.ortho_s - 1), false);
        -- Using 'slender' for comparison
        return quality_ll == "slender" and ZZZ_L_STR_PAL_PHON or ZZZ_L_STR_BRD_PHON
    end },
    { p = toNFC("MKR_NN_STR"), r = function(fm, ocs, omi)
        local quality_nn = get_ortho_vowel_quality_implication_from_char_or_group( -- Renamed variable
        usub(ocs, omi.ortho_e + 1, omi.ortho_e + 1), true) or
        get_ortho_vowel_quality_implication_from_char_or_group(usub(ocs, omi.ortho_s - 1, omi.ortho_s - 1), false);
        -- Using 'slender' for comparison
        return quality_nn == "slender" and ZZZ_N_STR_PAL_PHON or ZZZ_N_STR_BRD_PHON
    end },
    { p = toNFC("MKR_RR_STR"), r = function(fm, ocs, omi) return resolve_lenited_consonant(toNFC("R'"),
            toNFC("R"), fm, ocs, omi) end },
    { p = toNFC("MKR_MM_STR"), r = function(fm, ocs, omi) return
    resolve_lenited_consonant(toNFC("M'"), toNFC("M"), fm, ocs, omi) end },
    { p = toNFC("l°"), r = toNFC("l_neutral_") }, { p = toNFC("n°"), r = toNFC("n_neutral_") },
    {
        p = toNFC("([bcdfghkmprst])"), -- Pattern for single consonants
        r = function(c_capture, ocs, omi)
            debug_print_minimal(string.format("DEBUG GEN_CONS: Processing '%s' in '%s' (orig ortho '%s' at %d-%d)",
                c_capture,
                "STAGE3_INPUT_STRING_PLACEHOLDER", -- Placeholder, actual stage3 input string is complex to pass here
                ocs, omi.ortho_s, omi.ortho_e))

            if not c_capture then return "" end
            if c_capture == toNFC("l_neutral_") or c_capture == toNFC("n_neutral_") then
                debug_print_minimal(string.format("DEBUG GEN_CONS: '%s' is neutral, returning as is.", c_capture))
                return c_capture
            end

            local base = c_capture;
            if c_capture == toNFC("c") then base = toNFC("k") end -- Normalize 'c' to 'k' for base

            -- This check was problematic if omi was not correctly mapped for single chars from phonetic string
            if not omi or not omi.ortho_s or not omi.ortho_e or not ocs then
                debug_print_minimal(string.format("DEBUG GEN_CONS: Missing omi/ocs for '%s'. Defaulting.", c_capture))
                return base == toNFC("s") and toNFC("s") or base
            end

            local next_v_group = ""
            local scan_idx_next = omi.ortho_e + 1
            -- Robust next vowel group extraction (similar to resolve_lenited_consonant)
            while scan_idx_next <= ulen(ocs) do
                local char_next = usub(ocs, scan_idx_next, scan_idx_next)
                if umatch(char_next, ALL_VOWELS_ORTHO_PATTERN) then break
                elseif umatch(char_next, "[" .. CONSONANTS_ORTHO_CHARS_STR .. "]") then scan_idx_next = scan_idx_next + 1
                else break
                end
            end
            while scan_idx_next <= ulen(ocs) do
                local char_next = usub(ocs, scan_idx_next, scan_idx_next)
                if umatch(char_next, ALL_VOWELS_ORTHO_PATTERN) then next_v_group = next_v_group .. char_next; scan_idx_next = scan_idx_next + 1
                else break
                end
            end

            local prev_v_group = ""
            local scan_idx_prev = omi.ortho_s - 1
            local temp_prev_v_chars = {}
            -- Robust prev vowel group extraction
            while scan_idx_prev >= 1 do
                local char_prev = usub(ocs, scan_idx_prev, scan_idx_prev)
                if umatch(char_prev, ALL_VOWELS_ORTHO_PATTERN) then break
                elseif umatch(char_prev, "[" .. CONSONANTS_ORTHO_CHARS_STR .. "]") or char_prev == "ˈ" then scan_idx_prev = scan_idx_prev - 1
                else break
                end
            end
            while scan_idx_prev >= 1 do
                local char_prev = usub(ocs, scan_idx_prev, scan_idx_prev)
                if umatch(char_prev, ALL_VOWELS_ORTHO_PATTERN) then table.insert(temp_prev_v_chars, 1, char_prev); scan_idx_prev = scan_idx_prev - 1
                else break
                end
            end
            prev_v_group = table.concat(temp_prev_v_chars)

            local next_qual = get_ortho_vowel_quality_implication_from_char_or_group(next_v_group, true)
            local prev_qual = get_ortho_vowel_quality_implication_from_char_or_group(prev_v_group, false)

            local quality_determined = next_qual or prev_qual or "nonpalatal" -- Default to nonpalatal
            -- Rule: if a consonant is between a slender vowel and a broad vowel, it's palatal (slender)
            if next_qual == "broad" and prev_qual == "slender" then quality_determined = "slender" end

            debug_print_minimal(string.format("DEBUG GEN_CONS: For '%s': next_v_group='%s'(%s), prev_v_group='%s'(%s) -> quality_determined='%s'",
                c_capture, next_v_group, tostring(next_qual), prev_v_group, tostring(prev_qual), quality_determined))

            local is_truly_initial_in_ortho = (omi.ortho_s == 1);
            if omi.ortho_s == 2 and usub(ocs, 1, 1) == toNFC("ˈ") then is_truly_initial_in_ortho = true end

            local result_consonant

            if is_truly_initial_in_ortho and quality_determined == "nonpalatal" then
                if base == toNFC("n") then
                    result_consonant = ZZZ_N_SNG_BRD_PHON
                elseif base == toNFC("l") then
                    result_consonant = ZZZ_L_SNG_BRD_PHON
                elseif base == toNFC("s") then -- Initial broad 's'
                    result_consonant = toNFC("s")
                else -- Other initial broad consonants
                    result_consonant = base
                end
            else -- Not initial OR is palatal
                if base == toNFC("s") then
                    result_consonant = quality_determined == 'slender' and toNFC("s'") or toNFC("s")
                else
                    result_consonant = quality_determined == 'slender' and base .. toNFC("'") or base
                end
            end
            debug_print_minimal(string.format("DEBUG GEN_CONS: Final output for '%s' -> '%s'", c_capture, result_consonant))
            return result_consonant
        end
    }
}


irishPhonetics.rules_stage3_5_consonant_assimilation = {
    { p = toNFC("(d')(f')"), r = toNFC("t'%2") },
}
irishPhonetics.rules_stage4_0_specific_ortho_to_temp_marker = { { p = toNFC("^(ˈ?(?:[^" .. ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR .. "]*))a(" .. toNFC("MKR_AVOCMMEDR") .. ")(s[" .. ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR .. "]?)"), r = "%1" .. toNFC("MKR_TEMP_CONN_AU") .. "%3" }, { p = toNFC("^(ˈ?(?:[^" .. ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR .. "]*))MKR_EAVOCB(r[" .. ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR .. "]?)"), r = "%1" .. toNFC("MKR_TEMP_CONN_AU") .. "%2" }, { p = toNFC("(" .. ANY_SHORT_VOWEL_PHONETIC_CHARS_STR .. "])(" .. toNFC("MKR_AVOCMMEDR") .. ")"), r = "%1" .. toNFC("MKR_VOC_AMH_MED_R") }, { p = toNFC("(" .. ANY_SHORT_VOWEL_PHONETIC_CHARS_STR .. "])(" .. toNFC("MKR_EAVOCB") .. ")"), r = "%1" .. toNFC("MKR_VOC_EABH_MED_R") }, { p = toNFC("^(ˈ?)(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "*'?)" .. "ea(" .. toNFC("MKR_EACHTBRDFX") .. ")$"), r = "%1%2" .. toNFC("MKR_EA_BRD_SHT_PRE_CHT") .. "%3" }, { p = toNFC("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "*'?)" .. "ea(" .. toNFC("MKR_CH") .. ")"), r = "%1" .. toNFC("MKR_EA_SLN_PRE_CH") .. "%2" }, { p = toNFC("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "*'?)" .. "ea(ŋ)"), r = function(
    full_match, c_part, ng_cap, o_context_str, original_match_info_tbl)
    local ortho_n_start_idx = original_match_info_tbl.ortho_e - ulen(ng_cap) + 1; local quality_of_n =
    determine_consonant_quality_ortho(o_context_str, ortho_n_start_idx, ortho_n_start_idx); if quality_of_n == "palatal" then return (c_part or "") ..
        toNFC("MKR_EA_SLN_PRE_NG") .. ng_cap else return (c_part or "") .. toNFC("MKR_EA_BRD_PRE_NG") .. ng_cap end
end, use_original_context_for_rules = true },
    { p = toNFC("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "*'?)" .. "ea(" .. ZZZ_N_STR_PAL_PHON .. ")$"), r = "%1" .. toNFC("MKR_EA_SLN_PRE_NN") .. "%2" },
    { p = toNFC("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "*'?)" .. "ea(" .. ZZZ_N_STR_BRD_PHON .. ")$"), r = "%1" .. toNFC("MKR_EA_BRD_PRE_NN") .. "%2" },
    { p = toNFC("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "*'?)" .. "ea(" .. ZZZ_N_STR_BRD_PHON .. ")([^'])"), r = "%1" .. toNFC("MKR_EA_BRD_PRE_NN") .. "%2%3" },
    { p = toNFC("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "*'?)" .. "ea(r')"), r = "%1" .. toNFC("MKR_EA_SLN_PRE_RPRIME") .. "%2" }, { p = toNFC("((?:[" .. ANY_CONSONANT_PHONETIC_RAW_CHARS_STR .. "]'?)*)iu(" .. toNFC("MKR_CH") .. ")"), r = "%1" .. toNFC("MKR_IU_SLN_FIN_PRE_CH") .. "%2" }, { p = toNFC("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "*'?)" .. "ea(r)"), r = "%1" .. toNFC("MKR_EA_BRD_PRE_R") .. "%2" }, { p = toNFC("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "*'?)" .. "ea(n)$"), r = function(
    full_match, c_part, n_cap, o_context_str, original_match_info_tbl)
    local n_quality = determine_consonant_quality_ortho(o_context_str,
        original_match_info_tbl.ortho_s + ulen(c_part or "") + 2,
        original_match_info_tbl.ortho_s + ulen(c_part or "") + 2); if n_quality == "palatal" then return (c_part or "") ..
        toNFC("MKR_EA_SLN_PRE_N") .. (n_cap or "") else return (c_part or "") ..
        toNFC("MKR_EA_BRD_PRE_N") .. (n_cap or "") end
end, use_original_context_for_rules = true }, { p = toNFC("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "*'?)" .. "ea(n)([^" .. ALL_VOWELS_ORTHO_CHARS_STR .. "°%-bhfpgcdtmls" .. ANY_CONSONANT_PHONETIC_RAW_CHARS_STR .. "'])"), r = function(
    full_match, c_part, n_cap, next_char_phon, o_context_str, original_match_info_tbl)
    local n_quality = determine_consonant_quality_ortho(o_context_str,
        original_match_info_tbl.ortho_s + ulen(c_part or "") + 2,
        original_match_info_tbl.ortho_s + ulen(c_part or "") + 2); if n_quality == "palatal" then return (c_part or "") ..
        toNFC("MKR_EA_SLN_PRE_N") .. (n_cap or "") .. (next_char_phon or "") else return (c_part or "") ..
        toNFC("MKR_EA_BRD_PRE_N") .. (n_cap or "") .. (next_char_phon or "") end
end, use_original_context_for_rules = true }, { p = toNFC("io"), r = toNFC("MKR_IO_SHT_TRGT") }, }
irishPhonetics.rules_stage4_0_1_resolve_ch_marker = {
    {
        p = toNFC("MKR_CH"),
        r = function(full_match_marker, o_context_str, original_match_info_tbl)
            if not original_match_info_tbl or not original_match_info_tbl.ortho_s or not original_match_info_tbl.ortho_e then return
                toNFC("x") end

            local ortho_s = original_match_info_tbl.ortho_s
            local ortho_e = original_match_info_tbl.ortho_e

            -- Determine quality by checking surrounding orthographic vowels
            local next_v_group = ""
            local scan_idx = ortho_e + 1
            while scan_idx <= ulen(o_context_str) do
                local char = usub(o_context_str, scan_idx, scan_idx)
                if umatch(char, ALL_VOWELS_ORTHO_PATTERN) then next_v_group = next_v_group .. char else break end
                scan_idx = scan_idx + 1
            end

            local prev_v_group = ""
            scan_idx = ortho_s - 1
            while scan_idx >= 1 do
                local char = usub(o_context_str, scan_idx, scan_idx)
                if umatch(char, ALL_VOWELS_ORTHO_PATTERN) then prev_v_group = char .. prev_v_group else break end
                scan_idx = scan_idx - 1
            end

            local next_qual = get_ortho_vowel_quality_implication_from_char_or_group(next_v_group, true)
            local prev_qual = get_ortho_vowel_quality_implication_from_char_or_group(prev_v_group, false)
            local quality = next_qual or prev_qual or "nonpalatal"
            if next_qual == "broad" and prev_qual == "slender" then quality = "palatal" end

            -- Determine position (is it between other characters?)
            local is_medial = (ortho_s > 1 and usub(o_context_str, 1, 1) ~= 'ˈ' or ortho_s > 2) and
            (ortho_e < ulen(o_context_str))

            debug_print_minimal("Stage4_0_1_Resolve_CH_Marker", "Resolving <ch> in '", o_context_str, "'. Quality: ",
                quality, ". Is Medial: ", tostring(is_medial))

            if quality == "palatal" and is_medial then
                -- Hickey (162): Medial palatal /xʲ/ can be debuccalised to /h/.
                return toNFC("h")
            elseif quality == "palatal" then
                -- Initial or final palatal <ch> is /ç/.
                return toNFC("ç")
            else
                -- Broad <ch> is always /x/.
                return toNFC("x")
            end
        end
    },
}


irishPhonetics.rules_stage4_1_vocmark_to_temp_marker = {}
irishPhonetics.rules_stage4_2_long_vowels_ortho_to_temp_marker = {
    { p = toNFC("ái"), r = toNFC("MKR_A_I_ACT_LNG_RSLV") },
    { p = toNFC("éi"), r = toNFC("MKR_E_ACT_I_LNG") }, { p = toNFC("iú"), r = toNFC("MKR_I_U_SHT") }, { p = toNFC("á"), r = toNFC("MKR_A_ACT_LNG") }, { p = toNFC("é"), r = toNFC("MKR_E_ACT_LNG") }, { p = toNFC("í"), r = toNFC("MKR_I_ACT_LNG") }, { p = toNFC("ó"), r = toNFC("MKR_O_ACT_LNG") }, { p = toNFC("ú"), r = toNFC("MKR_U_ACT_LNG") }, { p = toNFC("MKR_AIACTLNG"), r = toNFC("MKR_A_I_ACT_LNG_RSLV") }, }
irishPhonetics.rules_stage4_3_diphthongs_ortho_to_temp_marker = {
    { p = toNFC("MKR_EOITRIGOLNG"),                      r = toNFC("MKR_EOI_TRIG_O_LNG") }, { p = toNFC("MKR_EOITRIGOLNGACT"), r = toNFC("MKR_EOI_TRIG_O_LNG_ACT") },
    { p = toNFC("(b)(ai)(" .. ZZZ_N_STR_PAL_PHON .. ")(e)"), r = function(fm, cap_b, cap_ai, cap_nnn,
                                                                                          cap_e) return cap_b ..
        toNFC("MKR_A_FRM_BAINNE") .. cap_nnn .. cap_e end },
    { p = toNFC("éa"),                                   r = toNFC("MKR_EA_COMPOUND_LONG_E") },
    { p = toNFC("ae"),                                   r = toNFC("MKR_AE_SEQ") }, { p = toNFC("ia"), r = toNFC("MKR_IA_DIPH") }, { p = toNFC("ua"), r = toNFC("MKR_UA_DIPH") }, { p = toNFC("ai"), r = toNFC("MKR_AI_DIPH") }, { p = toNFC("ei"), r = toNFC("MKR_EI_DIPH") }, { p = toNFC("oi"), r = toNFC("MKR_OI_DIPH") }, { p = toNFC("ui"), r = toNFC("MKR_UI_DIPH") }, { p = toNFC("au"), r = toNFC("MKR_AU_DIPH") }, { p = toNFC("ou"), r = toNFC("MKR_OU_DIPH") }, { p = toNFC("eo"), r = toNFC("MKR_EO_SEQ") }, }
irishPhonetics.rules_stage4_4_resolve_temp_vowel_markers = {
    { p = toNFC("MKR_I_U_SHT"), r = toNFC("u") },
    { p = toNFC("MKR_SUFFIX_LAINN"), r = toNFC("lən̠ʲ") },

    { p = toNFC("MKR_SUFFIX_OIRƏXTA"), r = toNFC("oːɾʲəxt̪ə") },
    { p = toNFC("MKR_SUFFIX_IƏXTA"), r = toNFC("iəxt̪ə") },
    { p = toNFC("MKR_SUFFIX_ƏX"), r = toNFC("əx") }, { p = toNFC("MKR_SUFFIX_IGH"), r = toNFC("iː") }, { p = toNFC("MKR_SUFFIX_A_II"), r = toNFC("iː") }, { p = toNFC("MKR_SUFFIX_ADH_VAR"), r = toNFC("ə") }, { p = toNFC("MKR_SUFFIX_ADH_CONN_UU"), r = toNFC("uː") }, { p = toNFC("MKR_SUFFIX_AALJ"), r = toNFC("ɑːlʲ") }, { p = toNFC("MKR_SUFFIX_UULJ"), r = toNFC("uːlʲ") }, { p = toNFC("MKR_SUFFIX_OOIRJ"), r = toNFC("oːɾʲ") }, { p = toNFC("MKR_SUFFIX_IINJ"), r = toNFC("iːnʲ") }, { p = toNFC("MKR_SUFFIX_ƏN_VERB"), r = toNFC("ən̪ˠ") }, { p = toNFC("MKR_SUFFIX_IIN_VERB"), r = toNFC("iːn̪ˠ") }, { p = toNFC("MKR_SUFFIX_UUNTJ"), r = toNFC("uːn̠ʲtʲ") },
    { p = toNFC("MKR_SUFFIX_FIDIIS"), r = toNFC("hədʲiːʃ") }, { p = toNFC("MKR_SUFFIX_FIDH"), r = toNFC("iː") },
    { p = toNFC("MKR_SUFFIX_FIMID"), r = toNFC("həmʲədʲ") }, { p = toNFC("MKR_SUFFIX_FIMIS"), r = toNFC("həmʲəʃ") },
    { p = toNFC("MKR_SUFFIX_IIMID"), r = toNFC("iːmʲədʲ") },
    { p = toNFC("MKR_SUFFIX_INN_VERB"), r = toNFC("ən̠ʲ") }, { p = toNFC("MKR_SUFFIX_MID_VERB"), r = toNFC("mʲədʲ") }, { p = toNFC("MKR_SUFFIX_OOS"), r = toNFC("oːsˠ") }, { p = toNFC("MKR_SUFFIX_OOFAA"), r = toNFC("oːhɑː") }, { p = toNFC("MKR_SUFFIX_OOIJ_VERB"), r = toNFC("oːj") },
    { p = toNFC("MKR_SUFFIX_TAA_ACT"), r = toNFC("t̪ˠɑː") }, { p = toNFC("MKR_SUFFIX_TII_ACT"), r = toNFC("tʲiː") }, { p = toNFC("MKR_SUFFIX_FII_ACT"), r = toNFC("fʲiː") },
    { p = toNFC("MKR_SUFFIX_IGTHE_CONN"), r = toNFC("ɪctʲçi") }, { p = toNFC("MKR_SUFFIX_IHƏ_GEN"), r = toNFC("ɪhə") },
    { p = toNFC("MKR_EOI_TRIG_O_LNG"), r = toNFC("oː") }, { p = toNFC("MKR_EOI_TRIG_O_LNG_ACT"), r = toNFC("oː") },
    { p = toNFC("MKR_EIDHCONNAI(#?)"), r = toNFC("ai%1") },
    { p = toNFC("MKR_AV_VOC_SLENDER_(n̠ʲ|nʲ|l̠ʲ|lʲ|mʲ)"), r = function(m, pal_son) return toNFC("əu") ..
        pal_son end },
    { p = toNFC("MKR_UVOCBFIN(#?)"), r = toNFC("uː%1") }, { p = toNFC("MKR_AACTLNGVOCMFIN(#?)"), r = toNFC("ɑːv%1") }, { p = toNFC("MKR_AVOCMMEDR(r)"), r = toNFC("MKR_TEMP_CONN_AU%1") }, { p = toNFC("MKR_EAVOCB(r)"), r = toNFC("MKR_TEMP_CONN_AU%1") }, { p = toNFC("MKR_AVOCDFIN(#?)"), r = toNFC("ə%1") }, { p = toNFC("MKR_EAVOCDFIN(#?)"), r = toNFC("uː%1") }, { p = toNFC("MKR_AGHAIDHVOCTRGT(#?)"), r = toNFC("əi%1") }, { p = toNFC("MKR_AVOCGFIN(#?)"), r = toNFC("ə%1") }, { p = toNFC("MKR_OVOCGFIN(#?)"), r = toNFC("ə%1") }, { p = toNFC("MKR_OVOCBFIN(#?)"), r = toNFC("oː%1") }, { p = toNFC("MKR_OVOCMFIN(#?)"), r = toNFC("oː%1") }, { p = toNFC("MKR_IVOCBFIN(#?)"), r = toNFC("iː%1") },
    { p = toNFC("MKR_IVOCMMEDEFIN(#?)"), r = toNFC("ɪv'%1") }, { p = toNFC("MKR_IVOCMFIN(#?)"), r = toNFC("iː%1") },
    { p = toNFC("MKR_IVOCDMEDEFIN(#?)"), r = toNFC("iː%1") }, { p = toNFC("MKR_UIVOCDMEDEFIN(#?)"), r = toNFC("iː%1") },
    { p = toNFC("MKR_IVOCDFIN(#?)"), r = toNFC("iː%1") }, { p = toNFC("MKR_UIVOCDFIN(#?)"), r = toNFC("iː%1") },
    { p = toNFC("MKR_AACTLNGVOCTHSILFIN(#?)"), r = toNFC("ɑː%1") }, { p = toNFC("MKR_AIDHFINSCHWA(#?)"), r = toNFC("ə%1") }, { p = toNFC("MKR_AIGHFINSCHWA(#?)"), r = toNFC("ə%1") }, { p = toNFC("MKR_AIDHFINVOC(#?)"), r = toNFC("ai%1") }, { p = toNFC("MKR_AIGHFINVOC(#?)"), r = toNFC("ai%1") },
    { p = toNFC("MKR_EA_COMPOUND_LONG_E"), r = toNFC("eː") },
    { p = toNFC("MKR_A_I_ACT_LNG_RSLV"), r = toNFC("ɑː") }, { p = toNFC("MKR_E_ACT_I_LNG"), r = toNFC("eː") }, { p = toNFC("MKR_I_ACT_U_LNG"), r = toNFC("uː") }, { p = toNFC("MKR_A_ACT_LNG"), r = toNFC("ɑː") }, { p = toNFC("MKR_E_ACT_LNG"), r = toNFC("eː") }, { p = toNFC("MKR_I_ACT_LNG"), r = toNFC("iː") }, { p = toNFC("MKR_O_ACT_LNG"), r = toNFC("oː") }, { p = toNFC("MKR_U_ACT_LNG"), r = toNFC("uː") }, { p = toNFC("MKR_AOLNG"), r = toNFC("iː") }, { p = toNFC("MKR_AOILNG"), r = toNFC("iː") }, { p = toNFC("MKR_OIACTLNG"), r = toNFC("oː") }, { p = toNFC("MKR_AE_SEQ"), r = toNFC("eː") }, { p = toNFC("MKR_EO_SEQ"), r = toNFC("oː") }, { p = toNFC("MKR_IA_DIPH"), r = toNFC("iə") }, { p = toNFC("MKR_UA_DIPH"), r = toNFC("ua") },
    { p = toNFC("MKR_A_FRM_BAINNE"),                       r = toNFC("a") },
    { p = toNFC("MKR_AI_DIPH(" .. ZZZ_N_STR_PAL_PHON .. ")$"), r = toNFC("a%1") },
    { p = toNFC("MKR_AI_DIPH(nm')"),                       r = toNFC("a%1") },
    { p = toNFC("MKR_AI_DIPH"),                            r = toNFC("ai") },
    { p = toNFC("MKR_EI_DIPH"),                            r = toNFC("e") }, { p = toNFC("MKR_OI_DIPH(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "*')"), r = toNFC("ɛ%1") }, { p = toNFC("MKR_OI_DIPH"), r = toNFC("ɔ") }, { p = toNFC("MKR_UI_DIPH"), r = toNFC("ɪ") }, { p = toNFC("MKR_AU_DIPH"), r = toNFC("au") }, { p = toNFC("MKR_OU_DIPH"), r = toNFC("ou") }, { p = toNFC("MKR_VOC_AMH_MED_R"), r = toNFC("MKR_TEMP_CONN_AU") }, { p = toNFC("MKR_VOC_EABH_MED_R"), r = toNFC("MKR_TEMP_CONN_AU") }, { p = toNFC("MKR_EA_PRE_BH_VOC"), r = toNFC("a") }, { p = toNFC("MKR_IO_SHT_TRGT"), r = toNFC("ɪ") },
    { p = toNFC("MKR_EACHTBRDFX"),         r = toNFC("axt") },
    { p = toNFC("MKR_EA_BRD_SHT_PRE_CHT"), r = toNFC("a") },
    { p = toNFC("MKR_EA_SLN_PRE_CH"),      r = toNFC("æ") },
    { p = toNFC("MKR_EA_SLN_PRE_NG"),      r = toNFC("æ") }, { p = toNFC("MKR_EA_BRD_PRE_NG"), r = toNFC("a") }, { p = toNFC("MKR_EA_SLN_PRE_NN"), r = toNFC("æ") }, { p = toNFC("MKR_EA_BRD_PRE_NN"), r = toNFC("a") }, { p = toNFC("MKR_EA_SLN_PRE_RPRIME"), r = toNFC("æ") }, { p = toNFC("MKR_EA_BRD_PRE_R"), r = toNFC("a") }, { p = toNFC("MKR_IU_SLN_FIN_PRE_CH"), r = toNFC("ʊ") }, { p = toNFC("MKR_EA_SLN_PRE_N"), r = toNFC("æ") }, { p = toNFC("MKR_EA_BRD_PRE_N"), r = toNFC("a") },
    { p = toNFC("ea"), r = toNFC("a") },
}

placeholder_creation_rules_stage4_5 = {
    { p = toNFC("ɑu"), r = toNFC("MKR_PHON_AU_DIPH") }, { p = toNFC("ai"), r = toNFC("MKR_PHON_AI_DIPH") },
    { p = toNFC("iə"), r = toNFC("MKR_PHON_IA_DIPH") }, { p = toNFC("ua"), r = toNFC("MKR_PHON_UA_DIPH") },
    { p = toNFC("ou"), r = toNFC("MKR_PHON_OU_DIPH") }, { p = toNFC("ei"), r = toNFC("MKR_PHON_EI_DIPH") },
    { p = toNFC("oi"), r = toNFC("MKR_PHON_OI_DIPH") }, { p = toNFC("ui"), r = toNFC("MKR_PHON_UI_DIPH") },
    { p = toNFC("əu"), r = toNFC("MKR_PHON_SCHWA_U_DIPH") }, { p = toNFC("aw"), r = toNFC("MKR_PHON_AW_SEQ") },
    { p = toNFC("əi"), r = toNFC("MKR_PHON_SCHWA_I_DIPH") },
    { p = toNFC("ɑː"), r = toNFC("MKR_PHON_A_LONG") }, { p = toNFC("eː"), r = toNFC("MKR_PHON_E_LONG") },
    { p = toNFC("iː"), r = toNFC("MKR_PHON_I_LONG") }, { p = toNFC("oː"), r = toNFC("MKR_PHON_O_LONG") },
    { p = toNFC("uː"), r = toNFC("MKR_PHON_U_LONG") }, { p = toNFC("ɨː"), r = toNFC("MKR_PHON_Y_LONG") },
    { p = toNFC("æː"), r = toNFC("MKR_PHON_AE_LONG") },
}
core_allophony_rules_for_stage4_5 = {
    { p = toNFC("^(ˈ?)o(sp')"), r = "%1ɔ%2" },
    { p = toNFC("(st')i"), r = "%1ʊ" },
    { p = toNFC("MKR_PHON_Y_LONG"), r = toNFC("MKR_PHON_I_LONG") },
    { p = toNFC("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "[']?)([ou])([kgxɣ])"), r = "%1ʊ%3" },
    { p = toNFC("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "['])(a)(r)$"), r = "%1a%3" },
    { p = toNFC("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "['])(a)(R)$"), r = "%1a%3" },
    { p = toNFC("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "['])(a)(" .. BROAD_CONSONANT_PHONETIC_CLASS_NO_CAPTURE:gsub("[rR]", "") .. ")"), r = "%1ɑ%3" },
    { p = toNFC("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "['])(a)(" .. BROAD_CONSONANT_PHONETIC_CLASS_NO_CAPTURE:gsub("[rR]", "") .. ")$"), r = "%1ɑ%3" },
    { p = toNFC("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "['])(a)([^" .. ANY_CONSONANT_PHONETIC_RAW_CHARS_STR .. "rR]?)$"), r = "%1æ%3" },
    { p = toNFC("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "['])(a)"), r = "%1æ" },
    { p = toNFC("a"), r = toNFC("a") },
    { p = toNFC("e"), r = toNFC("ɛ") },
    { p = toNFC("i"), r = toNFC("ɪ") },
    { p = toNFC("o"), r = toNFC("ʊ") },
    { p = toNFC("u"), r = toNFC("ʊ") },
    { p = toNFC("(v')([aæ])"), r = "%1%2" }, { p = toNFC("t(æ)"), r = "t'%1" }, { p = toNFC("l(MKR_PHON_I_LONG)"), r = "l'%1" }, { p = toNFC("d(l'MKR_PHON_I_LONG)"), r = "d'%1" }, { p = toNFC("n(iv')"), r = "n'%1" }, { p = toNFC("(d'a)(r)(h)(MKR_PHON_A_LONGɾ')"), r = "%1ɾˠ%4" }, { p = toNFC("(MKR_PHON_A_LONG)i(r)$"), r = "%1iɾ'" }, { p = toNFC("d(a)(r)"), r = "d'%1%2" }, { p = toNFC("k(a)(rt)"), r = "c%1%2" },
    { p = toNFC("(MKR_PHON_I_LONGɔ)([" .. BROAD_CONSONANT_PHONETIC_CLASS_NO_CAPTURE .. "])"), r = "%1%2" },
    { p = toNFC("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "*'?)([ɔʊʌ])(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "['])"), r = "%1ɛ%3" },
    { p = toNFC("([ɾR]')i"), r = "%1ɛ" }, { p = toNFC("([ɾR])i"), r = "%1ɛ" },
    { p = toNFC("([ɾR]')ɔ"), r = "%1ɔ" }, { p = toNFC("([ɾR])ɔ"), r = "%1ɔ" },
    { p = toNFC("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "*')(a)(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "['])"), r = "%1ɛ%3" },
    { p = toNFC("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "*')([ɔʊʌ])(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "['])"), r = "%1ɪ%3" },
    { p = toNFC("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "*')(e)(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "['])"), r = "%1ɛ%3" },
    { p = toNFC("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "*')(i)(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "['])"), r = "%1ɪ%3" },
    { p = toNFC("l_neutral_"), r = toNFC("l") }, { p = toNFC("n_neutral_"), r = toNFC("n") },
}
placeholder_restoration_rules_stage4_5 = {
    { p = toNFC("MKR_PHON_A_LONG"), r = toNFC("ɑː") }, { p = toNFC("MKR_PHON_E_LONG"), r = toNFC("eː") },
    { p = toNFC("MKR_PHON_I_LONG"), r = toNFC("iː") }, { p = toNFC("MKR_PHON_O_LONG"), r = toNFC("oː") },
    { p = toNFC("MKR_PHON_U_LONG"), r = toNFC("uː") }, { p = toNFC("MKR_PHON_Y_LONG"), r = toNFC("ɨː") },
    { p = toNFC("MKR_PHON_AE_LONG"), r = toNFC("æː") },
    { p = toNFC("MKR_PHON_AU_DIPH"), r = toNFC("ɑu") }, { p = toNFC("MKR_PHON_AI_DIPH"), r = toNFC("ai") },
    { p = toNFC("MKR_PHON_IA_DIPH"), r = toNFC("iə") }, { p = toNFC("MKR_PHON_UA_DIPH"), r = toNFC("ua") },
    { p = toNFC("MKR_PHON_OU_DIPH"), r = toNFC("ou") }, { p = toNFC("MKR_PHON_EI_DIPH"), r = toNFC("ei") },
    { p = toNFC("MKR_PHON_OI_DIPH"), r = toNFC("oi") }, { p = toNFC("MKR_PHON_UI_DIPH"), r = toNFC("ui") },
    { p = toNFC("MKR_PHON_SCHWA_U_DIPH"), r = toNFC("əu") }, { p = toNFC("MKR_PHON_AW_SEQ"), r = toNFC("ɑu") },
    { p = toNFC("MKR_PHON_SCHWA_I_DIPH"), r = toNFC("əi") },
}
connacht_au_to_schwa_u_shift_rule_stage4_5 = { p = toNFC("^(ˈ?[" ..
ANY_CONSONANT_PHONETIC_RAW_CHARS_STR .. "]*'?)(ɑu)([" .. ANY_CONSONANT_PHONETIC_RAW_CHARS_STR .. "]*'?)$"), r = function(
    full_match, pre_part, au_diph, post_part)
    if is_likely_monosyllable_phonetic_revised(full_match) then return (pre_part or "") ..
        toNFC("əu") .. (post_part or "") end; return full_match
end }
temp_conn_au_to_final_au_rule_stage4_5 = { p = toNFC("MKR_TEMP_CONN_AU"), r = toNFC("əu") }
irishPhonetics.rules_stage4_5_2_connacht_specific_vowel_shifts = {
    { p = toNFC("(oː)(nʲ)"), r = toNFC("uː%2") },
    { p = toNFC("(oː)(" .. ZZZ_N_STR_PAL_PHON .. ")"), r = toNFC("uː%2") },
}

irishPhonetics.rules_stage4_5_contextual_allophony_on_phonetic = {}

local process_vocalization_on_units_impl
process_vocalization_on_units_impl = function(parsed_units, phon_word_input, context)
    if not parsed_units or #parsed_units < 2 then return false end
    local modified_in_pass = false
    local new_units_build = {}
    local i = 1
    while i <= #parsed_units do
        local current_unit = parsed_units[i]
        local next_unit = (i < #parsed_units) and parsed_units[i + 1] or nil

        local v_phon = current_unit.phon
        local is_v_fric = umatch(v_phon, "^[vjɣwˠ]")


        if is_v_fric and i > 1 then
            local prev_unit = parsed_units[i - 1]
            local is_prev_vowel = (prev_unit.quality == "vowel")
            local is_next_vowel = next_unit and (next_unit.quality == "vowel")
            local is_word_final = (i == #parsed_units)

            if is_prev_vowel and (is_word_final or is_next_vowel) then
                local new_phon = v_phon
                if v_phon == toNFC("vˠ") or v_phon == toNFC("w") then
                    new_phon = toNFC("əu")
                elseif v_phon == toNFC("vʲ") or v_phon == toNFC("j") then
                    new_phon = toNFC("iː")
                elseif v_phon == toNFC("ɣ") then
                    new_phon = toNFC("əi")
                end

                if new_phon ~= v_phon then
                    debug_print_minimal("Stage4_4_1_VocalizeLenitedFricatives", "PROCEDURAL Vocalization: Replacing '",
                        prev_unit.phon .. v_phon, "' with '", new_phon, "'")
                    table.remove(new_units_build) -- remove previous vowel
                    table.insert(new_units_build, { phon = new_phon, stress = prev_unit.stress, quality = "vowel" })
                    modified_in_pass = true
                    i = i + 1
                    goto continue_vocalization_loop
                end
            end
        end
        table.insert(new_units_build, current_unit)
        i = i + 1
        ::continue_vocalization_loop::
    end

    if modified_in_pass then return new_units_build else return false end
end
local process_vocalization_on_units = memoize(process_vocalization_on_units_impl)

local function process_phonetic_units_procedurally(phon_word_input, stage_name_for_debug, unit_processor_func,
                                                   context_params)
    if STAGE_DEBUG_ENABLED[stage_name_for_debug] then debug_print_minimal("  " .. stage_name_for_debug .. " START (Proc Helper): In=",
            phon_word_input) end
    if not phon_word_input or phon_word_input == "" then return phon_word_input end

    local parsed_units = parse_phonetic_string_to_units_for_epenthesis(phon_word_input)
    if not parsed_units or #parsed_units == 0 then
        if STAGE_DEBUG_ENABLED[stage_name_for_debug] then debug_print_minimal("  " .. stage_name_for_debug .. " END (no units): Out=",
                phon_word_input) end
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
        if STAGE_DEBUG_ENABLED[stage_name_for_debug] then debug_print_minimal(
            "  " .. stage_name_for_debug .. " END (modified by unit_processor): Out=", new_phon_word) end
        return new_phon_word
    else
        if STAGE_DEBUG_ENABLED[stage_name_for_debug] then debug_print_minimal(
            "  " .. stage_name_for_debug .. " END (no change by unit_processor): Out=", phon_word_input) end
        return phon_word_input
    end
end

process_phonetic_units_procedurally = memoize(process_phonetic_units_procedurally)

local process_disyllabic_raising_on_units_impl
process_disyllabic_raising_on_units_impl = function(parsed_units, phon_word_input, context)
    if not parsed_units or #parsed_units < 2 then return false end
    local vowel_units_data, primary_stress_vowel_original_index, explicit_stress_mark_found = {}, -1, false
    for k, unit_data in ipairs(parsed_units) do
        if unit_data.stress == toNFC("ˈ") then
            explicit_stress_mark_found = true; if k + 1 <= #parsed_units and parsed_units[k + 1].quality == "vowel" then
                primary_stress_vowel_original_index =
                    k + 1
            end
        elseif unit_data.quality == "vowel" then
            table.insert(vowel_units_data,
                { phon = unit_data.phon, stress = unit_data.stress, quality = unit_data.quality, original_idx = k }); if not explicit_stress_mark_found and primary_stress_vowel_original_index == -1 then
                primary_stress_vowel_original_index =
                    k
            end
        end
    end
    if #vowel_units_data ~= 2 then return false end
    local v1_data, v2_data = vowel_units_data[1], vowel_units_data[2]; local v1_original_idx = v1_data.original_idx
    local v1_is_stressed = (v1_original_idx == primary_stress_vowel_original_index)
    if not v1_is_stressed then return false end
    local v1_phon, v2_phon = v1_data.phon, v2_data.phon; local v1_is_short, v2_is_long = not umatch(v1_phon, "ː$"),
        umatch(v2_phon, "ː$")
    if not (v1_is_stressed and v1_is_short and v2_is_long) then return false end
    local c_after_v1_quality, c_after_v1_phon = "neutral", ""
    if v1_original_idx + 1 < v2_data.original_idx then
        local cons_idx = v1_original_idx + 1; while cons_idx < v2_data.original_idx and parsed_units[cons_idx].quality ~= "vowel" do
            if parsed_units[cons_idx].quality ~= "stress_mark" then
                c_after_v1_quality = parsed_units[cons_idx].quality; c_after_v1_phon = parsed_units[cons_idx].phon; break
            end; cons_idx = cons_idx + 1
        end
    end
    debug_print_minimal("Stage4_5_1_DisyllabicShortLongRaising", "V1='", v1_phon, "', C_after_V1_qual='",
        c_after_v1_quality, "', C_after_V1_phon='", c_after_v1_phon, "', V2='", v2_phon, "'")
    local new_v1_phon = v1_phon
    if (v1_phon == toNFC("ɑ") or v1_phon == toNFC("ɔ") or v1_phon == toNFC("ʌ")) and c_after_v1_quality == "nonpalatal" then
        new_v1_phon = toNFC("ʊ")
    elseif (v1_phon == toNFC("ɛ") or v1_phon == toNFC("ɪ") or v1_phon == toNFC("i") or v1_phon == toNFC("e") or v1_phon == toNFC("ai")) and c_after_v1_quality == "palatal" then
        new_v1_phon = toNFC("ɪ")
    end
    if new_v1_phon ~= v1_phon then
        debug_print_minimal("Stage4_5_1_DisyllabicShortLongRaising", "Applying raising: V1 '", v1_phon, "' -> '",
            new_v1_phon, "'"); parsed_units[v1_original_idx].phon = new_v1_phon; return true
    end
    return false
end
local process_disyllabic_raising_on_units = memoize(process_disyllabic_raising_on_units_impl)

local process_nasalization_on_units_impl
process_nasalization_on_units_impl = function(parsed_units, phon_word_input, context)
    debug_print_minimal("Nasalization", "General nasal spreading TEMPORARILY MINIMIZED/DISABLED for 43 testing.")
    return false
end
local process_nasalization_on_units = memoize(process_nasalization_on_units_impl)

local process_unstressed_reduction_on_units_impl
process_unstressed_reduction_on_units_impl = function(parsed_units, phon_word_input, context)
    if not parsed_units or #parsed_units == 0 then return false end
    local modified_in_pass = false
    local primary_stress_found, primary_stress_vowel_index = false, -1
    for k, unit_data in ipairs(parsed_units) do if unit_data.stress == toNFC("ˈ") then if k + 1 <= #parsed_units and parsed_units[k + 1].quality == "vowel" then
                primary_stress_found = true; primary_stress_vowel_index = k + 1; break
            elseif unit_data.quality == "vowel" then
                primary_stress_found = true; primary_stress_vowel_index = k; break
            end end end
    if not primary_stress_found then for k, unit_data in ipairs(parsed_units) do if unit_data.quality == "vowel" then
                primary_stress_vowel_index = k; primary_stress_found = true; debug_print_minimal(
                "Stage4_6_UnstressedVowelReduction_Procedural", "No explicit stress, first vowel '", unit_data.phon,
                    "' at unit ", k, " is stressed."); break
            end end end

    for k, unit_data in ipairs(parsed_units) do
        if unit_data.quality == "vowel" then
            local is_stressed = (k == primary_stress_vowel_index); local v_phon = unit_data.phon;
            local is_eligible = not is_stressed and not umatch(v_phon, "ː$") and v_phon ~= toNFC("ə") and
            v_phon ~= toNFC("i") and v_phon ~= toNFC("ʊ̽") and
            #parse_phonetic_string_to_units_for_epenthesis(v_phon) == 1
            if is_eligible then
                local prec_c_qual, foll_c_qual, prec_c_unit_idx = "neutral", "neutral", -1
                local prev_stressed_vowel_is_u_type = false
                if primary_stress_vowel_index < k and primary_stress_vowel_index > 0 then
                    local stressed_v_phon = parsed_units[primary_stress_vowel_index].phon
                    if stressed_v_phon == toNFC("uː") or stressed_v_phon == toNFC("ʊ") then
                        prev_stressed_vowel_is_u_type = true
                    end
                end

                if k > 1 then
                    local prev_actual_c_idx = k - 1; while prev_actual_c_idx > 0 and parsed_units[prev_actual_c_idx].quality == "stress_mark" do prev_actual_c_idx =
                        prev_actual_c_idx - 1 end; if prev_actual_c_idx > 0 and (parsed_units[prev_actual_c_idx].quality == "palatal" or parsed_units[prev_actual_c_idx].quality == "nonpalatal") then
                        prec_c_qual = parsed_units[prev_actual_c_idx].quality; prec_c_unit_idx = prev_actual_c_idx
                    end
                end
                if k < #parsed_units then
                    local next_actual_c_idx = k + 1; if next_actual_c_idx <= #parsed_units and parsed_units[next_actual_c_idx].quality ~= "stress_mark" then if parsed_units[next_actual_c_idx].quality == "palatal" or parsed_units[next_actual_c_idx].quality == "nonpalatal" then foll_c_qual =
                            parsed_units[next_actual_c_idx].quality end end
                end

                local reduced_v = toNFC("ə")
                if prev_stressed_vowel_is_u_type and (foll_c_qual == "nonpalatal" or (foll_c_qual == "neutral" and prec_c_qual == "nonpalatal")) then
                    if prec_c_unit_idx == primary_stress_vowel_index + 1 then
                        reduced_v = toNFC("MKR_SCHWA_U_TINT")
                    end
                elseif foll_c_qual == "palatal" then
                    reduced_v = toNFC("i")
                elseif foll_c_qual == "nonpalatal" then
                    reduced_v = toNFC("ə")
                elseif prec_c_qual == "palatal" then
                    reduced_v = toNFC("i")
                end

                if v_phon == toNFC("ɛ") and k > 1 and parsed_units[k - 1].phon == toNFC("v'") and k == #parsed_units then
                    reduced_v = toNFC("ə")
                end

                if reduced_v ~= unit_data.phon then
                    debug_print_minimal("Stage4_6_UnstressedVowelReduction_Procedural", "Reducing '", unit_data.phon,
                        "' to '", reduced_v, "'. Prec: ", prec_c_qual, " Foll: ", foll_c_qual, " PrevStressedU: ",
                        tostring(prev_stressed_vowel_is_u_type)); parsed_units[k].phon = reduced_v; modified_in_pass = true
                end
            end
        end
    end
    return modified_in_pass
end
local process_unstressed_reduction_on_units = memoize(process_unstressed_reduction_on_units_impl)

irishPhonetics.rules_stage4_6_unstressed_vowel_reduction_specific_finals = { { p = toNFC("aí$"), r = toNFC("iː") }, { p = toNFC("eiə$"), r = toNFC("iː") }, { p = toNFC("iːə$"), r = toNFC("iː") }, }
irishPhonetics.EPENTHESIS_TARGET_CLUSTERS_BROAD = { [toNFC("lk")] = true, [toNFC("lg")] = true, [toNFC("lb")] = true,
    [toNFC("lv")] = true, [toNFC("rm")] = true, [toNFC("rx")] = true, [toNFC("rb")] = true, [toNFC("rg")] = true, }
irishPhonetics.EPENTHESIS_TARGET_CLUSTERS_SLENDER = { [toNFC("lk")] = true, [toNFC("lf")] = true, [toNFC("rg")] = true,
    [toNFC("rk")] = true, [toNFC("nm")] = true, }

local function process_epenthesis_on_units(parsed_units, phon_word_input, context)
    local is_overall_monosyllable = is_likely_monosyllable_phonetic_revised(phon_word_input, parsed_units)

    if not is_overall_monosyllable then return false end

    local vowel_count_for_epenthesis = 0
    for _, unit in ipairs(parsed_units) do
        if unit.quality == "vowel" then vowel_count_for_epenthesis = vowel_count_for_epenthesis + 1 end
    end

    if vowel_count_for_epenthesis >= 3 then
        debug_print_minimal("EpenthesisAndStrongSonorants", "PROCEDURAL Epenthesis: Word '", phon_word_input,
            "' has >=3 syllables, SKIPPING epenthesis.")
        return false
    end

    local new_units_build, i, modified_by_epenthesis = {}, 1, false
    while i <= #parsed_units do
        if parsed_units[i].quality == "stress_mark" then
            table.insert(new_units_build, parsed_units[i]); i = i + 1; if i > #parsed_units then break end
        end
        if i + 2 <= #parsed_units then
            local unit_v, unit_c1, unit_c2 = parsed_units[i], parsed_units[i + 1], parsed_units[i + 2]
            local is_v_short = unit_v.quality == "vowel" and not umatch(unit_v.phon, "ː$")
            local c1_base = ugsub(unit_c1.phon, "['ˠʲ̪]", ""); local is_c1_son = umatch(c1_base, "^[rlnm]$")
            local c2_base = ugsub(unit_c2.phon, "['ˠʲ̪]", ""); local is_c2_valid = umatch(c2_base, "^[kgptdfbxs]$") or
            (is_c1_son and umatch(c2_base, "^[rlnm]$"))
            local c1_qual, c2_qual = unit_c1.quality, unit_c2.quality
            local cluster_key = c1_base .. c2_base; local ep_v_insert = nil
            if is_v_short and is_c1_son and is_c2_valid then
                if c1_qual == "palatal" and c2_qual == "palatal" then
                    if irishPhonetics.EPENTHESIS_TARGET_CLUSTERS_SLENDER[cluster_key] then ep_v_insert = toNFC("i") end
                elseif c1_qual == "nonpalatal" and c2_qual == "nonpalatal" then
                    if irishPhonetics.EPENTHESIS_TARGET_CLUSTERS_BROAD[cluster_key] then ep_v_insert = toNFC("ə") end
                end
            end
            if ep_v_insert then
                debug_print_minimal("EpenthesisAndStrongSonorants", "PROCEDURAL Epenthesis: ", unit_v.stress ..
                unit_v.phon, unit_c1.phon, unit_c2.phon, " -> inserting ", ep_v_insert)
                table.insert(new_units_build, unit_v); table.insert(new_units_build, unit_c1); table.insert(
                new_units_build,
                    { phon = ep_v_insert, stress = "", quality = (ep_v_insert == toNFC("i") and "palatal" or "nonpalatal") }); table
                    .insert(new_units_build, unit_c2)
                i = i + 3; modified_by_epenthesis = true
            else
                table.insert(new_units_build, parsed_units[i]); i = i + 1
            end
        else
            if i <= #parsed_units then table.insert(new_units_build, parsed_units[i]) end; i = i + 1
        end
    end
    if modified_by_epenthesis then return new_units_build else return false end
end

local process_epenthesis_on_units = memoize(process_epenthesis_on_units)

irishPhonetics.rules_stage5_strong_sonorants_only = {}
do
    local CPART_CAPTURE = CPART_CAPTURE_STRICT; local FINAL_CONS_CAPTURE = FINAL_CONSONANT_CAPTURE_STRICT
    local vowel_effects_map_ss_connacht = {
        { input_v_class_str = VOWEL_A_CLASS_CAPTURE_STRICT, broad_lnm = toNFC("ɑː"), broad_r = toNFC("ɑː"), pal_lnm_N_target = toNFC("a"), pal_lnm_L_target = toNFC("a"), pal_lnm_M_target = toNFC("a"), pal_r = toNFC("a"), sonorant_triggers_special_diphthong = {} },
        { input_v_class_str = VOWEL_E_I_CLASS_CAPTURE_STRICT, broad_lnm = toNFC("iː"), broad_r = toNFC("a"), pal_lnm_N_target = toNFC("iː"), pal_lnm_L_target = toNFC("iː"), pal_lnm_M_target = toNFC("iː"), pal_r = toNFC("əi"), sonorant_triggers_special_diphthong = {} },
        { input_v_class_str = VOWEL_O_U_CLASS_CAPTURE_STRICT, broad_lnm = toNFC("uː"), broad_r = toNFC("ɔ"), pal_lnm_N_target = toNFC("iː"), pal_lnm_L_target = toNFC("oi"), pal_lnm_M_target = toNFC("uː"), pal_r = toNFC("ai"), sonorant_triggers_special_diphthong = { [ZZZ_L_STR_BRD_PHON] = toNFC("ɑu"), [ZZZ_L_SNG_BRD_PHON] = toNFC("ɑu") } },
        { input_v_class_str = DIPHTHONG_AI_CAPTURE_STRICT, broad_lnm = toNFC("ɑː"), broad_r = toNFC("ɑː"), pal_lnm_N_target = toNFC("ai"), pal_lnm_L_target = toNFC("ai"), pal_lnm_M_target = toNFC("ai"), pal_r = toNFC("ɑː"), sonorant_triggers_special_diphthong = {} }
    }

    local function create_rules_for_specific_sonorant(rules_table, vowel_class_capture_str_arg,
                                                      specific_son_marker_literal, son_type_key_base_str_arg,
                                                      veffect_entry_arg, is_palatal_arg)
        local actual_repl_v_base
        if veffect_entry_arg.sonorant_triggers_special_diphthong[specific_son_marker_literal] and not is_palatal_arg then
            actual_repl_v_base = veffect_entry_arg.sonorant_triggers_special_diphthong[specific_son_marker_literal]
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
            if son_type_key_base_str_arg == "BroadN" or son_type_key_base_str_arg == "BroadL" or son_type_key_base_str_arg == "BroadM" then
                actual_repl_v_base = veffect_entry_arg.broad_lnm
            elseif son_type_key_base_str_arg == "BroadR" then
                actual_repl_v_base = veffect_entry_arg.broad_r
            else
                actual_repl_v_base = veffect_entry_arg[son_type_key_base_str_arg:lower()]
            end
        end
        if not actual_repl_v_base then
            debug_print_minimal("EpenthesisAndStrongSonorants", "SS Rule WARNING: No r vowel for VClass='",
                veffect_entry_arg.input_v_class_str:sub(1, 10), "' SonKey='", son_type_key_base_str_arg, "' Pal=",
                tostring(is_palatal_arg)); return
        end

        local ps_to_generate = {
            { ptn = "^(ˈ?)" .. CPART_CAPTURE .. vowel_class_capture_str_arg .. "(" .. specific_son_marker_literal .. ")" .. FINAL_CONS_CAPTURE .. "(#?)$", caps = { s = true, cp = true, v = true, son = true, fc = true, b = true } },
            { ptn = "^(ˈ?)" .. CPART_CAPTURE .. vowel_class_capture_str_arg .. "(" .. specific_son_marker_literal .. ")" .. "(#?)$", caps = { s = true, cp = true, v = true, son = true, fc = false, b = true } },
            { ptn = "^(ˈ?)" .. vowel_class_capture_str_arg .. "(" .. specific_son_marker_literal .. ")" .. FINAL_CONS_CAPTURE .. "(#?)$", caps = { s = true, cp = false, v = true, son = true, fc = true, b = true } },
            { ptn = "^(ˈ?)" .. vowel_class_capture_str_arg .. "(" .. specific_son_marker_literal .. ")" .. "(#?)$", caps = { s = true, cp = false, v = true, son = true, fc = false, b = true } }
        }
        for _, ptn_data in ipairs(ps_to_generate) do
            table.insert(rules_table, {
                p = ptn_data.ptn,
                r = function(...)
                    local all_captures = { ... }; local fm = all_captures[1]; local stress, c_part, vowel_cap, son_cap, final_cons_cap, boundary_cap; local current_cap_idx = 2
                    if ptn_data.caps.s then
                        stress = all_captures[current_cap_idx]; current_cap_idx = current_cap_idx + 1;
                    end; if ptn_data.caps.cp then
                        c_part = all_captures[current_cap_idx]; current_cap_idx = current_cap_idx + 1;
                    end; if ptn_data.caps.v then
                        vowel_cap = all_captures[current_cap_idx]; current_cap_idx = current_cap_idx + 1;
                    end; if ptn_data.caps.son then
                        son_cap = all_captures[current_cap_idx]; current_cap_idx = current_cap_idx + 1;
                    end; if ptn_data.caps.fc then
                        final_cons_cap = all_captures[current_cap_idx]; current_cap_idx = current_cap_idx + 1;
                    end; if ptn_data.caps.b then boundary_cap = all_captures[current_cap_idx]; end
                    local final_r_vowel = actual_repl_v_base
                    debug_print_minimal("EpenthesisAndStrongSonorants", "SS Rule EXEC (Helper): PtnKey='",
                        son_type_key_base_str_arg, veffect_entry_arg.input_v_class_str, "' Ptn='", ptn_data.ptn,
                        "' Full='", fm, "' VIn='", vowel_cap or "", "' VOut='", final_r_vowel or "nil", "'.")
                    return (stress or "") ..
                    (c_part or "") ..
                    (final_r_vowel or vowel_cap or "") ..
                    (son_cap or "") .. (final_cons_cap or "") .. (boundary_cap or "")
                end,
                use_current_phonetic_for_condition = true,
                condition_func = function(fm, pu) return is_likely_monosyllable_phonetic_revised(fm, pu) end
            })
        end
    end
    for _, veffect in ipairs(vowel_effects_map_ss_connacht) do
        for _, son_mkr in ipairs(BROAD_LNM_MARKERS_FOR_STAGE5) do
            local son_type_key = "BroadLNM"; if umatch(son_mkr, "ZZZN") then son_type_key = "BroadN" elseif umatch(son_mkr, "ZZZL") then son_type_key =
                "BroadL" elseif umatch(son_mkr, "^[mM]$") then son_type_key = "BroadM" end
            create_rules_for_specific_sonorant(irishPhonetics.rules_stage5_strong_sonorants_only,
                veffect.input_v_class_str, son_mkr, son_type_key, veffect, false)
        end
        for _, son_mkr in ipairs(BROAD_R_MARKERS_FOR_STAGE5) do create_rules_for_specific_sonorant(
            irishPhonetics.rules_stage5_strong_sonorants_only, veffect.input_v_class_str, son_mkr, "BroadR", veffect,
                false) end
        for _, son_mkr in ipairs(PALATAL_LNM_MARKERS_FOR_STAGE5) do
            local son_type_key = "PalLNM"; if umatch(son_mkr, "ZZZN") then son_type_key = "PalN" elseif umatch(son_mkr, "ZZZL") then son_type_key =
                "PalL" elseif umatch(son_mkr, "^[mM]'") then son_type_key = "PalM" elseif umatch(son_mkr, "^[nNlL]'") then son_type_key =
                "PalLNM" end
            create_rules_for_specific_sonorant(irishPhonetics.rules_stage5_strong_sonorants_only,
                veffect.input_v_class_str, son_mkr, son_type_key, veffect, true)
        end
        for _, son_mkr in ipairs(PALATAL_R_MARKERS_FOR_STAGE5) do create_rules_for_specific_sonorant(
            irishPhonetics.rules_stage5_strong_sonorants_only, veffect.input_v_class_str, son_mkr, "PalR", veffect, true) end
    end
end

irishPhonetics.rules_stage6_diacritics = {
    
        { p = toNFC("n(x)"), r = toNFC("nˠ%1") }, 
        { p = toNFC("s$"), r = toNFC("sˠ") }, 
        { p = toNFC("s(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])"), r = toNFC("sˠ%1") }, 
        { p = toNFC("s(" .. SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR .. ")"), r = toNFC("sˠ%1") }, 
        
        { p = toNFC("t$"), r = toNFC("t̪ˠ") }, 
        { p = toNFC("t(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])"), r = toNFC("t̪ˠ%1") }, 
        { p = toNFC("t(" .. SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR .. ")"), r = toNFC("t̪ˠ%1") }, 
        
        { p = toNFC("d$"), r = toNFC("d̪ˠ") }, 
        { p = toNFC("d(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])"), r = toNFC("d̪ˠ%1") }, 
        { p = toNFC("d(" .. SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR .. ")"), r = toNFC("d̪ˠ%1") }, 
        
        -- Default broad n, l to just velarized. Add dental marker specifically if needed.
        { p = toNFC("n$"), r = toNFC("nˠ") }, 
        { p = toNFC("n(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])"), r = toNFC("nˠ%1") }, 
        { p = toNFC("n(" .. SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR .. ")"), r = toNFC("nˠ%1") }, 
        
        { p = toNFC("l$"), r = toNFC("lˠ") }, 
        { p = toNFC("l(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])"), r = toNFC("lˠ%1") }, 
        { p = toNFC("l(" .. SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR .. ")"), r = toNFC("lˠ%1") }, 
    
        -- Specific rule for dental n/l if needed (example, not fully implemented here)
        -- { p = toNFC("(VOWEL_CONTEXT_FOR_DENTAL)(n)"), r = "%1n̪ˠ" },
    
        { p = toNFC("r$"), r = toNFC("ɾˠ") }, 
        { p = toNFC("r(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])"), r = toNFC("ɾˠ%1") }, 
        { p = toNFC("r(" .. SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR .. ")"), r = toNFC("ɾˠ%1") }, 
        
        { p = toNFC("m$"), r = toNFC("mˠ") }, 
        { p = toNFC("m(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])"), r = toNFC("mˠ%1") }, 
        { p = toNFC("m(" .. SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR .. ")"), r = toNFC("mˠ%1") }, 
        
        { p = toNFC("b$"), r = toNFC("bˠ") }, 
        { p = toNFC("b(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])"), r = toNFC("bˠ%1") }, 
        { p = toNFC("b(" .. SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR .. ")"), r = toNFC("bˠ%1") }, 
        
        { p = toNFC("p$"), r = toNFC("pˠ") }, 
        { p = toNFC("p(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])"), r = toNFC("pˠ%1") }, 
        { p = toNFC("p(" .. SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR .. ")"), r = toNFC("pˠ%1") }, 
        
        { p = toNFC("f$"), r = toNFC("fˠ") }, 
        { p = toNFC("f(" .. CONSONANT_CLASS_NO_CAPTURE .. "[^'])"), r = toNFC("fˠ%1") }, 
        { p = toNFC("f(" .. SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR .. ")"), r = toNFC("fˠ%1") }, 
    
}
irishPhonetics.rules_stage7_final_cleanup = {
    { p = ZZZ_N_STR_PAL_PHON, r = toNFC("n̠ʲ") }, { p = ZZZ_N_STR_BRD_PHON, r = toNFC("n̪ˠ") },
    { p = ZZZ_L_STR_PAL_PHON, r = toNFC("l̠ʲ") }, { p = ZZZ_L_STR_BRD_PHON, r = toNFC("l̪ˠ") },
    { p = ZZZ_N_SNG_BRD_PHON, r = toNFC("n̪ˠ") }, { p = ZZZ_L_SNG_BRD_PHON, r = toNFC("l̪ˠ") },
    { p = toNFC("(n̠ʲ)t̪$"), r = "%1tʲ" }, { p = toNFC("(n̠ʲ)t̪(" .. CONSONANT_CLASS_NO_CAPTURE .. ")"), r = "%1tʲ%2" },
    { p = toNFC("(lʲ)t̪$"), r = "%1tʲ" },
    { p = toNFC("(ɾʲ)j$"), r = "%1h" },
    { p = toNFC("j$"), r = toNFC("h") },
    { p = toNFC("MKR_SCHWA_U_TINT"), r = toNFC("ʊ̽") },
    { p = toNFC("(" .. ANY_CONSONANT_PHONETIC_RAW_CHARS_STR .. ")''"), r = "%1'" },
    { p = toNFC("^st'"), r = toNFC("ʃtʲ") },
    { p = toNFC("s'"), r = toNFC("ʃ") }, { p = toNFC("t'"), r = toNFC("tʲ") }, { p = toNFC("d'"), r = toNFC("dʲ") },
    { p = toNFC("k'"), r = toNFC("c") }, { p = toNFC("g'"), r = toNFC("ɟ") },
    { p = toNFC("l'"), r = toNFC("lʲ") }, { p = toNFC("n'"), r = toNFC("nʲ") },
    { p = toNFC("R'"), r = toNFC("ɾʲ") }, { p = toNFC("r'"), r = toNFC("ɾʲ") },
    { p = toNFC("f'"), r = toNFC("fʲ") }, { p = toNFC("v'"), r = toNFC("vʲ") },
    { p = toNFC("b'"), r = toNFC("bʲ") }, { p = toNFC("p'"), r = toNFC("pʲ") },
    { p = toNFC("M'"), r = toNFC("mʲ") }, { p = toNFC("m'"), r = toNFC("mʲ") },
    { p = toNFC("h'"), r = toNFC("ç") },
    { p = toNFC("L"), r = toNFC("lˠ") }, { p = toNFC("N"), r = toNFC("nˠ") },
    { p = toNFC("R"), r = toNFC("ɾˠ") }, { p = toNFC("M"), r = toNFC("mˠ") },
    { p = toNFC("h$"), r = "" }, { p = toNFC("#"), r = "" },
    { p = toNFC("^%s*(.-)%s*$"), r = "%1" }, { p = toNFC("ˈə"), r = toNFC("ə") },
    { p = toNFC(" "),            r = toNFC(" ") }, { p = toNFC("%-"), r = "" },
    { p = toNFC("MKR_"), r = "" },
    { p = toNFC("ZZZ"),  r = "" },
    { p = toNFC("&"),    r = "" },
    { p = toNFC("g"),    r = toNFC("ɡ") },
}

local function apply_rules_to_string_generic_impl(current_string_input, rules_to_apply_list, stage_name_str, mode_str,
                                                  use_orig_context_flag, o_context_str_for_func,
                                                  current_ortho_map_for_func)
    local current_string_local = current_string_input

    if mode_str == "iterative_gsub" then
        local iteration_changed_this_pass; repeat
            iteration_changed_this_pass = false
            local string_before_this_gsub_pass = current_string_local
            for _, rule_data in ipairs(rules_to_apply_list) do
                if type(rule_data.p) == "string" then
                    local r_target = rule_data.r
                    if type(rule_data.r) == "function" and rule_data.needs_full_context_in_func then
                        r_target = function(...) return rule_data.r(..., current_string_local,
                                ufind(current_string_local, rule_data.p, (...))) end
                    end
                    local new_str, num_repl = ugsub(current_string_local, rule_data.p, r_target)
                    if new_str ~= current_string_local then
                        debug_print_minimal(stage_name_str, "Iter.gsub: Rule '", rule_data.p, "' APPLIED to '",
                            current_string_local, "' -> '", new_str, "' (", num_repl, "x)"); current_string_local =
                        new_str; iteration_changed_this_pass = true
                    end
                end
            end
        until not iteration_changed_this_pass
    elseif mode_str == "single_pass_priority_match" then
        local new_string_parts = {}; local scan_offset = 1
        while scan_offset <= ulen(current_string_local) do
            local best_match_s, best_match_e, best_rule_idx; local best_captures = {}; local current_best_match_len = -1
            for rule_idx, rule_data in ipairs(rules_to_apply_list) do
                if type(rule_data.p) == "string" then
                    local s, e, cap1, cap2, cap3, cap4, cap5, cap6, cap7, cap8, cap9, cap10 = ufind(current_string_local,
                        rule_data.p, scan_offset)
                    if s then
                        local current_match_len = e - s + 1; if not best_match_s or s < best_match_s or (s == best_match_s and current_match_len > current_best_match_len) then
                            best_match_s = s; best_match_e = e; best_rule_idx = rule_idx; current_best_match_len =
                            current_match_len; best_captures = { cap1, cap2, cap3, cap4, cap5, cap6, cap7, cap8, cap9,
                                cap10 }
                        end
                    end
                end
            end
            if best_rule_idx then
                if best_match_s > scan_offset then table.insert(new_string_parts,
                        usub(current_string_local, scan_offset, best_match_s - 1)) end
                local rule = rules_to_apply_list[best_rule_idx]; local full_match_seg = usub(current_string_local,
                    best_match_s, best_match_e)
                local actual_caps_for_func = {}; if best_captures then for _, c_val in ipairs(best_captures) do if c_val ~= nil then
                            table.insert(actual_caps_for_func, c_val) end end end
                local apply_this_rule_now = true
                if rule.use_current_phonetic_for_condition and rule.condition_func then
                    local parsed_units_for_cond_generic = parse_phonetic_string_to_units_for_epenthesis(full_match_seg); if not rule.condition_func(full_match_seg, parsed_units_for_cond_generic) then apply_this_rule_now = false end
                end
                local r_val
                if apply_this_rule_now then
                    if type(rule.r) == "string" then
                        r_val = rule.r; if r_val:match("%%[%d]") then
                            local temp_r = r_val; for i_c = #actual_caps_for_func, 1, -1 do temp_r = ugsub(
                                temp_r, "%%" .. i_c, actual_caps_for_func[i_c] or "") end; r_val = temp_r
                        end
                    elseif type(rule.r) == "function" then
                        local call_params = { full_match_seg }; for _, cap_v in ipairs(actual_caps_for_func) do table
                                .insert(call_params, cap_v) end
                        if use_orig_context_flag then
                            local o_s, o_l = get_original_indices_from_map(best_match_s, best_match_e,
                                current_ortho_map_for_func); local o_match_info = { ortho_s = o_s, ortho_e = o_s + o_l -
                            1 }; table.insert(call_params, o_context_str_for_func); table.insert(call_params,
                                o_match_info)
                        elseif rule.needs_full_context_in_func then
                            table.insert(call_params, current_string_local); table.insert(call_params, best_match_s); table
                                .insert(call_params, best_match_e)
                        end
                        r_val = rule.r(table.unpack(call_params))
                    end; r_val = r_val or ""
                else
                    r_val = full_match_seg
                end
                table.insert(new_string_parts, r_val); scan_offset = best_match_e + 1
            else
                if scan_offset <= ulen(current_string_local) then table.insert(new_string_parts,
                        usub(current_string_local, scan_offset)) end; break
            end
        end; current_string_local = table.concat(new_string_parts)
    end
    return current_string_local
end
apply_rules_to_string_generic = (apply_rules_to_string_generic_impl)


function irishPhonetics.transcribe_single_word(orthographic_word_input)
    local cleaned_ortho_word = toNFC(orthographic_word_input)
    -- PreProcess is now the first stage in the stages table,
    -- so we run it first to get the cleaned_ortho_word for lexical lookup
    -- and for original_ortho_for_context.
    cleaned_ortho_word = apply_rules_to_string_generic(cleaned_ortho_word, irishPhonetics.rules_stage1_preprocess, "PreProcess", "single_pass_priority_match")
    if STAGE_DEBUG_ENABLED["PreProcess"] then debug_print_minimal("  PreProcess END: Out=", cleaned_ortho_word) end
    
    if not cleaned_ortho_word or cleaned_ortho_word == "" then return "" end

    -- Lexical Lookup AFTER cleaning (PreProcess output)
    local exception_key_direct = cleaned_ortho_word
    local exception_key_no_apostrophe = ugsub(cleaned_ortho_word, "^'", "") -- Check without initial apostrophe

    if lexical_exceptions_connacht[exception_key_direct] then
        if STAGE_DEBUG_ENABLED["LexicalLookup"] then debug_print_minimal("  LexicalLookup: Found '", exception_key_direct, "' -> [", lexical_exceptions_connacht[exception_key_direct], "]") end
        return lexical_exceptions_connacht[exception_key_direct]
    elseif lexical_exceptions_connacht[exception_key_no_apostrophe] and exception_key_no_apostrophe ~= exception_key_direct then
        if STAGE_DEBUG_ENABLED["LexicalLookup"] then debug_print_minimal("  LexicalLookup: Found (no apostrophe) '", exception_key_no_apostrophe, "' -> [", lexical_exceptions_connacht[exception_key_no_apostrophe], "]") end
        return lexical_exceptions_connacht[exception_key_no_apostrophe]
    end

    local current_word_phonetic = cleaned_ortho_word -- Start pipeline with cleaned word
    local original_ortho_for_context = cleaned_ortho_word 
    local ortho_map = {}
    
    local stages = {
        -- PreProcess is already done above, so it's not in this loop.
        -- The 'original_ortho_for_context' for subsequent stages is the *output* of PreProcess.
        { name = "Stage2_5_MarkSuffixes", rules = irishPhonetics.rules_stage2_5_mark_suffixes, mode = "single_pass_priority_match" },
        { name = "MarkDigraphsAndVocalisationTriggers", rules = irishPhonetics.rules_stage2_mark_digraphs_and_vocalisation_triggers, mode = "single_pass_priority_match" ,updates_map_from_original_with_priority = true}, -- CRITICAL: No updates_map_from_original
        { name = "ConsonantResolution", rules = irishPhonetics.rules_stage3_consonant_resolution, use_original_context_for_rules = true, is_procedural_stage = true, func = function(
            phon_word_in_stage3, o_context_str_stage3, current_ortho_map_stage3)
            if STAGE_DEBUG_ENABLED["ConsonantResolution"] then debug_print_minimal("  ConsonantResolution START (Proc): In=",
                    phon_word_in_stage3) end; local metathesis_phon_parts = {}; local meta_scan_offset = 1; while meta_scan_offset <= ulen(phon_word_in_stage3) do
                local stress_marker = ""; local current_phon_char_for_meta = usub(phon_word_in_stage3, meta_scan_offset,
                    meta_scan_offset); if current_phon_char_for_meta == toNFC("ˈ") then
                    stress_marker = toNFC("ˈ"); meta_scan_offset = meta_scan_offset + 1; if meta_scan_offset > ulen(phon_word_in_stage3) then
                        table.insert(metathesis_phon_parts, stress_marker); break
                    end; current_phon_char_for_meta = usub(phon_word_in_stage3, meta_scan_offset, meta_scan_offset)
                end; local c_phon_base = current_phon_char_for_meta; local c_is_palatal = false; local n_phon_base = ""; local n_is_palatal = false; local advance_for_c = 1; if usub(phon_word_in_stage3, meta_scan_offset + 1, meta_scan_offset + 1) == toNFC("'") then
                    c_is_palatal = true; advance_for_c = 2
                end; local n_phon_start_idx_in_phon = meta_scan_offset + advance_for_c; if n_phon_start_idx_in_phon <= ulen(phon_word_in_stage3) then
                    n_phon_base = usub(phon_word_in_stage3, n_phon_start_idx_in_phon, n_phon_start_idx_in_phon); if usub(phon_word_in_stage3, n_phon_start_idx_in_phon + 1, n_phon_start_idx_in_phon + 1) == toNFC("'") then n_is_palatal = true end
                end; local c_is_k_type = (c_phon_base == toNFC("k") or c_phon_base == toNFC("c")); local c_is_g_type = (c_phon_base == toNFC("g")); if ((c_is_k_type) and n_phon_base == toNFC("n")) or (c_is_g_type and n_phon_base == toNFC("n")) then if (meta_scan_offset == 1 and stress_marker == "") or (meta_scan_offset == (1 + ulen(stress_marker)) and stress_marker ~= "") then
                        debug_print_minimal("ConsonantResolution", "Metathesis candidate found: ",
                            stress_marker ..
                            c_phon_base .. (c_is_palatal and "'" or "") .. n_phon_base .. (n_is_palatal and "'" or "")); local n_phon_end_idx_in_phon =
                        n_phon_start_idx_in_phon + (n_is_palatal and 1 or 0); local ortho_s_n, ortho_len_n =
                        get_original_indices_from_map(n_phon_start_idx_in_phon, n_phon_end_idx_in_phon,
                            current_ortho_map_stage3); local quality_for_r; local n_ortho_actual_start_idx = ortho_s_n; local n_ortho_actual_end_idx =
                        ortho_s_n + ortho_len_n - 1; quality_for_r = determine_consonant_quality_ortho( -- This call might need to be removed if quality is fully handled in r
                        o_context_str_stage3, n_ortho_actual_start_idx, n_ortho_actual_end_idx); table.insert(
                        metathesis_phon_parts, stress_marker .. c_phon_base .. (c_is_palatal and toNFC("'") or "")); if quality_for_r == "palatal" then
                            table.insert(metathesis_phon_parts, toNFC("r'")) else table.insert(metathesis_phon_parts,
                                toNFC("r")) end; meta_scan_offset = n_phon_end_idx_in_phon + 1
                    else
                        table.insert(metathesis_phon_parts,
                            stress_marker ..
                            usub(phon_word_in_stage3, meta_scan_offset, meta_scan_offset + advance_for_c - 1)); meta_scan_offset =
                        meta_scan_offset + advance_for_c
                    end else
                    table.insert(metathesis_phon_parts,
                        stress_marker .. usub(phon_word_in_stage3, meta_scan_offset, meta_scan_offset)); meta_scan_offset =
                    meta_scan_offset + 1
                end
            end; phon_word_in_stage3 = table.concat(metathesis_phon_parts); local multi_char_rules_stage3 = {}; local single_char_rule_data_stage3; for _, rule_data_loop in ipairs(irishPhonetics.rules_stage3_consonant_resolution) do if rule_data_loop.p ~= toNFC("([bcdfghkmprst])") then
                    table.insert(multi_char_rules_stage3, rule_data_loop) else single_char_rule_data_stage3 =
                    rule_data_loop end end; local pass1_phonetic_parts_stage3 = {}; local pass1_scan_offset_stage3 = 1; while pass1_scan_offset_stage3 <= ulen(phon_word_in_stage3) do
                local best_match_s_this_iter, best_match_e_this_iter, best_rule_this_iter_idx; local best_captures_this_iter = {}; local current_best_match_length_this_iter = -1; for rule_idx_loop, rule_data_loop in ipairs(multi_char_rules_stage3) do
                    local s, e, cap1, cap2, cap3, cap4; s, e, cap1, cap2, cap3, cap4 = ufind(phon_word_in_stage3,
                        rule_data_loop.p, pass1_scan_offset_stage3); if s then
                        local current_match_len_loop = e - s + 1; if not best_match_s_this_iter or s < best_match_s_this_iter or (s == best_match_s_this_iter and current_match_len_loop > current_best_match_length_this_iter) then
                            best_match_s_this_iter = s; best_match_e_this_iter = e; best_rule_this_iter_idx =
                            rule_idx_loop; current_best_match_length_this_iter = current_match_len_loop; best_captures_this_iter = {
                                cap1, cap2, cap3, cap4 }
                        end
                    end
                end; if best_rule_this_iter_idx then
                    if best_match_s_this_iter > pass1_scan_offset_stage3 then table.insert(pass1_phonetic_parts_stage3,
                            usub(phon_word_in_stage3, pass1_scan_offset_stage3, best_match_s_this_iter - 1)) end; local rule =
                    multi_char_rules_stage3[best_rule_this_iter_idx]; local full_match_segment = usub(
                    phon_word_in_stage3, best_match_s_this_iter, best_match_e_this_iter); local original_ortho_s, original_ortho_len =
                    get_original_indices_from_map(best_match_s_this_iter, best_match_e_this_iter,
                        current_ortho_map_stage3); local original_match_info = { ortho_s = original_ortho_s, ortho_e =
                    original_ortho_s + original_ortho_len - 1 }; local actual_captures = {}; if best_captures_this_iter then for _, c_val in ipairs(best_captures_this_iter) do if c_val ~= nil then
                                table.insert(actual_captures, c_val) end end end; local r_text; if type(rule.r) == "string" then r_text =
                        rule.r elseif type(rule.r) == "function" then r_text = rule
                        .r(full_match_segment, o_context_str_stage3, original_match_info,
                            table.unpack(actual_captures)) end; r_text = r_text or ""; table.insert(
                    pass1_phonetic_parts_stage3, r_text); pass1_scan_offset_stage3 = best_match_e_this_iter + 1
                else if pass1_scan_offset_stage3 <= ulen(phon_word_in_stage3) then
                        table.insert(pass1_phonetic_parts_stage3,
                            usub(phon_word_in_stage3, pass1_scan_offset_stage3, pass1_scan_offset_stage3)); pass1_scan_offset_stage3 =
                        pass1_scan_offset_stage3 + 1
                    else break end end
            end; phon_word_in_stage3 = table.concat(pass1_phonetic_parts_stage3); if single_char_rule_data_stage3 then
                local pass2_phonetic_parts_stage3 = {}; local pass2_scan_offset_stage3 = 1; while pass2_scan_offset_stage3 <= ulen(phon_word_in_stage3) do
                    local char_to_check = usub(phon_word_in_stage3, pass2_scan_offset_stage3, pass2_scan_offset_stage3); if char_to_check:match("^[bcdfghkmprst]$") or umatch(char_to_check, "^MKR_[LN]_SNG_BRD$") or umatch(char_to_check, "^MKR_[LN]_STR_PAL$") or umatch(char_to_check, "^MKR_[LN]_STR_BRD$") then
                        local original_ortho_s, original_ortho_len = get_original_indices_from_map(
                        pass2_scan_offset_stage3, pass2_scan_offset_stage3, current_ortho_map_stage3); local original_match_info = { ortho_s =
                        original_ortho_s, ortho_e = original_ortho_s + original_ortho_len - 1 }; local r_text =
                        single_char_rule_data_stage3.r(char_to_check, o_context_str_stage3, original_match_info); r_text =
                        r_text or char_to_check; table.insert(pass2_phonetic_parts_stage3, r_text)
                    else table.insert(pass2_phonetic_parts_stage3, char_to_check) end; pass2_scan_offset_stage3 =
                    pass2_scan_offset_stage3 + 1
                end; phon_word_in_stage3 = table.concat(pass2_phonetic_parts_stage3)
            end; if STAGE_DEBUG_ENABLED["ConsonantResolution"] then debug_print_minimal("  ConsonantResolution END (Proc): Out=",
                    phon_word_in_stage3) end; return phon_word_in_stage3
        end },
        { name = "Stage3_5_ConsonantAssimilation", rules = irishPhonetics.rules_stage3_5_consonant_assimilation, mode = "iterative_gsub" },
        { name = "Stage3_2_ApplyStress", is_procedural_stage = true, func = function(phon_word, o_word, o_map)
            if STAGE_DEBUG_ENABLED["PreProcess"] then debug_print_minimal("  ApplyStress START: In=", phon_word, " (Original Ortho: '", o_word, "')") end
            local word_to_check_stress = o_word -- Use the original cleaned orthography for checking unstressed list
            local should_have_stress = true
            if UNSTRESSED_WORDS_AND_SUFFIXES[word_to_check_stress] then
                should_have_stress = false
                debug_print_minimal("PreProcess", "ApplyStress: Word '", word_to_check_stress, "' found in UNSTRESSED list.")
            else
                for _, prefix in ipairs(UNSTRESSED_PREFIXES_ORTHO) do
                    local prefix_p_for_match = ugsub(prefix, "%-", "")
                    if usub(word_to_check_stress, 1, ulen(prefix_p_for_match)) == prefix_p_for_match then
                        should_have_stress = false
                        debug_print_minimal("PreProcess", "ApplyStress: Word '", word_to_check_stress, "' has unstressed prefix '", prefix_p_for_match, "'.")
                        break
                    end
                end
            end
            if should_have_stress and not umatch(phon_word, "^ˈ") then
                phon_word = "ˈ" .. phon_word
                 debug_print_minimal("PreProcess", "ApplyStress: Adding stress to '", phon_word, "'.")
            end
            if STAGE_DEBUG_ENABLED["PreProcess"] then debug_print_minimal("  ApplyStress END: Out=", phon_word) end
            return phon_word
        end },
        { name = "Stage4_0_SpecificOrthoToTempMarker", rules = irishPhonetics.rules_stage4_0_specific_ortho_to_temp_marker, mode = "single_pass_priority_match", use_original_context_for_rules = true },
        { name = "Stage4_0_1_Resolve_CH_Marker", rules = irishPhonetics.rules_stage4_0_1_resolve_ch_marker, mode = "single_pass_priority_match", use_original_context_for_rules = true },
        { name = "Stage4_1_VocmarkToTempMarker", rules = irishPhonetics.rules_stage4_1_vocmarkToTempMarker, mode = "single_pass_priority_match" },
        { name = "Stage4_2_LongVowelsOrthoToTempMarker", rules = irishPhonetics.rules_stage4_2_long_vowels_ortho_to_temp_marker, mode = "single_pass_priority_match" },
        { name = "Stage4_3_DiphthongsOrthoToTempMarker", rules = irishPhonetics.rules_stage4_3_diphthongs_ortho_to_temp_marker, mode = "single_pass_priority_match", use_original_context_for_rules = true },
        { name = "Stage4_4_ResolveTempVowelMarkers", rules = irishPhonetics.rules_stage4_4_resolve_temp_vowel_markers, mode = "iterative_gsub" },
        { name = "Stage4_4_1_VocalizeLenitedFricatives", is_procedural_stage = true, func = function(phon_word) return process_phonetic_units_procedurally(phon_word, "Stage4_4_1_VocalizeLenitedFricatives", process_vocalization_on_units) end },
        { name = "Stage4_5_ContextualAllophonyOnPhonetic", is_procedural_stage = true, func = function(phon_word)
            if STAGE_DEBUG_ENABLED["Stage4_5_ContextualAllophonyOnPhonetic"] then debug_print_minimal(
                "  Stage4_5_ContextualAllophonyOnPhonetic START: In=", phon_word) end; phon_word =
            apply_rules_to_string_generic(phon_word, placeholder_creation_rules_stage4_5,
                "Stage4_5_ContextualAllophonyOnPhonetic", "iterative_gsub", false); phon_word =
            apply_rules_to_string_generic(phon_word, core_allophony_rules_for_stage4_5,
                "Stage4_5_ContextualAllophonyOnPhonetic", "iterative_gsub", false); phon_word =
            apply_rules_to_string_generic(phon_word, placeholder_restoration_rules_stage4_5,
                "Stage4_5_ContextualAllophonyOnPhonetic", "iterative_gsub", false); phon_word =
            apply_rules_to_string_generic(phon_word, { connacht_au_to_schwa_u_shift_rule_stage4_5 },
                "Stage4_5_ContextualAllophonyOnPhonetic", "single_pass_priority_match", false); phon_word =
            apply_rules_to_string_generic(phon_word, { temp_conn_au_to_final_au_rule_stage4_5 },
                "Stage4_5_ContextualAllophonyOnPhonetic", "single_pass_priority_match", false); if STAGE_DEBUG_ENABLED["Stage4_5_ContextualAllophonyOnPhonetic"] then
                    debug_print_minimal("  Stage4_5_ContextualAllophonyOnPhonetic END: Out=", phon_word) end; return phon_word
        end },
        { name = "Stage4_5_1_DisyllabicShortLongRaising", is_procedural_stage = true, func = function(phon_word) return
            process_phonetic_units_procedurally(phon_word, "Stage4_5_1_DisyllabicShortLongRaising",
                process_disyllabic_raising_on_units) end },
        { name = "Stage4_5_2_ConnachtSpecificVowelShifts", rules = irishPhonetics.rules_stage4_5_2_connacht_specific_vowel_shifts, mode = "iterative_gsub" },
        { name = "Nasalization", is_procedural_stage = true, func = function(phon_word) return
            process_phonetic_units_procedurally(phon_word, "Nasalization", process_nasalization_on_units) end },
        {
            name = "Stage4_6_UnstressedVowelReduction_Procedural",
            is_procedural_stage = true,
            func = function(phon_word)
                if STAGE_DEBUG_ENABLED["Stage4_6_UnstressedVowelReduction_Procedural"] then debug_print_minimal(
                    "  Stage4_6_UnstressedVowelReduction_Procedural START (Outer): In=", phon_word) end
                local parsed_units_for_mono_check = parse_phonetic_string_to_units_for_epenthesis(phon_word)
                if is_likely_monosyllable_phonetic_revised(phon_word, parsed_units_for_mono_check) then
                    debug_print_minimal("Stage4_6_UnstressedVowelReduction_Procedural", "Word '", phon_word,
                        "' is monosyllabic, SKIPPING."); if STAGE_DEBUG_ENABLED["Stage4_6_UnstressedVowelReduction_Procedural"] then
                            debug_print_minimal("  Stage4_6_UnstressedVowelReduction_Procedural END (monosyllable): Out=", phon_word) end; return
                    phon_word
                end
                phon_word = apply_rules_to_string_generic(phon_word,
                    irishPhonetics.rules_stage4_6_unstressed_vowel_reduction_specific_finals,
                    "Stage4_6_UnstressedVowelReduction_Procedural", "iterative_gsub")
                phon_word = process_phonetic_units_procedurally(phon_word, "Stage4_6_UnstressedVowelReduction_Procedural",
                    process_unstressed_reduction_on_units)
                if STAGE_DEBUG_ENABLED["Stage4_6_UnstressedVowelReduction_Procedural"] then debug_print_minimal(
                    "  Stage4_6_UnstressedVowelReduction_Procedural END (Outer): Out=", phon_word) end
                return phon_word
            end
        },
        {
            name = "EpenthesisAndStrongSonorants",
            is_procedural_stage = true,
            func = function(phon_word_in_stage5, o_context_str_stage5, current_ortho_map_stage5)
                if STAGE_DEBUG_ENABLED["EpenthesisAndStrongSonorants"] then debug_print_minimal(
                    "  EpenthesisAndStrongSonorants START (Proc): In=", phon_word_in_stage5) end
                phon_word_in_stage5 = process_phonetic_units_procedurally(phon_word_in_stage5,
                    "EpenthesisAndStrongSonorants_EpenthesisPart", process_epenthesis_on_units,
                    { original_ortho_for_context = o_context_str_stage5, current_ortho_map = current_ortho_map_stage5 })
                debug_print_minimal("EpenthesisAndStrongSonorants", "After procedural epenthesis: ", phon_word_in_stage5)
                phon_word_in_stage5 = apply_rules_to_string_generic(phon_word_in_stage5,
                    irishPhonetics.rules_stage5_strong_sonorants_only, "EpenthesisAndStrongSonorants",
                    "single_pass_priority_match", true, o_context_str_stage5, current_ortho_map_stage5)
                debug_print_minimal("EpenthesisAndStrongSonorants", "After strong sonorant rules: ", phon_word_in_stage5)
                if STAGE_DEBUG_ENABLED["EpenthesisAndStrongSonorants"] then debug_print_minimal(
                    "  EpenthesisAndStrongSonorants END (Proc): Out=", phon_word_in_stage5) end
                return phon_word_in_stage5
            end
        },
        { name = "Diacritics",   rules = irishPhonetics.rules_stage6_diacritics,    mode = "iterative_gsub" },
        { name = "FinalCleanup", rules = irishPhonetics.rules_stage7_final_cleanup, mode = "iterative_gsub" },
    }

    if STAGE_DEBUG_ENABLED["PreProcess"] then debug_print_minimal(string.format("Af. %s (before loop): [%s]", "PreProcess", current_word_phonetic)) end

    for i, stage_data in ipairs(stages) do
        if stage_data.name ~= "PreProcess" then -- Skip PreProcess as it's done
            local stage_start_time = os.clock()
            local stage_name = stage_data.name
            local string_before_stage = current_word_phonetic

            if STAGE_DEBUG_ENABLED[stage_name] and not stage_data.is_procedural_stage then debug_print_minimal("  " .. stage_name .. " START: In=", current_word_phonetic) end

            if stage_data.is_procedural_stage and type(stage_data.func) == "function" then
                current_word_phonetic = stage_data.func(current_word_phonetic, original_ortho_for_context, ortho_map)
            elseif stage_data.updates_map_from_original_with_priority then
                 -- This block should ideally not be used if the pipeline is strictly linear after the initial tokenization.
                 -- The first tokenization (MarkDigraphs...) should build the map.
                 -- Subsequent tokenization stages (like Stage2_5_MarkSuffixes if it were also map-based) would need careful map merging.
                 -- For now, Stage2_5 is single_pass_priority_match on the output of Stage2.
                local temp_phonetic_string_build, temp_new_map, original_cursor, current_phonetic_len_accumulator = {}, {}, 1, 0
                while original_cursor <= ulen(original_ortho_for_context) do
                    local matched_this_pass_at_cursor = false
                    for rule_idx, rule in ipairs(stage_data.rules) do
                        local s_match_ortho, e_match_ortho, cap1, cap2, cap3, cap4 = ufind(original_ortho_for_context, rule.p, original_cursor)
                        if s_match_ortho and s_match_ortho == original_cursor then
                            local current_ortho_match_len = rule.ortho_len_func and rule.ortho_len_func(usub(original_ortho_for_context, s_match_ortho, e_match_ortho), cap1, cap2, cap3, cap4) or rule.ortho_len or (e_match_ortho - s_match_ortho + 1)
                            if rule.ortho_len and current_ortho_match_len > (e_match_ortho - s_match_ortho + 1) then goto continue_map_update_rule_loop_compacted_37h_iter45 end
                            local full_match_ortho_segment_for_r = usub(original_ortho_for_context, s_match_ortho, s_match_ortho + current_ortho_match_len - 1)
                            local r_text = type(rule.r) == "string" and rule.r or type(rule.r) == "function" and rule.r(full_match_ortho_segment_for_r, cap1, cap2, cap3, cap4) or ""
                            table.insert(temp_phonetic_string_build, r_text)
                            table.insert(temp_new_map, { phon_s = current_phonetic_len_accumulator + 1, phon_e = current_phonetic_len_accumulator + ulen(r_text), ortho_s = original_cursor, ortho_e = original_cursor + current_ortho_match_len - 1 })
                            current_phonetic_len_accumulator = current_phonetic_len_accumulator + ulen(r_text)
                            original_cursor = original_cursor + current_ortho_match_len
                            matched_this_pass_at_cursor = true; goto restart_map_update_rule_scan_compacted_37h_iter45
                        end; ::continue_map_update_rule_loop_compacted_37h_iter45::
                    end; ::restart_map_update_rule_scan_compacted_37h_iter45::
                    if not matched_this_pass_at_cursor then if original_cursor <= ulen(original_ortho_for_context) then
                            local char = usub(original_ortho_for_context, original_cursor, original_cursor); table.insert(temp_phonetic_string_build, char); table.insert(temp_new_map, { phon_s = current_phonetic_len_accumulator + 1, phon_e = current_phonetic_len_accumulator + 1, ortho_s = original_cursor, ortho_e = original_cursor }); current_phonetic_len_accumulator = current_phonetic_len_accumulator + 1; original_cursor = original_cursor + 1
                        else break end end
                end
                current_word_phonetic = table.concat(temp_phonetic_string_build); ortho_map = temp_new_map
            elseif stage_data.rules then
                current_word_phonetic = apply_rules_to_string_generic(current_word_phonetic, stage_data.rules, stage_name, stage_data.mode or "single_pass_priority_match", stage_data.use_original_context_for_rules, original_ortho_for_context, ortho_map, current_word_phonetic)
            end

            local stage_end_time = os.clock()
            if STAGE_DEBUG_ENABLED[stage_name] then
                if not stage_data.is_procedural_stage then debug_print_minimal("  " .. stage_name .. " END: Out=", current_word_phonetic) end
                if STAGE_DEBUG_ENABLED.Performance then debug_print_minimal(string.format("PERF: Stage %s took %.6f seconds for input: %s", stage_name, stage_end_time - stage_start_time, orthographic_word_input)) end
            end
            if string_before_stage ~= current_word_phonetic then
                if STAGE_DEBUG_ENABLED[stage_name] then debug_print_minimal(string.format("Af. %s: [%s]", stage_name, current_word_phonetic)) end
            end
        end
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
                table.insert(words,
                    irishPhonetics.transcribe_single_word(usub(orthographic_phrase, current_pos, next_space_s - 1)))
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

local RUN_TESTS = not MINIMAL_DEBUG_ENABLED
local CSV_FILE_NAME = "wiki_sample_for_llm.csv"

if RUN_TESTS then
    local words_to_test_focused = {
        "Eabhrac", "Fhionlainn", "éabhlóideach", "ar chuma", "chonaic", "creidfead", "gníomhaíocht", "goilliúnach",
        "shleamhnaigh", "ospidéal", "amharc", "dóibh", "Stiofáin", "Bhríd", "ceann", "dúnigh", "oíche", "aduaidh",
        "bhuíochas", "Aoine", "Gaeil", "Cháit", "cnoic", "snasán" }
    original_print_func("\n--- Running Focused Test Set for Connacht (Iteration 43 - CSV Targets) ---")
    if debug_file then debug_file:write("\n--- Running Focused Test Set for Connacht (Iteration 43 - CSV Targets) ---\n") end

    STAGE_DEBUG_ENABLED.Parser = false; STAGE_DEBUG_ENABLED.ParserSetup = false

    for _, word_or_phrase in ipairs(words_to_test_focused) do
        local original = word_or_phrase
        original_print_func("\n--- Transcribing:", original, "---")
        if debug_file then debug_file:write(string.format("\n--- Transcribing: %s ---\n", original)) end
        local transcribed = irishPhonetics.transcribe(original)
        original_print_func(string.format("%-30s -> [%s]", original, transcribed))
        if debug_file then debug_file:write(string.format("%-30s -> [%s]\n", original, transcribed)) end
    end
else
    local input = arg[1] or io.read()
    if input then
        print(irishPhonetics.transcribe(toNFC(input)))
    else
        -- Fallback for testing if no command line arg is given
        original_print_func("No command line argument provided. Running default test phrase.")
        local test_phrase = "seo é an tástáil dheireanach"
        original_print_func("\n--- Transcribing Default Test Phrase:", test_phrase, "---")
        if debug_file then debug_file:write(string.format("\n--- Transcribing Default Test Phrase: %s ---\n", test_phrase)) end
        local transcribed = irishPhonetics.transcribe(test_phrase)
        original_print_func(string.format("%-30s -> [%s]", test_phrase, transcribed))
        if debug_file then debug_file:write(string.format("%-30s -> [%s]\n", test_phrase, transcribed)) end
    end
end


return irishPhonetics
