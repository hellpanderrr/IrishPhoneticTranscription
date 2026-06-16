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

      -- Check if this vowel is the first element of a VV pair (split digraph).
      local is_digraph_first = next and next.type == "vowel"

      -- Silencing standalone i when it's a palatalization marker.
      -- Pattern: vowel + i + consonant => i is always a palatal marker.
      -- The consonant already gets palatal=true from the polarity pass.
      if ortho == "i" and next and next.type == "cons" and prev and prev.type == "vowel" then
        token.phon = ""
        token.source = "palatal_marker_silenced"
        goto continue
      end

      -- Silencing i before u (palatalization marker in iú/iu patterns).
      -- Pattern: i + u => i is a palatalization marker, u carries the vowel.
      -- E.g., siúl → ʃuːlˠ, fiú → fʲuː
      if ortho == "i" and next and next.type == "vowel" and
         (next.ortho == "u" or next.ortho == "ú") then
        token.phon = ""
        token.source = "palatal_marker_silenced"
        goto continue
      end

      -- Handle ae digraph (split as a + e) BEFORE need_resolve guard.
      -- Resolve a+e → eː, silence the e token.
      if ortho == "a" and is_digraph_first and next.ortho == "e" then
        token.phon = "eː"
        next.phon = ""
        next.source = "ae_digraph_resolved"
        goto continue
      end

      -- Guard: only resolve if vowel wasn't modified by earlier passes.
      -- phon == ortho means unresolved.
      -- For 'a' where phon 'a' == ortho 'a', check source flag.
      local need_resolve = (token.phon == ortho or token.phon == nil or token.phon == "")
      if ortho == "a" and token.phon == "a" and token.source == "lexeme" then
        need_resolve = true
      end

      -- Skip need_resolve for vowels that are the first element of a VV pair.
      -- These are part of a split digraph (ia, io, iu, etc.).
      -- The dialect digraph resolution will set the correct phoneme.
      -- Without this guard, standalone i→ɪ, o→ɔ etc. would overwrite the digraph result.
      -- Exempt known digraph orthos (ae, ea, ai, etc.) which need need_resolve.
      if is_digraph_first and not S.VOWEL_DIGRAPHS[ortho] then
        need_resolve = false
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
        elseif ortho == "ai" and not next then token.phon = "iː"  -- word-final -aí
        elseif ortho == "ai" then token.phon = dv.ai
        elseif ortho == "oi" then token.phon = dv.oi
        elseif ortho == "ui" then token.phon = dv.ui
        elseif ortho == "ua" then token.phon = dv.ua
        elseif ortho == "ia" then token.phon = dv.ia
        elseif ortho == "éi" then token.phon = dv["éi"]
        elseif ortho == "éa" then token.phon = "eː"
        elseif ortho == "ío" then token.phon = dv["ío"]
        elseif ortho == "eoi" then token.phon = dv.eo
        elseif ortho == "ái" then
          -- ái: stressed long a + slender ending → ɑː (Connacht)
          local next_t = tokens[i + 1]
          if next_t and next_t.type == "cons" then
            token.phon = "ɑː"  -- medial: sráid → sˠɾˠɑːdʲ
          else
            token.phon = "iː"  -- word-final
          end
        elseif ortho == "aí" or (ortho == "ai" and not next) then
          -- aí: unstressed variant → word-final iː, medial short a
          local next_t = tokens[i + 1]
          if next_t and next_t.type == "cons" then
            token.phon = "a"  -- medial: resolve a+i short, reduction will handle
          else
            token.phon = "iː"  -- word-final: aí -> iː
          end
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
      -- Skip if phon already resolved to a long vowel (e.g. word-final -aí → iː)
      if not token.stress and token.phon ~= "iː" and token.phon ~= "ɑːiː" then
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
      if next and next.type == "cons" and not has_x_block and not is_digraph_first then
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

      -- oi before palatal consonant: front to ɛ (not back ɔ)
      -- goilim → ɡɛlʲəmʲ, foide → fˠɛdʲə, coire → kɛɾʲə
      if ortho == "oi" and next and next.type == "cons" and next.palatal == true then
        token.phon = "ɛ"
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
