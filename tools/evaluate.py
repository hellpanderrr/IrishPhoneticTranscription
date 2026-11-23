# -*- coding: utf-8 -*-
"""Rebuild the exception layers and measure the engine, including on held-out words.

    python tools/evaluate.py            # all three dialects
    python tools/evaluate.py munster    # one dialect
    LUA=/path/to/lua python tools/evaluate.py

What it does, per dialect (all of it deterministic):
  1. RULES   score all words without the exception layer (--no-lexsubs). The pass files still contain
             word-specific tables (see docs/EVALUATION.md), so this is "no generated layer", not "no word lists".
  2. PRODUCTION LAYER   regenerate passes/lex_subs_<dialect>.lua from the errors of step 1 (all words) and score
             all words with it. This number is IN-SAMPLE: the layer was fitted to these very words.
  3. HELD-OUT   regenerate a layer from the errors on the 80% "train" words only (build/lex_subs_train_<dialect>.lua),
             then score the 20% "test" words with it. The layer never saw those words, so this is the figure that
             says how the engine does on words it has not been corrected on.
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LUA = os.environ.get("LUA", "lua")
os.makedirs(os.path.join(ROOT, "build"), exist_ok=True)



def run(cmd):
    out = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, encoding="utf-8", check=True)
    return out.stdout


def bench(dialect, *extra):
    text = run([LUA, "bench_run.lua", "x", dialect, *extra])
    m = re.search(r"Exact: (\d+)/(\d+) \(([\d.]+)%\)", text)
    return int(m.group(1)), int(m.group(2)), float(m.group(3))


def main():
    dialects = sys.argv[1:] or ["connacht", "munster", "ulster"]
    rows = []
    for d in dialects:
        # 1. rules only, all words (this also writes the error list the production layer is built from)
        rules = bench(d, "--no-lexsubs", "--write")
        run([sys.executable, "tools/gen_lexical_subs.py", d])
        # 2. production layer, all words (in-sample)
        hybrid = bench(d)
        # 3. held-out
        rules_train = bench(d, "--no-lexsubs", "--split", "train", "--write")
        run([sys.executable, "tools/gen_lexical_subs.py", d, "--out", f"build/lex_subs_train_{d}.lua"])
        mod = f"build.lex_subs_train_{d}"
        held_rules = bench(d, "--no-lexsubs", "--split", "test")
        held_hybrid = bench(d, "--split", "test", "--lexsubs", mod)
        # restore the all-word errors for anyone who looks at build/ afterwards
        bench(d, "--no-lexsubs", "--write")
        rows.append((d, rules, hybrid, held_rules, held_hybrid))
    print("| dialect | words | rules only | + exception layer (in-sample) | held-out words | held-out, rules only | held-out, + layer from train words |")
    print("|---|---|---|---|---|---|---|")
    for d, rules, hybrid, held_rules, held_hybrid in rows:
        print("| %s | %d | %.2f%% | %.2f%% | %d | %.2f%% | %.2f%% |"
              % (d, rules[1], rules[2], hybrid[2], held_rules[1], held_rules[2], held_hybrid[2]))


if __name__ == "__main__":
    main()
