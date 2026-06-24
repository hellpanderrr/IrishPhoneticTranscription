-- Generate _base.tsv directly from benchmark data
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

local f = io.open("_base.tsv", "w")
local total, exact = 0, 0
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
  local is_exact = (got == best_exp)
  if is_exact then exact = exact + 1 end
  f:write(word .. "\t" .. got .. "\t" .. best_exp .. "\t" .. (is_exact and "1" or "0") .. "\t" .. best_lev .. "\n")
end
f:close()
print("Wrote " .. total .. " words, exact=" .. exact)
