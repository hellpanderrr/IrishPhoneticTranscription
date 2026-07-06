local e = require("irish_engine_new")

local words = {
    "bord", "dorn", "corn", "dord", "boird", "Sord",
    "urla", "urnaí", "murnán",
    "bairneach", "cairdeas", "gairdín", "airne",
    "cearnóg", "dearna",
}
for _, w in ipairs(words) do
    local result = e.transcribe(w, "connacht")
    print(string.format("%-16s => %s", w, result))
end
