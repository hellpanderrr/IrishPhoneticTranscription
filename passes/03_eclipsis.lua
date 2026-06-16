-- Pass #3: Handle eclipsis clusters.
-- Word-initial eclipsis: mb→m, gc→g, dt→d, bp→b, nd→n, nn→n, ng→ŋ, bhf→w
-- Silences the eclipsed consonant. Survivor keeps its ortho and resolves normally in pass 09.
-- Now scans EVERY word start (position 1 or after a boundary token),
-- so multi-word eclipsis (i bhfad, i dtosach) works.

local S = require("passes._shared")

local ECLIPSIS_PAIRS = { mb = true, gc = true, dt = true, bp = true, nd = true, nn = true, bhf = true }

return {
  name = "eclipsis",
  writes_context = false,

  run = function(tokens, context)
    -- Scan for word-start positions (index 1 = start of string, or after boundary)
    local i = 1
    while i <= #tokens do
      -- If not at position 1, skip to next word start (past the boundary token)
      if i > 1 then
        if tokens[i].type ~= "boundary" then i = i + 1; goto continue end
        i = i + 1  -- skip the boundary token
      end

      local t1 = tokens[i]
      local t2 = tokens[i + 1]
      if not t1 or not t2 then i = i + 1; goto continue end

      if t1.type == "cons" and t2.type == "cons" then
        local pair = t1.ortho .. t2.ortho

        if pair == "bhf" then
          -- bh + f → w (bh resolves to w in pass 09, f is silenced)
          t2.phon = ""
          t2.source = "eclipsis_silenced"
          i = i + 2
          goto continue
        end

        if ECLIPSIS_PAIRS[pair] then
          -- Silence the eclipsed consonant(s), survivor resolves normally in pass 09
          t2.phon = ""
          t2.source = "eclipsis_silenced"
          i = i + 2
          goto continue
        end
      end

      -- Single-token ng at word start is eclipsis of g → ŋ
      if t1.type == "cons" and t1.ortho == "ng" then
        S.set_polarity(t1, false)
        i = i + 1
        goto continue
      end

      i = i + 1
      ::continue::
    end

    return tokens
  end,
}
