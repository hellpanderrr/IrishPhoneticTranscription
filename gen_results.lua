-- Regenerate new_results.csv with current engine
local engine = require("irish_engine_new")

local function parse_csv(line)
  local fields = {}; local cur = {}; local inq = false
  for i = 1, #line do
    local c = line:sub(i,i)
    if c == [["]] then inq = not inq
    elseif c == "," and not inq then
      table.insert(fields, table.concat(cur)); cur = {}
    else table.insert(cur, c) end
  end
  table.insert(fields, table.concat(cur))
  return fields
end

local function norm(s)
  if not s then return "" end
  return s:gsub("[ˈˌ\"]", "")
end

local function lev(a, b)
  if a == b then return 0 end
  local m, n = #a, #b
  local d = {}
  for i = 0, m do d[i] = { [0] = i } end
  for j = 0, n do d[0][j] = j end
  for j = 1, n do
    for i = 1, m do
      d[i][j] = math.min(d[i-1][j] + 1, d[i][j-1] + 1, d[i-1][j-1] + (a:byte(i) == b:byte(j) and 0 or 1))
    end
  end
  return d[m][n]
end

local function match_and_score(expected, result)
  local nr = norm(result)
  local variants = {}
  local cur, inq = "", false
  for i = 1, #expected do
    local c = expected:sub(i, i)
    if c == [["]] then inq = not inq
    elseif c == "," and not inq then
      local trimmed = cur:match("^%s*(.-)%s*$")
      if trimmed and trimmed ~= "" then table.insert(variants, trimmed) end
      cur = ""
    else cur = cur .. c end
  end
  if cur ~= "" then
    local trimmed = cur:match("^%s*(.-)%s*$")
    if trimmed and trimmed ~= "" then table.insert(variants, trimmed) end
  end

  local best = nil
  for _, v in ipairs(variants) do
    local nv = norm(v)
    if nr == nv then return 100, 0 end
    local d = lev(nr, nv)
    if best == nil or d < best then best = d end
  end
  if best == nil then return 0, 10 end
  return math.max(0, 100 - best * 5), best
end

-- Load input
local fi = io.open("data/connacht_only.csv", "r")
local header = fi:read()
local lines = {}
for line in fi:lines() do
  table.insert(lines, line)
end
fi:close()

-- Generate output
local fo = io.open("new_results.csv", "w")
fo:write("word\ttags\tipa\tresults\tmatch\tdolgo\n")

local total, exact = 0, 0
local total_lev = 0

for _, line in ipairs(lines) do
  local fields = parse_csv(line)
  if #fields >= 3 then
    local word = fields[1]
    local tags = fields[2] or ""
    local expected = fields[3]

    local ok, ipa = pcall(engine.transcribe, word)
    if not ok then ipa = "ERROR" end

    local score, dist = match_and_score(expected, ipa)

    fo:write(string.format("%s\t%s\t%s\t%s\t%d\t%s\n",
      word, tags, expected, ipa, score, string.format("%.1f", dist)))

    total = total + 1
    if score == 100 then exact = exact + 1 end
    total_lev = total_lev + dist
  end
end

fo:close()

print(string.format("Generated new_results.csv"))
print(string.format("Words: %d, Exact: %d (%.2f%%), Avg Lev: %.2f", total, exact, exact/total*100, total_lev/total))
