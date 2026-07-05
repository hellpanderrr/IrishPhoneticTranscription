local ustring = require("ustring.ustring")
local usub = ustring.sub

local e = require("irish_engine_new")

-- Test words
local words = {"bíonn", "suíonn", "aithníonn", "éirínn", "míol", "cíor", "síob"}
for _, w in ipairs(words) do
  local r, tokens = e.transcribe(w, "connacht")
  io.write(w .. " => " .. r .. "\n")
  -- Show token details for bíonn
  if w == "bíonn" then
    for i, t in ipairs(tokens) do
      if t.type ~= "boundary" then
        io.write(string.format("  %d: ortho=%s phon=%s type=%s broad=%s slender=%s\n",
          i, t.ortho, t.phon, t.type, tostring(t.broad), tostring(t.slender)))
      end
    end
  end
end

-- Reference expected
print("\nExpected:")
print("bíonn  => bʲiːn̪ˠ")
print("suíonn => sˠiːn̪ˠ")
print("aithníonn => ˈahnʲiːn̪ˠ")
print("míol => mʲiːlˠ")
