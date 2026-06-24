-- Analyze which unstressed vowels the engine reduces but shouldn't
local engine = require("irish_engine_new")
local bm = dofile("_benchmark.lua")

-- Find words where engine produces schwa but expected doesn't
local patterns = {}
local total = 0
for w, data in pairs(bm) do
  local ok, actual = pcall(engine.transcribe, w)
  if ok and actual ~= data.expected then
    total = total + 1
    -- Check: does engine have schwa but expected doesn't?
    local eng_has = actual:find("\xC9\x99") ~= nil
    local exp_has = data.expected:find("\xC9\x99") ~= nil
    if eng_has and not exp_has then
      -- Find which vowel in the expected output corresponds to the schwa position
      -- Simple approach: extract vowels from expected
      local exp_vowels = {}
      for v in data.expected:gmatch("[aeiouAEIOU\xC9\x91\xC9\x9B\xC9\xAA\xC9\x94\xC9\xAF\xC9\x99]") do
        exp_vowels[#exp_vowels+1] = v
      end
      local eng_vowels = {}
      for v in actual:gmatch("[aeiouAEIOU\xC9\x91\xC9\x9B\xC9\xAA\xC9\x94\xC9\xAF\xC9\x99]") do
        eng_vowels[#eng_vowels+1] = v
      end
      -- Match positions
      for i = 1, math.min(#eng_vowels, #exp_vowels) do
        if eng_vowels[i] == "\xC9\x99" and exp_vowels[i] ~= "\xC9\x99" then
          patterns[exp_vowels[i]] = (patterns[exp_vowels[i]] or 0) + 1
        end
      end
    end
  end
end

print("Words with over-reduction where engine produces ə:")
local sorted = {}
for v, c in pairs(patterns) do sorted[#sorted+1] = {v=v, c=c} end
table.sort(sorted, function(a,b) return a.c > b.c end)
for _, s in ipairs(sorted) do
  print(string.format("  expected vowel %-8s -> %d words", s.v, s.c))
end
