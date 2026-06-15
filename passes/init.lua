-- Passes initializer. Loads all 19 passes in order.

local S = require("passes._shared")

local passes = {}
passes[1]  = require("passes.01_polarity")
passes[2]  = require("passes.02_stress")
passes[3]  = require("passes.03_eclipsis")
passes[4]  = require("passes.04_cluster_simplify")
passes[5]  = require("passes.05_mutated_fricatives")
passes[6]  = require("passes.06_vocalization")
passes[7]  = require("passes.06b_vowel_gradation")          -- NEW
passes[8]  = require("passes.06c_r_lowering")                -- NEW
passes[9]  = require("passes.06d_anticipatory_raising")      -- NEW
passes[10] = require("passes.06e_labial_vocalization")       -- NEW
passes[11] = require("passes.07_nasalization")
passes[12] = require("passes.08_slender_coda")
passes[13] = require("passes.09_consonants")
passes[14] = require("passes.09b_vowel_adjunct")
passes[15] = require("passes.10_vowels")
passes[16] = require("passes.11_unstressed_reduction")
passes[17] = require("passes.12_epenthesis")
passes[18] = require("passes.13_sonorants")
passes[19] = require("passes.14_final_cleanup")

local function run_all(tokens, context)
  for i = 1, 19 do
    tokens = passes[i].run(tokens, context)
  end
  return tokens
end

return {
  passes = passes,
  run_all = run_all,
}
