-- Reusable benchmark harness for the Irish G2P engine.
-- Usage: lua bench_run.lua [label]
-- Prints exact match count/percentage and average + normalized Levenshtein.
-- Optionally writes per-word results to a file given as second arg.
--
-- The benchmark dictionary is _benchmark.lua: keys are words, values have
-- `expected` (comma-separated IPA variants) and `monolith` fields.

local engine = require("irish_engine_new")
local bench = require("_benchmark")
local ustring = require("ustring.ustring")
local ulen = ustring.len
local usub = ustring.sub

local function trim(s) return s:match("^%s*(.-)%s*$") end

-- Expand parenthetical optional elements into multiple variants.
-- "mʲa(h)" -> {"mʲa", "mʲah"}
local function expand_variant(s)
  local results = {""}
  local i = 1
  while i <= #s do
    if s:sub(i, i) == "(" then
      local close = s:find(")", i, true)
      if close then
        local inner = s:sub(i + 1, close - 1)
        local new = {}
        for _, r in ipairs(results) do
          table.insert(new, r .. inner)
          table.insert(new, r)
        end
        results = new
        i = close + 1
      else
        for j, r in ipairs(results) do results[j] = r .. s:sub(i, i) end
        i = i + 1
      end
    else
      for j, r in ipairs(results) do results[j] = r .. s:sub(i, i) end
      i = i + 1
    end
  end
  return results
end

local function levenshtein(s1, s2)
  if not s1 or not s2 then return 999, 1 end
  local m, n = ulen(s1), ulen(s2)
  if m == 0 then return n, math.max(n, 1) end
  if n == 0 then return m, math.max(m, 1) end
  local v0, v1 = {}, {}
  for i = 0, n do v0[i] = i end
  for i = 1, m do
    v1[0] = i
    for j = 1, n do
      local a, b = usub(s1, i, i), usub(s2, j, j)
      local c = (a == b) and 0 or 1
      v1[j] = math.min(v1[j - 1] + 1, v0[j] + 1, v0[j - 1] + c)
    end
    for j = 0, n do v0[j] = v1[j] end
  end
  return v1[n], math.max(m, n)
end

-- Simple Dolgopolsky equivalence classes for IPA
local DOLGO_MAP = {
  ["i"] = "i", ["iː"] = "i", ["ɪ"] = "i",
  ["e"] = "e", ["eː"] = "e", ["ɛ"] = "e", ["ɛː"] = "e",
  ["a"] = "a", ["aː"] = "a", ["æ"] = "a", ["æː"] = "a",
  ["ə"] = "ə",
  ["o"] = "o", ["oː"] = "o", ["ɔ"] = "o", ["ɔː"] = "o",
  ["u"] = "u", ["uː"] = "u", ["ʊ"] = "u", ["ɤ"] = "u",
  ["ʌ"] = "a",
  ["p"] = "p", ["b"] = "b", ["t"] = "t", ["d"] = "d",
  ["k"] = "k", ["ɡ"] = "g", ["g"] = "g", ["c"] = "k", ["ɟ"] = "g",
  ["f"] = "f", ["v"] = "v", ["s"] = "s", ["z"] = "z",
  ["ʃ"] = "s", ["ʒ"] = "z", ["ç"] = "x", ["x"] = "x",
  ["ɣ"] = "g", ["h"] = "h", ["ɦ"] = "h",
  ["m"] = "m", ["n"] = "n", ["ɲ"] = "n", ["ŋ"] = "n",
  ["l"] = "l", ["ʎ"] = "l", ["r"] = "r", ["ɾ"] = "r",
  ["j"] = "j", ["w"] = "w",
  ["ʷ"] = "", ["ʲ"] = "", ["ˠ"] = "", ["̪"] = "", ["̠"] = "",
  ["ˈ"] = "", [","] = "", ["."] = "", [" "] = "",
}

local function dolgo_tokenize(s)
  local tokens = {}
  local i = 1
  local len = ulen(s)
  while i <= len do
    local ch = usub(s, i, i)
    local next_ch = (i < len) and usub(s, i + 1, i + 1) or ""
    if next_ch == "ː" then
      local digraph = ch .. "ː"
      local mapped = DOLGO_MAP[digraph]
      if mapped then
        if mapped ~= "" then table.insert(tokens, mapped) end
        i = i + 2
      else
        local mapped_ch = DOLGO_MAP[ch]
        if mapped_ch and mapped_ch ~= "" then table.insert(tokens, mapped_ch) end
        i = i + 1
      end
    else
      local mapped = DOLGO_MAP[ch]
      if mapped then
        if mapped ~= "" then table.insert(tokens, mapped) end
      else
        table.insert(tokens, ch)
      end
      i = i + 1
    end
  end
  return tokens
end

local function dolgo_distance(s1, s2)
  local t1, t2 = dolgo_tokenize(s1), dolgo_tokenize(s2)
  local m, n = #t1, #t2
  if m == 0 and n == 0 then return 0 end
  local v0, v1 = {}, {}
  for i = 0, n do v0[i] = i end
  for i = 1, m do
    v1[0] = i
    for j = 1, n do
      local c = (t1[i] == t2[j]) and 0 or 1
      v1[j] = math.min(v1[j - 1] + 1, v0[j] + 1, v0[j - 1] + c)
    end
    for j = 0, n do v0[j] = v1[j] end
  end
  local maxlen = math.max(m, n)
  if maxlen == 0 then return 0 end
  return (v1[n] or 0) / maxlen
end

local exact, total, total_lev, total_norm_lev, total_dolgo, total_norm_dolgo = 0, 0, 0, 0, 0, 0
local out_file = io.open("data/results.csv", "w")
local err_file = io.open("data/errors.csv", "w")
if out_file then out_file:write("word\tgot\texpected\texact\tlev\tlev_norm\tdolgo\tdolgo_norm\n") end
if err_file then err_file:write("word\tgot\texpected\tlev\tlev_norm\tdolgo\tdolgo_norm\n") end

for word, entry in pairs(bench) do
  local got = engine.transcribe(word, "connacht")
  total = total + 1
  local variants = {}
  for v in entry.expected:gmatch("[^,]+") do
    -- Split on ~ for dialect variants (e.g. "a ~ b" → two variants)
    for side in v:gmatch("[^~]+") do
      local trimmed = trim(side)
      if trimmed ~= "" then
        local expanded = expand_variant(trimmed)
        for _, ev in ipairs(expanded) do
          table.insert(variants, ev)
        end
      end
    end
  end
  local best_lev, best_exp, best_dolgo, best_norm_lev, best_norm_dolgo = nil, nil, nil, nil, nil
  for _, ev in ipairs(variants) do
    local lev, maxlen = levenshtein(got, ev)
    local dolgo = dolgo_distance(got, ev)
    if best_lev == nil or lev < best_lev then
      best_lev, best_exp, best_dolgo = lev, ev, dolgo
      best_norm_lev = (maxlen > 0) and ((1 - lev / maxlen) * 100) or 100
      best_norm_dolgo = (1 - dolgo) * 100
    end
  end
  if best_lev == nil then best_lev, best_exp, best_dolgo, best_norm_lev, best_norm_dolgo = 999, "", 1, 0, 0 end
  total_lev = total_lev + best_lev
  total_norm_lev = total_norm_lev + best_norm_lev
  total_dolgo = total_dolgo + best_dolgo
  total_norm_dolgo = total_norm_dolgo + best_norm_dolgo
  if got == best_exp then exact = exact + 1 end
  if out_file then
    out_file:write(word .. "\t" .. got .. "\t" .. best_exp .. "\t" ..
      tostring(got == best_exp) .. "\t" .. best_lev .. "\t" .. string.format("%.2f", best_norm_lev) .. "\t" .. string.format("%.4f", best_dolgo) .. "\t" .. string.format("%.2f", best_norm_dolgo) .. "\n")
  end
  if err_file and got ~= best_exp then
    err_file:write(word .. "\t" .. got .. "\t" .. best_exp .. "\t" .. best_lev .. "\t" .. string.format("%.2f", best_norm_lev) .. "\t" .. string.format("%.4f", best_dolgo) .. "\t" .. string.format("%.2f", best_norm_dolgo) .. "\n")
  end
end
if out_file then out_file:close() end
if err_file then err_file:close() end

local label = (arg and arg[1]) or ""
local pct = exact / total * 100
local avg_lev = total_lev / total
local avg_norm_lev = total_norm_lev / total
local avg_dolgo = total_dolgo / total
local avg_norm_dolgo = total_norm_dolgo / total
if label ~= "" then io.write(label .. ": ") end
io.write(string.format("Exact: %d/%d (%.2f%%)  Avg Lev: %.2f  Norm Lev: %.2f  Norm Dolgo: %.2f\n",
  exact, total, pct, avg_lev, avg_norm_lev, avg_norm_dolgo))
