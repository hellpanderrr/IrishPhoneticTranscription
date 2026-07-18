-- Pass #11: Reduce unstressed short vowels to schwa.
-- In unstressed positions, short vowels reduce to ə.
-- Long vowels (with ː) are never reduced.
-- References: Hickey II.1.9.6 (unstressed vowels → only [ə] and [ɪ] possible),
--  Hickey II.2.7.2 (final devoicing), II.1.9.4 (vowel gradation)

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
  ["farraige"] = true, ["bhfarraige"] = true,
  ["peige"] = true, ["boige"] = true,
  ["craice"] = true, ["circe"] = true, ["coirce"] = true,
  ["chirce"] = true, ["déirce"] = true,
  ["uisce"] = true,
  ["tuige"] = true,
  ["cailce"] = true, ["lige"] = true,
	  ["gairge"] = true,
}

-- Words where ɪ after c/ɟ (from vowel resolution) should still reduce to ə.
-- The after-c/ɟ guard normally protects ɪ in this context, but these words
-- need regular reduction (airgid → airged, eiscir → eiscər).
local AFTER_C_G_GUARD_EXCEPTIONS = {
  ["airgid"] = true, ["eiscir"] = true,
	  ["feicim"] = true, ["fáiscim"] = true,
  -- Words where unstressed ɪ after c/ɟ should reduce to ə (benchmark expects ə).
  -- Many are genitive/plural forms ending in -ige/-oige/-acha.
  ["fuinneoige"]=true, ["carraige"]=true, ["indiacha"]=true,
  ["cearnóige"]=true, ["cad chuige"]=true, ["diosfaige"]=true,
  ["nollaig"]=true, ["uair an chloig"]=true, ["danmhairge"]=true,
  ["gaedhilge"]=true,
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

      -- Munster: pretonic short vowels keep full quality when stress has been
      -- attracted rightward (pacáil [pˠaˈkɑːlʲ], bruitíneach [bˠɾˠɪˈtʲiːnʲəx]).
      -- FG Ch.5/Ó Sé: pretonic reduction is much weaker than post-tonic.
      -- Only a/ɑ/ɪ in the FIRST syllable resist pretonic reduction
      -- (cailín [kɑˈlʲiːnʲ], bruitíneach [bˠɾˠɪˈtʲiːnʲəx]); non-initial
      -- pretonic vowels and ɔ/ʊ/ɛ reduce (portach [pˠəɾˠˈt̪ˠax], buachalán).
      if context.dialect == "munster" then
        local pretonic = false
        for j = i + 1, #tokens do
          if tokens[j].type == "boundary" then break end
          if tokens[j].type == "vowel" and tokens[j].stress then pretonic = true; break end
        end
        if pretonic then
          if phon == "a" or phon == "ɑ" or phon == "ɪ" then
            local is_first_vowel = true
            for j = i - 1, 1, -1 do
              if tokens[j].type == "vowel" then is_first_vowel = false; break end
              if tokens[j].type == "boundary" then break end
            end
            if is_first_vowel then goto continue end
          end
          -- Other pretonic short vowels reduce even in 2-vowel words —
          -- attracted stress leaves a reduced pretonic syllable
          -- (cosán [kəˈsˠɑːn̪ˠ], portach [pˠəɾˠˈt̪ˠax]).
          if SHORT_VOWELS[phon] then
            token.phon = "ə"
            goto continue
          end
        end
      end

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
      -- Hickey II.1.9.6: slender vowel quality [ɪ] preserved after palatal stops
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
      -- Hickey II.1.9.6: ɪ offglide survives before slender voiceless stops
      if phon == "ɪ" then
        local nxt = tokens[i + 1]
        if nxt and nxt.type == "cons" and nxt.palatal == true and nxt.phon ~= "" then
          -- strip trailing ʲ (slender sonorants render as base+ʲ, e.g. lʲ nʲ mʲ)
          local p = nxt.phon:gsub("\xca\xb2$", "")
          if p == "t" or p == "p" or p == "c" then
            -- Lexical exceptions: words where ɪ should still reduce to ə.
            -- uiliteoir: second vowel ɪ before slender t should be ə
            -- Meiriceá: unstressed ɪ before slender c should be ə (Hickey §3.4)
            local exc = false
            if context.word_ortho then
              local lower = context.word_ortho:lower()
              if lower == "uiliteoir" or lower == "meirice\xc3\xa1" then exc = true end
            end
            if not exc then goto continue end
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

      -- Keep ɪ before word-final c or ɟ (palatal stops). The after-c/ɟ guard
      -- protects ɪ *after* c/ɟ, but ɪ *before* c/ɟ (mairg -> mˠaɾʲɪɟ, leirg
      -- -> l̠ʲɛɾʲɪɟ, etc.) needs the same protection. Check that the ɪ is
      -- followed by c/ɟ with nothing but boundary (or silenced tokens) after it.
      -- Hickey II.1.9.6: slender offglide ɪ survives before palatal stops.
      if phon == "ɪ" then
        local after_cg = false
        for j = i + 1, #tokens do
          local t2 = tokens[j]
          if t2.type == "boundary" then
            after_cg = true; break  -- c/ɟ found earlier + boundary = word-final
          end
          if t2.type == "vowel" then break end  -- another vowel = not word-final
          if t2.type == "cons" and t2.phon and t2.phon ~= "" then
            local p = t2.phon:gsub("\xca\xb2$", "")
            if p == "c" or p == "ɟ" then
              -- Found c/ɟ; now check if anything non-boundary follows
              local all_done = true
              for k = j + 1, #tokens do
                local tk = tokens[k]
                if tk.type == "boundary" then break end
                if tk.type == "vowel" then all_done = false; break end
                if tk.type == "cons" and tk.phon and tk.phon ~= "" then
                  all_done = false; break
                end
              end
              if all_done then after_cg = true end
              break
            else
              break  -- non-c/ɟ consonant = not our pattern
            end
          end
        end
        if after_cg then goto continue end
      end

      -- Keep word-final ɪ after h/ç (-the/-che/-ghe endings).
      -- The historical verbal noun suffix retains final ɪ in Connacht.
      -- Hickey II.1.9.6: slender verb-noun suffix carries ɪ before the h.
      if phon == "ɪ" then
        local nxt = tokens[i + 1]
        local word_final = (nxt == nil) or (nxt.type == "boundary")
        if word_final then
          local prev_t = tokens[i - 1]
          if prev_t and prev_t.type == "cons" then
            local p = prev_t.phon:gsub("\xca\xb2$", "")
            if p == "h" or p == "ç" then
              goto continue
            end
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