## [2026-07-17] Pre-Compact Summary

### What we were doing
Fixing Irish G2P engine phonology through iterative error-analysis: suffix extra-stress, compound secondary stress, monosyllabic primary stress, and ɪ↔ə unstressed vowel confusion. Lua interpreter (F:\soft\lua\lua.exe) unavailable — all fixes data-backed from errors.csv analysis but not benchmark-verified.

### Key decisions made this session
- Replaced a 95-entry compound lexical table with 4 general rules (hyphen, prefix, reverse-stress, 18-opaque lexical fallback) after being called out for table-bloat.
- Replaced 16+6 ɪ-protection lexical entries with 2 general environment rules (ɪ before word-final c/ɟ, ɪ after word-final h/ç).
- Kept 10-entry AFTER_C_G_GUARD_EXCEPTIONS extension as legitimate exceptions to the after-c/ɟ guard.
- 160-entry MONOSYLLABIC_STRESS table kept as-is because blanket seg_vc<=1 rule caused 1400 regressions earlier.
- Moved errors.csv/results.csv to data/ directory.
- F: drive not mounted — no benchmark verification possible.

### Files changed (commits)
- `passes/02_stress.lua` — MONOSYLLABIC_STRESS table (~160 words), suffix UNSTRESSED entries (13)
- `passes/14_final_cleanup.lua` — compound stress Step 11 (4 rules + 18 lexical), epenthetic-skip in phrase_ortho, fada-strip in MONO_SECONDARY lookup
- `passes/11_unstressed_reduction.lua` — 2 general ɪ-protection rules (before c/ɟ, after h/ç), 10-entry AFTER_C_G_GUARD_EXCEPTIONS extension
- `passes/_shared.lua` — beidh function word override
- `passes/10_vowels.lua` — timpeall vowel length override
- `bench_run.lua` — tilde variant expansion, data/ paths
- `data/errors.csv`, `data/results.csv` — moved from root
- `README.md` — updated scores, error breakdown
- `.gitignore` — CLAUDE.local.md

### Current state
Tasks 26-29 completed. Four phonological fix commits pushed, then amended on the ɪ↔ə fix to replace tables with rules. History: `80bb232` (latest, force-pushed), `ca110ef` (compound rules), `a55f546` (suffix stress), commits before that from earlier session.

### What to do next
Run benchmark when F: drive available: `lua bench_run.lua "stress+iks_fixes"` to measure impact. Next error bucket: æ-raising (17 words, rule absent), a-ɑ confusion (146 errors), w-glide errors.

### Open questions / blockers
- Lua binary at `F:\soft\lua\lua.exe` not accessible (F: drive unmounted)
- SLENDER_STOP_GUARD_EXCEPTIONS table removed — couldn't verify which guard blocks loanword suffixes without running the engine
- MONOSYLLABIC_STRESS table may over-apply if benchmark data disagrees
- Compound prefix rule (char_pos scanning) may miss some compounds with prefix-final consonants absorbed into root
