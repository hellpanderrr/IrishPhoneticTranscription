package.path = "F:/projects/transcription/wiktionary_ipa_phoneme_lexicons/irish/repo/?.lua;F:/projects/transcription/wiktionary_ipa_phoneme_lexicons/irish/repo/?/init.lua;" .. package.path
package.path = "archive/?.lua;" .. package.path
local engine = require('irish_engine_new')
local bench = require('_benchmark')
local ustring = require("ustring.ustring")
local ulen, usub = ustring.len, ustring.sub

local ioch_expected_i = {}
local ioch_expected_ischwa = {}

for word, entry in pairs(bench) do
  if word:find(CP1252Toobj) then
    local got = engine.transcribe(word, 'connacht')
    local got_i = got:find(CP1252Toobj) and got:find(CP1252Toobj) or nil
  end
end
