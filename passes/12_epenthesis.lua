-- Pass #12: Epenthesis (Svarabhakti vowel insertion).
-- Inserts a vowel between heterorganic sonorant+voiced-obstruent
-- clusters when the preceding vowel is SHORT and STRESSED.
-- NOT restricted to monosyllables. (Corrected per Hickey Chapter 2)

local S = require("passes._shared")

local function is_heterorganic_cluster(tokens, i)
  local t1 = tokens[i]
  local t2 = tokens[i + 1]
  if not t1 or not t2 then return false end
  -- Heterorganic: sonorant followed by a different-place obstruent
  -- Broad clusters: rC, lC, nC (where C is a stop like b/d/g)
  local sonorants_broad = { r = true, l = true, n = true }
  if sonorants_broad[t1.ortho] then
    if t2.ortho == "b" or t2.ortho == "d" or t2.ortho == "g" then
      return true
    end
  end
  return false
end

return {
  name = "epenthesis",
  writes_context = false,

  run = function(tokens, context)
    local new_tokens = {}
    local i = 1
    while i <= #tokens do
      table.insert(new_tokens, tokens[i])

      -- Check: current token is sonorant, next is voiced obstruent
      if S.is_sonorant(tokens[i]) and tokens[i + 1] and S.is_voiced_obstruent(tokens[i + 1]) then
        -- Find preceding vowel
        local prev_vowel = S.find_preceding_vowel(tokens, i)
        -- Condition: preceding vowel is stressed AND short
        if prev_vowel and prev_vowel.stress and S.is_short_vowel(prev_vowel) then
          -- Insert epenthetic vowel matching the preceding consonant polarity
          local epenthetic = S.clone_token(tokens[i])
          epenthetic.type = "vowel"
          epenthetic.phon = "ə"
          epenthetic.is_epenthetic = true
          epenthetic.stress = false
          epenthetic.source = "epenthesis"
          if tokens[i].palatal == true then
            epenthetic.ortho = "i"
          else
            epenthetic.ortho = "a"
          end
          table.insert(new_tokens, epenthetic)
        end

      -- Also handle l+bh/mh cluster: insert epenthetic schwa and change bh/mh -> vˠ/vʲ
      -- e.g. dealbh -> dʲalˠəvˠ, colbha -> kɔlˠəvˠə
      -- Only when bh/mh is word-final or followed by the final vowel (no more consonants after).
      elseif tokens[i] and tokens[i].ortho == "l" and tokens[i + 1] and
             (tokens[i + 1].ortho == "bh" or tokens[i + 1].ortho == "mh") then
        local prev_vowel = S.find_preceding_vowel(tokens, i)
        -- Check that bh/mh is word-final or followed only by a final vowel
        local bh_idx = i + 1
        local after_bh = tokens[bh_idx + 1]
        local is_final = after_bh == nil or after_bh.type == "boundary"
        local is_final_vowel = after_bh and after_bh.type == "vowel" and
          S.is_short_vowel(after_bh) and
          (tokens[bh_idx + 2] == nil or tokens[bh_idx + 2].type == "boundary")
        -- Condition: preceding vowel is short AND bh/mh is at word end or before final vowel
        if prev_vowel and S.is_short_vowel(prev_vowel) and (is_final or is_final_vowel) then
          -- Insert epenthetic schwa
          local epenthetic = S.clone_token(tokens[i])
          epenthetic.type = "vowel"
          epenthetic.phon = "ə"
          epenthetic.is_epenthetic = true
          epenthetic.stress = false
          epenthetic.source = "epenthesis"
          if tokens[i].palatal == true then
            epenthetic.ortho = "i"
          else
            epenthetic.ortho = "a"
          end
          table.insert(new_tokens, epenthetic)
          -- Change bh/mh from w to vˠ (broad) or vʲ (slender)
          if tokens[i + 1].palatal == true then
            tokens[i + 1].phon = "vʲ"
          else
            tokens[i + 1].phon = "vˠ"
          end
        end
      end

      i = i + 1
    end
    return new_tokens
  end,
}
