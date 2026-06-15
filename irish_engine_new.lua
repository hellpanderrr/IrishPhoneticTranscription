-- New Irish G2P engine: token-array pipeline.
-- Replaces the monolith irish_engine.lua + irish_rules.lua.
-- Loads passes from passes/ directory and orchestrates them.

local S = require("passes._shared")
local passes = require("passes.init")
local ustring = require("ustring.ustring")
local ulen = ustring.len
local usub = ustring.sub
local umatch = ustring.match

-- Tokenizer: splits orthographic word into tokens
local function tokenize_word(word)
  local tokens = {}
  local i = 1
  word = S.normalize_ortho(word)

  while i <= ulen(word) do
    local c1 = usub(word, i, i)
    local c2 = i < ulen(word) and usub(word, i + 1, i + 1) or ""
    local c3 = i + 2 <= ulen(word) and usub(word, i + 2, i + 2) or ""
    local tri = c1 .. c2 .. c3
    local digraph = c1 .. c2

    if c1 == " " then
      table.insert(tokens, S.make_token(" ", "boundary", i, i))
      i = i + 1
    elseif tri == "d'fh" then
      local token = S.make_token(tri, "cons", i, i + 2)
      token.is_mutated = true
      token.mutation = "eclipsis"
      table.insert(tokens, token)
      i = i + 3
    elseif digraph == "bh" or digraph == "mh" or digraph == "ch" or
           digraph == "dh" or digraph == "gh" or digraph == "ph" or
           digraph == "sh" or digraph == "th" or digraph == "fh" then
      local token = S.make_token(digraph, "cons", i, i + 1)
      token.is_mutated = true
      token.mutation = "lenition"
      table.insert(tokens, token)
      i = i + 2
    elseif c1 == "'" then
      local token = S.make_token(c1, "boundary", i, i)
      token.source = "apostrophe"
      table.insert(tokens, token)
      i = i + 1
    elseif tri == "aoi" or tri == "eoi" then
      table.insert(tokens, S.make_token(tri, "vowel", i, i + 2))
      i = i + 3
    elseif digraph == "ng" then
      table.insert(tokens, S.make_token(digraph, "cons", i, i + 1))
      i = i + 2
    elseif S.VOWEL_DIGRAPHS[digraph] then
      table.insert(tokens, S.make_token(digraph, "vowel", i, i + 1))
      i = i + 2
    elseif S.is_vowel_char(c1) then
      table.insert(tokens, S.make_token(c1, "vowel", i, i))
      i = i + 1
    elseif S.is_consonant_char(c1) then
      table.insert(tokens, S.make_token(c1, "cons", i, i))
      i = i + 1
    else
      table.insert(tokens, S.make_token(c1, "unknown", i, i))
      i = i + 1
    end
  end

  return tokens
end

-- Render output: place stress mark before the syllable onset
-- IPA convention: ˈCV, not CˈV
local function render_output(tokens)
  -- Pre-process: move stress from vowel to preceding onset consonant(s)
  for i = #tokens, 1, -1 do
    if tokens[i].type == "vowel" and tokens[i].stress then
      local onset_start = i
      for j = i - 1, 1, -1 do
        local t = tokens[j]
        if t.type == "cons" and t.phon and t.phon ~= "" then
          onset_start = j
        else
          break
        end
      end
      if onset_start < i then
        tokens[i].stress = false
        tokens[onset_start].stress = true
      end
    end
  end

  local parts = {}
  for _, token in ipairs(tokens) do
    if token.phon and token.phon ~= "" then
      if token.stress then
        table.insert(parts, S.STRESS_MARK)
      end
      table.insert(parts, token.phon)
    end
  end
  return table.concat(parts)
end

-- Orchestrator entry point
local function transcribe(word, dialect)
  local tokens = tokenize_word(word)
  local context = {
    dialect = dialect or "connacht",
    word_ortho = word,
    is_monosyllabic = false,
    vowel_count = 0,
    root_vowel_count = 0,
    stress_index = nil,
    stress_position = 0,
    known_prefixes = S.KNOWN_PREFIXES,
  }
  tokens = passes.run_all(tokens, context)
  return render_output(tokens), tokens
end

return {
  transcribe = transcribe,
  tokenize_word = tokenize_word,
  render_output = render_output,
}
