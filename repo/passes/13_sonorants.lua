-- Pass #13: Strong sonorants.
-- Vowel lengthening/diphthongization before strong sonorants (nn, ll).
-- Restricted to monosyllables or word-final positions.

local S = require("passes._shared")

return {
  name = "sonorants",
  writes_context = false,

  run = function(tokens, context)
    if not context.is_monosyllabic then
      return tokens
    end

    -- Find the last consonant (checking for strong sonorant in word-final position)
    local last_cons = nil
    local last_idx = 0
    for i = #tokens, 1, -1 do
      if tokens[i].type == "cons" then
        last_cons = tokens[i]
        last_idx = i
        break
      end
    end

    if not last_cons then return tokens end

    local is_strong_sonorant = last_cons.ortho == "nn" or last_cons.ortho == "ll" or
                               last_cons.ortho == "rr" or last_cons.ortho == "mm"

    if not is_strong_sonorant then return tokens end

    -- Find the vowel before this sonorant (must be the vowel immediately preceding)
    local prev_vowel = tokens[last_idx - 1]
    if not prev_vowel or prev_vowel.type ~= "vowel" then return tokens end

    -- Only modify if vowel hasn't been modified by earlier passes
    if prev_vowel.phon ~= prev_vowel.ortho then return tokens end

    local ortho = prev_vowel.ortho
    if ortho == "a" then
      prev_vowel.phon = "ɑː"
    elseif ortho == "o" then
      prev_vowel.phon = "oː"
    elseif ortho == "u" then
      prev_vowel.phon = "uː"
    end

    return tokens
  end,
}
