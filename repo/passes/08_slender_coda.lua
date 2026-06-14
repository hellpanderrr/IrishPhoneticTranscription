-- Pass #8: Vowel gradation before slender codas.
-- Before lt/rt -> [ɛ]
-- Before slender ng -> [ɪ]
-- Before slender nn -> [ɪ]

local S = require("passes._shared")

return {
  name = "slender_coda",
  writes_context = false,

  run = function(tokens, context)
    for i = 1, #tokens do
      local token = tokens[i]
      if token.type ~= "vowel" then goto continue end

      -- Only apply if vowel hasn't been modified by an earlier pass
      if token.phon ~= token.ortho and token.phon ~= nil and token.phon ~= "" then
        goto continue
      end

      local next = tokens[i + 1]
      local next2 = tokens[i + 2]

      -- Before lt/rt (slender coda pair)
      if next and next.type == "cons" and next2 and next2.type == "cons" and
         ((next.ortho == "l" and next2.ortho == "t") or
          (next.ortho == "r" and next2.ortho == "t")) then
        if token.ortho == "ai" or token.ortho == "a" then
          token.phon = "ɛ"
        end

      -- Before ng
      elseif next and next.type == "cons" and next.ortho == "ng" then
        token.phon = "ɪ"
      end

      ::continue::
    end
    return tokens
  end,
}
