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

      -- Stressed 'io' collapses to [ʊ] before certain consonants (Summary
      -- Ch.1 5.2.3: /ʊ/ from <io> in stressed syllable, e.g. iomarca,
      -- piocadh). The following o is silenced. Covers:
      --  - io+m : iom- prefix (iomlan, iompar, iomra, ...), liom- (liomog)
      --  - io+c : the tiocf- future (tiocfad, dtiocfa, thiocfa) and pioc/phioc
      --  - io+f : Stiofan/Stiofain
      --  - io+bh: Siobhan
      -- Does not apply when stress is non-initial (iomanaiocht -> ə'mɑːn...).
      if ortho == "i" and token.stress and
         next and next.type == "vowel" and next.ortho == "o" and
         tokens[i + 2] and tokens[i + 2].type == "cons" then
        local c2 = tokens[i + 2]
        local c3 = tokens[i + 3]
        local collapse_u = false
        if c2.ortho == "m" then
          collapse_u = true
        elseif c2.ortho == "c" then
          -- tiocf- (c followed by f) or word-final pioc/phioc
          collapse_u = (c3 and c3.type == "cons" and c3.ortho == "f") or
                     (c3 == nil or c3.type == "boundary")
        elseif c2.ortho == "f" then
          collapse_u = true
        elseif c2.ortho == "bh" then
          collapse_u = true
        end
        if collapse_u or c2.type == "cons" then
          local use_i = false
          if not collapse_u and context.word_ortho then
            local w = context.word_ortho:lower()
            if w == "ciorcal" or w == "giota" or w == "giorracht" or w == "ionadaí" or w == "liopard" or w == "tionscadal" then
              use_i = true
            end
          end
          token.phon = collapse_u and "\xca\x8a" or (use_i and "i" or "\xc9\xaa")
          token.source = "io_collapse"
          next.phon = ""
          next.source = "io_collapse"
          next.is_epenthetic = true
          goto continue
        end
      end

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

      -- thig, thit: lenited t raises short i to i in Connacht
      if ortho == "i" and token.phon == "ɪ" and context.word_ortho then
        local w = context.word_ortho:lower()
        if w == "thig" or w == "thit" then
          token.phon = "i"
        end
      end

      -- Lexical overrides: specific words where short i should be i not ɪ.
      -- Only for stressed vowels (pass 11 reduction won't touch unstressed ones).
      if ortho == "i" and token.phon == "ɪ" and token.stress and context.word_ortho then
        local w = context.word_ortho:lower()
        if w == "im" or w == "ime" or w == "imeacht" or w == "imigh" or
           w == "imím" or w == "imleacán" or w == "imreas" or w == "hime" or
           w == "itheann" or w == "ite" or w == "ithir" or
           w == "dile" or w == "liopard" or w == "mise" or w == "nis" or
           w == "mithid" or w == "minic" or w == "titim" or
           w == "tionscadal" or w == "bindealán" or w == "cisteanach" or
           w == "litreach" or w == "cluife" or w == "cluifí" or
           w == "gaeilic" or w == "cuingir" or w == "clismirt" or
           w == "muiris" or w == "roimis" or w == "iníona" or
           w == "inseoidh" or w == "innealtóir" or w == "ionadaí" or
           w:find("mire") or w:find("mhire")
        then
          token.phon = "i"
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
        if next.ortho == "n" or next.ortho == "m" or next.ortho == "t" then
          token.phon = "ɪ"
        elseif (next.ortho == "b" or next.ortho == "p" or next.ortho == "d" or next.ortho == "g" or next.ortho == "c") then
          -- Word-final: check nothing substantial follows
          local wf = true
          for j = i + 2, #tokens do
            local t2 = tokens[j]
            if t2.type == "boundary" then break end
            if (t2.type == "cons" or t2.type == "vowel") and t2.phon and t2.phon ~= "" then
              wf = false; break
            end
          end
          if wf then token.phon = "ɪ" else token.phon = "ɛ" end
        else
          token.phon = "ɛ"
        end
      end

      -- ui before palatal consonant: front to ɪ (not back ʊ)
      -- muiníneach → mˠɪnʲiːnʲəx, cuireann → kɪɾʲən̪ˠ
      if ortho == "ui" and next and next.type == "cons" and next.palatal == true then
        token.phon = "ɪ"
      end

      -- uisce: standalone word wants i, not ɪ
      if ortho == "ui" and context.word_ortho then
        local w = context.word_ortho:lower()
        if w == "uisce" or w == "cuirim" or w == "cuideachta" or
           w == "cuid" or w == "cuisle" or w == "cuileog" or
           w == "cuingir" or w == "muiris" or w == "muirnín" or
           w == "cuidhil" or w == "cuimhnigh" or w == "fuinneoige" or
           w == "buile" then
          token.phon = "i"
        end
      end

      -- dh triggers raising
      if next and next.type == "cons" and next.ortho == "dh" then
        if ortho == "o" or ortho == "u" then
          token.phon = "uː"
        end
      end

      -- Word-ending patterns: set no_reduce or restore_i on vowels that should survive reduction
      if not token.stress then
        local w = context.word_ortho
        if w then
          -- Ends in "ig" (orthographic -g): aisig, oifig, rainig
          if w:match("[^r]ig$") and next and next.type == "cons" and next.phon == "ɟ" then
            token.restore_i = true
          end
          -- Ends in "aic": Afraic, aonraic, diuraic
          if w:match("aic$") and ortho == "ai" and next and next.type == "cons" and next.phon == "c" then
            token.phon = "ɪ"; token.no_reduce = true
          end
          -- Ends in "is" (consonant + is): Inis, Peirsis, Soirbis
          if not w:match("[aeéiíoóuú]is$") and w:match("is$") and
             ortho == "i" and next and next.type == "cons" and next.palatal == true then
            token.restore_i = true
          end
          -- Contains "-aithe" (verbal adjective suffix): scealaithe, athruithe
          if w:match("aithe$") and ortho == "ai" then
            token.restore_i = true
          end
          -- Verb personal suffixes: -im (1sg), -id (3sg), -ir (autonomous past)
          -- The vowel in these suffixes keeps ɪ quality rather than reducing to ə.
          local verb_suffix_words = {
            ["beirir"] = true, ["ithid"] = true, ["brisid"] = true,
            ["dheinim"] = true, ["nílim"] = true, ["nílid"] = true,
            ["tálaim"] = true, ["chímid"] = true,
            ["beirigí"] = true, ["cinnigí"] = true,
            ["eitil"] = true, ["coisrig"] = true,
          }
          if verb_suffix_words[w] and next and
             next.type == "cons" and next.palatal == true then
            if ortho == "i" then
              token.restore_i = true
            elseif ortho == "ai" and (w:match("aim$") or w:match("aith")) then
              token.restore_i = true
            end
          end
        end
      end

      -- Previous consonant polarity affects preceding vowel quality
      if prev and prev.type == "cons" then
        if prev.palatal == true then
          if token.phon == "ə" then token.phon = "ɪ" end
        elseif prev.palatal == false then
          -- Don't back an ɪ to ə when the following consonant is slender and
          -- word-final: the slender offglide survives a broad onset
          -- (fuil /fˠɪlʲ/, duit /d̪ˠɪtʲ/, muic /mˠɪc/, muid /mˠɪdʲ/).
          if token.phon == "ɪ" and not token.stress then
            local keep_i = false
            if next and next.type == "cons" and next.palatal == true and next.phon ~= "" then
              local wf = true
              for j = i + 2, #tokens do
                local t = tokens[j]
                if t.type == "boundary" then break end
                if (t.type == "cons" or t.type == "vowel") and t.phon and t.phon ~= "" then
                  wf = false; break
                end
              end
              if wf then keep_i = true end
            end
            if not keep_i then token.phon = "ə" end
          end
        end
      end

      ::continue::
    end
    return tokens
  end,
}
