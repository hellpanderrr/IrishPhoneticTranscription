"""Analyze the two biggest error categories: stress_position and initial_consonant_diff."""
import csv, sys, io, re
from collections import Counter

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

def load_csv(path):
    with open(path, 'r', encoding='utf-8-sig') as f:
        return list(csv.reader(f))

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

base = r'F:\projects\transcription\wiktionary_ipa_phoneme_lexicons\irish'
connacht = load_csv(f'{base}/repo/data/connacht_only.csv')
new_rows = load_csv(f'{base}/repo/new_results.csv')[1:]
mono_rows = load_csv(f'{base}/results.csv')[1:]

expected_by = {r[0]: r[2] for r in connacht if len(r) > 2}
mono_by = {r[0]: r[3] for r in mono_rows if len(r) > 3}

# Build lost words list
lost = []
for r in new_rows:
    if len(r) < 4: continue
    w, n_ipa = r[0], r[3]
    exp = expected_by.get(w)
    if not exp: continue
    m_ipa = mono_by.get(w, '')
    if not m_ipa: continue
    new_ok = matches_any(n_ipa, exp)
    mono_ok = matches_any(m_ipa, exp)
    if mono_ok and not new_ok:
        lost.append((w, n_ipa, m_ipa, exp))

# 1. STRESS POSITION ANALYSIS
def stress_positions(s):
    """Return list of (offset, stress_type) for each stress mark."""
    positions = []
    for i, c in enumerate(s):
        if c in 'ˈˌ':
            positions.append((i, c))
    return positions

stress_examples = []
init_cons_examples = []

for w, n, m, e in lost:
    sp_n = stress_positions(n)
    sp_m = stress_positions(m)

    if sp_n != sp_m:
        n_stress_on = norm(n).strip()
        m_stress_on = norm(m).strip()

        # Categorize stress difference
        if not sp_n:
            stress_examples.append((w, n, m, e, 'new_no_stress'))
        elif not sp_m:
            stress_examples.append((w, n, m, e, 'mono_no_stress'))
        elif len(sp_n) < len(sp_m):
            stress_examples.append((w, n, m, e, 'new_fewer_stress'))
        elif len(sp_n) > len(sp_m):
            stress_examples.append((w, n, m, e, 'new_more_stress'))
        else:
            stress_examples.append((w, n, m, e, 'stress_different_position'))

    # Initial consonant diff
    n_norm = norm(n)
    m_norm = norm(m)
    if n_norm[:2] != m_norm[:2] and n_norm[:3] != m_norm[:3]:
        init_cons_examples.append((w, n, m, e, n_norm[:3], m_norm[:3]))

print(f"=== STRESS POSITION CATEGORIES ===")
stress_cats = Counter(s[-1] for s in stress_examples)
for cat, count in stress_cats.most_common():
    print(f"  {cat:30s}: {count:5d} ({count/len(stress_examples)*100:.1f}%)")

print(f"\n=== STRESS EXAMPLES (10 each) ===")
for cat in ['new_no_stress', 'new_fewer_stress', 'new_more_stress', 'mono_no_stress']:
    print(f"\n--- {cat} ---")
    shown = 0
    for w, n, m, e, c in stress_examples:
        if c == cat and shown < 5:
            print(f"  {w:20s} NEW: {n:40s} MONO: {m:40s}")
            shown += 1

print(f"\n=== INITIAL CONSONANT DIFF EXAMPLES (15) ===")
for w, n, m, e, n_pref, m_pref in init_cons_examples[:15]:
    print(f"  {w:20s} PREF: {m_pref:>3s}->{n_pref:<3s}  | NEW: {n:40s} MONO: {m:40s}")

# 2. Check initial consonant mutation patterns
print(f"\n=== INITIAL CONSONANT MUTATION WORD TYPES ===")
mut_types = Counter()
for w, n, m, e, n_pref, m_pref in init_cons_examples:
    # Check if monolith does lenition/eclipsis correctly
    if m_pref[:1] in 'bchdfgmpt' and n_pref[:1] != m_pref[:1]:
        mut_types[f'mono_{m_pref[:3]}_new_{n_pref[:3]}'] += 1
    elif n_pref[:1] in 'bchdfgmpt' and m_pref[:1] != n_pref[:1]:
        mut_types[f'mono_{m_pref[:3]}_new_{n_pref[:3]}'] += 1
    else:
        mut_types[f'mono_{m_pref[:3]}_new_{n_pref[:3]}'] += 1

for cat, count in mut_types.most_common(20):
    print(f"  {cat:30s}: {count}")

# 3. What words are in "new_fewer_stress" (new engine missing secondary stress)?
print(f"\n=== NEW FEWER STRESS — mult-word check ===")
multi = sum(1 for w, n, m, e, c in stress_examples if c == 'new_fewer_stress' and ' ' in w)
single = sum(1 for w, n, m, e, c in stress_examples if c == 'new_fewer_stress' and ' ' not in w)
print(f"  multi-word: {multi}, single-word: {single}")
