local e = require("irish_engine_new")
local bench = require("_benchmark")

function show(s)
  if not s or s == "" then return "" end
  local out = {}
  for i = 1, #s do
    local b = s:byte(i)
    if b > 127 then
      table.insert(out, string.format("\\x%02X", b))
    else
      table.insert(out, string.char(b))
    end
  end
  return table.concat(out)
end

-- Investigate specific error patterns
local patterns = {
  h_insert = {"anraith","chath","feith","dath","ngaoith","beith","fáth"},
  h_extra = {"brisfidh","ceachartha","danartha","corpartha","cheithre","uathlathaí"},
  oi_to_i = {"chroí","croítí","oícheanta","croí","snoí"},
  j_extra = {"tiobraid","Stiofáin","thiocfá","Stiofán","tiobraid"},
  e_to_i = {"goirme","moille","oileáin","oileán"},
  b_to_i = {"badhb","bhfadhb","fadhb","maidhm","straidhn","taghd"},
  a_to_i = {"caisleán"},
  v_to_w = {"vác","Baváir"},
  d_to_t = {"stadfaidh"},
  ah_over = {"beathaisnéisí","gabhlóg"},
  u_to_o = {"Odhrán"},
}

for pattern, words in pairs(patterns) do
  print("\n=== " .. pattern .. " ===")
  for _, w in ipairs(words) do
    local r = e.transcribe(w)
    local data = bench[w]
    local exp = data and data.expected or "?"
    print(w .. ":  eng=" .. show(r) .. "  exp=" .. show(exp))
  end
end
