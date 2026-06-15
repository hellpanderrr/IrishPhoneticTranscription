-- Pass #3: Handle eclipsis clusters.
-- Word-initial eclipsis: mb→m, gc→g, dt→d, bp→b, nd→n, nn→n, ng→ŋ, bhf→bh
-- Collapse two-consonant cluster by silencing the eclipsed consonant.
-- The surviving consonant retains its polarity for later consonant resolution.

local S = require("passes._shared")

return {
  name = "eclipsis",
  writes_context = false,

  run = function(tokens, context)
    if #tokens < 2 then return tokens end

    local t1, t2 = tokens[1], tokens[2]
    if not t1 or not t2 then return tokens end
    if t1.type ~= "cons" or t2.type ~= "cons" then return tokens end

    -- Two-consonant eclipsis clusters at word start
    local pair = t1.ortho .. t2.ortho
    local TWO_CONS_ECLIPSIS = {
      mb = true, gc = true, dt = true, bp = true, nd = true, nn = true,
    }
    if TWO_CONS_ECLIPSIS[pair] then
      t2.phon = ""
      t2.source = "eclipsis_silenced"
      return tokens
    end

    -- Three-consonant eclipsis: bhf (bh + f)
    if #tokens >= 3 and t1.ortho == "bh" and t2.ortho == "f" then
      t2.phon = ""
      t2.source = "eclipsis_silenced"
      return tokens
    end

    -- Single-token ng at word start is eclipsis of g → ŋ
    if t1.ortho == "ng" and t1.type == "cons" then
      -- Ensure broad polarity for eclipsis ng (ŋ is always velar)
      S.set_polarity(t1, false)
      return tokens
    end

    return tokens
  end,
}
