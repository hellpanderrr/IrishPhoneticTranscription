-- engine_compare.lua
-- Direct comparison: new engine vs monolith output on every word.
-- Shows specific rule differences.

local engine_new = require("irish_engine_new")
local monolith = require("irish")

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

-- Load word list
local f = io.open("data/connacht_only.csv", "r")
f:read()
local words = {}
for line in f:lines() do
  local fields = parse_csv(line)
  if #fields >= 3 then table.insert(words, fields[1]) end
end
f:close()

-- Run both engines
local diff_words = {}
local mono_missing, new_missing = 0, 0

-- For classifying word types
local function word_type(w)
  if w:match("^[tnd]%-") or w:match("^[dt]\x27") or w:match("^n\x27") then return "prefix"
  elseif w:match(" ") then return "multiword"
  elseif w:match("^[%-\x27]") then return "special"
  elseif w:match("^[A-Z]") then return "capital"
  else return "normal" end
end

for _, word in ipairs(words) do
  local ok_new, new_ipa = pcall(engine_new.transcribe, word)
  local ok_mono, mono_ipa = pcall(monolith.transcribe, word)

  if not ok_new then new_ipa = "ERROR" end
  if not ok_mono then mono_ipa = "ERROR" end

  if new_ipa ~= mono_ipa then
    table.insert(diff_words, {
      word = word,
      new = new_ipa,
      mono = mono_ipa,
      wtype = word_type(word)
    })
  end
  if not ok_new then new_missing = new_missing + 1 end
  if not ok_mono then mono_missing = mono_missing + 1 end
end

print(string.format("Total words: %d", #words))
print(string.format("Words where NEW != MONO: %d (%.1f%%)", #diff_words, #diff_words/#words*100))
print()

-- Analyze differences by type
local diffs_by_type = {}
for _, d in ipairs(diff_words) do
  diffs_by_type[d.wtype] = (diffs_by_type[d.wtype] or 0) + 1
end
print("=== DIFFERENCES BY WORD TYPE ===")
for k, v in pairs(diffs_by_type) do
  print(string.format("  %-15s: %d", k, v))
end

-- Function to count Unicode chars
local function ulen(s)
  local n = 0; local i = 1
  while i <= #s do
    local b = s:byte(i)
    if b < 128 then i = i + 1 elseif b < 224 then i = i + 2 elseif b < 240 then i = i + 3 else i = i + 4 end
    n = n + 1
  end
  return n
end

-- Normalize for comparison
local function norm(s)
  return s:gsub("[ˈˌ\"]", "")
end

-- Classify phonological differences
local phons = {}
local function p(name, d)
  phons[name] = (phons[name] or 0) + 1
  if #phons[name .. "_ex"] or 0 < 5 then
    if not phons[name .. "_ex"] then phons[name .. "_ex"] = {} end
    if #phons[name .. "_ex"] < 5 then
      table.insert(phons[name .. "_ex"], d)
    end
  end
end

for _, d in ipairs(diff_words) do
  if d.wtype ~= "normal" then goto continue end

  local n_new = norm(d.new)
  local n_mono = norm(d.mono)

  -- Specific known pattern categories

  -- 1. Final -adh/-aidh/-aigh endings (mono has uː or iː, new has ə)
  if n_mono:match("uː$") and n_new:match("ə$") then
    p("mono ends uː new ends schwa", d)
  elseif n_mono:match("iː$") and n_new:match("ə$") then
    p("mono ends iː new ends schwa", d)
  elseif n_mono:match("ə$") and n_new:match("uː$") then
    p("mono ends schwa new ends uː", d)
  elseif n_mono:match("ə$") and n_new:match("iː$") then
    p("mono ends schwa new ends iː", d)

  -- 2. Vowel quality: a vs ɪ vs ə vs ʊ
  elseif n_mono:match("ɪ") and n_new:match("ə") then
    p("mono ɪ new ə", d)
  elseif n_mono:match("ɪ") and n_new:match("ʊ") then
    p("mono ɪ new ʊ", d)
  elseif n_mono:match("ɪ") and n_new:match("ɛ") then
    p("mono ɪ new ɛ", d)
  elseif n_mono:match("a") and n_new:match("ə") then
    p("mono a new ə", d)
  elseif n_mono:match("a") and n_new:match("ɪ") then
    p("mono a new ɪ", d)
  elseif n_mono:match("ə") and n_new:match("a") then
    p("mono ə new a", d)
  elseif n_mono:match("ə") and n_new:match("ɪ") then
    p("mono ə new ɪ", d)
  elseif n_mono:match("ɔ") and n_new:match("ə") then
    p("mono ɔ new ə", d)
  elseif n_mono:match("ɔ") and n_new:match("ʊ") then
    p("mono ɔ new ʊ", d)
  elseif n_mono:match("ʊ") and n_new:match("ə") then
    p("mono ʊ new ə", d)
  elseif n_mono:match("ʊ") and n_new:match("ɪ") then
    p("mono ʊ new ɪ", d)
  elseif n_mono:match("ɛ") and n_new:match("ə") then
    p("mono ɛ new ə", d)

  -- 3. Long vowels shortened
  elseif n_mono:match("iː") and n_new:match("i") then
    p("mono iː new short", d)
  elseif n_mono:match("uː") and n_new:match("ʊ") then
    p("mono uː new ʊ", d)
  elseif n_mono:match("aː") and n_new:match("a") then
    p("mono aː new short", d)
  elseif n_mono:match("oː") and n_new:match("ɔ") then
    p("mono oː new ɔ", d)

  -- 4. Diphthong differences
  elseif n_mono:match("au") and not n_new:match("au") then
    p("mono au new missing", d)
  elseif n_mono:match("ai") and not n_new:match("ai") then
    p("mono ai new missing", d)
  elseif n_mono:match("əu") and not n_new:match("əu") then
    p("mono əu new missing", d)
  elseif n_mono:match("iə") and not n_new:match("iə") then
    p("mono iə new missing", d)
  elseif n_new:match("au") and not n_mono:match("au") then
    p("new extra au", d)
  elseif n_new:match("əu") and not n_mono:match("əu") then
    p("new extra əu", d)
  elseif n_new:match("əi") and not n_mono:match("əi") then
    p("new extra əi", d)

  -- 5. Consonant polarity
  elseif n_mono:match("lˠ") and n_new:match("lʲ") then
    p("mono broad l new slender l", d)
  elseif n_mono:match("lʲ") and n_new:match("lˠ") then
    p("mono slender l new broad l", d)
  elseif n_mono:match("n̪ˠ") and n_new:match("nʲ") then
    p("mono n̪ˠ new nʲ", d)
  elseif n_mono:match("nʲ") and n_new:match("n̪ˠ") then
    p("mono nʲ new n̪ˠ", d)
  elseif n_mono:match("ɾˠ") and n_new:match("ɾʲ") then
    p("mono broad r new slender r", d)
  elseif n_mono:match("ɾʲ") and n_new:match("ɾˠ") then
    p("mono slender r new broad r", d)
  elseif n_mono:match("d̪ˠ") and n_new:match("dʲ") then
    p("mono d̪ˠ new dʲ", d)
  elseif n_mono:match("t̪ˠ") and n_new:match("tʲ") then
    p("mono t̪ˠ new tʲ", d)

  -- 6. /x/ presence
  elseif n_mono:match("x") and not n_new:match("x") then
    p("mono has x new missing", d)
  elseif n_new:match("x") and not n_mono:match("x") then
    p("new extra x", d)

  -- 7. Epenthesis (extra vowel)
  elseif n_mono:match("[lmnr]ə") and n_new:match("[lmnr][^ə]") then
    p("mono has epenthesis new missing", d)

  -- 8. Stress position
  elseif n_mono:match("^ˈ") and not n_new:match("^ˈ") then
    p("mono stressed new unstressed", d)
  elseif n_new:match("^ˈ") and not n_mono:match("^ˈ") then
    p("new stressed mono unstressed", d)

  -- 9. Glide insertions
  elseif n_mono:match("j") and not n_new:match("j") then
    p("mono has j-glide new missing", d)
  elseif n_new:match("j") and not n_mono:match("j") then
    p("new extra j-glide", d)
  elseif n_mono:match("w") and not n_new:match("w") then
    p("mono has w new missing", d)
  elseif n_new:match("w") and not n_mono:match("w") then
    p("new extra w", d)

  else
    p("other", d)
  end

  ::continue::
end

-- Sort categories
local sorted = {}
for k, v in pairs(phons) do
  if not k:match("_ex$") then table.insert(sorted, { k, v }) end
end
table.sort(sorted, function(a,b) return a[2] > b[2] end)

print()
print("=== PHONOLOGICAL CATEGORIES (NEW vs MONO) ===")
for _, c in ipairs(sorted) do
  print(string.format("  %-40s: %5d (%.1f%%)", c[1], c[2], c[2]/#diff_words*100))
  if phons[c[1] .. "_ex"] then
    for _, ex in ipairs(phons[c[1] .. "_ex"]) do
      print(string.format("    >> %-20s | NEW: %s", ex.word, ex.new))
      print(string.format("    %22s | MONO: %s", "", ex.mono))
    end
  end
end
