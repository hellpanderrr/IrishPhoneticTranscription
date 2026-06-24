local content = io.open("passes/10_vowels.lua", "rb"):read("*a")
-- The bad strings are literally: \x{00C9}\x{009E} etc.
-- Replace them with proper hex escapes
local old1 = "\x{00C9}\x{009E}"  -- should be \xc9\x9e (ɞ)
local new1 = "\xc9\x9e"
local old2 = "\x{00C9}\x{009B}"  -- should be \xc9\x9b (ɛ)
local new2 = "\xc9\x9b"
local old3 = "\x{00C9}\x{00AA}"  -- should be \xc9\xaa (ɪ)
local new3 = "\xc9\xaa"

local count = 0
local function replace(old, new)
  local pos = content:find(old, 1, true)
  while pos do
    content = content:sub(1, pos - 1) .. new .. content:sub(pos + #old)
    count = count + 1
    pos = content:find(old, pos + #new, true)
  end
end

replace(old1, new1)
replace(old2, new2)
replace(old3, new3)

io.open("passes/10_vowels.lua", "wb"):write(content)
print("Fixed " .. count .. " escape sequences")
