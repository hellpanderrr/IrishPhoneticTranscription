# Third-party notices

The code of this repository is licensed under the **GNU General Public License v3.0** (see `LICENSE`).
It contains the following third-party material under its own terms.

| Material | Where | Licence |
|---|---|---|
| **ustring**, a pure-Lua UTF-8 string library by Brad Jorsch, from MediaWiki's Scribunto | `ustring/` | MIT (text in `ustring/LICENSE`) |
| **Irish pronunciations from English Wiktionary** (words, dialect tags, IPA) | `data/all_regions.csv`, `data/connacht_only.csv`; derived from them: `benchmarks/*.lua`, `passes/lex_subs_*.lua`, `tests/golden.tsv` | CC BY-SA 4.0 (Wiktionary states CC BY-SA 4.0 and GFDL). Attribution: the contributors of the English Wiktionary Irish entries (page histories at https://en.wiktionary.org). Share-alike applies to these files and to what is derived from them. |

Linguistic sources the rules follow (cited in the pass files; no text of them is included here):

- Raymond Hickey, *The Sound Structure of Modern Irish*, De Gruyter Mouton, 2014.
- Brian Ó Raghallaigh, *Fuaimeanna na Gaeilge*, Cois Life, 2013.
