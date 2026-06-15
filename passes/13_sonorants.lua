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
    if not context.is_monosyllabic then
      return tokens
    end

    -- Find consecutive identical sonorants at word end (nn, ll, rr, mm)
    local last_idx = #tokens
    local penult = tokens[last_idx - 1]
    local last = tokens[last_idx]

    if not penult or not last then return tokens end
    if penult.type ~= "cons" or last.type ~= "cons" then return tokens end
    if penult.ortho ~= last.ortho then return tokens end
    if penult.ortho ~= "n" and penult.ortho ~= "l" and
       penult.ortho ~= "r" and penult.ortho ~= "m" then return tokens end

    -- Override phon directly (consonants pass already ran).
    -- Strong sonorants are inherently broad/velarized in Irish.
    if penult.ortho == "n" then
      penult.phon = "n̪ˠ"
    elseif penult.ortho == "l" then
      penult.phon = "lˠ"
    elseif penult.ortho == "r" then
      penult.phon = "ɾˠ"
    elseif penult.ortho == "m" then
      penult.phon = "mˠ"
    end
    penult.source = "strong_sonorant"
    last.phon = ""
    last.source = "strong_sonorant"

    -- Find the vowel before this geminate sonorant
    local prev_vowel = tokens[last_idx - 2]
    if not prev_vowel or prev_vowel.type ~= "vowel" then return tokens end

    local ortho = prev_vowel.ortho
    -- Handle digraphs: ea → aː before strong sonorant
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

    return tokens
  end,
}
