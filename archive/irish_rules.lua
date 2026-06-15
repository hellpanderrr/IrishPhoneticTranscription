-- irish_rules.lua
-- Contains all rule tables and lists used by the Irish G2P pipeline stages.
-- This module wraps the monolith irish.lua rules for accuracy.

local core = require("irish_core")
local N = core.N
local ulower = core.ulower
local ustring_module_path = "ustring.ustring"
local status, ustring_lib = pcall(require, ustring_module_path)
if status and ustring_lib then
    N = ustring_lib.toNFC
    ulower = ustring_lib.lower
end

local irish_rules = {}

-- Load the monolith module
local monolith_success, monolith = pcall(require, "irish")
if monolith_success and monolith then
    -- Get rules from monolith's irishPhonetics table
    local source = monolith.irishPhonetics or monolith

    -- Map monolith rule names to refactored names
    local name_map = {
        rules_stage1_preprocess = "rules_stage1_preprocess",
        rules_stage1_5_ortho_cluster_simplification = "rules_stage1_5_ortho_cluster_simplification",
        rules_stage2_mark_digraphs_and_vocalisation_triggers = "rules_stage2_mark_digraphs_and_vocalisation_triggers",
        rules_stage2_5_mark_suffixes = "rules_stage2_5_mark_suffixes",
        rules_stage3_1_marker_resolution = "rules_stage3_1_marker_resolution",
        rules_stage3_5_consonant_assimilation = "rules_stage3_5_consonant_assimilation",
        rules_stage4_0_specific_ortho_to_temp_marker = "rules_stage4_0_specific_ortho_to_temp_marker",
        rules_stage4_0_1_resolve_ch_marker = "rules_stage4_0_1_resolve_ch_marker",
        rules_stage4_1_vocmark_to_temp_marker = "rules_stage4_1_vocmark_to_temp_marker",
        rules_stage4_2_long_vowels_ortho_to_temp_marker = "rules_stage4_2_long_vowels_ortho_to_temp_marker",
        rules_stage4_3_diphthongs_ortho_to_temp_marker = "rules_stage4_3_diphthongs_ortho_to_temp_marker",
        rules_stage4_4_resolve_temp_vowel_markers = "rules_stage4_4_resolve_temp_vowel_markers",
        rules_stage4_5_contextual_allophony_on_phonetic = "rules_stage4_5_contextual_allophony_on_phonetic",
        rules_stage4_6_unstressed_vowel_reduction_specific_finals = "rules_stage4_6_unstressed_vowel_reduction_specific_finals",
        rules_stage5_strong_sonorants_only = "rules_stage5_strong_sonorants_only",
        rules_stage6_diacritics = "rules_stage6_diacritics",
        rules_stage7_final_cleanup = "rules_stage7_final_cleanup",
        placeholder_creation_rules_stage4_5 = "placeholder_creation_rules_stage4_5",
        placeholder_restoration_rules_stage4_5 = "placeholder_restoration_rules_stage4_5",
        core_allophony_rules_for_stage4_5 = "core_allophony_rules_for_stage4_5",
        connacht_au_to_schwa_u_shift_rule_stage4_5 = "connacht_au_to_schwa_u_shift_rule_stage4_5",
        temp_conn_au_to_final_au_rule_stage4_5 = "temp_conn_au_to_final_au_rule_stage4_5"
    }

    for old_name, new_name in pairs(name_map) do
        if source[old_name] then
            irish_rules[new_name] = source[old_name]
        end
    end

    -- Export additional rules from monolith that may exist
    for k, v in pairs(source) do
        if type(v) == "table" and not irish_rules[k] then
            irish_rules[k] = v
        end
    end

else
    -- Fallback: rules if monolith not available
    -- This section provides minimal stubs for standalone operation
    local N = core.N
    local usub = core.usub
local umatch = core.umatch
local get_ortho_vowel_quality_implication_from_char_or_group = core.get_ortho_vowel_quality_implication_from_char_or_group
local determine_consonant_quality_ortho = core.determine_consonant_quality_ortho
local resolve_lenited_consonant = core.resolve_lenited_consonant
local is_likely_monosyllable_phonetic_revised = core.is_likely_monosyllable_phonetic_revised

local ALL_VOWELS_ORTHO_PATTERN = core.ALL_VOWELS_ORTHO_PATTERN
local ALL_VOWELS_ORTHO_CHARS_STR = core.ALL_VOWELS_ORTHO_CHARS_STR
local ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR = core.ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR
local SHORT_VOWELS_ORTHO_SINGLE_STR = core.SHORT_VOWELS_ORTHO_SINGLE_STR
local CONSONANTS_ORTHO_CHARS_STR = core.CONSONANTS_ORTHO_CHARS_STR
local CONSONANT_CLASS_NO_CAPTURE = core.CONSONANT_CLASS_NO_CAPTURE
local SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR = core.SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR
local ANY_SHORT_VOWEL_PHONETIC_CHARS_STR = core.ANY_SHORT_VOWEL_PHONETIC_CHARS_STR
local ANY_CONSONANT_PHONETIC_PATTERN = core.ANY_CONSONANT_PHONETIC_PATTERN
local ANY_CONSONANT_PHONETIC_RAW_CHARS_STR = core.ANY_CONSONANT_PHONETIC_RAW_CHARS_STR
local BROAD_CONSONANT_PHONETIC_CLASS_NO_CAPTURE = core.BROAD_CONSONANT_PHONETIC_CLASS_NO_CAPTURE
local CPART_CAPTURE_STRICT = core.CPART_CAPTURE_STRICT
local VOWEL_A_CLASS_CAPTURE_STRICT = core.VOWEL_A_CLASS_CAPTURE_STRICT
local VOWEL_E_I_CLASS_CAPTURE_STRICT = core.VOWEL_E_I_CLASS_CAPTURE_STRICT
local VOWEL_O_U_CLASS_CAPTURE_STRICT = core.VOWEL_O_U_CLASS_CAPTURE_STRICT
local DIPHTHONG_AI_CAPTURE_STRICT = core.DIPHTHONG_AI_CAPTURE_STRICT
local ZZZ_N_STR_BRD_PHON = core.ZZZ_N_STR_BRD_PHON
local ZZZ_L_STR_BRD_PHON = core.ZZZ_L_STR_BRD_PHON
local ZZZ_N_SNG_BRD_PHON = core.ZZZ_N_SNG_BRD_PHON
local ZZZ_L_SNG_BRD_PHON = core.ZZZ_L_SNG_BRD_PHON
local ZZZ_N_STR_PAL_PHON = core.ZZZ_N_STR_PAL_PHON
local ZZZ_L_STR_PAL_PHON = core.ZZZ_L_STR_PAL_PHON
local BROAD_LNM_MARKERS_FOR_STAGE5 = core.BROAD_LNM_MARKERS_FOR_STAGE5
local PALATAL_LNM_MARKERS_FOR_STAGE5 = core.PALATAL_LNM_MARKERS_FOR_STAGE5
local BROAD_R_MARKERS_FOR_STAGE5 = core.BROAD_R_MARKERS_FOR_STAGE5
local PALATAL_R_MARKERS_FOR_STAGE5 = core.PALATAL_R_MARKERS_FOR_STAGE5

local debug_print_minimal = core.debug_print_minimal

irish_rules.rules_stage1_preprocess = {
    {
        p = N("^%s*(.-)%s*$"),
        r = function(captured_string)
            if captured_string then
                return ulower(captured_string)
            else
                return ""
            end
        end
    }, { p = N("%s+"), r = " " }, { p = N(""), r = "" }
}

irish_rules.rules_stage1_5_ortho_cluster_simplification = {
    { p = N("chn"), r = N("chr") },
    { p = N("ghn"), r = N("ghr") },
    { p = N("mhn"), r = N("mhr") },
    { p = N("cn"),  r = N("cr") },
    { p = N("gn"),  r = N("gr") },
    { p = N("mn"),  r = N("mr") },
    { p = N("tn"),  r = N("tr") },
    { p = N("dhg"), r = N("g") },
    { p = N("mhth"),r = N("r") },
    { p = N("bhth"),r = N("r") }   
}

irish_rules.rules_stage2_mark_digraphs_and_vocalisation_triggers = {
    {
        p = N("^(d'fh)"),
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
    {
        p = N("^(tsn)"),
        r = N("MKR_TSN_CLUSTER"),
        ortho_len = 3
    },
    {
        p = N("^(tsl)"),
        r = N("MKR_TSL_CLUSTER"),
        ortho_len = 3
    },
    {
        p = N("^(ts)"),
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
    { p = N("abh"), r = N("MKR_ABH_VOC"), ortho_len = 3 },
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
    { p = N("ibh"),   r = N("MKR_IBH_VOCALIZING_ENDING"), ortho_len = 3 },
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
    { p = N("eidh"),     r = N("MKR_EIDHVOC"),         ortho_len = 4 },
    { p = N("aidh"),     r = N("MKR_AIDHVOC"),         ortho_len = 4 },
    { p = N("amhr"),     r = N("MKR_AMH_R_VOC"),       ortho_len = 4 },
    { p = N("amha"),     r = N("MKR_AMHAVOC"),         ortho_len = 4 },
    { p = N("ogha"),     r = N("MKR_OGHAVOC"),         ortho_len = 4 },
    { p = N("agha"),     r = N("MKR_AGHAVOC"),         ortho_len = 4 },
    { p = N("adha"),     r = N("MKR_ADHAVOC"),         ortho_len = 4 },
    { p = N("adh(#?)$"), r = N("MKR_ADHFINSCHWA"),     ortho_len = 3 },
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
    { p = N("mm"),       r = N("MKR_MM_STR"),          ortho_len = 2 },
    {
        p = N("(ˈ" .. SHORT_VOWELS_ORTHO_SINGLE_STR .. ")l(" ..
            ALL_VOWELS_ORTHO_PATTERN .. ")"),
        r = "%1l°%2",
        ortho_len_func = function(m, c1, c2)
            return ulen(c1) + 1 + ulen(c2)
        end
    },
    {
        p = N("(ˈ" .. SHORT_VOWELS_ORTHO_SINGLE_STR .. ")n(" ..
            ALL_VOWELS_ORTHO_PATTERN .. ")"),
        r = "%1n°%2",
        ortho_len_func = function(m, c1, c2)
            return ulen(c1) + 1 + ulen(c2)
        end
    },
    { p = N("ia"), r = N("MKR_IA_DIPH"),  ortho_len = 2 },
    { p = N("ua"), r = N("MKR_UA_DIPH"),  ortho_len = 2 },
    { p = N("eo"), r = N("MKR_EO_VOWEL"), ortho_len = 2 },
    { p = N("ei"), r = N("MKR_EI_DIPH"),  ortho_len = 2 },
    { p = N("ai"), r = N("MKR_AI_DIPH"),  ortho_len = 2 },
    { p = N("oi"), r = N("MKR_OI_DIPH"),  ortho_len = 2 },
    { p = N("ui"), r = N("MKR_UI_DIPH"),  ortho_len = 2 },
    { p = N("éa"), r = N("MKR_E_ACT_A"),  ortho_len = 2 },
    { p = N("ío"), r = N("MKR_I_ACT_O"),  ortho_len = 2 },
    { p = N("o"),  r = N("MKR_O_SHT"),    ortho_len = 1 },
    { p = N("u"),  r = N("MKR_U_SHT"),    ortho_len = 1 },
}

-- Programmatically generated rules for stage2
local palatal_sonorants = { N("n̠ʲ"), N("nʲ"), N("l̠ʲ"), N("lʲ"), N("mʲ") }
local preceding_fricatives = { N("bh"), N("mh") }
local av_voc_replacement_func = function(m, a, fric, pal_son)
    return N("MKR_AV_VOC_SLENDER_") .. pal_son
end
local av_voc_ortho_len_func = function(m, a, fric, pal_son)
    return ulen(a .. fric .. pal_son)
end
for _, fric in ipairs(preceding_fricatives) do
    for _, sonorant in ipairs(palatal_sonorants) do
        local rule = {
            p = N("(a)(" .. fric .. ")(" .. sonorant .. ")"),
            r = av_voc_replacement_func,
            ortho_len_func = av_voc_ortho_len_func
        }
        table.insert(irish_rules.rules_stage2_mark_digraphs_and_vocalisation_triggers, rule)
    end
end

irish_rules.rules_stage2_5_mark_suffixes = {
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
    }, {
        p = N("(feá)(#?)$"),
        r = function(fm, sfx, b) return N("MKR_SUFFIX_FEA") .. (b or "") end,
        ortho_len_func = function(fm, sfx, b) return ulen(sfx) end
    }, {
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

irish_rules.rules_stage3_1_marker_resolution = {
    { p = N("MKR_BH_INTERVOCALIC"), r = N("w") },
    {
        p = N("MKR_CH"),
        r = function(fm, ocs, omi)
            local scan_idx = omi.ortho_e + 1
            while scan_idx <= ulen(ocs) do
                local char = usub(ocs, scan_idx, scan_idx)
                if umatch(char, "[" .. CONSONANTS_ORTHO_CHARS_STR .. "]") then
                    scan_idx = scan_idx + 1
                else
                    break
                end
            end
            local next_v_group = ""
            while scan_idx <= ulen(ocs) do
                local char = usub(ocs, scan_idx, scan_idx)
                if umatch(char, ALL_VOWELS_ORTHO_PATTERN) then
                    next_v_group = next_v_group .. char
                    scan_idx = scan_idx + 1
                else
                    break
                end
            end
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
            local quality = get_ortho_vowel_quality_implication_from_char_or_group(next_v_group, true, following_cons_cluster)
            debug_print_minimal("ConsonantResolution", string.format("Resolving <ch> in '%s'. Found vowel group: '%s'. Determined quality -> %s",
                ocs, next_v_group, tostring(quality)))
            if quality == 'slender' then
                return N("ç")
            else
                return N("x")
            end
        end
    },
    {
        p = N("MKR_PAST_DFH"),
        r = function(fm, ocs, omi)
            local quality = determine_consonant_quality_ortho(ocs, omi.ortho_e + 1, omi.ortho_e + 1)
            if quality == 'slender' then
                return N("d'")
            else
                return N("d")
            end
        end
    },
    {
        p = N("MKR_URUF"),
        r = function(fm, ocs, omi)
            local quality = determine_consonant_quality_ortho(ocs, omi.ortho_e + 1, omi.ortho_e + 1)
            if quality == 'slender' then
                return N("v'")
            else
                return N("v")
            end
        end
    },
    {
        p = N("MKR_TSN_CLUSTER"),
        r = function(fm, ocs, omi)
            return N("tr")
        end
    },
    {
        p = N("MKR_TSL_CLUSTER"),
        r = function(fm, ocs, omi)
            return N("tl")
        end
    },
    {
        p = N("MKR_TS_PREFIX"),
        r = function(fm, ocs, omi)
            local quality = determine_consonant_quality_ortho(ocs, omi.ortho_e + 1, omi.ortho_e + 1)
            if quality == 'slender' then
                return N("t'")
            else
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
    { p = N("MKR_FHINITLEN"), r = "" },
    {
        p = N("MKR_BH"),
        r = function(fm, ocs, omi)
            return resolve_lenited_consonant(N("v'"), N("w"), fm, ocs, omi, { can_be_w = true })
        end
    },
    {
        p = N("MKR_MH"),
        r = function(fm, ocs, omi)
            return resolve_lenited_consonant(N("v'"), N("w"), fm, ocs, omi, { can_be_w = true })
        end
    },
    { p = N("MKR_DH"), r = function(fm, ocs, omi) return resolve_lenited_consonant(N("j"), N("ɣ"), fm, ocs, omi) end },
    { p = N("MKR_GH"), r = function(fm, ocs, omi) return resolve_lenited_consonant(N("j"), N("ɣ"), fm, ocs, omi) end },
    { p = N("MKR_PH"), r = function(fm, ocs, omi) return resolve_lenited_consonant(N("f'"), N("f"), fm, ocs, omi) end },
    {
        -- sh is the lenited form of s; it is always pronounced /h/ in all environments.
        -- (The palatal ç only arises from lenited t/c before front vowels, never from sh.)
        p = N("MKR_SH"),
        r = N("h")
    },
    {
        -- th: word-final → silent (Ø); word-medial → h.
        -- The lenited t before front vowels gives ç only when written as th- word-initially
        -- before slender vowels (thiocfadh → ç). But mid/final th → h or Ø.
        p = N("MKR_TH"),
        r = function(fm, ocs, omi)
            if not omi or not omi.ortho_e then return N("h") end
            -- Check if this is word-final (nothing follows except word boundary)
            local scan_idx = omi.ortho_e + 1
            local remaining = ""
            while scan_idx <= ulen(ocs) do
                local char = usub(ocs, scan_idx, scan_idx)
                if umatch(char, "[#%s]") then break end
                remaining = remaining .. char
                scan_idx = scan_idx + 1
            end
            -- Word-final th (possibly followed only by # marker) → silent
            if remaining == "" or remaining == N("#") then
                return ""
            end
            -- Word-initial th + slender vowel group → ç (e.g. thiocfadh, thit)
            if omi.ortho_s == 1 then
                local next_v_group = ""
                local vi = scan_idx
                while vi <= ulen(ocs) do
                    local char = usub(ocs, vi, vi)
                    if umatch(char, ALL_VOWELS_ORTHO_PATTERN) then
                        next_v_group = next_v_group .. char
                        vi = vi + 1
                    else
                        break
                    end
                end
                local quality = get_ortho_vowel_quality_implication_from_char_or_group(next_v_group, true)
                if quality == 'slender' then return N("ç") end
            end
            -- Default: medial th → h
            return N("h")
        end
    },
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
    { p = N("l°"),         r = N("l_neutral_") },
    { p = N("n°"),         r = N("n_neutral_") },
    {
        p = N("c"),
        r = function(fm, ocs, omi)
            local quality = determine_consonant_quality_ortho(ocs, omi.ortho_s, omi.ortho_e)
            if quality == 'slender' then
                return N("k'")
            else
                return N("k")
            end
        end
    },
    -- cn- → kr- (word-initial cluster simplification)
    { p = N("cr"), r = function(fm, ocs, omi)
        local quality = determine_consonant_quality_ortho(ocs, omi.ortho_s, omi.ortho_e)
        return quality == 'slender' and N("kr'") or N("kr")
    end },
    -- gn- → gr- (word-initial cluster simplification)
    { p = N("gr"), r = function(fm, ocs, omi)
        local quality = determine_consonant_quality_ortho(ocs, omi.ortho_s, omi.ortho_e)
        return quality == 'slender' and N("gr'") or N("gr")
    end },
    -- mn- → mr- (word-initial cluster simplification)
    { p = N("mr"), r = function(fm, ocs, omi)
        local quality = determine_consonant_quality_ortho(ocs, omi.ortho_s, omi.ortho_e)
        return quality == 'slender' and N("m'") or N("m")
    end }
}

irish_rules.rules_stage3_5_consonant_assimilation = {
    { p = N("(d')(f')"), r = N("t'%2") }
}

irish_rules.rules_stage4_0_specific_ortho_to_temp_marker = {
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
    }, {
        p = N("MKR_CH"),
        r = function(fm, ocs, omi)
            local scan_idx = omi.ortho_e + 1
            while scan_idx <= ulen(ocs) do
                local char = usub(ocs, scan_idx, scan_idx)
                if umatch(char, "[" .. CONSONANTS_ORTHO_CHARS_STR .. "]") then
                    scan_idx = scan_idx + 1
                else
                    break
                end
            end
            local next_v_group = ""
            while scan_idx <= ulen(ocs) do
                local char = usub(ocs, scan_idx, scan_idx)
                if umatch(char, ALL_VOWELS_ORTHO_PATTERN) then
                    next_v_group = next_v_group .. char
                    scan_idx = scan_idx + 1
                else
                    break
                end
            end
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
            local quality = get_ortho_vowel_quality_implication_from_char_or_group(next_v_group, true, following_cons_cluster)
            debug_print_minimal("ConsonantResolution", string.format("Resolving <ch> in '%s'. Found vowel group: '%s'. Determined quality -> %s",
                ocs, next_v_group, tostring(quality)))
            if quality == 'slender' then
                return N("ç")
            else
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

irish_rules.rules_stage4_0_1_resolve_ch_marker = {
    {
        p = N("MKR_CH"),
        r = function(fm, ocs, omi_ch)
            if not omi_ch or not omi_ch.ortho_s or not omi_ch.ortho_e then
                debug_print_minimal("Stage4_0_1", "MKR_CH: Missing omi_ch, defaulting to x. ocs: " .. ocs)
                return N("x")
            end

            local scan_idx = omi_ch.ortho_e + 1
            while scan_idx <= ulen(ocs) do
                local char = usub(ocs, scan_idx, scan_idx)
                if umatch(char, "[" .. CONSONANTS_ORTHO_CHARS_STR .. "]") then
                    scan_idx = scan_idx + 1
                else
                    break
                end
            end

            local next_v_group = ""
            while scan_idx <= ulen(ocs) do
                local char = usub(ocs, scan_idx, scan_idx)
                if umatch(char, ALL_VOWELS_ORTHO_PATTERN) then
                    next_v_group = next_v_group .. char
                    scan_idx = scan_idx + 1
                else
                    break
                end
            end

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

            local quality_ch = get_ortho_vowel_quality_implication_from_char_or_group(next_v_group, true, following_cons_cluster)
            
            debug_print_minimal("Stage4_0_1_Resolve_CH_Marker",
                string.format("Resolving <ch> in '%s'. Found vowel group: '%s'. Determined quality -> %s",
                ocs, next_v_group, tostring(quality_ch)))

            local is_phonetically_initial_ch = false
            if omi_ch.ortho_s == 1 then
                is_phonetically_initial_ch = true
            elseif omi_ch.ortho_s == 2 and usub(ocs, 1, 1) == N("ˈ") then
                is_phonetically_initial_ch = true
            end

            if quality_ch == 'slender' then
                return is_phonetically_initial_ch and N("ç") or N("h")
            else
                return N("x")
            end
        end
    }
}

irish_rules.rules_stage4_1_vocmark_to_temp_marker = {}

irish_rules.rules_stage4_2_long_vowels_ortho_to_temp_marker = {
    { p = N("éa"), r = N("MKR_E_ACT_LNG"), ortho_len = 2 },
    { p = N("ío"), r = N("MKR_I_ACT_LNG"), ortho_len = 2 },
    { p = N("iú"), r = N("MKR_U_ACT_LNG"), ortho_len = 2 },
    { p = N("ae"), r = N("MKR_E_ACT_LNG"), ortho_len = 2 },
    { p = N("eo"), r = N("MKR_O_ACT_LNG"), ortho_len = 2 },
    { p = N("uí"), r = N("MKR_UI_LONG"),   ortho_len = 2 },
    { p = N("úi"), r = N("MKR_U_ACT_LNG"), ortho_len = 2 },
    { p = N("ái"), r = N("MKR_A_I_ACT_LNG_RSLV") },
    { p = N("éi"), r = N("MKR_E_ACT_I_LNG") },
    { p = N("á"),  r = N("MKR_A_ACT_LNG") },
    { p = N("é"),  r = N("MKR_E_ACT_LNG") },
    { p = N("í"),  r = N("MKR_I_ACT_LNG") },
    { p = N("ó"),  r = N("MKR_O_ACT_LNG") },
    { p = N("ú"),  r = N("MKR_U_ACT_LNG") },
    { p = N("MKR_AIACTLNG"), r = N("MKR_A_I_ACT_LNG_RSLV") }
}

irish_rules.rules_stage4_3_diphthongs_ortho_to_temp_marker = {
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

irish_rules.rules_stage4_4_resolve_temp_vowel_markers = {
    { p = N("MKR_SUFFIX_FEA"),    r = N("hɑː") },
    { p = N("MKR_SUFFIX_FAIDH"), r = N("ə") },
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
        p = N("^(MKR_AV_VOC_SLENDER_)(.+)"),
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
    { p = N("ei(MKR_MH)"), r = N("MKR_I_ACT_LNG%1") },
    { p = N("MKR_EI_DIPH"), r = N("e") },
    {
        p = N("MKR_OI_DIPH(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "*')"),
        r = N("ɛ%1")
    }, { p = N("MKR_OI_DIPH"), r = N("ɔ") },
    { p = N("uMKR_IBH_VOCALIZING_ENDING"), r = N("ɪv'") },
    { p = N("MKR_IBH_VOCALIZING_ENDING"), r = N("ɪv'") },
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
    { p = N("MKR_AMHAVOC"), r = N("əu") },
    { p = N("MKR_AMH_R_VOC"), r = N("əu") },
    { p = N("MKR_EIDHVOC"), r = N("ai") },
    { p = N("MKR_AIDHVOC"), r = N("ai") },
    { p = N("MKR_AGHAVOC"), r = N("ai") },
    { p = N("MKR_ADHAVOC"), r = N("ai") },
    { p = N("MKR_OGHAVOC"), r = N("əu") },
    { p = N("MKR_EO_VOWEL"), r = N("oː") },
    { p = N("MKR_E_ACT_A"), r = N("eː") },
    { p = N("MKR_I_ACT_O"), r = N("iː") },
    { p = N("MKR_AI_DIPH"), r = N("ai") },
    { p = N("MKR_EI_DIPH"), r = N("ai") },
    { p = N("MKR_OI_DIPH"), r = N("ai") },
    { p = N("MKR_SUFFIX_ACH"), r = N("əx") },
    { p = N("MKR_SUFFIX_AIGH"), r = N("iː") },
    { p = N("MKR_SUFFIX_ANN"), r = N("ən̪ˠ") },
    { p = N("MKR_SUFFIX_AS"), r = N("əsˠ") },
    { p = N("MKR_ADHFINSCHWA(#?)"), r = N("ə%1") }
}

irish_rules.placeholder_creation_rules_stage4_5 = {
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

irish_rules.core_allophony_rules_for_stage4_5 = {
    {
        p = N("([ɔʌ])(mˠ)"),
        r = N("uː%2")
    },
    {
        p = N("([ɔʌ])(" .. ZZZ_N_STR_BRD_PHON .. ")"),
        r = N("uː%2")
    },
    {
        p = N("(a)(mˠ)"),
        r = N("ɑː%2")
    },
    {
        p = N("(a)(" .. ZZZ_N_STR_BRD_PHON .. ")"),
        r = N("ɑː%2")
    },
    {
        p = N("(a)(ŋ)"),
        r = N("au%2")
    },
    { p = N("(a)(l't')"), r = N("ɛ%2") },
    { p = N("(a)(r'd')"), r = N("ɛ%2") },
    { p = N("(a)(l'c)"),  r = N("ɛ%2") },
    { p = N("(a)(r'c)"),  r = N("ɛ%2") },
    { p = N("^(ˈ?)vˠ([" .. ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR .. "])"), r = N("%1w%2") },
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
    { p = N("a"), r = N("a") },
    { p = N("e"), r = N("ɛ") },
    { p = N("i"), r = N("ɪ") },
    { p = N("o"), r = N("ɔ") },
    { p = N("u"), r = N("ʊ") },
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
    { p = N("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "*')(ɔ|[ʊʌ])(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "['])"), r = "%1ɪ%3" },
    { p = N("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "*')(e)(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "['])"), r = "%1ɛ%3" },
    { p = N("(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "*')(i)(" .. ANY_CONSONANT_PHONETIC_PATTERN .. "['])"), r = "%1ɪ%3" },
    { p = N("l_neutral_"), r = N("l") },
    { p = N("n_neutral_"), r = N("n") },
    { p = N("(MKR_PHON_O_LONG)(n[']?)"), r = N("uː%2") }
}

irish_rules.placeholder_restoration_rules_stage4_5 = {
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

irish_rules.connacht_au_to_schwa_u_shift_rule_stage4_5 = {
    p = N("^(ˈ?[" .. ANY_CONSONANT_PHONETIC_RAW_CHARS_STR .. "]*'?)(ɑu)([" ..
        ANY_CONSONANT_PHONETIC_RAW_CHARS_STR .. "]*'?)$"),
    r = function(full_match, pre_part, au_diph, post_part)
        if is_likely_monosyllable_phonetic_revised(full_match) then
            return (pre_part or "") .. N("əu") .. (post_part or "")
        end
        return full_match
    end
}

irish_rules.temp_conn_au_to_final_au_rule_stage4_5 = {
    p = N("MKR_TEMP_CONN_AU"),
    r = N("əu")
}

irish_rules.rules_stage4_5_2_connacht_specific_vowel_shifts = {
    { p = N("(oː)(nʲ)"), r = N("uː%2") },
    { p = N("(oː)(" .. ZZZ_N_STR_PAL_PHON .. ")"), r = N("uː%2") }
}

irish_rules.rules_stage4_5_contextual_allophony_on_phonetic = {
    { p = N("MKR_U_SHT"), r = N("ʊ%2") },
    { p = N("MKR_U_SHT"), r = N("ʌ") },
    { p = N("MKR_O_SHT"), r = N("ʌ") },
    { p = N("o"), r = N("ʌ") },
    { p = N("u"), r = N("ʌ") },
    {
        p = N("(a)(" .. CPART_CAPTURE_STRICT:gsub("%?'%)", "'%)") .. "$)"),
        r = N("ɛ%2")
    },
    {
        p = N("(ʌ)(" .. CPART_CAPTURE_STRICT:gsub("%?'%)", "'%)") .. "$)"),
        r = N("ɪ%2")
    },
    {
        p = N("(ɛ)(" .. CPART_CAPTURE_STRICT:gsub("%?'%)", "%)") .. ")$"),
        r = N("ʌ%2")
    },
    {
        p = N("(ɪ)(" .. CPART_CAPTURE_STRICT:gsub("%?'%)", "%)") .. ")$"),
        r = N("a%2")
    },
    {
        p = N("(" .. CPART_CAPTURE_STRICT:gsub("%?'%)", "'%)") .. ")(a)"),
        r = N("%1æ")
    },
    { p = N("(r'?)ɪ"), r = N("%1ɛ") },
    { p = N("ɪ(r'?)"), r = N("ɛ%1") }
}

-- Add historic u allophony to the contextual allophony
table.insert(irish_rules.rules_stage4_5_contextual_allophony_on_phonetic, 1, { p = N("(MKR_U_SHT)([kg][^'])"), r = N("ʊ%2") })
table.insert(irish_rules.rules_stage4_5_contextual_allophony_on_phonetic, 2, { p = N("(MKR_U_SHT)([vf][^'])"), r = N("ʊ%2") })

irish_rules.rules_stage4_6_unstressed_vowel_reduction_specific_finals = {
    { p = N("aí$"), r = N("iː") }, { p = N("eiə$"), r = N("iː") },
    { p = N("iːə$"), r = N("iː") }
}

irish_rules.EPENTHESIS_TARGET_CLUSTERS_BROAD = {
    [N("rg")] = true,
    [N("rb")] = true,
    [N("lg")] = true,
    [N("lb")] = true,
    [N("lv")] = true,
    [N("rm")] = true,
    [N("rn")] = true,
    [N("lm")] = true
}

irish_rules.EPENTHESIS_TARGET_CLUSTERS_SLENDER = {
    [N("rg")] = true,
    [N("rb")] = true,
    [N("lv")] = true,
    [N("rv")] = true,
    [N("rm")] = true,
    [N("rn")] = true,
    [N("lm")] = true,
    [N("nm")] = true
}

irish_rules.rules_stage5_strong_sonorants_only = {}
do
    local CPART_CAPTURE = CPART_CAPTURE_STRICT
    local FINAL_CONS_CAPTURE = core.FINAL_CONSONANT_CAPTURE_STRICT
    local vowel_effects_map_ss_connacht = {
        {
            input_v_class_str = VOWEL_A_CLASS_CAPTURE_STRICT,
            broad_lnm = N("qpqpqpqpqpqpqpqpqpqpqpqpqpqp"), -- Placeholder, will be overwritten by creation function logic
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
    -- Overwrite broad_lnm for vowel A
    vowel_effects_map_ss_connacht[1].broad_lnm = N("ɑː")

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
            return
        end

        local ps_to_generate = {
            {
                ptn = "^(ˈ?)" .. CPART_CAPTURE .. vowel_class_capture_str_arg ..
                    "(" .. specific_son_marker_literal .. ")" ..
                    FINAL_CONS_CAPTURE .. "(#?)$",
                caps = { s = true, cp = true, v = true, son = true, fc = true, b = true }
            }, {
                ptn = "^(ˈ?)" .. CPART_CAPTURE .. vowel_class_capture_str_arg ..
                    "(" .. specific_son_marker_literal .. ")" .. "(#?)$",
                caps = { s = true, cp = true, v = true, son = true, fc = false, b = true }
            }, {
                ptn = "^(ˈ?)" .. vowel_class_capture_str_arg .. "(" ..
                    specific_son_marker_literal .. ")" .. FINAL_CONS_CAPTURE ..
                    "(#?)$",
                caps = { s = true, cp = false, v = true, son = true, fc = true, b = true }
            }, {
                ptn = "^(ˈ?)" .. vowel_class_capture_str_arg .. "(" ..
                    specific_son_marker_literal .. ")" .. "(#?)$",
                caps = { s = true, cp = false, v = true, son = true, fc = false, b = true }
            }
        }
        for _, ptn_data in ipairs(ps_to_generate) do
            table.insert(rules_table, {
                p = ptn_data.ptn,
                r = function(...)
                    local all_captures = { ... };
                    local fm = all_captures[1];
                    local stress, c_part, vowel_cap, son_cap, final_cons_cap, boundary_cap;
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
                irish_rules.rules_stage5_strong_sonorants_only,
                veffect.input_v_class_str, son_mkr, son_type_key, veffect, false)
        end
        for _, son_mkr in ipairs(BROAD_R_MARKERS_FOR_STAGE5) do
            create_rules_for_specific_sonorant(
                irish_rules.rules_stage5_strong_sonorants_only,
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
                irish_rules.rules_stage5_strong_sonorants_only,
                veffect.input_v_class_str, son_mkr, son_type_key, veffect, true)
        end
        for _, son_mkr in ipairs(PALATAL_R_MARKERS_FOR_STAGE5) do
            create_rules_for_specific_sonorant(
                irish_rules.rules_stage5_strong_sonorants_only,
                veffect.input_v_class_str, son_mkr, "PalR", veffect, true)
        end
    end
end

irish_rules.rules_stage6_diacritics = {
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

irish_rules.rules_stage7_final_cleanup = {
    { p = N("([ɑeiou]ː)[ɣçh]$"), r = N("%1") },
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
    { p = N("Kɾˠ_[A-Za-z_]+"), r = N("") },  -- Remove Kɾˠ markers with suffixes like Kɾˠ_O_SHT
    { p = N("ZZZ"), r = "" }, { p = N("&"), r = "" }, { p = N("g"), r = N("ɡ") }
}
end -- close if monolith_success block

return irish_rules
