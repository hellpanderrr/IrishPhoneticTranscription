-- Compare new engine vs monolith on REAL words only (no suffix entries)

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
local entries = {}
for line in f:lines() do
  local fields = parse_csv(line)
  if #fields >= 3 then table.insert(entries, { word = fields[1], expected = fields[3] }) end
end
f:close()

-- Filter to real words (no suffix entries starting with - or ')
local real_words = {}
for _, e in ipairs(entries) do
  local w = e.word
  if w:match("^[%-\x27]") then goto skip end
  table.insert(real_words, e)
  ::skip::
end

print(string.format("Real words: %d", #real_words))

-- Compare
local diffs = {}
for _, e in ipairs(real_words) do
  local word = e.word
  local ok_n, ipa_n = pcall(engine_new.transcribe, word)
  local ok_m, ipa_m = pcall(monolith.transcribe, word)
  if not ok_n then ipa_n = "ERROR" end
  if not ok_m then ipa_m = "ERROR" end
  if ipa_n ~= ipa_m then
    table.insert(diffs, { word = word, new = ipa_n, mono = ipa_m, expected = e.expected })
  end
end

print(string.format("Diffs: %d (%.1f%%)", #diffs, #diffs/#real_words*100))
print()

-- Show sample diffs
print("=== WORDS WHERE NEW != MONO ===")
for i = 1, math.min(40, #diffs) do
  local d = diffs[i]
  print(string.format("%-25s | NEW: %-30s | MONO: %s", d.word, d.new, d.mono))
end
print()
print(string.format("... and %d more differences", #diffs - 40))
