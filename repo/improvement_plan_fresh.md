# Improvement Plan: Close the Accuracy Gap (28.9% → target 40%+)

> **Agentic note:** Implement tasks in order. Run `F:/soft/lua/lua.exe gen_results.lua` and `python analyze_errors.py` after each task to measure impact.

**Current baseline (fresh 2026-06-16):** 28.9% exact match (1990/6878), avg Lev 2.32 on 6911 words.
**Monolith baseline:** 37.5% exact vs expected IPA.

## Architecture Overview

The 16-pass token-array pipeline processes ortho → tokens → phon, with stress assigned in pass 02 and vowel resolution in pass 10. Critical gaps found:
- **Eclipsis pass (03)** silences wrong consonant — leaks through to output as double articulations (bhf→wf, dt→dtˠt̪ˠ)
- **Multi-word pass-through** — no phrase-level sandhi handling
- **Vowel reduction (pass 11)** too aggressive — unstressed a→ə, ɪ→ə, ɔ→ə but expected retains quality
- **Initial consonant /s/ before stops** — polarity rules need fixing
- **Vowel resolution in function words** — wrong quality for `i` (should be ə), `do` (should be d̪ˠə), `ag` (should be əɡ)

---

## Task 1: Fix eclipsis collapse (highest impact)

**File:** `passes/03_eclipsis.lua`

**Problem:** Eclipsis collapses the first consonant but the second consonant's ortho/type leaks into the phon. `bhf` → token `[bh, f]` where bh→w and f→f (silenced in pass 03 but `f` still has type=="cons" and gets resolved by pass 09). `dt` → tokens `[d, t]` where d gets polysyllabic polarity and t stays. `gc` → tokens `[g, c]` where c resolves to /k/.

The current pass 03 silences t2.phon="" only. But the silenced consonant token still carries its ortho through later passes and its type="cons" triggers contextual vowel rules. The real fix:

- **For `bhf` (3-consonant):** Silence BOTH t2 and t1 (so only t1.phon="w" surfaces). Set t1.source="eclipsis_resolved"
- **For `dt` (2-consonant):** After silencing t2, check if there's a following vowel that could make t1 palatal — set t1.palatal explicitly based on next vowel
- **For `gc` (2-consonant):** Same treatment as dt
- **For `nd` (2-consonant):** Set nd→nˠ (broad n), silence d
- **For `bp`:** Set bp→bˠ, silence p
- **For `mb`:** Set mb→mˠ, silence b

After pass 03 eclipsis silencing, add an **eclipsis cleanup** in pass 14 (final_cleanup.lua) that strips any lingering eclipsed second-consonant traces from tokens where t1 has source="eclipsis_silencing":

```lua
-- In 03_eclipsis.lua, replace the TWO_CONS_ECLIPSIS section:
local function handle_eclipsis_pair(t1, t2, pair)
  local ECLIPSIS_RESULT = {
    mb = { phon = "mˠ" },
    gc = { phon = "ɡ" },
    dt = { phon = "d̪ˠ" },
    bp = { phon = "bˠ" },
    nd = { phon = "n̪ˠ" },
    nn = { phon = "n̪ˠ" },
    bhf = { phon = "w" },
  }
  local result = ECLIPSIS_RESULT[pair]
  if result then
    t1.phon = result.phon
    t1.source = "eclipsis_result"
    t2.phon = ""
    t2.source = "eclipsis_silenced"
    t2.type = "silenced"  -- prevents later passes from treating it as cons
    return true
  end
  return false
end
```

Also handle `bhf` as a special case — it's the only 3-char eclipsis cluster:

```lua
-- In 03_eclipsis.lua, after TWO_CONS_ECLIPSIS:
if #tokens >= 3 and t1.ortho == "bh" and t2.ortho == "f" then
  t1.phon = "w"
  t1.source = "eclipsis_result"
  t2.phon = ""
  t2.type = "silenced"
  t3.phon = ""
  t3.type = "silenced"
  return tokens
end
```

**Expected impact:** Fixes ~100+ words where `bhfuil`, `dt-`, `gc-`, `nd-` produce broken output like wfˠ, t̪ˠt̪ˠ, ɡk, etc.

**Test words:** `bhfuil`, `i dtosach`, `i gceist`, `i gcónaí`, `i ndán`, `i bhfad`, `gc-` prefix words

---

## Task 2: Multi-word phrase stress and function word reduction

**File:** `passes/14_final_cleanup.lua`

**Problem:** The engine treats each word in a multi-word phrase independently — every word gets primary stress `ˈ` on its first vowel. Expected IPA for phrases typically has:
- Primary stress `ˈ` on the first CONTENT word only
- Secondary stress `ˌ` on subsequent content words  
- NO stress on function words (prepositions, articles, pronouns)
- Function words reduce to schwa

**Fix in final_cleanup:**
```lua
-- Step: Multi-word stress cleanup
-- Check if there are boundary tokens (spaces) — multi-word phrase
local has_boundary = false
for _, t in ipairs(tokens) do
  if t.type == "boundary" and t.ortho == " " then has_boundary = true; break end
end

if has_boundary then
  local content_word_count = 0
  for i, t in ipairs(tokens) do
    if t.type == "boundary" then
      -- Just crossed a word boundary
    elseif t.type == "vowel" and t.stress then
      content_word_count = content_word_count + 1
      -- After first content word, downgrade to secondary stress
      if content_word_count > 1 then
        t.stress_secondary = true
        t.stress = false  -- will render as ˌ not ˈ
      end
    end
  end
end
```

Then update `render_output` in `irish_engine_new.lua` to handle `stress_secondary` → `ˌ`.

**Also:** Function words (unstressed words in UNSTRESSED table) should NOT get stress even in multi-word context. Currently they're checked only in the monosyllabic stress logic but not re-checked in multi-word. Fix in pass 02:

```lua
-- In 02_stress.lua, after segment loop, add for multi-word:
local function is_function_word(ortho)
  return UNSTRESSED[ortho] ~= nil
end
```

**Expected impact:** Fixes ~320 multi-word entries (6.5% of all errors) plus secondary stress correct for all phrases.

---

## Task 3: Fix vowel reduction tuning (a→ə, ɪ→ə, ɔ→ə)

**File:** `passes/11_unstressed_reduction.lua`

**Problem:** The reduction pass is too aggressive — it reduces ANY unstressed short vowel to ə. Expected IPA retains vowel quality in:
- Unstressed /a/ before certain consonants (often before /x/, /ɾˠ/, /lˠ/)
- Unstressed /ɪ/ in palatal contexts (where expected has ɪ not ə)
- Unstressed /ɔ/ before /x/, /ɾˠ/

**Fix — add coda-conditioned exceptions:**
```lua
-- In 11_unstressed_reduction.lua, before reducing to ə:
-- Check the following consonant context
local next_cons = nil
for j = i + 1, #tokens do
  if tokens[j].type == "cons" then next_cons = tokens[j]; break end
  if tokens[j].type == "vowel" then break end
end

-- Don't reduce before certain consonants
local QUALITY_RETAINING = { ch = true, gh = true, th = true, sh = true,
                            r = true, rr = true, s = true, ss = true,
                            l = true, ll = true }

if next_cons and QUALITY_RETAINING[next_cons.ortho] and phon ~= "ə" then
  -- Keep original quality
  goto continue
end

-- Palatal codas: keep as ɪ not ə
if next_cons and next_cons.palatal == true and phon == "ɪ" then
  goto continue
end
```

**Expected impact:** Fixes ~1200+ vowel quality errors (v_a_to_ə 577, v_ɪ_to_ə 452, v_ɔ_to_ə 169 = ~1198 combined).

---

## Task 4: Fix sonorant polarization (n̪ˠ/nʲ/lˠ/lʲ/ɾˠ/ɾʲ)

**File:** `passes/01_polarity.lua` and `passes/09_consonants.lua`

**Problem:** ~1880 sonorant marker mismatches — the engine picks the wrong broad/slender polarity for sonorants (n, l, r), especially:
- Word-final sonorants after a digraph vowel (e.g., `abhainn` → expected n̠ʲ, engine produces n̪ˠ)
- Medial sonorants where the polarity depends on the FOLLOWING vowel but the engine uses the PREVIOUS vowel
- In `nn`/`ll`/`rr` geminates, pass 13 forces them to broad (ˠ) but expected often has slender (ʲ)

**Fix in 01_polarity.lua** — for sonorants specifically, use FOLLOWING vowel as primary determinant (not previous):
```lua
-- After line 52 (current polarity logic), add this for sonorants:
local sonorants = { l = true, n = true, r = true, m = true }
if sonorants[token.ortho] then
  -- Sonorants: FOLLOWING vowel determines polarity (not previous)
  local following_vowel = next_vowel
  if following_vowel then
    local pol = S.vowel_polarity(following_vowel, "next")
    if pol ~= nil then
      S.set_polarity(token, pol)
      goto continue
    end
  end
end
```

**In pass 13 (sonorants):** Don't force geminate n→n̪ˠ when the vowel context is slender:
```lua
-- After line 27, before setting first.phon = "n̪ˠ":
-- Check if preceding vowel is slender (e/i/é/í) — if so, use nʲ not n̪ˠ
local prev_vowel = tokens[i - 1]
if prev_vowel and prev_vowel.type == "vowel" then
  local v = prev_vowel.ortho
  if v:match("[iíeé]") then
    if first.ortho == "n" then first.phon = "nʲ"
    elseif first.ortho == "l" then first.phon = "lʲ"
    end
  else
    if first.ortho == "n" then first.phon = "n̪ˠ"
    elseif first.ortho == "l" then first.phon = "lˠ"
    elseif first.ortho == "r" then first.phon = "ɾˠ"
    elseif first.ortho == "m" then first.phon = "mˠ"
    end
  end
else
  -- Original broad defaults
  if first.ortho == "n" then first.phon = "n̪ˠ"
  elseif first.ortho == "l" then first.phon = "lˠ"
  elseif first.ortho == "r" then first.phon = "ɾˠ"
  elseif first.ortho == "m" then first.phon = "mˠ"
  end
end
```

**Expected impact:** Fixes ~1500+ sonorant polarity errors (many in the "other" category).

---

## Task 5: Fix ç vs h distinction (missing_ç + extra_ç)

**Files:** `passes/05_mutated_fricatives.lua` and `passes/09_consonants.lua`

**Problem:** The current code only produces ç for INITIAL slender ch (word position 1). But expected IPA shows ç also in medial positions after front vowels and before front vowels. And conversely, h is often expected where the engine produces ç.

Key rules from Hickey:
- **Word-initial slender ch** → ç (already handled)
- **Medial slender ch after front vowel** → ç (NOT h)
- **Medial slender ch after back vowel** → h
- **Word-final slender ch after front vowel** → ç
- **th slender after vowel** → h (always — never ç)
- **sh** → h (always — never ç)

**Fix in 09_consonants.lua:**
```lua
elseif token.ortho == "ch" then
  local prev = tokens[i - 1]
  if token.palatal == true then
    -- Slender ch: ç after front vowels, h after back vowels
    if prev and prev.type == "vowel" then
      local v = prev.ortho
      if v:match("[iíeé]") then
        token.phon = "ç"  -- front vowel → ç
      else
        token.phon = "h"  -- back vowel → h
      end
    else
      token.phon = "ç"  -- word-initial or after boundary → ç
    end
  else
    token.phon = "x"  -- broad ch always
  end
```

**Expected impact:** Fixes ~88 ç/h errors (44 missing + 44 extra).

---

## Task 6: Fix vowel quality in function words (i, do, ag, etc.)

**File:** `passes/10_vowels.lua` and `passes/02_stress.lua`

**Problem:** Many function words in the UNSTRESSED table produce wrong vowel quality:
- `i` (preposition) → expected "ə", engine produces "ɪ" or "a"
- `do` → expected "d̪ˠə", engine produces "dˠo" → "dˠə" (but initial vowel resolves wrong)
- `ag` → expected "əɡ", engine produces "aɡ" → reduces but initial consonant wrong
- `go` → expected "ɡə", engine produces "ɡo" → "ɡə" (vowel wrong before reduction)

**Fix:** In UNSTRESSED table handling (pass 02), set a context flag `context.word_is_function_word = true`. Then in pass 10 (vowels), check this flag:

```lua
-- In 10_vowels.lua, after need_resolve block:
-- Function words: override to expected vowels
if context.word_is_function_word then
  if ortho == "i" then token.phon = "ə"
  elseif ortho == "a" or ortho == "a'" then token.phon = "ə"
  end
end
```

**Expected impact:** Fixes ~100+ function word errors including `a`, `i`, `do` variants.

---

## Task 7: Fix long vowel quality (`eː`→ə, `iə`→ɪə, short vs long)

**File:** `passes/10_vowels.lua` and `passes/06_vocalization.lua`

**Problem:** `long_eː_to_ə` (14 errors), `diphthong_iə` (142 errors) where engine produces the right diphthong but wrong quality. `iə` should be monophthong `iːə` when stressed and preceding consonant is slender.

The `diphthong_iə` pattern from the analysis shows the engine producing `ɪə` instead of `iə` — the vowel gets reduced before the diphthong forms.

**Fix in 10_vowels.lua:** For the `ia` digraph, keep the full quality when stressed and preceded by palatal:
```lua
-- After "ua" and "ia" handling:
elseif ortho == "ia" then
  if token.stress and prev and prev.type == "cons" and prev.palatal == true then
    token.phon = "iə"
  else
    token.phon = dv.ia
  end
```

---

## Verification

After each task, run:
```bash
F:/soft/lua/lua.exe gen_results.lua
python analyze_errors.py
```

Key regression test words (check with `F:/soft/lua/lua.exe -e "local e=require('irish_engine_new'); print(e.transcribe('WORD'))"):
- Eclipsis: bhfuil, i dtosach, i gceist, i gcónaí, i ndán, i bhfad
- Multi-word: Dia dhuit, ar dtús, i dtreo, go raibh maith agat
- Function words: i, a, do, go, ag
- Vowel reduction: abairt, abairtí, agaibh, codail
- ç/h: athair, aichear, rac-cheol, seachain
- Sonorants: abhainn, inniu, peann, mall, carraig
- Long vowel: bhfiacha, bhia, aiféala, aigéad
