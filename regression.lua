--[[
    Regression Test Suite for the Irish G2P Script (with History Tracking)
    
    Purpose:
    This script runs a series of predefined test words through the G2P transcriber,
    compares the output to a known-correct IPA transcription, and calculates the
    Levenshtein distance to measure accuracy. It saves the results of each run
    and compares the current run to the previous one to track progress.
    This version has NO EXTERNAL DEPENDENCIES besides the ustring library.

    Instructions:
    1. Place this file in the same directory as your G2P script (e.g., 'irish.lua')
       and the 'ustring' library.
    2. To keep the output clean, it is recommended to set MINIMAL_DEBUG_ENABLED = true
       in your main G2P script before running this test.
    3. Run from the command line: lua regression.lua
]]

-- Require the G2P script as a library
-- The require path should match the filename (without .lua)
local irishPhonetics = require('irish')

-- Require necessary libraries
local status_ustring, ustring_lib = pcall(require, "ustring.ustring")
if not status_ustring then
    print("ERROR: Failed to load ustring module. Make sure it is accessible.")
    error("ustring module not found.")
end
local ulen, usub, ugsub, N = ustring_lib.len, ustring_lib.sub, ustring_lib.gsub, ustring_lib.toNFC

-- History file configuration
local HISTORY_FILE = "g2p_test_history.txt"
local DELIMITER = "|" -- A character unlikely to be in the IPA output

---
-- Calculates the Levenshtein distance between two UTF-8 strings.
--
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

---
-- Loads the results from the previous test run from a custom text file.
-- @return A table of previous results, or an empty table if none exist.
--
local function load_previous_results()
    local file = io.open(HISTORY_FILE, "r")
    if not file then
        return {}
    end

    local results = { summary = {}, words = {} }
    local current_section = nil

    for line in file:lines() do
        if line == "--SUMMARY--" then
            current_section = "summary"
        elseif line == "--WORDS--" then
            current_section = "words"
        elseif current_section == "summary" then
            local key, value = line:match("([^:]+):(.*)")
            if key and value then
                -- Convert numeric values back from strings
                local num_value = tonumber(value)
                results.summary[key] = num_value or value
            end
        elseif current_section == "words" then
            local parts = {}
            for part in line:gmatch("([^" .. DELIMITER .. "]+)") do
                table.insert(parts, part)
            end
            if #parts == 3 then
                local word, ipa, distance = parts[1], parts[2], tonumber(parts[3])
                results.words[word] = { ipa = ipa, distance = distance }
            end
        end
    end

    file:close()
    return results
end

---
-- Saves the current test results to a custom text file.
-- @param results The table of current results to save.
--
local function save_current_results(results)
    local file = io.open(HISTORY_FILE, "w")
    if not file then
        print("WARNING: Could not open history file for writing: " .. HISTORY_FILE)
        return
    end

    -- Write summary
    file:write("--SUMMARY--\n")
    if results.summary then
        for key, value in pairs(results.summary) do
            file:write(string.format("%s:%s\n", key, tostring(value)))
        end
    end

    -- Write word data
    file:write("--WORDS--\n")
    if results.words then
        -- Sort words for consistent output
        local sorted_words = {}
        for word in pairs(results.words) do
            table.insert(sorted_words, word)
        end
        table.sort(sorted_words)

        for _, word in ipairs(sorted_words) do
            local data = results.words[word]
            file:write(string.format("%s%s%s%s%d\n", word, DELIMITER, data.ipa, DELIMITER, data.distance))
        end
    end

    file:close()
end


-- =============================================================================
-- TEST DATA
-- =============================================================================
local test_data = {
     -- =====================================================================
    -- Category 1: Vowel Gradation (Refined)
    -- Testing the now more complex a -> ɛ vs. a -> a rule.
    -- =====================================================================
    { word = "glas",      target = "ɡlˠasˠ",     comment = "Vowel Gradation (Base): Broad coda" },
    { word = "glais",     target = "ɡlˠaʃ",      comment = "Vowel Gradation (a -> a): 'a' does NOT front to 'ɛ' before 's' -> 'ʃ'." },
    { word = "alt",       target = "al̪ˠt̪ˠ",      comment = "Vowel Gradation (Base): Broad coda" },
    { word = "ailt",      target = "ɛlʲtʲ",      comment = "Vowel Gradation (a -> ɛ): 'a' DOES front to 'ɛ' before 'lt' -> 'lʲtʲ'." },

    -- =====================================================================
    -- Category 2: Nasal Raising (NEW & High Priority)
    -- Testing vowel changes before nasal consonants.
    -- =====================================================================
    { word = "seomra",    target = "ʃuːmˠɾˠə",  comment = "Nasal Raising: eo -> [uː] before m." },
    { word = "seomraí",   target = "ʃuːmˠɾˠiː",  comment = "Nasal Raising: Plural form, eo -> [uː] before m." },
    { word = "trom",      target = "t̪ˠɾˠuːmˠ",    comment = "Nasal Raising: o -> [uː] before m." },
    { word = "bonn",      target = "bˠuːn̪ˠ",      comment = "Nasal Raising: o -> [uː] before nn." },
    { word = "fón",       target = "fˠoːnˠ",      comment = "Nasal Raising (Control): Should NOT raise if the rule is too broad." },

    -- =====================================================================
    -- Category 3: `sh`/`th` Lenition (Verification)
    -- Re-testing with the new understanding.
    -- =====================================================================
    { word = "sheol",    target = "çɔːlˠ",     comment = "sh + broad 'eo' -> [ç]" },
    { word = "thóg",     target = "hoːɡ",       comment = "th + broad 'ó' -> [h] (Grammatical exception)" },
    { word = "shíl",     target = "hiːlʲ",      comment = "sh + slender 'í' -> [h]" },
    { word = "a Sheáin", target = "ə çɑːnʲ",    comment = "Sandhi context: sh + broad 'á' -> [ç]" },
    { word = "aithrí",   target = "ahɾʲiː",     comment = "Medial th + slender 'í' -> [h]" },
    { word = "brath",    target = "bˠɾˠa",       comment = "Final th -> silent" },

    -- =====================================================================
    -- Category 4: Cluster Simplification (Verification)
    -- =====================================================================
    { word = "cnoc",      target = "kɾˠʊk",      comment = "Cluster Shift: cn -> cr (with vowel raising)" },
    { word = "tnúth",      target = "t̪ˠɾˠuː",     comment = "Cluster Shift: tn -> tr" },
    { word = "Tadhg",      target = "t̪ˠaiɡ",      comment = "Cluster Simplification: dhg -> g" },

    -- =====================================================================
    -- Category 5: Suffix & Grammatical Word Phonology (Verification)
    -- =====================================================================
    { word = "'ur",       target = "ə",          comment = "Grammatical Word: Final 'r' is silent" },
    { word = "íocfaidh",   target = "iːkə",       comment = "Suffix Engine: -faidh -> [ə]" },
    { word = "marcaigh",   target = "mˠaɾˠkiː",  comment = "Suffix Engine: Palatalized -ach -> [iː]" },

    -- =====================================================================
    -- Category 6: Vocalization (Ongoing Challenge)
    -- =====================================================================
    { word = "chugham",   target = "xuːmˠ",      comment = "Vocalization: ugh -> [uː]" },
    { word = "láimh",      target = "l̪ˠɑːvʲ",     comment = "Blocked Vocalization: Final slender mh -> [vʲ]" },
    { word = "leabhar",    target = "lʲəuɾˠ",     comment = "Vocalization: eabh -> [əu]" },

    { word = "greamaím",   target = "ˈɟɾʲamˠiːmʲ", comment = "" },

    { word = "dugaire",    target = "d̪ˠʊɡəɾʲə", comment = "e reduction to schwa in final position in slender context" },

    { word = "Gaelach",    target = "ˈɡeːl̪ˠəx", comment = "" },
    { word = "Gaedhlaing", target = "ˈɡeːlɪɲ", comment = "" },
}

-- Creates a left-aligned, space-padded string by calculating the VISUAL width.
-- It does this by removing common zero-width combining diacritics before measuring.
-- This function is UTF-8 aware.
-- @param str The string to pad.
-- @param width The desired final column width.
-- @return The padded string.
--
local function pad_utf8(str, width)
    -- This pattern removes the most common zero-width combining marks found in
    -- Irish orthography (fada) and the generated IPA (quality/stress markers).
    -- Unicode ranges can be added for more completeness if needed.
    local zero_width_diacritics = "[´`^~¨˛ˇˈˈ ̪´´´]" -- Includes fada, gravis, stress, quality markers etc.

    local stripped_str = ugsub(str, zero_width_diacritics, "")
    local visual_len = ulen(stripped_str)

    if visual_len >= width then
        return str
    end
    
    local padding_needed = width - visual_len
    -- Handle potential negative padding if stripping made it seem shorter than it is
    if padding_needed < 0 then padding_needed = 0 end
    
    local padding = string.rep(" ", padding_needed)
    return str .. padding
end
-- =============================================================================
-- TEST RUNNER
-- =============================================================================

-- Load previous results for comparison
local previous_results = load_previous_results()
local current_results = {}

local total_distance = 0
local word_count = #test_data

print("\n--- Running Irish G2P Regression Test ---\n")
print(string.format("%-20s | %-25s | %-25s | %s", "Word", "Expected IPA", "Generated IPA", "Distance"))
print(string.rep("-", 80))

-- Column widths for manual formatting
local COL_WIDTH_WORD = 20
local COL_WIDTH_EXPECTED = 30 -- Increased width to accommodate long IPA
local COL_WIDTH_GENERATED = 30 -- Increased width to accommodate long IPA

print("\n--- Running Irish G2P Regression Test ---\n")
-- Print a manually formatted header
local header = pad_utf8("Word", COL_WIDTH_WORD) .. " | " ..
               pad_utf8("Expected IPA", COL_WIDTH_EXPECTED) .. " | " ..
               pad_utf8("Generated IPA", COL_WIDTH_GENERATED) .. " | " ..
               "Distance"
print(header)
print(string.rep("-", ulen(header) + 2)) -- Use ulen for accurate line length

for _, test_case in ipairs(test_data) do
    local word = test_case.word
    local expected_ipa = test_case.target

    local generated_ipa = irishPhonetics.transcribe(word)

    local normalized_expected = ugsub(expected_ipa, "ˈ", "")
    local normalized_generated = ugsub(generated_ipa, "ˈ", "")

    local distance = levenshtein(normalized_expected, normalized_generated)
    total_distance = total_distance + distance

    current_results[word] = {
        ipa = generated_ipa,
        distance = distance,
        target = expected_ipa,
    }

    -- THIS IS THE KEY CHANGE: Build the line using the new UTF-8 aware padding function
    local line_parts = {}
    table.insert(line_parts, pad_utf8(word, COL_WIDTH_WORD))
    table.insert(line_parts, pad_utf8(expected_ipa, COL_WIDTH_EXPECTED))
    table.insert(line_parts, pad_utf8(generated_ipa, COL_WIDTH_GENERATED))
    table.insert(line_parts, string.format("%d", distance))

    -- Join with a consistent separator for clean columns
    print(table.concat(line_parts, " | "))
end

print(string.rep("-", 80))

-- =============================================================================
-- SUMMARY AND HISTORY COMPARISON
-- =============================================================================

-- Calculate current run summary
if word_count > 0 then
    local average_distance = total_distance / word_count
    print(string.format("\nCURRENT RUN SUMMARY (%d words):", word_count))
    print(string.format("  Total Levenshtein Distance: %d", total_distance))
    print(string.format("  Average Distance per Word:  %.4f", average_distance))
else
    print("\nNo test data found.")
    return
end

-- Compare with previous run
local prev_total_distance = previous_results.summary and previous_results.summary.total_distance or nil
if prev_total_distance then
    local diff = total_distance - prev_total_distance
    local sign = diff >= 0 and "+" or ""
    print(string.format("\nCOMPARISON WITH PREVIOUS RUN:"))
    print(string.format("  Change in Total Distance: %s%d (Lower is better)", sign, diff))

    local improvements = {}
    local regressions = {}
    local neutral_changes = {}

    for word, current_data in pairs(current_results) do
        if previous_results.words and previous_results.words[word] then
            local prev_data = previous_results.words[word]
            if current_data.distance < prev_data.distance then
                table.insert(improvements, string.format("  - %s (Dist: %d -> %d) [%s], old [%s], target [%s]", word, prev_data.distance, current_data.distance, current_data.ipa,prev_data.ipa, current_data.target))
            elseif current_data.distance > prev_data.distance then
                table.insert(regressions, string.format("  - %s (Dist: %d -> %d) [%s], old [%s], target [%s]", word, prev_data.distance, current_data.distance, current_data.ipa,prev_data.ipa, current_data.target))
            elseif current_data.ipa ~= prev_data.ipa then
                 table.insert(neutral_changes, string.format("  - %s (Dist: %d) [%s] vs old [%s], target [%s]", word, current_data.distance, current_data.ipa, prev_data.ipa, current_data.target))
            end
        end
    end

    if #improvements > 0 then
        print("\n  IMPROVEMENTS:")
        for _, line in ipairs(improvements) do print(line) end
    end
    if #regressions > 0 then
        print("\n  REGRESSIONS:")
        for _, line in ipairs(regressions) do print(line) end
    end
    if #neutral_changes > 0 then
        print("\n  NEUTRAL CHANGES (Same Score, Different IPA):")
        for _, line in ipairs(neutral_changes) do print(line) end
    end

else
    print("\nNo previous test history found. Results saved for next run.")
end

-- Save current results for the next run
local results_to_save = {
    summary = {
        total_distance = total_distance,
        average_distance = total_distance / word_count,
        timestamp = os.date()
    },
    words = current_results
}
save_current_results(results_to_save)

print("\nTest complete. Current results saved to " .. HISTORY_FILE .. "\n")