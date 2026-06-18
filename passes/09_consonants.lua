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
            -- Check ortho for front vowel: i, e, i, e
            -- Use byte matching since these are multi-byte in UTF-8.
            local b1 = (prev_v.ortho:byte(1) or 0)
            local b2 = (prev_v.ortho:byte(2) or 0)
            if b1 == 0x69 or b1 == 0x65 then
              token.phon = "\xc3\xa7"  -- i or e
            elseif b1 == 0xC3 and (b2 == 0xAD or b2 == 0xA9) then
              token.phon = "\xc3\xa7"  -- i or e
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
        local word_initial = (prev == nil) or (prev.type == "boundary")
        local nxt = tokens[i + 1]
        -- Word-initial slender sh -> ç before back rounded vowel (eo).
        if word_initial and token.palatal == true and nxt and nxt.type == "vowel" and nxt.ortho == "eo" then
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
        -- s before p/t/k: check polarity. If the following consonant
        -- is broad, s stays broad. Only palatalize s before a slender p/t/k.
        local next = tokens[i + 1]
        if next and (next.ortho == "p" or next.ortho == "t" or next.ortho == "c") then
          if next.palatal == true then
            token.phon = "ʃ"
          else
            token.phon = "sˠ"
          end
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
