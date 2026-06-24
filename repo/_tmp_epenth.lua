package.path = "F:/projects/transcription/wiktionary_ipa_phoneme_lexicons/irish/repo/?.lua;F:/projects/transcription/wiktionary_ipa_phoneme_lexicons/irish/repo/?/init.lua;" .. package.path
package.path = "archive/?.lua;" .. package.path
local engine = require('irish_engine_new')
local bench = require('_benchmark')
local ustring = require("ustring.ustring")
local ulen, usub = ustring.len, ustring.sub

-- ə = U+0259 = \xc9\x99
local schwa = string.char(0xC9, 0x99)

local missing = {}
for word, entry in pairs(bench) do
  local got = engine.transcribe(word, 'connacht')
  local exp = entry.expected
  if got ~= exp then
    local m, n = ulen(got), ulen(exp)
    local d = {}
    for i = 0, m do d[i] = {}; for j = 0, n do d[i][j] = 0 end end
    for i = 0, m do d[i][0] = i end
    for j = 0, n do d[0][j] = j end
    for i = 1, m do
      for j = 1, n do
        local cost = (usub(got,i,i) == usub(exp,j,j)) and 0 or 1
        d[i][j] = math.min(d[i-1][j]+1, d[i][j-1]+1, d[i-1][j-1]+cost)
      end
    end
    if d[m][n] == 1 then
      local i, j = 1, 1
      while i <= m and j <= n do
        if usub(got,i,i) == usub(exp,j,j) then i=i+1; j=j+1
        else
          if i+1 <= m and usub(got,i+1,i+1) == usub(exp,j,j) then
            i = i+1
          elseif j+1 <= n and usub(got,i,i) == usub(exp,j+1,j+1) then
            if usub(exp,j,j) == schwa then
              missing[#missing+1] = {word=word, got=got, exp=exp}
            end
            j = j+1
          else
            if usub(exp,j,j) == schwa then
              missing[#missing+1] = {word=word, got=got, exp=exp}
            end
            i=i+1; j=j+1
          end
        end
      end
    end
  end
end

print("=== Words missing schwa (Lev-1) ===")
for _,e in ipairs(missing) do
  print(e.word .. " | got=" .. e.got .. " exp=" .. e.exp)
end
print("Count: " .. #missing)
