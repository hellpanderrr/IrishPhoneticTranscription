-- Shared data and utilities for all passes.

local ustring = require("ustring.ustring")
local N = ustring.toNFC
local ulen = ustring.len
local usub = ustring.sub
local umatch = ustring.match
local ugsub = ustring.gsub

local _shared = {}

-- Character classes
_shared.SLENDER_VOWELS_ORTHO = "eéií"
_shared.BROAD_VOWELS_ORTHO = "aáoóuú"
_shared.ALL_VOWELS_ORTHO = _shared.SLENDER_VOWELS_ORTHO .. _shared.BROAD_VOWELS_ORTHO
_shared.SHORT_VOWELS_ORTHO = "aeiou"
_shared.CONSONANTS_ORTHO = "bcdfghlmnprst"
_shared.STRESS_MARK = "ˈ"
_shared.SECONDARY_STRESS_MARK = "ˌ"
_shared.SILENT_MUTATED_FINALS = { th = true, dh = true, gh = true }
_shared.INITIAL_CLUSTER_SHIFTS = {
    cn = { "c", "r" },
    gn = { "g", "r" },
    mn = { "m", "r" },
    tn = { "t", "r" },
}
_shared.VOWEL_DIGRAPHS = {
    ["ao"] = true, ["eo"] = true, ["ea"] = true, ["ae"] = true,
    ["ai"] = true, ["oi"] = true, ["ui"] = true, ["ua"] = true,
    ["ái"] = true, ["éa"] = true, ["ío"] = true, ["óí"] = true, ["aí"] = true,
    ["ei"] = true, ["éi"] = true,
}
_shared.DIALECTS = {
    connacht = {
        ao = "iː", ai = "a", ea = "a", eo = "oː", ["ío"] = "iː",
        oi = "ɔ", ui = "ʊ", ua = "uə", ia = "iə", ["éi"] = "eː",
        short = { a = "a", o = "ɔ", u = "ʊ", i = "ɪ", e = "ɛ" },
        long  = { a = "ɑː", o = "oː", u = "uː", i = "iː", e = "eː" },
        diphthong = {},
        r_lowering_trigger = true,
        anticipatory_raising = true,
        vowel_gradation = {
            a = { broad = "a", slender = "ɛ" },
            o = { broad = "ɔ", slender = "ɔ" },
            u = { broad = "ʊ", slender = "ʊ" },
            i = { broad = "ɪ", slender = "ɪ" },
            e = { broad = "ɛ", slender = "ɛ" },
        },
    },
    munster  = {
        ao = "eː", ai = "ai", ea = "a", eo = "oː", ["ío"] = "iː",
        oi = "ɔi", ui = "ʊi", ua = "uə", ia = "iə", ["éi"] = "eː",
        short = { a = "a", o = "ɔ", u = "ʊ", i = "ɪ", e = "ɛ" },
        long  = { a = "ɑː", o = "oː", u = "uː", i = "iː", e = "eː" },
        diphthong = {},
        r_lowering_trigger = true,
        anticipatory_raising = false,
        vowel_gradation = {
            a = { broad = "a", slender = "ɛ" },
            o = { broad = "ɔ", slender = "ɔ" },
            u = { broad = "ʊ", slender = "ʊ" },
            i = { broad = "ɪ", slender = "ɪ" },
            e = { broad = "ɛ", slender = "ɛ" },
        },
    },
    ulster   = {
        ao = "iː", ai = "ai", ea = "a", eo = "ɔː", ["ío"] = "iː",
        oi = "ɔi", ui = "ʊi", ua = "uə", ia = "iə", ["éi"] = "eː",
        short = { a = "a", o = "ɔ", u = "ʊ", i = "ɪ", e = "ɛ" },
        long  = { a = "ɑː", o = "oː", u = "uː", i = "iː", e = "eː" },
        diphthong = {},
        r_lowering_trigger = true,
        anticipatory_raising = false,
        vowel_gradation = {
            a = { broad = "a", slender = "ɛ" },
            o = { broad = "ɔ", slender = "ɔ" },
            u = { broad = "ʊ", slender = "ʊ" },
            i = { broad = "ɪ", slender = "ɪ" },
            e = { broad = "ɛ", slender = "ɛ" },
        },
    },
}
_shared.KNOWN_PREFIXES = {
    ["an"] = true, droch = true, ["do"] = true, dea = true,
    sean = true, ath = true, ["fo"] = true, frith = true,
    idir = true, ["in"] = true, so = true, tras = true,
    ban = true, cam = true, fionn = true, leas = true,
    comh = true,
}

function _shared.is_vowel_char(ch)
    return umatch(ch, "[" .. _shared.ALL_VOWELS_ORTHO .. "]") ~= nil
end

function _shared.is_slender_vowel_char(ch)
    return umatch(ch, "[" .. _shared.SLENDER_VOWELS_ORTHO .. "]") ~= nil
end

function _shared.is_broad_vowel_char(ch)
    return umatch(ch, "[" .. _shared.BROAD_VOWELS_ORTHO .. "]") ~= nil
end

function _shared.is_short_vowel_char(ch)
    return umatch(ch, "[" .. _shared.SHORT_VOWELS_ORTHO .. "]") ~= nil
end

function _shared.is_consonant_char(ch)
    return umatch(ch, "[" .. _shared.CONSONANTS_ORTHO .. "]") ~= nil
end

function _shared.is_short_vowel(token)
    if not token or token.type ~= "vowel" then return false end
    local ortho = token.ortho
    for i = 1, ulen(ortho) do
        if not _shared.is_short_vowel_char(usub(ortho, i, i)) then
            return false
        end
    end
    return true
end

function _shared.normalize_ortho(word)
    return ustring.lower(N(word or ""))
end

function _shared.make_token(ortho, token_type, s, e)
    return {
        ortho = ortho,
        phon = ortho,
        type = token_type,
        palatal = nil,
        broad = nil,
        slender = nil,
        is_mutated = false,
        mutation = nil,
        ortho_indices = { s, e },
        stress = false,
        source = "lexeme",
        is_voiceless = false,
        is_epenthetic = false,
    }
end

function _shared.set_polarity(token, value)
    token.palatal = value
    token.slender = value == true or nil
    token.broad = value == false or nil
end

function _shared.vowel_has_slender_trace(vowel)
    if not vowel then return false end
    return umatch(vowel.ortho, "[ií]") ~= nil
end

function _shared.vowel_polarity(vowel, direction)
    if not vowel then return nil end
    if vowel.ortho == "ai" then
        return direction == "prev" and true or false
    end
    if vowel.ortho == "ae" then
        return false
    end
    if vowel.ortho == "ea" or vowel.ortho == "éa" then
        if direction == "prev" then return false else return true end
    end
    if vowel.ortho == "eo" then
        if direction == "prev" then return false else return true end
    end
    if vowel.ortho == "ao" or
       vowel.ortho == "ua" then return false end
    -- oi/ui end in i (slender) but start with a broad vowel: like ai, they
    -- propagate slender to a FOLLOWING consonant (prev) and broad to a
    -- PRECEDING consonant (next/default).
    if vowel.ortho == "oi" or vowel.ortho == "ui" then
        return direction == "prev" and true or false
    end
    if vowel.ortho == "aoi" or vowel.ortho == "aí" or vowel.ortho == "ái" then
        if direction == "prev" then return true else return false end
    end
    if vowel.ortho == "eoi" or vowel.ortho == "ío" then return true end
    local last = usub(vowel.ortho, ulen(vowel.ortho), ulen(vowel.ortho))
    if _shared.is_slender_vowel_char(last) then return true end
    if _shared.is_broad_vowel_char(last) then return false end
    return nil
end

function _shared.palatal_consonant(token, slender, broad)
    if token.palatal == true then return slender end
    if token.palatal == false then return broad end
    return broad
end

function _shared.is_vocalizable_fricative(token)
    return token and (token.ortho == "bh" or token.ortho == "mh" or
                     token.ortho == "dh" or token.ortho == "gh")
end

function _shared.is_slender_coda_pair(tokens, i)
    local c1 = tokens[i]; local c2 = tokens[i + 1]
    return c1 and c2 and c1.type == "cons" and c2.type == "cons" and
        ((c1.ortho == "l" and c2.ortho == "t") or (c1.ortho == "r" and c2.ortho == "t"))
end

function _shared.is_sonorant(token)
    return token and token.type == "cons" and
        (token.ortho == "l" or token.ortho == "n" or token.ortho == "r" or token.ortho == "m")
end

function _shared.is_voiced_obstruent(token)
    return token and token.type == "cons" and
        (token.ortho == "b" or token.ortho == "d" or token.ortho == "g")
end

-- Hickey §2.8: Svarabhakti epenthesis occurs between a sonorant and a
-- following heterorganic obstruent or fricative — not just voiced stops.
-- This covers r+ch (urchar), r+f (dearfa), r+m (gairme), l+m (calma).
function _shared.is_heterorganic_obstruent(token)
    return token and token.type == "cons" and
        (token.ortho == "b" or token.ortho == "d" or token.ortho == "g" or
         token.ortho == "ch" or token.ortho == "f" or token.ortho == "m")
end

function _shared.clone_token(token)
    local copy = {}
    for k, v in pairs(token) do
        if type(v) == "table" then
            local nested = {}
            for nk, nv in pairs(v) do nested[nk] = nv end
            copy[k] = nested
        else
            copy[k] = v
        end
    end
    return copy
end

function _shared.clone_tokens(tokens)
    local copy = {}
    for i, token in ipairs(tokens) do copy[i] = _shared.clone_token(token) end
    return copy
end

function _shared.count_vowel_tokens(tokens)
    local count = 0
    for _, token in ipairs(tokens) do
        if token.type == "vowel" then count = count + 1 end
    end
    return count
end

-- Count syllables (not vowel tokens): adjacent vowel tokens count as 1 syllable.
-- ia, ea, ua, io → 1 syllable. ai, oi → already single token from VOWEL_DIGRAPHS.
function _shared.count_syllables(tokens)
    local count = 0
    local in_vowel_seq = false
    for _, token in ipairs(tokens) do
        if token.type == "vowel" then
            if not in_vowel_seq then
                count = count + 1
                in_vowel_seq = true
            end
        elseif token.type ~= "unknown" then
            in_vowel_seq = false
        end
    end
    return count
end

function _shared.vowel_token_index(tokens)
    for i, token in ipairs(tokens) do
        if token.type == "vowel" then return i end
    end
    return nil
end

function _shared.find_preceding_vowel(tokens, i)
    for j = i - 1, 1, -1 do
        if tokens[j].type == "vowel" then return tokens[j] end
    end
    return nil
end

function _shared.is_stressed_vowel(token)
    return token and token.type == "vowel" and token.stress
end

-- Lookup tables: eclipsis -> base consonant
_shared.ECLIPSIS_MAP = {
    mb = { phon = "mˠ" },
    gc = { phon = "ɡ" },
    dt = { phon = "d̪ˠ" },
    bp = { phon = "bˠ" },
    ng = { phon = "ŋ" },
    ngl = { phon = "ŋ" },
    nn = { phon = "n̪ˠ" },
    bpr = { phon = "bˠ" },
}

_shared.FUNCTION_WORDS_OVERRIDE = {
  i   = { "ə" },         -- preposition "in"
  a   = { "ə" },         -- possessive/particle
  ["a'"] = { "ə" },      -- variant of "a"
  ag  = { "ə", "ɡ" },    -- "at"
  ar  = { "ɛ", "ɾʲ" },   -- "on" (Connacht: palatal r, open e)
  ["do"]  = { "d̪ˠ", "ɔ" },    -- "to/for"
  mo  = { "mˠ", "ə" },    -- "my"
  de  = { "dʲ", "ə" },   -- "of/from"
  na  = { "n̪ˠ", "ə" },    -- plural article
  sa  = { "sˠ", "ə" },    -- "in the" (sing.)
  ba  = { "bˠ", "ə" },    -- conditional copula
  as  = { "a", "sˠ" },    -- "out of"
  le  = { "lʲ", "ɛ" },   -- "with" (Connacht: lʲɛ)
  mar = { "mˠ", "a", "ɾˠ" }, -- "as/like" — [a] not [ə] to match expected mˠaɾˠ in multi-word phrases
  go  = { "ɡ", "ə" },    -- "to" / "that" particle
  se  = { "ʃ", "ɛ" },    -- unstressed "he/it"
  ["o"]   = { "oː" },        -- "ó" — "from"
  ["ni"]  = { "nʲ", "iː" },  -- "ní" -- "not" / "daughter"
  is  = { "ə", "sˠ" },   -- "and" / copula
  ach = { "a", "x" },    -- "but"
  bhur = { "w", "ə", "ɾˠ" }, -- "your" (pl.)
  an  = { "ə", "nˠ" },   -- article "the" (masc. nom.)
  gan = { "ɡ", "ə", "n̪ˠ" }, -- "without"
  san = { "sˠ", "ə", "n̪ˠ" }, -- "in the" (dat.)
  am  = { "ə", "mˠ" },   -- "time"
  ad  = { "ə", "d̪ˠ" },   -- "luck/blessing"
  reo = { "ɾˠ", "oː" }, -- "frost/death" — r before eo stays broad
}

return _shared
