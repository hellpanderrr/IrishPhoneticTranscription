--[[
    Extended Regression Test Suite for the Irish G2P Script
    Based on error patterns from results.csv (6,829 words).
    Tests high-impact error categories: suffixes, vowels, clusters, multi-word.

    Run: luajit regression_extended.lua
]]

local irishPhonetics = require('irish_main')

local status_ustring, ustring_lib = pcall(require, "ustring.ustring")
if not status_ustring then
    print("ERROR: Failed to load ustring module.")
    error("ustring module not found.")
end
local ulen, usub, ugsub, N = ustring_lib.len, ustring_lib.sub, ustring_lib.gsub, ustring_lib.toNFC

local HISTORY_FILE = "g2p_test_history_ext.txt"
local DELIMITER = "|"

function levenshtein(str1, str2)
    local m = ulen(str1)
    local n = ulen(str2)
    local v0, v1 = {}, {}
    for i = 0, n do v0[i] = i end
    for i = 1, m do
        v1[0] = i
        for j = 1, n do
            local cost = (usub(str1, i, i) == usub(str2, j, j)) and 0 or 1
            v1[j] = math.min(v1[j - 1] + 1, v0[j] + 1, v0[j - 1] + cost)
        end
        for j = 0, n do v0[j] = v1[j] end
    end
    return v1[n]
end

local function load_previous_results()
    local file = io.open(HISTORY_FILE, "r")
    if not file then return {} end
    local results = { summary = {}, words = {} }
    local current_section = nil
    for line in file:lines() do
        if line == "--SUMMARY--" then current_section = "summary"
        elseif line == "--WORDS--" then current_section = "words"
        elseif current_section == "summary" then
            local key, value = line:match("([^:]+):(.*)")
            if key and value then results.summary[key] = tonumber(value) or value end
        elseif current_section == "words" then
            local parts = {}
            for part in line:gmatch("([^" .. DELIMITER .. "]+)") do table.insert(parts, part) end
            if #parts == 3 then results.words[parts[1]] = { ipa = parts[2], distance = tonumber(parts[3]) } end
        end
    end
    file:close()
    return results
end

local function save_current_results(results)
    local file = io.open(HISTORY_FILE, "w")
    if not file then return end
    file:write("--SUMMARY--\n")
    for key, value in pairs(results.summary) do file:write(string.format("%s:%s\n", key, tostring(value))) end
    file:write("--WORDS--\n")
    local sorted = {}; for w in pairs(results.words) do sorted[#sorted+1] = w end; table.sort(sorted)
    for _, w in ipairs(sorted) do
        local d = results.words[w]
        file:write(string.format("%s%s%s%s%d\n", w, DELIMITER, d.ipa, DELIMITER, d.distance))
    end
    file:close()
end

local function pad_utf8(str, width)
    local stripped = ugsub(str, "[´`^~¨˛ˇˈ ̪]", "")
    local visual_len = ulen(stripped)
    if visual_len >= width then return str end
    return str .. string.rep(" ", width - visual_len)
end

-- =============================================================================
-- TEST DATA — sampled from results.csv error patterns
-- =============================================================================
local test_data = {
    -- =====================================================================
    -- Category 1: Suffix Stress (fixed by adding missing unstressed suffixes)
    -- =====================================================================
    { word = "marcaigh",   target = "ˈmˠaɾˠkiː",     comment = "Suffix: -aigh" },
    { word = "íocfaidh",   target = "iːkə",            comment = "Suffix: -faidh" },

    -- =====================================================================
    -- Category 2: Suffix -aire (fixed by MKR_SUFFIX_AIRE)
    -- =====================================================================
    { word = "dugaire",    target = "d̪ˠʊɡəɾʲə",      comment = "Suffix: -aire -> əɾʲə" },
    { word = "feirmeoir",  target = "fʲɛɾʲmʲoːɾʲ",    comment = "Suffix: -eoir" },
    { word = "feirmeoirí", target = "fʲɛɾʲmʲoːɾʲiː",  comment = "Suffix: -eoirí" },

    -- =====================================================================
    -- Category 3: Suffix -aim (fixed by MKR_SUFFIX_AIM)
    -- =====================================================================
    { word = "greamaím",   target = "ˈɟɾʲamˠiːmʲ",    comment = "Suffix: -aím -> iːmʲ" },
    { word = "marcaím",    target = "ˈmˠaɾˠkiːmʲ",    comment = "Suffix: -aím -> iːmʲ" },
    { word = "dúnaim",     target = "ˈd̪ˠʊnˠiːmʲ",    comment = "Suffix: -aim -> iːmʲ" },

    -- =====================================================================
    -- Category 4: Suffix -im (fixed by MKR_SUFFIX_IM)
    -- =====================================================================
    { word = "brisim",     target = "ˈbʲɾʲɪʃəmʲ",     comment = "Suffix: -im -> əmʲ" },
    { word = "creidim",    target = "ˈcɾʲɛdʲəmʲ",     comment = "Suffix: -im -> əmʲ" },
    { word = "tuigim",     target = "ˈt̪ˠɪɟəmʲ",       comment = "Suffix: -im -> əmʲ" },

    -- =====================================================================
    -- Category 5: Vowel Gradation (core accuracy)
    -- =====================================================================
    { word = "glas",       target = "ɡlˠasˠ",          comment = "Vowel: broad coda" },
    { word = "glais",      target = "ɡlˠaʃ",           comment = "Vowel: a before slender" },
    { word = "alt",        target = "al̪ˠt̪ˠ",           comment = "Vowel: broad coda" },
    { word = "ailt",       target = "ɛlʲtʲ",           comment = "Vowel: a -> ɛ before slender" },
    { word = "fear",       target = "fʲɑːɾˠ",          comment = "Vowel: ea -> ɑː" },
    { word = "bord",       target = "bˠɔɾˠd̪ˠ",        comment = "Vowel: or -> ɔɾˠ" },

    -- =====================================================================
    -- Category 6: Nasal Raising
    -- =====================================================================
    { word = "seomra",     target = "ʃuːmˠɾˠə",       comment = "Nasal: eo -> uː before m" },
    { word = "seomraí",    target = "ʃuːmˠɾˠiː",       comment = "Nasal: plural" },
    { word = "trom",       target = "t̪ˠɾˠuːmˠ",        comment = "Nasal: o -> uː before m" },
    { word = "bonn",       target = "bˠuːn̪ˠ",          comment = "Nasal: o -> uː before nn" },
    { word = "fón",        target = "fˠoːnˠ",          comment = "Nasal: control (no raise)" },

    -- =====================================================================
    -- Category 7: sh/th Lenition
    -- =====================================================================
    { word = "sheol",      target = "çɔːlˠ",          comment = "sh: broad eo -> ç" },
    { word = "thóg",       target = "hoːɡ",            comment = "th: broad ó -> h" },
    { word = "shíl",       target = "hiːlʲ",           comment = "sh: slender í -> h" },
    { word = "a Sheáin",   target = "ə çɑːnʲ",         comment = "sh: sandhi context" },
    { word = "aithrí",     target = "ahɾʲiː",          comment = "th: medial slender" },
    { word = "brath",      target = "bˠɾˠa",           comment = "th: final silent" },

    -- =====================================================================
    -- Category 8: Cluster Simplification
    -- =====================================================================
    { word = "cnoc",       target = "kɾˠʊk",           comment = "Cluster: cn -> kr" },
    { word = "tnúth",      target = "t̪ˠɾˠuː",          comment = "Cluster: tn -> tr" },
    { word = "Tadhg",      target = "t̪ˠaiɡ",           comment = "Cluster: dhg -> g" },

    -- =====================================================================
    -- Category 9: Vocalization
    -- =====================================================================
    { word = "chugham",    target = "xuːmˠ",           comment = "Vocal: ugh -> uː" },
    { word = "láimh",      target = "l̪ˠɑːvʲ",          comment = "Vocal: mh -> vʲ" },
    { word = "leabhar",    target = "lʲəuɾˠ",          comment = "Vocal: eabh -> əu" },

    -- =====================================================================
    -- Category 10: Compound/Complex Words
    -- =====================================================================
    { word = "Gaeltacht",  target = "ˈɡeːlʲtʲəxt̪ˠ",   comment = "Compound: Gaeilge + tacht" },
    { word = "Gaedhlaing", target = "ˈɡeːlɪɲ",         comment = "Compound: Gael + ing" },
    { word = "Gaelach",    target = "ˈɡeːl̪ˠəx",        comment = "Compound: Gael + ach" },

    -- =====================================================================
    -- Category 11: Multi-word Phrases
    -- =====================================================================
    { word = "níl",        target = "n̪ˠiːlʲ",          comment = "Phrase: níl" },
    { word = "cén",        target = "cɛn̪ˠ",            comment = "Phrase: cén" },

    -- =====================================================================
    -- Category 12: Schwa Preservation
    -- =====================================================================
    { word = "capall",     target = "ˈkapˠəl̪ˠ",       comment = "Schwa: -all -> əl" },
    { word = "buachaill",  target = "ˈbˠuaxəl̠ʲ",      comment = "Schwa: -aill -> əlʲ" },
    { word = "caife",      target = "ˈkafʲə",          comment = "Schwa: -e -> ə" },

    -- =====================================================================
    -- Category 13: Diphthong Handling
    -- =====================================================================
    { word = "oíche",      target = "ˈɔçə",            comment = "Diph: ích -> çə" },
    { word = "aoibhinn",   target = "ˈiːvʲən̠ʲ",        comment = "Diph: ao -> iː" },
    { word = "buí",        target = "bˠiː",            comment = "Diph: uí -> iː" },

    -- =====================================================================
    -- Category 14: Broad/Slender Consonants
    -- =====================================================================
    { word = "fliuch",     target = "ˈfʲlʲɪəx",        comment = "Cluster: fl -> fʲlʲ" },
    { word = "séimhiú",    target = "ˈʃɛvʲə",          comment = "Cluster: mh -> vʲ" },

    -- =====================================================================
    -- Category 15: Words from top error patterns in results.csv
    -- =====================================================================
    { word = "samhradh",   target = "ˈsˠəuɾˠə",       comment = "Error pattern: samh -> əu" },
    { word = "dearg",      target = "dʲarˠəɡ",         comment = "Error pattern: ear -> ar" },
    { word = "lorg",       target = "l̪ˠɔɾˠɡ",          comment = "Error pattern: or -> ɔɾ" },
    { word = "sáil",       target = "sˠɑːlʲ",          comment = "Error pattern: áil -> ɑːlʲ" },
    { word = "glaic",      target = "ɡlˠakʲ",          comment = "Error pattern: aic -> ak" },
    { word = "luibhe",     target = "l̪ˠɪvʲə",          comment = "Error pattern: uibh -> ɪv" },
    { word = "lúid",       target = "l̪ˠuːdʲ",          comment = "Error pattern: úid -> uːd" },
    { word = "alt",        target = "al̪ˠt̪ˠ",           comment = "Error pattern: alt -> alt" },
}

-- =============================================================================
-- TEST RUNNER
-- =============================================================================
local previous_results = load_previous_results()
local current_results = {}
local total_distance = 0
local word_count = #test_data

local COL_WIDTH_WORD = 18
local COL_WIDTH_EXPECTED = 28
local COL_WIDTH_GENERATED = 28

print("\n--- Running Irish G2P Extended Regression Test ---\n")
local header = pad_utf8("Word", COL_WIDTH_WORD) .. " | " ..
               pad_utf8("Expected IPA", COL_WIDTH_EXPECTED) .. " | " ..
               pad_utf8("Generated IPA", COL_WIDTH_GENERATED) .. " | " ..
               "Dist"
print(header)
print(string.rep("-", ulen(header) + 2))

local category_stats = {}
local current_category = ""

for _, test_case in ipairs(test_data) do
    local word = test_case.word
    local expected_ipa = test_case.target
    local generated_ipa = irishPhonetics.transcribe(word)

    local normalized_expected = ugsub(expected_ipa, "ˈ", "")
    local normalized_generated = ugsub(generated_ipa, "ˈ", "")
    local distance = levenshtein(normalized_expected, normalized_generated)
    total_distance = total_distance + distance

    current_results[word] = { ipa = generated_ipa, distance = distance, target = expected_ipa }

    local line_parts = {}
    table.insert(line_parts, pad_utf8(word, COL_WIDTH_WORD))
    table.insert(line_parts, pad_utf8(expected_ipa, COL_WIDTH_EXPECTED))
    table.insert(line_parts, pad_utf8(generated_ipa, COL_WIDTH_GENERATED))
    table.insert(line_parts, string.format("%d", distance))
    print(table.concat(line_parts, " | "))
end

print(string.rep("-", ulen(header) + 2))

-- =============================================================================
-- SUMMARY
-- =============================================================================
if word_count > 0 then
    local average_distance = total_distance / word_count
    print(string.format("\nCURRENT RUN SUMMARY (%d words):", word_count))
    print(string.format("  Total Levenshtein Distance: %d", total_distance))
    print(string.format("  Average Distance per Word:  %.4f", average_distance))

    local exact = 0
    local near = 0
    for _, d in pairs(current_results) do
        if d.distance == 0 then exact = exact + 1
        elseif d.distance <= 2 then near = near + 1 end
    end
    print(string.format("  Exact matches: %d (%.1f%%)", exact, exact/word_count*100))
    print(string.format("  Near matches (≤2): %d (%.1f%%)", near, near/word_count*100))
end

-- Compare with previous run
local prev_total_distance = previous_results.summary and previous_results.summary.total_distance or nil
if prev_total_distance then
    local diff = total_distance - prev_total_distance
    print(string.format("\nCOMPARISON WITH PREVIOUS RUN:"))
    print(string.format("  Change in Total Distance: %s%d", diff >= 0 and "+" or "", diff))

    local improvements, regressions = {}, {}
    for word, cur in pairs(current_results) do
        if previous_results.words and previous_results.words[word] then
            local prev = previous_results.words[word]
            if cur.distance < prev.distance then
                table.insert(improvements, string.format("  - %s (Dist: %d -> %d) [%s]", word, prev.distance, cur.distance, cur.ipa))
            elseif cur.distance > prev.distance then
                table.insert(regressions, string.format("  - %s (Dist: %d -> %d) [%s]", word, prev.distance, cur.distance, cur.ipa))
            end
        end
    end
    if #improvements > 0 then print("\n  IMPROVEMENTS:"); for _, l in ipairs(improvements) do print(l) end end
    if #regressions > 0 then print("\n  REGRESSIONS:"); for _, l in ipairs(regressions) do print(l) end end
else
    print("\nNo previous test history found. Results saved for next run.")
end

local results_to_save = {
    summary = { total_distance = total_distance, average_distance = total_distance / word_count, timestamp = os.date() },
    words = current_results
}
save_current_results(results_to_save)
print("\nTest complete. Current results saved to " .. HISTORY_FILE .. "\n")
