-- Scan all benchmark outputs for phonetically impossible patterns in Irish
local engine = require("irish_engine_new")
local bench = require("_benchmark")
local ut = require("ustring.ustring")

local function trim(s) return s:match("^%s*(.-)%s*$") end

-- Get full character at position in byte string
local function char_at(s, i)
  if not s or i > #s then return nil, 0 end
  local b = s:byte(i)
  if b >= 248 then return s:sub(i, i+4), 5
  elseif b >= 240 then return s:sub(i, i+3), 4
  elseif b >= 224 then return s:sub(i, i+2), 3
  elseif b >= 192 then return s:sub(i, i+1), 2
  else return s:sub(i, i), 1 end
end

-- Build sequence of IPA base characters (no diacritics, no stress)
local function get_base_sequence(s)
  local seq = {}
  local i = 1
  while i <= #s do
    local ch, adv = char_at(s, i)
    if not ch then break end
    local b1 = ch:byte(1)
    -- Skip combining diacritics (start with 203 or 204)
    if b1 == 203 or b1 == 204 then
      -- skip
    elseif ch == "ˈ" or ch == "," or ch == "." or ch == " " or ch == "'" then
      -- skip stress, pause, space
    else
      table.insert(seq, ch)
    end
    i = i + adv
  end
  return seq
end

-- Check if character is a vowel (Irish IPA)
local function is_v(ch)
  if not ch then return false end
  if #ch == 1 then
    return ch == "a" or ch == "e" or ch == "i" or ch == "o" or ch == "u"
  end
  if #ch == 2 then
    local b1, b2 = ch:byte(1), ch:byte(2)
    if b1 == 201 then
      return b2 == 153 -- schwa
          or b2 == 155 -- epsilon
          or b2 == 170 -- iota_bar
          or b2 == 148 -- open_o
          or b2 == 145 -- alpha
          or b2 == 164 -- ram's_horn
    end
    if b1 == 202 then
      return b2 == 138 -- upsilon
    end
    if b1 == 195 and b2 == 166 then return true end -- ash
  end
  return false
end

-- Check if char is an Irish consonant in IPA (including non-syllabic glides)
local function is_c(ch)
  if not ch then return false end
  if #ch == 1 then
    local singles = {b=98, d=100, f=102, g=103, h=104, j=106, k=107,
                     l=108, m=109, n=110, p=112, r=114, s=115, t=116,
                     v=118, w=119, x=120, z=122}
    return singles[ch] ~= nil
  end
  if #ch == 2 then
    local b1, b2 = ch:byte(1), ch:byte(2)
    if b1 == 201 then
      return b2 == 190  -- fishhook_r
          or b2 == 163  -- gamma
          or b2 == 178  -- n_with_left_hook
          or b2 == 159  -- dotless_j_with_stroke
          or b2 == 161  -- single_story_g
          or b2 == 166  -- hooktop_h
    end
    if b1 == 202 then
      return b2 == 131  -- esh
    end
    if b1 == 195 and b2 == 167 then return true end -- c_cedilla
    if b1 == 197 and b2 == 139 then return true end -- eng
  end
  return false
end

-- Known voiced stops in Irish IPA
local function is_voiced_stop(ch)
  if not ch then return false end
  if #ch == 1 then
    return ch == "b" or ch == "d" or ch == "g"
  end
  if #ch == 2 then
    local b1, b2 = ch:byte(1), ch:byte(2)
    return (b1 == 201) and (b2 == 159 or b2 == 161) -- dotless_j_stop, single_story_g
  end
  return false
end

-- Known sonorants in Irish
local function is_sonorant(ch)
  if not ch then return false end
  if #ch == 1 then
    local s = {m=true, n=true, l=true, r=true, j=true, w=true}
    return s[ch] == true
  end
  if #ch == 2 then
    local b1, b2 = ch:byte(1), ch:byte(2)
    if b1 == 201 and b2 == 190 then return true end -- fishhook_r
    if b1 == 201 and b2 == 178 then return true end -- n_with_left_hook
    if b1 == 197 and b2 == 139 then return true end -- eng
  end
  return false
end

-- Check if char is an obstruent (non-sonorant consonant)
local function is_obstruent(ch)
  if not ch then return false end
  if ch == "h" then return true end -- h is a fricative
  return is_c(ch) and not is_sonorant(ch)
end

-- Scan for violations
local violations = {}

for word, entry in pairs(bench) do
  local got = engine.transcribe(word, "connacht")
  local variants = {}
  for v in entry.expected:gmatch("[^,]+") do table.insert(variants, trim(v)) end
  local expected = variants[1] or ""

  local seq = get_base_sequence(got)
  if #seq < 2 then goto continue end

  for j = 1, #seq - 1 do
    local c1 = seq[j]
    local c2 = seq[j+1]

    -- VIOLATION: Voiced stop + h (impossible cluster in Irish)
    if c2 == "h" and is_voiced_stop(c1) then
      table.insert(violations, {
        word=word, got=got, exp=expected,
        cat="voiced_stop_h", detail=c1.."h",
        desc="voiced stop + h: impossible cluster"
      })
      goto next_word
    end

    -- VIOLATION: gamma before obstruent (gamma only before vowels/sonorants)
    -- gamma = 201,163
    if c2 ~= "h" and #c1 == 2 and c1:byte(1) == 201 and c1:byte(2) == 163 then
      if is_obstruent(c2) then
        table.insert(violations, {
          word=word, got=got, exp=expected,
          cat="gamma_before_obstruent", detail="gamma+"..c2,
          desc="gamma before obstruent"
        })
        goto next_word
      end
    end

    -- VIOLATION: c_cedilla before obstruent (should only precede vowels or sonorants)
    -- c_cedilla = 195,167
    if #c1 == 2 and c1:byte(1) == 195 and c1:byte(2) == 167 then
      if is_obstruent(c2) then
        table.insert(violations, {
          word=word, got=got, exp=expected,
          cat="c_cedilla_before_obstruent", detail="c_cd+"..c2,
          desc="c_cedilla before obstruent"
        })
        goto next_word
      end
    end

    -- VIOLATION: h between two consonants (needs vowel adjacency)
    if c1 == "h" and is_c(c2) and j > 1 and is_c(seq[j-1]) then
      table.insert(violations, {
        word=word, got=got, exp=expected,
        cat="h_between_cons", detail=seq[j-1].."h"..c2,
        desc="h between two consonants"
      })
      goto next_word
    end
  end

  ::next_word::
  ::continue::
end

-- Sort by severity
local severity_map = {
  voiced_stop_h=5, gamma_before_obstruent=3,
  c_cedilla_before_cons=2, h_between_cons=1
}
table.sort(violations, function(a,b)
  local sa = severity_map[a.cat] or 1
  local sb = severity_map[b.cat] or 1
  if sa ~= sb then return sa > sb end
  return #a.got > #b.got
end)

print("=== PHONOTACTIC VIOLATIONS IN IRISH G2P OUTPUT ===")
print("")
if #violations == 0 then
  print("None found -- all outputs are phonetically possible in Irish.")
else
  for _, v in ipairs(violations) do
    print("["..v.cat.."] "..v.detail.."  "..v.word.."  -- "..v.desc)
    print("  GOT: "..v.got)
    print("  EXP: "..v.exp)
    print("")
  end
  print("Total: "..#violations.." violations found")
end
