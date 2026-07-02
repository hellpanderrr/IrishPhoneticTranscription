-- Pass #2: Calculate primary stress position.
-- Also computes is_monosyllabic, vowel_count, root_vowel_count.
-- Runs early so vocalization (pass #6) and reduction (pass #11) are stress-aware.
-- References: Hickey II.3 (stress), FG Ch.5 (Connacht stress patterns)

local S = require("passes._shared")

return {
  name = "stress",
  writes_context = true,

  run = function(tokens, context)
    local vowel_count = S.count_syllables(tokens)
    context.vowel_count = vowel_count
    if vowel_count == 0 then return tokens end

    -- Split tokens into word segments at space/apostrophe boundaries
    local segments = {}
    local current = {}
    for _, t in ipairs(tokens) do
      if t.type == "boundary" then
        if #current > 0 then table.insert(segments, current) end
        current = {}
      else
        table.insert(current, t)
      end
    end
    if #current > 0 then table.insert(segments, current) end
    if #segments == 0 then return tokens end

    local UNSTRESSED = {
      -- Hickey II.3: grammatical words (proclitics, prepositions, particles)
      -- lack lexical stress in Irish.
      ["'un"]=true,["un"]=true,["'ur"]=true,["ur"]=true,["-as"]=true,["-sa"]=true,
      ["-se"]=true,["-ne"]=true,["-na"]=true,["-im"]=true,["-fas"]=true,["-fá"]=true,
      ["-fí"]=true,["-tá"]=true,["-ím"]=true,bhur=true,["-óidh"]=true,["-ithe"]=true,
      ["-aimid"]=true,["-aíonn"]=true,["-idís"]=true,["-aigh"]=true,["-igh"]=true,
      ["-ach"]=true,["-san"]=true,["-sean"]=true,["-eog"]=true,["-ín"]=true,["-óg"]=true,
      ["-ál"]=true,["-úil"]=true,["-tacht"]=true,["-acht"]=true,["-áil"]=true,
      ["-eáil"]=true,["-ail"]=true,["-eal"]=true,["-ógra"]=true,["-úint"]=true,
      ["-aint"]=true,a=true,["a'"]=true,["a-"]=true,["ab"]=true,ach=true,["ad"]=true,
      ["ag"]=true,["an"]=true,["ar"]=true,["as"]=true,["ba"]=true,["bh"]=true,["bhf"]=true,
      ["am"]=true,["ch"]=true,de=true,["do"]=true,["dh"]=true,["dh'"]=true,["go"]=true,["gh"]=true,
      ["i"]=true,["is"]=true,["le"]=true,["mar"]=true,["mh"]=true,["ní"]=true,
      ["níl"]=true,["os"]=true,["ó"]=true,["ph"]=true,["na"]=true,["sa"]=true,["se"]=true,["sh"]=true,
      ["th"]=true,["th'"]=true,["um"]=true,
      -- Prepositional pronouns (should not carry lexical stress)
      agam=true,agat=true,againn=true,agaibh=true,acu=true,
      dom=true,duit=true,["dúinn"]=true,daoibh=true,["dóibh"]=true,
      liom=true,leat=true,linn=true,libh=true,leo=true,
      orm=true,ort=true,orainn=true,oraibh=true,orthu=true,
      ["fúm"]=true,["fút"]=true,["fúinn"]=true,["fúibh"]=true,["fúthu"]=true,
      chugam=true,chugat=true,chugainn=true,chugaibh=true,chuige=true,
      uaim=true,uait=true,uainn=true,uaibh=true,uathu=true,
      ["faoi"]=true,["fearacht"]=true,["trí"]=true,["trína"]=true,
    }

    -- Process each word segment independently.
    local seg_is_monosyllabic = false
    local seg_root_vowel_count = 0
    for _, seg in ipairs(segments) do
      -- Build ortho for this segment for UNSTRESSED check
      local ortho = ""
      for _, t in ipairs(seg) do
        if t.ortho and t.ortho ~= "" then ortho = ortho .. t.ortho end
      end

      local seg_vc = S.count_syllables(seg)

      if UNSTRESSED[ortho] then
        if seg_vc == 1 then seg_is_monosyllabic = true end
        goto next_seg
      end

      if seg_vc <= 1 then
        if #segments > 1 then
          for _, t in ipairs(seg) do
            if t.type == "vowel" then
              t.stress = true
              break
            end
          end
        end
        if #segments == 1 then seg_is_monosyllabic = true end
        goto next_seg
      end

      -- Prefix check for this segment
      -- Hickey II.3: prefixes do not attract stress; root-initial stress dominates
      local has_prefix = false
      if seg_vc >= 2 and seg[1].type == "cons" and seg[2] and
         (seg[2].type == "vowel" or seg[2].type == "cons") then
        local key = seg[1].ortho .. seg[2].ortho
        if S.KNOWN_PREFIXES[key] then has_prefix = true end
      end

      -- Find stress position
      -- Hickey II.3: lexical stress falls on first syllable of the root in
      -- Connacht/Ulster (Munster differs — stress attracted to long vowels)
      local stress_index = S.vowel_token_index(seg)
      if not stress_index then goto next_seg end

      -- Stress stays on the vowel. render_output moves the stress mark to the
      -- onset consonant for IPA rendering. Shifting to consonant here
      -- causes incorrect vowel reduction (unstressed vowels get reduced to ə).
      -- ae digraph: stress on a (vowel), not e (vowel)
      if seg[stress_index].ortho == "e" and stress_index > 1 and
             seg[stress_index - 1].type == "vowel" and
             seg[stress_index - 1].ortho == "a" then
        stress_index = stress_index - 1
      end

      -- Mark stress in the original tokens array
      local found = 0
      for _, orig_t in ipairs(tokens) do
        if orig_t == seg[stress_index] then
          orig_t.stress = true
          break
        end
      end

      -- Compute root_vowel_count for the first segment
      if #segments == 1 and has_prefix then
        local in_prefix = true
        for _, t in ipairs(seg) do
          if in_prefix and t.type == "cons" then
            -- still in prefix
          elseif in_prefix then
            in_prefix = false
            if t.type == "vowel" then seg_root_vowel_count = seg_root_vowel_count + 1 end
          elseif t.type == "vowel" then
            seg_root_vowel_count = seg_root_vowel_count + 1
          end
        end
        if seg_root_vowel_count <= 1 then seg_is_monosyllabic = true end
      end

      ::next_seg::
    end

    context.is_monosyllabic = seg_is_monosyllabic
    return tokens
  end,
}
