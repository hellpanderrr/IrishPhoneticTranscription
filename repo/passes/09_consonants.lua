-- Pass #9: Resolve consonant tokens to IPA.
-- Handles broad/slender alternation and voiceless sonorants.

local S = require("passes._shared")

return {
  name = "consonants",
  writes_context = false,

  run = function(tokens, context)
    for i, token in ipairs(tokens) do
      if token.type ~= "cons" then goto continue end
      -- Skip tokens already silenced or vocalized by earlier passes
      if token.phon == "" then goto continue end
      if token.source == "vocalized" then goto continue end

      local prev = tokens[i - 1]

      if token.ortho == "bh" or token.ortho == "mh" then
        if token.palatal == true then
          token.phon = "vʲ"
        elseif token.palatal == false then
          -- Word-initial broad bh/mh before a consonant cluster: historically /vˠ/
          -- in Connacht before broad sonorant (r/l) + short vowel "a" (not "ai"),
          -- or before "n". Otherwise /w/ before vowels and other contexts.
          local word_initial = (prev == nil) or (prev.type == "boundary")
          if word_initial then
            local nxt = tokens[i + 1]
            if nxt and nxt.type == "cons" and nxt.ortho == "n" then
              token.phon = "vˠ"
            elseif nxt and nxt.type == "cons" and (nxt.ortho == "r" or nxt.ortho == "l") then
              -- Check the vowel after the sonorant: short "a" (not "ai") -> vˠ
              local vowel_after = tokens[i + 2]
              if vowel_after and vowel_after.type == "vowel" and
                 vowel_after.ortho == "a" then
                token.phon = "vˠ"
              else
                token.phon = "w"
              end
            else
              token.phon = "w"
            end
          else
            token.phon = "w"
          end
        else
          token.phon = "vˠ"
        end
      elseif token.ortho == "ch" then
        if token.palatal == true then
          -- Hickey: slender ch after front vowel ortho -> c, after back vowel -> h
          -- Word-initial slender ch -> c,
          local prev_v = tokens[i - 1]
          if prev_v and prev_v.type == "vowel" then
            -- Check ortho for front vowel: simple i/e/í/é or digraphs
            -- ending in i (ai/aoi/ei/oi/ui etc. - palatal offglide = front context)
            local b1 = (prev_v.ortho:byte(1) or 0)
            local b2 = (prev_v.ortho:byte(2) or 0)
            if b1 == 0x69 or b1 == 0x65 then
              token.phon = "\xc3\xa7"  -- i or e
            elseif b1 == 0xC3 and (b2 == 0xAD or b2 == 0xA9) then
              token.phon = "\xc3\xa7"  -- í or é
            elseif prev_v.ortho == "ai" or prev_v.ortho == "aoi" or
                   prev_v.ortho == "ei" or prev_v.ortho == "oi" or
                   prev_v.ortho == "ui" or prev_v.ortho == "aí" or
                   prev_v.ortho == "oí" or prev_v.ortho == "uí" then
              token.phon = "\xc3\xa7"  -- front-vowel digraphs
            else
              token.phon = "h"
            end
          else
            token.phon = "\xc3\xa7"
          end
        else
          token.phon = "x"
        end
      elseif token.ortho == "sh" then
        -- Connacht: slender sh before back rounded vowel -> ç.
        -- shiúl /çuːlˠ/, Sheoirse /çoːɾˠʃə/
        -- Otherwise: slender sh before front vowels -> h.
        -- shé /heː/, shín /hiːnʲ/, ó shin /oː hɪnʲ/
        local nxt = tokens[i + 1]
        local is_back_rounded = false
        if token.palatal == true and nxt and nxt.type == "vowel" then
          if nxt.ortho == "eo" or nxt.ortho == "eoi" then
            is_back_rounded = true
          elseif nxt.ortho == "u" or nxt.ortho == "ú" then
            is_back_rounded = true
          elseif nxt.ortho == "o" or nxt.ortho == "ó" then
            is_back_rounded = true
          elseif nxt.ortho == "i" then
            -- Palatal marker "i" before back vowel (iú, io)
            local nnxt = tokens[i + 2]
            if nnxt and nnxt.type == "vowel" and
               (nnxt.ortho == "ú" or nnxt.ortho == "u" or nnxt.ortho == "o" or nnxt.ortho == "ó") then
              is_back_rounded = true
            end
          end
        end
        if is_back_rounded then
          token.phon = "\xc3\xa7"  -- ç
        else
          token.phon = "h"
        end
      elseif token.ortho == "th" then
        if i == #tokens then
          token.phon = ""
        else
          local word_initial = (prev == nil) or (prev.type == "boundary")
          local nxt = tokens[i + 1]
          -- Word-initial slender th -> ç before back rounded vowel (eo).
          if word_initial and token.palatal == true and nxt and nxt.type == "vowel" and nxt.ortho == "eo" then
            token.phon = "\xc3\xa7"  -- ç
          else
            token.phon = "h"
          end
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
        -- s before p/t/k/m: check polarity. If the following consonant
        -- is broad, s stays broad. Only palatalize s before a slender p/t/k/m.
        local next = tokens[i + 1]
        if next and (next.ortho == "p" or next.ortho == "t" or next.ortho == "c") then
          if next.palatal == true then
            token.phon = "ʃ"
          else
            token.phon = "sˠ"
          end
        elseif next and next.ortho == "m" then
          token.phon = "sˠ"
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
        -- Connacht: r before dental consonants (t, d, n, s) is broad ɾˠ
        -- regardless of vowel context. Irish phonotactics forbid /rʲ/ before
        -- dental stops in syllable coda (Hickey 2.7.4).
        local next_c = tokens[i + 1]
        local force_broad = next_c and next_c.type == "cons" and
          (next_c.ortho == "s" or next_c.ortho == "t" or
           next_c.ortho == "d" or next_c.ortho == "n")
        if force_broad then
          token.palatal = false
        end
        -- Lexical override: r before slender s/t should be slender in specific words
        if context.word_ortho and next_c and next_c.palatal == true then
          local w = context.word_ortho:lower()
          local slender_r_words = {
            ["mairteoil"] = true, ["deirtí"] = true, ["abairtí"] = true,
            peirsis = true, abairte = true, peirsil = true,
            peirs = true, deirtear = true,
            bhfuiltear = true, fuiltear = true, beirtear = true,
          }
          if slender_r_words[w] then
            token.palatal = true
          end
        end
        if token.is_voiceless then
          token.phon = S.palatal_consonant(token, "r̥", "ɾˠ")
        else
          token.phon = S.palatal_consonant(token, "ɾʲ", "ɾˠ")
        end
      elseif token.ortho == "f" then
        -- Future-tense suffix -fidh/-faidh: f between consonant and (i|ai)+dh → context rule.
        -- After obstruent (c/t/d/g/s/ch/x): f elides (∅). After sonorant (l/n/r): f → h.
        local prev = tokens[i - 1]
        local next1 = tokens[i + 1]
        local next2 = tokens[i + 2]
        -- Match -fidh (f + i + dh) or -faidh (f + ai + dh)
        local suffix_f = prev and prev.type == "cons" and prev.phon and prev.phon ~= ""
          and next1 and next1.type == "vowel"
          and ((next1.ortho == "i" and next2 and next2.ortho == "dh")
            or (next1.ortho == "ai" and next2 and next2.ortho == "dh"))
        if suffix_f then
          local pp = prev.phon
          local is_obstruent = false
          for ch in pp:gmatch(".") do
            if ch == "k" or ch == "g" or ch == "p" or ch == "t"
              or ch == "d" or ch == "b" or ch == "s" or ch == "x"
              or ch == "f" or ch == "v" or ch == "h" or ch == "ʃ" then
              is_obstruent = true; break
            end
          end
          if is_obstruent then
            token.phon = ""
          else
            token.phon = "h"
          end
        else
          token.phon = S.palatal_consonant(token, "fʲ", "fˠ")
        end
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
