-- Pass #4: Normalize consonant clusters.
-- Runs after eclipsis but before mutated_fricatives so the simplified
-- ortho is what the fricative rules see.

local S = require("passes._shared")

return {
  name = "cluster_simplify",
  writes_context = false,

  run = function(tokens, context)
    -- Merge adjacent consonant tokens that form known compound clusters
    -- e.g., "bhth" surfaces as two tokens [bh, th] -> merge to [r]
    local i = 1
    while i < #tokens do
      local t1 = tokens[i]; local t2 = tokens[i + 1]

      -- bh + th -> r
      if t1.type == "cons" and t2.type == "cons" and
         t1.ortho == "bh" and t2.ortho == "th" then
        t1.ortho = "r"
        t1.source = "cluster_shift"
        t2.phon = ""  -- silence the second half
        i = i + 1

      -- ch + n -> ch + r (if followed by a vowel)
      elseif t1.type == "cons" and t2.type == "cons" and
             t1.ortho == "ch" and t2.ortho == "n" then
        -- Check next token is a vowel
        local next_t = tokens[i + 2]
        if next_t and next_t.type == "vowel" then
          t2.ortho = "r"
          t2.source = "cluster_shift"
        end
        i = i + 1

      else
        i = i + 1
      end
    end
    return tokens
  end,
}
