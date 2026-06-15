-- irish_main.lua
-- Main module entrypoint and CLI runner.

local core = require("irish_core")
local rules = require("irish_rules")
local processors = require("irish_processors")
local engine = require("irish_engine")

local N = core.N
local ulen = core.ulen
local usub = core.usub
local ufind = core.ufind
local umatch = core.umatch
local ugsub = core.ugsub

local irishPhonetics = {}

-- Forward public APIs
irishPhonetics.transcribe = engine.transcribe
irishPhonetics.transcribe_single_word = engine.transcribe_single_word

-- Metatable to transparently forward read/writes to appropriate sub-modules
setmetatable(irishPhonetics, {
    __index = function(_, key)
        return engine[key] or core[key] or rules[key] or processors[key]
    end,
    __newindex = function(_, key, value)
        if engine[key] ~= nil then
            engine[key] = value
        elseif rules[key] ~= nil then
            rules[key] = value
        elseif processors[key] ~= nil then
            processors[key] = value
        else
            core[key] = value
        end
    end
})

-- Determine if required as a module or executed directly
local is_required = false
local file_args = {...}
if #file_args > 0 and type(file_args[1]) == "string" and (file_args[1]:match("irish_main") or package.loaded[file_args[1]]) then
    is_required = true
end

-- If executed directly (not required), run command-line interface or default tests
if not is_required then
    local RUN_DEFAULT_TESTS_IF_NO_INPUT = true

    -- Check for command-line argument first
    local input = arg[1]
    if arg[1] ~= "--d" then
        input = arg[1]
    else
        input = nil
    end
    local showDebug = arg[2] == "--d" or arg[1] == "--d"
    if showDebug then
        core.MINIMAL_DEBUG_ENABLED = true
    else
        core.MINIMAL_DEBUG_ENABLED = false
    end

    local original_print = print
    print = function(...)
        local msg = table.concat({ ... }, "\t")
        original_print(msg)
        if core.debug_file then
            if msg:match("^%-%-%- Transcribing:") or msg:match("^%-*%s*-> %[%s*%S") or
                (core.MINIMAL_DEBUG_ENABLED and msg:match("^    MIN_DBG")) or
                msg:match("^PERF:") then
                core.debug_file:write(msg .. "\n");
                core.debug_file:flush()
            elseif not core.MINIMAL_DEBUG_ENABLED then
                core.debug_file:write(msg .. "\n");
                core.debug_file:flush()
            end
        end
    end

    -- Debug Flags
    if core.MINIMAL_DEBUG_ENABLED then
        local debug_file_path = "irish_debug_43_lua_p_strict.txt"
        core.debug_file = io.open(debug_file_path, "w")
        if core.debug_file then
            core.debug_file:write("\239\187\191")
        else
            original_print("WARN: Could not open debug_file " .. debug_file_path)
        end
        core.STAGE_DEBUG_ENABLED = {
            PreProcess = false,
            MarkDigraphsAndVocalisationTriggers = true,
            Stage2_5_MarkSuffixes = true,
            Stage3_1_MarkerResolution = true,
            ConsonantResolution = true,
            Stage3_2_ApplyStress = true,
            Stage4_0_SpecificOrthoToTempMarker = true,
            Stage4_0_1_Resolve_CH_Marker = true,
            Stage4_1_VocmarkToTempMarker = true,
            Stage4_2_LongVowelsOrthoToTempMarker = true,
            Stage4_3_DiphthongsOrthoToTempMarker = true,
            Stage4_4_ResolveTempVowelMarkers = true,
            Stage4_4_1_VocalizeLenitedFricatives = true,
            Stage4_5_ContextualAllophonyOnPhonetic = true,
            Stage4_5_1_DisyllabicShortLongRaising = true,
            Stage4_5_2_ConnachtSpecificVowelShifts = true,
            Nasalization = true,
            Stage4_6_UnstressedVowelReduction_Procedural = true,
            EpenthesisAndStrongSonorants = true,
            Diacritics = true,
            FinalCleanup = true,
            Parser = false,
            ParserSetup = false,
            LexicalLookup = false,
            Performance = false
        }
    else
        core.STAGE_DEBUG_ENABLED = {
            PreProcess = false,
            MarkDigraphsAndVocalisationTriggers = false,
            Stage2_5_MarkSuffixes = false,
            ConsonantResolution = false,
            Stage4_0_SpecificOrthoToTempMarker = false,
            Stage4_0_1_Resolve_CH_Marker = false,
            Stage4_1_VocmarkToTempMarker = false,
            Stage4_2_LongVowelsOrthoToTempMarker = false,
            Stage4_3_DiphthongsOrthoToTempMarker = false,
            Stage4_4_ResolveTempVowelMarkers = false,
            Stage4_4_1_VocalizeLenitedFricatives = false,
            Stage4_5_ContextualAllophonyOnPhonetic = false,
            Stage4_5_1_DisyllabicShortLongRaising = false,
            Stage4_5_2_ConnachtSpecificVowelShifts = false,
            Nasalization = false,
            Stage4_6_UnstressedVowelReduction_Procedural = false,
            EpenthesisAndStrongSonorants = false,
            Diacritics = false,
            FinalCleanup = false,
            Parser = false,
            ParserSetup = false,
            LexicalLookup = false,
            Performance = false
        }
    end

    if not input then
        if io.stdin:seek("end") then
            io.stdin:seek("set")
            input = io.read("*a")
        end
    end

    if input then
        original_print(irishPhonetics.transcribe(N(input)))
    else
        if RUN_DEFAULT_TESTS_IF_NO_INPUT then
            local words_to_test_focused_from_errors = {"sheol","thug","shúil","Sheáin","théigh","a theach","chugham","Eoghan","Laoghaire","beirbhiughadh","láimh","comhairle","chnáimh","ghníomh","tnúth","Tadhg","comhartha","Airméanach","mairbh","cailc","feirm","íocfaidh","abhaile","ailm","mairc","dearg","Iúr","Toirdhealbhach","suaimhneas","ríomhleabhar","lonnaithe",}
            original_print("\n--- Running Default Test Set (No Input Provided) ---")
            if core.debug_file then
                core.debug_file:write("\n--- Running Default Test Set (No Input Provided) ---\n")
            end

            core.STAGE_DEBUG_ENABLED.Parser = false
            core.STAGE_DEBUG_ENABLED.ParserSetup = false

            for _, word_or_phrase in ipairs(words_to_test_focused_from_errors) do
                local original = word_or_phrase
                original_print("\n--- Transcribing:", original, "---")
                if core.debug_file then
                    core.debug_file:write(string.format("\n--- Transcribing: %s ---\n", original))
                end
                local transcribed = irishPhonetics.transcribe(original)
                original_print(string.format("%-30s -> [%s]", original, transcribed))
                if core.debug_file then
                    core.debug_file:write(string.format("%-30s -> [%s]\n", original, transcribed))
                end
            end
        else
            original_print("No input provided. To run tests, set RUN_DEFAULT_TESTS_IF_NO_INPUT to true.")
            original_print("Usage: lua your_script.lua \"text to transcribe\"")
            original_print("   or: echo \"text to transcribe\" | lua your_script.lua")
        end
    end
end

return irishPhonetics
