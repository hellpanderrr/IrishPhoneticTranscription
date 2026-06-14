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
      end

      i = i + 1
    end
    return new_tokens
  end,
}
