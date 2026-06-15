package.path='?.lua;ustring/?.lua'
print("Starting test...")
local ok, err = pcall(function()
    local m = require('irish_main')
    print("Module loaded successfully")
    print("Testing transcribe('glas'):")
    local result = m.transcribe('glas')
    print(result)
end)
if not ok then
    print("ERROR:", err)
end