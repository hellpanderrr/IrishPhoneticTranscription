-- Run regression test words through the new engine and compare to monolith output.
-- Uses the same test words as regression.lua and regression_extended.lua.

local irish = require("irish_main")
local engine_new = require("irish_engine_new")

-- Levenshtein distance
local function lev(s, t)
  if s == t then return 0 end
  local m, n = #s, #t
  local d = {}
  for i = 0, m do d[i] = {}; d[i][0] = i end
  for j = 0, n do d[0][j] = j end
  for i = 1, m do
    for j = 1, n do
      d[i][j] = math.min(
        d[i-1][j] + 1,
        d[i][j-1] + 1,
        d[i-1][j-1] + (s:sub(i,i) == t:sub(j,j) and 0 or 1)
      )
    end
  end
  return d[m][n]
end

-- Test words (same as regression.lua)
local test_words = {
  -- Format: { word, expected_ipa (from regression.lua) }
  {"alt", "ɛlˠt̪ˠ"},
  {"a Sheáin", "ˈa hɛɑːnʲ"},
  {"aithrí", "ˈahɾʲiː"},
  {"brath", "bˠɾˠaç"},
  {"cnoc", "kˠɾˠɔk"},
  {"glas", "ɡlˠasˠ"},
  {"glais", "ɡlˠaʃ"},
  {"tnúth", "ˈt̪ˠɾˠuː"},
  {"íocfaidh", "ˈiːkfˠə"},
  {"marcaigh", "ˈmˠaɾˠkiː"},
  {"chugham", "ˈxuːəmˠ"},
  {"láimh", "lˠɑːiː"},
  {"leabhar", "ˈlʲəuəɾˠ"},
  {"dugaire", "ˈd̪ˠʊɡəɾʲə"},
  {"Gaelach", "ˈɡeːlʲəx"},
  {"Gaedhlaing", "ˈɡeːjlʲɪŋ"},
}

print("--- New Engine Regression Test ---")
print(string.format("%-20s | %-25s | %-25s | %s", "Word", "Production", "New Engine", "Dist"))
print(string.rep("-", 80))

local total_dist = 0
local exact = 0

for _, entry in ipairs(test_words) do
  local word = entry[1]
  local expected = entry[2]

  local prod_ipa = irish.transcribe(word)
  local new_ipa = engine_new.transcribe(word)

  local dist = lev(prod_ipa, new_ipa)
  total_dist = total_dist + dist
  if dist == 0 then exact = exact + 1 end

  print(string.format("%-20s | %-25s | %-25s | %d", word, prod_ipa, new_ipa, dist))
end

print(string.rep("-", 80))
print(string.format("Exact: %d/%d | Total dist: %d | Avg: %.2f", exact, #test_words, total_dist, total_dist / #test_words))
