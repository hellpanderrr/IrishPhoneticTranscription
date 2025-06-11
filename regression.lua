--[[
    Regression Test Suite for the Irish G2P Script
    
    Purpose:
    This script runs a series of predefined test words through the G2P transcriber,
    compares the output to a known-correct IPA transcription, and calculates the
    Levenshtein (edit) distance to measure accuracy. It then reports the
    average distance across the entire test set as a performance metric.

    Instructions:
    1. Place this file in the same directory as 'irish_phonetics_43_lua_p_strict.lua'
       and the 'ustring' library.
    2. To keep the output clean, it is recommended to set MINIMAL_DEBUG_ENABLED = true
       in 'irish_phonetics_43_lua_p_strict.lua' before running this test.
    3. Run from the command line: lua test_g2p.lua
]]

-- Require the G2P script as a library
local irishPhonetics = require('irish')

-- Require the ustring library for correct UTF-8 handling
local status, ustring_lib = pcall(require, "ustring.ustring")
if not status then
    print("ERROR: Failed to load ustring module. Make sure it is accessible.")
    error("ustring module not found.")
end
local ulen, usub = ustring_lib.len, ustring_lib.sub

local ulower, usub, ulen, ufind, umatch, ugsub, ugmatch, N = ustring_lib.lower,
    ustring_lib.sub,
    ustring_lib.len,
    ustring_lib.find,
    ustring_lib.match,
    ustring_lib.gsub,
    ustring_lib.gmatch,
    ustring_lib.toNFC

---
-- Calculates the Levenshtein distance between two UTF-8 strings.
-- This measures the number of single-character edits (insertions, deletions,
-- or substitutions) required to change one string into the other.
-- @param str1 The first string.
-- @param str2 The second string.
-- @return The Levenshtein distance (integer).
--
function levenshtein(str1, str2)
    local m = ulen(str1)
    local n = ulen(str2)

    -- Create a matrix (using two rows for space efficiency)
    local v0 = {}
    local v1 = {}

    -- Initialize the first row
    for i = 0, n do
        v0[i] = i
    end

    for i = 1, m do
        -- First element of the current row is i
        v1[0] = i

        for j = 1, n do
            -- Calculate substitution cost
            local cost = 0
            if usub(str1, i, i) ~= usub(str2, j, j) then
                cost = 1
            end
            -- Get the minimum of insertion, deletion, or substitution
            v1[j] = math.min(v1[j - 1] + 1, v0[j] + 1, v0[j - 1] + cost)
        end

        -- Copy v1 to v0 for the next iteration
        for j = 0, n do
            v0[j] = v1[j]
        end
    end

    return v1[n]
end

-- =============================================================================
-- TEST DATA
-- =============================================================================
-- A list of test cases, each with the orthographic word and the expected IPA.
-- This list is populated with challenging examples from your error logs.
-- You can add, remove, or modify entries here to expand the test suite.
-- NOTE: IPA strings are normalized to NFC for consistency.
local test_data = {
    -- Cases testing the 'c' vs 'k' distinction
    { word = N("crom"), ipa = N("kɾˠuːmˠ") },
    { word = N("cart"), ipa = N("kɑɾˠt̪ˠ") },
    { word = N("caint"), ipa = N("kɑːn̠ʲtʲ") },
    { word = N("cliath"), ipa = N("clʲiə") }, -- Target from log had 'ç' at end, likely typo. Should be silent.
    { word = N("ceol"), ipa = N("coːlˠ") },
    { word = N("ceird"), ipa = N("ceːɾˠdʲ") }, -- Note: a difficult word with dialectal variation.
    { word = N("cáis"), ipa = N("kɑːʃ") },
    { word = N("cill"), ipa = N("cɪl̠ʲ") },

    -- Cases testing the 'ch' lenition quality
    { word = N("cha"), ipa = N("ha") },
    { word = N("chonaic"), ipa = N("hʊnɪc") },
    { word = N("chroí"), ipa = N("xɾˠiː") },
    { word = N("cheana"), ipa = N("çanˠə") },
    { word = N("cháis"), ipa = N("xɑːʃ") },
    { word = N("chirt"), ipa = N("çɪɾˠtʲ") },

    -- Cases testing lenited labials (bh/mh -> w)
    { word = N("bhfuil"), ipa = N("wɪlʲ") },
    { word = N("a mhadra"), ipa = N("ə wad̪ˠɾˠə") },
    { word = N("caidhp bháis"), ipa = N("kaipʲ wɑːʃ") },

    -- Cases testing suffixes and unstressed words
    { word = N("agam"), ipa = N("ʊɡəmˠ") },
    { word = N("-aimid"), ipa = N("əmʲɪdʲ") },
    { word = N("ar"), ipa = N("əɾʲ") },

    -- Cases testing vowel vocalization
    { word = N("leabhar"), ipa = N("lʲəuɾˠ") },
    { word = N("Eoghan"), ipa = N("oːnˠ") },
    { word = N("Aodh"), ipa = N("iː") },

    -- Other challenging cases from logs
    { word = N("Gaelach"), ipa = N("ɡeːlˠəx") },
    { word = N("Ghaelach"), ipa = N("ɣeːlˠəx") },
    { word = N("oíche"), ipa = N("iːhə") },
    { word = N("droichead"), ipa = N("d̪ˠɾˠɛhəd̪ˠ") },
}

-- =============================================================================
-- TEST RUNNER
-- =============================================================================

local total_distance = 0
local word_count = #test_data

print("\n--- Running Irish G2P Regression Test ---\n")
print(string.format("%-20s | %-25s | %-25s | %s", "Word", "Expected IPA", "Generated IPA", "Distance"))
print(string.rep("-", 80))

for _, test_case in ipairs(test_data) do
    local word = test_case.word
    local expected_ipa = test_case.ipa

    -- Run the transcription
    local generated_ipa = irishPhonetics.transcribe(word)

    -- For a fair comparison, we can normalize by removing the primary stress marker,
    -- as its presence might not be consistent in the target data.
    local normalized_expected = ugsub(expected_ipa, "ˈ", "")
    local normalized_generated = ugsub(generated_ipa, "ˈ", "")

    -- Calculate Levenshtein distance
    local distance = levenshtein(normalized_expected, normalized_generated)
    total_distance = total_distance + distance

    -- Print the result for this word
    print(string.format("%-20s | %-25s | %-25s | %d", word, expected_ipa, generated_ipa, distance))
end

print(string.rep("-", 80))

-- Calculate and print the final average distance
if word_count > 0 then
    local average_distance = total_distance / word_count
    print(string.format("\nTest Complete. %d words tested.", word_count))
    print(string.format("Total Levenshtein Distance: %d", total_distance))
    print(string.format("Average Distance per Word: %.4f\n", average_distance))
else
    print("\nNo test data found.")
end