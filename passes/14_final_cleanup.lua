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

    -- Step 6: /rʲ/ word-final assibilation (Hickey Ch.2)
    -- In some dialects, slender /rʲ/ → [ʃ] at word end
    for i = #tokens, 1, -1 do
      if tokens[i].type == "cons" and tokens[i].phon == "ɾʲ" then
        local is_final = true
        for j = i + 1, #tokens do
          if tokens[j].phon and tokens[j].phon ~= "" then is_final = false; break end
        end
        if is_final then
          tokens[i].phon = "ʃ"
          tokens[i].source = "assibilation"
        end
        break
      end
    end

    -- Step 7: Consonant aspiration (Fuaimeanna 3.5.1)
    -- Word-initial voiceless stops aspirate [ʰ] except after /s/.
    for i, token in ipairs(tokens) do
      if token.type ~= "cons" or not token.phon then goto continue end
      local phon = token.phon
      local is_voiceless_stop = phon == "pʲ" or phon == "pˠ" or phon == "p" or
                                phon == "tʲ" or phon == "t̪ˠ" or phon == "t" or
                                phon == "c" or phon == "k"
      if not is_voiceless_stop then goto continue end

      -- After /s/ blocks aspiration
      local prev = tokens[i - 1]
      if prev and prev.type == "cons" and prev.phon and
         (prev.phon == "sˠ" or prev.phon == "ʃ") then
        goto continue
      end

      -- Aspirate word-initially (most reliable case)
      if i == 1 or (prev and prev.phon == "") then
        token.phon = phon .. "ʰ"
      end

      ::continue::
    end

    -- Step 8: Conservative glide insertion (sleamhnóga) (Fuaimeanna 3.5.3)
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

    return tokens
  end,
}
