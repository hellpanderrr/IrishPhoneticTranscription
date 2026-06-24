local bench = require("_benchmark")
local engine = require("irish_engine_new")

-- Find all words where engine has o before m and expected has u
local count = 0
local correct = 0
local total = 0
local fixable = {}

for w, entry in pairs(bench) do
  local got = engine.transcribe(w, "connacht")
  total = total + 1
  
  if got ~= entry.expected then
    -- Check if engine has o or ɔ before broad m
    if got:match("[oɔ]mˠ") or got:match("[oɔ]m[^a]") then
      if entry.expected:match("[uʊ]mˠ") or entry.expected:match("mˠ") and entry.expected:match("[uʊ]") then
        count = count + 1
        if #fixable < 10 then
          table.insert(fixable, {w=w, got=got, exp=entry.expected})
        end
      end
    end
  else
    correct = correct + 1
  end
end

print("Words with o before m where expected has u: " .. count)
print("Total correct: " .. correct)
print()
for _, f in ipairs(fixable) do
  print(f.w .. " got=" .. f.got .. " exp=" .. f.exp)
end
