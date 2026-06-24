package.path = "F:/projects/transcription/wiktionary_ipa_phoneme_lexicons/irish/repo/?.lua;F:/projects/transcription/wiktionary_ipa_phoneme_lexicons/irish/repo/?/init.lua;" .. package.path
package.path = "archive/?.lua;" .. package.path
local engine = require('irish_engine_new')
local bench = require('_benchmark')

-- Categorize remaining schwa-missing words by pattern
local words = {
  "urchar","donncha","dorchadas","seanchas","Beannchar","sorcha",
  "dhorcha","dorchacht",
  "gairme","Gearmáinis","foirmle","ormsa","Airméin","formad","calma",
  "foirfe","dearfach","dearfa","marfach","deifreach",
  "thairbhe","tairbhe","searbhas","dearbhú",
  "eitre","Eibhlín","bíchearb",
  "tinnis","Spáinnis","Meiriceá",
  "cosán","mba",
  "cíoch","beithíoch","buíochán","buíocháin","céilíoch",
  "le chéile","le déanaí",
  "fadhbanna","adhairc",
}
for _,w in ipairs(words) do
  local tokens = engine.tokenize_word(w, 'connacht')
  local got = engine.transcribe(w, 'connacht')
  local exp = bench[w] and bench[w].expected or "N/A"
  print("=== " .. w .. " got=" .. got .. " exp=" .. exp .. " ===")
  for i,t in ipairs(tokens) do
    print(string.format("  %d: ortho=[%s] type=%s phon=[%s] stress=%s epenth=%s",
      i, t.ortho, t.type, t.phon, tostring(t.stress), tostring(t.is_epenthetic)))
  end
end
