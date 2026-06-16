"""Deeper error analysis on fresh new_results.csv."""
import csv, sys, io, re
from collections import Counter

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

def load_csv(path, delimiter=','):
    with open(path, 'r', encoding='utf-8-sig') as f:
        return list(csv.reader(f, delimiter=delimiter))

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
new_rows = load_csv(f'{base}/repo/new_results.csv', delimiter='\t')[1:]
mono_rows = load_csv(f'{base}/results.csv')[1:]

expected_by = {r[0]: r[2] for r in connacht if len(r) > 2}
mono_by = {r[0]: r[3] for r in mono_rows if len(r) > 3}

# Find all errors, categorize deeply
errors = []
for r in new_rows:
    if len(r) < 4: continue
    w, n_ipa = r[0], r[3]
    exp = expected_by.get(w)
    if not exp: continue
    m_ipa = mono_by.get(w, '')
    if not m_ipa: continue
    if not matches_any(n_ipa, exp):
        errors.append((w, n_ipa, m_ipa, exp, matches_any(m_ipa, exp)))

print(f"Total errors: {len(errors)}")
print(f"  Monolith correct on these: {sum(1 for *_,m_ok in errors if m_ok)}")
print(f"  Monolith also wrong: {sum(1 for *_,m_ok in errors if not m_ok)}")
print()

# Deep categorize
def get_vowels(s):
    """Extract vowel phonemes (including diphthongs)."""
    return re.findall('[əaɪɛɔʊiu]ː?|[əiəuauaiɔiʊiiəuə]', s)

def stress_correctness(n, exp):
    """Check if stress placement matches expected."""
    n_stress = [(i, c) for i,c in enumerate(n) if c in 'ˈˌ']
    e_stress = [(i, c) for i,c in enumerate(exp) if c in 'ˈˌ']
    return len(n_stress) == len(e_stress)

cats = Counter()
examples = {}

for w, n, m, exp, m_ok in errors:
    nn = norm(n)
    ne = norm(exp)

    # 1. Multi-word phrases
    if ' ' in w:
        cats['multi_word'] += 1
        continue
    # 2. Proper nouns
    if w[0].isupper():
        cats['proper_noun'] += 1
        continue
    # 3. Prefix forms
    if w.startswith(('t-','d-','n-',"d'","t'","n'")):
        cats['prefix_boundary'] += 1
        continue
    # 4. Suffix entries
    if w.startswith(('-', "'", '—')):
        cats['suffix_entry'] += 1
        continue

    # Remove (ə) and other optional notation from expected
    ne_clean = re.sub(r'\([^)]*\)', '', ne)

    # 5. Stress position differences that cause mismatch
    # Check if stripped (remove stress marks) versions match
    if nn == ne_clean or nn == ne:
        cats['stress_only'] += 1
        continue

    # 6. Long vowel / diphthong in expected but short in result
    exp_vowels = get_vowels(ne)
    new_vowels = get_vowels(nn)

    # 7. Check ç vs h difference
    key = None
    if 'ç' in ne and 'ç' not in nn:
        key = 'missing_ç'; cats[key] += 1
    elif 'ç' not in ne and 'ç' in nn:
        key = 'extra_ç'; cats[key] += 1
    elif 'x' in ne and 'x' not in nn:
        key = 'missing_x'; cats[key] += 1
    elif 'x' not in ne and 'x' in nn:
        key = 'extra_x'; cats[key] += 1
    elif 'j' in ne and 'j' not in nn:
        key = 'missing_j_glide'; cats[key] += 1
    elif 'j' not in ne and 'j' in nn:
        key = 'extra_j_glide'; cats[key] += 1
    elif 'w' in ne and 'w' not in nn:
        key = 'missing_w_glide'; cats[key] += 1
    elif 'w' not in ne and 'w' in nn:
        key = 'extra_w_glide'; cats[key] += 1
    else:
        # Check for specific vowel quality differences
        for old_v, new_v, label in [
            ('ɪ', 'ə', 'v_ɪ_to_ə'), ('a', 'ə', 'v_a_to_ə'),
            ('ə', 'ɪ', 'v_ə_to_ɪ'), ('ə', 'a', 'v_ə_to_a'),
            ('ɔ', 'ə', 'v_ɔ_to_ə'), ('ɪ', 'ʊ', 'v_ɪ_to_ʊ'),
            ('ʊ', 'ɪ', 'v_ʊ_to_ɪ'), ('a', 'ɪ', 'v_a_to_ɪ'),
            ('e', 'ɪ', 'v_e_to_ɪ'), ('ɛ', 'ə', 'v_ɛ_to_ə'),
            ('ɔ', 'ʊ', 'v_ɔ_to_ʊ'),
        ]:
            if old_v in ne and new_v in nn:
                cats[label] += 1
                key = label
                break

        if not key:
            # Check length differences
            if len(nn) > len(ne) + 2:
                key = 'new_longer'; cats[key] += 1
            elif len(ne) > len(nn) + 2:
                key = 'new_shorter'; cats[key] += 1
            else:
                key = 'other'; cats[key] += 1

    # Store examples
    if key not in examples:
        examples[key] = []
    if len(examples[key]) < 5:
        examples[key].append((w, n, ne[:60]))

print("=== ERROR CATEGORIES (fresh) ===")
for cat, count in cats.most_common(30):
    print(f"  {cat:25s}: {count:5d} ({count/len(errors)*100:.1f}%)")

print("\n=== 'OTHER' EXAMPLES ===")
for w, n, e in examples.get('other', [])[:10]:
    print(f"  {w:20s} NEW: {n:40s} EXP: {e}")

# Focus on multi_word - show examples
print("\n=== MULTI-WORD EXAMPLES ===")
for w, n, m, exp, m_ok in errors:
    if ' ' in w:
        nm = norm(m)
        nn = norm(n)
        ne = norm(exp)
        # Show cases where monolith is close to expected
        if abs(len(nm) - len(ne)) < abs(len(nn) - len(ne)):
            print(f"  {w:25s} NEW: {n:35s} MONO: {m:35s} EXP: {ne[:50]}")

# Check sonorant polarization differences
print("\n=== n̪ˠ/nʲ/lˠ/lʲ/rˠ/rʲ IN ERRORS ===")
son_count = 0
for w, n, m, exp, m_ok in errors:
    nn = norm(n)
    ne = norm(exp)
    for marker in ['l̠', 'lʲ', 'lˠ', 'n̪ˠ', 'nʲ', 'ɾˠ', 'ɾʲ']:
        if marker in ne and marker not in nn:
            son_count += 1
            break
        if marker not in ne and marker in nn:
            son_count += 1
            break
print(f"  Sonorant marker mismatches: ~{son_count}")
