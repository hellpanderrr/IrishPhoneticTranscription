import csv
from collections import Counter
import difflib
import sys

def analyze():
    errors = []
    with open('../errors.csv', encoding='utf-8') as f:
        reader = csv.DictReader(f, delimiter='\t')
        for row in reader:
            got = row['got']
            exp = row['expected']
            
            # Find differences
            s = difflib.SequenceMatcher(None, got, exp)
            for tag, i1, i2, j1, j2 in s.get_opcodes():
                if tag == 'replace':
                    errors.append(f"{got[i1:i2]} -> {exp[j1:j2]}")
                elif tag == 'delete':
                    errors.append(f"{got[i1:i2]} -> (deleted)")
                elif tag == 'insert':
                    errors.append(f"(inserted) -> {exp[j1:j2]}")
                    
    c = Counter(errors)
    for k, v in c.most_common(50):
        print(f"{v}\t{k}")

if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    analyze()
