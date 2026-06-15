-- Pass #13: Strong sonorants (Hickey Ch.2, Fuaimeanna 5.1).
-- Vowel lengthening/diphthongization before strong sonorants (nn, ll, rr, mm).
-- These geminate in spelling but tokenize as individual cons tokens.
-- Also handles consonant side: sets geminate sonorants to broad and silences
-- the second of the pair. peann → pʲaːnˠ, not pʲanʲnʲ.
-- Restricted to monosyllables or word-final position.
-- Runs after vowel resolution (#15).

local S = require("passes._shared")

return {
  name = "sonorants",
  writes_context = false,

  run = function(tokens, context)
    -- First pass: handle consecutive identical sonorants ANYWHERE in the word.
    -- This handles both geminate clusters (medium, carraig) and
    -- word-final geminates (peann, mall).
    for i = 1, #tokens - 1 do
      local first = tokens[i]
      local second = tokens[i + 1]
      if first.type ~= "cons" or second.type ~= "cons" then goto next_pair end
      if first.ortho ~= second.ortho then goto next_pair end
      if first.ortho ~= "n" and first.ortho ~= "l" and
         first.ortho ~= "r" and first.ortho ~= "m" then goto next_pair end

      -- Merge geminate sonorants: first becomes broad, second silenced.
      -- Strong sonorants are inherently broad/velarized in Irish.
      if first.ortho == "n" then first.phon = "n̪ˠ"
      elseif first.ortho == "l" then first.phon = "lˠ"
      elseif first.ortho == "r" then first.phon = "ɾˠ"
      elseif first.ortho == "m" then first.phon = "mˠ"
      end
      first.source = "strong_sonorant"
      second.phon = ""
      second.source = "strong_sonorant"

      -- Vowel lengthening before geminate sonorants only in monosyllables.
      -- (e.g., peann → pʲɑːn̪ˠ, but mallacht doesn't lengthen)
      if context.is_monosyllabic then
        local prev_vowel = tokens[i - 1]
        if prev_vowel and prev_vowel.type == "vowel" then
          local ortho = prev_vowel.ortho
          if ortho == "ea" then
            prev_vowel.phon = "aː"
            prev_vowel.source = "sonorant_lengthening"
          elseif ortho == "a" then
            prev_vowel.phon = "ɑː"
            prev_vowel.source = "sonorant_lengthening"
          elseif ortho == "o" then
            prev_vowel.phon = "oː"
            prev_vowel.source = "sonorant_lengthening"
          elseif ortho == "u" then
            prev_vowel.phon = "uː"
            prev_vowel.source = "sonorant_lengthening"
          end
        end
      end

      ::next_pair::
    end

    return tokens
  end,
}
