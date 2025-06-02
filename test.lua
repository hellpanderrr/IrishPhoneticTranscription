-- test_lua_pattern_strict_debug.lua

local ustring_lib = require("ustring.ustring")
local ufind = ustring_lib.find
local toNFC = ustring_lib.toNFC

local ANY_CONSONANT_PHONETIC_RAW_CHARS_STR = "kgptdfbmnszrlLNRMçjɣŋhwcʃɟɾ"
local CONSONANT_CLASS_NO_CAPTURE = "[" .. ANY_CONSONANT_PHONETIC_RAW_CHARS_STR .. "]"

print(ufind("ɪm","^(ˈ?)([eɛɪ])(m')(#?)$"))