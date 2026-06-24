-- Quick error categorization
local engine = require("irish_engine_new")
local bm = dofile("_benchmark.lua")

local categories = {
  sonorant_polarity = 0,
  vowel_reduction = 0,
  vowel_quality = 0,
  stress = 0,
  consonant = 0,
  long_vowel = 0,
  diphthong = 0,
  palatalization = 0,
  lenition = 0,
  eclipsis = 0,
  other = 0,
}

local total, lev_total = 0, 0
local function lev(a,b)
  local m, n = #a, #b
  local d = {}
  for i = 0, m do d[i] = {}; d[i][0] = i end
  for j = 0, n do d[0][j] = j end
  for i = 1, m do
    for j = 1, n do
      local cost = (a:sub(i,i) == b:sub(j,j)) and 0 or 1
      d[i][j] = math.min(d[i-1][j]+1, d[i][j-1]+1, d[i-1][j-1]+cost)
    end
  end
  return d[m][n]
end

local err_words = {}
for w, data in pairs(bm) do
  total = total + 1
  local ok, actual = pcall(engine.transcribe, w)
  if ok then
    local d = lev(actual, data.expected)
    lev_total = lev_total + d
    if actual ~= data.expected then
      table.insert(err_words, {word=w, got=actual, expected=data.expected, lev=d})
    end
  end
end

-- Categorize errors
local cat_counts = {}
for _, e in ipairs(err_words) do
  local cat = "other"
  local g, x = e.got, e.expected

  -- Check for multiple-expected patterns first
  if #x > #g * 2 or #x > 40 then cat = "multi_expected"; goto done end

  -- Sonorant polarity: n\ub02 vs n\ub2, l\ub02 vs l\ub2, n\ub2ꜱ vs nꜱ
  if g:match("[nl][̪̰]") or x:match("[nl][̪̰]") then
    if g:gsub("[nl]̪", "X"):gsub("[nl]̰", "Y") ~= x:gsub("[nl]̪", "X"):gsub("[nl]̰", "Y") then
      cat = "sonorant_polarity"
    end
  end

  -- Check vowel reduction (ə vs full vowel)
  if cat == "other" then
    local g_red = g:gsub("ə", "Z")
    local x_red = x:gsub("ə", "Z")
    if g_red ~= x_red and (g:match("ə") or x:match("ə")) then
      cat = "vowel_reduction"
    end
  end

  -- Stress differences
  if cat == "other" then
    local g_stress = g:gsub("[ˈˌ]", "")
    local x_stress = x:gsub("[ˈˌ]", "")
    if g_stress == x_stress and g ~= x then
      cat = "stress"
    end
  end

  -- Palatalization
  if cat == "other" then
    local g_pal = g:gsub("[ʲˠ]", "")
    local x_pal = x:gsub("[ʲˠ]", "")
    if g_pal == x_pal and g ~= x then
      cat = "palatalization"
    end
  end

  -- Long vowel
  if cat == "other" and (g:match("[aiueo]ː") or x:match("[aiueo]ː")) then
    cat = "long_vowel"
  end

  ::done::
  cat_counts[cat] = (cat_counts[cat] or 0) + 1
end

-- Sort categories by count
local sorted = {}
for cat, cnt in pairs(cat_counts) do table.insert(sorted, {cat=cat, cnt=cnt}) end
table.sort(sorted, function(a,b) return a.cnt > b.cnt end)

print(string.format("Total: %d, Wrong: %d, Exact: %.2f%%", total, #err_words, (total-#err_words)/total*100))
print(string.format("Avg Lev: %.2f", lev_total/total))
print()
print("--- Error Categories ---")
for _, s in ipairs(sorted) do
  print(string.format("  %-25s %5d (%.1f%%)", s.cat, s.cnt, s.cnt/#err_words*100))
end
