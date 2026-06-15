-- Pass #6d: Anticipatory vowel raising (Western Irish, Connacht only).
-- Hickey Ch.2: Short /a/ or /o/ in the FIRST syllable raises to [ɪ] or [ʊ]
-- if the second syllable contains a long [aː].
-- coláiste → kʊlˠaːʃtʲə, caisleán → kɪʃlʲaːnˠ.
-- Only applies when anticipatory_raising = true (Connacht).
-- Runs after r_lowering (#6c), before labial_vocalization (#6e).
-- Uses orthography to check, since vowel resolution hasn't run yet.

local S = require("passes._shared")

return {
  name = "anticipatory_raising",
  writes_context = false,

  run = function(tokens, context)
    local dv = S.DIALECTS[context.dialect] or S.DIALECTS.connacht
    if not dv.anticipatory_raising then return tokens end
    if not context.vowel_count or context.vowel_count < 2 then return tokens end

    for i, token in ipairs(tokens) do
      if token.type ~= "vowel" then goto continue end
      -- Skip if already modified by a prior pass (e.g. r_lowering, vowel_gradation)
      if token.source ~= "lexeme" then goto continue end
      local ortho = token.ortho
      if ortho ~= "a" and ortho ~= "o" then goto continue end

      -- Check: is this vowel in the first syllable?
      -- Scan backwards: if there's another vowel before this, not first syllable
      local is_first = true
      for j = i - 1, 1, -1 do
        if tokens[j].type == "vowel" or tokens[j].type == "boundary" then
          is_first = false; break
        end
      end
      if not is_first then goto continue end

      -- Check if a later vowel orthographically contains a long á
      -- (maps to long [aː] after vowel resolution). Check for á, ái, etc.
      for j = i + 1, #tokens do
        if tokens[j].type == "vowel" then
          local o = tokens[j].ortho
          if o and (o == "á" or o == "ái" or o == "aí") then
            if ortho == "a" then
              token.phon = "ɪ"
              token.source = "anticipatory_raising"
            elseif ortho == "o" then
              token.phon = "ʊ"
              token.source = "anticipatory_raising"
            end
            break
          end
        end
      end

      ::continue::
    end
    return tokens
  end,
}
