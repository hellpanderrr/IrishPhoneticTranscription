-- Pass #10: Resolve vowel tokens to IPA.
-- Dialect-aware via context.dialect.
-- Handles short/long/diphthong mappings plus contextual allophony.

local S = require("passes._shared")

return {
  name = "vowels",
  writes_context = false,

  run = function(tokens, context)
    local dialect_values = S.DIALECTS[context.dialect] or S.DIALECTS.connacht

    for i, token in ipairs(tokens) do
      if token.type ~= "vowel" then goto continue end
      if token.is_epenthetic then goto continue end  -- skip epenthetic vowels

      local ortho = token.ortho
      local next = tokens[i + 1]
      local prev = tokens[i - 1]

      -- Only apply default mapping if not already modified by an earlier pass
      if token.phon == ortho or token.phon == nil or token.phon == "" then
        if next and next.type == "cons" and next.ortho == "dh" and
           (ortho == "a" or ortho == "ai" or ortho == "á" or ortho == "aí") then
          if ortho == "aí" then token.phon = "ɑːiː"
          else token.phon = "ɑː" end
        elseif ortho == "aoi" then token.phon = "iː"
        elseif ortho == "ao" then token.phon = dialect_values.ao
        elseif ortho == "eo" then token.phon = dialect_values.eo
        elseif ortho == "ea" then token.phon = dialect_values.ea
        elseif ortho == "ae" then token.phon = "eː"
        elseif ortho == "aí" or ortho == "ái" then token.phon = "ɑː"
        elseif ortho == "óí" or ortho == "ó" then token.phon = "oː"
        elseif ortho == "ú" then token.phon = "uː"
        elseif ortho == "í" then token.phon = "iː"
        elseif ortho == "é" then token.phon = "eː"
        elseif ortho == "á" then token.phon = "ɑː"
        elseif ortho == "o" then token.phon = "ɔ"
        elseif ortho == "u" then token.phon = "ʊ"
        elseif ortho == "i" then token.phon = "ɪ"
        elseif ortho == "e" then token.phon = "ɛ"
        elseif ortho == "a" then token.phon = "a"
        end
      end

      -- Nasal raising (only if vowel wasn't already overridden to non-ortho value)
      if token.phon == ortho or token.phon == nil or token.phon == "" then
        local is_broad_nasal = next and next.type == "cons" and
            (next.ortho == "nn" or next.ortho == "ng") and
            (next.palatal == false or next.palatal == nil)
        local is_geminate_n = next and next.type == "cons" and next.ortho == "n" and
            tokens[i + 2] and tokens[i + 2].type == "cons" and tokens[i + 2].ortho == "n"

        if is_broad_nasal or is_geminate_n then
          if ortho == "o" or ortho == "ó" or ortho == "u" then
            token.phon = "uː"
          end
        end
      end

      -- Broad o default (only if not already nasal-raised)
      if ortho == "o" and next and next.type == "cons" and next.palatal == false then
        if token.phon == ortho or token.phon == nil or token.phon == "" then
          token.phon = "ɔ"
        end
      end

      -- ío
      if ortho == "ío" and (token.phon == ortho or token.phon == nil or token.phon == "") then
        token.phon = "iː"
      end

      -- Contextual: consonant polarity affects vowel quality
      if next and next.type == "cons" then
        if next.palatal == true and (ortho == "o" or ortho == "u") then
          token.phon = "ɪ"
        elseif next.palatal == true and ortho == "a" and not token.stress then
          token.phon = "ɛ"
        elseif next.palatal == false and ortho == "i" and not token.stress then
          token.phon = "ə"
        elseif next.palatal == true and ortho == "e" and not token.stress then
          token.phon = "ɪ"
        elseif next.palatal == false and ortho == "e" and not token.stress then
          token.phon = "ə"
        end
      end

      -- dh triggers raising
      if next and next.type == "cons" and next.ortho == "dh" then
        if ortho == "o" or ortho == "u" then
          token.phon = "uː"
        end
      end

      -- Previous consonant polarity affects preceding vowel quality
      if prev and prev.type == "cons" then
        if prev.palatal == true then
          if token.phon == "ə" then token.phon = "ɪ" end
        elseif prev.palatal == false then
          if token.phon == "ɪ" and not token.stress then token.phon = "ə" end
        end
      end

      ::continue::
    end
    return tokens
  end,
}
