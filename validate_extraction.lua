-- Phase 1 validation: compare new engine vs old token prototype (27-word probe + full wordlist)
-- Goal: 0 differences between new engine and old prototype output.

local old = require("irish_tokens")
local new = require("irish_engine_new")

local function normalize(word)
  return (word or ""):gsub("^%s*(.-)%s*$", "%1")
end

local probe_words = {
  "glas", "glais", "alt", "ailt", "seomra", "trom", "bonn", "fón",
  "sheol", "thóg", "shíl", "a Sheáin", "aithrí", "brath", "cnoc",
  "tnúth", "Tadhg", "'ur", "íocfaidh", "marcaigh", "chugham",
  "láimh", "leabhar", "dugaire", "Gaelach", "Gaedhlaing",
}

local total_ok, total_diff = 0, 0
for _, word in ipairs(probe_words) do
  local ok, ophon = pcall(old.transcribe_tokens, word)
  if not ok then ophon = "ERROR:" .. ophon end
  local nword = normalize(word)
  local nphon = new.transcribe(nword)
  local match = ophon == nphon
  if match then
    total_ok = total_ok + 1
    print("OK:   " .. word .. " -> " .. ophon)
  else
    total_diff = total_diff + 1
    print("DIFF: " .. word)
    print("  old: " .. ophon)
    print("  new: " .. nphon)
  end
end

print(string.format("\nSummary: %d OK, %d DIFF", total_ok, total_diff))
