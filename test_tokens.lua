local e = require("irish_engine_new")

-- Test words with -íonn suffix
local words = {"bíonn", "chíonn", "níonn", "luíonn", "suíonn", "áitíonn", "-íonn", "bainne", "sloinne"}
for _, w in ipairs(words) do
    local tokens = e.tokenize_word(w)
    print("--- " .. w .. " ---")
    for i, t in ipairs(tokens) do
        local pal = "broad"
        if t.palatal then pal = "slender" end
        local phon = t.phon or "(nil)"
        print(string.format("  [%d] ortho=%-6s type=%-6s phon=%-10s pal=%s",
            i, t.ortho, t.type, phon, pal))
    end
    local result = e.transcribe(w, "connacht")
    print("  => " .. result)
    print()
end
