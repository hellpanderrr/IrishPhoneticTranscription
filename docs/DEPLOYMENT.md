# Deployment: the engine also runs in the browser app

The engine is used by the browser IPA transcriber at https://hellpanderrr.github.io/wiktionary_pron/ (repo `hellpanderrr/hellpanderrr.github.io`, served from GitHub Pages), where it runs under wasmoon (Lua 5.4 in WebAssembly). The app holds a **copy** under `wiktionary_pron/lua_modules/` (`ga-irish_engine.lua` plus `ga-passes/`). There is no submodule and no build step: the copy is manual.

`hellpanderrr/hellpanderrr.github.io`, served from GitHub Pages) as a **copy** under
`wiktionary_pron/lua_modules/`. There is no submodule or build step — the copy is manual.

- **The copies can drift, and drift is invisible.** At one point a review fix was applied to the deployed copy but never benchmarked here, and ~220 lines diverged. As of 2026-11-23 the 17 pass files and the three exception layers are identical in both places after the require rename; the entry file differs (the deployed one has an extracted onset-search helper). **After changing either copy, reconcile both and re-run `python tools/evaluate.py`.** Verify with a normalized diff — the deployed files are CRLF, so a
  raw `diff` reports whole-file mismatches and hides the real delta. The transform must cover
  the require prefix *and* the `_shared` rename, or every pass file shows a spurious 1-line diff:
  ```sh
  norm() { sed 's/"passes\./"ga-passes./g; s/ga-passes\._shared/ga-passes.shared/g; s/\r$//' "$1"; }
  diff <(norm passes/X.lua) <(sed 's/\r$//' "$DEPLOY/X.lua")
  ```
  (`_shared.lua` itself maps to `shared.lua`; its internal `local _shared` variable is just an
  identifier and stays as-is on both sides.)
- **The sync is a rename, not a copy.** `passes.` → `ga-passes.` in every require, **and**
  `_shared` → `shared` (see the Jekyll note below). Source keeps `_shared.lua`; the deployed
  copy is `shared.lua`.
- **GitHub Pages silently drops files whose basename starts with `_`.** The Pages build runs
  `actions/jekyll-build-pages`, which excludes them. `_shared.lua` 404'd in production and
  broke Irish entirely (all 17 passes require it) while every local test passed. A repo
  `_config.yml` with an `include:` entry does **not** fix this — that action runs in safe mode
  with GitHub's own config and ignores it (tried, deploy succeeded, still 404). `.nojekyll`
  is also irrelevant (legacy pipeline only). **The fix is to not use a leading underscore.**
- **Green tests ≠ working site.** Golden and e2e both run against local files and passed
  throughout the outage. Only a request to the live URL caught it. After deploying, curl the
  actual asset.
- The deployed copy also carries `lex_subs_*.lua`. Regenerate them here (`python tools/evaluate.py`), then copy; do not edit them there.
  edit them there.

