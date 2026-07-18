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

    if context.dialect == "munster" then
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
