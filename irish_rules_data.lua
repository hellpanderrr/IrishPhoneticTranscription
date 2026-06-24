local C = require("irish_constants")
local U = require("irish_utils")

local N = U.N
local ulen = U.ulen
local usub = U.usub
local ufind = U.ufind
local ugsub = U.ugsub
local ulower = U.ulower

local CONSONANTS_ORTHO_CHARS_STR = C.CONSONANTS_ORTHO_CHARS_STR
local ALL_VOWELS_ORTHO_CHARS_STR = C.ALL_VOWELS_ORTHO_CHARS_STR
local ALL_VOWELS_ORTHO_PATTERN = C.ALL_VOWELS_ORTHO_PATTERN
local ANY_CONSONANT_PHONETIC_PATTERN = C.ANY_CONSONANT_PHONETIC_PATTERN
local ANY_CONSONANT_PHONETIC_RAW_CHARS_STR = C.ANY_CONSONANT_PHONETIC_RAW_CHARS_STR
local SHORT_VOWELS_ORTHO_SINGLE_STR = C.SHORT_VOWELS_ORTHO_SINGLE_STR
local ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR = C.ALL_SINGLE_PHONETIC_VOWEL_CHARS_STR
local ANY_SHORT_VOWEL_PHONETIC_CHARS_STR = C.ANY_SHORT_VOWEL_PHONETIC_CHARS_STR
local ANY_LONG_VOWEL_PHONETIC_CHARS_STR = C.ANY_LONG_VOWEL_PHONETIC_CHARS_STR
local SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR = C.SINGLE_VOWEL_WITH_OPT_LONG_CAPTURE_STR
local CPART_CAPTURE_STRICT = C.CPART_CAPTURE_STRICT
local CONSONANT_CLASS_NO_CAPTURE = C.CONSONANT_CLASS_NO_CAPTURE
local BROAD_CONSONANT_PHONETIC_CLASS_NO_CAPTURE = C.BROAD_CONSONANT_PHONETIC_CLASS_NO_CAPTURE
local ZZZ_N_STR_PAL_PHON = C.ZZZ_N_STR_PAL_PHON
local ZZZ_N_STR_BRD_PHON = C.ZZZ_N_STR_BRD_PHON
local ZZZ_L_STR_PAL_PHON = C.ZZZ_L_STR_PAL_PHON
local ZZZ_L_STR_BRD_PHON = C.ZZZ_L_STR_BRD_PHON
local ZZZ_N_SNG_BRD_PHON = C.ZZZ_N_SNG_BRD_PHON
local ZZZ_L_SNG_BRD_PHON = C.ZZZ_L_SNG_BRD_PHON

rules_stage1_preprocess = {
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
rules_stage1_5_ortho_cluster_simplification = {
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
rules_stage2_mark_digraphs_and_vocalisation_triggers = {
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
        table.insert(rules_stage2_mark_digraphs_and_vocalisation_triggers, rule)
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


rules_stage2_5_mark_suffixes = {
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

rules_stage3_1_marker_resolution = {}
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
    rules_stage3_1_marker_resolution = rules
end

rules_stage3_5_consonant_assimilation = {
    { p = N("(d')(f')"), r = N("t'%2") }
}
rules_stage4_0_specific_ortho_to_temp_marker = {
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
rules_stage4_0_1_resolve_ch_marker = {
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

local rules_stage4_1_vocmark_to_temp_marker = {}
rules_stage4_2_long_vowels_ortho_to_temp_marker = {
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
rules_stage4_3_diphthongs_ortho_to_temp_marker = {
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
rules_stage4_4_resolve_temp_vowel_markers = {
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
rules_stage4_5_2_connacht_specific_vowel_shifts = {
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

rules_stage4_6_unstressed_vowel_reduction_specific_finals = {
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

rules_stage5_strong_sonorants_only = {}
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

rules_stage6_diacritics = {

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
rules_stage7_final_cleanup = {
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
        table.insert(rules_stage2_mark_digraphs_and_vocalisation_triggers, rule)
    end
end

return {
    rules_stage1_preprocess = rules_stage1_preprocess,
    rules_stage1_5_ortho_cluster_simplification = rules_stage1_5_ortho_cluster_simplification,
    rules_stage2_mark_digraphs_and_vocalisation_triggers = rules_stage2_mark_digraphs_and_vocalisation_triggers,
    rules_stage2_5_mark_suffixes = rules_stage2_5_mark_suffixes,
    rules_stage3_1_marker_resolution = rules_stage3_1_marker_resolution,
    rules_stage3_5_consonant_assimilation = rules_stage3_5_consonant_assimilation,
    rules_stage4_0_specific_ortho_to_temp_marker = rules_stage4_0_specific_ortho_to_temp_marker,
    rules_stage4_0_1_resolve_ch_marker = rules_stage4_0_1_resolve_ch_marker,
    rules_stage4_1_vocmarkToTempMarker = rules_stage4_1_vocmarkToTempMarker,
    rules_stage4_2_long_vowels_ortho_to_temp_marker = rules_stage4_2_long_vowels_ortho_to_temp_marker,
    rules_stage4_3_diphthongs_ortho_to_temp_marker = rules_stage4_3_diphthongs_ortho_to_temp_marker,
    rules_stage4_4_resolve_temp_vowel_markers = rules_stage4_4_resolve_temp_vowel_markers,
    rules_stage4_5_2_connacht_specific_vowel_shifts = rules_stage4_5_2_connacht_specific_vowel_shifts,
    rules_stage4_6_unstressed_vowel_reduction_specific_finals = rules_stage4_6_unstressed_vowel_reduction_specific_finals,
    rules_stage5_strong_sonorants_only = rules_stage5_strong_sonorants_only,
    rules_stage6_diacritics = rules_stage6_diacritics,
    rules_stage7_final_cleanup = rules_stage7_final_cleanup,
    placeholder_creation_rules_stage4_5 = placeholder_creation_rules_stage4_5,
    core_allophony_rules_for_stage4_5 = core_allophony_rules_for_stage4_5,
    placeholder_restoration_rules_stage4_5 = placeholder_restoration_rules_stage4_5,
    connacht_au_to_schwa_u_shift_rule_stage4_5 = connacht_au_to_schwa_u_shift_rule_stage4_5,
    temp_conn_au_to_final_au_rule_stage4_5 = temp_conn_au_to_final_au_rule_stage4_5,
    placeholder_restoration_rules_final = placeholder_restoration_rules_final,
}
