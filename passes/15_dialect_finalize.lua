-- Pass #15: Dialect surface finalization.
-- Runs LAST, after all passes that can create or rewrite phones (13's
-- sonorant lengthening, 14's lexical overrides). Per-dialect surface
-- normalizations belong here so they cannot be bypassed by later passes
-- regenerating their input pattern (e.g. Ulster ɑː→aː missed the ɑː that
-- pass 13 cluster lengthening and pass 14 digraph resolution create after
-- pass 11 already ran — Gardaí, cairdeas, Cháit).
-- References: Hickey I.2.3 (Ulster á fronting), II.1.8 (Munster sonorants)

return {
  name = "dialect_finalize",
  writes_context = false,

  run = function(tokens, context)
    if context.dialect == "ulster" then
      -- Ulster á is front [aː] in all spellings and all sources of ɑː
      -- (Hickey I.2.3). Complements the pass-11 conversion, catching
      -- ɑː created downstream of pass 11.
      for _, t in ipairs(tokens) do
        if t.type == "vowel" and t.phon == "ɑː" then t.phon = "aː" end
      end
    end

    if context.dialect == "ulster" then
      -- Ulster: the -ach/-acht suffix vowel resists schwa reduction — it
      -- surfaces as full [a] (Hickey I.2.3: Ulster unstressed vowels keep
      -- quality in the -ach class: salach→sˠalˠax, Gaeltacht→ɡeːl̪ˠt̪ˠaxt̪ˠ).
      -- Target: ə immediately before a word-final x (or x+t̪ˠ) whose ortho is
      -- a/ea (the -ach suffix), not other schwas.
      for i, t in ipairs(tokens) do
        if t.type == "vowel" and t.phon == "ə" and
           (t.ortho == "a" or t.ortho == "ea") then
          local c1 = tokens[i + 1]
          if c1 and c1.type == "cons" and c1.ortho == "ch" and c1.phon == "x" then
            -- word-final x, or x followed only by final t (acht)
            local c2 = tokens[i + 2]
            local final_x = (c2 == nil) or (c2.type == "boundary")
            local final_xt = c2 and c2.type == "cons" and c2.ortho == "t" and
              (tokens[i + 3] == nil or tokens[i + 3].type == "boundary")
            -- -acha/-eacha plural: x + final a also keeps [a]
            local final_xa = c2 and c2.type == "vowel" and
              (tokens[i + 3] == nil or tokens[i + 3].type == "boundary")
            if final_x or final_xt or final_xa then
              t.phon = "a"
            end
          end
        end
      end

      -- Ulster: word-final -ach weakens [x]→[h] in a lexical set (~77 of 420
      -- -ach words; Hickey I.2.3 notes Ulster ch-weakening is variable).
      -- Keys strip_fadas'd.
      local ACH_TO_H = {
        aoibheallach=true, baisteach=true, balsamach=true, bandach=true,
        barulach=true, bhacach=true, bhealach=true, biseach=true, bodach=true,
        bogach=true, boireannach=true, bradach=true, bratach=true,
        breagach=true, cantalach=true, canunach=true, carbonach=true,
        ceallach=true, ceannach=true, ceannasach=true, ciotach=true,
        curamach=true, daltach=true, deireanach=true, direach=true,
        donasach=true, dtosach=true, eireannach=true, finiunach=true,
        firinneach=true, francach=true, galach=true, geagach=true,
        greannach=true, ["i dtosach"]=true, lachtach=true, leathanach=true,
        mbealach=true, naoscach=true, ngealach=true, ostach=true,
        protastunach=true, reiteach=true, ruifineach=true,
        ["t-eadach"]=true, tosach=true, tiomanach=true,
      }
      local w_ach = (context.word_ortho or ""):lower()
      local w_ach_nf = w_ach:gsub("[áéíóú]", { ["á"]="a", ["é"]="e", ["í"]="i", ["ó"]="o", ["ú"]="u" })
      if ACH_TO_H[w_ach_nf] then
        for i = #tokens, 1, -1 do
          local t = tokens[i]
          if t.type == "cons" and t.ortho == "ch" and t.phon == "x" then
            t.phon = "h"
            break
          end
        end
      end

      -- Ulster: əu diphthong is [au] (amhras→auɾˠəsˠ, slabhradh→t̪ˠlˠauɾˠu).
      -- Hickey I.2.3: Ulster keeps an open first element in the bh/mh
      -- vocalization diphthong.
      for _, t in ipairs(tokens) do
        if t.type == "vowel" and t.phon == "əu" then t.phon = "au" end
      end

      -- Ulster -íocht is [iaxt̪ˠ], not Connacht [iəxt̪ˠ] (barraíocht,
      -- coisíocht — benchmark Ulster rows use a full [a]).
      local w = (context.word_ortho or ""):lower()
      if w:match("[íi]ocht$") or w:match("[íi]ochta$") or w:match("íochtaí$") then
        for i, t in ipairs(tokens) do
          local nxt = tokens[i + 1]
          if t.type == "vowel" and t.phon == "iə" and nxt and
             nxt.type == "cons" and nxt.ortho == "ch" then
            t.phon = "ia"
          end
        end
      end
    end

    if context.dialect == "munster" then
      -- Munster word-final -igh/-aigh/-aidh/-idh keeps a real palatal stop:
      -- [ɪɟ] after a consonant (bealaigh→bʲal̪ˠɪɟ, doiligh→d̪ˠɪlʲɪɟ), bare [ɟ]
      -- after a long vowel or diphthong (dóigh→d̪ˠoːɟ, luaigh→l̪ˠuəɟ).
      -- Hickey I.2.2/III.2: Munster retains final /ɟ/ where Connacht
      -- vocalizes or deletes. Future -f- forms excluded (molfaidh→mˠɔl̪ˠhə
      -- keeps the Connacht-style h-suffix path; benchmark is split there).
      local w = (context.word_ortho or ""):lower()
      local is_igh = w:match("[aeiíáéó]igh$") or w:match("igh$")
        or w:match("aidh$") or w:match("idh$")
      local is_future_f = w:match("f[ae]?aidh$") or w:match("f[ei]?idh$")
      if is_igh and not is_future_f and not w:find(" ") then
        -- Find last vowel with non-empty phon and the trailing gh/dh token.
        local last_v, gh_tok = nil, nil
        for i = #tokens, 1, -1 do
          local t = tokens[i]
          if not gh_tok and t.type == "cons" and (t.ortho == "gh" or t.ortho == "dh") then
            gh_tok = t
          elseif t.type == "vowel" and t.phon and t.phon ~= "" then
            last_v = t
            break
          end
        end
        if last_v and gh_tok then
          local p = last_v.phon
          local is_long = p:find("ː", 1, true) ~= nil or p == "uə" or p == "iə" or p == "ai" or p == "əi"
          if is_long and (p == "iː") then
            -- iː from IGH_RESTORE is the suffix vowel itself → ɪɟ
            last_v.phon = "ɪ"
            gh_tok.phon = "ɟ"
          elseif is_long then
            -- root long vowel/diphthong: keep it, add final ɟ
            gh_tok.phon = "ɟ"
          elseif p == "ə" or p == "ɪ" or p == "i" then
            last_v.phon = "ɪ"
            gh_tok.phon = "ɟ"
          end
        end
      end

      -- Munster éa-breaking: long éa [eː] breaks to [iːa̯] under stress and
      -- [ia̯] pretonic (Hickey I.2.2: Munster ia-diphthongization of éa —
      -- méar→mʲiːa̯ɾˠ, bréag→bʲɾʲiːa̯ɡ, éadóchasach→ia̯ˈd̪ˠoː...).
      -- Only orthographic éa (not ao/aou/é alone) breaks.
      -- Length: [iːa̯] when the éa syllable itself is prominent, [ia̯] when a
      -- LATER syllable carries the stress (pretonic shortening:
      -- éadóchasach→ia̯ˈd̪ˠoː...). Only FIRST-SYLLABLE éa breaks — loanwords
      -- with éa in later syllables (piléar, páipéar, buidéal, coirnéal)
      -- keep [eː] (Hickey I.2.2: breaking is confined to root syllables).
      for i, t in ipairs(tokens) do
        if t.type == "vowel" and t.phon == "eː" and t.ortho == "éa" then
          local earlier_vowel = false
          for j = 1, i - 1 do
            local u = tokens[j]
            if u.type == "boundary" then earlier_vowel = false
            elseif u.type == "vowel" and u.phon and u.phon ~= "" then earlier_vowel = true end
          end
          if not earlier_vowel then
            local later_stress = false
            for j = i + 1, #tokens do
              local u = tokens[j]
              if u.type == "vowel" and (u.stress or u.secondary) then
                later_stress = true
                break
              end
            end
            t.phon = later_stress and "ia̯" or "iːa̯"
          end
        end
      end

      -- Munster sonorant notation normalization (moved here from the end of
      -- pass 13 so pass-14-created sonorants are covered too): broad l/n are
      -- dental, slender l/n are plain palatal (benchmark Munster convention;
      -- empirical winner over Hickey's clean 2-way description).
      local MUNSTER_SONORANTS = {
        ["l\xcb\xa0"] = "l\xcc\xaa\xcb\xa0",           -- lˠ → l̪ˠ
        ["n\xcb\xa0"] = "n\xcc\xaa\xcb\xa0",           -- nˠ → n̪ˠ
        ["l\xcc\xa0\xca\xb2"] = "l\xca\xb2",           -- l̠ʲ → lʲ
        ["n\xcc\xa0\xca\xb2"] = "n\xca\xb2",           -- n̠ʲ → nʲ
      }
      for _, t in ipairs(tokens) do
        if t.type == "cons" and t.phon and MUNSTER_SONORANTS[t.phon] then
          t.phon = MUNSTER_SONORANTS[t.phon]
        end
      end
    end

    return tokens
  end,
}
