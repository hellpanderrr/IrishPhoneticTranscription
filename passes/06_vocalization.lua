-- Pass #6: Vocalize vowel+fricative sequences.
-- Stress-aware: -adh stressed -> [ai/eː], unstressed -> [ə].
-- ea+bh -> [əu], u+gh -> [uː], a/o/u+bh/mh -> [əu].
-- NOTE: Does NOT silence the fricative — that's handled by pass #9b (vowel_adjunct)
-- after consonants have been resolved by pass #9.

local S = require("passes._shared")

return {
  name = "vocalization",
  writes_context = false,

  run = function(tokens, context)
    for i = 1, #tokens - 1 do
      local vowel = tokens[i]
      local fricative = tokens[i + 1]
      if vowel.type ~= "vowel" or not S.is_vocalizable_fricative(fricative) then
        goto continue
      end

      local is_slender = vowel.ortho == "e" or vowel.ortho == "i" or vowel.ortho == "ea"

      if vowel.ortho == "ea" and (fricative.ortho == "bh" or fricative.ortho == "mh") then
        vowel.phon = "əu"
      elseif fricative.ortho == "bh" or fricative.ortho == "mh" then
        if is_slender then
          vowel.phon = "əi"
        elseif vowel.ortho == "a" or vowel.ortho == "o" or vowel.ortho == "u" then
          vowel.phon = "əu"
        end
      elseif fricative.ortho == "dh" or fricative.ortho == "gh" then
        if vowel.stress then
          -- Stressed: produce diphthong
          if is_slender then
            vowel.phon = "əi"
          elseif vowel.ortho == "a" or vowel.ortho == "o" or vowel.ortho == "u" then
            vowel.phon = "ai"
          end
        else
          -- Unstressed a/dh, o/dh, u/dh → ə (for subsequent reduction)
          vowel.phon = "ə"
        end
      end

      -- Note: fricative is NOT silenced here. Let pass #9 resolve it,
      -- then pass #9b may silence it if needed.

      ::continue::
    end

    return tokens
  end,
}
