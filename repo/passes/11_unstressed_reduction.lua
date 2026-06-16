-- Pass #11: Reduce unstressed short vowels to schwa.
-- In unstressed positions, short vowels reduce to ə.
-- Long vowels (with ː) are never reduced.

local S = require("passes._shared")

-- Words in the UNSTRESSED table that should NOT have their vowel reduced to ə.
-- These words have specific phonetic forms handled by other passes (e.g. r-lowering).
local REDUCTION_EXCEPTIONS = {
  ar = true, as = true, im = true,
}

local SHORT_VOWELS = { ["a"] = true, ["e"] = true, ["i"] = true, ["o"] = true, ["u"] = true,
                       ["ɛ"] = true, ["ɪ"] = true, ["ɔ"] = true, ["ʊ"] = true }

-- Check if phon is a short vowel (no length mark)
local function is_short_vowel(phon)
  if not phon or phon == "" then return false end
  -- Phon containing ː is long — never reduce
  if phon:match(ustring and "[".. (ustring and ustring.len and "ː" or "ː") .."]") then
    return false
  end
  return SHORT_VOWELS[phon]
end

return {
  name = "unstressed_reduction",
  writes_context = false,

  run = function(tokens, context)
    if context.vowel_count <= 1 then
      if context.is_monosyllabic then return tokens end

      -- Check if this is an exception word
      local ortho = ""
      for _, t in ipairs(tokens) do
        if t.ortho and t.ortho ~= "" then ortho = ortho .. t.ortho end
      end
      if REDUCTION_EXCEPTIONS[ortho] then return tokens end

      -- Reduce unstressed short vowel to ə (only if not a long vowel)
      for _, token in ipairs(tokens) do
        if token.type == "vowel" and not token.stress then
          if token.phon and not token.phon:match("ː") and SHORT_VOWELS[token.phon] then
            token.phon = "ə"
          end
          break
        end
      end
      return tokens
    end

    for i, token in ipairs(tokens) do
      if token.type ~= "vowel" or token.stress then goto continue end
      if token.is_epenthetic then goto continue end
      local phon = token.phon
      if not phon or phon == "" then goto continue end

      -- Must not reduce vowel before another vowel — it's part of a VV diphthong
      local next_token = tokens[i + 1]
      if next_token and next_token.type == "vowel" then goto continue end

      -- For 2-vowel words: short vowels in non-final syllable keep full quality
      if context.vowel_count == 2 and SHORT_VOWELS[phon] then
        local has_later_vowel = false
        for j = i + 1, #tokens do
          if tokens[j].type == "vowel" then has_later_vowel = true; break end
        end
        if has_later_vowel then goto continue end
      end

      if SHORT_VOWELS[phon] then
        token.phon = "ə"
      end
      ::continue::
    end
    return tokens
  end,
}
