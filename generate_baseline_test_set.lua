-- generate_baseline_test_set.lua

-- 1. Make sure your main transcriber script is accessible.
--    If it's named "irish_phonetics_37DE_ea_Refinement.lua" and in the same directory:
local transcriber_module_path = "irish"
local status, irishPhonetics = pcall(require, transcriber_module_path)

if not status then
    print("ERROR: Failed to load the transcriber module from path: " .. transcriber_module_path)
    print("Ensure the main Lua script (e.g., irish_phonetics_37DE_ea_Refinement.lua) is in the same directory or adjust the path.")
    return
end

-- 2. Define the words to test (copied from your script)
local words_to_test_focused = {
    -- Strong Sonorants - Broad
    "ceann", "am", "fonn", "poll", "trom", "corr", "bord", "tallann", "seanchas",
    -- Strong Sonorants - Palatal
    "im", "roinnt", "caill", "coill", "poinn", "cill",
    "bainne", -- Polysyllabic, should not lengthen first vowel
    -- Vocalized Fricatives
    "leabhar", "amhrán", "samhradh", "slaghdán", "adhradh", "laghadh", "feabhas",
    "ghabh", "damhsa",
    "deifir", "nimhe", "suidhe",
    "beidh", -- Special handling for 'ai'
    "lae", -- Standard long vowel for reference
    -- New for 37DL - Disyllabic Short-Long
    "scadán", "cailín", "soláthar", "bacán", "fuinneog", "oileán",
    -- New for 37DE - Low Vowel 'ea' checks
    "fear", "geal", "bean", "teach", "leaba", "seacht"
}

-- Define categories for better organization (optional, but good for the final test set)
-- For simplicity in generation, we'll assign a generic category for now.
-- You can manually categorize them later based on the list in the previous prompt.

local generated_test_set_lua_string = "local baseline_test_set = {\n"

print("\n--- Generating Baseline Test Set (Lua Table Format) ---")
print("-- Copy the 'local baseline_test_set = {...}' part below --\n")

-- Temporarily suppress the transcriber's own debug prints to keep this output clean
local original_transcriber_print = irishPhonetics.print -- Assuming your transcriber uses a global-like print
local original_transcriber_debug_minimal = irishPhonetics.debug_print_minimal -- and this one

if original_transcriber_print then
    irishPhonetics.print = function() end -- No-op
end
if original_transcriber_debug_minimal then
    irishPhonetics.debug_print_minimal = function() end -- No-op
end
-- Also, if your transcriber's main `print` is the global `print`, we need to manage that.
-- The `print` function in *this* script is already redirected to a file.
-- The `irishPhonetics.transcribe` function will use the `print` from its own environment.
-- To silence the transcriber's internal `print` calls if it uses the global `print`:
local global_print_backup = print
_G.print = function() end -- Temporarily silence global print for the transcriber

for _, word in ipairs(words_to_test_focused) do
    local original_ortho = word
    local transcribed_ipa = irishPhonetics.transcribe(original_ortho)

    -- Escape single quotes in the strings for Lua syntax
    local escaped_ortho = original_ortho:gsub("'", "\\'")
    local escaped_ipa = transcribed_ipa:gsub("'", "\\'")

    local phenomenon_comment = "Auto-generated baseline"
    -- Attempt to find a matching phenomenon from a predefined map (simplified)
    -- This is a placeholder; you'd ideally have a more structured way to map words to phenomena.
    if word == "ceann" or word == "am" or word == "fonn" or word == "poll" or word == "trom" or
       word == "corr" or word == "bord" or word == "im" or word == "roinnt" or
       word == "caill" or word == "coill" or word == "poinn" or word == "cill" then
        phenomenon_comment = "Strong Sonorant"
    elseif word == "fear" or word == "geal" or word == "bean" or word == "teach" or
           word == "leaba" or word == "seacht" then
        phenomenon_comment = "ea Allophony"
    elseif word == "leabhar" or word == "nimhe" or word == "suidhe" or word == "beidh" then
        phenomenon_comment = "Vocalized Fricative / Specific Diphthong"
    elseif word == "scadán" or word == "cailín" or word == "bacán" or word == "fuinneog" or word == "oileán" then
         phenomenon_comment = "Disyllabic Short-Long Raising"
    end


    generated_test_set_lua_string = generated_test_set_lua_string ..
        string.format("    {ortho=\"%s\", expected_ipa=\"%s\", dialect=\"connacht\", phenomenon=\"%s\"},\n",
                      escaped_ortho, escaped_ipa, phenomenon_comment)
end

-- Restore original print functions if they were modified
if original_transcriber_print then
    irishPhonetics.print = original_transcriber_print
end
if original_transcriber_debug_minimal then
    irishPhonetics.debug_print_minimal = original_transcriber_debug_minimal
end
_G.print = global_print_backup -- Restore global print

generated_test_set_lua_string = generated_test_set_lua_string .. "}\n\n"
generated_test_set_lua_string = generated_test_set_lua_string ..
[[
-- Example of how to run this test set:
-- function run_my_tests(test_data)
--     local failures = 0
--     local successes = 0
--     for i, test_case in ipairs(test_data) do
--         -- Assuming your transcriber is in a module called 'my_transcriber'
--         -- and has a function called 'transcribe'
--         local got_ipa = irishPhonetics.transcribe(test_case.ortho)
--         if got_ipa == test_case.expected_ipa then
--             successes = successes + 1
--             -- print(string.format("SUCCESS: %s -> Expected [%s], Got [%s]", test_case.ortho, test_case.expected_ipa, got_ipa))
--         else
--             failures = failures + 1
--             print(string.format("FAILURE: %s", test_case.ortho))
--             print(string.format("  Expected: [%s]", test_case.expected_ipa))
--             print(string.format("  Got:      [%s]", got_ipa))
--             print(string.format("  Phenom:   %s", test_case.phenomenon))
--         end
--     end
--     print(string.format("\nTest Summary: %d Successes, %d Failures", successes, failures))
-- end
--
-- run_my_tests(baseline_test_set)
]]
original_print_func = print
-- Print the generated Lua table to the console
original_print_func(generated_test_set_lua_string)

-- Optionally, write it to a file
local output_file_name = "baseline_test_set_generated.lua"
local file, err = io.open(output_file_name, "w")
if file then
    file:write(generated_test_set_lua_string)
    file:close()
    original_print_func("\nBaseline test set also written to: " .. output_file_name)
else
    original_print_func("\nERROR: Could not write baseline test set to file: " .. output_file_name .. " (" .. (err or "unknown error") .. ")")
end

if irishPhonetics.debug_file then -- Assuming your main script has this global
    irishPhonetics.debug_file:close()
    irishPhonetics.debug_file = nil -- Prevent main script from trying to close it again if run multiple times
end