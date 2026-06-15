import csv
import unicodedata

def normalize(s):
    """Remove stress marks and normalize."""
    return s.replace('\u02C8', '').strip()

schwa_to_i = 0
total_mismatches = 0
schwa_examples = []

with open('F:/projects/transcription/wiktionary_ipa_phoneme_lexicons/irish/repo/results.csv', 'r', encoding='utf-8') as f:
    reader = csv.reader(f)
    next(reader)  # skip header
    for row in reader:
        if len(row) < 4:
            continue
        word, tags, ipa, result = row[0], row[1], row[2], row[3]
        if not ipa or not result:
            continue
        exp = normalize(ipa)
        got = normalize(result)
        if exp == got:
            continue
        total_mismatches += 1
        # Check if replacing schwa with ɪ would fix it
        exp_fixed = exp.replace('\u0259', '\u026A')
        if exp_fixed == got:
            schwa_to_i += 1
            if len(schwa_examples) < 10:
                schwa_examples.append((word, ipa, result))

print(f"Total mismatches (ignoring stress): {total_mismatches}")
print(f"Fixed by ə->ɪ: {schwa_to_i}")
print()
for w, e, g in schwa_examples:
    print(f"  {w}: exp={e} got={g}")
