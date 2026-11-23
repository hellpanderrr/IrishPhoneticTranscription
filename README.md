# Irish G2P engine

A rule-based **grapheme-to-phoneme (G2P) engine for Irish**, written in Lua. It converts Irish spelling to IPA for three
dialects: **Connacht** (the main target), **Munster** and **Ulster**. The rules follow Raymond Hickey's *The Sound Structure
of Modern Irish* (2014) and Brian Ó Raghallaigh's *Fuaimeanna na Gaeilge* (2013). It runs under Lua 5.4 and, through
[wasmoon](https://github.com/ceifa/wasmoon), in the browser transcriber at
https://hellpanderrr.github.io/wiktionary_pron/?lang=Irish (see `docs/DEPLOYMENT.md`).

It is an experimental research tool, not a finished product. Read "How accurate is it?" before you rely on it.

## Use

Requires Lua 5.4. The `ustring` library it depends on is included.

```sh
lua -e "local e=require('irish_engine_new'); print(e.transcribe('seomra','connacht'))"
```

`transcribe(word, dialect, opts)` takes one word (lower or upper case), `dialect` = `"connacht"` (default), `"munster"` or
`"ulster"`, and returns the IPA string. A non-string word or an unknown dialect raises an error. `opts.no_lexsubs = true`
switches the generated per-word exception layer off (rules only).

It is built for single words. A phrase can be passed, but behaviour across word boundaries is not specified.

## How accurate is it?

Exact match against Wiktionary's dialect-tagged IPA, on **words the exception layer was not built from** (a fixed 20% test
split; method and caveats in [`docs/EVALUATION.md`](docs/EVALUATION.md)):

| | Connacht | Munster | Ulster |
|---|---|---|---|
| Held-out exact match | **69.4%** (1,553 words) | **54.5%** (795) | **51.8%** (929) |
| Held-out phone error rate | 10.3% | 16.0% | 19.4% |
| All words, rules only | 71.3% (8,034) | 56.8% (4,102) | 52.4% (4,785) |
| All words, rules + exception layer | 96.1% | 93.9% | 95.0% |

**The last row is not a measure of quality.** The exception layer is generated from the benchmark's own errors, so it scores
high on the words it was built from and does nothing for other words (the held-out gain is 0.0 to 0.3 points). Quote the
held-out row. Even that row is somewhat optimistic: the pass files contain word-specific tables tuned on the whole benchmark.
The reference transcriptions are also inconsistent between Wiktionary contributors, which caps the Munster and Ulster scores.

## Reproduce

```sh
lua tests/run_tests.lua              # golden snapshot + argument handling (about 390 checks)
python tools/evaluate.py             # rebuilds the exception layers and prints the table above (LUA=... if needed)
lua bench_run.lua label munster --split test --no-lexsubs   # one benchmark run
```

## Layout

```
irish_engine_new.lua       entry point: tokenizer, pass orchestration, exception layer
passes/                    the 17 passes (01_polarity ... 15_dialect_finalize), init.lua, _shared.lua,
                           lex_subs_<dialect>.lua = generated exception layers
benchmarks/                generated benchmark per dialect, with a train/test split (committed)
bench_run.lua              benchmark harness (exact match, Levenshtein, Dolgopolsky, phone error rate)
tools/                     make_dialect_benchmarks.py, gen_lexical_subs.py, evaluate.py
tests/                     golden snapshot and tests
data/                      Wiktionary pronunciation lists the benchmarks come from (CC BY-SA)
docs/                      ARCHITECTURE.md, EVALUATION.md, DEPLOYMENT.md
ustring/                   MIT-licensed UTF-8 string library for Lua
```

## Known limits

- Phrases are not supported across word boundaries (`ar an mbord` transcribes the eclipsed `mb` wrongly).
- Many monosyllables get no stress mark, following an inconsistent convention in the reference data.
- Dialects are idealised: Ulster follows Donegal conventions; Munster merges Kerry, Cork and Waterford.
- The exception layer's per-word fixes are keyed on the spelling with its fadas, so mis-spelt or unfadaed input
  (`sean` for `séan`) does not receive the fix.

## Licence and citation

GPL-3.0-only (`LICENSE`). `ustring/` is MIT. The pronunciation data in `data/` and everything derived from it
(`benchmarks/`, `passes/lex_subs_*.lua`, `tests/golden.tsv`) comes from English Wiktionary and is CC BY-SA 4.0:
see `THIRD_PARTY_NOTICES.md`. To cite, use `CITATION.cff` (GitHub's "Cite this repository" button).
