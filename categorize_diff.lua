-- Systematic comparison: categorize ALL differences between engines

package.path = "archive/?.lua;" .. (package.path or "")

local engine_new = require("irish_engine_new")
local monolith = require("archive.irish")

local function parse_csv(line)
  local fields = {}; local cur = {}; local inq = false
  for i = 1, #line do
    local c = line:sub(i,i)
    if c == [["]] then inq = not inq
    elseif c == "," and not inq then
      table.insert(fields, table.concat(cur)); cur = {}
    else table.insert(cur, c) end
  end
  table.insert(fields, table.concat(cur))
  return fields
end

-- Normalize: remove stress marks for comparison
local function norm(s)
  if not s then return "" end
  return s:gsub("[ˈˌ\"]", "")
end

-- Unicode length
local function ulen(s)
  local n = 0; local i = 1
  while i <= #s do
    local b = s:byte(i)
    if b < 128 then i = i + 1 elseif b < 224 then i = i + 2 elseif b < 240 then i = i + 3 else i = i + 4 end
    n = n + 1
  end
  return n
end

-- Unicode substring
local function usub(s, i, j)
  local chars = {}; local pos = 1; local idx = 1
  while pos <= #s and idx <= (j or 9999) do
    local b = s:byte(pos)
    local len = 1; if b >= 240 then len = 4 elseif b >= 224 then len = 3 elseif b >= 128 then len = 2 end
    if idx >= i then table.insert(chars, s:sub(pos, pos+len-1)) end
    pos = pos + len; idx = idx + 1
  end
  return table.concat(chars)
end

-- Load data
local f = io.open("data/connacht_only.csv", "r")
f:read()
local entries = {}
for line in f:lines() do
  local fields = parse_csv(line)
  if #fields >= 3 then
    local w = fields[1]
    if not w:match("^[%-\x27]") then -- skip suffix entries
      table.insert(entries, { word = w, expected = fields[3] })
    end
  end
end
f:close()

-- Run comparison on real words
local all_diffs = {}
for _, e in ipairs(entries) do
  local ok_n, ipa_n = pcall(engine_new.transcribe, e.word)
  local ok_m, ipa_m = pcall(monolith.transcribe, e.word)
  if not ok_n then ipa_n = "ERROR" end
  if not ok_m then ipa_m = "ERROR" end
  if ipa_n ~= ipa_m then
    table.insert(all_diffs, { word = e.word, new = ipa_n, mono = ipa_m, expected = e.expected })
  end
end

print(string.format("Total real words: %d", #entries))
print(string.format("Differences: %d (%.1f%%)", #all_diffs, #all_diffs/#entries*100))
print()

-- Categorization system
-- We look at key phonetic features and compare new vs mono
local cats = {}
local function c(name) cats[name] = (cats[name] or 0) + 1 end

local cat_data = {}  -- store examples per category

local function add_to_cat(name, d)
  if not cat_data[name] then cat_data[name] = {} end
  if #cat_data[name] < 3 then table.insert(cat_data[name], d) end
end

-- Phonetic feature extractor
local function has(s, pat) return s:find(pat) ~= nil end

for _, d in ipairs(all_diffs) do
  local w = d.word
  local n = norm(d.new)
  local m = norm(d.mono)

  -- Skip entries where the only diff is stress
  if n == m then
    c("stress_only")
    goto continue
  end

  -- ============ MULTI-WORD (spaces) ============
  if w:match(" ") then
    c("multi_word")
    add_to_cat("multi_word", d)
    goto continue
  end

  -- ============ PREFIX (t-, d', n-) ============
  if w:match("^[tnd]%-") or w:match("^[dt]\x27") or w:match("^n\x27") then
    c("prefix_boundary")
    add_to_cat("prefix_boundary", d)
    goto continue
  end

  -- ============ CAPITAL first letter ============
  if w:match("^[A-Z]") then
    c("capitalized")
    add_to_cat("capitalized", d)
    goto continue
  end

  -- ============ SUFFIX FORMS ============
  -- Check if monolith recognizes grammatical suffixes
  -- Future tense: -fidh, -fimid, -fá, -finn, etc.
  if not has(m, "ERROR") and has(m, "h") and not has(n, "h") and
     (has(w, "fidh$") or has(w, "fá$") or has(w, "finn$") or has(w, "fimid$") or has(w, "feadh$") or has(w, "fimis$") or has(w, "fidís$") or has(w, "faidh$")) then
    c("future_tense_suffix")
    add_to_cat("future_tense_suffix", d)
    goto continue
  end

  -- -igh endings
  if has(w, "igh$") and has(m, "iː$") and has(n, "ə$") then
    c("igh_ending")
    add_to_cat("igh_ending", d)
    goto continue
  end

  -- -adh endings
  if has(w, "adh$") and has(m, "uː") and has(n, "ə") then
    c("adh_ending")
    add_to_cat("adh_ending", d)
    goto continue
  end

  -- -aí endings
  if has(w, "aí$") and has(m, "iː") and not has(n, "iː") then
    c("aí_ending")
    add_to_cat("aí_ending", d)
    goto continue
  end

  -- -im, -ím, -igi endings
  if has(w, "im$") or has(w, "imíd$") or has(w, "í$") or has(w, "igí$") or has(w, "imis$") or has(w, "ínn$") or has(w, "itear$") then
    c("verbal_suffix")
    add_to_cat("verbal_suffix", d)
    goto continue
  end

  -- ============ PHONOLOGICAL DIFFERENCES ============

  -- 1. Vowel: ɪ vs ə
  if not has(m, "ə") and has(m, "ɪ") and has(n, "ə") and not has(n, "ɪ") then
    c("mono_ɪ_new_ə")
    add_to_cat("mono_ɪ_new_ə", d)
  elseif not has(n, "ɪ") and has(n, "ə") and has(m, "ɪ") then
    c("mono_ɪ_new_ə")
    add_to_cat("mono_ɪ_new_ə", d)

  -- 2. Vowel: ə vs a
  elseif has(m, "a") and not has(m, "ə") and has(n, "ə") and not has(n, "a") then
    c("mono_a_new_ə")
    add_to_cat("mono_a_new_ə", d)
  elseif has(m, "ə") and has(n, "a") then
    c("mono_ə_new_a")
    add_to_cat("mono_ə_new_a", d)

  -- 3. Vowel: ɔ vs ə
  elseif has(m, "ɔ") and has(n, "ə") and not has(n, "ɔ") then
    c("mono_ɔ_new_ə")
    add_to_cat("mono_ɔ_new_ə", d)

  -- 4. Vowel: ʊ vs ɪ
  elseif has(m, "ʊ") and has(n, "ɪ") then
    c("mono_ʊ_new_ɪ")
    add_to_cat("mono_ʊ_new_ɪ", d)
  elseif has(m, "ɪ") and has(n, "ʊ") then
    c("mono_ɪ_new_ʊ")
    add_to_cat("mono_ɪ_new_ʊ", d)

  -- 5. Vowel: ɛ vs ə
  elseif has(m, "ɛ") and has(n, "ə") then
    c("mono_ɛ_new_ə")
    add_to_cat("mono_ɛ_new_ə", d)

  -- 6. Long vowel shortened
  elseif has(m, "iː") and has(n, "ɪ") then
    c("mono_iː_new_ɪ")
    add_to_cat("mono_iː_new_ɪ", d)
  elseif has(m, "uː") and has(n, "ʊ") then
    c("mono_uː_new_ʊ")
    add_to_cat("mono_uː_new_ʊ", d)
  elseif has(m, "aː") and has(n, "a") then
    c("mono_aː_new_a")
    add_to_cat("mono_aː_new_a", d)
  elseif has(m, "oː") and has(n, "ɔ") then
    c("mono_oː_new_ɔ")
    add_to_cat("mono_oː_new_ɔ", d)

  -- 7. Diphthong: mono has au/ai/əu/əi, new doesn't
  elseif has(m, "au") and not has(n, "au") then
    c("mono_au_new_missing")
    add_to_cat("mono_au_new_missing", d)
  elseif has(m, "ai") and not has(n, "ai") then
    c("mono_ai_new_missing")
    add_to_cat("mono_ai_new_missing", d)
  elseif has(m, "əu") and not has(n, "əu") then
    c("mono_əu_new_missing")
    add_to_cat("mono_əu_new_missing", d)
  elseif has(m, "əi") and not has(n, "əi") then
    c("mono_əi_new_missing")
    add_to_cat("mono_əi_new_missing", d)

  -- New has extra diphthongs
  elseif has(n, "əu") and not has(m, "əu") then
    c("new_extra_əu")
    add_to_cat("new_extra_əu", d)
  elseif has(n, "əi") and not has(m, "əi") then
    c("new_extra_əi")
    add_to_cat("new_extra_əi", d)
  elseif has(n, "au") and not has(m, "au") then
    c("new_extra_au")
    add_to_cat("new_extra_au", d)

  -- 8. iə/uə diphthong
  elseif has(m, "iə") and not has(n, "iə") then
    c("mono_iə_new_missing")
  elseif has(m, "uə") and not has(n, "uə") then
    c("mono_uə_new_missing")

  -- 9. Glides
  elseif has(m, "j") and not has(n, "j") then
    c("mono_j_glide_new_missing")
    add_to_cat("mono_j_glide_new_missing", d)
  elseif has(n, "j") and not has(m, "j") then
    c("new_extra_j_glide")
    add_to_cat("new_extra_j_glide", d)
  elseif has(m, "w") and not has(n, "w") then
    c("mono_w_glide_new_missing")
  elseif has(n, "w") and not has(m, "w") then
    c("new_extra_w_glide")

  -- 10. Dental diacritic differences
  elseif has(m, "n̪ˠ") and has(n, "n̪ʲ") then
    c("mono_n̪ˠ_new_n̪ʲ")
  elseif has(m, "nʲ") and has(n, "n̪ˠ") then
    c("mono_nʲ_new_n̪ˠ")
  elseif has(m, "lˠ") and has(n, "lʲ") then
    c("mono_lˠ_new_lʲ")
  elseif has(m, "lʲ") and has(n, "lˠ") then
    c("mono_lʲ_new_lˠ")
  elseif has(m, "ɾˠ") and has(n, "ɾʲ") then
    c("mono_ɾˠ_new_ɾʲ")
  elseif has(m, "ɾʲ") and has(n, "ɾˠ") then
    c("mono_ɾʲ_new_ɾˠ")

  -- 11. Fricative: mono has ç (slender ch), new has h
  elseif has(m, "ç") and not has(n, "ç") then
    c("mono_ç_new_missing")
    add_to_cat("mono_ç_new_missing", d)

  -- 12. Epenthesis
  elseif has(m, "[ɾl][ə]") and has(n, "[ɾl][^ə]") then
    c("mono_epenthesis_new_missing")
    add_to_cat("mono_epenthesis_new_missing", d)

  -- 13. /x/ deletion
  elseif has(m, "x") and not has(n, "x") then
    c("mono_x_new_missing")
    add_to_cat("mono_x_new_missing", d)

  -- 14. Astray epenthetic from cluster simplification
  elseif ulen(n) < ulen(m) and ulen(m) - ulen(n) <= 2 then
    c("new_shorter")
  elseif ulen(n) > ulen(m) then
    c("new_longer")

  else
    c("other")
    add_to_cat("other", d)
  end

  ::continue::
end

-- Print categories
local sorted = {}
for k, v in pairs(cats) do
  table.insert(sorted, { k, v })
end
table.sort(sorted, function(a,b) return a[2] > b[2] end)

for _, cat in ipairs(sorted) do
  local pct = cat[2] / #all_diffs * 100
  print(string.format("%-30s: %5d (%.1f%%)", cat[1], cat[2], pct))
  if cat_data[cat[1]] then
    for _, d in ipairs(cat_data[cat[1]]) do
      print(string.format("  │ %-20s | NEW: %s", d.word, d.new))
      print(string.format("  │ %20s | MONO: %s", "", d.mono))
    end
    print()
  end
end
