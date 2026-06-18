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

local function levenshtein(s1, s2)
  local m, n = ulen(s1), ulen(s2)
  local v0, v1 = {}, {}
  for i = 0, n do v0[i] = i end
  for i = 1, m do
    v1[0] = i
    for j = 1, n do
      local c = (usub(s1, i, i) == usub(s2, j, j)) and 0 or 1
      v1[j] = math.min(v1[j - 1] + 1, v0[j] + 1, v0[j - 1] + c)
    end
    for j = 0, n do v0[j] = v1[j] end
  end
  return v1[n]
end

local exact, total, total_lev = 0, 0, 0
local out_file = arg and arg[2] and io.open(arg[2], "w") or nil

for word, entry in pairs(bench) do
  local got = engine.transcribe(word, "connacht")
  total = total + 1
  local variants = {}
  for v in entry.expected:gmatch("[^,]+") do table.insert(variants, trim(v)) end
  local best_lev, best_exp = nil, nil
  for _, ev in ipairs(variants) do
    local lev = levenshtein(got, ev)
    if best_lev == nil or lev < best_lev then best_lev, best_exp = lev, ev end
  end
  total_lev = total_lev + best_lev
  if got == best_exp then exact = exact + 1 end
  if out_file then
    out_file:write(word .. "\t" .. got .. "\t" .. best_exp .. "\t" ..
      tostring(got == best_exp) .. "\t" .. best_lev .. "\n")
  end
end
if out_file then out_file:close() end

local label = (arg and arg[1]) or ""
local pct = exact / total * 100
local avg_lev = total_lev / total
local norm_lev = (1 - total_lev / (total * 20)) * 100
if label ~= "" then io.write(label .. ": ") end
io.write(string.format("Exact: %d/%d (%.2f%%)  Avg Lev: %.2f  Norm Lev: %.2f%%\n",
  exact, total, pct, avg_lev, norm_lev))
