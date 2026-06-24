"""Analyze new_results.csv vs expected IPA, with results.csv as monolith baseline."""
import csv
import sys
import io
import re
from collections import Counter

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

def load_csv(path):
    rows = []
    with open(path, 'r', encoding='utf-8-sig') as f:
        reader = csv.reader(f)
        header = next(reader)
        for row in reader:
            if len(row) >= 3:
                rows.append(row)
    return header, rows

def norm(s):
    if not s: return ''
    return s.replace('ˈ', '').replace('ˌ', '').replace('"', '')

def matches_any(result, expected_field):
    n_result = norm(result)
    current, in_quotes = '', False
    variants = []
    for ch in expected_field:
        if ch == '"': in_quotes = not in_quotes
        elif ch == ',' and not in_quotes:
            variants.append(current.strip()); current = ''
        else: current += ch
    if current.strip(): variants.append(current.strip())
    for v in variants:
        if norm(v) == n_result: return True
    return False

def first_variant(field):
    return field.split(',')[0].strip().strip('"')

# Load data
base = r'F:\projects\transcription\wiktionary_ipa_phoneme_lexicons\irish'
_, connacht = load_csv(f'{base}/repo/data/connacht_only.csv')
_, new_results = load_csv(f'{base}/repo/new_results.csv')  # new engine output, cols: word,tags,ipa,results,match,dolgo
_, old_results = load_csv(f'{base}/results.csv')  # monolith output, cols: word,tags,ipa,results,match,dolgo

# Build lookups
expected_by_word = {r[0]: r[2] for r in connacht if len(r) > 2}
mono_by_word = {r[0]: r[3] for r in old_results if len(r) > 3}

total = 0
exact_new = 0
mono_matched = 0
errors = []

for row in new_results:
    word = row[0]
    result_new = row[3] if len(row) > 3 else ''
    expected = expected_by_word.get(word, '')
    if not expected: continue
    total += 1

    new_ok = matches_any(result_new, expected)
    mono_ipa = mono_by_word.get(word, '')
    mono_ok = matches_any(mono_ipa, expected)

    if new_ok:
        exact_new += 1
    else:
        errors.append((word, result_new, mono_ipa, expected, new_ok, mono_ok))
    if mono_ok and not new_ok:
        mono_matched += 1

print(f"=== BENCHMARK ===")
print(f"Total: {total}")
print(f"New engine exact: {exact_new}/{total} ({exact_new/total*100:.1f}%)")
print(f"Errors: {len(errors)}")
print(f"  of which monolith got right: {mono_matched}")
print(f"  monolith also wrong: {len(errors) - mono_matched}")
print()

# Classify errors
def classify(word, new_ipa, mono_ipa):
    n = norm(new_ipa)
    m = norm(mono_ipa)

    # Special word types
    if word.startswith('-') or word.startswith("'"): return 'suffix_entry'
    if ' ' in word: return 'multi_word'
    if word.startswith(('t-','d-','n-',"d'","t'","n'")): return 'prefix_boundary'
    if word[0].isupper(): return 'proper_noun'

    # Grammatical suffix patterns
    suffix_checks = [
        (r'fidh$', r'iː'), (r'fá$', r'hɑː'), (r'finn$', r'hən'),
        (r'fidís$', r'hə'), (r'fmid$', r'həm'), (r'feadh$', r'hə'),
        (r'faidh$', r'hə'), (r'igh$', r'iː'), (r'aí$', r'iː'),
        (r'adh$', r'uː'), (r'aidh$', r'iː'), (r'aimid$', r'əm'),
        (r'aíonn$', r'iː'), (r'igí$', r'ɪɟ'), (r'imis$', r'ɪm'),
        (r'ímid$', r'iːm'), (r'í$', r'iː'), (r'idís$', r'iːʃ'),
        (r'inn$', r'ən'), (r'ithe$', r'ɪh'), (r'ítear$', r'iːt'),
        (r'óidh$', r'oː'), (r'óinn$', r'oː'), (r'ófá$', r'oː'),
        (r'óimis$', r'oː'), (r'óimid$', r'oː'),
        (r'eoinn$', r'oː'), (r'eoidh$', r'oː'),
    ]
    for pat, vowel in suffix_checks:
        if re.search(pat, word) and vowel in m and vowel not in n:
            return f'suffix_{pat[1:-1]}'

    # Vowel quality
    pairs = [
        ('ɪ', 'ə', 'ɪ_to_ə'), ('a', 'ə', 'a_to_ə'), ('ə', 'a', 'ə_to_a'),
        ('ɔ', 'ə', 'ɔ_to_ə'), ('ɛ', 'ə', 'ɛ_to_ə'), ('ʊ', 'ɪ', 'ʊ_to_ɪ'),
        ('ɪ', 'ʊ', 'ɪ_to_ʊ'), ('a', 'ɪ', 'a_to_ɪ'), ('ə', 'ɪ', 'ə_to_ɪ'),
        ('ɔ', 'ʊ', 'ɔ_to_ʊ'), ('ʊ', 'ə', 'ʊ_to_ə'),
    ]
    for mono_v, new_v, label in pairs:
        if mono_v in m and new_v in n and mono_v not in n and new_v not in m:
            return f'v_{label}'

    # Diphthongs
    dips = ['au', 'ai', 'əu', 'əi', 'iə', 'uə']
    for d in dips:
        if d in m and d not in n: return f'diphthong_{d}'

    # Long vowel shortened
    lv_pairs = [('iː', 'ɪ'), ('uː', 'ʊ'), ('eː', 'ə'), ('oː', 'ɔ'), ('aː', 'a')]
    for l, s in lv_pairs:
        if l in m and s in n and l not in n: return f'long_{l[:2]}_to_{s}'

    # Glides
    if 'j' in m and 'j' not in n: return 'missing_j_glide'
    if 'j' not in m and 'j' in n: return 'extra_j_glide'
    if 'w' in m and 'w' not in n: return 'missing_w_glide'
    if 'w' not in m and 'w' in n: return 'extra_w_glide'

    # Consonant differences
    if 'ç' in m and 'ç' not in n: return 'missing_ç'
    if 'x' in m and 'x' not in n: return 'missing_x'

    # Length differences
    if len(m) > len(n) + 1: return 'new_shorter'
    if len(n) > len(m) + 1: return 'new_longer'

    return 'other'

print("=== ERROR CATEGORIES ===")
counter = Counter()
for word, new_ipa, mono_ipa, exp, n_ok, m_ok in errors:
    cat = classify(word, new_ipa, mono_ipa)
    counter[cat] += 1

for cat, count in counter.most_common(50):
    print(f"  {cat:30s}: {count:5d} ({count/len(errors)*100:.1f}%)")

# Show examples from top 10 categories
print(f"\n=== EXAMPLE ERRORS (top categories) ===")
seen = set()
for cat, _ in counter.most_common(10):
    shown = 0
    for word, new_ipa, mono_ipa, exp, n_ok, m_ok in errors:
        c = classify(word, new_ipa, mono_ipa)
        if c == cat and shown < 2:
            print(f"\n  [{cat}] {word}")
            print(f"    NEW: {new_ipa}")
            print(f"    MONO: {mono_ipa[:60]}")
            print(f"    EXP: {first_variant(exp)[:60]}")
            shown += 1
