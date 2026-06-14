-- Pass #14: Final cleanup and diacritics.
-- Handles final silent mutated fricatives (th, dh, gh) and
-- deletion of final ç/ɣ/h after long vowels.

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

    -- Step 2: Delete final ç/ɣ/h after long vowels (production rule: ([ɑeiou]ː)[ɣçh]$ → %1)
    for i, token in ipairs(tokens) do
      if token.type == "vowel" and is_long_vowel_phon(token.phon) then
        local next_t = tokens[i + 1]
        if next_t and next_t.phon then
          local ph = next_t.phon
          if ph == "ç" or ph == "ɣ" or ph == "h" then
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

    return tokens
  end,
}
