-- Passes initializer. Loads all 16 passes in order.

local S = require("passes._shared")

local passes = {}
passes[1]  = require("passes.01_polarity")
passes[2]  = require("passes.02_stress")
passes[3]  = require("passes.03_eclipsis")
passes[4]  = require("passes.04_cluster_simplify")
passes[5]  = require("passes.05_mutated_fricatives")
passes[6]  = require("passes.06_vocalization")
passes[7]  = require("passes.06d_anticipatory_raising")
passes[8]  = require("passes.07_nasalization")
passes[9]  = require("passes.08_slender_coda")
passes[10] = require("passes.09_consonants")
passes[11] = require("passes.09b_vowel_adjunct")
passes[12] = require("passes.10_vowels")
passes[13] = require("passes.11_unstressed_reduction")
passes[14] = require("passes.12_epenthesis")
passes[15] = require("passes.13_sonorants")
passes[16] = require("passes.14_final_cleanup")

local function run_all(tokens, context)
  for i = 1, 16 do
    tokens = passes[i].run(tokens, context)
  end
  return tokens
end

return {
  passes = passes,
  run_all = run_all,
}
