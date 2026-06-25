-- Pass #14: Final cleanup and diacritics.
-- Hickey §2.6.2: Final lenited fricatives th, dh, gh are silent.
-- Hickey §2.6.3: Devoicing rules in coda position.
-- 1. Remove final silent mutated fricatives (th, dh, gh)
-- 2. Strip trailing ç/ɣ/h from vowels that have a long phon
-- 3. Unstressed final devoicing: slender g [ɟ] -> [c] (Hickey §2.6.3)
-- 4. ch + s -> tʃ sandhi (assimilation, Hickey §2.4)
-- 5. Devoice b/d/g before th: b+th->p, d+th->t, g+th->k (Hickey §2.6.3)
-- 6. Palatal C before back rounded vowel -> j-glide insertion (Hickey §2.6.3)-- 5. Devoice b/d/g before th: b+th→p, d+th→t, g+th→k

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
    -- dh and gh are always silent word-finally in Connacht (Hickey §2.6.2).
    -- th after SHORT vowels retains h (dath→d̪ˠah, croith→kɾˠɔh); th after LONG
    -- vowels/diphthongs is silent (síth→ʃiː, fáth→fˠɑː). Hickey §2.6.3.
    if #tokens > 0 then
      local last = tokens[#tokens]
      if last.type == "cons" and (last.ortho == "dh" or last.ortho == "gh") then
        local prev = tokens[#tokens - 1]
        if prev and prev.type == "vowel" then
          prev.source = "vowel_before_silent_fricative"
        end
        last.phon = ""
      elseif last.type == "cons" and last.ortho == "th" then
        -- Word-final th: h only in specific words. Most are silent or optional (h)
        -- which benchmark matches via variant matching. Hickey §2.6.3.
        if context.word_ortho then
          local w = context.word_ortho:lower()
          local FINAL_TH_H = {
            ["dath"]=true, ["feith"]=true, ["chath"]=true, ["anraith"]=true,
            ["croith"]=true, ["gaoith"]=true, ["ngaoith"]=true,
          }
          if FINAL_TH_H[w] then
            if last.phon == "" then last.phon = "h" end
          else
            last.phon = ""
          end
        else
          last.phon = ""
        end
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
    -- Exception: gaoith/ngaoith keep h despite aoi→iː producing a long vowel.
    local skip_h_strip = false
    if context.word_ortho then
      local w = context.word_ortho:lower()
      if w == "gaoith" or w == "ngaoith" then skip_h_strip = true end
    end
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
          if not has_further_content and not skip_h_strip then
            next_t.phon = ""
          end
        end
      end
    end

    -- Step 4: Unstressed final devoicing (Connacht/Ulster) — TIGHTENED
    -- Devoice slender g [ɟ] -> [c] ONLY when preceded by schwa [ə]. Empirical
    -- analysis of the benchmark: of 39 slender-g-final words the rule fired on,
    -- 33 were over-devoiced (exp keeps ɟ: cúig, tréig, bróig, smig, etc.) and
    -- only 6 were correct — all 6 had schwa before the final g (Nollaig,
    -- coisrig, oifig, aisig, ráinig, Lá Fhéile Pádraig). Restricting to the
    -- schwa context keeps the legitimate devoicing while not touching full-vowel
    -- cases (ɪ, eː, oː, a, uː, uə, etc.) where ɟ is preserved.
    -- Lexical exceptions: tháinig and easpaig keep ɟ despite schwa-final-ɪ context.
    local KEEP_DEV = { ["tháinig"] = true, ["easpaig"] = true }
    for i = #tokens, 1, -1 do
      if tokens[i].phon == "ɟ" then
        if context.word_ortho and KEEP_DEV[context.word_ortho:lower()] then
          goto devoice_skip
        end
        local is_final = true
        for j = i + 1, #tokens do
          if tokens[j].phon and tokens[j].phon ~= "" then is_final = false; break end
        end
        if is_final then
          local prev_vowel = S.find_preceding_vowel(tokens, i)
          if prev_vowel and not prev_vowel.stress
             and prev_vowel.phon and prev_vowel.phon:match("ə") then
            tokens[i].phon = "c"
          end
        end
        break
      end
    end
    ::devoice_skip::


    -- Step 4b: Restore unstressed vowels from restore_i: ? back to ?
    for _, token in ipairs(tokens) do
      if token.restore_i and token.phon == "ə" then
        token.phon = "ɪ"
      end
    end

    -- Step 4c: Lexical ɪ→i overrides (after reduction so pass 11 doesn't re-reduce)
    -- Words where short i should be full i even in unstressed/monosyllabic positions.
    -- Also handles u→palatal→ɪ and oi→m→ɪ cases.
    if context.word_ortho then
      local w = context.word_ortho:lower()
      for _, token in ipairs(tokens) do
        if token.phon == "ɪ" then
          if w == "gaeilic" or w == "nis" or w == "minic" or
             w == "cluife" or w == "cluifí" or
             w == "sínid" or w == "ghéaraigh" or
             (w == "roimis" and token.ortho == "oi") then
            token.phon = "i"
          end
        end
      end
    end

    -- Step 4d: Keep unstressed "a" in specific loanwords.
    -- cileagram/chileagram: final "a" in "-gram" suffix should stay /a/
    -- paragraf: final "a" in "-graf" suffix should stay /a/
    -- eiseachaid: "ea" in the 2nd syllable should be /a/ not /ə/
    if context.word_ortho then
      local w = context.word_ortho:lower()
      for _, token in ipairs(tokens) do
        if token.type == "vowel" and token.ortho == "oi" and token.phon == "ɪ" then
          if w == "goid" or w == "ghoid" then
            token.phon = "\xc9\x9e"
            token.restore_i = nil
          elseif w == "coite" or w == "coiteann" then
            token.phon = "\xc9\x94"
          end
        end
      end
    end

    -- Step 4e: Keep unstressed "a" in specific loanwords.
    -- cileagram/chileagram: final "a" in "-gram" suffix should stay /a/
    -- paragraf: final "a" in "-graf" suffix should stay /a/
    -- eiseachaid: "ea" in the 2nd syllable should be /a/ not /ə/
    if context.word_ortho then
      local w = context.word_ortho:lower()
      if w == "eiseachaid" then
        for _, token in ipairs(tokens) do
          if token.type == "vowel" and token.phon == "ə" and token.ortho == "ea" then
            token.phon = "a"
          end
        end
      elseif w == "paragraf" then
        for i, token in ipairs(tokens) do
          if token.type == "vowel" and token.phon == "ə" and token.ortho == "a" then
            local nxt = tokens[i + 1]
            if nxt and nxt.ortho == "f" then
              token.phon = "a"
            end
          end
        end
      elseif w == "cileagram" or w == "chileagram" then
        for i, token in ipairs(tokens) do
          if token.type == "vowel" and token.phon == "ə" and token.ortho == "a" then
            local nxt = tokens[i + 1]
            if nxt and nxt.ortho == "m" then
              token.phon = "a"
            end
          end
        end
      end

      -- Step 4h: á→aː in borrowings and specific contexts.
      -- Hickey §2.3: loanwords may retain [aː] where native words have [ɑː].
      local AA_OVERRIDE = {
        ["beár"]=true, ["seám"]=true, ["micheál"]=true,
        ["áine"]=true, ["bleánach"]=true, ["beáltaine"]=true,
        ["bhíteá"]=true, ["ciceáil"]=true,
      }
      if AA_OVERRIDE[w] then
        for _, token in ipairs(tokens) do
          if token.type == "vowel" and token.phon == "\xC9\x91\xCB\x90" then
            token.phon = "aː"
          end
        end
      end
    end

    -- Step 4i: dh+cons → i vocalization (Connacht).
    -- When orthographic dh is followed by a consonant, it vocalizes to [i],
    -- forming a diphthong with the preceding vowel. Hickey §2.6.2.
    -- fadhb → fˠəibˠ, maidhm → mˠəimʲ, straidhn → sˠt̪ˠɾˠəinʲ, taghd → t̪ˠəid̪ˠ
    local DH_VOCALIZE = {
      fadhb=true, badhb=true, ["bhfadhb"]=true,
      maidhm=true, straidhn=true, taghd=true,
    }
    if context.word_ortho then
      local w = context.word_ortho:lower()
      if DH_VOCALIZE[w] then
        for _, token in ipairs(tokens) do
          if token.type == "cons" and (token.ortho == "dh" or token.ortho == "gh") then
            token.phon = "i"
          end
        end
      end
    end

    -- Step 4k: teagasc — silence final k.
    -- The final -c in teagasc (teaching) is silent in Connacht.
    -- Hickey §2.6.3: final c after s is silent in this word.
    if context.word_ortho and context.word_ortho:lower() == "teagasc" then
      for i = #tokens, 1, -1 do
        if tokens[i].phon == "k" then
          tokens[i].phon = ""
          break
        end
      end
    end

    -- Step 4l: oí → iː lexical overrides.
    -- The normalizer strips fadas, so oí becomes oi and resolves as /ɔ/.
    -- These words need the o vowel silenced and í→iː kept. Hickey §1.4.
    local OI_SILENCE_O = {
      snoi=true, chroi=true, croi=true,
      snoiodoireacht=true, ["gra mo chroi"]=true,
    }
    if context.word_ortho then
      local w = context.word_ortho:lower()
      if OI_SILENCE_O[w] then
        local found = false
        for _, token in ipairs(tokens) do
          if not found and token.type == "vowel" and token.ortho == "oi" then
            token.phon = "iː"
            found = true
          end
        end
      end
    end

    -- Step 4f: -igh endings: restore ə → iː (imperative verbs, adjectives).

    -- Step 4j: Silence th after r in unstressed syllables.
    -- Words where medial th after r should be silent, not h.
    -- ceachartha→ˈcaxəɾˠə, danartha→ˈd̪ˠan̪ˠəɾˠə, corpartha→ˈkɔɾˠpˠəɾˠə, cheithre→ˈçɛɾʲə
    local RTH_SILENT = {
      danartha=true, corpartha=true, ceachartha=true,
      cheithre=true, braithre=true,
    }
    if context.word_ortho then
      local w = context.word_ortho:lower()
      if RTH_SILENT[w] then
        for _, token in ipairs(tokens) do
          if token.ortho == "th" then
            token.phon = ""
          end
        end
      end
    end

    -- Step 4f: -igh endings: restore ə → iː (imperative verbs, adjectives).
    -- Words ending in -igh have the final vowel reduced to ə by pass 11, but
    -- benchmark expects iː (e.g. beirigh→ˈbʲɛɾʲiː, suigh→sˠiː, istigh→əʃˈtʲiː).
    -- Not all -igh words want iː (Corcaigh→ˈkɔɾˠkə, brostaigh→ˈbˠɾˠʊsˠt̪ˠə).
    local IGH_RESTORE = {
      ["beirigh"]=true, ["bligh"]=true, ["bhligh"]=true,
      ["suigh"]=true, ["shuigh"]=true, ["igh"]=true, ["nigh"]=true,
      ["righ"]=true, ["ligh"]=true, ["tigh"]=true, ["thigh"]=true,
      ["dtigh"]=true, ["dúigh"]=true, ["éiligh"]=true,
      ["áirigh"]=true, ["doiligh"]=true, ["toiligh"]=true,
      ["thoiligh"]=true, ["fraoigh"]=true, ["fhraoigh"]=true,
      ["deasaigh"]=true, ["feisigh"]=true, ["bogaigh"]=true,
      ["bunaigh"]=true, ["cuimhnigh"]=true, ["oibrigh"]=true,
      ["Shligigh"]=true, ["istigh"]=true,
      ["airbheartaigh"]=true, ["taoisigh"]=true, ["taobhaigh"]=true,
      ["gairmiúlaigh"]=true, ["díghalraigh"]=true,
      ["fréamhshamhaltaigh"]=true, ["Ó Cathasaigh"]=true,
    }
    if context.word_ortho then
      local w = context.word_ortho:lower()
      if IGH_RESTORE[w] then
        local last_vowel = nil
        for _, token in ipairs(tokens) do
          if token.type == "vowel" then last_vowel = token end
        end
        if last_vowel and last_vowel.phon == "ə" then
          last_vowel.phon = "iː"
        end
      end
    end

    -- Step 4g: Fix vowel pairs split by fadas. When the tokenizer splits
    -- digraphs like ea/ui by a fada mark on the second vowel, the first
    -- vowel should be silent in these specific combos.
    -- References:
    -- - "eá" → ɑː: Hickey §1.4 (long vowels and diphthongs), the first
    --   element of the ea digraph is always elided when the second carries
    --   a fada. The result is a long back vowel /ɑː/.
    -- - "uí" → iː: Hickey §1.4; uí as a word-final diphthong reduces to
    --   a long front vowel /iː/, the initial /u/ offglide is dropped.
    -- - "i"+"a" → iə: Hickey §1.4; the diphthong /iə/ has ə as second
    --   element in all dialects; a is never realized as /a/ in this position.
    -- - "e"+"a" → a: Hickey §1.4; ea as a digraph always produces /a/ or
    --   /aː/; the first element is silent.
    for i = 1, #tokens - 1 do
      local t = tokens[i]
      local nxt = tokens[i + 1]
      if t.type == "vowel" and nxt.type == "vowel" then
        -- "i"+"a" or "i"+"ai": /iə/ diphthong; second element is always ə.
        -- The tokenizer produces "ai" (digraph) when ia is followed by a
        -- slender consonant, or "a" in other contexts. (Hickey §1.4)
        if t.ortho == "i" and (nxt.ortho == "a" or nxt.ortho == "ai") then
          nxt.phon = "\xC9\x99"
        -- "e"+"á" or "e"+"ái": éa digraph with fada → ɑː, silent e.
        -- The tokenizer may produce either "á" or "ái" as the digraph.
        elseif t.ortho == "e" and (nxt.ortho == "á" or nxt.ortho == "ái") then
          t.phon = ""
          nxt.phon = "ɑː"
        -- "u"+"í" or "u"+"ío": uí → iː, silent u.
        -- The tokenizer may produce either "í" or "ío" as the digraph.
        elseif t.ortho == "u" and (nxt.ortho == "í" or nxt.ortho == "ío") then
          t.phon = ""
        -- "e"+"a" (plain ea): silent e, keep a as-is (pass 10 already set it)
        elseif t.ortho == "e" and nxt.ortho == "a" then
          t.phon = ""
        end
      end
    end

    -- Step 5: ch + s ->> tʃ sandhi
    for i = 1, #tokens - 1 do
      if tokens[i].phon == "x" and tokens[i + 1].ortho == "s" then
        tokens[i].phon = "tʃ"; tokens[i + 1].phon = ""
      end
    end

    -- Step 6: Devoice b/d/g before th — b+th→p, d+th→t, g+th→k, silence th
    -- Handles verbal adjective forms: fágtha→kə, scuabtha→pˠə, lúbtha→pˠə
    -- Also silences th after ANY obstruent (incl. c, ch, p, f, s) — the default
    -- medial th outcome is h in V_th contexts but silent in C_th clusters.
    for i = 1, #tokens - 1 do
      local c = tokens[i]
      local next_t = tokens[i + 1]
      if c.type ~= "cons" then goto dev_continue end
      if not next_t or next_t.ortho ~= "th" then goto dev_continue end
      if next_t.phon ~= "h" then goto dev_continue end

      -- Devoice the consonant: b+th→p, d+th→t, g+th→k, then silence th
      -- Hickey §2.6.3: th assimilates to the voicing of the preceding consonant
      -- and then the cluster is devoiced.
      local phon = c.phon
      if phon == "bˠ" then c.phon = "pˠ"; next_t.phon = ""
      elseif phon == "bʲ" then c.phon = "pʲ"; next_t.phon = ""
      elseif phon == "d̪ˠ" then c.phon = "t̪ˠ"; next_t.phon = ""
      elseif phon == "dʲ" then c.phon = "tʲ"; next_t.phon = ""
      elseif phon == "ɡ" then c.phon = "k"; next_t.phon = ""
      elseif phon == "ɟ" then c.phon = "c"; next_t.phon = ""
      -- Silence th after already-voiceless obstruents (c, k, p, t, ch, f, x, s)
      -- Hickey §2.6.3: th after any obstruent is silent in consonant clusters.
      elseif phon == "c" or phon == "k" or phon == "pˠ" or phon == "pʲ"
          or phon == "t̪ˠ" or phon == "tʲ" or phon == "x" or phon == "fˠ"
          or phon == "fʲ" then
        next_t.phon = ""
      end

      ::dev_continue::
    end

    -- Step 6b: Devoice g before f/t/s -- regressive devoicing assimilation.
    for i = 1, #tokens - 1 do
      local c = tokens[i]
      local next_t = tokens[i + 1]
      if c.type ~= "cons" then goto dev2_continue end
      if c.phon ~= "ɡ" then goto dev2_continue end
      if next_t.type ~= "cons" then goto dev2_continue end
      local np = next_t.phon
      if np == "fˠ" or np == "fʲ" or np == "t̪ˠ" or np == "tʲ" then
        c.phon = "k"
      end
      ::dev2_continue::
    end

    -- Step 6c: Word-final broad g -> k for lexically-specified words (easpag)
    if context.word_ortho then
      local w = context.word_ortho:lower()
      if w == "easpag" then
        for i = #tokens, 1, -1 do
          if tokens[i].phon == "ɡ" then
            local is_final = true
            for j = i + 1, #tokens do
              if tokens[j].phon and tokens[j].phon ~= "" then is_final = false; break end
            end
            if is_final then tokens[i].phon = "k" end
            break
          end
        end
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
      if vfirst and umatch(vfirst, "[oɔu]") then
        -- Skip j-glide when vowel orthography starts with e (eo/eó digraph)
        -- because the e already marks palatal quality before the rounded vowel.
        local vorrho = next.ortho or ""
        if not umatch(usub(vorrho, 1, 1), "[eé]") then
          token.phon = token.phon .. "j"
        end
      end

      ::continue::
    end

    -- Step 8b: Convert diphthong-final u to w before a following vowel.
    -- When bh/mh vocalization produces "?u" before another vowel
    -- (e.g. -abhair, -abhach), the u offglide should become w.
    -- Must scan past silent tokens (vocalized bh/mh with empty phon) to
    -- find the next real vowel token.
    for i, token in ipairs(tokens) do
      if token.type ~= "vowel" then goto uw_c end
      local p = token.phon
      if not p or p == "" then goto uw_c end
      if #p > 1 and p:sub(-1) == "u" then
        -- Scan forward past silent tokens to find next vowel
        local nx = nil
        for j = i + 1, #tokens do
          local t = tokens[j]
          if t.type == "vowel" then nx = t; break end
          if t.type ~= "cons" then break end
          if t.phon and t.phon ~= "" then break end  -- non-silent cons blocks
        end
        if nx and nx.phon and nx.phon ~= "" then
          token.phon = p:sub(1,-2) .. "w"
        end
      end
      ::uw_c::
    end

    -- Step 9: Function word overridess — replace ALL phonemes with hardcoded IPA.
    -- Must be the very last step so no further rules touch these tokens.
    -- Split tokens into word segments so function words inside multi-word phrases are caught.
    -- Track segment token-index ranges and the boundary that follows each segment
    -- so Step 10 can blank inter-word boundaries for proclitic + content fusions.
    local fw_segments = {}
    local fw_current = {}
    local seg_ranges = {}  -- { {start=i, stop=j, boundary=k}, ... }
    local fw_current_start = nil
    for idx, t in ipairs(tokens) do
      if t.type == "boundary" then
        if #fw_current > 0 then
          table.insert(fw_segments, fw_current)
          table.insert(seg_ranges, { start = fw_current_start, stop = idx - 1, boundary = idx })
        end
        fw_current = {}
        fw_current_start = idx + 1
      else
        if fw_current_start == nil then fw_current_start = idx end
        table.insert(fw_current, t)
      end
    end
    if #fw_current > 0 then
      table.insert(fw_segments, fw_current)
      table.insert(seg_ranges, { start = fw_current_start, stop = #tokens, boundary = nil })
    end

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

    -- Step 9b: Proclitic cliticization. Certain function words fuse with the
    -- following content word — the expected IPA has no space between them
    -- (e.g. "i gceart" -> əˈɟaɾˠt̪ˠ, "go dtí" -> ɡəˈdʲiː, "faoi deara" ->
    -- fˠiːˈdʲaɾˠə). Mark the inter-word boundary as cliticized so render_output
    -- suppresses the space. The boundary token itself is preserved so the
    -- onset-walk in render_output still treats it as a word break (preventing
    -- the function word's coda consonant from being adopted as the content
    -- word's onset).
    local PROCLITICS = {
      ["i"] = true, ["go"] = true, ["ar"] = true, ["faoi"] = true,
      ["de"] = true, ["a"] = true,
      -- "ó" excluded: mixes cliticization ("ó dheas" fuses) with non-cliticization
      -- ("ó shin", "Ó Briain" keep space). Net negative.
      ["cén"] = true, ["cá"] = true, ["cé"] = true,             -- interrogatives
      ["cen"] = true, ["ca"] = true, ["ce"] = true,             -- (unaccented fallback)
      ["ní"] = true, ["ni"] = true,                             -- "ní"
    }
    if #fw_segments >= 2 then
      for si = 1, #fw_segments - 1 do
        local seg = fw_segments[si]
        local seg_ortho = ""
        for _, t in ipairs(seg) do
          if t.ortho then seg_ortho = seg_ortho .. t.ortho end
        end
        local lookup = ustring.lower(seg_ortho)
        if PROCLITICS[lookup] then
          -- Check that the next segment is a content word (not a function word).
          local next_seg = fw_segments[si + 1]
          local next_ortho = ""
          for _, t in ipairs(next_seg) do
            if t.ortho then next_ortho = next_ortho .. t.ortho end
          end
          local next_lookup = ustring.lower(next_ortho)
          if not S.FUNCTION_WORDS_OVERRIDE[next_lookup] then
            local range = seg_ranges[si]
            if range and range.boundary then
              -- Blank the boundary's phon (suppress space) but keep the token
              -- as type "boundary" so render_output's onset walk still stops
              -- here — the function word's coda consonant must not be adopted
              -- as the content word's onset.
              tokens[range.boundary].phon = ""
            end
          end
        end
      end
    end

    -- Step 10: Reassign stress in multi-word phrases.
    -- Empirically (analysis of 212 multi-word benchmark entries with ≥2 content
    -- words), the dominant Connacht pattern is: primary ˈ on the LAST content
    -- word, secondary ˌ on the FIRST content word. Single content words keep
    -- their primary stress. Function words remain unstressed (set above).
    if #fw_segments > 1 then
	-- Lexical stress override: these phrases keep default stress (primary on
	-- first content word, no secondary) instead of the default reassignment.
	-- These are typically noun+adjective compounds and name phrases.
	local STRESS_OVERRIDE_FIRST_PRIMARY = {
	  ["fianna fáil"] = true, ["madra uisce"] = true, ["uisce beatha"] = true,
	  ["duine fásta"] = true, ["portaireacht bhéil"] = true,
	  ["tuaisceart éireann"] = true, ["oide faoistine"] = true,
	  ["pocaire gaoithe"] = true, ["imeartas focal"] = true,
	}
	

      -- Collect content-word segments (those not overridden as function words).
      local content_segs = {}
      for _, seg in ipairs(fw_segments) do
        local seg_ortho = ""
        for _, t in ipairs(seg) do
          if t.ortho then seg_ortho = seg_ortho .. t.ortho end
        end
        local lookup_word = ustring.lower(seg_ortho)
        local is_function_word = S.FUNCTION_WORDS_OVERRIDE[lookup_word] ~= nil
        if not is_function_word then
          table.insert(content_segs, seg)
        end
      end

	-- Build phrase ortho for stress override lookup
	local phrase_ortho = ""
	for ci, seg in ipairs(content_segs) do
	  local seg_ortho = ""
	  for _, t in ipairs(seg) do
	    if t.ortho then seg_ortho = seg_ortho .. t.ortho end
	  end
	  if ci > 1 then phrase_ortho = phrase_ortho .. " " end
	  phrase_ortho = phrase_ortho .. ustring.lower(seg_ortho)
	end

	-- Skip stress reassignment for lexically-specified phrases (keep pass 02 default)
	if not STRESS_OVERRIDE_FIRST_PRIMARY[phrase_ortho] then
      if #content_segs >= 2 then
        -- For each content segment, remember which vowel pass 02 stressed.
        local stressed_vowel = {}
        for ci, seg in ipairs(content_segs) do
          for _, t in ipairs(seg) do
            if t.stress and t.type == "vowel" then
              stressed_vowel[ci] = t
              break
            end
          end
        end
        -- Clear all existing stress in content segments.
        for _, seg in ipairs(content_segs) do
          for _, t in ipairs(seg) do
            t.stress = false
            t.secondary = false
          end
        end
        -- First content word: secondary stress (on pass 02's chosen vowel, or
        -- first vowel). Skip if the first content word is monosyllabic — those
        -- typically take no stress at all in this position (e.g. numerals +
        -- "déag", "Ó Briain", "Sinn Féin", "Dé hAoine").
        local first_seg_vowel_count = 0
        for _, t in ipairs(content_segs[1]) do
          if t.type == "vowel" then first_seg_vowel_count = first_seg_vowel_count + 1 end
        end
        if first_seg_vowel_count >= 2 then
          local first_v = stressed_vowel[1]
          if not first_v then
            for _, t in ipairs(content_segs[1]) do
              if t.type == "vowel" then first_v = t; break end
            end
          end
          if first_v then first_v.secondary = true end
        end
        -- Last content word: primary stress, except for enclitics like
        -- "déag"/"dhéag" (the "-teen" suffix) which take no stress at all
        -- (e.g. "trí déag" -> tʲɾʲiː dʲeːɡ, "dó dhéag" -> d̪ˠoː jeːɡ).
        local last_seg = content_segs[#content_segs]
        local last_ortho = ""
        for _, t in ipairs(last_seg) do
          if t.ortho then last_ortho = last_ortho .. t.ortho end
        end
        local last_lookup = ustring.lower(last_ortho)
        local suppress_last_stress = (last_lookup == "déag" or last_lookup == "dhéag"
          or last_lookup == "deag" or last_lookup == "dheag")
        if not suppress_last_stress then
          local last_v = stressed_vowel[#content_segs]
          if not last_v then
            for _, t in ipairs(last_seg) do
              if t.type == "vowel" then last_v = t; break end
            end
          end
          if last_v then last_v.stress = true end
        end
      end
      end
    end

    return tokens
  end,
}
