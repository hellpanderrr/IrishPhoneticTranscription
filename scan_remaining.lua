-- Scan remaining errors, group by Levenshtein distance 1
local bench = require("_benchmark")

local function lev(a, b)
  if a == b then return 0 end
  local m, n = #a, #b
  local d = {}
  for i = 0, m do d[i] = { [0] = i } end
  for j = 0, n do d[0][j] = j end
  for i = 1, m do
    for j = 1, n do
      d[i][j] = math.min(d[i-1][j] + 1, d[i][j-1] + 1, d[i-1][j-1] + (a:sub(i,i) == b:sub(j,j) and 0 or 1))
    end
  end
  return d[m][n]
end

local e = require("irish_engine_new")

local errors = {}
for _, entry in ipairs(bench) do
  local got = e.transcribe(entry.ortho, "connacht")
  local expected = entry.expected
  if got ~= expected then
    local d = lev(got, expected)
    -- Generate substitution signature for lev-1
    local sig = ""
    if d <= 2 then
      sig = got .. " → " .. expected
    end
    local monolith = entry.monolith or ""
    table.insert(errors, { ortho=entry.ortho, got=got, expected=expected, lev=d, sig=sig, monolith=monolith })
  end
end

table.sort(errors, function(a,b) return a.lev < b.lev end)

-- Count lev-1 by category
local cats = {}
for _, err in ipairs(errors) do
  if err.lev == 1 then
    cats[err.sig] = (cats[err.sig] or 0) + 1
  end
end

-- Sort categories by count desc
local sorted = {}
for k, v in pairs(cats) do table.insert(sorted, { sig = k, count = v }) end
table.sort(sorted, function(a,b) return a.count > b.count end)

io.write("=== Lev-1 error buckets (", #errors, " total errors) ===\n\n")
for _, cat in ipairs(sorted) do
  io.write(string.format("%4d  %s\n", cat.count, cat.sig))
end

io.write("\n=== Top 50 errors by Lev distance ===\n\n")
local shown = 0
for _, err in ipairs(errors) do
  if shown >= 50 then break end
  if err.lev <= 2 then
    io.write(string.format("%-20s got=%-20s exp=%-20s lev=%d\n", err.ortho, err.got, err.expected, err.lev))
    shown = shown + 1
  end
end
