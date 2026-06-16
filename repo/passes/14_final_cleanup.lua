-- Pass #14: Final cleanup and diacritics.
-- 1. Remove final silent mutated fricatives (th, dh, gh) — append ç for th
-- 2. Strip trailing ç/ɣ/h from vowels that have a long phon (matches production rule)
-- 3. Unstressed final devoicing: slender g [ɟ] -> [c] (Hickey Ch.2)
-- 4. ch + s -> tʃ sandhi

local S = require("passes._shared")
local ustring = require("ustring.ustring")
local ugsub = ustring.gsub
local usub = ustring.sub
local umatch = ustring.match

local function strip_trailing_fricative(phon)
  if not phon then return phon end
  -- Match pattern: long vowel + ç/ɣ/h at end
  -- Use ugsub (UTF-8-aware) not plain gsub — ː, ç, ɣ are multi-byte
  return ugsub(phon, "([ɑeiou]ː)[ɣçh]$", "%1")
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

    -- Step 2: Strip trailing ç/ɣ/h from long-vowel phons
    -- This matches the production rule: ([ɑeiou]ː)[ɣçh]$ → %1
    for _, token in ipairs(tokens) do
      if token.type == "vowel" then
        token.phon = strip_trailing_fricative(token.phon)
      end
    end

    -- Step 3: Delete final ç/ɣ/h tokens after long vowels (production rule)
    for i, token in ipairs(tokens) do
      if token.type == "vowel" and token.phon and token.phon:match("[ɑeiou]ː") then
        local next_t = tokens[i + 1]
        if next_t and next_t.phon and (next_t.phon == "ç" or next_t.phon == "ɣ" or next_t.phon == "h") then
          local has_further_content = false
          for j = i + 2, #tokens do
            if tokens[j].phon and tokens[j].phon ~= "" then
              has_further_content = true; break
            end
          end
          if not has_further_content then
            next_t.phon = ""
          end
        end
      end
    end

    -- Step 4: Unstressed final devoicing (Connacht/Ulster)
    for i = #tokens, 1, -1 do
      if tokens[i].phon == "ɟ" then
        local is_final = true
        for j = i + 1, #tokens do
          if tokens[j].phon and tokens[j].phon ~= "" then is_final = false; break end
        end
        if is_final then
          local prev_vowel = S.find_preceding_vowel(tokens, i)
          if prev_vowel and not prev_vowel.stress then
            tokens[i].phon = "c"
          end
        end
        break
      end
    end

    -- Step 5: ch + s -> tʃ sandhi
    for i = 1, #tokens - 1 do
      if tokens[i].phon == "x" and tokens[i + 1].ortho == "s" then
        tokens[i].phon = "tʃ"; tokens[i + 1].phon = ""
      end
    end

    -- Step 6 removed: rʲ → ʃ assibilation (Hickey Ch.2)
    -- 503 words produced ʃ incorrectly, only 54 expected it

    -- Step 8:*  (was 7: aspiration removed — dataset doesn't use ʰ
    -- Only insert [j] after palatal C when followed by back rounded vowels (ɔ, o, u, ʊ).
    -- Broad C + front V → [w] is not productive; removed as it produced ~1000 false positives.
    for i, token in ipairs(tokens) do
      if token.type ~= "cons" then goto continue end
      if token.phon == "" then goto continue end
      if token.source == "strong_sonorant" then goto continue end
      local next = tokens[i + 1]
      if not next or next.type ~= "vowel" then goto continue end
      local vphon = next.phon
      if not vphon or vphon == "" then goto continue end
      if token.palatal ~= true then goto continue end

      -- Get first IPA character (strip length mark)
      local vfirst = ugsub(vphon, "ː", "")
      vfirst = usub(vfirst, 1, 1)

      -- Palatal C before back rounded vowel → j-glide
      -- NOT for a/ɑ (which commonly follow palatal C without glide)
      if vfirst and umatch(vfirst, "[oɔuʊ]") then
        token.phon = token.phon .. "j"
      end

      ::continue::
    end

    -- Step 9: Function word overrides — replace ALL phonemes with hardcoded IPA.
    -- Must be the very last step so no further rules touch these tokens.
    -- Split tokens into word segments so function words inside multi-word phrases are caught.
    local fw_segments = {}
    local fw_current = {}
    for _, t in ipairs(tokens) do
      if t.type == "boundary" then
        if #fw_current > 0 then table.insert(fw_segments, fw_current) end
        fw_current = {}
      else
        table.insert(fw_current, t)
      end
    end
    if #fw_current > 0 then table.insert(fw_segments, fw_current) end

    for _, seg in ipairs(fw_segments) do
      if #seg == 0 then goto next_fw_seg end
      -- Build normalized ortho for lookup
      local seg_ortho = ""
      for _, t in ipairs(seg) do
        if t.ortho then seg_ortho = seg_ortho .. t.ortho end
      end
      if seg_ortho == "" then goto next_fw_seg end

      -- Use simple lowercased lookup (normalize_ortho strips accents)
      local lookup_word = ustring.lower(seg_ortho)
      local fw_ipa = S.FUNCTION_WORDS_OVERRIDE[lookup_word]
      if fw_ipa then
        local override_idx = 1
        for _, t in ipairs(seg) do
          if fw_ipa[override_idx] then
            t.phon = fw_ipa[override_idx]
            t.stress = false
          end
          override_idx = override_idx + 1
        end
        -- Also silence any trailing apostrophe boundary (e.g., "a'" -> ə not ə')
        local next_boundary = tokens[seg[#seg].ortho_indices[2] + 1] or {}
        if next_boundary.type == "boundary" and next_boundary.ortho == "'" then
          next_boundary.phon = ""
        end
      end
      ::next_fw_seg::
    end

    -- Step 10: Downgrade stress in multi-word phrases.
    -- Primary stress on the first content word, secondary stress on subsequent content words.
    -- Function words (overridden above) already have stress=false.
    if #fw_segments > 1 then
      local content_word_idx = 0
      local current_pos = 1
      for _, seg in ipairs(fw_segments) do
        -- Check if this segment was overridden by function word rules
        local seg_ortho = ""
        for _, t in ipairs(seg) do
          if t.ortho then seg_ortho = seg_ortho .. t.ortho end
        end
        local lookup_word = ustring.lower(seg_ortho)
        local is_function_word = S.FUNCTION_WORDS_OVERRIDE[lookup_word] ~= nil

        if not is_function_word then
          content_word_idx = content_word_idx + 1
          if content_word_idx > 1 then
            -- Downgrade primary stress in this segment to secondary (no stress mark)
            -- Secondary stress is currently not rendered; removing it entirely
            -- is closer to the expected IPA format.
            for _, t in ipairs(seg) do
              t.stress = false
            end
          end
        end
        current_pos = current_pos + #seg + 1
      end
    end

    return tokens
  end,
}
