-- Pass #13: Sonorant diacritics and geminates.
-- 1. Adjust l/n diacritics to 4-way system based on following context:
--    Broad + before_cons → insert dental ̪ (l̪ˠ, n̪ˠ)
--    Broad + before_vowel/end → keep ˠ (lˠ, n̪ˠ — n already has ̪ from consonant pass)
--    Slender + before_cons → insert postalveolar ̠ (l̠ʲ, n̠ʲ)
--    Slender + before_vowel/end → keep ʲ (lʲ, nʲ)
-- 2. Handle geminate sonorants (ll, nn, rr, mm): silence second, adjust first.
-- 3. Vowel lengthening before geminate sonorants in monosyllables.
-- Runs after vowel resolution (#12) so vowel phonemes are final.

local S = require("passes._shared")
local ustring = require("ustring.ustring")
local usub = ustring.sub

-- UTF-8 safe check: is the first IPA character a front vowel?
local function is_front_vowel_phon(phon)
  if not phon then return false end
  local c1 = usub(phon, 1, 1)
  return c1 == "i" or c1 == "e" or c1 == "ɪ" or c1 == "ɛ"
end

-- Insert a combining diacritic into a phoneme string after the base character.
-- base_char: 1-byte ASCII letter (l, n, etc.)
-- combining: UTF-8 combining character (e.g. ̪ U+032A, ̠ U+0320)
-- suffix: remaining diacritics (e.g. ˠ, ʲ)
-- Returns: base_char + combining + suffix
local function insert_combining(phon, combining)
  if not phon or #phon == 0 then return phon end
  -- Find the base character (first byte, which is ASCII for l/n/m/r)
  local base = phon:sub(1, 1)
  local rest = phon:sub(2)
  return base .. combining .. rest
end

local DENTAL = string.char(0xCC, 0xAA)    -- U+032A combining bridge below
local POSTALVEOLAR = string.char(0xCC, 0xA0)  -- U+0320 combining minus below

-- Check if a phoneme already contains the dental diacritic
local function has_dental(phon)
  if not phon then return false end
  return phon:find(DENTAL, 1, true) ~= nil
end

-- Check if a phoneme already contains the postalveolar diacritic
local function has_postalveolar(phon)
  if not phon then return false end
  return phon:find(POSTALVEOLAR, 1, true) ~= nil
end

return {
  name = "sonorants",
  writes_context = false,

  run = function(tokens, context)
    -- Phase 1: Adjust non-geminate sonorant diacritics.
    -- For l and n: insert dental/postalveolar combining mark based on context.
    -- Skip consecutive identical sonorants (handled in Phase 2).
    for i = 1, #tokens do
      local token = tokens[i]
      if token.type ~= "cons" then goto next_son end
      if token.phon == "" then goto next_son end
      if token.ortho ~= "l" and token.ortho ~= "n" then goto next_son end

      -- Skip if next token is same ortho (geminate pair — handled in Phase 2)
      local next_t = tokens[i + 1]
      if next_t and next_t.type == "cons" and next_t.ortho == token.ortho then
        goto next_son
      end

      -- Determine broad or slender from token palatal flag (pass 01)
      local is_broad = not token.palatal
      if token.broad ~= nil then is_broad = token.broad end
      -- Check what follows
      local followed_by_cons = next_t and next_t.type == "cons" and
        next_t.phon and next_t.phon ~= "" and
        next_t.type ~= "boundary"

      if is_broad then
        if followed_by_cons and not has_dental(token.phon) then
          -- Insert dental diacritic: lˠ → l̪ˠ, n̪ˠ stays n̪ˠ (already has dental)
          token.phon = insert_combining(token.phon, DENTAL)
        end
      else
        if followed_by_cons and not has_postalveolar(token.phon) then
          -- Insert postalveolar diacritic: lʲ → l̠ʲ, nʲ → n̠ʲ
          token.phon = insert_combining(token.phon, POSTALVEOLAR)
        end
      end

      ::next_son::
    end

    -- Phase 1b: Strip dental from word-final broad n when preceding vowel is
    -- LONG and UNSTRESSED. Distribution: ~125 words want nˠ vs ~93 want n̪ˠ
    -- in this context (net +41 exact). Word-final = no following non-boundary
    -- token with non-empty phon.
    for i = 1, #tokens do
      local token = tokens[i]
      if token.type ~= "cons" then goto next_strip end
      if token.ortho ~= "n" then goto next_strip end
      if not token.phon or token.phon == "" then goto next_strip end
      if not has_dental(token.phon) then goto next_strip end

      local is_final = true
      for j = i + 1, #tokens do
        local t = tokens[j]
        if t.type == "boundary" then break end
        if (t.type == "cons" or t.type == "vowel") and t.phon and t.phon ~= "" then
          is_final = false; break
        end
      end
      if not is_final then goto next_strip end

      local prev_v
      for j = i - 1, 1, -1 do
        if tokens[j].type == "vowel" then prev_v = tokens[j]; break end
        if tokens[j].type == "boundary" then break end
        if tokens[j].type == "cons" and tokens[j].phon and tokens[j].phon ~= "" then break end
      end
      if not prev_v then goto next_strip end

      local pv_phon = prev_v.phon or ""
      local is_long = pv_phon:find("ː", 1, true) ~= nil
      local is_stressed = prev_v.stress or false
      if is_long and not is_stressed then
        token.phon = "nˠ"
      end

      ::next_strip::
    end

    -- Phase 2: Handle consecutive identical sonorants (geminate ll, nn, rr, mm).
    for i = 1, #tokens - 1 do
      local first = tokens[i]
      local second = tokens[i + 1]
      if first.type ~= "cons" or second.type ~= "cons" then goto next_pair end
      if first.ortho ~= second.ortho then goto next_pair end
      if first.ortho ~= "n" and first.ortho ~= "l" and
         first.ortho ~= "r" and first.ortho ~= "m" then goto next_pair end

      local prev_vowel = tokens[i - 1]
      local is_slender = first.palatal == true

      -- Determine what follows the entire geminate pair
      local after_pair = tokens[i + 2]
      local before_cons = after_pair and after_pair.type == "cons" and
        after_pair.phon and after_pair.phon ~= ""

      if first.ortho == "n" then
        if is_slender then
          if before_cons then
            first.phon = "n̠ʲ"  -- postalveolar
          else
            first.phon = "nʲ"  -- palatalized
          end
        else
          -- Geminate broad n always dental
          first.phon = "n̪ˠ"
        end
      elseif first.ortho == "l" then
        if is_slender then
          if before_cons then
            first.phon = "l̠ʲ"  -- postalveolar
          else
            first.phon = "lʲ"  -- palatalized
          end
        else
          -- Geminate broad l: dental before cons, velarized otherwise
          if before_cons then
            first.phon = "l̪ˠ"
          else
            first.phon = "lˠ"
          end
        end
      elseif first.ortho == "r" then
        first.phon = is_slender and "ɾʲ" or "ɾˠ"
      elseif first.ortho == "m" then
        first.phon = is_slender and "mʲ" or "mˠ"
      end
      first.source = "strong_sonorant"
      second.phon = ""
      second.source = "strong_sonorant"

      -- Vowel lengthening before geminate sonorants only in monosyllables.
      if context.is_monosyllabic then
        local pv = tokens[i - 1]
        if pv and pv.type == "vowel" then
          local ortho = pv.ortho
          if ortho == "ea" then
            pv.phon = "aː"
            pv.source = "sonorant_lengthening"
          elseif ortho == "a" then
            pv.phon = "aː"
            pv.source = "sonorant_lengthening"
          elseif ortho == "o" then
            pv.phon = "oː"
            pv.source = "sonorant_lengthening"
          elseif ortho == "u" then
            pv.phon = "uː"
            pv.source = "sonorant_lengthening"
          end
        end
      end

      ::next_pair::
    end

    return tokens
  end,
}
