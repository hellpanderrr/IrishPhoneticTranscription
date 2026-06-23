-- Pass #6: Vocalize vowel+fricative sequences.
-- Stress-aware: -adh stressed -> [ai/eː], unstressed -> [ə].
-- ea+bh -> [əu], u+gh -> [uː], a/o/u+bh/mh -> [əu].
-- NOTE: Does NOT silence the fricative — that's handled by pass #9b (vowel_adjunct)
-- after consonants have been resolved by pass #9.

local S = require("passes._shared")

return {
  name = "vocalization",
  writes_context = false,

  run = function(tokens, context)
    for i = 1, #tokens - 1 do
      local vowel = tokens[i]
      local fricative = tokens[i + 1]
      if vowel.type ~= "vowel" or not S.is_vocalizable_fricative(fricative) then
        goto continue
      end

      local is_slender = vowel.ortho == "e" or vowel.ortho == "i" or vowel.ortho == "ea"
      local was_vocalized = false

      if vowel.ortho == "ea" and (fricative.ortho == "bh" or fricative.ortho == "mh") then
        vowel.phon = "əu"; was_vocalized = true
      elseif fricative.ortho == "bh" or fricative.ortho == "mh" then
        if is_slender then
          vowel.phon = "əi"; was_vocalized = true
        elseif vowel.ortho == "a" or vowel.ortho == "o" or vowel.ortho == "u" then
          vowel.phon = "əu"; was_vocalized = true
        end
      elseif fricative.ortho == "dh" or fricative.ortho == "gh" then
        if vowel.stress then
          if is_slender then
            vowel.phon = "əi"; was_vocalized = true
          elseif vowel.ortho == "a" or vowel.ortho == "o" or vowel.ortho == "u" then
            vowel.phon = "ai"; was_vocalized = true
          end
        else
          vowel.phon = "ə"; was_vocalized = true
        end
      end

      if was_vocalized then
        fricative.phon = ""
      end

      -- Lexical overrides: stressed a+bh/mh → au (not əu) for specific words
      if was_vocalized and vowel.ortho == "a" and (fricative.ortho == "bh" or fricative.ortho == "mh") and context.word_ortho then
        local A_VOCALIZE_AU = { damhsaigh=true, rabhadar=true, ["clamhsán"]=true,
          ["damhán"]=true, clabhta=true, fabhtach=true, amha=true, ["clabhtaí"]=true,
          rabhamar=true, ["gabhála"]=true, ["sabhdán"]=true, cabhsa=true }
        if A_VOCALIZE_AU[context.word_ortho:lower()] then
          vowel.phon = "au"
        end
      end

      ::continue::
    end

    return tokens
  end,
}
