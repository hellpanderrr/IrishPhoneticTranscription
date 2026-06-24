-- Analyze sonorant polarity mismatches
local engine = require("irish_engine_new")
local bm = dofile("_benchmark.lua")

-- Collect sonorant-related mismatches
local sonorant_words = {}
local vowel_red_words = {}
local total = 0

local function lev(a,b)
  local m,n = #a,#b
  local d = {}
  for i=0,m do d[i]={}; d[i][0]=i end
  for j=0,n do d[0][j]=j end
  for i=1,m do for j=1,n do
    local c = (a:sub(i,i)==b:sub(j,j)) and 0 or 1
    d[i][j]=math.min(d[i-1][j]+1,d[i][j-1]+1,d[i-1][j-1]+c)
  end end
  return d[m][n]
end

for w, data in pairs(bm) do
  total = total + 1
  local ok, actual = pcall(engine.transcribe, w)
  if ok and actual ~= data.expected then
    -- Sonorant: check if any n/l/ɾ is present
    local g_has_n = actual:match("n[%̪̰ˠʲ%[%]]") or actual:match("n(%s|$)")
    local x_has_n = data.expected:match("n[%̪̰ˠ̠ʲ%[%]]") or data.expected:match("n(%s|$)")
    local g_has_l = actual:match("l[%̪̰ˠ̠ʲ%[%]]")
    local x_has_l = data.expected:match("l[%̪̰ˠ̠ʲ%[%]]")
    if g_has_n or x_has_n or g_has_l or x_has_l then
      -- More precise: check if the error is specifically about n/l diacritics
      local ga = actual:gsub("[n][^%s%d]+", "N_"):gsub("[l][^%s%d]+", "L_")
      local xa = data.expected:gsub("[n][^%s%d]+", "N_"):gsub("[l][^%s%d]+", "L_")
      if ga ~= xa then
        table.insert(sonorant_words, {word=w, got=actual, expected=data.expected, lev=lev(actual,data.expected)})
      end
    end
    -- Vowel reduction: check if ə is mismatched
    local g_vowels = {}
    for v in actual:gmatch("[əɪɔʊaeiouɑɛ]+") do g_vowels[#g_vowels+1] = v end
    local x_vowels = {}
    for v in data.expected:gmatch("[əɪɔʊaeiouɑɛ]+") do x_vowels[#x_vowels+1] = v end
    if #g_vowels == #x_vowels then
      local differs = false
      for i = 1, #g_vowels do
        if g_vowels[i] ~= x_vowels[i] then differs = true; break end
      end
      if differs then
        local reduced_g = actual:gsub("ə","_"):gsub("ː","")
        local reduced_x = data.expected:gsub("ə","_"):gsub("ː","")
        if reduced_g:gsub("[_aeiouɔɪʊɑɛ]","V") == reduced_x:gsub("[_aeiouɔɪʊɑɛ]","V") then
          table.insert(vowel_red_words, {word=w, got=actual, expected=data.expected})
        end
      end
    end
  end
end

print("=== Sonorant polarity mismatches: " .. #sonorant_words .. " ===")
table.sort(sonorant_words, function(a,b) return a.lev > b.lev end)
for i = 1, math.min(30, #sonorant_words) do
  print(string.format("  %-25s got=%s  expected=%s", sonorant_words[i].word, sonorant_words[i].got, sonorant_words[i].expected))
end

-- Analyze what sonorant symbols are in engine vs expected
local eng_n, eng_l, eng_r = {}, {}, {}
local exp_n, exp_l, exp_r = {}, {}, {}
for _, e in ipairs(sonorant_words) do
  -- Engine sonorant counts
  for s in e.got:gmatch("[n̪ˠn̠ʲn̰ˠn̠ˠlˠl̪ˠl̠ʲl̰ˠɾˠɾʲ]") do
    eng_n[s] = (eng_n[s] or 0) + 1
  end
  -- Expected sonorant counts
  for s in e.expected:gmatch("[n̪ˠn̠ʲn̰ˠn̠ˠnˠlˠl̪ˠl̠ʲl̰ˠl̠ˠlˠɾˠɾʲ]") do
    exp_n[s] = (exp_n[s] or 0) + 1
  end
end

print()
print("=== Engine sonorant frequencies (in mismatched words) ===")
for s, c in pairs(eng_n) do print(string.format("  %-8s %d", s, c)) end
print()
print("=== Expected sonorant frequencies (in mismatched words) ===")
for s, c in pairs(exp_n) do print(string.format("  %-8s %d", s, c)) end
