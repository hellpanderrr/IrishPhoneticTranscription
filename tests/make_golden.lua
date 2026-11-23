-- Regenerates tests/golden.tsv: a SNAPSHOT of what the engine outputs now for a fixed sample of benchmark words.
-- It records behaviour, not linguistic truth: run it only when you changed the engine on purpose, and read the diff.
-- Usage: lua tests/make_golden.lua
local engine = require("irish_engine_new")
local out = assert(io.open("tests/golden.tsv", "w"))
out:write("dialect\tword\texpected\n")
for _, dialect in ipairs{ "connacht", "munster", "ulster" } do
  local bench = require("benchmarks." .. dialect)
  local words = {}
  for w in pairs(bench) do words[#words + 1] = w end
  table.sort(words)
  -- every 45th word: a fixed, spread-out sample of about 90-180 words
  for i = 1, #words, 45 do
    out:write(dialect, "\t", words[i], "\t", (engine.transcribe(words[i], dialect)), "\n")
  end
end
out:close()
