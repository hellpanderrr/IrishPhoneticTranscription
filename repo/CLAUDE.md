# Irish G2P Engine

## Project
Irish G2P (grapheme-to-phoneme) engine — modular 16-pass token-array pipeline. Transcribes Irish orthography to IPA for Connacht dialect.

## Key Commands
- **Benchmark**: `F:/soft/lua/lua.exe bench_run.lua "label"`
- **Lua**: `F:/soft/lua/lua.exe` (not on PATH)
- **Test a word**: `F:/soft/lua/lua.exe -e "local e=require('irish_engine_new'); print(e.transcribe('word','connacht'))"`

## Architecture
- `passes/init.lua` — pass order (16 passes)
- `passes/_shared.lua` — shared defs (VOWEL_DIGRAPHS, DIALECTS, make_token)
- `passes/01_polarity.lua` — consonant broad/slender polarity
- `passes/10_vowels.lua` — vowel resolution + contextual allophony
- `passes/11_unstressed_reduction.lua` — unstressed vowel reduction
- `irish_engine_new.lua` — engine entry point

## Benchmark Target
- Current: ~44.17% exact match (2912/6593) Connacht
- Lev-1 single-substitution error buckets in `_base.tsv`

## Encoding
- Lua strings are raw bytes. Unicode chars use UTF-8 byte sequences.
- ɛ = `\xc9\x9b` (U+025B), ɪ = `\xc9\xaa` (U+026A), ʊ = `\xca\x8a` (U+028A)
- ˠ = `\xcb\xa0` (U+02E0, broad), ʲ = `\xca\xb2` (U+02B2, slender)
- Use `ustring` library: `ulen(s)`, `usub(s,i,i)` for Unicode-aware operations

<!-- graymatter:instructions:begin — managed by `graymatter init`; edits inside this block are overwritten -->
## Memory (GrayMatter)

This project has persistent agent memory via the `graymatter` MCP tools:

- `memory_search` (`agent_id`, `query`) — call at the **start of a task** when prior context might matter.
- `memory_add` (`agent_id`, `text`) — call whenever you learn something **durable**: user preferences, decisions, conventions, gotchas.
- `memory_reflect` (`action`, `agent`, `text`/`target`) — update or forget stale facts. ⚠ takes `agent`, not `agent_id`.
- `checkpoint_save` / `checkpoint_resume` (`agent_id`) — snapshot/restore session state before major refactors or across restarts.

Use a stable `agent_id` of the form `<project>-<role>` (e.g. `myapp-backend`). Store conclusions, not conversation logs. Err on the side of remembering.
<!-- graymatter:instructions:end -->
