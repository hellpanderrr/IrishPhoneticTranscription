-- Pass 9b: Resolve vowel + mutated fricative adjuncts.
-- Runs after consonants (#9) but before vowels (#10).
-- mh/bh after certain vowels append iː to the vowel and silence the fricative.
-- This must run AFTER consonants resolve so that silhouette consonants
-- (like mh→vʲ) are detected, then silenced with their iː appended to the vowel.

local S = require("passes._shared")

return {
  name = "vowel_adjunct",
  writes_context = false,

  run = function(tokens, context)
    for i = 1, #tokens - 1 do
      local vowel = tokens[i]
      local fricative = tokens[i + 1]
      if vowel.type ~= "vowel" or fricative.type ~= "cons" then goto continue end

      if fricative.ortho == "mh" then
        if fricative.palatal == true then
          vowel.phon = vowel.phon .. "iː"
        elseif vowel.ortho == "ái" or vowel.ortho == "á" then
          vowel.phon = vowel.phon .. "iː"
        end
        fricative.phon = ""
      elseif fricative.ortho == "bh" and fricative.palatal == false and
             (vowel.ortho == "á" or vowel.ortho == "aí" or vowel.ortho == "ai") then
        if vowel.ortho == "aí" then
          vowel.phon = "ɑːiː"
        else
          vowel.phon = vowel.phon .. "iː"
        end
        fricative.phon = ""
      end

      ::continue::
    end
    return tokens
  end,
}
