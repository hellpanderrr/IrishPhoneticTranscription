local U = require("irish_utils")
local N = U.N
local ulen = U.ulen
local usub = U.usub
local ugsub = U.ugsub

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
COMBINED_PHONETIC_UNITS_PRIORITY = {}
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
            if not current_node[char] then current_node[char] = {} end
            current_node = current_node[char]
        end
        current_node.is_unit_end = true
        current_node.phon = phon
        current_node.type = type
    end
    return root
end
local PHONETIC_TRIE = build_phonetic_trie()

return {
    SLENDER_VOWELS_ORTHO_CHARS_STR = SLENDER_VOWELS_ORTHO_CHARS_STR,
    BROAD_VOWELS_ORTHO_CHARS_STR = BROAD_VOWELS_ORTHO_CHARS_STR,
    ALL_VOWELS_ORTHO_CHARS_STR = ALL_VOWELS_ORTHO_CHARS_STR,
    SLENDER_VOWELS_ORTHO_PATTERN = SLENDER_VOWELS_ORTHO_PATTERN,
    BROAD_VOWELS_ORTHO_PATTERN = BROAD_VOWELS_ORTHO_PATTERN,
    ALL_VOWELS_ORTHO_PATTERN = ALL_VOWELS_ORTHO_PATTERN,
    SHORT_VOWELS_ORTHO_SINGLE_STR = SHORT_VOWELS_ORTHO_SINGLE_STR,
    CONSONANTS_ORTHO_CHARS_STR = CONSONANTS_ORTHO_CHARS_STR,
    ANY_CONSONANT_PHONETIC_RAW_CHARS_STR = ANY_CONSONANT_PHONETIC_RAW_CHARS_STR,
    CONSONANT_CLASS_NO_CAPTURE = CONSONANT_CLASS_NO_CAPTURE,
    ANY_CONSONANT_PHONETIC_PATTERN = ANY_CONSONANT_PHONETIC_PATTERN,
    FINAL_CONSONANT_CAPTURE_STRICT = FINAL_CONSONANT_CAPTURE_STRICT,
    BROAD_CONSONANT_PHONETIC_CLASS_NO_CAPTURE = BROAD_CONSONANT_PHONETIC_CLASS_NO_CAPTURE,
    ANY_SHORT_VOWEL_PHONETIC_CHARS_STR = ANY_SHORT_VOWEL_PHONETIC_CHARS_STR,
    ANY_LONG_VOWEL_PHONETIC_CHARS_STR = ANY_LONG_VOWEL_PHONETIC_CHARS_STR,
    ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR = ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR,
    SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR = SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR,
    DIPHTHONG_LITERALS_FOR_PRIORITY = DIPHTHONG_LITERALS_FOR_PRIORITY,
    PHONETIC_VOWEL_NUCLEUS_PATTERN_PARTS = PHONETIC_VOWEL_NUCLEUS_PATTERN_PARTS,
    SHORT_VOWEL_CAPTURE_FOR_EPENTHESIS = SHORT_VOWEL_CAPTURE_FOR_EPENTHESIS,
    CPART_CAPTURE_STRICT = CPART_CAPTURE_STRICT,
    VOWEL_A_CLASS_CAPTURE_STRICT = VOWEL_A_CLASS_CAPTURE_STRICT,
    VOWEL_E_I_CLASS_CAPTURE_STRICT = VOWEL_E_I_CLASS_CAPTURE_STRICT,
    VOWEL_O_U_CLASS_CAPTURE_STRICT = VOWEL_O_U_CLASS_CAPTURE_STRICT,
    DIPHTHONG_AI_CAPTURE_STRICT = DIPHTHONG_AI_CAPTURE_STRICT,
    ZZZ_N_STR_BRD_PHON = ZZZ_N_STR_BRD_PHON,
    ZZZ_L_STR_BRD_PHON = ZZZ_L_STR_BRD_PHON,
    ZZZ_N_SNG_BRD_PHON = ZZZ_N_SNG_BRD_PHON,
    ZZZ_L_SNG_BRD_PHON = ZZZ_L_SNG_BRD_PHON,
    ZZZ_N_STR_PAL_PHON = ZZZ_N_STR_PAL_PHON,
    ZZZ_L_STR_PAL_PHON = ZZZ_L_STR_PAL_PHON,
    BROAD_LNM_MARKERS_FOR_STAGE5 = BROAD_LNM_MARKERS_FOR_STAGE5,
    PALATAL_LNM_MARKERS_FOR_STAGE5 = PALATAL_LNM_MARKERS_FOR_STAGE5,
    BROAD_R_MARKERS_FOR_STAGE5 = BROAD_R_MARKERS_FOR_STAGE5,
    PALATAL_R_MARKERS_FOR_STAGE5 = PALATAL_R_MARKERS_FOR_STAGE5,
    ALL_PHONETIC_CONSONANTS_INTERMEDIATE_PRIORITY = ALL_PHONETIC_CONSONANTS_INTERMEDIATE_PRIORITY,
    ALL_PHONETIC_NUCLEI_PRIORITY = ALL_PHONETIC_NUCLEI_PRIORITY,
    COMBINED_PHONETIC_UNITS_PRIORITY = COMBINED_PHONETIC_UNITS_PRIORITY,
    PHONETIC_TRIE = PHONETIC_TRIE,
    lexical_exceptions_connacht = lexical_exceptions_connacht,
    UNSTRESSED_WORDS_AND_SUFFIXES = UNSTRESSED_WORDS_AND_SUFFIXES,
    UNSTRESSED_PREFIXES_ORTHO = UNSTRESSED_PREFIXES_ORTHO,
    DEFAULT_STRESS_RULES = DEFAULT_STRESS_RULES,
    STRESS_EXCEPTIONS_ORTHO = STRESS_EXCEPTIONS_ORTHO,
    EPENTHESIS_TARGET_CLUSTERS_BROAD = EPENTHESIS_TARGET_CLUSTERS_BROAD,
    EPENTHESIS_TARGET_CLUSTERS_SLENDER = EPENTHESIS_TARGET_CLUSTERS_SLENDER,
}
