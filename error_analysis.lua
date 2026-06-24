-- error_analysis.lua
-- Full error analysis: categorize all errors from new engine vs expected

local engine_new = require("irish_engine_new")

local function norm(s)
  if not s then return "" end
  return s:gsub("[ˈˌ\"]", "")
end

local function parse_csv(line)
  local fields = {}
  local cur = {}
  local inq = false
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

local function ulen(s)
  local n = 0; local i = 1
  while i <= #s do
    local b = s:byte(i)
    if b < 128 then i = i + 1
    elseif b < 224 then i = i + 2
    elseif b < 240 then i = i + 3
    else i = i + 4 end
    n = n + 1
  end
  return n
end

-- Load data
local f = io.open("data/connacht_only.csv", "r")
f:read()
local entries = {}
for line in f:lines() do
  local fields = parse_csv(line)
  if #fields >= 3 then table.insert(entries, { word = fields[1], expected = fields[3] }) end
end
f:close()

-- Load results.csv (monolith)
local f2 = io.open("../results.csv", "r")
f2:read()
local mono_results = {}
for line in f2:lines() do
  local fields = parse_csv(line)
  if #fields >= 6 then mono_results[fields[1]] = fields[3] end
end
f2:close()

local function matches_any(ipa, expected)
  local n_ipa = norm(ipa)
  for variant in expected:gmatch("([^,]+)") do
    if norm(variant) == n_ipa then return true end
  end
  return false
end

-- Benchmark
local new_exact, mono_exact, total, mono_matched = 0, 0, 0, 0
local all_errors = {}

for _, entry in ipairs(entries) do
  local word = entry.word; local expected = entry.expected
  total = total + 1

  local ok, ipa = pcall(engine_new.transcribe, word)
  if not ok then ipa = "ERROR" end

  if matches_any(ipa, expected) then
    new_exact = new_exact + 1
  else
    local mono = mono_results[word] or ""
    if matches_any(mono, expected) then mono_matched = mono_matched + 1 end
    table.insert(all_errors, {
      word = word, ipa = ipa, mono = mono, expected = expected,
      first_exp = expected:match("^([^,]+)")
    })
  end
end

print(string.format("Total words: %d", total))
print(string.format("New engine exact: %d (%.2f%%)", new_exact, new_exact/total*100))
print(string.format("Total errors: %d", #all_errors))
print(string.format("  of which monolith got right: %d", mono_matched))
print()

-- Split errors: prefix/special vs normal words
local prefix_errs = {}
local normal_errs = {}

for _, e in ipairs(all_errors) do
  local w = e.word
  if w:match("^[tnd]%-") or w:match("^[dt]\x27") or w:match("^n\x27") or w:match(" ") or w:match("^[%-\x27]") then
    table.insert(prefix_errs, e)
  else
    table.insert(normal_errs, e)
  end
end

print(string.format("Prefix/special errors: %d", #prefix_errs))
print(string.format("Normal word errors: %d", #normal_errs))
print()

-- Categorize normal errors
local cats = {}
local function c(name) cats[name] = (cats[name] or 0) + 1 end
local other_errors = {}

for _, e in ipairs(normal_errs) do
  local ipa = e.ipa; local exp = e.first_exp; local mono = e.mono
  local n_ipa = norm(ipa); local n_exp = norm(exp); local n_mono = norm(mono)

  -- Vowel quality
  if n_exp:match("ɪ") and n_ipa:match("ə") then c("vowel_ɪ_to_ə")
  elseif n_exp:match("ɪ") and n_ipa:match("ʊ") then c("vowel_ɪ_to_ʊ")
  elseif n_exp:match("ɪ") and n_ipa:match("ɛ") then c("vowel_ɪ_to_ɛ")
  elseif n_exp:match("ɪ") and n_ipa:match("a") then c("vowel_ɪ_to_a")
  elseif n_exp:match("ə") and n_ipa:match("ɪ") then c("vowel_ə_to_ɪ")
  elseif n_exp:match("ə") and n_ipa:match("ʊ") then c("vowel_ə_to_ʊ")
  elseif n_exp:match("ə") and n_ipa:match("a") then c("vowel_ə_to_a")
  elseif n_exp:match("a") and n_ipa:match("ɪ") then c("vowel_a_to_ɪ")
  elseif n_exp:match("a") and n_ipa:match("ə") then c("vowel_a_to_ə")
  elseif n_exp:match("ɔ") and n_ipa:match("ə") then c("vowel_ɔ_to_ə")
  elseif n_exp:match("ɔ") and n_ipa:match("ʊ") then c("vowel_ɔ_to_ʊ")
  elseif n_exp:match("ɔ") and n_ipa:match("o") then c("vowel_ɔ_to_o")
  elseif n_exp:match("ɛ") and n_ipa:match("ə") then c("vowel_ɛ_to_ə")
  elseif n_exp:match("ɛ") and n_ipa:match("ɪ") then c("vowel_ɛ_to_ɪ")
  elseif n_exp:match("ʊ") and n_ipa:match("ɪ") then c("vowel_ʊ_to_ɪ")

  -- Long vowel issues
  elseif n_exp:match("iː") and n_ipa:match("ə") then c("long_i_to_schwa")
  elseif n_exp:match("iː") and n_ipa:match("ɪ") then c("long_i_to_short")
  elseif n_exp:match("eː") and n_ipa:match("ə") then c("long_e_to_schwa")
  elseif n_exp:match("aː") and n_ipa:match("ə") then c("long_a_to_schwa")
  elseif n_exp:match("oː") and n_ipa:match("ə") then c("long_o_to_schwa")
  elseif n_exp:match("uː") and n_ipa:match("ə") then c("long_u_to_schwa")
  elseif n_exp:match("uː") and n_ipa:match("ʊ") then c("long_u_to_short")

  -- Diphthong issues
  elseif n_exp:match("au") and not n_ipa:match("au") then c("missing_au_diphthong")
  elseif n_exp:match("ai") and not n_ipa:match("ai") then c("missing_ai_diphthong")
  elseif n_exp:match("əu") and not n_ipa:match("əu") then c("missing_əu_diphthong")
  elseif n_exp:match("uə") and not n_ipa:match("uə") then c("missing_uə")
  elseif n_exp:match("iə") and not n_ipa:match("iə") then c("missing_iə")

  -- Ending differences
  elseif n_ipa:match("ə$") and n_exp:match("uː$") then c("schwa_vs_u_ending")
  elseif n_ipa:match("ə$") and n_exp:match("iː$") then c("schwa_vs_i_ending")
  elseif n_ipa:match("iː$") and n_exp:match("ə$") then c("i_ending_vs_schwa")
  elseif n_ipa:match("uː$") and n_exp:match("ə$") then c("u_ending_vs_schwa")

  -- Consonant polarity/dental
  elseif n_exp:match("ʲ") and not n_ipa:match("ʲ") then c("missing_slender")
  elseif n_exp:match("ˠ") and not n_ipa:match("ˠ") then c("missing_broad")
  elseif n_exp:match("n̪") and n_ipa:match("nʲ") then c("dental_n_vs_palatal")
  elseif n_exp:match("nʲ") and n_ipa:match("n̪") then c("palatal_n_vs_dental")
  elseif n_exp:match("lʲ") and n_ipa:match("lˠ") then c("slender_l_vs_broad")
  elseif n_exp:match("t̪") and n_ipa:match("tʲ") then c("dental_t_vs_palatal")
  elseif n_exp:match("d̪") and n_ipa:match("dʲ") then c("dental_d_vs_palatal")
  elseif n_exp:match("ɾʲ") and n_ipa:match("ɾˠ") then c("slender_r_vs_broad")

  -- Lenition issues
  elseif n_exp:match("h") and not n_ipa:match("h") and n_ipa:match("[ptkf]") then c("missing_lenition_h")
  elseif n_exp:match("ɣ") and n_ipa:match("g") then c("lenited_g_vs_stop")
  elseif n_exp:match("j") and n_ipa:match("ɟ") then c("lenited_d_vs_stop")
  elseif n_exp:match("w") and n_ipa:match("b") then c("lenited_b_vs_stop")

  -- Epenthesis missing (sonorant+obstruent needs epenthetic vowel)
  elseif n_exp:match("[lmnr][ə][bvgd]") and not n_ipa:match("[lmnr][ə][bvgd]") and ulen(n_ipa) < ulen(n_exp) then c("missing_epenthesis")

  -- Sonorant + C not separated (missing epenthetic /ə/)
  elseif n_exp:match("[lmnr][əə̥]") and n_ipa:match("[lmnr][mb]") then c("missing_epenthesis")

  -- Vowel length before sonorant clusters
  elseif n_exp:match("[ɑau][ː]") and n_ipa:match("[əa]") and n_exp:match("n[̪]?[ˠ]?[td]") then c("vowel_short_before_son_cluster")
  elseif n_exp:match("[ʊ]") and n_ipa:match("[uː]") and n_exp:match("n[̪]?[ˠ]?[td]") then c("vowel_short_before_son_cluster")

  -- Initial long vowel not preserved
  elseif n_exp:match("^eː") and n_ipa:match("^ɪ") then c("initial_e_reduced")
  elseif n_exp:match("^aː") and n_ipa:match("^ə") then c("initial_a_reduced")
  elseif n_exp:match("^iː") and n_ipa:match("^ɪ") then c("initial_i_reduced")

  -- Stress position
  elseif n_exp:match("^ˈ") and not n_ipa:match("^ˈ") then c("stress_missing_on_first")
  elseif n_ipa:match("^[ˈ]") and n_exp:match("^[ˈ]") and n_ipa ~= n_exp then c("stress_position")

  -- Dental diacritic: l̪ˠ vs lˠ
  elseif n_exp:match("l̪ˠ") and n_ipa:match("lˠ") then c("dental_l_vs_velar_l")
  elseif n_exp:match("l̪ʲ") and n_ipa:match("lʲ") then c("dental_l_pal_vs_pal_l")
  elseif n_exp:match("n̪ˠ") and n_ipa:match("n̪ʲ") then c("broad_dental_n_vs_pal_dental")
  elseif n_exp:match("ɲ") and n_ipa:match("nʲ") then c("palatal_nasal_vs_palatal_n")
  elseif n_exp:match("n̠ʲ") and n_ipa:match("nʲ") then c("alveolo_palatal_n_vs_regular_n")
  elseif n_exp:match("l̠ʲ") and n_ipa:match("lʲ") then c("alveolo_palatal_l_vs_regular_l")

  -- Vocalization / lenited fricatives
  elseif n_exp:match("uː$") and n_ipa:match("ə$") and n_exp:match("bh") then c("mh_bh_not_vocalized")

  -- Unexpected diphthong output
  elseif n_ipa:match("əu") and not n_exp:match("əu") then c("extra_əu_diphthong")
  elseif n_ipa:match("əi") and not n_exp:match("əi") then c("extra_əi_diphthong")

  else
    c("other")
    table.insert(other_errors, e)
  end
end

-- Sort categories
local sorted = {}
for k, v in pairs(cats) do table.insert(sorted, { k, v }) end
table.sort(sorted, function(a,b) return a[2] > b[2] end)

print("=== NORMAL WORD ERROR CATEGORIES ===")
for _, cat in ipairs(sorted) do
  print(string.format("  %-30s: %5d (%.1f%%)", cat[1], cat[2], cat[2]/#normal_errs*100))
end

print()
print(string.format("Total normal errors: %d", #normal_errs))
print(string.format("Other errors: %d", #other_errors))

-- Show other errors
print()
print("=== OTHER ERROR EXAMPLES ===")
for i = 1, math.min(15, #other_errors) do
  local e = other_errors[i]
  print(string.format("  %-20s | %s | exp: %s", e.word, e.ipa, e.first_exp))
end
