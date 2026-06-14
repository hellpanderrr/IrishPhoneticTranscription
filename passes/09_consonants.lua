-- Pass #9: Resolve consonant tokens to IPA.
-- Handles broad/slender alternation and voiceless sonorants.

local S = require("passes._shared")

return {
  name = "consonants",
  writes_context = false,

  run = function(tokens, context)
    for i, token in ipairs(tokens) do
      if token.type ~= "cons" then goto continue end

      local prev = tokens[i - 1]

      if token.ortho == "bh" or token.ortho == "mh" then
        if token.palatal == true then
          token.phon = "vʲ"
        elseif token.palatal == false then
          token.phon = "w"
        else
          token.phon = "vˠ"
        end
      elseif token.ortho == "ch" then
        if token.palatal == true then
          token.phon = i == 1 and "ç" or "h"
        else
          token.phon = "x"
        end
      elseif token.ortho == "sh" then
        token.phon = "h"
      elseif token.ortho == "th" then
        if i == #tokens then
          token.phon = ""
        else
          token.phon = "h"
        end
      elseif token.ortho == "dh" or token.ortho == "gh" then
        local next = tokens[i + 1]
        if i == #tokens or (next and next.type == "cons") then
          token.phon = ""
        elseif token.palatal == true then
          token.phon = "j"
        else
          token.phon = "ɣ"
        end
      elseif token.ortho == "ph" then
        token.phon = S.palatal_consonant(token, "fʲ", "fˠ")
      elseif token.ortho == "fh" then
        token.phon = ""
      elseif token.ortho == "bhf" then
        token.phon = "w"
      elseif token.ortho == "s" then
        local next = tokens[i + 1]
        if next and (next.ortho == "p" or next.ortho == "t" or next.ortho == "k") then
          token.phon = "ʃ"
        elseif token.palatal == true then
          token.phon = "ʃ"
        else
          token.phon = "sˠ"
        end
      elseif token.ortho == "c" then
        token.phon = S.palatal_consonant(token, "c", "k")
      elseif token.ortho == "g" then
        token.phon = S.palatal_consonant(token, "ɟ", "ɡ")
      elseif token.ortho == "t" then
        token.phon = S.palatal_consonant(token, "tʲ", "t̪ˠ")
      elseif token.ortho == "d" then
        token.phon = S.palatal_consonant(token, "dʲ", "d̪ˠ")
      elseif token.ortho == "n" then
        if token.is_voiceless then
          token.phon = S.palatal_consonant(token, "n̥", "n̪ˠ")
        else
          token.phon = S.palatal_consonant(token, "nʲ", "n̪ˠ")
        end
      elseif token.ortho == "ng" then
        token.phon = S.palatal_consonant(token, "ɲ", "ŋ")
      elseif token.ortho == "l" then
        if token.is_voiceless then
          token.phon = S.palatal_consonant(token, "l̥", "lˠ")
        else
          token.phon = S.palatal_consonant(token, "lʲ", "lˠ")
        end
      elseif token.ortho == "r" then
        if token.is_voiceless then
          token.phon = S.palatal_consonant(token, "r̥", "ɾˠ")
        else
          token.phon = S.palatal_consonant(token, "ɾʲ", "ɾˠ")
        end
      elseif token.ortho == "f" then
        token.phon = S.palatal_consonant(token, "fʲ", "fˠ")
      elseif token.ortho == "b" then
        token.phon = S.palatal_consonant(token, "bʲ", "bˠ")
      elseif token.ortho == "m" then
        if token.is_voiceless then
          token.phon = S.palatal_consonant(token, "m̥", "mˠ")
        else
          token.phon = S.palatal_consonant(token, "mʲ", "mˠ")
        end
      elseif token.ortho == "p" then
        token.phon = S.palatal_consonant(token, "pʲ", "pˠ")
      end

      ::continue::
    end
    return tokens
  end,
}
