local us = require("ustring.ustring")
local fi = io.open("_base.tsv", "r")
local lines = {}
for l in fi:lines() do table.insert(lines, l) end
fi:close()
local subs, wmap = {}, {}
for _, line in ipairs(lines) do
  local parts = {}
  for p in line:gmatch("[^\t]+") do table.insert(parts, p) end
  if #parts >= 5 then
    local w, got, exp, exact, lev = parts[1], parts[2], parts[3], parts[4], parts[5]
    if lev == "1" and exact ~= "1" and us.len(got) == us.len(exp) then
      local subst
      for ci = 1, us.len(got) do
        local gc, ec = us.sub(got,ci,ci), us.sub(exp,ci,ci)
        if gc ~= ec then subst = ec .. "\xe2\x86\x92" .. gc end
      end
      if subst then
        subs[subst] = (subs[subst] or 0) + 1
        if not wmap[subst] then wmap[subst] = {} end
        if #wmap[subst] < 8 then table.insert(wmap[subst], w .. " got=" .. got .. " exp=" .. exp) end
      end
    end
  end
end
local s = {}
for k,v in pairs(subs) do table.insert(s, {k,v}) end
table.sort(s, function(a,b) return a[2]>b[2] end)
local t = 0
for _,v in ipairs(s) do t = t + v[2] end
print("Total: " .. t .. "\n")
for _,v in ipairs(s) do
  print(string.format("%3d %s", v[2], v[1]))
  if wmap[v[1]] then for _,ex in ipairs(wmap[v[1]]) do print("  " .. ex) end end
  print("")
end
