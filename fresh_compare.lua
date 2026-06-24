-- Generate fresh new_results.csv and compare to monolith results.csv
package.path = "archive/?.lua;" .. (package.path or "")

local engine_new = require("irish_engine_new")
local monolith = require("archive.irish")

local function parse_csv(line)
  local fields = {}; local cur = {}; local inq = false
  for i = 1, #line do
    local c = line:sub(i,i)
    if c == [["]] then inq = not inq
    elseif c == "," and not inq then table.insert(fields, table.concat(cur)); cur = {}
    else table.insert(cur, c) end
  end
  table.insert(fields, table.concat(cur))
  return fields
end

local function norm(s)
  if not s then return "" end
  return s:gsub("[ˈˌ\"]", "")
end

-- Levenshtein distance (byte-level, works for IPA)
local function lev(a, b)
  if a == b then return 0 end
  local m, n = #a, #b
  local d = {}
  for i = 0, m do d[i] = { [0] = i } end
  for j = 0, n do d[0][j] = j end
  for j = 1, n do
    for i = 1, m do
      d[i][j] = math.min(d[i-1][j] + 1, d[i][j-1] + 1, d[i-1][j-1] + (a:byte(i) == b:byte(j) and 0 or 1))
    end
  end
  return d[m][n]
end

local function match_new(expected, result)
  local nr = norm(result)
  -- Parse multi-variant expected (comma-separated with possible " quotes)
  local variants = {}
  local cur, inq = "", false
  for i = 1, #expected do
    local c = expected:sub(i, i)
    if c == [["]] then inq = not inq
    elseif c == "," and not inq then
      local trimmed = cur:match("^%s*(.-)%s*$")
      if trimmed and trimmed ~= "" then table.insert(variants, trimmed) end
      cur = ""
    else cur = cur .. c end
  end
  if cur ~= "" then
    local trimmed = cur:match("^%s*(.-)%s*$")
    if trimmed and trimmed ~= "" then table.insert(variants, trimmed) end
  end

  if #variants == 0 then return 0, 10 end

  local best = nil
  for _, v in ipairs(variants) do
    local nv = norm(v)
    if nr == nv then return 100, 0 end
    local d = lev(nr, nv)
    if best == nil or d < best then best = d end
  end
  return math.max(0, 100 - best * 5), best
end

-- Load connacht data
local f = io.open("data/connacht_only.csv", "r")
local header = f:read()
local entries = {}
for line in f:lines() do
  local fields = parse_csv(line)
  if #fields >= 3 then
    table.insert(entries, { word = fields[1], expected = fields[3] })
  end
end
f:close()

-- Run engines
local total, new_exact, new_lev, mono_exact, mono_lev = 0, 0, 0, 0, 0
local regressions = {}

for _, e in ipairs(entries) do
  local w = e.word

  local ok_n, ipa_n = pcall(engine_new.transcribe, w)
  if not ok_n then ipa_n = "ERROR" end

  local ok_m, ipa_m = pcall(monolith.transcribe, w)
  if not ok_m then ipa_m = "ERROR" end

  total = total + 1

  local nmatch, ndist = match_new(e.expected or "", ipa_n)
  local mmatch, mdist = match_new(e.expected or "", ipa_m)

  if nmatch == 100 then new_exact = new_exact + 1 end
  if mmatch == 100 then mono_exact = mono_exact + 1 end

  new_lev = new_lev + ndist
  mono_lev = mono_lev + mdist

  if mmatch == 100 and nmatch < 100 then
    table.insert(regressions, { word = w, new = ipa_n, mono = ipa_m, expected = e.expected, ndist = ndist })
  end
end

print(string.format("=== BENCHMARK ==="))
print(string.format("Total: %d", total))
print(string.format("New engine exact: %d/%d (%.2f%%)", new_exact, total, new_exact/total*100))
print(string.format("Monolith exact: %d/%d (%.2f%%)", mono_exact, total, mono_exact/total*100))
print(string.format("New avg Lev dist: %.2f", new_lev/total))
print(string.format("Mono avg Lev dist: %.2f", mono_lev/total))
print()

-- Filter to real words (no suffix entries)
local real_total, real_new_exact, real_mono_exact = 0, 0, 0
local real_regressions = {}
for _, e in ipairs(entries) do
  local w = e.word
  if w:match("^[%-\x27]") then goto skip end
  real_total = real_total + 1

  local ok_n, ipa_n = pcall(engine_new.transcribe, w)
  if not ok_n then ipa_n = "ERROR" end
  local ok_m, ipa_m = pcall(monolith.transcribe, w)
  if not ok_m then ipa_m = "ERROR" end

  local nmatch = match_new(e.expected, ipa_n)
  local mmatch = match_new(e.expected, ipa_m)
  if nmatch == 100 then real_new_exact = real_new_exact + 1 end
  if mmatch == 100 then real_mono_exact = real_mono_exact + 1 end
  if mmatch == 100 and nmatch < 100 then
    table.insert(real_regressions, { word = w, new = ipa_n, mono = ipa_m, expected = e.expected })
  end
  ::skip::
end

print(string.format("=== REAL WORDS ==="))
print(string.format("Total: %d", real_total))
print(string.format("New engine exact: %d/%d (%.2f%%)", real_new_exact, real_total, real_new_exact/real_total*100))
print(string.format("Monolith exact: %d/%d (%.2f%%)", real_mono_exact, real_total, real_mono_exact/real_total*100))
print(string.format("Regressions (mono right, new wrong): %d", #real_regressions))
print()

-- Analyze regressions: stress
local stress_regs = {}
for _, r in ipairs(real_regressions) do
  local has_n = r.new:find("ˈ") or r.new:find("ˌ")
  local has_m = r.mono:find("ˈ") or r.mono:find("ˌ")
  if has_m and not has_n then
    table.insert(stress_regs, r)
  end
end
print(string.format("Regressions where mono has stress but new doesn't: %d/%d", #stress_regs, #real_regressions))

-- Show top regressions by Lev distance
table.sort(real_regressions, function(a,b) return a.ndist > b.ndist end)
print(string.format("\n=== TOP 30 REGRESSIONS BY LEV DISTANCE ==="))
for i = 1, math.min(30, #real_regressions) do
  local r = real_regressions[i]
  print(string.format("  %-20s NEW: %-35s MONO: %s", r.word, r.new, r.mono))
end
