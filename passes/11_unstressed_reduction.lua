-- Pass #11: Reduce unstressed vowels to schwa.
-- Short vowels not bearing primary stress reduce to [ə] or [ɪ].
-- Monosyllables never reduce (via context.is_monosyllabic).

local S = require("passes._shared")

return {
  name = "unstressed_reduction",
  writes_context = false,

  run = function(tokens, context)
    if context.is_monosyllabic then return tokens end
    if not context.stress_index then return tokens end
    if context.vowel_count <= 1 then return tokens end

    for i, token in ipairs(tokens) do
      if token.type ~= "vowel" or token.stress then goto continue end
      if token.is_epenthetic then goto continue end

      local prev = tokens[i - 1]
      local next = tokens[i + 1]

      -- a after vocalized fricative -> schwa
      if token.ortho == "a" and not S.is_stressed_vowel(prev) and not S.is_stressed_vowel(next) and
         (prev and prev.type == "cons" and
          (prev.ortho == "bh" or prev.ortho == "mh" or prev.ortho == "dh" or prev.ortho == "gh")) then
        token.phon = "ə"

      -- e before n -> schwa
      elseif token.ortho == "e" and not S.is_stressed_vowel(prev) and not S.is_stressed_vowel(next) and
             (next and next.type == "cons" and next.ortho == "n") then
        token.phon = "ə"

      -- ai before dh/gh -> schwa
      elseif token.ortho == "ai" and next and next.type == "cons" and
             (next.ortho == "dh" or next.ortho == "gh") then
        token.phon = "ə"
      end

      ::continue::
    end
    return tokens
  end,
}
