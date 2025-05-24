--[[
    Simplified Phonetic Transcription Script for Modern Irish
    Based on "The Sound Structure of Modern Irish" by Raymond Hickey
    Primarily targeting Connemara Irish dialect.
]]

-- Debug output file setup
local debug_file = io.open("irish_debug.txt", "w")
debug_file:write("\239\187\191") -- UTF-8 BOM
local original_print = print

-- Redefine print to write to both console and file
print = function(...)
    local args = {...}
    local str_args = {}
    for i, v in ipairs(args) do
        str_args[i] = tostring(v)
    end
    local msg = table.concat(str_args, "\t")
    original_print(msg)
    debug_file:write(msg .. "\n")
    debug_file:flush() -- Ensure it's written immediately
end

local irishPhonetics = {}

-- Vowel type definitions (orthographic)
local SLENDER_VOWELS_ORTHO = "[eéií]"
local BROAD_VOWELS_ORTHO = "[aáoóuú]"
local VOWELS_ORTHO_PATTERN = SLENDER_VOWELS_ORTHO:sub(1,-2) .. BROAD_VOWELS_ORTHO:sub(2)

-- Consonant definitions (orthographic, for context checking)
local CONSONANTS_ORTHO_PATTERN = "[bcdfghlmnprstBCDFGHLMNPRST]"

-- Helper to check if a character is an orthographic vowel
local function is_ortho_vowel(char)
    return char and char:match("[" .. VOWELS_ORTHO_PATTERN .. "]")
end

-- Helper to get orthographic vowel type and its length (1 or 2 chars)
local function get_ortho_vowel_info(text, pos)
    if not pos or pos > #text then return nil, 0 end
    local char1 = text:sub(pos, pos)
    local char2 = text:sub(pos + 1, pos + 1)

    if char1 == 'a' and char2 == 'o' then return "broad", 2 end -- ao
    if char1 == 'i' and char2 == 'a' then return "slender_broad", 2 end -- ia
    if char1 == 'u' and char2 == 'a' then return "broad", 2 end -- ua
    if char1 == 'e' and char2 == 'o' then return "broad", 2 end -- eo
    if char1 == 'e' and char2 == 'a' then return "slender", 2 end -- ea

    if char1 == 'a' and char2 == 'i' then return "slender", 2 end -- ai
    if char1 == 'e' and char2 == 'i' then return "slender", 2 end -- ei
    if char1 == 'o' and char2 == 'i' then return "slender", 2 end -- oi
    if char1 == 'u' and char2 == 'i' then return "slender", 2 end -- ui

    if SLENDER_VOWELS_ORTHO:find(char1, 1, true) then return "slender", 1 end
    if BROAD_VOWELS_ORTHO:find(char1, 1, true) then return "broad", 1 end
    return nil, 0
end

-- Determine consonant quality ('palatal' or 'nonpalatal')
local function determine_consonant_quality_ortho(text, cons_match_start_pos, cons_match_end_pos)
    local prev_v_type, prev_v_len = nil, 0
    local next_v_type, next_v_len = nil, 0
    local temp_pos

    -- Look backwards
    temp_pos = cons_match_start_pos - 1
    local max_iterations = 100 -- Prevent infinite loops
    local iteration_count = 0
    while temp_pos >= 1 and iteration_count < max_iterations do
        iteration_count = iteration_count + 1
        local v_start_guess = temp_pos
        if temp_pos > 1 and is_ortho_vowel(text:sub(temp_pos-1, temp_pos-1)) and is_ortho_vowel(text:sub(temp_pos,temp_pos)) then
             v_start_guess = temp_pos -1 -- potential start of a digraph
        end
        local vtype, vlen = get_ortho_vowel_info(text, v_start_guess)
        if vtype then
            prev_v_type = vtype
            break
        elseif not text:sub(temp_pos, temp_pos):match(CONSONANTS_ORTHO_PATTERN) then break end
        temp_pos = temp_pos - 1
    end

    -- Look forwards
    temp_pos = cons_match_end_pos + 1
    iteration_count = 0
    while temp_pos <= #text and iteration_count < max_iterations do
        iteration_count = iteration_count + 1
        local vtype, vlen = get_ortho_vowel_info(text, temp_pos)
        if vtype then
            next_v_type = vtype
            break
        elseif not text:sub(temp_pos, temp_pos):match(CONSONANTS_ORTHO_PATTERN) then break end
        temp_pos = temp_pos + 1 -- Always increment by 1 to avoid getting stuck
    end

    if next_v_type == "slender" or next_v_type == "slender_broad" then
        if prev_v_type == "slender" or prev_v_type == "slender_broad" or not prev_v_type then
            return "palatal"
        else return "nonpalatal" end
    elseif next_v_type == "broad" then
        if prev_v_type == "broad" or not prev_v_type then
            return "nonpalatal"
        else return "palatal" end
    elseif prev_v_type then
        return (prev_v_type == "slender" or prev_v_type == "slender_broad") and "palatal" or "nonpalatal"
    end
    return "nonpalatal"
end

irishPhonetics.rules_stage1_preprocess = {
    { pattern = "%s+", replacement = " " },
    { pattern = "^%s*(.-)%s*$", replacement = function(m) return m:lower() end },
}

irishPhonetics.rules_stage2_digraphs_initial = {
    { pattern = "bhf", replacement = "_URUF_" }, { pattern = "bp", replacement = "_URUP_" },
    { pattern = "dt", replacement = "_URUT_" }, { pattern = "gc", replacement = "_URUC_" },
    { pattern = "mb", replacement = "_URUM_" }, { pattern = "nd", replacement = "_URUN_" },
    { pattern = "ng", replacement = "_URUG_" },

    { pattern = "bh", replacement = "_BH_" }, { pattern = "ch", replacement = "_CH_" },
    { pattern = "dh", replacement = "_DH_" }, { pattern = "fh", replacement = "_FH_" },
    { pattern = "gh", replacement = "_GH_" }, { pattern = "mh", replacement = "_MH_" },
    { pattern = "ph", replacement = "_PH_" }, { pattern = "sh", replacement = "_SH_" },
    { pattern = "th", replacement = "_TH_" },

    { pattern = "ll", replacement = "_LL_" }, { pattern = "nn", replacement = "_NN_" },
    { pattern = "rr", replacement = "_RR_" }, { pattern = "mm", replacement = "_MM_" },
}

irishPhonetics.rules_stage3_consonant_quality_and_digraph_resolution = {
    -- Resolve Urú (quality fixed by the mutation type, not surrounding vowels)
    { pattern = "_URUF_", replacement = "v" }, -- /v/
    { pattern = "_URUP_", replacement = "b" }, -- /b/
    { pattern = "_URUT_", replacement = "d" }, -- /d/
    { pattern = "_URUC_", replacement = "g" }, -- /g/
    { pattern = "_URUM_", replacement = "m" }, -- /m/
    { pattern = "_URUN_", replacement = "n" }, -- /n/
    { pattern = "_URUG_", replacement = "ŋ" }, -- /ŋ/

    -- Resolve Séimhiú
    { pattern = "_PH_", replacement = function(m, ortho_text, pos) -- p.277
        local quality = determine_consonant_quality_ortho(ortho_text, pos, pos + #m - 1)
        return quality == "palatal" and "f'" or "f"
    end },
    { pattern = "_SH_", replacement = function(m, ortho_text, pos) -- p.82, p.277
        -- Quality of /h/ from séimhiú of 's' is palatal if original 's' was before e/i,
        -- or if following vowel is front. Hickey notes `a theach [q hæ:x]` vs `a Sheáin [q çɑɑn']` (p.83)
        -- where 'h' from 'th' is influenced by following vowel, 'h' from 'sh' can be palatal [ç].
        local next_char_pos = pos + #m
        local next_v_type, _ = get_ortho_vowel_info(ortho_text, next_char_pos)
        if next_v_type == "slender" or next_v_type == "slender_broad" then return "h'" -- or "ç"
        elseif next_v_type == "broad" and (ortho_text:sub(pos-1,pos-1) == "i" or ortho_text:sub(pos-1,pos-1) == "e") then return "h'" -- ç for Seán
        else return "h" end
    end },
    { pattern = "_TH_", replacement = "h" }, -- /h/, simple /h/, quality determined by following vowel (p.82, p.277)
    { pattern = "_FH_", replacement = "" },  -- Generally silent, esp. initial lenited fh (p.277). Hickey p.85

    -- Resolve other digraphs
    { pattern = "_BH_", replacement = function(m, ortho_text, pos) -- p.72-74
        local quality = determine_consonant_quality_ortho(ortho_text, pos, pos + #m - 1)
        local next_char_pos = pos + #m
        local next_v_type, _ = get_ortho_vowel_info(ortho_text, next_char_pos)
        if quality == "palatal" then return "v'"
        -- Non-palatal /v/ often [w] before broad vowel in W/N (Hickey p.73)
        elseif next_v_type == "broad" then return "w"
        else return "v" end
    end },
    { pattern = "_CH_", replacement = function(m, ortho_text, pos) -- p.78-81
        local quality = determine_consonant_quality_ortho(ortho_text, pos, pos + #m - 1)
        return quality == "palatal" and "ç" or "x"
    end },
    { pattern = "_DH_", replacement = function(m, ortho_text, pos) -- p.78-81
        local quality = determine_consonant_quality_ortho(ortho_text, pos, pos + #m - 1)
        return quality == "palatal" and "j" or "ɣ"
    end },
    { pattern = "_GH_", replacement = function(m, ortho_text, pos) -- p.78-81
        local quality = determine_consonant_quality_ortho(ortho_text, pos, pos + #m - 1)
        return quality == "palatal" and "j" or "ɣ"
    end },
    { pattern = "_MH_", replacement = function(m, ortho_text, pos) -- p.72-74
        local quality = determine_consonant_quality_ortho(ortho_text, pos, pos + #m - 1)
        local next_char_pos = pos + #m
        local next_v_type, _ = get_ortho_vowel_info(ortho_text, next_char_pos)
        if quality == "palatal" then return "v'"
        elseif next_v_type == "broad" then return "w"
        else return "v" end
    end },

    -- Resolve strong sonorants placeholders (p.97-99)
    { pattern = "_LL_", replacement = function(m, ortho_text, pos)
        local quality = determine_consonant_quality_ortho(ortho_text, pos, pos + #m - 1)
        return quality == "palatal" and "L'" or "L"
    end },
    { pattern = "_NN_", replacement = function(m, ortho_text, pos)
        local quality = determine_consonant_quality_ortho(ortho_text, pos, pos + #m - 1)
        return quality == "palatal" and "N'" or "N"
    end },
    { pattern = "_RR_", replacement = function(m, ortho_text, pos)
        local quality = determine_consonant_quality_ortho(ortho_text, pos, pos + #m - 1)
        return quality == "palatal" and "R'" or "R"
    end },
    { pattern = "_MM_", replacement = function(m, ortho_text, pos)
        local quality = determine_consonant_quality_ortho(ortho_text, pos, pos + #m -1)
        return quality == "palatal" and "M'" or "M"
    end },

    -- Single consonants (if not part of a processed digraph/placeholder)
    { pattern = "([bcdfglmnprst])", replacement = function(cons_match, original_text_for_context, match_start_pos_in_current)
        local quality = determine_consonant_quality_ortho(original_text_for_context, match_start_pos_in_current, match_start_pos_in_current)
        local base_sound = cons_match
        if cons_match == "c" then base_sound = "k" end

        if cons_match == "s" then
            return quality == "palatal" and "s'" or "s" -- s' will become ʃ
        elseif quality == "palatal" then
            return base_sound .. "'"
        else
            return base_sound
        end
    end},
}

irishPhonetics.rules_stage4_vowels_and_diphthongs = {
    -- LONG VOWELS
    { pattern = "á", replacement = "ɑɑ" }, { pattern = "é", replacement = "ee" },
    { pattern = "í", replacement = "ii" }, { pattern = "ó", replacement = "oo" },
    { pattern = "ú", replacement = "uu" },
    { pattern = "ao", replacement = "II" }, -- Connemara retracted /i:/ (Hickey p.171-173)

    -- DIPHTHONGS (Phonemic, p.156-163)
    { pattern = "ae", replacement = "ee" }, -- Commonly /e:/, can be /ai/ (p.123)
    { pattern = "eo", replacement = "oo" }, -- Commonly /o:/
    { pattern = "ia", replacement = "ia" },
    { pattern = "ua", replacement = "ua" },

    -- Vocalisation of fricatives (bh, mh, dh, gh) after vowel (p.166-167)
    -- These should target the phonetic segments created in stage 3
    -- After BROAD VOWELS (a, o, u becoming ɑ, ɔ, ʊ or long versions)
    { pattern = "([ɑaɔoʊuə])([vw])([#%s])", replacement = function(v, fric, boundary) return v .. "u" .. boundary end }, -- e.g. leabhar -> l'aur -> l'au
    { pattern = "([ɑaɔoʊuə])([vw])([kptxçLNRMN'%W])", replacement = function(v, fric, cons) return v .. "u" .. cons end }, -- e.g., amhrán -> aurɑɑN
    { pattern = "([ɑaɔoʊuə])([jɣ])([#%s])", replacement = function(v, fric, boundary) return v .. "i" .. boundary end }, -- e.g. aghaidh -> ai
    { pattern = "([ɑaɔoʊuə])([jɣ])([kptxçLNRMN'%W])", replacement = function(v, fric, cons) return v .. "i" .. cons end }, -- e.g. adhmad -> aiməd

    -- After SLENDER VOWELS (e, i becoming e, i)
    { pattern = "([eiɪ])v'([#%s])", replacement = "%1i%2"}, -- e.g. suibhe -> sui:
    { pattern = "([eiɪ])v'([kptxçLNRMN'%W]')", replacement = "%1i%2"},
    { pattern = "([eiɪ])j([#%s])", replacement = "%1i%2"},   -- e.g. suidhe -> sui:
    { pattern = "([eiɪ])j([kptxçLNRMN'%W]')", replacement = "%1i%2"},

    -- SHORT VOWEL ALLOPHONY (Hickey p.139-155 "Short Vowels"; p.129-133 "Vowel Gradation")
    -- C' V C' (palatal - vowel - palatal)
    { pattern = "([kgptdfbmnszrlLNRMçjɣŋhw]')a([kgptdfbmnszrlLNRMçjɣŋhw]')", replacement = "%1e%2" }, -- e.g. glaic /gl'ek'/
    { pattern = "([kgptdfbmnszrlLNRMçjɣŋhw]')([ou])([kgptdfbmnszrlLNRMçjɣŋhw]')", replacement = "%1i%3" }, -- e.g. fuil /f'il'/
    { pattern = "([kgptdfbmnszrlLNRMçjɣŋhw]')e([kgptdfbmnszrlLNRMçjɣŋhw]')", replacement = "%1e%2" }, -- e.g. teist /t'es't'/
    { pattern = "([kgptdfbmnszrlLNRMçjɣŋhw]')i([kgptdfbmnszrlLNRMçjɣŋhw]')", replacement = "%1i%2" }, -- e.g. min /m'in'/

    -- C' V C (palatal - vowel - non-palatal)
    { pattern = "([kgptdfbmnszrlLNRMçjɣŋhw]')a([kgptdfbmnszrlLNRMxɣŋhw%W])", replacement = "%1æ%2" }, -- e.g. fear /f'ær/
    { pattern = "([kgptdfbmnszrlLNRMçjɣŋhw]')([ou])([kgptdfbmnszrlLNRMxɣŋhw%W])", replacement = "%1ɔ%3" }, -- e.g. cion /k'ɔn/ (or /k'un/)
    { pattern = "([kgptdfbmnszrlLNRMçjɣŋhw]')e([kgptdfbmnszrlLNRMxɣŋhw%W])", replacement = "%1æ%2" },  -- e.g. bean /b'æn/ (from ortho ea)
    { pattern = "([kgptdfbmnszrlLNRMçjɣŋhw]')i([kgptdfbmnszrlLNRMxɣŋhw%W])", replacement = "%1i%2" },  -- e.g. fios /f'is/

    -- C V C' (non-palatal - vowel - palatal) (Vowel Gradation context)
    { pattern = "([kgptdfbmnszrlLNRMxɣŋhw%W])a([kgptdfbmnszrlLNRMçjɣŋhw]')", replacement = "%1e%2" }, -- e.g. glais /gles'/
    { pattern = "([kgptdfbmnszrlLNRMxɣŋhw%W])([ou])([kgptdfbmnszrlLNRMçjɣŋhw]')", replacement = "%1e%3" },-- e.g. poll -> poill /pel'/ -> pail' (further diphthongization)
    { pattern = "([kgptdfbmnszrlLNRMxɣŋhw%W])e([kgptdfbmnszrlLNRMçjɣŋhw]')", replacement = "%1e%2" },
    { pattern = "([kgptdfbmnszrlLNRMxɣŋhw%W])i([kgptdfbmnszrlLNRMçjɣŋhw]')", replacement = "%1i%2" },

    -- C V C (non-palatal - vowel - non-palatal)
    { pattern = "([kgptdfbmnszrlLNRMxɣŋhw%W])([ou])([kgxɣ])", replacement = "%1u%3" }, -- Before velars, o/u -> u (e.g. muc /muk/)
    -- Default short vowels if no other rule applied
    { pattern = "a", replacement = "a" }, { pattern = "[ou]", replacement = "ɔ" },
    { pattern = "e", replacement = "e" }, { pattern = "i", replacement = "i" },


    -- Diphthongization after vowel gradation for 'oi' and 'ei' if applicable
    -- (e.g. poll -> poill /pel'/ becomes /pail'/) (Hickey p.123, p.299)
    { pattern = "([kgptdfbmnszrlLNRMxɣŋhw%W])e(l')", replacement = "%1ai%2" }, -- poll > poill (pel') > pail'

    -- Unstressed vowel reduction (p.152-155)
    -- Very simplified, targets final -a, -e in assumed multi-syllable words
    { pattern = "([%w']+)a$", replacement = function(stem) if #stem > 2 then return stem .. "ə" else return stem .. "a" end end },
    { pattern = "([%w']+)e$", replacement = function(stem) if #stem > 2 then return stem .. "ə" else return stem .. "e" end end },
    { pattern = "aí#", replacement = "ii#" }, { pattern = "aí$", replacement = "ii" },
}

irishPhonetics.rules_stage5_strong_sonorants_epenthesis = {
    -- Vowel changes before strong sonorants in MONOSYLLABLES (Connemara, p.100-105)
    -- This requires a robust way to identify monosyllables from the *phonetic string*.
    -- For now, a heuristic based on common short vowel + strong sonorant + word end.
    -- `a` + Strong Sonorant -> `ɑɑ`
    { pattern = "a(L)$", replacement = "ɑɑ%1" }, { pattern = "a(N)$", replacement = "ɑɑ%1" },
    { pattern = "a(R)$", replacement = "ɑɑ%1" }, { pattern = "a(M)$", replacement = "ɑɑ%1" },
    -- `o/ɔ` + Strong Sonorant -> `oo` or `ou`
    { pattern = "ɔ(L)$", replacement = "ou%1" }, { pattern = "ɔ(N)$", replacement = "uu%1" }, -- tonn -> /tuuN/
    { pattern = "ɔ(R)$", replacement = "ou%1" }, { pattern = "ɔ(M)$", replacement = "oo%1" }, -- trom -> /trooM/
    -- `i` + Strong Sonorant -> `ii`
    { pattern = "i(L')$", replacement = "ii%1" }, { pattern = "i(N')$", replacement = "ii%1" },
    { pattern = "i(R')$", replacement = "ii%1" }, { pattern = "i(M')$", replacement = "ii%1" },
    -- `e` + Strong Sonorant -> `ee` or `ei`
    { pattern = "e(L')$", replacement = "ei%1" }, { pattern = "e(N')$", replacement = "ee%1" }, -- cenn -> /k'eeN/

    -- Epenthesis (p.197-205)
    -- Stressed ShortVowel + CoronalSonorant + VoicedNonCoronalObstruent + Boundary/VoicelessConsonant
    -- Non-palatal: epenthetic ə
    { pattern = "([aæɔeiouʊəII])([rln])([bgm])([#%sckpftxçʃcɟ%W]?)", replacement = function(v, s1, s2, boundary_or_vc)
        boundary_or_vc = boundary_or_vc or "" -- Default to empty string if nil
        if not v:match("^[aɑæeioɔuʊəIIiauaeiioiouuɨ][aɑæeioɔuʊəIIiauaeiioiouuɨ]$") and not v:match("ia") and not v:match("ua") then
            return v .. s1 .. "ə" .. s2 .. boundary_or_vc
        end
        return v .. s1 .. s2 .. boundary_or_vc
    end},
    -- Palatal: epenthetic i
    { pattern = "([aæɔeiouʊəII])([rln]')([bgm]')([#%sckpftxçʃcɟ%W]'?)", replacement = function(v, s1, s2, boundary_or_vc)
        boundary_or_vc = boundary_or_vc or "" -- Default to empty string if nil
        if not v:match("^[aɑæeioɔuʊəIIiauaeiioiouuɨ][aɑæeioɔuʊəIIiauaeiioiouuɨ]$") and not v:match("ia") and not v:match("ua") then
            return v .. s1 .. "i" .. s2 .. boundary_or_vc
        end
        return v .. s1 .. s2 .. boundary_or_vc
    end},
}

irishPhonetics.rules_stage6_final_cleanup = {
    { pattern = "([kgptdfbmnszrlvçjɣŋhwLNRMcsʃcɟ])''", replacement = "%1'" },
    { pattern = "s'", replacement = "ʃ" }, { pattern = "k'", replacement = "c" },
    { pattern = "g'", replacement = "ɟ" }, -- Note: Hickey often uses 'j' for palatal g
    { pattern = "II", replacement = "ɨɨ"},
    { pattern = "#", replacement = ""},
    { pattern = "%d+", replacement = ""}, -- Remove any unexpected digits
    { pattern = "^%s*(.-)%s*$", replacement = "%1" },
}

function irishPhonetics.transcribe(orthographic_word)
    local current_word = orthographic_word
    local original_ortho_for_context = orthographic_word:lower()

    print("Starting transcription of: " .. orthographic_word)

    local stages = {
        {name = "PreProcess", rules = irishPhonetics.rules_stage1_preprocess},
        {name = "InitialDigraphMarking", rules = irishPhonetics.rules_stage2_digraphs_initial},
        {name = "ConsonantQualityResolution", rules = irishPhonetics.rules_stage3_consonant_quality_and_digraph_resolution},
        {name = "VowelsAndDiphthongs", rules = irishPhonetics.rules_stage4_vowels_and_diphthongs},
        {name = "StrongSonorantsEpenthesis", rules = irishPhonetics.rules_stage5_strong_sonorants_epenthesis},
        {name = "FinalCleanup", rules = irishPhonetics.rules_stage6_final_cleanup},
    }

    for i, stage_data in ipairs(stages) do
        print("Starting stage: " .. stage_data.name)
        local rules_to_apply = stage_data.rules
        for j, rule in ipairs(rules_to_apply) do
            local original_for_gsub_pass = current_word
            if type(rule.replacement) == "string" then
                -- Simple string replacement
                current_word = current_word:gsub(rule.pattern, rule.replacement)
            elseif type(rule.replacement) == "function" then
                -- Function-based replacement with position workaround
                current_word = current_word:gsub(rule.pattern, function(...)
                    local args = {...}
                    local match_text = args[1]

                    -- Default position (beginning of string)
                    local match_pos = 1

                    -- Try to find a better position estimate
                    if match_text then
                        local pos = original_ortho_for_context:find(match_text, 1, true)
                        if pos then
                            match_pos = pos
                        end
                    end

                    -- Call the replacement function with the match text, context, and position
                    local result = rule.replacement(match_text, original_ortho_for_context, match_pos)
                    return result or ""
                end)
            end
        end
        print("After stage " .. stage_data.name .. ": " .. current_word)
    end

    print("Final transcription: " .. current_word)
    return current_word
end

-- Example Usage:
local words_to_test = {
    "leabhar", "samhradh", "aghaidh", "suidhe", "nimhe", "bóthar", "oíche", "ainm", "fear", "glaic", "muc", "fliuch",
    "ceann", "poll", "bord", "fada", "beag", "séimhiú", "úrú", "bacach", "isteach", "baile", "duine",
    "Gaeltacht", "Conamara", "Gaeilge", "aoibhinn", "buí", "caol", "leathan", "drochbhean", "an-mhaith",
    "fuinneog", "balla", "oiliúint", "staighre", "fios", "teanga", "dearg", "athbhliain", "comhrá", "mícheart"
}

print("\n=== Testing Irish Transcription ===\n")

for _, word in ipairs(words_to_test) do
    local original = word
    local transcribed = irishPhonetics.transcribe(original)
    print(string.format("%-15s -> %s", original, transcribed))
end

print("\n=== Transcription Complete ===\n")
debug_file:close()

return irishPhonetics
