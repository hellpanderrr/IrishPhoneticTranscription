-- Pass #2: Calculate primary stress position.
-- Also computes is_monosyllabic, vowel_count, root_vowel_count.
-- Runs early so vocalization (pass #6) and reduction (pass #11) are stress-aware.

local S = require("passes._shared")

return {
  name = "stress",
  writes_context = true,

  run = function(tokens, context)
    local vowel_count = S.count_vowel_tokens(tokens)

    context.vowel_count = vowel_count
    if vowel_count == 0 then return tokens end
    if vowel_count == 1 then
      context.is_monosyllabic = true
      context.stress_index = nil
      -- Don't set token.stress for monosyllables — render_output uses this to add ˈ
      return tokens
    end

    -- Check for known unstressed words/suffixes
    local ortho = ""
    for _, t in ipairs(tokens) do
      if t.ortho and t.ortho ~= "" then ortho = ortho .. t.ortho end
    end
    local core = require("irish_core")
    if core.UNSTRESSED_WORDS_AND_SUFFIXES[ortho] then return tokens end

    -- Check for unstressed prefix by looking at first consonant+next segment pairs
    local has_prefix = false
    if S.count_vowel_tokens(tokens) >= 2 and tokens[1].type == "cons" then
      local next2 = tokens[2]
      if next2 and (next2.type == "vowel" or next2.type == "cons") then
        local key = tokens[1].ortho .. tokens[2].ortho
        if S.KNOWN_PREFIXES[key] then
          has_prefix = true
        end
      end
    end

    local stress_index = S.vowel_token_index(tokens)
    if not stress_index then return tokens end

    -- Stress adjustment: initial cluster with r/l pulls stress left
    if stress_index > 1 and tokens[stress_index - 1].type == "cons" and
       tokens[stress_index - 2] and tokens[stress_index - 2].type == "cons" and
       (tokens[stress_index - 1].ortho == "r" or tokens[stress_index - 1].ortho == "l") then
      stress_index = stress_index - 1
    end

    -- ge/le initial clusters
    if tokens[stress_index].ortho == "e" and stress_index > 1 and
       tokens[stress_index - 1].type == "cons" and
       (tokens[stress_index - 1].ortho == "g" or tokens[stress_index - 1].ortho == "l") then
      stress_index = stress_index - 1
    elseif tokens[stress_index].ortho == "e" and stress_index > 1 and
           tokens[stress_index - 1].type == "vowel" and
           tokens[stress_index - 1].ortho == "a" then
      stress_index = stress_index - 1
    end

    -- a after g
    if tokens[stress_index].ortho == "a" and stress_index > 1 and
       tokens[stress_index - 1].type == "cons" and
       tokens[stress_index - 1].ortho == "g" then
      stress_index = stress_index - 1
    end

    -- Compute root_vowel_count (vowels after prefix)
    if has_prefix then
      context.root_vowel_count = 0
      local in_prefix = true
      for i, t in ipairs(tokens) do
        if in_prefix and t.type == "cons" and i <= 4 then
          -- still in prefix region
        elseif in_prefix then
          in_prefix = false
          if t.type == "vowel" then context.root_vowel_count = context.root_vowel_count + 1 end
        elseif t.type == "vowel" then
          context.root_vowel_count = context.root_vowel_count + 1
        end
      end
      if context.root_vowel_count <= 1 then
        -- Prefix + short root: treat as effectively monosyllabic for sonorant rules
        context.is_monosyllabic = true
      end
    else
      context.root_vowel_count = vowel_count
    end

    context.stress_index = stress_index
    tokens[stress_index].stress = true
    return tokens
  end,
}
