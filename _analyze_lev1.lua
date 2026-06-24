-- Analyze Lev-1 substitution buckets: use ustring for proper Unicode
-- The TSV already has ustring Levenshtein distance. For lev==1, find
-- the Unicode position that differs.

local ustring = require("ustring.ustring")
local ulen, usub = ustring.len, ustring.sub

local function trim(s) return s:match("^%s*(.-)%s*$") end

local f = io.open("_base.tsv", "r")
if not f then print("Can't open _base.tsv"); return end

local buckets = {}
local non_sub = 0
local lev1_single_sub = 0
local total = 0

for line in f:lines() do
  local parts = {}
  for p in line:gmatch("[^\t]+") do table.insert(parts, p) end
  if #parts < 5 then end
  local word, got, exp, exact, lev = parts[1], parts[2], parts[3], parts[4], tonumber(parts[5])
  total = total + 1
  if exact ~= "true" and lev == 1 then
    -- Find positions by Unicode character
    local glen, elen = ulen(got), ulen(exp)
    if glen == elen then
      local diff_char_got, diff_char_exp = nil, nil
      for i = 1, glen do
        local gc, ec = usub(got, i, i), usub(exp, i, i)
        if gc ~= ec then
          if diff_char_got then
            diff_char_got = nil  -- multi-diff, skip
            break
          end
          diff_char_got, diff_char_exp = gc, ec
        end
      end
      if diff_char_got then
        lev1_single_sub = lev1_single_sub + 1
        local key = diff_char_got .. diff_char_exp
        local b = buckets[key]
        if not b then b = {gc=diff_char_got, ec=diff_char_exp, count=0, ex={}}; buckets[key] = b end
        b.count = b.count + 1
        if #b.ex < 5 then b.ex[#b.ex+1] = word .. " got=" .. trim(got) .. " exp=" .. trim(exp) end
      else
        non_sub = non_sub + 1
      end
    else
      non_sub = non_sub + 1
    end
  elseif exact ~= "true" and lev > 1 then
    non_sub = non_sub + 1
  end
end
f:close()

local exact_count = total - lev1_single_sub - non_sub
print(string.format("Total: %d  Exact: %d  Lev-1 single-sub: %d  Other errors: %d",
  total, exact_count, lev1_single_sub, non_sub))

local sorted = {}
for k, v in pairs(buckets) do
  local function esc(c)
    if #c == 1 then return c end
    return string.format("\\x%02x\\x%02x", c:byte(1), c:byte(2))
  end
  sorted[#sorted+1] = {count=v.count, gc=v.gc, ec=v.ec, disp=esc(v.gc) .. " -> " .. esc(v.ec), ex=v.ex}
end
table.sort(sorted, function(a,b) return a.count > b.count end)

print(string.format("\n%-42s %s", "Bucket (got->exp)", "Count"))
print(string.rep("-", 60))
for _, item in ipairs(sorted) do
  print(string.format("%-42s %d", item.disp, item.count))
  for _, ex in ipairs(item.ex) do print(string.format("  %s", ex)) end
end
