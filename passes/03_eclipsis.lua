-- Pass #3: Handle eclipsis markers (mb, gc, bpr, dt, ngc, ngl).
-- Eclipsis is a spelling phenomenon: the orthographic sequence resolves
-- to a single base consonant phoneme. Run before cluster_simplify and
-- mutated_fricatives so they see the resolved form.

local S = require("passes._shared")

local ECLIPSIS_MAP = {
  mb  = { phon = "mˠ" },
  gc  = { phon = "ɡ" },
  dt  = { phon = "d̪ˠ" },
  bp  = { phon = "bˠ" },
  ngc = { phon = "ŋ" },  -- eclipsis of c -> ng
  ngl = { phon = "ŋ" },  -- eclipsis of l -> ng
  bpr = { phon = "bˠ" }, -- eclipsis of p -> b
  ["mbF"] = { phon = "" }, -- eclipsis of f -> m -> silent in initial
  ["bF"]  = { phon = "" },  -- eclipsis of f -> b -> silent
  nn  = { phon = "n̪ˠ" },
}

return {
  name = "eclipsis",
  writes_context = false,

  run = function(tokens, context)
    for i, token in ipairs(tokens) do
      if token.is_mutated and token.mutation == "eclipsis" then
        local entry = ECLIPSIS_MAP[token.ortho]
        if entry then
          token.phon = entry.phon
          -- Mark the ortho to its base consonant so later passes use the right form
          if token.ortho == "gc" then token.ortho = "g"
          elseif token.ortho == "dt" then token.ortho = "d"
          elseif token.ortho == "bp" or token.ortho == "bpr" then token.ortho = "b"
          elseif token.ortho == "mb" then token.ortho = "m"
          elseif token.ortho == "ngc" or token.ortho == "ngl" then token.ortho = "ng"
          end
        end
      end
    end
    return tokens
  end,
}
