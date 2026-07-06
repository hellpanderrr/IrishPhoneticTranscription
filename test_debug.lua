local e = require("irish_engine_new")
local passes = require("passes.init")
local S = require("passes._shared")

local word = "bíonn"
local tokens = e.tokenize_word(word)
local ctx = { word_ortho = word, dialect = "connacht" }

local all_passes = passes.passes
for i = 1, 16 do
    tokens = all_passes[i].run(tokens, ctx)
    if i <= 2 or i == 15 or i == 16 then
        print(string.format("=== After pass %02d (%s) ===", i, all_passes[i].name))
        for j, t in ipairs(tokens) do
            print(string.format("  [%d] ortho=%-6s type=%-6s phon=%-15s palatal=%s",
                j, t.ortho, t.type, t.phon or "(nil)", tostring(t.palatal)))
        end
    end
end

print("\nRendered: " .. e.transcribe(word, "connacht"))
