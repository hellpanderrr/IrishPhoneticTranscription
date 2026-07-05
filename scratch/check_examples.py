import csv

def check_examples():
    words_to_check = {
        'do', 'fheadh', '-aigh', 'fheadha', '-igh', 'ibh', 'gach uile', 
        'amharc', 'abhac', 'ngabha', 'gabhaidh', 'agaibh', 'umhal',
        'éireoidh', 'i gceann', 'oighear', 'feadha', 'cad chuige',
        'bhur', 'n-ubh', '-fidh', 'ex', 'faigh', 'meá', 'aici',
        'Ard-Fheis', 'feadh', '-ithe', 'libh', 'uainn', 'téigh',
        'leamh', 'aige', 'le haghaidh', '-fas', 'comh', 'nimh',
        'bhfeadh', 'ardfhear', 'inniu', '-finn', 'seabhac', 'feighil', 'Laighin',
        'dearg', 'searbh', 'dealbh', 'pleidhc', 'd\'ith', 'b\'fhearr', 'Aodh', 'Eochaidh'
    }

    found = []
    with open('../errors.csv', encoding='utf-8') as f:
        reader = csv.DictReader(f, delimiter='\t')
        for row in reader:
            w = row['word'].strip()
            if w in words_to_check or any(w.endswith(suf) for suf in ['-fidh', '-fas', '-igh', '-aigh', '-tha']):
                found.append(f"{w}: got={row['got']}, exp={row['expected']}")

    for f in found[:50]:
        print(f)
    print(f'Total matches found: {len(found)}')

if __name__ == '__main__':
    import sys
    sys.stdout.reconfigure(encoding='utf-8')
    check_examples()
