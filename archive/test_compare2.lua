package.path='?.lua;ustring/?.lua'

print("Loading monolith...")
local monolith = require('irish')
print("Monolith loaded, result:", monolith.transcribe('glas'))

print("Loading refactored...")
local refactored = require('irish_main')
print("Refactored loaded, result:", refactored.transcribe('glas'))