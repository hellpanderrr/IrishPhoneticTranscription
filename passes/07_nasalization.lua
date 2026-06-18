-- Pass #7: Vowel nasal raising.
-- o/u/ó/ú -> [uː] before geminate nasals (nn, ng, doubled n n).
-- Runs after vocalization so vocalized forms aren't re-nasalized.

local S = require("passes._shared")

return {
  name = "nasalization",
  writes_context = false,

  run = function(tokens, context)
    for i, token in ipairs(tokens) do
      if token.type ~= "vowel" then goto continue end

      local next = tokens[i + 1]
      local ortho = token.ortho

      -- Only raise if vowel hasn't been modified by earlier passes
      if token.phon ~= ortho and token.phon ~= nil and token.phon ~= "" then
        goto continue
      end

      local is_broad_nasal = next and next.type == "cons" and
          (next.ortho == "nn" or next.ortho == "ng") and
          (next.palatal == false or next.palatal == nil)

      local is_geminate_n = next and next.type == "cons" and next.ortho == "n" and
          tokens[i + 2] and tokens[i + 2].type == "cons" and tokens[i + 2].ortho == "n"

      if is_broad_nasal or is_geminate_n then
        -- Only SHORT o/u raise before geminate nasals (Hickey: o->u before
        -- nasals). Long ó/ú already carry length and keep it (dhónna->oːn,
        -- not ʊn). brúnn keeps uː.
        if ortho == "o" or ortho == "u" then
          token.phon = "ʊ"
        end
      end

      ::continue::
    end
    return tokens
  end,
}
