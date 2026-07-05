-- Apply 3 fixes to passes/09_consonants.lua
local content = io.open('passes/09_consonants.lua', 'r'):read('*a')
local nl = '\n'

-- Hex literal sequences as stored in file: literal \xNN text (LONG STRINGS = no escape processing)
local SH = [[\xCA\x83]]  -- ʃ
local DJ = [[\xC9\x9F]]  -- ɟ
local GA = [[\xC9\xA1]]  -- ɡ
local CC = [[\xC3\xA7]]  -- ç (uppercase for pp:find)
local GN = [[\xC9\xA3]]  -- ŋ

-- For matching the file: LOWERCASE hex in token.phon assignments
local CC_low = [[\xc3\xa7]]  -- ç lowercase for token.phon = "\xc3\xa7"

local ok = 0

-- ========== CHANGE 1: th+r deletion ==========
-- Find the th section, then find "h" within it, then find dh/gh after it
local th_anchor = 'elseif token.ortho == "th" then'
local dh_anchor = 'elseif token.ortho == "dh" or token.ortho == "gh" then'
local h_anchor = 'token.phon = "h"'

local th_pos = content:find(th_anchor, 1, true)
if not th_pos then print('CHANGE 1: th anchor not found'); os.exit(1) end
print('CHANGE 1: th anchor at byte ' .. th_pos)

-- Find "h" within the th block (after the th anchor, before dh/gh)
local dh_pos = content:find(dh_anchor, th_pos, true)
if not dh_pos then print('CHANGE 1: dh anchor not found'); os.exit(1) end
print('CHANGE 1: dh anchor at byte ' .. dh_pos)

-- Find "h" between th and dh
local h_pos, h_end = content:find(h_anchor, th_pos, true)
if not h_pos or h_pos > dh_pos then print('CHANGE 1: h not found within th section'); os.exit(1) end
print('CHANGE 1: h anchor at byte ' .. h_pos)

-- The between content (from end of "h" to start of dh/gh)
local between = content:sub(h_end + 1, dh_pos - 1)
print('CHANGE 1: Between "h" and dh/gh:')
print('[' .. between .. ']')

-- Expected: \n          end\n        end\n
-- Let's verify this and extract the indentation patterns
local end1_s, end1_e = between:find('end', 1, true)  -- first "end" = inner end
if not end1_s then print('CHANGE 1: first end not found'); os.exit(1) end
local end2_s, end2_e = between:find('end', end1_e, true)  -- second "end" = outer end
if not end2_s then print('CHANGE 1: second end not found'); os.exit(1) end

-- Verify it matches the expected pattern (no extra code between the ends and elseif)
local before_end1 = between:sub(1, end1_s - 1)  -- \n + spaces
local between_ends = between:sub(end1_e + 1, end2_s - 1)  -- \n + spaces
local after_end2 = between:sub(end2_e + 1)  -- \n + spaces

print('  before first end: [' .. before_end1 .. ']')
print('  between ends: [' .. between_ends .. ']')
print('  after second end: [' .. after_end2 .. ']')

-- Build the th+r insertion block at 8-space indent (between inner end and outer end)
local ins = nl .. '        -- Connacht: /h/ from th deletes before r after long V/diphthong'
        .. nl .. '        -- Kept after short a/ai/ea (athru) and word-initially (thra)'
        .. nl .. '        if nxt and nxt.type == "cons" and nxt.ortho == "r" then'
        .. nl .. '          local word_init = (prev == nil) or (prev.type == "boundary")'
        .. nl .. '          if not word_init then'
        .. nl .. '            local prev_v = tokens[i - 1]'
        .. nl .. '            local keep = prev_v and prev_v.type == "vowel"'
        .. nl .. '              and (prev_v.ortho == "a" or prev_v.ortho == "ai" or prev_v.ortho == "ea")'
        .. nl .. '            if not keep then'
        .. nl .. '              token.phon = ""'
        .. nl .. '            end'
        .. nl .. '          end'
        .. nl .. '        end'

-- Reconstruct: keep the structure but add the th+r block between the two ends
-- Old: ..."h" + between + elseif...dh
-- New: ..."h" + before_end1 + "end" + ins + between_ends + "end" + after_end2 + elseif...dh
local old_mid = between
local new_mid = before_end1 .. 'end' .. ins .. between_ends .. 'end' .. after_end2

content = content:sub(1, h_end) .. new_mid .. content:sub(dh_pos)
ok = ok + 1
print('CHANGE 1: Applied')

-- ========== CHANGE 2: Multi-byte obstruent detection ==========
-- Replace pp:find("\xCA\x83") with pp:find("\xCA\x83") or pp:find("\xC9\x9F") or ...
local old_find = 'pp:find("' .. SH .. '")'
local new_find = 'pp:find("' .. SH .. '") or pp:find("' .. DJ .. '") or pp:find("' .. GA .. '") or pp:find("' .. CC .. '")'
local f2_start, f2_end = content:find(old_find, 1, true)
if f2_start then
  content = content:sub(1, f2_end - #old_find) .. new_find .. content:sub(f2_end + 1)
  ok = ok + 1
  print('CHANGE 2: Applied')
else
  print('CHANGE 2: Cannot find "' .. old_find .. '"')
  print('  old_find bytes:')
  for i = 1, #old_find do io.write(string.format('%02X ', old_find:byte(i))) end
  print('')
  os.exit(1)
end

-- ========== CHANGE 3: Devoicing ==========
-- Find "if is_obstruent then" block and replace with devoicing version
local a3 = 'if is_obstruent then'
local a3_start, a3_end = content:find(a3, 1, true)
if not a3_start then print('CHANGE 3: Cannot find "if is_obstruent then"'); os.exit(1) end

-- Find "else" after the if
local else3_start, else3_end = content:find('else', a3_end, true)
if not else3_start then print('CHANGE 3: else not found'); os.exit(1) end

-- Find "end" after the else
local end3_start, end3_end = content:find('end', else3_end, true)
if not end3_start then print('CHANGE 3: end not found'); os.exit(1) end

-- Read indentation for this block
local line_start = a3_start
while line_start > 1 and content:sub(line_start-1, line_start-1) ~= nl do
  line_start = line_start - 1
end
local indent = content:sub(line_start, a3_start - 1)
local body_indent = indent .. '  '

-- Build replacement
local r3 = indent .. 'if is_obstruent then' .. nl
       .. body_indent .. 'token.phon = ""' .. nl
       .. body_indent .. '-- Future -f- devoices preceding obstruent' .. nl
       .. body_indent .. 'if pp:find("' .. DJ .. '") then' .. nl
       .. body_indent .. '  prev.phon = "c"' .. nl
       .. body_indent .. 'elseif pp:find("' .. GA .. '") then' .. nl
       .. body_indent .. '  prev.phon = "k"' .. nl
       .. body_indent .. 'elseif pp:find("' .. GN .. '") then' .. nl
       .. body_indent .. '  prev.phon = "x"' .. nl
       .. body_indent .. 'else' .. nl
       .. body_indent .. '  local d = {b="p", d="t", g="k", v="f"}' .. nl
       .. body_indent .. '  for from, to in pairs(d) do' .. nl
       .. body_indent .. '    if pp:find(from) then' .. nl
       .. body_indent .. '      prev.phon = pp:gsub(from, to, 1); break' .. nl
       .. body_indent .. '    end' .. nl
       .. body_indent .. '  end' .. nl
       .. body_indent .. 'end' .. nl
       .. indent .. 'else' .. nl
       .. body_indent .. 'token.phon = "h"' .. nl
       .. indent .. 'end'

-- Verify the block being replaced
local block = content:sub(a3_start, end3_end)
print('CHANGE 3: Block to replace:')
print(block)

if block:find('if is_obstruent') and block:find('else') and block:find('token.phon = ""') then
  -- Use line_start-1 (NOT a3_start-1) to avoid doubling the indent:
  -- a3_start-1 includes the indent spaces, but r3 already starts with indent.
  content = content:sub(1, line_start - 1) .. r3 .. content:sub(end3_end + 1)
  ok = ok + 1
  print('CHANGE 3: Applied')
else
  print('CHANGE 3: Block mismatch')
  os.exit(1)
end

if ok >= 3 then
  local out = io.open('passes/09_consonants.lua', 'w')
  out:write(content)
  out:close()
  print('')
  print('ALL 3 CHANGES APPLIED SUCCESSFULLY!')
else
  print('Only ' .. ok .. '/3 applied')
  os.exit(1)
end
