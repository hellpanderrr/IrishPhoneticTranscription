-- New script to capture terminal output with proper encoding
local function run_with_capture()
    -- Set up UTF-8 output file
    local output_file = io.open("captured_output.txt", "wb") -- Binary mode
    output_file:write("\239\187\191") -- UTF-8 BOM
    
    -- Save original print function
    local original_print = _G.print
    
    -- Override global print to write to both console and file
    _G.print = function(...)
        local args = {...}
        local str_args = {}
        for i, v in ipairs(args) do
            str_args[i] = tostring(v)
        end
        local msg = table.concat(str_args, "\t")
        
        -- Print to console
        original_print(msg)
        
        -- Write to file
        output_file:write(msg .. "\r\n")
        output_file:flush()
    end
    
    -- Now load the Irish module (after print is overridden)
    local irish = require("irish")
    
    -- Run the test words
    print("--- Running Test Set with Captured Output ---")
    local words_to_test = {
        "fhéach", "teach", "deartháir", "cat", "bord", "ceann", "poll",
        "leabhar", "samhradh", "beannacht", "fonn", "leagan", "teanga", "seacht"
    }
    
    for _, word in ipairs(words_to_test) do
        local transcribed = irish.transcribe(word)
        print(string.format("%-15s -> [%s]", word, transcribed))
    end
    
    -- Restore original print function
    _G.print = original_print
    
    -- Close the file
    output_file:close()
    print("Output captured to captured_output.txt")
end

-- Run the function
run_with_capture()

