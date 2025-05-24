-- Simple test script for Unicode file writing
local test_file = io.open("unicode_test.txt", "w")
test_file:write("\239\187\191") -- UTF-8 BOM

-- Test writing a Unicode character directly
test_file:write("Unicode test: ŋ\r\n")

-- Test writing the same character with its UTF-8 byte representation
local ng_char_utf8 = string.char(0xC5, 0x8B) -- UTF-8 bytes for ŋ
test_file:write("UTF-8 bytes: " .. ng_char_utf8 .. "\r\n")

test_file:close()
print("Test completed. Check unicode_test.txt")