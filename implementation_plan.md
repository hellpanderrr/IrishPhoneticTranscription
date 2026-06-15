# Irish G2P Improvement Plan

## Background

Analysis of **6,911 words** in `results.csv`:

| Metric | Value |
|---|---|
| Perfect match (`match=100`) | 2,423 (35.1%) |
| Partial match | 4,388 (63.5%) |
| Zero match | 100 (1.4%) |
| Average Dolgo score | **0.9417** |
| Words with Dolgo < 0.8 (significant errors) | **611** |

The Dolgo score is a phoneme-class-aware distance (0 = completely different class, 1.0 = perfect). Most words score well at the phoneme class level but fail at the fine-grained diacritic / allophone level. Fixing issues in order below will have the highest yield.

---

## Priority 1 — High Impact, High Confidence (fix first)

### Issue 1 · `sh`/`th` Lenition: `h` vs `ç` Confusion — **113 cases**

**Problem:** The engine emits `ç` (palatal fricative) where the expected output is `h`, and vice versa. This is the single most impactful systematic rule error.

- `Sheáin` → engine produces `ˈhɛɑːnʲ`, expected `çɑːnʲ`
- `cheana` → engine produces `ˈçanˠə`, expected `ˈhanˠə`
- `athair` → engine produces `ˈaçɪɾʲ`, expected `ˈahæɾʲ`
- `beathaí` → engine produces `ˈbʲaçiː`, expected `ˈbʲahiː`
- `brath` → engine produces `ˈbˠɾˠaç`, expected `ˈbˠɾˠa`

**Root cause (Hickey Ch. II §B):**
- `sh` and `th` lenite to `h` **before back/low vowels** and in word-final position.
- `ch` lenition of `s` or `t` → `ç` happens only **before front vowels** (`e/i`).
- Word-final `th` is **silent** (→ Ø), not `ç`.
- `sh` before any vowel is always `h`, never `ç`.

**Fix:**
```
Rule: word-final <th> → Ø (silent)
Rule: <sh> → h  (always, regardless of following vowel)
Rule: lenited <t> + front vowel → ç
Rule: lenited <t> + back/low vowel → h
Rule: lenited <s> → h  (s-lenition is always h, not ç)
```

---

### Issue 2 · Stress Mark False Positives — **362 cases**

**Problem:** The engine adds `ˈ` to monosyllabic words, function words, and words whose expected IPA form is unstressed. The expected IPA deliberately omits the stress mark for these.

- `glas` → expected `ɡlˠasˠ`, engine produces `ˈɡlˠasˠ`
- `glais` → expected `ɡlˠaʃ`, engine produces `ˈɡlˠaʃ`
- `ˈ'sé` → expected `ʃeː`, engine produces `ʃeː` ✓ (but many others like it fail)

**Root cause:** The engine unconditionally prefixes `ˈ` to every word output. The Wiktionary reference transcriptions omit the stress mark for monosyllabic words (where stress is obvious and unmarked by convention) and for clitic/function words.

**Fix:** Apply one of two strategies (choose based on Wiktionary convention):
1. **Suppress `ˈ` on monosyllabic words** — count vowel nuclei; if = 1, omit `ˈ`.
2. **Suppress `ˈ` on known function words** — maintain a blocklist of clitics (`is`, `an`, `go`, `do`, `a`, `le`, `ar`, `i`, `ó`, `ag`, etc.)

> [!IMPORTANT]
> Strategy 1 is the correct approach per Wiktionary IPA conventions and will resolve the majority of cases with a single rule change.

---

### Issue 3 · `ó` Not Raised to `uː` Before Nasals — **~30 cases, affects many more**

**Problem:** The engine maps `ó` → `oː` but many words require `ó` → `uː` due to **Nasal Raising** (Hickey Ch. II §3, §3.3).

- `cónaí` → expected `ˈkuːnˠiː`, engine produces `ˈkoːnˠiː`
- `nóin` → expected `n̪ˠuːnʲ`, engine produces `ˈnˠoːnʲ`
- `nóiméad` → expected `ˈn̪ˠuːmʲeːd̪ˠ`, engine produces `ˈnˠoːmʲeːd̪ˠ`
- `inneoin` → expected `ˈin̠ʲuːnʲ`, engine produces `ˈɪn̠ʲoːnʲ`
- `trom` → expected `t̪ˠɾˠuːmˠ`, engine produces `ˈt̪ˠɾˠmˠKɾˠ_O_SHTmˠ` (marker leak + no raising)

**Root cause (Hickey §3 "Nasal Raising"):** A **short or long mid-back vowel** `/o/` or `/oː/` raises to `/uː/` when the **following consonant is a nasal** (`m, n, ŋ`). This is a coda-conditioned rule, not an onset rule. The engine either applies it inconsistently or only to short vowels.

**Fix:**
```
Rule: <ó> (written) before coda nasal m/n/ng → /uː/  (not /oː/)
Rule: short <o> before coda nasal → /ʊ/ or /uː/ depending on syllable weight
```
Must apply in the Raising stage before vowel finalization.

---

## Priority 2 — Medium Impact, Phonological Accuracy

### Issue 4 · Dental Diacritic `̪` Missing — **52 cases**

**Problem:** The engine produces `nˠ`, `lˠ`, `d`, `t` where the expected IPA uses the dental diacritics `n̪ˠ`, `l̪ˠ`, `d̪ˠ`, `t̪ˠ` (subscript bridge = dental place of articulation).

- `Seán` → expected `ʃɑːn̪ˠ`, engine produces `ˈʃɛɑːnˠ`
- `nóiméad` → expected `ˈn̪ˠuːmʲeːd̪ˠ`, engine produces `ˈnˠoːmʲeːd̪ˠ`
- `meán` → expected `mʲɑːn̪ˠ`, engine produces `ˈmʲɛɑːnˠ`
- `bhranda` → expected `ˈvˠɾˠan̪ˠd̪ˠə`, engine produces `ˈwɾˠanˠə`

**Root cause (Hickey Ch. V §1 Appendix):** In Irish, `n`, `l`, `d`, `t` when non-palatal (broad) are specifically **dental** (tongue tip to upper teeth), not alveolar. Wiktionary transcribes this with `̪`. The engine's velarization rules produce the right broad quality but omit the dental place diacritic.

**Fix:** Apply `̪` to all broad (non-palatal) coronals `n`, `l`, `d`, `t` as part of the Diacritics stage. This is a systematic output rule: whenever these consonants carry `ˠ`, they should also carry `̪`.

```
nˠ → n̪ˠ
lˠ → l̪ˠ  
d (broad) → d̪ˠ
t (broad) → t̪ˠ
```

---

### Issue 5 · Vocalized Fricative Diphthongs (`bh/mh/gh/dh`) — **84 + 71 + 56 cases**

**Problem:** Sequences like `-abh`, `-amh`, `-adh`, `-agh`, `-odh`, `-ogh` should produce diphthongs `/au/` or `/ai/`, but the engine often produces incorrect vowels or retains fricatives.

- `marbh` → expected `ˈmˠaɾˠuː`, engine produces `ˈmˠɑːrw`  (epenthesis wrong, vowel wrong)
- `tarbh` → expected `ˈt̪ˠaɾˠuː`, engine produces `ˈt̪ˠɑːrw`
- `Domhnach` → expected `ˈd̪ˠoːn̪ˠəx`, engine produces `ˈd̪ˠowɾˠəx`
- `Shamhain` → expected `həunʲ`, engine produces `ˈçəuɪnʲ`

**Root cause (Hickey Ch. III §Appendix "Diphthongization Matrix"):**
- `-abh`, `-amh` → `/auv/` → `/au/` (labial fricative vocalizes to back diphthong)
- `-adh`, `-agh` → `/ai/` (velar fricative vocalizes to front diphthong)  
- `-amh` word-final → `/uː/` (full vocalization to long vowel in many words)
- Broad `-bh`/`-mh` word-final after short central vowel → `/uː/` (Hickey §5 "Labial Fricative Vocalization")

**Fix:** Add/repair rules in the Digraph/MarkerResolution stage:
```
Rule: <abh> coda → /auv/ → /au/   (broad labial)
Rule: <amh> coda → /au/ or /uː/
Rule: <adh> coda → /ai/
Rule: <agh> coda → /ai/
Rule: <ʌv> or <əv> word-final (broad) → /uː/   (Labial Fricative Vocalization)
```

---

### Issue 6 · `cn-`/`gn-`/`mn-` Sonorant Shift (`n → r`) — **~13 cases**

**Problem:** Word-initial clusters `cn`, `gn`, `mn` should map `n → r` (Hickey Ch. III §2 "Sonorant Shift"), but the engine is either treating these as `kn`, `gn`, `mn` or producing `Kɾˠ_O_SHT` leaked markers (see regression test: *cnoc*, *trom*, *bonn*).

- `cnoc` → expected `kɾˠʊk`, engine produces `ˈkɾˠmˠKɾˠ_O_SHTk` (marker leak)
- `gnáth` → expected `ɡɾˠɑː`, engine produces `ˈɡɾˠɑː` (some cases work)
- `mná` → expected `mˠɾˠɑː`, likely similar issue

**Root cause:** There is an internal marker (`Kɾˠ_O_SHT`) being leaked in some forms of the `cn-` cluster rule. The marker is used to tag something for later resolution but the FinalCleanup stage is not removing it in all paths.

**Fix (two parts):**
1. **Immediate:** Find and fix the FinalCleanup rule that should strip `Kɾˠ_O_SHT` / `Kɾˠ_U_SHT` markers. These must never appear in output.
2. **Rule completeness:** Ensure `cn → kɾ`, `gn → ɡɾ`, `mn → mɾ` rules apply before the nasal-raising stage (so `kɾ + o + nasal` then raises correctly).

---

## Priority 3 — Accuracy Refinements

### Issue 7 · `sh` Before Back Vowels: `h` vs `w` (`bh/mh` Broad) — **~30 cases**

**Problem (two sub-issues):**

**7a.** `bh`/`mh` before broad vowels should produce `w` in Connacht/Ulster (Hickey Ch. I §B, Ch. III §A):
- `bhfuair` → expected `wuəɾʲ`, engine produces `ˈvʊɪɾʲ`
- `bhflaith` → expected `wlˠa`, engine produces `ˈvlˠaç`
- `Haváis` → expected `haˈwaːɪʃ`, engine produces `ˈhʊvɑːʃ`

**7b.** `bh`/`mh` before slender vowels should produce `vʲ`:
- `agaibh` → expected `ˈaɡiː`, engine produces `ˈaɡɪɪvʲ` (extra syllable)

**Fix:**
```
Rule: broad <bh>/<mh> before back vowel (word-initial/medial) → w
Rule: <agaibh>, <acu>, <leo> etc. — terminal <bh/mh> after -igh/-ai → silent (→ iː)
```
The suffix `-ibh` in prepositional pronouns vocalizes entirely: `agaibh → aɡiː`.

---

### Issue 8 · Unstressed Vowel Reduction: `ə` vs `ɪ` — **~70 cases**

**Problem:** The engine sometimes emits `ə` where `ɪ` is expected in closed unstressed syllables with palatal codas (and vice versa).

- `gallán` → expected `ˈɡʊl̪ˠɑːnˠ`, engine produces `ˈɡʊlˠɑːnˠ` (dental + nasal raising issue compound)
- Several genitive forms show wrong reduced vowel quality

**Root cause (Hickey Ch. III §4 "Unstressed Reduction"):** In closed unstressed syllables, `ə` → `ɪ` when the **coda consonant is palatal**. Engine appears to apply `ə` uniformly.

**Fix:** In the UnstressedReduction stage, check the polarity of the coda consonant:
```
unstressed closed syllable + palatal coda → reduce to ɪ
unstressed closed syllable + broad coda   → reduce to ə
```

---

### Issue 9 · Vowel Shift Before Long Low Vowels (Western) — **~20 cases**

**Problem:** First-syllable short `a`/`o` is not being raised to `ʊ`/`ɪ` when the second syllable contains `ɑː`.

- `gallán` → expected `ˈɡʊl̪ˠɑːnˠ`, engine produces `ˈɡʊlˠɑːnˠ` (partially right)
- `gearrán` → expected `ˈɡʊɾˠɑːnˠ`, engine produces `ˈɡʊɾˠɑːnˠ` ✓ (works here)
- `cónaí` → first syllable short `o` raises to `ʊ`

**Root cause (Hickey §7 "Vowel Shifting Before Long Low Vowels"):** In Western Irish, a short `a`/`o` in syllable 1 anticipates `ɑː` in syllable 2 and raises to `ʊ`. This long-distance rule requires a 2-pass or lookahead in the stress/vowel stage.

**Fix:** Add a lookahead rule in the VowelQuality stage: if the current syllable has short `a`/`o` and the next syllable nucleus is `ɑː`, raise to `ʊ`.

---

## Priority 4 — Data Quality Issues

### Issue 10 · Empty Expected IPA / Multi-phrase entries — **~100 cases**

**Problem:** 100 words have `dolgo=0.0` but `exp=` (empty). These are data entries where the Wiktionary IPA field was blank or multi-word phrases where the CSV only captured part of the expected form.

- `fós`, `gabhair`, `lá`, `luch`, etc. → expected IPA is empty, dolgo computed as 0 unfairly.

**Fix (data, not engine):** Pre-filter entries with empty expected IPA from the scoring pass. These should not count against the engine. Consider also splitting multi-word expected IPA entries (comma-separated variants) and scoring against the best-matching variant.

---

## Proposed Execution Order

```
Phase 1 (biggest ROI):
  1. Fix sh/th h↔ç rule (113 cases)           → Irish rules stage
  2. Fix stress mark on monosyllables (362)    → Irish engine post-process
  3. Fix ó → uː nasal raising (30+ cases)      → Irish processors (Raising stage)

Phase 2 (phonological accuracy):
  4. Add dental diacritics n̪ˠ/l̪ˠ/d̪ˠ/t̪ˠ (52) → Irish rules Diacritics stage
  5. Fix vocalized fricative diphthongs (200+) → Irish rules MarkerResolution stage
  6. Fix cn-/gn- marker leak + n→r rule (13+)  → Irish rules PreProcess + FinalCleanup

Phase 3 (fine-tuning):
  7. Fix bh/mh → w broad rule (30)            → Irish rules Digraph stage
  8. Fix ə vs ɪ unstressed reduction (70)      → Irish processors UnstressedReduction
  9. Fix vowel shift before ɑː (20)            → Irish processors Raising/Quality stage

Phase 4 (data):
  10. Fix empty-IPA scoring in results.csv     → regression.lua / scoring script
```

## Estimated Score Impact

| Phase | Issues Fixed | Est. Words Corrected | Est. Dolgo Δ |
|---|---|---|---|
| Phase 1 | 1–3 | ~500 | +0.005–0.010 |
| Phase 2 | 4–6 | ~300 | +0.003–0.006 |
| Phase 3 | 7–9 | ~120 | +0.001–0.003 |
| Phase 4 | 10  | ~100 | +0.001 (scoring fix) |

> [!NOTE]
> The Dolgo average is already high (0.9417) because it measures phoneme class similarity. The real wins are in the `match=100` rate (currently 35.1%), which will improve dramatically from Phase 1–2 fixes since these are systematic rule errors affecting many words.
