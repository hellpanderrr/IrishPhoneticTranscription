local e = require("irish_engine_new")
local bench = require("_benchmark")

-- IPA byte constants for display
local function show(s)
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

local errors = {}
local total, exact = 0, 0

for word, data in pairs(bench) do
  local ipa = data.expected
  if ipa and ipa ~= "" then
    total = total + 1
    local result = e.transcribe(word)
    if result == ipa then
      exact = exact + 1
    else
      local function lev(a, b)
        local n, m = #a, #b
        local d = {}
        for i = 0, n do d[i] = { [0] = i } end
        for j = 0, m do d[0][j] = j end
        for i = 1, n do
          for j = 1, m do
            d[i][j] = math.min(
              d[i-1][j] + 1,
              d[i][j-1] + 1,
              d[i-1][j-1] + (a:sub(i, i) == b:sub(j, j) and 0 or 1)
            )
          end
        end
        return d[n][m]
      end
      local d = lev(result, ipa)
      if d == 1 then
        local key = ""
        for i = 1, math.min(#result, #ipa) do
          local rr = result:sub(i, i)
          local tt = ipa:sub(i, i)
          if rr ~= tt then
            -- Use hex to distinguish IPA chars
            key = string.format("%s->%s", show(rr), show(tt))
            break
          end
        end
        if key == "" then
          if #result > #ipa then
            key = string.format("%s->(del)", show(result:sub(#ipa + 1)))
          else
            key = string.format("(ins)->%s", show(ipa:sub(#result + 1)))
          end
        end
        if not errors[key] then errors[key] = {} end
        table.insert(errors[key], { word = word, got = result, exp = ipa })
      end
    end
  end
end

local f = io.open("_error_report.txt", "w")

f:write(string.format("Total: %d  Exact: %d  Other: %d\n\n", total, exact, total - exact))

local sorted = {}
for k, v in pairs(errors) do
  table.insert(sorted, { k, #v, v })
end
table.sort(sorted, function(a, b) return a[2] > b[2] end)

f:write("Lev-1 Error Buckets:\n")
f:write(string.format("%-5s  %-20s  %s\n", "Cnt", "Edit", "Examples"))
for _, item in ipairs(sorted) do
  local examples = {}
  for i = 1, math.min(3, #item[3]) do
    local ex = item[3][i]
    table.insert(examples, string.format("%s(%s->%s)", ex.word, show(ex.got), show(ex.exp)))
  end
  f:write(string.format("%-5d  %-20s  %s\n", item[2], item[1], table.concat(examples, " ")))
end
f:write(string.format("\nTotal Lev-1 categories: %d\n", #sorted))

f:close()
print("Written to _error_report.txt")
