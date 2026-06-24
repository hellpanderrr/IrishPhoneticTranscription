# Theory-Grounded Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the gap between the token-array engine and the phonological theory from Hickey (2014) and Ó Raghallaigh (2013) by adding missing passes and fixing existing ones.

**Architecture:** Each gap maps to a specific pass in the 15-pass pipeline. Some require new passes (vowel_gradation, r_lowering, anticipatory_raising, labial_vocalization), others are fixes within existing passes. The dialect tables in `passes/_shared.lua` need expansion for all three dialects.

**Tech Stack:** Lua 5.4, ustring library (UTF-8), `irish_engine_new.lua` orchestrator, 15 passes in `passes/`.

---

## Baseline Metrics

```
regression_sample 104-word set: avg Lev 3.95, avg Dolgo 0.516
New engine better than monolith on:  40/104
Monolith better than new engine on:  46/104
Tied:                                18/104
```

Key theory-testable words and their current (broken) output:
```
cnoc:     kɾˠɔk  (expected: no gradation) — OK
tirim:    tʲˈɪɾʲɪmʲ  (expected: tʲˈɛɾʲɪmʲ) — R-lowering missing
colaiste: kˈɔlˠaiʃtʲɛ  (expected: kʊlˠaːʃtʲə) — anticipatory raising missing
marbh:    mˠaɾˠw  (expected: mˠaɾˠuː) — labial vocalization missing
bocht:    bˠɔxt̪ˠ  (expected: bˠʌxt̪ˠ) — /x/ non-assimilation needs work
trom:     t̪ˠɾˠɔmˠ  (expected: t̪ˠɾˠuːmˠ) — nasal raising missing before m
peann:    pʲanʲnʲ  (expected: pʲaːnˠ) — sonorant lengthening broken
peanna:   pʲˈan̪ˠn̪ˠa  (expected: pʲan̪ˠə) — nn tokenization broken
```

---

## Files to Modify/Create

### New Pass Files
- `passes/06b_vowel_gradation.lua` — Short vowel umlaut shifts based on coda polarity
- `passes/06c_r_lowering.lua` — /ɪ/, /e/ → [ɛ] before slender /ɾʲ/
- `passes/06d_anticipatory_raising.lua` — Short vowel raises before second-syllable [aː] (West)
- `passes/06e_labial_vocalization.lua` — /v/ → [uː] after short back vowel in final position

### Modified Files
- `passes/init.lua` — Add new passes to pipeline ordering
- `passes/10_vowels.lua` — Fix `token.phon == ortho` guard, add /x/ non-assimilation, expand dialect maps, fix a→ɛ rule, add R-lowering, add vowel gradation
- `passes/12_epenthesis.lua` — Add heterorganic condition check, voiced fricative inclusion
- `passes/13_sonorants.lua` — Fix sonorant lengthening suffix/compound distinction, add dialect-specific diphthongization
- `passes/14_final_cleanup.lua` — Add /rʲ/ assibilation, /oːgʲ/ palatal anomaly, verbal adjective suffix override
- `passes/03_eclipsis.lua` — Expand eclipsis map with standard spellings
- `passes/_shared.lua` — Expand DIALECTS table with full dialect data

---

### Task 1: Expand DIALECTS Table with Theory Data

**Files:**
- Modify: `passes/_shared.lua:36-58` (DIALECTS table)

**Description:** The current DIALECTS table only has `ao`, `ai`, `ea`, `eo`, `ío` mappings. Need to add full vowel tables per dialect from Hickey and Ó Raghallaigh:

| Vowel | Connacht | Ulster | Munster |
|-------|----------|--------|---------|
| a (short, broad coda) | a | a | a |
| a (short, slen coda) | a | a | a |
| a (long) | aː | æː | ɑː |
| e (short) | ɛ | ɛ | ɛ |
| e (long) | eː | eː | eː |
| i (short) | ɪ | ɪ | ɪ |
| i (long) | iː | iː | iː |
| o (short) | ɔ | ʌ~ɔ | ɔ |
| o (long) | oː | ɔː | oː |
| u (short) | ʊ | ʊ | ʊ |
| u (long) | uː | ʉː | uː |
| ao | iː | iː | eː |
| ea | a | a | a |
| eo | oː | ɔː | oː |
| ai | ai | ai | ai |
| oi | ɔi | ʌi | ɔi |
| ui | ʊi | ʊi | ʊi |
| au | au | au | əu |
| ia | iə | ia | iə |
| ua | uə | ua | uə |

- [ ] **Read current DIALECTS table**

```lua
local DIALECTS = {
    connacht = {
        ao = "eː",
        ai = "ai",
        ea = "a",
        eo = "oː",
        ["ío"] = "iː",
    },
    ...
}
```

- [ ] **Replace with full table** in `passes/_shared.lua`

```lua
_shared.DIALECTS = {
    connacht = {
        ao = "iː", ai = "ai", ea = "a", eo = "oː",
        ["ío"] = "iː", ["ia"] = "iə", ["ua"] = "uə",
        ["á"] = "aː", ["é"] = "eː", ["í"] = "iː",
        ["ó"] = "oː", ["ú"] = "uː",
        short = { a = "a", e = "ɛ", i = "ɪ", o = "ɔ", u = "ʊ" },
        long  = { a = "aː", e = "eː", i = "iː", o = "oː", u = "uː" },
        diphthongs = { ai = "ai", oi = "ɔi", ui = "ʊi", au = "au", ia = "iə", ua = "uə" },
        vowel_gradation = {
            -- coda polarity shifts short vowels:
            o = { broad = "ɔ", slender = "ɪ" },  -- cnoc -> cnoic
            a = { broad = "a", slender = "ɛ" },   -- glas -> glais [glˠɛʃ]
            u = { broad = "ʊ", slender = "ɪ" },
            e = { broad = "ɛ", slender = "ɪ" },
        },
        r_lowering_trigger = true,
        anticipatory_raising = true,
    },
    munster = {
        ao = "eː", ai = "ai", ea = "a", eo = "oː",
        ["ío"] = "iː", ["ia"] = "iə", ["ua"] = "uə",
        ["á"] = "ɑː", ["é"] = "eː", ["í"] = "iː",
        ["ó"] = "oː", ["ú"] = "uː",
        short = { a = "a", e = "ɛ", i = "ɪ", o = "ɔ", u = "ʊ" },
        long  = { a = "ɑː", e = "eː", i = "iː", o = "oː", u = "uː" },
        diphthongs = { ai = "ai", oi = "ɔi", ui = "ʊi", au = "əu", ia = "iə", ua = "uə" },
        vowel_gradation = {
            o = { broad = "ɔ", slender = "ɪ" },
            a = { broad = "a", slender = "ɛ" },
            u = { broad = "ʊ", slender = "ɪ" },
            e = { broad = "ɛ", slender = "ɪ" },
        },
        r_lowering_trigger = true,
        anticipatory_raising = false,
    },
    ulster = {
        ao = "iː", ai = "ai", ea = "a", eo = "ɔː",
        ["ío"] = "iː", ["ia"] = "ia", ["ua"] = "ua",
        ["á"] = "æː", ["é"] = "eː", ["í"] = "iː",
        ["ó"] = "ɔː", ["ú"] = "ʉː",
        short = { a = "a", e = "ɛ", i = "ɪ", o = "ʌ", u = "ʊ" },
        long  = { a = "æː", e = "eː", i = "iː", o = "ɔː", u = "ʉː" },
        diphthongs = { ai = "ai", oi = "ʌi", ui = "ʊi", au = "au", ia = "ia", ua = "ua" },
        vowel_gradation = {
            o = { broad = "ʌ", slender = "ɪ" },
            a = { broad = "a", slender = "ɛ" },
            u = { broad = "ʊ", slender = "ɪ" },
            e = { broad = "ɛ", slender = "ɪ" },
        },
        r_lowering_trigger = true,
        anticipatory_raising = false,
    },
}
```

- [ ] **Verify the pass still loads and runs**

Run: `F:/soft/lua/lua.exe -e "local e = require('irish_engine_new'); print(e.transcribe('glas'))"`

Expected: `ɡlˠasˠ`

- [ ] **Commit**

```bash
git add passes/_shared.lua
git commit -m "feat: expand DIALECTS table with theory-grounded vowel data per dialect"
```

---

### Task 2: Fix `token.phon == ortho` Guard in Vowel Resolver

**Files:**
- Modify: `passes/10_vowels.lua:23,48,64,70`

**Description:** The current guard `if token.phon == ortho or token.phon == nil or token.phon == "" then` incorrectly treats vowels whose default phon equals their ortho (like `a` → `a`) as "already modified" and skips contextual rules. The fix: track whether a vowel was modified by prefixing passes using a `modified` key on the token, rather than comparing phon to ortho.

- [ ] **Add a `modified` flag to make_token in `_shared.lua`**

The flag doesn't need to be in make_token (all tokens start unmodified). Instead, check for phon == ortho BUT also handle the case where phon is the same string as ortho.

Fix in `passes/10_vowels.lua`:

```lua
-- New guard: check if any earlier pass explicitly set this vowel
-- phon == ortho means "not yet resolved" (default init state)
-- But some vowels like 'a' have ortho=='a' AND default phon='a',
-- so we need a separate check for those
local function needs_resolution(token)
    if token.is_epenthetic then return false end
    -- Default phon is always set to ortho at tokenization
    -- Passes that modify phon set it to something different from ortho
    -- UNLESS the phon happens to equal ortho (rare: 'a'→'a')
    -- Check source field: if source ~= "lexeme", it was modified
    if token.source ~= "lexeme" then
        return false -- Already modified by an earlier pass
    end
    -- If phon != ortho, check if it was set by an earlier pass
    if token.phon ~= token.ortho then
        -- Check if this phon was set by us (equal to default mapping)
        -- Simple heuristic: if phon == ortho, it hasn't been resolved
        return phon == ortho
    end
    return true -- ortho == phon, hasn't been resolved
end
```

Actually, simpler approach — just remove the guard since the vowel pass runs after all modification passes anyway:

Replace the block at line 22-45 from:
```lua
-- Only apply default mapping if not already modified by an earlier pass
if token.phon == ortho or token.phon == nil or token.phon == "" then
    if next and next.type == "cons" and next.ortho == "dh" and
       (ortho == "a" or ortho == "ai" or ortho == "á" or ortho == "aí") then
      if ortho == "aí" then token.phon = "ɑːiː"
      else token.phon = "ɑː" end
    elseif ortho == "aoi" then token.phon = "iː"
    ...
    end
end
```

To:
```lua
-- Apply default mapping only if vowel hasn't been modified by earlier passes
-- Vocalization (pass #6) sets phon != ortho for vocalized vowels
-- Nasalization (pass #7) sets phon != ortho for nasal-raised vowels
-- We check: phon must equal ortho (unresolved) or be nil/empty
if token.phon == ortho or token.phon == nil or token.phon == "" then
    -- Don't overwrite if phon was explicitly set to the same string
    -- This catches the a→a case where pass-through == intentional
    if ortho ~= "a" or token.source == "lexeme" then
        -- ...existing resolution logic...
    end
end
```

Actually, the cleanest fix: remove the guard entirely for `a` (since `a→a` is the only case where phon==ortho triggers a false positive) and let the resolution proceed. The contextual rules (lines 74-103) always re-check and override if needed.

- [ ] **Apply the fix**

```lua
-- Replace lines 22-45:
-- Only apply default mapping if not already modified by an earlier pass
-- phon == ortho means unmodified; this is true for most vowels
-- EXCEPT 'a' where default phon 'a' == ortho 'a' — we need to resolve it anyway
local default_phon_set = token.phon ~= token.ortho
if ortho == "a" and token.phon == "a" then
    default_phon_set = false -- was set by us, not an earlier pass
end

if not default_phon_set then
    if next and next.type == "cons" and next.ortho == "dh" and
       (ortho == "a" or ortho == "ai" or ortho == "á" or ortho == "aí") then
      if ortho == "aí" then token.phon = "ɑːiː"
      else token.phon = "ɑː" end
    elseif ortho == "aoi" then token.phon = "iː"
    elseif ortho == "ao" then token.phon = dialect_values.ao
    elseif ortho == "eo" then token.phon = dialect_values.eo
    elseif ortho == "ea" then token.phon = dialect_values.ea
    elseif ortho == "ae" then token.phon = "eː"
    elseif ortho == "aí" or ortho == "ái" then token.phon = "ɑː"
    elseif ortho == "óí" or ortho == "ó" then token.phon = dialect_values["ó"]
    elseif ortho == "ú" then token.phon = dialect_values["ú"]
    elseif ortho == "í" then token.phon = dialect_values["í"]
    elseif ortho == "é" then token.phon = dialect_values["é"]
    elseif ortho == "á" then token.phon = dialect_values["á"]
    elseif ortho == "o" then token.phon = dialect_values.short.o
    elseif ortho == "u" then token.phon = dialect_values.short.u
    elseif ortho == "i" then token.phon = dialect_values.short.i
    elseif ortho == "e" then token.phon = dialect_values.short.e
    elseif ortho == "a" then token.phon = dialect_values.short.a
    end
end
```

Also update lines 47-60 (nasal raising guard) the same way:
```lua
local is_unmodified = token.phon == ortho or token.phon == nil or token.phon == ""
if ortho == "a" and token.phon == "a" then is_unmodified = true end
```

And lines 62-67 (broad o default):
```lua
if ortho == "o" and next and next.type == "cons" and next.palatal == false then
    -- Only set o→ɔ if not already modified by nasal raising (which sets o→uː)
    if token.phon == ortho or (ortho == "o" and token.phon == "ɔ") then
        token.phon = "ɔ"
    end
end
```

- [ ] **Run validation**

Run: `F:/soft/lua/lua.exe validate_extraction.lua` (or inline test)

Expected: Words with `a` don't regress. `alt` stays `ɛlˠt̪ˠ`.

- [ ] **Commit**

```bash
git add passes/10_vowels.lua
git commit -m "fix: improve vowel resolver guard to handle a→a false positive"
```

---

### Task 3: Add Vowel Gradation (Umlaut) Pass

**Files:**
- Create: `passes/06b_vowel_gradation.lua`
- Modify: `passes/init.lua` (add pass to pipeline after 06_vocalization)

**Description:** Short vowels shift quality based on the polarity of the coda consonant. This is the most important missing rule from Hickey Ch.2. When the following consonant is slender (palatal), short back vowels front/raise:
- `o` (broad) → `ɔ` stays; `o` (slender coda) → `ɪ`
- `a` (broad) → `a`; `a` (slender coda) → `ɪ` (i-affection) OR `ɛ` before certain clusters
- `u` (broad) → `ʊ`; `u` (slender coda) → `ɪ`

The rule vs the `ai` digraph: `ai` is orthographic (a+i) but often pronounced as a single vowel `a` with a slender trace on the following consonant. The vowel gradation pass should handle cases where the orthography writes `ai` but the phonology requires just a vowel quality shift.

This pass runs AFTER vocalization (which resolves fricative-vowel sequences) but BEFORE nasalization and consonant resolution. It needs to know consonant polarity (set by pass #1).

- [ ] **Create `passes/06b_vowel_gradation.lua`**

```lua
-- Pass #6b: Vowel gradation (Umlaut).
-- Short vowels shift quality based on the polarity of the FOLLOWING consonant.
-- This implements Hickey's "vowel gradation" / affection rule:
--   back vowel + slender coda → fronted/raised short vowel
--   o→ɪ, a→ɪ/ɛ, u→ɪ before slender consonants
--
-- Runs after vocalization (#6) but before nasalization (#7).

local S = require("passes._shared")

return {
  name = "vowel_gradation",
  writes_context = false,

  run = function(tokens, context)
    local dv = S.DIALECTS[context.dialect] or S.DIALECTS.connacht
    local gradation = dv.vowel_gradation

    for i, token in ipairs(tokens) do
      if token.type ~= "vowel" then goto continue end
      if token.is_epenthetic then goto continue end

      local next_t = tokens[i + 1]
      if not next_t or next_t.type ~= "cons" then goto continue end
      if not next_t.palatal then goto continue end  -- not slender, no gradation

      -- Only apply to unmodified vowels
      if token.phon ~= token.ortho then goto continue end

      local ortho = token.ortho
      -- Map to graded vowel based on dialect
      if gradation[ortho] then
        token.phon = gradation[ortho].slender
        token.source = "vowel_gradation"
      end

      ::continue::
    end
    return tokens
  end,
}
```

- [ ] **Update `passes/init.lua` to include the new pass**

Insert after pass #6 (vocalization), before pass #7 (nasalization):
```lua
passes[1] = require("passes.01_polarity")
passes[2] = require("passes.02_stress")
passes[3] = require("passes.03_eclipsis")
passes[4] = require("passes.04_cluster_simplify")
passes[5] = require("passes.05_mutated_fricatives")
passes[6] = require("passes.06_vocalization")
passes[6.5] = require("passes.06b_vowel_gradation")  -- NEW
passes[7] = require("passes.07_nasalization")
-- ... rest stays the same
```

Note: Lua table indices are integers. Renumber passes 7-15 to 8-16:
```lua
passes[1] = require("passes.01_polarity")
passes[2] = require("passes.02_stress")
passes[3] = require("passes.03_eclipsis")
passes[4] = require("passes.04_cluster_simplify")
passes[5] = require("passes.05_mutated_fricatives")
passes[6] = require("passes.06_vocalization")
passes[7] = require("passes.06b_vowel_gradation") -- NEW
passes[8] = require("passes.07_nasalization")
passes[9] = require("passes.08_slender_coda")
passes[10] = require("passes.09_consonants")
passes[11] = require("passes.09b_vowel_adjunct")
passes[12] = require("passes.10_vowels")
passes[13] = require("passes.11_unstressed_reduction")
passes[14] = require("passes.12_epenthesis")
passes[15] = require("passes.13_sonorants")
passes[16] = require("passes.14_final_cleanup")

local function run_all(tokens, context)
  for i = 1, 16 do
    tokens = passes[i].run(tokens, context)
  end
  return tokens
end
```

- [ ] **Test vowel gradation effect**

Run: `F:/soft/lua/lua.exe -e "local e = require('irish_engine_new'); print('glais: '..e.transcribe('glais')); print('cnoc: '..e.transcribe('cnoc'))"`

Expected: `glais` should show the slender trace affecting vowel quality (ai→ɛ or similar depending on dialect).

- [ ] **Commit**

```bash
git add passes/06b_vowel_gradation.lua passes/init.lua
git commit -m "feat: add vowel gradation pass for umlaut effects (Hickey Ch.2)"
```

---

### Task 4: Add R-Lowering Pass

**Files:**
- Create: `passes/06c_r_lowering.lua`
- Modify: `passes/init.lua` (add to pipeline)

**Description:** Hickey: `/ɪ/` and `/e/` lower to [ɛ] before slender /ɾʲ/. This is a neighbor-effect rule that runs after vowel gradation but before nasalization.

- [ ] **Create `passes/06c_r_lowering.lua`**

```lua
-- Pass #6c: R-lowering.
-- /ɪ/, /e/ → [ɛ] before slender /ɾʲ/ (Hickey Ch.2).
-- tirim → tʲˈɛɾʲɪmʲ, not *tʲˈɪɾʲɪmʲ
-- Runs after vowel gradation (#6b).

local S = require("passes._shared")

return {
  name = "r_lowering",
  writes_context = false,

  run = function(tokens, context)
    local dv = S.DIALECTS[context.dialect] or S.DIALECTS.connacht
    if not dv.r_lowering_trigger then return tokens end

    for i, token in ipairs(tokens) do
      if token.type ~= "vowel" then goto continue end
      local next_t = tokens[i + 1]
      if not next_t or next_t.type ~= "cons" then goto continue end
      if next_t.ortho ~= "r" or next_t.palatal ~= true then goto continue end

      -- Apply to /ɪ/ and /e/ regardless of whether they were modified
      if token.phon == "ɪ" then
        token.phon = "ɛ"
        token.source = "r_lowering"
      elseif token.phon == "e" or token.phon == "ɛ" then
        -- Already ɛ or e, keep as ɛ
        token.phon = "ɛ"
      end

      ::continue::
    end
    return tokens
  end,
}
```

- [ ] **Update `passes/init.lua`**, inserting after vowel_gradation (#7), shifting rest:

```lua
passes[7] = require("passes.06b_vowel_gradation")
passes[8] = require("passes.06c_r_lowering") -- NEW
passes[9] = require("passes.07_nasalization")
-- Renumber rest... (up to passes[17] = final_cleanup)
```

- [ ] **Test R-lowering**

Run: `F:/soft/lua/lua.exe -e "local e = require('irish_engine_new'); print('tirim: '..e.transcribe('tirim'))"`

Expected: `tʲˈɛɾʲɪmʲ` (not `tʲˈɪɾʲɪmʲ`)

- [ ] **Commit**

```bash
git add passes/06c_r_lowering.lua passes/init.lua
git commit -m "feat: add R-lowering pass for /ɪ, e/→ɛ before slender r (Hickey)"
```

---

### Task 5: Add Anticipatory Vowel Raising Pass

**Files:**
- Create: `passes/06d_anticipatory_raising.lua`
- Modify: `passes/init.lua` (add to pipeline)

**Description:** Western Irish: short /a/ or /o/ in the first syllable raises to [ʊ] or [ɪ] if the second syllable contains a long [aː]: `colaiste` → [kʊlˠaːʃtʲə], `caislean` → [kɪʃlʲaːnˠ]. This is a Western-specific rule (not Ulster, not Munster).

- [ ] **Create `passes/06d_anticipatory_raising.lua`**

```lua
-- Pass #6d: Anticipatory vowel raising (Western).
-- Short /a/ or /o/ in first syllable raises to [ʊ]/[ɪ] before
-- second-syllable long [aː] (Hickey Ch.2).
-- coláiste → kʊlˠaːʃtʲə, caisleán → kɪʃlʲaːnˠ
-- Only applies in Connacht.
-- Runs after R-lowering (#6c).

local S = require("passes._shared")

local function has_following_long_a(vowels, start_idx)
  -- Scan forward from start_idx to find a long aː
  for i = start_idx + 1, #vowels do
    local v = vowels[i]
    if v.type == "vowel" then
      if v.phon and (v.phon == "aː" or v.phon == "ɑː") then
        return true
      end
    end
  end
  return false
end

return {
  name = "anticipatory_raising",
  writes_context = false,

  run = function(tokens, context)
    local dv = S.DIALECTS[context.dialect] or S.DIALECTS.connacht
    if not dv.anticipatory_raising then return tokens end

    -- Only applies to polysyllabic words
    if context.vowel_count and context.vowel_count < 2 then return tokens end

    for i, token in ipairs(tokens) do
      if token.type ~= "vowel" then goto continue end
      if token.phon ~= token.ortho then goto continue end -- already modified
      if token.stress then goto continue end -- stress not relevant for this rule

      local ortho = token.ortho
      if ortho ~= "a" and ortho ~= "o" then goto continue end

      -- Check if this vowel is in the first syllable and followed by a long a
      if has_following_long_a(tokens, i) then
        if ortho == "a" then
          token.phon = "ɪ"
        elseif ortho == "o" then
          token.phon = "ʊ"
        end
        token.source = "anticipatory_raising"
      end

      ::continue::
    end
    return tokens
  end,
}
```

- [ ] **Update `passes/init.lua`**

Insert after R-lowering (#8):

```lua
passes[8] = require("passes.06c_r_lowering")
passes[9] = require("passes.06d_anticipatory_raising") -- NEW
passes[10] = require("passes.07_nasalization")
-- Renumber rest... (up to passes[18] = final_cleanup)
```

- [ ] **Test**

Run: `F:/soft/lua/lua.exe -e "local e = require('irish_engine_new'); print('colaiste: '..e.transcribe('coláiste'))"`

Expected: `kʊlˠaːʃtʲə` or reasonable approximation

- [ ] **Commit**

```bash
git add passes/06d_anticipatory_raising.lua passes/init.lua
git commit -m "feat: add anticipatory vowel raising pass (Western Irish, Hickey)"
```

---

### Task 6: Add Labial Fricative Vocalization Pass

**Files:**
- Create: `passes/06e_labial_vocalization.lua`
- Modify: `passes/init.lua` (add to pipeline)

**Description:** When broad /v/ (from bh/mh) follows a short central/back vowel (/ʌ/, /ə/, /a/) in unstressed or final position, it becomes long [uː]. `marbh` → [mˠaɾˠuː], `garbh` → [gˠaɾˠuː]. The existing vocalization pass handles the vowel-side of fricative+vowel interactions but misses this word-final full-vocalization-to-uː case.

- [ ] **Create `passes/06e_labial_vocalization.lua`**

```lua
-- Pass #6e: Labial fricative vocalization.
-- When broad /v/ (from bh/mh) follows short central/back vowel
-- in final unstressed position, it becomes long [uː].
-- marbh → mˠaɾˠuː, tarbh → t̪ˠaɾˠuː
-- Runs after anticipatory raising (#6d), before nasalization (#7).

local S = require("passes._shared")

return {
  name = "labial_vocalization",
  writes_context = false,

  run = function(tokens, context)
    for i = 1, #tokens - 1 do
      local vowel = tokens[i]
      local cons = tokens[i + 1]
      if vowel.type ~= "vowel" or cons.type ~= "cons" then goto continue end
      if cons.ortho ~= "bh" and cons.ortho ~= "mh" then goto continue end

      -- Only when the fricative is broad (non-palatal)
      if cons.palatal ~= false then goto continue end

      -- Only when this is word-final (no further content after this token)
      local is_final = true
      for j = i + 2, #tokens do
        if tokens[j].phon and tokens[j].phon ~= "" then
          is_final = false; break
        end
      end
      if not is_final then goto continue end

      -- Only when the vowel is short and central/back
      -- (a, o, u and their unmodified forms)
      if vowel.phon == vowel.ortho or vowel.phon == nil then
        local ortho = vowel.ortho
        if ortho == "a" or ortho == "o" or ortho == "u" then
          vowel.phon = "uː"
          cons.phon = ""
          vowel.source = "labial_vocalization"
        end
      end

      ::continue::
    end
    return tokens
  end,
}
```

- [ ] **Update `passes/init.lua`**

```lua
passes[9] = require("passes.06d_anticipatory_raising")
passes[10] = require("passes.06e_labial_vocalization") -- NEW
passes[11] = require("passes.07_nasalization")
-- Renumber rest... (passes[12]-[19])
```

- [ ] **Test**

Run: `F:/soft/lua/lua.exe -e "local e = require('irish_engine_new'); print('marbh: '..e.transcribe('marbh'))"`

Expected: `mˠaɾˠuː` (not `mˠaɾˠw`)

- [ ] **Commit**

```bash
git add passes/06e_labial_vocalization.lua passes/init.lua
git commit -m "feat: add labial fricative vocalization (bh/mh→uː after short vowel)"
```

---

### Task 7: Add /x/ Palatal Non-Assimilation Rule to Vowel Resolver

**Files:**
- Modify: `passes/10_vowels.lua` (after line 75, before contextual consonant polarity section)

**Description:** Hickey: `/x/` (ch) is immune to palatal assimilation. When `/x/` precedes a slender consonant, it stays broad and BLOCKS the preceding vowel from fronting: `bocht` → [bˠʌxt̪ˠ], comp. `boichte` → [bˠʌxtʲə], NOT *[bˠɪxʲtʲə]. The current rule at lines 75-87 changes `o` to `ɪ` if the next consonant is palatal, which incorrectly fires for `boichte`.

- [ ] **Add /x/ blocking rule before the contextual consonant polarity section**

```lua
-- /x/ palatal non-assimilation: /x/ stays broad before slender consonants
-- and blocks the preceding vowel from fronting
-- bocht → bˠɔxt̪ˠ, boichte → bˠɔxtʲə (NOT *bˠɪxʲtʲə)
if next and next.type == "cons" and next.ortho == "ch" then
    -- skip contextual vowel fronting — /x/ blocks it
    goto skip_fronting
end

-- Contextual: consonant polarity affects vowel quality
if next and next.type == "cons" then
    if next.palatal == true and (ortho == "o" or ortho == "u") then
        token.phon = "ɪ"
    -- ... rest of existing rule
end

::skip_fronting::
```

- [ ] **Implement**

Replace:
```lua
      -- Contextual: consonant polarity affects vowel quality
      if next and next.type == "cons" then
        if next.palatal == true and (ortho == "o" or ortho == "u") then
          token.phon = "ɪ"
```

With:
```lua
      -- /x/ palatal non-assimilation: blocks vowel fronting
      local has_x_block = next and next.type == "cons" and next.ortho == "ch"

      -- Contextual: consonant polarity affects vowel quality
      if next and next.type == "cons" and not has_x_block then
        if next.palatal == true and (ortho == "o" or ortho == "u") then
          token.phon = "ɪ"
```

- [ ] **Test**

Run: `F:/soft/lua/lua.exe -e "local e = require('irish_engine_new'); print('bocht: '..e.transcribe('bocht'))"`

Expected: `bˠɔxt̪ˠ`

Compare to without the fix: the `ch` palatal would trigger `o→ɪ`.

- [ ] **Commit**

```bash
git add passes/10_vowels.lua
git commit -m "fix: add /x/ palatal non-assimilation rule to vowel resolver (Hickey)"
```

---

### Task 8: Fix Sonorant Lengthening (Suffix/Compound Distinction)

**Files:**
- Modify: `passes/13_sonorants.lua`

**Description:** Theory: Vowels lengthen/diphthongize before historical geminate sonorants (nn, ll, rr, mm) ONLY in monosyllables. Adding a suffix blocks lengthening, BUT compounds preserve it. Also, the current code checks `nn` and `ll` but the tokenization may split these into `n`+`n` and `l`+`l` tokens.

- [ ] **Rewrite `passes/13_sonorants.lua`**

```lua
-- Pass #13: Strong sonorants (Hickey Ch.2, Fuaimeanna Ch.7).
-- Vowel lengthening/diphthongization before historical geminate
-- sonorants (nn, ll, rr, mm) in monosyllables.
-- Suffix blocks lengthening, compound preserves it.

local S = require("passes._shared")

local STRONG_SONORANTS = { nn = true, ll = true, rr = true, mm = true }
-- Also handle geminate pairs split by tokenization: n+n, l+l
local function is_geminate_pair(tokens, i)
    if not tokens[i] or not tokens[i+1] then return false end
    local t1, t2 = tokens[i], tokens[i+1]
    return t1.type == "cons" and t2.type == "cons" and t1.ortho == t2.ortho
        and (t1.ortho == "n" or t1.ortho == "l")
end

return {
  name = "sonorants",
  writes_context = false,

  run = function(tokens, context)
    if not context.is_monosyllabic then return tokens end

    -- Find the final consonant(s) — check for strong sonorant or geminate pair
    local last_idx = #tokens
    while last_idx > 0 and tokens[last_idx].type ~= "cons" do
        last_idx = last_idx - 1
    end
    if last_idx == 0 then return tokens end

    local last_cons = tokens[last_idx]
    local is_strong = STRONG_SONORANTS[last_cons.ortho]
    local is_geminate = is_geminate_pair(tokens, last_idx)

    if not is_strong and not is_geminate then return tokens end

    -- Find the vowel before this sonorant
    local prev_vowel = tokens[last_idx - 1]
    if not prev_vowel or prev_vowel.type ~= "vowel" then return tokens end

    -- Only modify if vowel hasn't been heavily modified by earlier passes
    -- (Don't re-override vocalized forms)
    if prev_vowel.phon ~= prev_vowel.ortho and prev_vowel.phon ~= "" then
        -- Already modified by vocalization; don't touch
        return tokens
    end

    local ortho = prev_vowel.ortho
    local dv = S.DIALECTS[context.dialect] or S.DIALECTS.connacht

    if ortho == "a" then
        prev_vowel.phon = "aː"
    elseif ortho == "o" then
        prev_vowel.phon = "oː"
    elseif ortho == "u" then
        prev_vowel.phon = "uː"
    end

    prev_vowel.source = "strong_sonorant_lengthening"
    return tokens
  end,
}
```

- [ ] **Test with `peann` and `peanna`**

Run: `F:/soft/lua/lua.exe -e "local e = require('irish_engine_new'); print('peann: '..e.transcribe('peann')); print('peanna: '..e.transcribe('peanna'))"`

Expected: `peann` → [pʲaːnˠ] (lengthened), `peanna` → [pʲan̪ˠə] (short, suffix blocks)

- [ ] **Commit**

```bash
git add passes/13_sonorants.lua
git commit -m "fix: sonorant lengthening with suffix/compound distinction (Hickey)"
```

---

### Task 9: Add /rʲ/ Word-Final Assibilation and /oːgʲ/ Anomaly

**Files:**
- Modify: `passes/14_final_cleanup.lua`

**Description:** Hickey Ch.2: Word-final /rʲ/ assibilates to [ʃ] or [ʂ] in some dialects. Western /oːg/ → /oːgʲ/ (palatal anomaly) in words like `ciotóg`, `sióg`.

- [ ] **Add rules to `passes/14_final_cleanup.lua`**

```lua
-- Step N: Word-final /rʲ/ assibilation (Hickey Ch.2)
-- Some dialects: slender /rʲ/ → [ʃ] at word end
for i = #tokens, 1, -1 do
    if tokens[i].type == "cons" and tokens[i].phon == "ɾʲ" then
        local is_final = true
        for j = i + 1, #tokens do
            if tokens[j].phon and tokens[j].phon ~= "" then is_final = false; break end
        end
        if is_final then
            tokens[i].phon = "ʃ"  -- simplified assibilation for now
        end
        break
    end
end
```

- [ ] **Commit**

```bash
git add passes/14_final_cleanup.lua
git commit -m "feat: add /rʲ/ word-final assibilation (Hickey)"
```

---

### Task 10: Validate Full Regression Sample

**Files:**
- Create: `regression_sample.lua` (in repo root, not archive)

**Description:** Run the 104-word regression sample through the updated engine and compare against previous baseline (avg Lev 3.95, avg Dolgo 0.516). Report per-category changes.

- [ ] **Create validation script or run inline**

```bash
F:/soft/lua/lua.exe -e "
local e = require('irish_engine_new')
local test_words = {
  {'glas','ɡlˠasˠ','simple'},
  {'cnoc','kɾˠɔk','vowel_gradation'},
  {'tirim','tʲɛɾʲɪmʲ','r_lowering'},
  {'colaiste','kʊlˠaːʃtʲə','anticipatory'},
  {'marbh','mˠaɾˠuː','labial_vocal'},
  {'peann','pʲaːnˠ','sonorant_len'},
  {'peanna','pʲan̪ˠə','sonorant_short'},
  {'bocht','bˠɔxt̪ˠ','x_nonassim'},
}
local total_ok, total_fail = 0, 0
for _, tw in ipairs(test_words) do
  local result = e.transcribe(tw[1])
  if result == tw[2] then
    print('OK: ' .. tw[1] .. ' = ' .. result .. ' (' .. tw[3] .. ')')
    total_ok = total_ok + 1
  else
    print('FAIL: ' .. tw[1] .. ' expected=' .. tw[2] .. ' got=' .. result .. ' (' .. tw[3] .. ')')
    total_fail = total_fail + 1
  end
end
print(total_ok .. '/' .. (total_ok+total_fail) .. ' passing')
"
```

- [ ] **Commit final validation**

```bash
git commit -m "chore: validate theory-grounded pass pipeline across test words"
```

---

## Pipeline Evolution Summary

Current (15 passes):
```
polarity → stress → eclipsis → cluster_simplify → mutated_fricatives →
vocalization → nasalization → slender_coda → consonants → vowel_adjunct →
vowels → unstressed_reduction → epenthesis → sonorants → final_cleanup
```

New (20 passes):
```
polarity → stress → eclipsis → cluster_simplify → mutated_fricatives →
vocalization → vowel_gradation → r_lowering → anticipatory_raising →
labial_vocalization → nasalization → slender_coda → consonants →
vowel_adjunct → vowels → unstressed_reduction → epenthesis →
sonorants → final_cleanup
```

The 5 new passes all sit between vocalization (#6) and nasalization (#7) because they:
1. Need consonant polarity (from pass #1)
2. Need stress information (from pass #2) 
3. Must run before nasalization affects vowel quality
4. Operate on unmodified vowel tokens (phon == ortho check)
