package.path='?.lua;ustring/?.lua'
local m = require('irish_main')
print("Module loaded successfully")
print("Testing transcribe('glas'):")
print(m.transcribe('glas'))