package.path='?.lua;ustring/?.lua'

-- Test monolith
local monolith = require('irish')
local mono_result = monolith.transcribe('glas')
print("Monolith result for 'glas':", mono_result)

-- Test refactored
local refactored = require('irish_main')
local ref_result = refactored.transcribe('glas')
print("Refactored result for 'glas':", ref_result)

print("")
if mono_result == ref_result then
    print("MATCH!")
else
    print("MISMATCH!")
end