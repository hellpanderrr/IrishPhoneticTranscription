-- run_irish_tests.lua
old_print = print

-- Attempt to load the phonetics module
local phonetics_module_name = "irish"
local status, irishPhonetics = pcall(require, phonetics_module_name)

if not status then
    print("ERROR: Could not load the phonetics module: " .. phonetics_module_name)
    print("Ensure it is in the same directory or Lua's package.path is set correctly.")
    print("Details: " .. tostring(irishPhonetics)) -- irishPhonetics will contain the error message here
    os.exit(1)
end

print("Successfully loaded phonetics module: " .. phonetics_module_name)

-- Define test cases: {orthographic_word, expected_ipa, optional_comment}
-- Add Connacht-specific targets where known.
local test_cases = {
    -- Strong Sonorants - Broad (Connacht Targets)
    {"ceann", "ˈkʲɑːnˠ"}, -- Target: k'ɑːN -> cɑːnˠ
    {"am", "ˈɑːm"},     -- Target: ˈɑːm
    {"fonn", "ˈfʊnˠ"},   -- Target: fuːN -> fʊnˠ (Connacht /uː/ often [ʊ])
    {"poll", "ˈpʊlˠ"},   -- Target: puːL -> pʊlˠ
    {"trom", "ˈt̪ɾˠʊmˠ"}, -- Target: trɔm -> t̪ɾˠuːmˠ -> t̪ɾˠʊmˠ (CPart issue was known for complex clusters)
    {"corr", "ˈkoːɾˠ"},   -- Target: koːR -> koːɾˠ
    {"bord", "ˈbˠoːɾˠd̪ˠ"}, -- Target: boːRd -> bˠoːɾˠd̪ˠ
    {"tallann", "ˈt̪ɑl̪ˠənˠ"}, -- Polysyllabic, first vowel should not lengthen
    {"seanchas", "ˈʃanˠəxəsˠ"}, -- Polysyllabic

    -- Strong Sonorants - Palatal (Connacht Targets)
    {"im", "ˈiːmʲ"},      -- Target: ˈiːm' -> ˈiːmʲ
    {"roinnt", "ˈɾˠəin̠ʲtʲ"},-- Target: rəiN't' -> ɾˠəin̠ʲtʲ
    {"caill", "ˈkɑːlʲ"},   -- Target: k'ɑːL' -> kɑːlʲ
    {"coill", "ˈkəilʲ"},   -- Target: kəiL' -> kəilʲ
    {"poinn", "ˈpəinʲ"},   -- Target: pəiN' -> pəinʲ
    {"cill", "ˈkʲiːlʲ"},    -- Target: k'iːL' -> kʲiːlʲ
    {"bainne", "ˈbˠanʲə"}, -- Polysyllabic, no lengthening

    -- Vocalized Fricatives (Connacht Targets where specific)
    {"leabhar", "ˈlʲəuɾˠ"}, -- Target: leəur -> lʲəuɾˠ
    {"amhrán", "ˈəuɾˠɑːnˠ"}, -- Target: əurrɑːn -> əuɾˠɑːnˠ (assuming amh -> əu)
    {"samhradh", "ˈsˠəuɾˠə"}, -- Target: səurrə -> sˠəuɾˠə
    {"slaghdán", "ˈsləid̪ˠɑːnˠ"}, -- Target: sləidɑːn -> sləid̪ˠɑːnˠ
    {"adhradh", "ˈəiɾˠə"},   -- Target: əirə -> əiɾˠə
    {"laghadh", "ˈləiə"},    -- Target: ləiə
    {"feabhas", "ˈfʲəusˠ"},  -- Target: f'eəəs -> fʲəusˠ (ea+bh usually əu)
    {"ghabh", "ˈɣəu"},     -- Target: ɣəu
    {"damhsa", "ˈd̪ˠəusˠə"}, -- Target: dəusə -> d̪ˠəusˠə
    {"deifir", "ˈdʲefʲəɾʲ"}, -- Target: d'ef'ir' -> dʲefʲəɾʲ
    {"nimhe", "ˈnʲiː"},    -- Target: niː (final e reduces)
    {"suidhe", "ˈsiː"},    -- Target: siː (final e reduces)
    {"beidh", "ˈbʲai"},     -- Target: b'ai -> bʲai
    {"lae", "ˈl̪ˠeː"},       -- Target: leː -> l̪ˠeː

    -- Previous test cases that were working, for regression
    {"fear", "ˈfʲaɾˠ"},
    {"cat", "ˈkat̪ˠ"},
    {"bord", "ˈbˠoːɾˠd̪ˠ"}, -- Repeated for strong sonorant context
    {"uisce", "ˈɪʃcə"},
    {"Gaeltacht", "ˈɡeːl̪ˠt̪ˠəxt̪ˠ"},
    {"Conamara", "ˌkʊn̪ˠəˈmaɾˠə"}, -- Stress pattern
    {"sláinte", "ˈsl̪ˠɑːn̠ʲtʲə"},
    {"oíche", "ˈiːə"}, -- Connacht often iə not iːhə
    {"aoibhinn", "ˈiːvʲən̠ʲ"},
    {"fuinneog", "ˈfˠɪn̠ʲoːɡ"},
    {"staighre", "ˈst̪ˠaiɾʲə"},
    {"dearmad", "ˈdʲaɾˠəmˠəd̪ˠ"},
    {"bean", "ˈbʲanˠ"}, -- Connacht often broad 'n'
    {"baile", "ˈbˠalʲə"},
    {"bacach", "ˈbˠakəx"},
    {"athair", "ˈahəɾʲ"}, -- Connacht can be 'æɾʲ' or 'ɑːɾʲ' in Cois Fharraige
    {"máthair", "ˈmˠɑːhəɾʲ"},
    {"deirfiúr", "ˈdʲɾʲɛhuːɾˠ"}, -- West Connacht
    {"obair", "ˈɔbˠəɾʲ"},
    {"eolas", "ˈoːl̪ˠəsˠ"},
    {"cnoc", "ˈkɾˠʊk"}, -- common Connacht kruk
    {"gnó", "ˈɡɾˠn̪ˠoː"}, -- common Connacht grnó
    {"mná", "ˈmˠɾˠɑː"},
    {"trá", "ˈt̪ɾˠɑː"},

    -- Edge cases or more complex words
    {"comharsan", "ˈkoːəɾˠsənˠ"}, -- Check unstressed vowel reduction
    {"cruinniú", "ˈkɾˠɪn̠ʲuː"},
    {"urlár", "ˈʊɾˠl̪ˠɑːɾˠ"},
    {"ceantar", "ˈkʲan̪ˠt̪ˠəɾˠ"},
    {"fiche", "ˈfʲɪhə"}, -- General target
    {"fiche", "ˈfʲiː"}, -- Cois Fharraige variant (illustrative, main script might not do this yet)
    {"leagan", "ˈl̠ʲaɡənˠ"}, -- Mayo/West Connacht general
    {"leagan", "ˈl̠ʲæːɡən̪ˠ"}, -- Cois Fharraige (illustrative)
    {"teanga", "ˈtʲaŋə"}, -- Aran/Kerry, but common Connacht too
    {"teanga", "ˈtʲæːŋɡə"}, -- Cois Fharraige (illustrative)

    -- Words from the original list that caused issues or have interesting features
    {"bindealán", "ˈbʲin̠ʲdʲəlˠɑːnˠ"}, -- Stress on second long vowel
    {"tarraing", "ˈt̪ˠaɾˠən̠ʲ"}, -- Epenthesis target if monosyllabic, but it's not.
    {"oibre", "ˈaibʲɾʲə"}, -- Diphthongization of oi
    {"mainicín", "ˈmˠanʲɪkʲiːnʲ"},
    {"amhras", "ˈəuɾˠəsˠ"}, -- amh -> əu
    {"urlár", "ˈʊɾˠl̪ˠɑːɾˠ"}, -- Strong R
    {"cnámha", "ˈknˠɑːvˠ"}, -- Broad mh vocalization
    {"ghaiscígh", "ˈɣaʃkʲiː"},
    {"cliabhán", "ˈclʲiəwɑːnˠ"}, -- bh vocalization to w (Connacht tendency)
    {"láidir", "ˈl̪ˠɑːdʲəɾʲ"},
    {"abhainn", "ˈəun̠ʲ"}, -- Broad bh vocalization
    {"geimhreadh", "ˈɟĩvʲɾʲu"}, -- Connacht `ea` -> `i` before slender
    {"cluife", "ˈklˠɪfʲə"},
    {"bualadh", "ˈbˠuəl̪ˠə"},

    -- Test words that revealed issues in 37DJ
    {"nimhe", "ˈnʲiː"}, -- Expected after vocalization and reduction
    {"suidhe", "ˈsiː"}, -- Expected after vocalization and reduction
}

local passed_count = 0
local failed_count = 0
local total_tests = #test_cases

print("\n--- Running Regression Test Suite (" .. total_tests .. " cases) ---")
print("----------------------------------------------------")
-- Temporarily disable debug prints from the phonetics module for cleaner test output
local original_phonetics_print = irishPhonetics.original_print_func -- Assuming your module has this
local original_minimal_debug = true -- Assuming this global exists
local original_stage_debug = {}
if irishPhonetics.STAGE_DEBUG_ENABLED then -- Check if it exists
    for k,v in pairs(irishPhonetics.STAGE_DEBUG_ENABLED) do original_stage_debug[k] = v end
    for k,_ in pairs(irishPhonetics.STAGE_DEBUG_ENABLED) do irishPhonetics.STAGE_DEBUG_ENABLED[k] = false end
end
if original_phonetics_print then
    irishPhonetics.print = function() end
end
if original_minimal_debug ~= nil then
    irishPhonetics.MINIMAL_DEBUG_ENABLED = true -- Force minimal during tests
end


for i, test_data in ipairs(test_cases) do
    local orth = test_data[1]
    local expected_ipa = test_data[2]
    local comment = test_data[3] or ""

    local actual_ipa = irishPhonetics.transcribe(orth)

    if actual_ipa == expected_ipa then
        passed_count = passed_count + 1
        old_print(string.format("[PASS] %-20s -> Expected: [%-25s] Got: [%s]", orth, expected_ipa, actual_ipa))
    else
        failed_count = failed_count + 1
        old_print(string.format("[FAIL] %-20s -> Expected: [%-25s] Got: [%s] %s", orth, expected_ipa, actual_ipa, comment))
    end
end

-- Restore debug prints
if original_phonetics_print then
    irishPhonetics.print = original_phonetics_print
end
if original_minimal_debug ~= nil then
    irishPhonetics.MINIMAL_DEBUG_ENABLED = original_minimal_debug
end
if irishPhonetics.STAGE_DEBUG_ENABLED then
    for k,v in pairs(original_stage_debug) do irishPhonetics.STAGE_DEBUG_ENABLED[k] = v end
end


old_print("----------------------------------------------------")
old_print(string.format("Tests Completed. Passed: %d, Failed: %d, Total: %d", passed_count, failed_count, total_tests))
old_print("----------------------------------------------------")

if failed_count > 0 then
    old_print("\n SOME TESTS FAILED.")
    -- os.exit(1) -- Optionally exit with error code if tests fail
else
    old_print("\n ALL TESTS PASSED.")
end