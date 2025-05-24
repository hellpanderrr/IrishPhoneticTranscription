--[[
    Script to write Irish transcriptions to a file with proper UTF-8 encoding
    This script loads the Irish phonetics module, runs transcriptions,
    and writes the results to a file with proper encoding.
]]

local irishPhonetics = require("irish")

-- Words to transcribe
local words_to_test = {
    "leabhar", "bóthar", "oíche", "ainm", "fear", "glaic", "muc", "fliuch",
    "ceann", "poll", "bord", "samhradh", "fada", "beag", "séimhiú", "úrú",
    "Gaeltacht", "Conamara", "Gaeilge", "aoibhinn", "buí", "caol", "leathan",
    "fuinneog", "balla", "oiliúint", "staighre", "fios", "teanga", "dearg",
    "glas", "glaise", "fearg", "borb", "fhada", "a Sheáin", "laghad", 
    "an-mhaith", "deifir", "doras", "dubh", "nimh", "slán", "snámh",
    "uisce", "duine", "baile", "mícheart"
}

-- Open file for writing with UTF-8 encoding
local output_file = io.open("transcription_output.txt", "w")
if not output_file then
    print("Error: Could not open output file for writing")
    return
end

-- Write a UTF-8 BOM (Byte Order Mark) to help some text editors recognize the encoding
output_file:write("\239\187\191") -- UTF-8 BOM

-- Write header
output_file:write("Irish Phonetic Transcriptions\n")
output_file:write("==========================\n\n")

-- Process each word and write to file
for _, word in ipairs(words_to_test) do
    local original = word
    local transcribed = irishPhonetics.transcribe(original)
    
    -- Print to console for verification
    print(string.format("%-15s -> %s", original, transcribed))
    
    -- Write to file
    output_file:write(string.format("%-15s -> %s\n", original, transcribed))
end

-- Close the file
output_file:close()

print("\nTranscriptions have been written to 'transcription_output.txt'")
