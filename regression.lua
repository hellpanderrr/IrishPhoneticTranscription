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
    3. Run from the command line: lua test_g2p.lua
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
    -- Category 1: Lenited `sh` and `th`
    { word = N("sheol"), ipa = N("çɔːlˠ") },
    { word = N("thug"), ipa = N("huɡ") },
    { word = N("shúil"), ipa = N("huːlʲ") },
    { word = N("Sheáin"), ipa = N("çɑːnʲ") },
    { word = N("théigh"), ipa = N("heːj") },
    { word = N("a theach"), ipa = N("ə hæx") },

    -- Category 2: Fricative Vocalization
    { word = N("chugham"), ipa = N("xuːmˠ") },
    { word = N("Eoghan"), ipa = N("oːnˠ") },
    { word = N("Laoghaire"), ipa = N("l̪ˠiːɾʲə") },
    { word = N("beirbhiughadh"), ipa = N("bʲɛɾʲuː") },
    { word = N("láimh"), ipa = N("l̪ˠɑːvʲ") },
    { word = N("comhairle"), ipa = N("kuːɾʲlʲə") },

    -- Category 3: Cluster Simplification & Historical Shifts
    { word = N("chnáimh"), ipa = N("xɾˠɑːvʲ") },
    { word = N("ghníomh"), ipa = N("jɾʲiːvˠ") },
    { word = N("tnúth"), ipa = N("t̪ˠɾˠuː") },
    { word = N("Tadhg"), ipa = N("t̪ˠaiɡ") },
    { word = N("comhartha"), ipa = N("koːɾˠə") },

    -- Category 4: Vowel Quality & Diphthongization
    { word = N("Airméanach"), ipa = N("aɾʲəmʲeːnˠəx") },
    { word = N("mairbh"), ipa = N("mˠaɾʲəvʲ") },
    { word = N("cailc"), ipa = N("kalʲc") },
    { word = N("feirm"), ipa = N("fʲɛɾʲəmʲ") },

    -- Category 5: Suffix & Grammatical Word Phonology
    { word = N("'ur"), ipa = N("ə") },
    { word = N("-fas"), ipa = N("həsˠ") },
    { word = N("íocfaidh"), ipa = N("iːkə") },
    { word = N("abhaile"), ipa = N("əwalʲə") },

    -- Category 6: Epenthesis
    { word = N("ailm"), ipa = N("alʲəmʲ") },
    { word = N("mairc"), ipa = N("mˠaɾʲc") },
    { word = N("dearg"), ipa = N("dʲaɾˠəɡ") },

    -- Category 7: Lexical Exceptions
    { word = N("Iúr"), ipa = N("ən̠ʲtʲuːɾˠ") },
    { word = N("Toirdhealbhach"), ipa = N("tʲɾʲɛl̪ˠax") },
    { word = N("suaimhneas"), ipa = N("ˈsˠiːmʲnʲəsˠ") },

    { word = N("ríomhleabhar"), ipa = N("ˈɾʲiːwˌlʲəuɾˠ") },
    { word = N("lonnaithe"), ipa = N("ˈl̪ˠɔn̪ˠiː") },
}

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

for _, test_case in ipairs(test_data) do
    local word = test_case.word
    local expected_ipa = test_case.ipa

    local generated_ipa = irishPhonetics.transcribe(word)

    local normalized_expected = ugsub(expected_ipa, "ˈ", "")
    local normalized_generated = ugsub(generated_ipa, "ˈ", "")

    local distance = levenshtein(normalized_expected, normalized_generated)
    total_distance = total_distance + distance

    -- Store current result for comparison and saving
    current_results[word] = {
        ipa = generated_ipa,
        distance = distance,
        target = expected_ipa,
    }

    print(string.format("%-20s | %-25s | %-25s | %d", word, expected_ipa, generated_ipa, distance))
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