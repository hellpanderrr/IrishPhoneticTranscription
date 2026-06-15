-- Pass 9b: Resolve vowel + mutated fricative adjuncts.
-- Runs after consonants (#9) but before vowels (#10).
-- mh/bh after certain vowels append iː to the vowel and silence the fricative.
-- This must run AFTER consonants resolve so that silhouette consonants
-- (like mh→vʲ) are detected, then silenced with their iː appended to the vowel.

local S = require("passes._shared")
local ustring = require("ustring.ustring")
local ulen = ustring.len

return {
  name = "vowel_adjunct",
  writes_context = false,

  run = function(tokens, context)
    for i = 1, #tokens - 1 do
      local vowel = tokens[i]
      local fricative = tokens[i + 1]
      if vowel.type ~= "vowel" or fricative.type ~= "cons" then goto continue end

      if fricative.ortho == "mh" then
        -- Skip if vowel is a trigraph (aoi, eoi) — resolved entirely by pass 10
        if ulen(vowel.ortho) >= 3 then goto continue end
        -- Skip if fricative is followed by another consonant (syllable onset, not coda)
        local next_after = i + 2 <= #tokens and tokens[i + 2] or nil
        if next_after and next_after.type == "cons" then goto continue end

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
