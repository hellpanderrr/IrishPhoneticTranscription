-- Pass #1: Assign broad/slender polarity to consonants.
-- Scans flanking vowels to determine palatal status.

local S = require("passes._shared")

return {
  name = "polarity",
  writes_context = false,

  run = function(tokens, context)
    -- Simplify initial clusters (cn→cr, gn→gr, etc.) before polarity assignment
    if #tokens >= 2 and tokens[1].type == "cons" and tokens[2].type == "cons" then
      local shift = S.INITIAL_CLUSTER_SHIFTS[tokens[1].ortho .. tokens[2].ortho]
      if shift then
        tokens[1].ortho = shift[1]
        tokens[1].phon = shift[1]
        tokens[2].ortho = shift[2]
        tokens[2].phon = shift[2]
        tokens[2].source = "cluster_shift"
      end
    end

    -- Assign ng polarity based on preceding broad vowel
    for i = 1, #tokens - 1 do
      local vowel = tokens[i]
      local ng = tokens[i + 1]
      if vowel.type == "vowel" and ng.type == "cons" and ng.ortho == "ng" then
        if vowel.ortho == "a" or vowel.ortho == "o" or vowel.ortho == "u" or
           vowel.ortho == "ai" or vowel.ortho == "aí" then
          S.set_polarity(ng, false)
        end
      end
    end

    -- Word-initial r is always broad (ɾˠ) in Connacht, regardless of the
    -- following vowel. rí /ɾˠiː/, ré /ɾˠeː/, reacht /ɾˠaxt̪ˠ/. Set this
    -- before the main loop so it isn't overridden by the next-vowel scan.
    if #tokens >= 1 and tokens[1].type == "cons" and tokens[1].ortho == "r"
       and tokens[1].palatal == nil then
      S.set_polarity(tokens[1], false)
    end

    -- Main polarity assignment for all consonants
    for i, token in ipairs(tokens) do
      if token.type ~= "cons" then goto continue end
      if token.palatal ~= nil then goto continue end  -- already set (e.g., ng)

      local prev_vowel, j = nil, i - 1
      while j >= 1 do
        if tokens[j].type == "vowel" then prev_vowel = tokens[j]; break end
        j = j - 1
      end

      local next_vowel, j = nil, i + 1
      while j <= #tokens do
        if tokens[j].type == "vowel" then next_vowel = tokens[j]; break end
        j = j + 1
      end

      local polarity = S.vowel_polarity(next_vowel)
      if polarity == nil then polarity = S.vowel_polarity(prev_vowel, "prev") end

      -- Narrow exception: a final lenited fricative (th/sh/fh/ch/ph) following
      -- oi/ui should stay BROAD. The slender trace of these digraphs normally
      -- propagates to a following consonant, but a final silent/quiet lenited
      -- fricative historically colors the vowel broadly (croith /kɾˠɔh/,
      -- sruith /sɾˠʊh/). Letting it go slender front-raises the vowel.
      if token.is_mutated and i == #tokens and not next_vowel and prev_vowel and
         (prev_vowel.ortho == "oi" or prev_vowel.ortho == "ui") and
         (token.ortho == "th" or token.ortho == "sh" or token.ortho == "fh" or
          token.ortho == "ch" or token.ortho == "ph") then
        polarity = false
      end

      -- Sonorant polarity: when no vowel context, check next consonant
      local sonorants = { l = true, n = true, r = true, m = true }
      if sonorants[token.ortho] and not polarity then
        local next_cons = nil
        for k = i + 1, #tokens do
          if tokens[k].type == "cons" then next_cons = tokens[k]; break end
          if tokens[k].type == "vowel" then break end
        end
        if next_cons and next_cons.palatal ~= nil then
          polarity = next_cons.palatal
        end
      end

      S.set_polarity(token, polarity)
      ::continue::
    end

    return tokens
  end,
}
