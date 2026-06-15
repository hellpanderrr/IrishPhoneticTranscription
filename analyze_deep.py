import csv, sys, io, collections

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open('results.csv', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    rows = list(reader)

failures = [r for r in rows if float(r['dolgo']) < 0.8]

# ── 1. Stress mark false positives ────────────────────────────
# Expected has NO stress mark, engine ADDS one
extra_stress = [r for r in failures if 'ˈ' in r['results'] and 'ˈ' not in r['ipa'] and r['ipa'].strip()]
print(f'=== EXTRA STRESS MARK (expected no ˈ, got ˈ): {len(extra_stress)} cases ===')
for r in extra_stress[:30]:
    print(f"  {r['word']:<22} exp={r['ipa']:<28} got={r['results']}")

# ── 2. sh/th lenition: h vs ç confusion ──────────────────────
print()
sh_h_ç = [r for r in failures if ('h' in r['ipa'] and 'ç' in r['results']) or ('ç' in r['ipa'] and 'h' in r['results'])]
print(f'=== SH/TH LENITION h↔ç CONFUSION: {len(sh_h_ç)} cases ===')
for r in sh_h_ç[:30]:
    print(f"  {r['word']:<22} exp={r['ipa']:<28} got={r['results']}")

# ── 3. ó → uː nasal raising (strict) ─────────────────────────
print()
nasal_raise = [r for r in rows if float(r['dolgo']) < 1.0 and 'uː' in r['ipa'] and 'oː' in r['results'] and r['ipa'].strip()]
print(f'=== ó NOT RAISED TO uː (nasal raising miss): {len(nasal_raise)} cases ===')
for r in nasal_raise[:30]:
    print(f"  {r['word']:<22} exp={r['ipa']:<28} got={r['results']}")

# ── 4. Diphthong failures: expected ai/au, got something else ─
print()
diph_fail = [r for r in failures if ('ai' in r['ipa'] or 'au' in r['ipa']) and r['ipa'].strip()]
print(f'=== DIPHTHONG FAILURES (expected ai/au): {len(diph_fail)} cases ===')
for r in diph_fail[:30]:
    print(f"  {r['word']:<22} exp={r['ipa']:<28} got={r['results']}")

# ── 5. Empty expected IPA (csv data issue) ────────────────────
print()
empty_exp = [r for r in failures if not r['ipa'].strip()]
print(f'=== EMPTY EXPECTED IPA (data issue): {len(empty_exp)} cases ===')
for r in empty_exp[:15]:
    print(f"  {r['word']:<22} got={r['results']}")

# ── 6. Words where expected has multiple variants (comma-sep) ──
print()
multi_var = [r for r in rows if ',' in r['ipa'] and float(r['dolgo']) < 0.8]
print(f'=== MULTI-VARIANT EXPECTED, still failing: {len(multi_var)} cases ===')
for r in multi_var[:20]:
    print(f"  {r['word']:<22} exp={r['ipa'][:45]:<45} got={r['results']}")

# ── 7. Dentalization diacritic: ̪ (dental) differences ─────────
print()
dental_fail = [r for r in failures if '̪' in r['ipa'] and '̪' not in r['results'] and r['ipa'].strip()]
print(f'=== MISSING DENTAL DIACRITIC ̪: {len(dental_fail)} cases ===')
for r in dental_fail[:25]:
    print(f"  {r['word']:<22} exp={r['ipa']:<28} got={r['results']}")

# ── 8. Velarization differences ───────────────────────────────
print()
extra_vel = [r for r in failures if 'ˠ' not in r['ipa'] and 'ˠ' in r['results'] and r['ipa'].strip()]
print(f'=== EXTRA VELARIZATION ˠ added by engine: {len(extra_vel)} cases ===')
for r in extra_vel[:25]:
    print(f"  {r['word']:<22} exp={r['ipa']:<28} got={r['results']}")

# ── 9. ɾ vs r ─────────────────────────────────────────────────
print()
r_fail = [r for r in failures if 'ɾ' in r['ipa'] and 'ɾ' not in r['results'] and r['ipa'].strip()]
print(f'=== FLAP ɾ not produced (r instead): {len(r_fail)} cases ===')
for r in r_fail[:20]:
    print(f"  {r['word']:<22} exp={r['ipa']:<28} got={r['results']}")

# ── 10. n̪ˠ dental nasal ──────────────────────────────────────
print()
dental_n = [r for r in failures if 'n̪ˠ' in r['ipa'] and 'n̪ˠ' not in r['results'] and r['ipa'].strip()]
print(f'=== DENTAL NASAL n̪ˠ missing: {len(dental_n)} cases ===')
for r in dental_n[:20]:
    print(f"  {r['word']:<22} exp={r['ipa']:<28} got={r['results']}")
