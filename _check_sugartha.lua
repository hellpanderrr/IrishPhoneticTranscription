local e = require("irish_engine_new")
local bench = require("_benchmark")
-- Check specific words
for _, w in ipairs{"súgartha","sugartha","corpartha","ceachartha","danartha","brisfidh"} do
  local r = ""
  pcall(function() r = e.transcribe(w) end)
  local d = bench[w]
  local exp = d and d.expected or "?"
  local ok = (r == exp) and "OK" or "DIFF"
  print(string.format("%s: eng=%s exp=%s %s", w, r, exp, ok))
end
