-- Compare sonorant symbols between engine and expected
local engine = require("irish_engine_new")
local bm = dofile("_benchmark.lua")

-- Extract all sonorant tokens with diacritics from an IPA string
local function extract_sonorants(ipa)
  local results = {}
  local i = 1
  while i <= #ipa do
    local b = ipa:byte(i)
    -- n, l, r (ASCII)
    if b == 110 or b == 108 or b == 114 then
      local base = string.char(b)
      local j = i + 1
      -- Collect combining diacritics (UTF-8 sequences starting with 0xCC or 0xCD)
      while j <= #ipa do
        local d = ipa:byte(j)
        if d == 0xCC or d == 0xCD then
          j = j + 2 -- skip combining char (2 bytes)
        else
          break
        end
      end
      local full = ipa:sub(i, j - 1)
      results[#results + 1] = full
      i = j
    else
      i = i + 1
    end
  end
  return results
end

-- Count sonorant types
local eng_counts = {}
local exp_counts = {}
local pair_counts = {}
local diff_words = 0
local total = 0

for w, data in pairs(bm) do
  total = total + 1
  local ok, actual = pcall(engine.transcribe, w)
  if ok then
    local eng_son = extract_sonorants(actual)
    local exp_son = extract_sonorants(data.expected)
    local function normalize(s) return s:gsub("ː", "") end
    local eng_norm = {}
    for _, s in ipairs(eng_son) do eng_norm[#eng_norm+1] = normalize(s) end
    local exp_norm = {}
    for _, s in ipairs(exp_son) do exp_norm[#exp_norm+1] = normalize(s) end

    for _, s in ipairs(eng_norm) do eng_counts[s] = (eng_counts[s] or 0) + 1 end
    for _, s in ipairs(exp_norm) do exp_counts[s] = (exp_counts[s] or 0) + 1 end

    local differs = false
    if #eng_norm ~= #exp_norm then differs = true
    else
      for i = 1, #eng_norm do
        if eng_norm[i] ~= exp_norm[i] then differs = true; break end
      end
    end
    if differs then
      diff_words = diff_words + 1
      for i = 1, math.max(#eng_norm, #exp_norm) do
        local e = eng_norm[i] or "-"
        local x = exp_norm[i] or "-"
        if e ~= x then
          local key = e .. " -> " .. x
          pair_counts[key] = (pair_counts[key] or 0) + 1
        end
      end
    end
  end
end

print(string.format("Total: %d, Words with sonorant diff: %d", total, diff_words))
print()
print("Engine sonorant counts:")
local se = {}; for s, c in pairs(eng_counts) do se[#se+1] = {s=s, c=c} end
table.sort(se, function(a,b) return a.c > b.c end)
for _, e in ipairs(se) do print(string.format("  %-12s %5d", e.s, e.c)) end

print()
print("Expected sonorant counts:")
local sx = {}; for s, c in pairs(exp_counts) do sx[#sx+1] = {s=s, c=c} end
table.sort(sx, function(a,b) return a.c > b.c end)
for _, e in ipairs(sx) do print(string.format("  %-12s %5d", e.s, e.c)) end

print()
print("Top mismatched pairs (engine -> expected):")
local sp = {}; for s, c in pairs(pair_counts) do sp[#sp+1] = {s=s, c=c} end
table.sort(sp, function(a,b) return a.c > b.c end)
for i = 1, math.min(30, #sp) do print(string.format("  %-30s %5d", sp[i].s, sp[i].c)) end
