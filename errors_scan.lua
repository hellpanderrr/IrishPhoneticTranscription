-- Analyze remaining errors by root cause categories
local f = io.open('errors.csv', 'r')
local header = f:read()
local cats = {
  apostrophe = 0, adh = 0, aigh = 0, stress_missing = 0, l_over_dental = 0,
  l_under_dental = 0, n_over_dental = 0, n_under_dental = 0,
  l_over_postalv = 0, l_under_postalv = 0, n_over_postalv = 0, n_under_postalv = 0,
  missing_length = 0, extra_length = 0, eo_ch = 0, dl = 0, s_labial = 0,
}
local total = 0
for line in f:lines() do
  local cols = {}
  for v in line:gmatch('[^\t]+') do cols[#cols+1] = v end
  local word, got, expected = cols[1], cols[2], cols[3]
  total = total + 1

  if word:find("'") then cats.apostrophe = cats.apostrophe + 1 end
  if word:match('adh$') then cats.adh = cats.adh + 1 end
  if word:match('aigh') then cats.aigh = cats.aigh + 1 end
  if word:find('eo') and word:find('ch') then cats.eo_ch = cats.eo_ch + 1 end
  if word:find('dl') then cats.dl = cats.dl + 1 end
  if word:find('sp') or word:find('sm') or word:find('sf') then cats.s_labial = cats.s_labial + 1 end

  -- Diacritic comparisons
  if got:find('\204\170') and not expected:find('\204\170') then cats.l_over_dental = cats.l_over_dental + 1 end
  if not got:find('\204\170') and expected:find('\204\170') then cats.l_under_dental = cats.l_under_dental + 1 end
  if got:find('\204\160') and not expected:find('\204\160') then cats.l_over_postalv = cats.l_over_postalv + 1 end
  if not got:find('\204\160') and expected:find('\204\160') then cats.l_under_postalv = cats.l_under_postalv + 1 end

  -- Length comparisons
  if got ~= expected and expected:find('\204\138') and not got:find('\204\138') then
    cats.missing_length = cats.missing_length + 1
  end
  if got ~= expected and not expected:find('\204\138') and got:find('\204\138') then
    cats.extra_length = cats.extra_length + 1
  end
end
f:close()

print('Total errors:', total)
print()
local sorted = {}
for k, v in pairs(cats) do table.insert(sorted, {k, v}) end
table.sort(sorted, function(a, b) return a[2] > b[2] end)
for _, p in ipairs(sorted) do
  print(p[1] .. ': ' .. p[2])
end
