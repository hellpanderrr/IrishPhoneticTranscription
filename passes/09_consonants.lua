-- Pass #9: Resolve consonant tokens to IPA.
-- Handles broad/slender alternation and voiceless sonorants.
-- References: Hickey II.1.7 (consonant system — stops, fricatives, pairs),
--  FG Ch.5 (Connacht consonant inventory), FG Appendix A (sound catalog)

local S = require("passes._shared")

return {
  name = "consonants",
  writes_context = false,

  run = function(tokens, context)
    for i, token in ipairs(tokens) do
      if token.type ~= "cons" then goto continue end
      -- Skip tokens already silenced or vocalized by earlier passes
      if token.phon == "" then goto continue end
      if token.source == "vocalized" then goto continue end

      local prev = tokens[i - 1]

      -- Hickey II.1.7.2: bh/mh → [vˠ/vʲ] or [w]
      -- Connacht: /v/ weakens to [w] intervocalically and initially (a bhua→[ə wuə])
      -- Southern: retains [v]; broad sonorant clusters → [vˠ]
      if token.ortho == "bh" or token.ortho == "mh" then
        if token.palatal == true then
          token.phon = "vʲ"
        elseif token.palatal == false then
          -- Word-initial broad bh/mh before a consonant cluster: historically /vˠ/
          -- in Connacht before broad sonorant (r/l) + short vowel "a" (not "ai"),
          -- or before "n". Otherwise /w/ before vowels and other contexts.
          local word_initial = (prev == nil) or (prev.type == "boundary")
          if word_initial then
            local nxt = tokens[i + 1]
            if nxt and nxt.type == "cons" and nxt.ortho == "n" then
              token.phon = "vˠ"
            elseif nxt and nxt.type == "cons" and (nxt.ortho == "r" or nxt.ortho == "l") then
              -- Check the vowel after the sonorant: short "a" (not "ai") -> vˠ
              local vowel_after = tokens[i + 2]
              if vowel_after and vowel_after.type == "vowel" and
                 vowel_after.ortho == "a" then
                token.phon = "vˠ"
              else
                token.phon = "w"
              end
            else
              token.phon = "w"
            end
          else
            -- Hickey II.1.7.2: non-initial broad mh/bh retained as [v] before
            -- consonants (coda); weakened to [w] before vowels or word-finally.
            -- Pass #06 already silenced historically vocalised forms.
            -- Lexical exceptions: words where non-initial broad mh/bh weakens
            -- to [w] even before a consonant (Connacht weakening in specific stems)
            local word_ortho = context and context.word_ortho or ""
            local W_BEFORE_C = {
              faobhrach=true, naomhtar=true,
            }
            local nxt = tokens[i + 1]
            if nxt and nxt.type == "cons" and nxt.phon and nxt.phon ~= ""
               and not W_BEFORE_C[word_ortho] then
              token.phon = "vˠ"  -- before consonant = coda (retained)
            else
              token.phon = "w"    -- before vowel or word-final -> weakened
            end
          end
        else
          token.phon = "vˠ"
        end
      elseif token.ortho == "ch" then
        if token.palatal == true then
          -- Hickey II.1.7.2: slender ch → [ç] after front V, [c] word-initially;
          -- after back V/without front context → [h]. Broad ch → [x].
          local prev_v = tokens[i - 1]
          if prev_v and prev_v.type == "vowel" then
            -- Check ortho for front vowel: simple i/e/í/é or digraphs
            -- ending in i (ai/aoi/ei/oi/ui etc. - palatal offglide = front context)
            local b1 = (prev_v.ortho:byte(1) or 0)
            local b2 = (prev_v.ortho:byte(2) or 0)
            if b1 == 0x69 or b1 == 0x65 then
              token.phon = "\xc3\xa7"  -- i or e
            elseif b1 == 0xC3 and (b2 == 0xAD or b2 == 0xA9) then
              token.phon = "\xc3\xa7"  -- í or é
            elseif prev_v.ortho == "ai" or prev_v.ortho == "aoi" or
                   prev_v.ortho == "ei" or prev_v.ortho == "oi" or
                   prev_v.ortho == "ui" or prev_v.ortho == "aí" or
                   prev_v.ortho == "oí" or prev_v.ortho == "uí" then
              token.phon = "\xc3\xa7"  -- front-vowel digraphs
            else
              token.phon = "h"
            end
          else
            token.phon = "\xc3\xa7"
          end
        else
          token.phon = "x"
        end
      -- Hickey II.1.7.2: slender sh → [ç] before back rounded V, [h] elsewhere.
      -- Broad sh → [h] (lenition of s)
      elseif token.ortho == "sh" then
        -- Connacht: slender sh before back rounded vowel -> ç.
        -- shiúl /çuːlˠ/, Sheoirse /çoːɾˠʃə/
        -- Otherwise: slender sh before front vowels -> h.
        -- shé /heː/, shín /hiːnʲ/, ó shin /oː hɪnʲ/
        local nxt = tokens[i + 1]
        local is_back_rounded = false
        if token.palatal == true and nxt and nxt.type == "vowel" then
          if nxt.ortho == "eo" or nxt.ortho == "eoi" then
            is_back_rounded = true
          elseif nxt.ortho == "u" or nxt.ortho == "ú" then
            is_back_rounded = true
          elseif nxt.ortho == "o" or nxt.ortho == "ó" then
            is_back_rounded = true
          elseif nxt.ortho == "i" then
            -- Palatal marker "i" before back vowel (iú, io)
            local nnxt = tokens[i + 2]
            if nnxt and nnxt.type == "vowel" and
               (nnxt.ortho == "ú" or nnxt.ortho == "u" or nnxt.ortho == "o" or nnxt.ortho == "ó") then
              is_back_rounded = true
            end
          end
        end
        if is_back_rounded then
          token.phon = "\xc3\xa7"  -- ç
        else
          token.phon = "h"
        end
      elseif token.ortho == "th" then
        if i == #tokens then
          token.phon = ""
        else
          local word_initial = (prev == nil) or (prev.type == "boundary")
          local nxt = tokens[i + 1]
          -- Word-initial slender th -> ç before back rounded vowel (eo).
          if word_initial and token.palatal == true and nxt and nxt.type == "vowel" and nxt.ortho == "eo" then
            token.phon = "\xc3\xa7"  -- ç
          else
            token.phon = "h"
          end
        end
      elseif token.ortho == "dh" or token.ortho == "gh" then
        local next = tokens[i + 1]
        if i == #tokens then
          -- Word-final dh/gh: silent
          token.phon = ""
        elseif token.palatal == true then
          token.phon = "j"
        else
          token.phon = "ɣ"
        end
      elseif token.ortho == "ph" then
        token.phon = S.palatal_consonant(token, "fʲ", "fˠ")
      elseif token.ortho == "fh" then
        token.phon = ""
      elseif token.ortho == "bhf" then
            -- Hickey II.1.7.2: non-initial broad mh/bh retained as [v] before
            -- consonants (coda) or word-finally; weakened to [w] only before
            -- vowels (onset). Pass #06 already silenced historically vocalised forms.
            local nxt = tokens[i + 1]
            if nxt and nxt.type == "cons" and nxt.phon and nxt.phon ~= "" then
              token.phon = "vˠ"  -- before consonant = coda
            elseif nxt and nxt.type == "boundary" then
              token.phon = "vˠ"  -- word-final = coda
            elseif not nxt then
              token.phon = "vˠ"  -- word-final = coda
            else
              token.phon = "w"    -- before vowel = onset -> weakened
            end
      -- Hickey II.1.7.2: s does NOT palatalize before labials (sméar→[sˠmʲeːɾˠ], not *[ʃmʲeːɾˠ])
      elseif token.ortho == "s" then
        -- s before p/t/k/m: check polarity. s stays broad before LABIALS
        -- (p, m, b, f) per Hickey II.1.7.2. Before coronals (t, c) it
        -- palatalizes if the following stop is slender.
        local next = tokens[i + 1]
        local word_initial_s = (prev == nil) or (prev.type == "boundary")
        if word_initial_s and next and (next.ortho == "p" or next.ortho == "m" or next.ortho == "b" or next.ortho == "f") then
          token.phon = "sˠ"  -- s always broad before labials (Hickey II.1.7.2)
        elseif next and (next.ortho == "t" or next.ortho == "c") then
          if next.palatal == true then
            token.phon = "ʃ"
          else
            token.phon = "sˠ"
          end
        elseif token.palatal == true then
          token.phon = "ʃ"
        else
          token.phon = "sˠ"
        end
      elseif token.ortho == "c" then
        token.phon = S.palatal_consonant(token, "c", "k")
      elseif token.ortho == "g" then
        token.phon = S.palatal_consonant(token, "ɟ", "ɡ")
      elseif token.ortho == "t" then
        token.phon = S.palatal_consonant(token, "tʲ", "t̪ˠ")
      elseif token.ortho == "d" then
        token.phon = S.palatal_consonant(token, "dʲ", "d̪ˠ")
                  elseif token.ortho == "n" then
        -- Hickey II.1.7.8: n assimilates to place of following stop:
        --   before velar/palatal stops (c, g) → ŋ (broad) / ɲ (slender).
        --   Word-internal n before c/g becomes velar nasal.
        --   Does NOT apply before fricatives (ch, gh, sh).
        local next_cons = tokens[i + 1]
        if next_cons and next_cons.type == "cons" and
           (next_cons.ortho == "c" or next_cons.ortho == "g") then
          if token.palatal == true then
            token.phon = "ɲ"
          else
            token.phon = "ŋ"
          end
        elseif token.is_voiceless then
          token.phon = S.palatal_consonant(token, "n̥", "n̪ˠ")
        else
          token.phon = S.palatal_consonant(token, "nʲ", "n̪ˠ")
        end
elseif token.ortho == "ng" then
        -- Hickey II.1.7.8: ng before coronal stops (t, d, th) -> n
        local next_c = tokens[i + 1]
        if next_c and next_c.type == "cons" and
           (next_c.ortho == "t" or next_c.ortho == "d" or next_c.ortho == "th") then
          token.ortho = "n"
          token.palatal = next_c.palatal
          token.broad = nil
          if next_c.palatal == true then
            token.phon = "nʲ"
          else
            token.phon = "n̪ˠ"
          end
        else
          token.phon = S.palatal_consonant(token, "\xC9\xB2", "\xC5\x8B")
        end
elseif token.ortho == "l" then
        if token.is_voiceless then
          token.phon = S.palatal_consonant(token, "l̥", "lˠ")
        else
          token.phon = S.palatal_consonant(token, "lʲ", "lˠ")
        end
      -- Hickey II.1.8: /r/→[ɾˠ] before dental stops (coronal assimilation);
      --   palatal /rʲ/ does not occur word-initially; neutralized after lenition
      elseif token.ortho == "r" then
        -- Connacht: r before dental consonants (t, d, n, s) is broad ɾˠ
        -- regardless of vowel context. Irish phonotactics forbid /rʲ/ before
        -- dental stops in syllable coda (Hickey II.1.8).
        local next_c = tokens[i + 1]
        local force_broad = next_c and next_c.type == "cons" and
          (next_c.ortho == "s" or next_c.ortho == "t" or
           next_c.ortho == "d" or next_c.ortho == "n")
        if force_broad then
          token.palatal = false
        end
        -- Lexical override: r before slender s/t should be slender in specific words
        if context.word_ortho and next_c and next_c.palatal == true then
          local w = context.word_ortho:lower()
          local slender_r_words = {
            ["mairteoil"] = true, ["deirtí"] = true, ["abairtí"] = true,
            peirsis = true, abairte = true, peirsil = true,
            peirs = true, deirtear = true,
            bhfuiltear = true, fuiltear = true, beirtear = true,
          }
          if slender_r_words[w] then
            token.palatal = true
          end
        end
        if token.is_voiceless then
          token.phon = S.palatal_consonant(token, "r̥", "ɾˠ")
        else
          token.phon = S.palatal_consonant(token, "ɾʲ", "ɾˠ")
        end
      -- Hickey II.1.7.2: f under lenition → ∅ (but fh→∅ is the lenited form, handled above)
      -- Future-f: f-lenition in verbal inflection (póg-f-aidh→poːkə)
      elseif token.ortho == "f" then
        -- Future-tense suffix -fidh/-faidh: f between consonant and (i|ai)+dh → context rule.
        -- After obstruent (c/t/d/g/s/ch/x): f elides (∅). After sonorant (l/n/r): f → h.
        -- After vowel (future tense marker -ó-/-f-): f → h.
        -- After bh/mh: bh+mh+f hardens to single f (scríobhfaidh→ʃcɾʲiːfˠə).
        local prev = tokens[i - 1]
        local next1 = tokens[i + 1]
        local next2 = tokens[i + 2]
        -- Match -fidh (f + i + dh) or -faidh (f + ai + dh) or -fead (f + ea + d) or
        -- -feadh (f + ea + dh) or -fas (f + a + s) or -fadh (f + a + dh) or -faimid (f + ai + mid)
        -- or -far (f + a + r) or -fá (f + á)
        -- The future -f- suffix lenites between a stem-final consonant and the verb ending.
        -- After obstruent: f → ∅. After sonorant: f → h.
        local is_future_suffix = next1 and next1.type == "vowel"
          and (prev and prev.type == "cons" and prev.phon and prev.phon ~= "" or
               prev and prev.type == "vowel")
          and (
            -- -fidh: f + i + dh
            (next1.ortho == "i" and next2 and next2.ortho == "dh")
            -- -faidh: f + ai + dh
            or (next1.ortho == "ai" and next2 and next2.ortho == "dh")
            -- -fead: f + ea + d (1sg. future)
            or (next1.ortho == "ea" and next2 and next2.ortho == "d" and (not tokens[i+3] or tokens[i+3].ortho ~= "h"))
            -- -feadh: f + ea + dh (autonomous future)
            or (next1.ortho == "ea" and next2 and next2.ortho == "dh")
            -- -fas: f + a + s (relative future) -- block if another syllable follows
            or (next1.ortho == "a" and next2 and next2.ortho == "s" and (not tokens[i+3] or tokens[i+3].type ~= "vowel"))
            -- -fad: f + a + d (1sg. future) -- word-final only
            or (next1.ortho == "a" and next2 and next2.ortho == "d" and (not tokens[i+3] or tokens[i+3].ortho ~= "h") and (not tokens[i+3] or tokens[i+3].type ~= "vowel"))
            -- -fadh: f + a + dh -- block if another syllable follows
            or (next1.ortho == "a" and next2 and next2.ortho == "dh" and (not tokens[i+3] or tokens[i+3].type ~= "vowel"))
            -- -faimid: f + ai + mid
            or (next1.ortho == "ai" and tokens[i+2] and tokens[i+2].ortho == "mid")
            -- -far: f + a + r (autonomous future) -- block if another syllable follows
            or (next1.ortho == "a" and next2 and next2.ortho == "r" and (not tokens[i+3] or tokens[i+3].type ~= "vowel"))
            -- -fá: f + á (2sg. conditional/future)
            or (next1.ortho == "\xC3\xA1")
          )
        if is_future_suffix then
          -- bh/mh + f hardening: when the preceding token is bh or mh,
          -- the f absorbs into a single hard f (scríobhfaidh→ʃcɾʲiːfˠə).
          -- Hickey II.1.7.2: lenited labial before future -f- hardens to [f].
          if prev and prev.type == "cons" and (prev.ortho == "bh" or prev.ortho == "mh") then
            prev.phon = ""
            token.phon = S.palatal_consonant(token, "fʲ", "fˠ")
            -- bh/mh already resolved to vˠ/w; silence them and let f carry the labial
          else
            local pp = prev and prev.phon or ""
            local is_obstruent = false
            -- Check for multi-byte IPA obstruents first (ʃ = 0xCA 0x83).
            -- Plain gmatch(".") iterates bytes, not UTF-8 chars.
            if pp:find("\xCA\x83") then
              is_obstruent = true
            end
            if not is_obstruent then
              for ch in pp:gmatch(".") do
                if ch == "k" or ch == "g" or ch == "p" or ch == "t"
                  or ch == "d" or ch == "b" or ch == "s" or ch == "x"
                  or ch == "f" or ch == "v" or ch == "h" then
                  is_obstruent = true; break
                end
              end
            end
            -- Check for multi-byte IPA devoicing targets (ɟ = 0xC9 0x9F)
            local is_dev_target = (pp == "\xC9\x9F")  -- ɟ (U+025F)
            if not is_obstruent and is_dev_target then
              is_obstruent = true
            end
            -- Determine if -far/-fá suffixes keep f (don't elide/lenite to h).
            -- Hickey II.1.7.2: future -f- suffix — f retained before r/á
            -- in specific contexts, elided/lenited before dh/d/s.
            -- -far (-f + a + r): f always kept (molfar, lúbfar).
            -- -fá (-f + á): f→h after consonant (déarfá), kept after vowel (-ófá).
            local keep_f = false
            if next2 and next2.ortho == "r" then
              keep_f = true  -- -far
            elseif next1.ortho == "\xC3\xA1" and prev and prev.type == "vowel" then
              keep_f = true  -- -fá after vowel (-ófá)
            end
            if is_obstruent then
              -- Regressive devoicing: a voiced stop before future -f- suffix
              -- devoices to its voiceless counterpart. creidfead→creitfead,
              -- lúbfad→lúbpād, ligfidh→ligcidh etc.
              local DEV = {
                ["d"] = "t", ["dʲ"] = "tʲ", ["d̪ˠ"] = "t̪ˠ",
                b = "p", ["bʲ"] = "pʲ", ["bˠ"] = "pˠ",
                ["ɟ"] = "c", ["ɡ"] = "k",
              }
              if DEV[pp] then
                prev.phon = DEV[pp]
              end
              if keep_f then
                token.phon = S.palatal_consonant(token, "fʲ", "fˠ")
              else
                token.phon = ""
              end
            else
              if keep_f then
                token.phon = S.palatal_consonant(token, "fʲ", "fˠ")
              else
                token.phon = "h"
              end
            end
          end
        else
          token.phon = S.palatal_consonant(token, "fʲ", "fˠ")
        end
      elseif token.ortho == "b" then
        token.phon = S.palatal_consonant(token, "bʲ", "bˠ")
      elseif token.ortho == "m" then
        if token.is_voiceless then
          token.phon = S.palatal_consonant(token, "m̥", "mˠ")
        else
          token.phon = S.palatal_consonant(token, "mʲ", "mˠ")
        end
      elseif token.ortho == "p" then
        token.phon = S.palatal_consonant(token, "pʲ", "pˠ")
      end

      ::continue::
    end
    return tokens
  end,
}
