-- Pass #10: Resolve vowel tokens to IPA.
-- Dialect-aware via context.dialect.
-- Handles short/long/diphthong mappings plus contextual allophony.

local S = require("passes._shared")

return {
  name = "vowels",
  writes_context = false,

  run = function(tokens, context)
    local dv = S.DIALECTS[context.dialect] or S.DIALECTS.connacht

    for i, token in ipairs(tokens) do
      if token.type ~= "vowel" then goto continue end
      if token.is_epenthetic then goto continue end

      local ortho = token.ortho
      local next = tokens[i + 1]
      local prev = tokens[i - 1]

      -- Guard: only resolve if vowel wasn't modified by earlier passes.
      -- phon == ortho means unresolved.
      -- For 'a' where phon 'a' == ortho 'a', check source flag.
      local need_resolve = (token.phon == ortho or token.phon == nil or token.phon == "")
      if ortho == "a" and token.phon == "a" and token.source == "lexeme" then
        need_resolve = true
      end

      if need_resolve then
        if next and next.type == "cons" and next.ortho == "dh" and
           (ortho == "a" or ortho == "ai" or ortho == "á" or ortho == "aí") then
          -- Only raise to long vowel when stressed. Unstressed suffix -adh
          -- (verb endings) should keep a short vowel so reduction can apply
          -- (producing u/ə/tʲ as the final syllable, not ɑː).
          if ortho == "aí" then token.phon = "ɑːiː"
          elseif token.stress then token.phon = "ɑː" end
        elseif ortho == "aoi" then token.phon = "iː"
        elseif ortho == "ao" then token.phon = dv.ao
        elseif ortho == "eo" then token.phon = dv.eo
        elseif ortho == "ea" then token.phon = dv.ea
        elseif ortho == "ae" then token.phon = "eː"
        elseif ortho == "ei" then token.phon = "ɛ"
        elseif ortho == "ai" then token.phon = dv.ai
        elseif ortho == "oi" then token.phon = dv.oi
        elseif ortho == "ui" then token.phon = dv.ui
        elseif ortho == "ua" then token.phon = dv.ua
        elseif ortho == "ia" then token.phon = dv.ia
        elseif ortho == "éi" then token.phon = dv["éi"]
        elseif ortho == "éa" then token.phon = "eː"
        elseif ortho == "ío" then token.phon = dv["ío"]
        elseif ortho == "eoi" then token.phon = dv.eo
        elseif ortho == "aí" or ortho == "ái" then token.phon = "ɑː"
        elseif ortho == "óí" or ortho == "ó" then token.phon = (dv.long and dv.long.o) or "oː"
        elseif ortho == "ú" then token.phon = (dv.long and dv.long.u) or "uː"
        elseif ortho == "í" then token.phon = (dv.long and dv.long.i) or "iː"
        elseif ortho == "é" then token.phon = (dv.long and dv.long.e) or "eː"
        elseif ortho == "á" then token.phon = (dv.long and dv.long.a) or "ɑː"
        elseif ortho == "o" then token.phon = (dv.short and dv.short.o) or "ɔ"
        elseif ortho == "u" then token.phon = (dv.short and dv.short.u) or "ʊ"
        elseif ortho == "i" then token.phon = (dv.short and dv.short.i) or "ɪ"
        elseif ortho == "e" then token.phon = (dv.short and dv.short.e) or "ɛ"
        elseif ortho == "a" then token.phon = (dv.short and dv.short.a) or "a"
        end
      end

      -- Unstressed diphthong digraphs → short vowels so reduction can produce ə
      if not token.stress then
        if ortho == "ai" and token.phon == "ai" then
          token.phon = "a"
        elseif ortho == "oi" and token.phon == "ɔi" then
          token.phon = "ɔ"
        elseif ortho == "ui" and token.phon == "ʊi" then
          token.phon = "ʊ"
        end
      end

      -- /x/ palatal non-assimilation: blocks vowel fronting
      -- bocht → bˠɔxt̪ˠ, NOT *bˠɪxʲtʲə
      local has_x_block = next and next.type == "cons" and next.ortho == "ch"

      -- Contextual: consonant polarity affects vowel quality
      if next and next.type == "cons" and not has_x_block then
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
