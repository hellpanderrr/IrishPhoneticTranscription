-- Pass #13: Strong sonorants.
-- Vowel lengthening/diphthongization before strong sonorants (nn, ll, rr, mm).
-- This pass IS restricted to monosyllables or word-final positions.

local S = require("passes._shared")

return {
  name = "sonorants",
  writes_context = false,

  run = function(tokens, context)
    if not context.is_monosyllabic and not context.root_vowel_count then
      return tokens  -- only affects monosyllables and word-final positions
    end

    -- Check if the word ends with a strong sonorant
    local last_cons = nil
    for i = #tokens, 1, -1 do
      if tokens[i].type == "cons" then
        last_cons = tokens[i]
        break
      end
    end

    if not last_cons then return tokens end

    local is_strong_sonorant = last_cons.ortho == "nn" or last_cons.ortho == "ll" or
                               last_cons.ortho == "rr" or last_cons.ortho == "mm" or
                               last_cons.ortho == "n" or last_cons.ortho == "l"

    if not is_strong_sonorant then return tokens end

    -- Find the vowel before this sonorant
    local prev_vowel = S.find_preceding_vowel(tokens, #tokens)

    if not prev_vowel then return tokens end

    -- Only modify if vowel hasn't been modified by earlier passes
    if prev_vowel.phon ~= prev_vowel.ortho then return tokens end

    -- Check: monosyllable root (vowel is the only root vowel)
    -- Or: the preceding consonant is the sonorant directly (no intervening cons)
    local ortho = prev_vowel.ortho

    -- Lengthen a before nn/ll in monosyllables
    if ortho == "a" then
      prev_vowel.phon = "ɑː"

    elseif ortho == "o" then
      prev_vowel.phon = "oː"

    elseif ortho == "u" then
      prev_vowel.phon = "uː"

    elseif ortho == "i" then
      prev_vowel.phon = "iː"

    elseif ortho == "e" then
      prev_vowel.phon = "eː"
    end

    return tokens
  end,
}
