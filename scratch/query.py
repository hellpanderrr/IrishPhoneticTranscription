import csv
import sys
sys.stdout.reconfigure(encoding='utf-8')
with open('../errors.csv', encoding='utf-8') as f:
    for row in csv.DictReader(f, delimiter='\t'):
        w = row['word'].strip()
        if w in ['gníomh', 'scríobh', 'lámh', 'Niamh', 'riamh', 'mol', 'gol', 'col', 'roimh', 'cruithneacht', 'staighre', 'aighneas']:
            print(f"{w}: got={row['got']} exp={row['expected']}")
