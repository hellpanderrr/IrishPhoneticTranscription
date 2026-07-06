local e = require("irish_engine_new")

local words = {"bíonn", "chíonn", "níonn", "luíonn", "suíonn", "áitíonn", "-íonn", "míol", "cíor", "síob"}
for _, w in ipairs(words) do
    local result = e.transcribe(w, "connacht")
    print(string.format("%-12s => %s", w, result))
end
