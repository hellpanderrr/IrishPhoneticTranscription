-- Regenerate _benchmark.lua from _base.tsv expected values
local fi = io.open("_base.tsv", "r")
local fo = io.open("_benchmark.lua", "w")
fo:write("-- Auto-generated from _base.tsv expected values\n")
fo:write("return {\n")
for line in fi:lines() do
  -- Parse 5 tab-separated fields; field 3 is expected IPA (may contain commas)
  local word, got, expected, exact, lev = line:match("^(.-)\t(.-)\t(.-)\t(.-)\t(.-)$")
  if word and expected then
    -- Escape Lua string special chars in word
    local wesc = word:gsub("\\", "\\\\"):gsub('"', '\\"')
    local eesc = expected:gsub("\\", "\\\\"):gsub('"', '\\"')
    -- Remove stress marks for the expected field value
    fo:write(string.format('  ["%s"] = { expected = "%s", monolith = "" },\n', wesc, eesc))
  end
end
fi:close()
fo:write("}\n")
fo:close()
print("Generated _benchmark.lua")
