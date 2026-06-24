local e = require("irish_engine_new")
-- Check the ə→a and a→ə bucket words
local words = {
  "mba", "adhnaic", "adhairc", "fadhbanna",
  "gabhaidís", "ghabhas", "tabharthach",
  "dubhach", "domlas", "dorú",
}
for _, w in ipairs(words) do
  print(w .. ": " .. e.transcribe(w, "connacht"))
end
