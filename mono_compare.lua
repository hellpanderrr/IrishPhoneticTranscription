-- Compare new engine vs monolith outputs
-- Set up Lua path to find old modules

package.path = "archive/?.lua;" .. (package.path or "")

local engine_new = require("irish_engine_new")
local monolith = require("archive.irish")

local function parse_csv(line)
  local fields = {}; local cur = {}; local inq = false
  for i = 1, #line do
    local c = line:sub(i,i)
    if c == [["]] then inq = not inq
    elseif c == "," and not inq then
      table.insert(fields, table.concat(cur)); cur = {}
    else table.insert(cur, c) end
  end
  table.insert(fields, table.concat(cur))
  return fields
end

-- Load word list
local f = io.open("data/connacht_only.csv", "r")
f:read()
local words = {}
for line in f:lines() do
  local fields = parse_csv(line)
  if #fields >= 3 then table.insert(words, fields[1]) end
end
f:close()

-- Run comparison
local diffs = {}
local errors_new, errors_mono = 0, 0
local safe = { __index = function() return "" end }

-- First quick test
local t_new = {}
local t_mono = {}
local errors_in_new, errors_in_mono = 0, 0

for _, word in ipairs(words) do
  local ok_n, ipa_n = pcall(engine_new.transcribe, word)
  local ok_m, ipa_m = pcall(monolith.transcribe, word)
  if not ok_n then errors_in_new = errors_in_new + 1; ipa_n = "ERROR" end
  if not ok_m then errors_in_mono = errors_in_mono + 1; ipa_m = "ERROR" end
  t_new[word] = ipa_n
  t_mono[word] = ipa_m
  if ipa_n ~= ipa_m then
    table.insert(diffs, { word = word, new = ipa_n, mono = ipa_m })
  end
end

print(string.format("Total words: %d", #words))
print(string.format("New engine errors: %d", errors_in_new))
print(string.format("Monolith errors: %d", errors_in_mono))
print(string.format("Diffs (NEW != MONO): %d", #diffs))
print()

-- Show diffs
if #diffs > 0 then
  print("=== SAMPLE DIFFERENCES ===")
  for i = 1, math.min(30, #diffs) do
    local d = diffs[i]
    print(string.format("  %-20s | NEW: %-30s | MONO: %s", d.word, d.new, d.mono))
  end
end
