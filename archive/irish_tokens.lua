local core = require("irish_core")

local N = core.N
local ulen = core.ulen
local usub = core.usub
local umatch = core.umatch
local ugsub = core.ugsub

local SLENDER_VOWELS_ORTHO = "eéií"
local BROAD_VOWELS_ORTHO = "aáoóuú"
local ALL_VOWELS_ORTHO = SLENDER_VOWELS_ORTHO .. BROAD_VOWELS_ORTHO
local SHORT_VOWELS_ORTHO = "aeiou"
local CONSONANTS_ORTHO = "bcdfghlmnprst"
local SILENT_MUTATED_FINALS = { th = true, dh = true, gh = true }
local INITIAL_CLUSTER_SHIFTS = {
    cn = { "c", "r" },
    gn = { "g", "r" },
    mn = { "m", "r" },
    tn = { "t", "r" },
}
local VOWEL_DIGRAPHS = {
    ["ao"] = true,
    ["eo"] = true,
    ["ea"] = true,
    ["ae"] = true,
    ["ai"] = true,
    ["oi"] = true,
    ["ui"] = true,
    ["ua"] = true,
    ["ái"] = true,
    ["éa"] = true,
    ["ío"] = true,
    ["óí"] = true,
    ["aí"] = true,
}
local DIALECTS = {
    connacht = {
        ao = "eː",
        ai = "ai",
        ea = "a",
        eo = "oː",
        ["ío"] = "iː",
    },
    munster = {
        ao = "eː",
        ai = "ai",
        ea = "a",
        eo = "oː",
        ["ío"] = "iː",
    },
    ulster = {
        ao = "iː",
        ai = "ai",
        ea = "a",
        eo = "oː",
        ["ío"] = "iː",
    },
}
local STRESS_MARK = "ˈ"

local irish_tokens = {}

local function is_vowel_char(ch)
    return umatch(ch, "[" .. ALL_VOWELS_ORTHO .. "]") ~= nil
end

local function is_slender_vowel_char(ch)
    return umatch(ch, "[" .. SLENDER_VOWELS_ORTHO .. "]") ~= nil
end

local function is_broad_vowel_char(ch)
    return umatch(ch, "[" .. BROAD_VOWELS_ORTHO .. "]") ~= nil
end

local function is_short_vowel_char(ch)
    return umatch(ch, "[" .. SHORT_VOWELS_ORTHO .. "]") ~= nil
end

local function is_consonant_char(ch)
    return umatch(ch, "[" .. CONSONANTS_ORTHO .. "]") ~= nil
end

local function normalize_ortho(word)
    return core.ulower(N(word or ""))
end

local function make_token(ortho, token_type, s, e)
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
    }
end

local function set_polarity(token, value)
    token.palatal = value
    token.slender = value == true or nil
    token.broad = value == false or nil
end

local function vowel_has_slender_trace(vowel)
    if not vowel then
        return false
    end
    return vowel.ortho:match("[ií]") ~= nil
end

local function vowel_polarity(vowel, direction)
    if not vowel then
        return nil
    end
    if vowel.ortho == "ai" then
        return direction == "prev" and true or false
    end
    if vowel.ortho == "ae" then
        return direction == "prev" and false or true
    end
    if vowel.ortho == "ea" or vowel.ortho == "éa" then
        return direction == "prev" and false or true
    end
    if vowel.ortho == "eo" then
        return false
    end
    if vowel.ortho == "ao" or vowel.ortho == "aoi" or
            vowel.ortho == "aí" or vowel.ortho == "ái" or
            vowel.ortho == "ua" or vowel.ortho == "oi" or
            vowel.ortho == "ui" then
        return false
    end
    if vowel.ortho == "eoi" or vowel.ortho == "ío" then
        return true
    end
    local last = usub(vowel.ortho, ulen(vowel.ortho), ulen(vowel.ortho))
    if is_slender_vowel_char(last) then
        return true
    end
    if is_broad_vowel_char(last) then
        return false
    end
    return nil
end

local function assign_final_ng_polarity(tokens)
    for i = 1, #tokens - 1 do
        local vowel = tokens[i]
        local ng = tokens[i + 1]
        if vowel.type == "vowel" and ng.type == "cons" and ng.ortho == "ng" then
            if vowel.ortho == "a" or vowel.ortho == "o" or vowel.ortho == "u" or
                    vowel.ortho == "ai" or vowel.ortho == "aí" then
                set_polarity(ng, false)
            end
        end
    end
end

local function is_orthographic_boundary(token)
    return token and (token.type == "boundary" or token.type == "unknown")
end

local function has_final_silent_mutated_fricative(tokens)
    if #tokens == 0 then
        return false
    end

    local last = tokens[#tokens]
    return last.type == "cons" and SILENT_MUTATED_FINALS[last.ortho] == true
end

local function is_final_stressed_vowel(token)
    return token and token.type == "vowel" and token.stress
end

local function tokenize_word(word)
    local tokens = {}
    local i = 1
    word = normalize_ortho(word)

    while i <= ulen(word) do
        local c1 = usub(word, i, i)
        local c2 = i < ulen(word) and usub(word, i + 1, i + 1) or ""
        local c3 = i + 2 <= ulen(word) and usub(word, i + 2, i + 2) or ""
        local tri = c1 .. c2 .. c3
        local digraph = c1 .. c2

        if c1 == " " then
            table.insert(tokens, make_token(" ", "boundary", i, i))
            i = i + 1
        elseif tri == "d'fh" then
            local token = make_token(tri, "cons", i, i + 2)
            token.is_mutated = true
            token.mutation = "eclipsis"
            table.insert(tokens, token)
            i = i + 3
        elseif digraph == "bh" or digraph == "mh" or digraph == "ch" or
               digraph == "dh" or digraph == "gh" or digraph == "ph" or
               digraph == "sh" or digraph == "th" then
            local token = make_token(digraph, "cons", i, i + 1)
            token.is_mutated = true
            token.mutation = "lenition"
            table.insert(tokens, token)
            i = i + 2
        elseif c1 == "'" then
            local token = make_token(c1, "boundary", i, i)
            token.source = "apostrophe"
            table.insert(tokens, token)
            i = i + 1
        elseif tri == "aoi" or tri == "eoi" then
            table.insert(tokens, make_token(tri, "vowel", i, i + 2))
            i = i + 3
        elseif digraph == "ng" then
            table.insert(tokens, make_token(digraph, "cons", i, i + 1))
            i = i + 2
        elseif VOWEL_DIGRAPHS[digraph] then
            table.insert(tokens, make_token(digraph, "vowel", i, i + 1))
            i = i + 2
        elseif is_vowel_char(c1) then
            table.insert(tokens, make_token(c1, "vowel", i, i))
            i = i + 1
        elseif is_consonant_char(c1) then
            table.insert(tokens, make_token(c1, "cons", i, i))
            i = i + 1
        else
            table.insert(tokens, make_token(c1, "unknown", i, i))
            i = i + 1
        end
    end

    return tokens
end

local function simplify_initial_clusters(tokens)
    if #tokens < 2 or tokens[1].type ~= "cons" or tokens[2].type ~= "cons" then
        return
    end
    local shift = INITIAL_CLUSTER_SHIFTS[tokens[1].ortho .. tokens[2].ortho]
    if not shift then
        return
    end
    tokens[1].ortho = shift[1]
    tokens[2].ortho = shift[2]
    tokens[2].source = "cluster_shift"
end

local function assign_polarity(tokens)
    simplify_initial_clusters(tokens)
    for i, token in ipairs(tokens) do
        if token.type ~= "cons" then
            goto continue
        end

        local prev_vowel
        local j = i - 1
        while j >= 1 do
            if tokens[j].type == "vowel" then
                prev_vowel = tokens[j]
                break
            end
            j = j - 1
        end

        local next_vowel
        j = i + 1
        while j <= #tokens do
            if tokens[j].type == "vowel" then
                next_vowel = tokens[j]
                break
            end
            j = j + 1
        end

        local polarity = vowel_polarity(next_vowel)
        if polarity == nil then
            polarity = vowel_polarity(prev_vowel, "prev")
        end
        local sonorants = { l = true, n = true, r = true, m = true }
        if sonorants[token.ortho] and prev_vowel and vowel_has_slender_trace(prev_vowel) then
            polarity = true
        end
        set_polarity(token, polarity)

        ::continue::
    end
end

local function palatal_consonant(token, slender, broad)
    if token.palatal == true then
        return slender
    end
    if token.palatal == false then
        return broad
    end
    return broad
end

local function is_vocalizable_fricative(token)
    return token and (token.ortho == "bh" or token.ortho == "mh" or token.ortho == "dh" or token.ortho == "gh")
end

local function apply_fricative_vocalization(tokens)
    for i = 1, #tokens - 1 do
        local vowel = tokens[i]
        local fricative = tokens[i + 1]
        if vowel.type ~= "vowel" or not is_vocalizable_fricative(fricative) then
            goto continue
        end

        local is_slender = vowel.ortho == "e" or vowel.ortho == "i" or vowel.ortho == "ea"
        local changed = false
        if vowel.ortho == "ea" and (fricative.ortho == "bh" or fricative.ortho == "mh") then
            vowel.phon = "əu"
            changed = true
        elseif (fricative.ortho == "bh" or fricative.ortho == "mh") then
            if is_slender then
                vowel.phon = "əi"
            elseif vowel.ortho == "a" or vowel.ortho == "o" or vowel.ortho == "u" then
                vowel.phon = "əu"
            end
            changed = true
        elseif fricative.ortho == "dh" or fricative.ortho == "gh" then
            if is_slender then
                vowel.phon = "əi"
            elseif vowel.ortho == "a" or vowel.ortho == "o" or vowel.ortho == "u" then
                vowel.phon = "ai"
            end
            changed = true
        end

        if changed then
            fricative.phon = ""
        end

        ::continue::
    end
end

local function apply_final_mutated_fricative_polarity(tokens)
    if #tokens == 0 then
        return
    end

    local last = tokens[#tokens]
    if last.type ~= "cons" or (last.ortho ~= "bh" and last.ortho ~= "mh") then
        return
    end

    local prev = tokens[#tokens - 1]
    if prev and prev.type == "vowel" and vowel_has_slender_trace(prev) then
        set_polarity(last, true)
    end
end

local function resolve_vowel_plus_mutated_fricative(tokens)
    for i = 1, #tokens - 1 do
        local vowel = tokens[i]
        local fricative = tokens[i + 1]
        if vowel.type ~= "vowel" or fricative.type ~= "cons" then
            goto continue
        end

        if fricative.ortho == "mh" then
            if fricative.palatal == true then
                vowel.phon = vowel.phon .. "iː"
            elseif vowel.ortho == "ái" or vowel.ortho == "á" then
                vowel.phon = vowel.phon .. "iː"
            end
            fricative.phon = ""
        elseif fricative.ortho == "bh" and fricative.palatal == false and
                (vowel.ortho == "á" or vowel.ortho == "aí" or vowel.ortho == "ai") then
            if vowel.ortho == "aí" then
                vowel.phon = "ɑːiː"
            else
                vowel.phon = vowel.phon .. "iː"
            end
            fricative.phon = ""
        end

        ::continue::
    end
end

local function remove_final_silent_mutated_fricatives(tokens)
    if #tokens == 0 then
        return
    end

    local last = tokens[#tokens]
    if last.type ~= "cons" or not SILENT_MUTATED_FINALS[last.ortho] then
        return
    end

    local prev = tokens[#tokens - 1]
    if prev and prev.type == "vowel" then
        prev.source = "vowel_before_silent_fricative"
        if last.ortho == "th" then
            prev.phon = prev.phon .. "ç"
        end
    end
    last.phon = ""
end

local function is_slender_coda_pair(tokens, i)
    local c1 = tokens[i]
    local c2 = tokens[i + 1]
    return c1 and c2 and c1.type == "cons" and c2.type == "cons" and
        ((c1.ortho == "l" and c2.ortho == "t") or (c1.ortho == "r" and c2.ortho == "t"))
end

local function apply_slender_coda_vowels(tokens)
    for i = 1, #tokens do
        local token = tokens[i]
        local next = tokens[i + 1]
        local next2 = tokens[i + 2]
        if token.type == "vowel" and is_slender_coda_pair(tokens, i + 1) and
                (token.ortho == "ai" or token.ortho == "a") then
            token.phon = "ɛ"
        elseif token.type == "vowel" and next and next.type == "cons" and next.ortho == "ng" then
            token.phon = "ɪ"
        end
    end
end

local function resolve_consonants(tokens)
    for i, token in ipairs(tokens) do
        if token.type ~= "cons" then
            goto continue
        end

        if is_slender_coda_pair(tokens, i) then
            token.phon = token.phon .. "ʲ"
        end

        if token.ortho == "bh" or token.ortho == "mh" then
            if token.palatal == true then
                token.phon = "vʲ"
            elseif token.palatal == false then
                token.phon = "w"
            else
                token.phon = "vˠ"
            end
        elseif token.ortho == "ch" then
            if token.palatal == true then
                token.phon = i == 1 and "ç" or "h"
            else
                token.phon = "x"
            end
        elseif token.ortho == "sh" then
            token.phon = "h"
        elseif token.ortho == "th" then
            if i == #tokens then
                token.phon = ""
            else
                token.phon = "h"
            end
        elseif token.ortho == "dh" or token.ortho == "gh" then
            local next = tokens[i + 1]
            if i == #tokens or next and next.type == "cons" then
                token.phon = ""
            elseif token.palatal == true then
                token.phon = "j"
            else
                token.phon = "ɣ"
            end
        elseif token.ortho == "ph" then
            if token.palatal == true then
                token.phon = "fʲ"
            else
                token.phon = "fˠ"
            end
        elseif token.ortho == "fh" then
            token.phon = ""
        elseif token.ortho == "bhf" then
            token.phon = "w"
        elseif token.ortho == "s" then
            local next = tokens[i + 1]
            if next and (next.ortho == "p" or next.ortho == "t" or next.ortho == "k") then
                token.phon = "ʃ"
            elseif token.palatal == true then
                token.phon = "ʃ"
            else
                token.phon = "sˠ"
            end
        elseif token.ortho == "c" then
            if token.palatal == true then
                token.phon = "c"
            else
                token.phon = "k"
            end
        elseif token.ortho == "g" then
            if token.palatal == true then
                token.phon = "ɟ"
            else
                token.phon = "ɡ"
            end
        elseif token.ortho == "t" then
            if token.palatal == true then
                token.phon = "tʲ"
            else
                token.phon = "t̪ˠ"
            end
        elseif token.ortho == "d" then
            if token.palatal == true then
                token.phon = "dʲ"
            else
                token.phon = "d̪ˠ"
            end
        elseif token.ortho == "n" then
            if token.palatal == true then
                token.phon = "nʲ"
            else
                token.phon = "n̪ˠ"
            end
        elseif token.ortho == "ng" then
            if token.palatal == true then
                token.phon = "ɲ"
            else
                token.phon = "ŋ"
            end
        elseif token.ortho == "l" then
            if token.palatal == true then
                token.phon = "lʲ"
            else
                token.phon = "lˠ"
            end
        elseif token.ortho == "r" then
            token.phon = palatal_consonant(token, "ɾʲ", "ɾˠ")
        elseif token.ortho == "f" then
            token.phon = palatal_consonant(token, "fʲ", "fˠ")
        elseif token.ortho == "b" then
            token.phon = palatal_consonant(token, "bʲ", "bˠ")
        elseif token.ortho == "m" then
            token.phon = palatal_consonant(token, "mʲ", "mˠ")
        elseif token.ortho == "p" then
            token.phon = palatal_consonant(token, "pʲ", "pˠ")
        end

        ::continue::
    end
end

local function count_vowel_tokens(tokens)
    local count = 0
    for _, token in ipairs(tokens) do
        if token.type == "vowel" then
            count = count + 1
        end
    end
    return count
end

local function ortho_from_tokens(tokens)
    local parts = {}
    for _, token in ipairs(tokens) do
        if token.ortho and token.ortho ~= "" then
            table.insert(parts, token.ortho)
        end
    end
    return table.concat(parts)
end

local function has_unstressed_prefix(tokens)
    local prefix_table = {
        ["an"] = true,
        ["droch"] = true,
        ["mí"] = true,
        ["do"] = true,
        ["ró"] = true,
        ["dea"] = true,
        ["fíor"] = true,
        ["sean"] = true,
        ["ath"] = true,
        ["comh"] = true,
        ["fo"] = true,
        ["frith"] = true,
        ["idir"] = true,
        ["in"] = true,
        ["réamh"] = true,
        ["so"] = true,
        ["tras"] = true,
        ["mór"] = true,
        ["ban"] = true,
        ["cam"] = true,
        ["fionn"] = true,
        ["leas"] = true,
    }

    if #tokens < 2 or tokens[1].type ~= "cons" then
        return false
    end

    local next = tokens[2]
    if next.type ~= "vowel" and next.type ~= "cons" then
        return false
    end

    return prefix_table[tokens[1].ortho .. tokens[2].ortho] == true
end

local function vowel_token_index(tokens)
    for i, token in ipairs(tokens) do
        if token.type == "vowel" then
            return i
        end
    end
end

local function render_output(tokens)
    local parts = {}
    for _, token in ipairs(tokens) do
        if token.phon and token.phon ~= "" then
            if token.type == "vowel" and token.stress then
                table.insert(parts, STRESS_MARK)
            end
            table.insert(parts, token.phon)
        end
    end
    return table.concat(parts)
end

local function apply_stress(tokens)
    if count_vowel_tokens(tokens) <= 1 then
        return
    end

    local ortho = ortho_from_tokens(tokens)
    if core.UNSTRESSED_WORDS_AND_SUFFIXES[ortho] then
        return
    end

    if has_unstressed_prefix(tokens) then
        return
    end

    local stress_index = vowel_token_index(tokens)
    if not stress_index then
        return
    end

    if tokens[stress_index].ortho == "e" and stress_index > 1 and
            tokens[stress_index - 1].type == "cons" and
            (tokens[stress_index - 1].ortho == "g" or tokens[stress_index - 1].ortho == "l") then
        stress_index = stress_index - 1
    elseif tokens[stress_index].ortho == "e" and stress_index > 1 and
            tokens[stress_index - 1].type == "vowel" and
            tokens[stress_index - 1].ortho == "a" then
        stress_index = stress_index - 1
    end

    if stress_index > 1 and tokens[stress_index - 1].type == "cons" and
            tokens[stress_index - 2] and tokens[stress_index - 2].type == "cons" and
            (tokens[stress_index - 1].ortho == "r" or tokens[stress_index - 1].ortho == "l") then
        stress_index = stress_index - 1
    end

    if tokens[stress_index].ortho == "a" and stress_index > 1 and
            tokens[stress_index - 1].type == "cons" and
            tokens[stress_index - 1].ortho == "g" then
        stress_index = stress_index - 1
    end

    tokens[stress_index].stress = true
end

local function is_stressed_vowel(token)
    return token and token.type == "vowel" and token.stress
end

local function apply_unstressed_reduction(tokens)
    for i, token in ipairs(tokens) do
        if token.type ~= "vowel" or token.stress then
            goto continue
        end

        local prev = tokens[i - 1]
        local next = tokens[i + 1]

        if token.ortho == "a" and not is_stressed_vowel(prev) and not is_stressed_vowel(next) and
                (prev and prev.type == "cons" and (prev.ortho == "bh" or prev.ortho == "mh" or prev.ortho == "dh" or prev.ortho == "gh")) then
            token.phon = "ə"
        elseif token.ortho == "e" and not is_stressed_vowel(prev) and not is_stressed_vowel(next) and
                (next and next.type == "cons" and next.ortho == "n") then
            token.phon = "ə"
        elseif token.ortho == "ai" and next and next.type == "cons" and
                (next.ortho == "dh" or next.ortho == "gh") then
            token.phon = "ə"
        end

        ::continue::
    end
end

local function resolve_vowels(tokens, dialect)
    local vowel_seen = 0
    local dialect_values = DIALECTS[dialect] or DIALECTS.connacht
    for i, token in ipairs(tokens) do
        if token.type ~= "vowel" then
            goto continue
        end
        vowel_seen = vowel_seen + 1

        local ortho = token.ortho
        local next = tokens[i + 1]
        local prev = tokens[i - 1]

        -- Only apply default mapping if not already modified by an earlier pass
        if token.phon == ortho or token.phon == nil or token.phon == "" then
            if next and next.type == "cons" and next.ortho == "dh" and
                    (ortho == "a" or ortho == "ai" or ortho == "á" or ortho == "aí") then
                if ortho == "aí" then
                    token.phon = "ɑːiː"
                else
                    token.phon = "ɑː"
                end
            elseif ortho == "aoi" then
                token.phon = "iː"
            elseif ortho == "ao" then
                token.phon = dialect_values.ao
            elseif ortho == "eo" then
                token.phon = dialect_values.eo
            elseif ortho == "ea" then
                token.phon = dialect_values.ea
            elseif ortho == "ae" then
                token.phon = "eː"
            elseif ortho == "aí" or ortho == "ái" then
                token.phon = "ɑː"
            elseif ortho == "óí" or ortho == "ó" then
                token.phon = "oː"
            elseif ortho == "ú" then
                token.phon = "uː"
            elseif ortho == "í" then
                token.phon = "iː"
            elseif ortho == "é" then
                token.phon = "eː"
            elseif ortho == "á" then
                token.phon = "ɑː"
            elseif ortho == "o" then
                token.phon = "ɔ"
            elseif ortho == "u" then
                token.phon = "ʊ"
            elseif ortho == "i" then
                token.phon = "ɪ"
            elseif ortho == "e" then
                token.phon = "ɛ"
            elseif ortho == "a" then
                token.phon = "a"
            end
        end

        local is_broad_nasal = next and next.type == "cons" and
                (next.ortho == "nn" or next.ortho == "ng") and
                (next.palatal == false or next.palatal == nil)

        local is_geminate_n = next and next.type == "cons" and next.ortho == "n" and
                tokens[i + 2] and tokens[i + 2].type == "cons" and tokens[i + 2].ortho == "n"

        if is_broad_nasal or is_geminate_n then
            if ortho == "o" or ortho == "ó" or ortho == "u" then
                token.phon = "uː"
            end
        end

        if ortho == "o" and next and next.type == "cons" and next.palatal == false and not is_broad_nasal and not is_geminate_n then
            token.phon = "ɔ"
        end

        if ortho == "ío" then
            token.phon = "iː"
        end

        if next and next.type == "cons" then
            if next.palatal == true and (ortho == "o" or ortho == "u") then
                token.phon = "ɪ"
            elseif next.palatal == true and ortho == "a" and not token.stress then
                token.phon = "ɛ"
            elseif next.palatal == false and ortho == "i" and not token.stress then
                token.phon = "ə"
            elseif next.palatal == true and ortho == "e" and not token.stress then
                token.phon = "ɪ"
            elseif next.palatal == false and ortho == "e" and not token.stress then
                token.phon = "ə"
            end
        end

        if next and next.type == "cons" and next.ortho == "dh" then
            if ortho == "o" or ortho == "u" then
                token.phon = "uː"
            end
        end

        if prev and prev.type == "cons" then
            if prev.palatal == true then
                if token.phon == "ə" then
                    token.phon = "ɪ"
                end
            elseif prev.palatal == false then
                if token.phon == "ɪ" and not token.stress then
                    token.phon = "ə"
                end
            end
        end

        ::continue::
    end
end

local function render_tokens_verbose(tokens)
    local lines = {}
    for i, token in ipairs(tokens) do
        table.insert(lines, string.format(
            "%02d ortho=%q type=%s phon=%q palatal=%s stress=%s indices=[%d,%d]",
            i,
            token.ortho or "",
            token.type or "",
            token.phon or "",
            tostring(token.palatal),
            tostring(token.stress),
            token.ortho_indices and token.ortho_indices[1] or 0,
            token.ortho_indices and token.ortho_indices[2] or 0
        ))
    end
    return table.concat(lines, "\n")
end

local function clone_token(token)
    local copy = {}
    for k, v in pairs(token) do
        if type(v) == "table" then
            local nested = {}
            for nk, nv in pairs(v) do
                nested[nk] = nv
            end
            copy[k] = nested
        else
            copy[k] = v
        end
    end
    return copy
end

local function clone_tokens(tokens)
    local copy = {}
    for i, token in ipairs(tokens) do
        copy[i] = clone_token(token)
    end
    return copy
end

local function process_tokens(tokens, dialect)
    tokens = clone_tokens(tokens)
    assign_polarity(tokens)
    assign_final_ng_polarity(tokens)
    apply_fricative_vocalization(tokens)
    apply_final_mutated_fricative_polarity(tokens)
    apply_slender_coda_vowels(tokens)
    resolve_consonants(tokens)
    resolve_vowel_plus_mutated_fricative(tokens)
    remove_final_silent_mutated_fricatives(tokens)
    apply_stress(tokens)
    resolve_vowels(tokens, dialect or "connacht")
    apply_unstressed_reduction(tokens)
    return tokens
end

local function transcribe_tokens(word, dialect)
    local tokens = tokenize_word(word)
    tokens = process_tokens(tokens, dialect)
    return render_output(tokens), tokens
end

irish_tokens.is_vowel_char = is_vowel_char
irish_tokens.is_slender_vowel_char = is_slender_vowel_char
irish_tokens.is_broad_vowel_char = is_broad_vowel_char
irish_tokens.make_token = make_token
irish_tokens.tokenize_word = tokenize_word
irish_tokens.assign_polarity = assign_polarity
irish_tokens.apply_stress = apply_stress
irish_tokens.resolve_consonants = resolve_consonants
irish_tokens.resolve_vowels = resolve_vowels
irish_tokens.render_output = render_output
irish_tokens.render_tokens_verbose = render_tokens_verbose
irish_tokens.process_tokens = process_tokens
irish_tokens.transcribe_tokens = transcribe_tokens

return irish_tokens
