-- Tests for the Irish G2P engine. Usage (from the repo root): lua tests/run_tests.lua
-- Exit status 0 = all passed.
local engine = require("irish_engine_new")
local failed, total = 0, 0

local function check(name, ok, detail)
  total = total + 1
  if not ok then
    failed = failed + 1
    io.write("FAIL ", name, detail and (": " .. detail) or "", "\n")
  end
end

-- 1. Golden snapshot (see tests/make_golden.lua)
for line in io.lines("tests/golden.tsv") do
  local dialect, word, expected = line:match("^([^\t]+)\t([^\t]*)\t(.*)$")
  if dialect and dialect ~= "dialect" then
    local got = engine.transcribe(word, dialect)
    check("golden " .. dialect .. " " .. word, got == expected, "got " .. got .. ", expected " .. expected)
  end
end

-- 2. Argument handling
check("nil word is rejected", not pcall(engine.transcribe, nil))
check("number word is rejected", not pcall(engine.transcribe, 42))
check("unknown dialect is rejected", not pcall(engine.transcribe, "bád", "foo"))
check("default dialect is connacht", engine.transcribe("bád") == engine.transcribe("bád", "connacht"))
check("empty string does not crash", pcall(engine.transcribe, "", "munster"))

-- 3. Case does not matter
for _, dialect in ipairs{ "connacht", "munster", "ulster" } do
  check("case-insensitive " .. dialect, engine.transcribe("Seán", dialect) == engine.transcribe("SEÁN", dialect)
    and engine.transcribe("Seán", dialect) == engine.transcribe("seán", dialect))
end

-- 4. The exception layer keeps fadas in its keys (sean and séan must be separate entries)
local subs = require("passes.lex_subs_connacht")
local has_fada_key = false
for key in pairs(subs) do
  if key:find("[áéíóú]") then has_fada_key = true break end
end
check("exception keys keep their fadas", has_fada_key)

-- 5. no_lexsubs switches the layer off, and it changes the output for at least one word
local differs = false
for word in pairs(subs) do
  if engine.transcribe(word, "connacht") ~= engine.transcribe(word, "connacht", { no_lexsubs = true }) then
    differs = true
    break
  end
end
check("no_lexsubs changes the output for a word in the layer", differs)

io.write(string.format("%d checks, %d failed\n", total, failed))
os.exit(failed == 0 and 0 or 1)
