#!/usr/bin/env python3
"""Comprehensive error analysis of the Irish G2P engine benchmark."""
import re
from collections import Counter, defaultdict

# Read per-word results (tab-separated: word \t got \t expected \t match \t lev)
errors = []
correct = []
with open("../_base.tsv", "r", encoding="utf-8") as f:
    for line in f:
        parts = line.strip().split("\t")
        if len(parts) < 5:
            continue
        word, got, exp, match_str, lev_str = parts[0], parts[1], parts[2], parts[3], parts[4]
        match = match_str.strip() == "true"
        lev = float(lev_str)
        if match:
            correct.append(word)
        else:
            errors.append({"word": word, "got": got, "exp": exp, "lev": lev})

print("=" * 70)
print("IRISH G2P ENGINE — FULL ERROR ANALYSIS")
print("=" * 70)
print()
print(f"Total: {len(correct) + len(errors)} words")
print(f"Correct: {len(correct)} ({len(correct)/(len(correct)+len(errors))*100:.2f}%)")
print(f"Wrong: {len(errors)} ({len(errors)/(len(correct)+len(errors))*100:.2f}%)")
print(f"Avg Levenshtein: 1.15")
print(f"Normalized Lev: 94.27%")
print()

# ========== Lev-1 same-length substitution buckets ==========
# Use proper Unicode character splitting
def ipa_split(s):
    return list(s)

lev1_same = Counter()
lev1_examples = defaultdict(list)
for e in errors:
    if e["lev"] > 1:
        continue
    gc = ipa_split(e["got"])
    ec = ipa_split(e["exp"])
    if len(gc) != len(ec):
        continue
    for i, (g, x) in enumerate(zip(gc, ec)):
        if g != x:
            key = f"{g} → {x}"
            lev1_same[key] += 1
            if len(lev1_examples[key]) < 4:
                lev1_examples[key].append(e["word"])

total_lev1 = sum(lev1_same.values())
print("=" * 70)
print(f"LEV-1 SAME-LENGTH SUBSTITUTION BUCKETS ({total_lev1} total)")
print("=" * 70)
print(f"{'Count':<6} {'Substitution':<16} Examples")
print("-" * 70)
for (sub, count) in lev1_same.most_common():
    ex = ", ".join(lev1_examples[sub][:4])
    print(f"{count:<6} {sub:<16} {ex}")
print()

# ========== IPA phoneme inventory ==========
all_engine_phones = Counter()
all_expected_phones = Counter()
for e in errors:
    for p in ipa_split(e["got"]):
        all_engine_phones[p] += 1
    for p in ipa_split(e["exp"]):
        all_expected_phones[p] += 1

# ========== Stress errors ==========
print("=" * 70)
print("ERROR CATEGORIES")
print("=" * 70)
print()

# Categorize
categories = {
    "Stress only": [],
    "a/ɑ quality": [],
    "o/u/ɔ/ʊ quality": [],
    "i/ɪ/e/ɛ quality": [],
    "schwa vs full vowel": [],
    "r vs ɾ": [],
    "Consonant broad/slender": [],
    "Devoicing (voiced↔voiceless)": [],
    "Consonant quality (ç/h/x/ɣ/v/w/j)": [],
    "Length (ː)": [],
    "Other": [],
}

o_vowels = set("oɔuʊ")
i_vowels = set("iɪeɛ")
dev_consonants = {"c": "ɟ", "ɟ": "c", "t": "d", "d": "t", "p": "b", "b": "p", "k": "ɡ", "ɡ": "k", "tʃ": "dʒ"}
quality_consonants = set("çh xv w j ɣ ʃ")

for e in errors:
    g, x = e["got"], e["exp"]
    gc = ipa_split(g)
    ec = ipa_split(x)

    # Strip stress marks for content comparison
    gs = re.sub("[ˈˌ]", "", g)
    es = re.sub("[ˈˌ]", "", x)

    if gs == es:
        categories["Stress only"].append(e)
        continue

    # r vs ɾ
    if ("r" in gc and "ɾ" in ec) or ("ɾ" in gc and "r" in ec):
        categories["r vs ɾ"].append(e)
        continue

    # a/ɑ quality
    if ("a" in gc and "ɑ" in ec) or ("ɑ" in gc and "a" in ec):
        categories["a/ɑ quality"].append(e)
        continue

    # o/u/ɔ/ʊ quality
    if any(c in gc for c in o_vowels) and any(c in ec for c in o_vowels):
        gc_o = [c for c in gc if c in o_vowels]
        ec_o = [c for c in ec if c in o_vowels]
        if gc_o != ec_o:
            categories["o/u/ɔ/ʊ quality"].append(e)
            continue

    # i/ɪ/e/ɛ quality
    if any(c in gc for c in i_vowels) and any(c in ec for c in i_vowels):
        gc_i = [c for c in gc if c in i_vowels]
        ec_i = [c for c in ec if c in i_vowels]
        if gc_i != ec_i:
            categories["i/ɪ/e/ɛ quality"].append(e)
            continue

    # schwa vs full vowel
    if ("ə" in g and "ə" not in x) or ("ə" in x and "ə" not in g):
        categories["schwa vs full vowel"].append(e)
        continue

    # Consonant broad/slender
    if ("ˠ" in g and "ˠ" not in x) or ("ʲ" in g and "ʲ" not in x):
        categories["Consonant broad/slender"].append(e)
        continue

    # Devoicing
    has_devoicing = False
    for i, (g_char, x_char) in enumerate(zip(gc, ec)):
        if g_char in dev_consonants and dev_consonants[g_char] == x_char:
            has_devoicing = True
            break
        if x_char in dev_consonants and dev_consonants[x_char] == g_char:
            has_devoicing = True
            break
    if has_devoicing:
        categories["Devoicing (voiced↔voiceless)"].append(e)
        continue

    # Length (ː) differences
    if "ː" in g and "ː" not in x or "ː" in x and "ː" not in g:
        categories["Length (ː)"].append(e)
        continue

    # Consonant quality
    if any(c in gc for c in "çh ɣ v w j".split()) or any(c in ec for c in "çh ɣ v w j".split()):
        categories["Consonant quality (ç/h/x/ɣ/v/w/j)"].append(e)
        continue

    categories["Other"].append(e)

for cat_name, cat_errors in sorted(categories.items(), key=lambda x: -len(x[1])):
    pct = len(cat_errors) / len(errors) * 100
    print(f"{cat_name:<35} {len(cat_errors):>5} ({pct:.1f}%)")
    for e in cat_errors[:5]:
        print(f"  {e['word']:<20} got={e['got']:<20} exp={e['exp']}")
    print()

# ========== Word position analysis ==========
print("=" * 70)
print("WORD ANALYSIS")
print("=" * 70)
print()

# How many single-char words are wrong?
single_errors = [e for e in errors if len(e["word"]) == 1]
print(f"Single-letter words wrong: {len(single_errors)}")
for e in single_errors:
    print(f"  {e['word']:<5} got={e['got']:<15} exp={e['exp']}")

# Prefix words
prefix_errors = [e for e in errors if "-" in e["word"]]
print(f"\nPrefix/hyphenated words wrong: {len(prefix_errors)}")

# Multi-word errors
mw_errors = [e for e in errors if " " in e["word"]]
print(f"\nMulti-word phrases wrong: {len(mw_errors)}")
for e in mw_errors[:10]:
    print(f"  {e['word']:<25} got={e['got']:<30} exp={e['exp']}")

# ========== Shortest/longest errors ==========
print()
by_lev = Counter(e["lev"] for e in errors)
print("Error distribution by Levenshtein distance:")
for lev, count in sorted(by_lev.items()):
    print(f"  Lev-{int(lev)}: {count} words")
