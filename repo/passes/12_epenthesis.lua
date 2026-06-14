-- Pass #12: Epenthesis (Svarabhakti vowel insertion).
-- Inserts a vowel between heterorganic sonorant+voiced-obstruent
-- clusters when the preceding vowel is SHORT and STRESSED.
-- NOT restricted to monosyllables! (Corrected per design review)

local S = require("passes._shared")

return {
  name = "epenthesis",
  writes_context = false,

  run = function(tokens, context)
    local new_tokens = {}
    local i = 1
    while i <= #tokens do
      table.insert(new_tokens, tokens[i])
      local token = tokens[i]

      -- Check: current token is sonorant, next is voiced obstruent
      if S.is_sonorant(token) then
        local next_t = tokens[i + 1]
        if S.is_voiced_obstruent(next_t) then
          -- Find preceding vowel
          local prev_vowel = S.find_preceding_vowel(tokens, i)
          -- Condition: preceding vowel is stressed AND short
          if prev_vowel and prev_vowel.stress and S.is_short_vowel(prev_vowel) then
            -- Insert epenthetic vowel matching the preceding consonant polarity
            local epenthetic = S.clone_token(token)
            epenthetic.type = "vowel"
            epenthetic.phon = "ə"
            epenthetic.is_epenthetic = true
            epenthetic.stress = false
            epenthetic.source = "epenthesis"
            -- Set ortho to ə or ɪ depending on palatal context
            if token.palatal == true then
              epenthetic.ortho = "i"
            else
              epenthetic.ortho = "a"
            end
            table.insert(new_tokens, epenthetic)
          end
        end
      end

      i = i + 1
    end
    return new_tokens
  end,
}
