-- Pass #6: Vocalize vowel+fricative sequences.
-- Stress-aware: -adh stressed -> [ai/eː], unstressed -> [ə].
-- ea+bh -> [əu], u+gh -> [uː], a/o/u+bh/mh -> [əu].
-- NOTE: Does NOT silence the fricative — that's handled by pass #9b (vowel_adjunct)
-- after consonants have been resolved by pass #9.
-- References: Hickey II.1.9.9.1 (vocalisation of fricatives), II.1.9.4 (vowel gradation)

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

      -- Skip vocalization when 'i' is a palatal marker (preceded by another vowel).
      -- dóibh → oː + vʲ (not vocalize i+bh to əi).
      -- The 'i' between a vowel and bh/mh is marking palatalization, not forming
      -- a diphthong with the following fricative.
      -- Hickey II.1.9: i as palatal marker between two Vs, not syllabic
      if vowel.ortho == "i" then
        local prev_t = tokens[i - 1]
        if prev_t and prev_t.type == "vowel" then
          goto continue
        end
      end

      local is_slender = vowel.ortho == "e" or vowel.ortho == "i" or vowel.ortho == "ea"
      local was_vocalized = false

      -- Hickey II.1.9.9.1: V+bh/mh → /əu əi/ — historical /v/ absorbed into vowel
      --   (leabhar→[lʲauɾˠ], samhradh→[sˠauɾˠə])
      if vowel.ortho == "ea" and (fricative.ortho == "bh" or fricative.ortho == "mh") then
        vowel.phon = "əu"; was_vocalized = true
      elseif fricative.ortho == "bh" or fricative.ortho == "mh" then
        if is_slender then
          vowel.phon = "əi"; was_vocalized = true
        elseif vowel.ortho == "a" or vowel.ortho == "o" or vowel.ortho == "u" then
          vowel.phon = "əu"; was_vocalized = true
        end
      -- Hickey II.1.9.9.1: V+dh/gh → /ai/ stressed, /ə/ unstressed
      --   (aghaidh→[əi], radharc→[ɾˠaɾˠk])
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
