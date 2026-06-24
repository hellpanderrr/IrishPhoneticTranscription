-- Analyze vowel reduction mismatches
local engine = require("irish_engine_new")
local bm = dofile("_benchmark.lua")

-- Use byte sequence for schwa
local function has_schwa(s)
  -- Find ə (U+0259, UTF-8: C9 99)
  for i = 1, #s - 1 do
    if s:byte(i) == 0xC9 and s:byte(i+1) == 0x99 then return true end
  end
  return false
end

local over_reduce, under_reduce, both_differ = {}, {}, {}
for w, data in pairs(bm) do
  local ok, actual = pcall(engine.transcribe, w)
  if ok and actual ~= data.expected then
    local got_s = has_schwa(actual)
    local exp_s = has_schwa(data.expected)
    if got_s and not exp_s then
      over_reduce[#over_reduce+1] = {w=w, g=actual, e=data.expected}
    elseif not got_s and exp_s then
      under_reduce[#under_reduce+1] = {w=w, g=actual, e=data.expected}
    elseif got_s and exp_s then
      both_differ[#both_differ+1] = {w=w, g=actual, e=data.expected}
    end
  end
end

print(string.format("Over-reduce (schwa where expected full vowel): %d", #over_reduce))
print(string.format("Under-reduce (full vowel where expected schwa): %d", #under_reduce))
print(string.format("Both have schwa but differ: %d", #both_differ))

print()
print("--- Over-reduce (first 30) ---")
table.sort(over_reduce, function(a,b) return a.w < b.w end)
for i = 1, math.min(30, #over_reduce) do
  print(string.format("  %-25s got=%s  exp=%s", over_reduce[i].w, over_reduce[i].g, over_reduce[i].e))
end

print()
print("--- Under-reduce (first 30) ---")
table.sort(under_reduce, function(a,b) return a.w < b.w end)
for i = 1, math.min(30, #under_reduce) do
  print(string.format("  %-25s got=%s  exp=%s", under_reduce[i].w, under_reduce[i].g, under_reduce[i].e))
end
