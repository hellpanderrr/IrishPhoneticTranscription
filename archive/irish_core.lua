-- irish_core.lua
-- Core infrastructure, utilities, phonetic data, and helper functions.

local irish_core = {}

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

function irish_core.memoize(f) 
    return f
end
local memoize = irish_core.memoize

local ustring_module_path = "ustring.ustring"
local status, ustring_lib = pcall(require, ustring_module_path)

if not status then
    local early_print = original_print_func
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

-- Export ustring functions
irish_core.ulower = ulower
irish_core.usub = usub
irish_core.ulen = ulen
irish_core.ufind = ufind
irish_core.umatch = umatch
irish_core.ugsub = ugsub
irish_core.ugmatch = ugmatch
irish_core.N = N
irish_core.original_print_func = original_print_func

-- Global debug control (to be populated/modified by engine/main)
irish_core.MINIMAL_DEBUG_ENABLED = false
irish_core.STAGE_DEBUG_ENABLED = {}
irish_core.debug_file = nil

function irish_core.debug_print_minimal(stage_name, ...)
    if irish_core.MINIMAL_DEBUG_ENABLED and irish_core.STAGE_DEBUG_ENABLED[stage_name] then
        local msg = table.concat({ ... }, "\t")
        original_print_func("    MIN_DBG (" .. stage_name:sub(1, 10) .. "): " .. msg)
        if irish_core.debug_file then
            irish_core.debug_file:write("    MIN_DBG (" .. stage_name:sub(1, 10) .. "): " .. msg .. "\n")
            irish_core.debug_file:flush()
        end
    end
end
local debug_print_minimal = irish_core.debug_print_minimal

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

local ALL_PHONETIC_CONSONANTS_INTERMEDIATE_PRIORITY = {
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
local ALL_PHONETIC_NUCLEI_PRIORITY = {
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
    [N("gníomhaíocht")] = N("ˈɡrˠiːwiəxt̪ˠ"),
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
    [N("Árann")] = N("ˈɑːrˠən̪ˠ"),
    [N("'un")] = N("ən̪ˠ"),
    [N("un")] = N("ən̪ˠ"), -- Add unstressed version
    [N("'ur")] = N("əɾˠ"),
    [N("ur")] = N("əɾˠ"), -- Add unstressed version
    [N("adhmad")] = N("ˈəimˠəd̪ˠ"),
    [N("seachain")] = N("ˈʃaxənʲ")
}

local UNSTRESSED_WORDS_AND_SUFFIXES={["'un"]=true,["un"]=true,["'ur"]=true,["ur"]=true,["-as"]=true,["-sa"]=true,["-se"]=true,["-ne"]=true,["-na"]=true,["-im"]=true,["-fas"]=true,["-fá"]=true,["-fí"]=true,["-tá"]=true,["-ím"]=true,["bhur"]=true,["-óidh"]=true,["-ithe"]=true,["-aimid"]=true,["-aíonn"]=true,["-idís"]=true,["-aigh"]=true,["-igh"]=true,["-ach"]=true,["-san"]=true,["-sean"]=true,["-eog"]=true,["-ín"]=true,["-óg"]=true,["-ál"]=true,["-úil"]=true,["-tacht"]=true,["-acht"]=true,["-áil"]=true,["-eáil"]=true,["-ail"]=true,["-eal"]=true,["-úil"]=true,["-tacht"]=true,["-acht"]=true,["-ógra"]=true,["-úint"]=true,["-aint"]=true,["-úint"]=true,["a"]=true,["a'"]=true,["a-"]=true,["ab"]=true,["ach"]=true,["ad"]=true,["ag"]=true,["an"]=true,["ar"]=true,["as"]=true,["ba"]=true,["bh"]=true,["bhf"]=true,["ch"]=true,["de"]=true,["do"]=true,["dh"]=true,["dh'"]=true,["go"]=true,["gh"]=true,["i"]=true,["is"]=true,["le"]=true,["mar"]=true,["mh"]=true,["ní"]=true,["níl"]=true,["os"]=true,["ó"]=true,["ph"]=true,["sa"]=true,["se"]=true,["sh"]=true,["th"]=true,["th'"]=true,["um"]=true}

-- Exports constants
irish_core.SLENDER_VOWELS_ORTHO_CHARS_STR = SLENDER_VOWELS_ORTHO_CHARS_STR
irish_core.BROAD_VOWELS_ORTHO_CHARS_STR = BROAD_VOWELS_ORTHO_CHARS_STR
irish_core.ALL_VOWELS_ORTHO_CHARS_STR = ALL_VOWELS_ORTHO_CHARS_STR
irish_core.SLENDER_VOWELS_ORTHO_PATTERN = SLENDER_VOWELS_ORTHO_PATTERN
irish_core.BROAD_VOWELS_ORTHO_PATTERN = BROAD_VOWELS_ORTHO_PATTERN
irish_core.ALL_VOWELS_ORTHO_PATTERN = ALL_VOWELS_ORTHO_PATTERN
irish_core.SHORT_VOWELS_ORTHO_SINGLE_STR = SHORT_VOWELS_ORTHO_SINGLE_STR
irish_core.CONSONANTS_ORTHO_CHARS_STR = CONSONANTS_ORTHO_CHARS_STR
irish_core.ANY_CONSONANT_PHONETIC_RAW_CHARS_STR = ANY_CONSONANT_PHONETIC_RAW_CHARS_STR
irish_core.CONSONANT_CLASS_NO_CAPTURE = CONSONANT_CLASS_NO_CAPTURE
irish_core.ANY_CONSONANT_PHONETIC_PATTERN = ANY_CONSONANT_PHONETIC_PATTERN
irish_core.FINAL_CONSONANT_CAPTURE_STRICT = FINAL_CONSONANT_CAPTURE_STRICT
irish_core.BROAD_CONSONANT_PHONETIC_CLASS_NO_CAPTURE = BROAD_CONSONANT_PHONETIC_CLASS_NO_CAPTURE
irish_core.ANY_SHORT_VOWEL_PHONETIC_CHARS_STR = ANY_SHORT_VOWEL_PHONETIC_CHARS_STR
irish_core.ANY_LONG_VOWEL_PHONETIC_CHARS_STR = ANY_LONG_VOWEL_PHONETIC_CHARS_STR
irish_core.ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR = ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR
irish_core.SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR = SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR
irish_core.DIPHTHONG_LITERALS_FOR_PRIORITY = DIPHTHONG_LITERALS_FOR_PRIORITY
irish_core.PHONETIC_VOWEL_NUCLEUS_PATTERN_PARTS = PHONETIC_VOWEL_NUCLEUS_PATTERN_PARTS
irish_core.SHORT_VOWEL_CAPTURE_FOR_EPENTHESIS = SHORT_VOWEL_CAPTURE_FOR_EPENTHESIS
irish_core.CPART_CAPTURE_STRICT = CPART_CAPTURE_STRICT
irish_core.VOWEL_A_CLASS_CAPTURE_STRICT = VOWEL_A_CLASS_CAPTURE_STRICT
irish_core.VOWEL_E_I_CLASS_CAPTURE_STRICT = VOWEL_E_I_CLASS_CAPTURE_STRICT
irish_core.VOWEL_O_U_CLASS_CAPTURE_STRICT = VOWEL_O_U_CLASS_CAPTURE_STRICT
irish_core.DIPHTHONG_AI_CAPTURE_STRICT = DIPHTHONG_AI_CAPTURE_STRICT

irish_core.ZZZ_N_STR_BRD_PHON = ZZZ_N_STR_BRD_PHON
irish_core.ZZZ_L_STR_BRD_PHON = ZZZ_L_STR_BRD_PHON
irish_core.ZZZ_N_SNG_BRD_PHON = ZZZ_N_SNG_BRD_PHON
irish_core.ZZZ_L_SNG_BRD_PHON = ZZZ_L_SNG_BRD_PHON
irish_core.ZZZ_N_STR_PAL_PHON = ZZZ_N_STR_PAL_PHON
irish_core.ZZZ_L_STR_PAL_PHON = ZZZ_L_STR_PAL_PHON

irish_core.BROAD_LNM_MARKERS_FOR_STAGE5 = BROAD_LNM_MARKERS_FOR_STAGE5
irish_core.PALATAL_LNM_MARKERS_FOR_STAGE5 = PALATAL_LNM_MARKERS_FOR_STAGE5
irish_core.BROAD_R_MARKERS_FOR_STAGE5 = BROAD_R_MARKERS_FOR_STAGE5
irish_core.PALATAL_R_MARKERS_FOR_STAGE5 = PALATAL_R_MARKERS_FOR_STAGE5

irish_core.ALL_PHONETIC_CONSONANTS_INTERMEDIATE_PRIORITY = ALL_PHONETIC_CONSONANTS_INTERMEDIATE_PRIORITY
irish_core.ALL_PHONETIC_NUCLEI_PRIORITY = ALL_PHONETIC_NUCLEI_PRIORITY
irish_core.COMBINED_PHONETIC_UNITS_PRIORITY = COMBINED_PHONETIC_UNITS_PRIORITY
irish_core.PHONETIC_TRIE = PHONETIC_TRIE

irish_core.lexical_exceptions_connacht = lexical_exceptions_connacht
irish_core.UNSTRESSED_WORDS_AND_SUFFIXES = UNSTRESSED_WORDS_AND_SUFFIXES

irish_core.UNSTRESSED_PREFIXES_ORTHO = {
    "an%-", "droch%-", "mí%-", "do%-", "ró%-", "dea%-", "fíor%-", "sean%-",
    "ath%-", "comh%-", "fo%-", "frith%-", "idir%-", "in%-", "réamh%-", "so%-",
    "tras%-", "mór%-", "ban%-", "cam%-", "fionn%-", "leas%-"
}

local function get_original_indices_from_map(phon_s_target, phon_e_target, current_map)
    if not current_map or #current_map == 0 or phon_s_target <= 0 then
        return phon_s_target, (phon_e_target - phon_s_target + 1)
    end

    if phon_s_target == 1 and phon_e_target == 1 and current_map[1] and current_map[1].marker and current_map[1].name == "stress" then
        return 0, 0
    end

    local relevant_map_entries = {}
    for _, entry in ipairs(current_map) do
        if not entry.marker and
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
            if #current_map == 1 and current_map[1].name and current_map[1].name:match("_rebuild_fullspan$") then
                local map_entry = current_map[1]
                local p_len_total = map_entry.phon_e - map_entry.phon_s + 1
                local o_len_total = map_entry.ortho_e - map_entry.ortho_s + 1
                if p_len_total > 0 and o_len_total > 0 then
                    local rel_phon_s = phon_s_target - map_entry.phon_s
                    local rel_phon_e = phon_e_target - map_entry.phon_s
                    local o_s = map_entry.ortho_s + math.floor(rel_phon_s * (o_len_total / p_len_total))
                    local o_e = map_entry.ortho_s + math.floor(rel_phon_e * (o_len_total / p_len_total))
                    if o_s > o_e then o_e = o_s end
                    return o_s, (o_e - o_s + 1)
                end
            end
            return phon_s_target, (phon_e_target - phon_s_target + 1)
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
irish_core.get_original_indices_from_map = get_original_indices_from_map

local get_ortho_vowel_quality_implication_from_char_or_group_impl
get_ortho_vowel_quality_implication_from_char_or_group_impl = function(
    v_char_or_group, is_for_preceding_consonant_context, following_cons_cluster)
    if not v_char_or_group or ulen(v_char_or_group) == 0 then return nil end

    if is_for_preceding_consonant_context then
        if v_char_or_group == "iú" or v_char_or_group == "iúr" then
            return "broad"
        end    
        if v_char_or_group == "eo" or v_char_or_group == "ia" or v_char_or_group == "ei" or v_char_or_group == "eu" then
            return "slender"
        end
        if v_char_or_group == "ao" or v_char_or_group == "ua" or v_char_or_group == "ai" or v_char_or_group == "oi" or v_char_or_group == "ui" then
            return "broad"
        end
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
        local char_to_check = usub(v_char_or_group, 1, 1)
        if umatch(char_to_check, SLENDER_VOWELS_ORTHO_PATTERN) then
            return "slender"
        elseif umatch(char_to_check, BROAD_VOWELS_ORTHO_PATTERN) then
            return "broad"
        end
    else
        local char_to_check = usub(v_char_or_group, ulen(v_char_or_group), ulen(v_char_or_group))
        if umatch(char_to_check, SLENDER_VOWELS_ORTHO_PATTERN) then
            return "slender"
        elseif umatch(char_to_check, BROAD_VOWELS_ORTHO_PATTERN) then
            return "broad"
        end
    end
    return nil
end

local get_ortho_vowel_quality_implication_from_char_or_group = memoize(
    get_ortho_vowel_quality_implication_from_char_or_group_impl)
irish_core.get_ortho_vowel_quality_implication_from_char_or_group = get_ortho_vowel_quality_implication_from_char_or_group

local determine_consonant_quality_ortho_impl
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
local determine_consonant_quality_ortho = memoize(
    determine_consonant_quality_ortho_impl)
irish_core.determine_consonant_quality_ortho = determine_consonant_quality_ortho

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

            local unit_start_idx = i;

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
local parse_phonetic_string_to_units_for_epenthesis = memoize(
    parse_phonetic_string_to_units_for_epenthesis_impl)
irish_core.parse_phonetic_string_to_units_for_epenthesis = parse_phonetic_string_to_units_for_epenthesis

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
        if irish_core.MINIMAL_DEBUG_ENABLED and
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
local is_likely_monosyllable_phonetic_revised = memoize(
    is_likely_monosyllable_phonetic_revised_impl)
irish_core.is_likely_monosyllable_phonetic_revised = is_likely_monosyllable_phonetic_revised

local resolve_lenited_consonant_impl
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
        return base_phoneme_nonpalatal
    end

    local quality_derived = determine_consonant_quality_ortho(o_context_str, original_match_info_tbl.ortho_s,
        original_match_info_tbl.ortho_e)

    debug_print_minimal("ConsonantResolution", string.format(
        "DEBUG RLC for %s in %s (ortho %s): determined quality -> %s",
        full_match_marker, o_context_str,
        usub(o_context_str, original_match_info_tbl.ortho_s, original_match_info_tbl.ortho_e),
        quality_derived))

    if options.can_be_w then
        if quality_derived == "slender" then
            return N("v'")
        else
            return N("w")
        end
    end

    if quality_derived == 'slender' then
        return base_phoneme_palatal
    else
        return base_phoneme_nonpalatal
    end
end
local resolve_lenited_consonant = memoize(resolve_lenited_consonant_impl)
irish_core.resolve_lenited_consonant = resolve_lenited_consonant

-- Check if a word is monosyllabic (single syllable)
local function is_monosyllabic_impl(ortho_word)
    if not ortho_word or ortho_word == "" then return false end
    local vowel_count = 0
    local i = 1
    while i <= ulen(ortho_word) do
        local char = usub(ortho_word, i, i)
        if umatch(char, "[" .. ALL_VOWELS_ORTHO_CHARS_STR .. "]") then
            vowel_count = vowel_count + 1
            while i + 1 <= ulen(ortho_word) do
                local next_char = usub(ortho_word, i + 1, i + 1)
                if umatch(next_char, "[" .. ALL_VOWELS_ORTHO_CHARS_STR .. "áéíóú]") then
                    i = i + 1
                else
                    break
                end
            end
        end
        i = i + 1
    end
    return vowel_count == 1
end
irish_core.is_monosyllabic = function(ortho_word)
    return is_monosyllabic_impl(ortho_word)
end

return irish_core
