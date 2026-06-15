-- Comparison harness: runs monolith vs new engine on full Connacht wordlist.
-- Reports per-word differences for regression detection.

local irish = require("irish")
local engine_new = require("irish_engine_new")

-- Levenshtein distance
local function levenshtein(s, t)
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

-- Load data/connacht_only.csv
local function load_wordlist()
  local file = io.open("data/connacht_only.csv", "r")
  if not file then
    print("ERROR: Could not open data/connacht_only.csv")
    return {}
  end

  local words = {}
  for line in file:lines() do
    local word, ipa = line:match("^([^,]+),(.+)$")
    if word then
      table.insert(words, { word = word, expected = ipa })
    end
  end
  file:close()
  return words
end

-- Main
local wordlist = load_wordlist()
if #wordlist == 0 then
  io.stderr:write("No words loaded from connacht_only.csv\n")
  os.exit(1)
end

print("--- Comparison Summary ---")
print("Processing " .. #wordlist .. " words...")

local diffs = {}
local exact = 0
local total_dist = 0
local max_diffs = 20

for _, entry in ipairs(wordlist) do
  local word = entry.word

  -- Skip empty words and stress-mark-only entries
  if word == "" or word == " " then goto continue end

  local ok_prod, prod_ipa = pcall(irish.transcribe, word)
  local ok_new, new_ipa = pcall(engine_new.transcribe, word)

  if not ok_prod then
    prod_ipa = "ERROR:" .. prod_ipa
  end
  if not ok_new then
    new_ipa = "ERROR:" .. new_ipa
  end

  local dist = levenshtein(prod_ipa, new_ipa)
  total_dist = total_dist + dist

  if dist == 0 then
    exact = exact + 1
  elseif #diffs < max_diffs then
    table.insert(diffs, { word = word, prod = prod_ipa, new = new_ipa, dist = dist })
  end

  ::continue::
end

print(string.format("\nTotal words: %d", #wordlist))
print(string.format("Exact match: %d (%.1f%%)", exact, exact / #wordlist * 100))
print(string.format("Different: %d (%.1f%%)", #wordlist - exact, (#wordlist - exact) / #wordlist * 100))
print(string.format("Average Levenshtein distance: %.4f", total_dist / #wordlist))

if #diffs > 0 then
  print("\n--- Top " .. #diffs .. " Differences ---")
  print(string.format("%-20s | %-25s | %-25s | %s", "Word", "Production", "New Engine", "Dist"))
  print(string.rep("-", 80))
  for _, d in ipairs(diffs) do
    print(string.format("%-20s | %-25s | %-25s | %d", d.word, d.prod, d.new, d.dist))
  end
end

print("\nDone.")
