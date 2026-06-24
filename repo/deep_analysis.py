"""Deeper error analysis: breakdown"other" category, monolith vs expected scores."""
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

# 1. Monolith scores vs expected IPA
mono_exact = 0
mono_total = 0
for r in mono_rows:
    if len(r) < 4: continue
    w, m_ipa = r[0], r[3]
    exp = expected_by.get(w)
    if not exp: continue
    mono_total += 1
    if matches_any(m_ipa, exp): mono_exact += 1
print(f"=== MONOLITH vs EXPECTED IPA ===")
print(f"Total: {mono_total}")
print(f"Exact: {mono_exact}/{mono_total} ({mono_exact/mono_total*100:.1f}%)")

# 2. Where monolith is right and new engine is wrong
print(f"\n=== WHERE MONOLITH IS RIGHT AND NEW ENGINE IS WRONG ===")
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

print(f"Words lost: {len(lost)}")
print()

# Analyze what causes these regressions
def deep_classify(w, n, m, e):
    nn = norm(n)
    nm = norm(m)

    # 1. Stress position difference
    def stress_pos(s):
        return [i for i,c in enumerate(s) if c in 'ˈˌ']
    sp_n = stress_pos(n)
    sp_m = stress_pos(m)
    if sp_n != sp_m:
        return 'stress_position'

    # 2. dh/gh vocalization (/j/ vs /ɣ/ vs silent)
    # Monolith often produces /j/ for broad dh/gh, new engine silences them
    if 'j' in nm and 'j' not in nn:
        return 'missing_j_from_vocalization'
    if 'ɣ' in nm and 'ɣ' not in nn:
        return 'missing_ɣ_from_vocalization'

    # 3. mh/bh/fh vocalization (/w/ vs /v/ vs /uː/)
    if 'w' in nm and 'w' not in nn:
        # monolith has /w/ that new engine lost - check if expected also has /w/
        if 'w' in norm(e):
            return 'missing_w_mh_bh_vocalization'

    # 4. Multiple consonant errors - check how many differ
    if len(nn) > len(nm) + 3:
        return 'new_much_longer'
    if len(nm) > len(nn) + 3:
        return 'mono_much_longer'

    # 5. Whole-word pattern mismatch
    # Initial consonant mutation
    if nn[:2] != nm[:2] and nn[:3] != nm[:3]:
        return 'initial_consonant_diff'

    # 6. Final syllable
    def last_vowel(s):
        m = re.search('[əaɪɛɔʊiu](?:ː)?$', s)
        return m.group(0) if m else ''
    lv_n = last_vowel(nn)
    lv_m = last_vowel(nm)
    if lv_n != lv_m:
        return f'final_vowel_{lv_m}_vs_{lv_n}'

    # 7. Diphthong vs vowel
    for d in ['əu', 'əi', 'au', 'ai', 'iu', 'ui', 'ei', 'ɛi', 'oi', 'iə', 'uə']:
        if d in nm and d not in nn and d not in norm(e):
            return f'diphthong_new_missing_{d}'
        if d not in nm and d in nn and d not in norm(e):
            return f'diphthong_new_extra_{d}'

    # 8. Broad/slender consonant polarity diff
    def sonorant_pattern(s):
        return [c for c in ['lˠ','lʲ','n̪ˠ','nʲ','ɾˠ','ɾʲ'] if c in s]
    sp_diff = [c for c in sonorant_pattern(nm) if c not in nn] + [c for c in sonorant_pattern(nn) if c not in nm]
    if sp_diff:
        return 'sonorant_polarity_' + '_'.join(sp_diff[:2])

    # 9. Length diff on non-final vowel
    def long_vowels(s):
        return re.findall('[aouei]ː', s)
    if long_vowels(nm) != long_vowels(nn):
        return 'long_vowel_mismatch'

    # 10. Unstressed vowel reduction pattern
    m_schwa = nn.count('ə')
    n_schwa = nm.count('ə')
    if abs(m_schwa - n_schwa) >= 2:
        return 'schwa_count_diff'

    # 11. h-insertion/aspiration
    h_count_m = nm.count('h')
    h_count_n = nn.count('h')
    diff = abs(h_count_m - h_count_n)
    if diff >= 1:
        return f'h_count_diff_{diff}'

    # 12. Glide pattern
    j_n, w_n = nn.count('j'), nn.count('w')
    j_m, w_m = nm.count('j'), nm.count('w')
    if (j_n > j_m + 1 or w_n > w_m + 1) and ' ' not in w:
        return 'new_extra_glide'
    if (j_m > j_n + 1 or w_m > w_n + 1) and ' ' not in w:
        return 'mono_extra_glide'

    # 13. č/š/tš/dž (borrowings)
    for ch in ['tʃ', 'dʒ', 'ʃ', 'ʒ', 't͡ʃ', 'd͡ʒ']:
        if (ch in nm and ch not in nn) or (ch in nn and ch not in nm):
            return 'borrowing_affricate'

    # 14. ç (slender ch) differences
    if 'ç' in nm and 'ç' not in nn: return 'missing_ç_slender_ch'

    return 'unclassified_other'

# Sample from top categories
deep_cats = Counter()
for w, n, m, e in lost[:1500]:
    deep_cats[deep_classify(w, n, m, e)] += 1

print("=== DEEP CATEGORIES (first 1500 lost words) ===")
for cat, count in deep_cats.most_common(30):
    print(f"  {cat:35s}: {count:5d} ({count/1500*100:.1f}%)")

# Show examples from top unclassified
print(f"\n=== UNCLASSIFIED EXAMPLES ===")
shown = 0
for w, n, m, e in lost:
    if deep_classify(w, n, m, e) == 'unclassified_other' and shown < 5:
        print(f"\n  {w}")
        print(f"    NEW:  {n}")
        print(f"    MONO: {m}")
        print(f"    EXP:  {norm(e)}")
        shown += 1

# Show monolith-gets-right examples from top categories
print(f"\n=== MONOLITH-RIGHT EXAMPLES ===")
for cat_name in ['missing_j_from_vocalization', 'missing_w_mh_bh_vocalization', 'missing_ç_slender_ch', 'diphthong_new_missing_əu']:
    print(f"\n--- {cat_name} ---")
    shown = 0
    for w, n, m, e in lost:
        if deep_classify(w, n, m, e) == cat_name and shown < 3:
            print(f"  {w}")
            print(f"    NEW:  {n}")
            print(f"    MONO: {m}")
            print(f"    EXP:  {norm(e)}")
            shown += 1

# Check the match scores for lost words
print(f"\n=== MONOLITH MATCH SCORE DISTRIBUTION (on its 1979 right answers) ===")
mono_scores = {}
for r in mono_rows:
    if len(r) > 4:
        try: mono_scores[r[0]] = float(r[4])
        except: pass

score_buckets = Counter()
for w, n, m, e in lost:
    sc = mono_scores.get(w, 0)
    bucket = int(sc / 10) * 10
    score_buckets[f"{bucket}-{bucket+9}"] += 1
for b in sorted(score_buckets.keys()):
    print(f"  mono score {b:>6}: {score_buckets[b]:5d}")
