-- Pass #11: Reduce unstressed short vowels to schwa.
-- In unstressed positions, short vowels reduce to ə.
-- Long vowels (with ː) are never reduced.

local S = require("passes._shared")

-- Words in the UNSTRESSED table that should NOT have their vowel reduced to ə.
-- These words have specific phonetic forms handled by other passes (e.g. r-lowering).
local REDUCTION_EXCEPTIONS = {
  ar = true, as = true, im = true,
}

-- Words where word-final -e after c/ɟ should reduce to ə, NOT stay as ɪ.
-- Most -e after slender c/ɟ keeps ɪ (glice, gaige, pice, lice), but these
-- lexical exceptions follow regular reduction to ə.
local FINAL_E_C_G_EXCEPTIONS = {
  ["farraige"] = true, ["fharraige"] = true, ["bhfarraige"] = true,
  ["peige"] = true, ["boige"] = true,
  ["craice"] = true, ["circe"] = true, ["coirce"] = true,
  ["chirce"] = true, ["déirce"] = true,
  ["uisce"] = true,
  ["tuige"] = true,
  ["cailce"] = true, ["lige"] = true,
}

-- Words where ɪ after c/ɟ (from vowel resolution) should still reduce to ə.
-- The after-c/ɟ guard normally protects ɪ in this context, but these words
-- need regular reduction (airgid → airged, eiscir → eiscər).
local AFTER_C_G_GUARD_EXCEPTIONS = {
  ["airgid"] = true, ["eiscir"] = true,
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

      -- Don't reduce ɪ after palatal c/ɟ (preserves Irish slender vowel quality).
      -- A few lexical exceptions (airgid, eiscir) need regular reduction.
      if phon == "ɪ" then
        local prev_t = tokens[i - 1]
        if prev_t and prev_t.type == "cons" and
           (prev_t.phon == "c" or prev_t.phon == "ɟ") then
          local exc = false
          if context.word_ortho then
            if AFTER_C_G_GUARD_EXCEPTIONS[context.word_ortho:lower()] then exc = true end
          end
          if not exc then goto continue end
        end
      end

      -- Don't reduce ɪ before a slender voiceless stop (t, p, c). In Connacht
      -- the slender offglide survives before these: expected ɪ ~89% before
      -- slender t, ~91% before p, and c is already covered by the word-final
      -- rule above for medial positions too. afraic, ceimic, fisic, critic.
      if phon == "ɪ" then
        local nxt = tokens[i + 1]
        if nxt and nxt.type == "cons" and nxt.palatal == true and nxt.phon ~= "" then
          -- strip trailing ʲ (slender sonorants render as base+ʲ, e.g. lʲ nʲ mʲ)
          local p = nxt.phon:gsub("\xca\xb2$", "")
          if p == "t" or p == "p" or p == "c" then
            goto continue
          end
        end
      end

      -- Word-final unstressed ɛ after a slender palatal stop (c, ɟ):
      -- keep ɪ instead of reducing to ə. The slender offglide survives before
      -- these consonants (glice /ɟlʲɪcɪ/, gaige /ɡaɟɪ/).
      -- Some lexical exceptions (farraige, Peige, uisce, etc.) need ə instead.
      -- Only applies to a TRUE word-final vowel (next token is boundary/end).
      if phon == "ɛ" then
        local prev_t = tokens[i - 1]
        local nxt = tokens[i + 1]
        local word_final = (nxt == nil) or (nxt.type == "boundary")
        if word_final and prev_t and prev_t.type == "cons" and
           prev_t.palatal == true and
           (prev_t.phon == "c" or prev_t.phon == "ɟ") then
          -- Check lexical exceptions (lowercased to match table keys)
          local exc = false
          if context.word_ortho then
            local w = context.word_ortho:lower()
            if FINAL_E_C_G_EXCEPTIONS[w] then exc = true end
          end
          if not exc then
            token.phon = "ɪ"
            goto continue
          end
        end
      end

      -- Unstressed 'ui' before a word-final slender consonant: keep ɪ, not ə.
      -- The ui digraph ends in slender i; before a final slender cons the
      -- offglide survives (cruit /kɾˠɪtʲ/, diúraic /dʲuːɾˠɪc/).
      if token.ortho == "ui" then
        local nxt = tokens[i + 1]
        if nxt and nxt.type == "cons" and nxt.palatal == true and nxt.phon ~= "" then
          local word_final_cons = true
          for j = i + 2, #tokens do
            local t = tokens[j]
            if t.type == "boundary" then break end
            if (t.type == "cons" or t.type == "vowel") and t.phon and t.phon ~= "" then
              word_final_cons = false; break
            end
          end
          if word_final_cons then
            token.phon = "ɪ"
            goto continue
          end
        end
      end

      if SHORT_VOWELS[phon] then
        token.phon = "ə"
      end
      ::continue::
    end
    return tokens
  end,
}
