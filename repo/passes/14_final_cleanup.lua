-- Pass #14: Final cleanup and diacritics.
-- 1. Remove final silent mutated fricatives (th, dh, gh) with vowel concatenation
-- 2. Add ç after vowel before final broad th
-- 3. Delete final ç/ɣ/h after long vowels
-- 4. Unstressed final devoicing: slender g [ɟ] -> [c]
-- 5. ch + s -> tʃ sandhi
-- 6. Remove empty tokens and normalize

local S = require("passes._shared")

local function is_long_vowel_phon(phon)
  if not phon then return false end
  return phon:match("[ɑeiou]ː") ~= nil
end

return {
  name = "final_cleanup",
  writes_context = false,

  run = function(tokens, context)
    -- Step 1: Handle final silent mutated fricatives
    if #tokens > 0 then
      local last = tokens[#tokens]
      if last.type == "cons" and S.SILENT_MUTATED_FINALS[last.ortho] then
        local prev = tokens[#tokens - 1]
        if prev and prev.type == "vowel" then
          prev.source = "vowel_before_silent_fricative"
          if last.ortho == "th" then
            prev.phon = prev.phon .. "ç"
          end
        end
        last.phon = ""
      end
    end

    -- Step 2: Delete final ç/ɣ/h after long vowels
    for i, token in ipairs(tokens) do
      if token.type == "vowel" and is_long_vowel_phon(token.phon) then
        -- Check next token for ç/ɣ/h that should be deleted
        local next_t = tokens[i + 1]
        if next_t and next_t.phon then
          local ph = next_t.phon
          if ph == "ç" or ph == "ɣ" or ph == "h" then
            -- Only if this is the last non-empty token
            local has_further_content = false
            for j = i + 2, #tokens do
              if tokens[j].phon and tokens[j].phon ~= "" then
                has_further_content = true
                break
              end
            end
            if not has_further_content then
              next_t.phon = ""
            end
          end
        end
      end
    end

    -- Step 3: Unstressed final devoicing (Connacht/Ulster rule)
    -- Word-final slender g [ɟ] in unstressed syllable -> [c]
    for i = #tokens, 1, -1 do
      if tokens[i].phon == "ɟ" then
        -- Check if this is truly the last non-empty token
        local is_final = true
        for j = i + 1, #tokens do
          if tokens[j].phon and tokens[j].phon ~= "" then
            is_final = false
            break
          end
        end
        if is_final then
          -- Check preceding vowel is unstressed
          local prev_vowel = S.find_preceding_vowel(tokens, i)
          if prev_vowel and not prev_vowel.stress then
            tokens[i].phon = "c"
          end
        end
        break
      end
    end

    -- Step 4: ch + s -> tʃ sandhi
    for i = 1, #tokens - 1 do
      if tokens[i].phon == "x" and tokens[i + 1].ortho == "s" then
        tokens[i].phon = "tʃ"
        tokens[i + 1].phon = ""
      end
    end

    -- Step 5: (removed — slender coda diacritics are handled by polarity-based consonant mapping in pass #9)

    return tokens
  end,
}
