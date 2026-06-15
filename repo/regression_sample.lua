-- Regression Sample: 100 rows from results.csv with varied error categories.
-- Runs both production and new engine, reports Levenshtein and Dolgo metrics.

local engine_new = require("irish_engine_new")
local core = require("irish_core")
local N = core.N
local ulen = core.ulen
local usub = core.usub
local umatch = core.umatch

-- Levenshtein distance (UTF-8 aware, uses ulen / usub)
local function levenshtein(s, t)
  if s == t then return 0 end
  local m = ulen(s)
  local n = ulen(t)
  if m == 0 then return n end
  if n == 0 then return m end

  local d = {}
  for i = 0, m do d[i] = {}; d[i][0] = i end
  for j = 0, n do d[0][j] = j end

  for i = 1, m do
    for j = 1, n do
      local ci = usub(s, i, i)
      local cj = usub(t, j, j)
      local cost = (ci == cj) and 0 or 1
      d[i][j] = math.min(
        d[i-1][j] + 1,
        d[i][j-1] + 1,
        d[i-1][j-1] + cost
      )
    end
  end
  return d[m][n]
end

-- Minimal Dolgo-like measure: normalized Levenshtein (1.0 = perfect)
local function dolgo(s, t)
  local dist = levenshtein(s, t)
  local max = math.max(ulen(s), ulen(t))
  if max == 0 then return 1.0 end
  return math.max(0, 1 - (dist / max))
end

-- Category names (based on match score brackets)
local categories = {
  { min=0,   max=9,   name="very_error" },
  { min=20,  max=39,  name="high_error" },
  { min=40,  max=59,  name="moderate_error" },
  { min=60,  max=69,  name="slight_error" },
  { min=70,  max=79,  name="minor_error" },
  { min=80,  max=89,  name="low_error" },
  { min=90,  max=99,  name="near_match" },
  { min=100, max=100, name="perfect" },
}

-- Load CSV
local function load_csv(filename)
  local file = io.open(filename, "r")
  if not file then error("Could not open " .. filename) end
  local rows = {}
  local header = file:read()
  for line in file:lines() do
    -- Parse: word,tags,ipa,results,match,dolgo
    local word, tags, ipa, results_raw, match_str, dolgo_str = line:match("^([^,]*),([^,]*),\"?([^,]*?)\"?,\"?([^,]*?)\"?,\"?([^,]*?)\"?,\"?([^,]*?)\"$")
    if not word then
      -- Fallback for simpler cases
      word, tags, ipa, results_raw, match_str, dolgo_str = line:match("^([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),([^,]*)$")
    end
    if word and ipa and match_str then
      local match_score = tonumber(match_str)
      if match_score then
        table.insert(rows, {
          word = word,
          tags = tags,
          expected_ipa = ipa,
          production_result = results_raw,
          match_score = match_score,
          dolgo = tonumber(dolgo_str) or 0,
        })
      end
    end
  end
  file:close()
  return rows
end

-- Select 100 rows, { per category }
local function select_sample(rows, count_per_cat, total)
  local selected = {}
  local per_cat = math.ceil(total / #categories)

  for _, cat in ipairs(categories) do
    local candidates = {}
    for _, row in ipairs(rows) do
      if row.match_score >= cat.min and row.match_score <= cat.max then
        table.insert(candidates, row)
      end
    end

    -- Sort by match score (pick most representative)
    table.sort(candidates, function(a, b) return a.match_score < b.match_score end)

    local n = math.min(#candidates, per_cat)
    for i = 1, n do
      table.insert(selected, candidates[i])
    end
  end

  -- If we're short, fill from remaining
  if #selected < total then
    -- Add more from mid-range categories
  end

  return selected
end

-- Main
local filepath = "../results.csv"

print("Loading results.csv...")
local rows = load_csv(filepath)
print("Loaded " .. #rows .. " rows")

print("")
print("=== Category distribution ===")
for _, cat in ipairs(categories) do
  local count = 0
  for _, r in ipairs(rows) do
    if r.match_score >= cat.min and r.match_score <= cat.max then
      count = count + 1
    end
  end
  print(string.format("  %-18s (%2d-%3d): %4d words", cat.name, cat.min, cat.max, count))
end

local sample = select_sample(rows, nil, 100)
print("\nSelected " .. #sample .. " sample rows")

print("")
print("=== Regression Test Results: New Engine vs Expected IPA ===")
print(string.format("%-20s | %-22s | %-22s | %-5s | %-5s | %-5s | %-5s | %-5s | %-5s",
    "Word", "Expected IPA", "New Engine",
    "MLev", "NLev", "MDolgo", "NDolgo", "M%", "N%"))
print(string.rep("-", 120))

local totals = { m_lev=0, n_lev=0, m_dolgo=0, n_dolgo=0, m_pct=0, n_pct=0 }
local new_better = 0
local prod_better = 0
local tied = 0

for _, entry in ipairs(sample) do
  local word = entry.word
  local expected = entry.expected_ipa
  local monolith = entry.production_result
  local new_ipa = engine_new.transcribe(word)

  -- New engine scores vs expected IPA
  local n_lev = levenshtein(expected, new_ipa)
  local n_dolgo = dolgo(expected, new_ipa)
  local n_max = math.max(ulen(expected), ulen(new_ipa))
  local n_pct = n_max > 0 and math.max(0, (1 - n_lev/n_max) * 100) or 100

  -- Monolith scores vs expected IPA
  local m_lev = levenshtein(expected, monolith)
  local m_dolgo = dolgo(expected, monolith)
  local m_max = math.max(ulen(expected), ulen(monolith))
  local m_pct = m_max > 0 and math.max(0, (1 - m_lev/m_max) * 100) or 100

  totals.m_lev = totals.m_lev + m_lev
  totals.n_lev = totals.n_lev + n_lev
  totals.m_dolgo = totals.m_dolgo + m_dolgo
  totals.n_dolgo = totals.n_dolgo + n_dolgo
  totals.m_pct = totals.m_pct + m_pct
  totals.n_pct = totals.n_pct + n_pct

  if n_lev < m_lev then new_better = new_better + 1
  elseif n_lev > m_lev then prod_better = prod_better + 1
  else tied = tied + 1 end

  local cat_name = "?"
  for _, cat in ipairs(categories) do
    if entry.match_score >= cat.min and entry.match_score <= cat.max then
      cat_name = cat.name; break
    end
  end

  local disp_exp = ulen(expected) > 22 and usub(expected, 1, 19) .. "..." or expected
  local disp_new = ulen(new_ipa) > 22 and usub(new_ipa, 1, 19) .. "..." or new_ipa

  print(string.format("%-20s | %-22s | %-22s | %5d | %5d | %5.3f | %5.3f | %4.1f | %4.1f",
      word, disp_exp, disp_new, m_lev, n_lev, m_dolgo, n_dolgo, m_pct, n_pct))
end

local n = #sample
print(string.rep("-", 120))
print(string.format("  Avg Levenshtein:  Mono=%.2f  New=%.2f", totals.m_lev/n, totals.n_lev/n))
print(string.format("  Avg Dolgo:        Mono=%.4f  New=%.4f", totals.m_dolgo/n, totals.n_dolgo/n))
print(string.format("  Avg Percent:      Mono=%.1f%%  New=%.1f%%", totals.m_pct/n, totals.n_pct/n))
print(string.format("  New better: %d | Mono better: %d | Tied: %d", new_better, prod_better, tied))

print("")
print("=== By Category Breakdown ===")
for _, cat in ipairs(categories) do
  local cat_lev = 0
  local cat_dolgo = 0
  local cat_count = 0
  for _, entry in ipairs(sample) do
    if entry.match_score >= cat.min and entry.match_score <= cat.max then
      cat_count = cat_count + 1
      local new_ipa = engine_new.transcribe(entry.word)
      cat_lev = cat_lev + levenshtein(entry.expected_ipa, new_ipa)
      cat_dolgo = cat_dolgo + dolgo(entry.expected_ipa, new_ipa)
    end
  end
  if cat_count > 0 then
    print(string.format("  %-18s: %3d words | avg lev=%.2f | avg dolgo=%.4f",
        cat.name, cat_count, cat_lev/cat_count, cat_dolgo/cat_count))
  end
end

print("\nDone.")