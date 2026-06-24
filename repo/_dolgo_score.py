import subprocess, sys, csv
sys.path.insert(0, r"C:\Users\hellpanderrr\AppData\Roaming\Python\Python311\site-packages")
from panphon.distance import Distance
d = Distance()

# Read results.csv for comparison
old_dolgo_sum, old_total = 0, 0
with open(r"F:\projects\transcription\wiktionary_ipa_phoneme_lexicons\irish\repo\..\results.csv") as f:
    for row in csv.DictReader(f):
        old_dolgo_sum += float(row["dolgo"])
        old_total += 1
old_avg = old_dolgo_sum / old_total if old_total else 0

# Parse benchmark TSV from stdin (piped from bench_run.lua output)
total, dolgo_sum = 0, 0.0
match_count = 0
norm_lev_sum = 0.0
for line in sys.stdin:
    line = line.strip()
    if not line or line.startswith("Exact:"):
        continue  # skip bench_run.lua footer
    parts = line.split("\t")
    if len(parts) < 4:
        continue
    # parts: word, got, exp_field, exact
    got = parts[1]
    exp_field = parts[2]
    exact = parts[3]
    total += 1
    if exact == "true":
        match_count += 1
    # Take first variant for DOLGO
    exp = exp_field.split(",")[0].strip()
    score = d.dolgo_prime_distance_div_maxlen(got, exp)
    # DOLGO stored as 1.0 - score (higher = better, 1.0 = perfect)
    dolgo_sum += (1.0 - score)
    # Norm Lev: best Levenshtein across all variants
    best_lev = None
    for variant in exp_field.split(","):
        v = variant.strip()
        # simple Lev comparison (character level)
        lv = 0
        if len(got) != len(v):
            # fallback to full lev
            m, n = len(got), len(v)
            v0, v1 = list(range(n + 1)), [0] * (n + 1)
            for i in range(1, m + 1):
                v1[0] = i
                for j in range(1, n + 1):
                    cost = 0 if got[i - 1] == v[j - 1] else 1
                    v1[j] = min(v1[j - 1] + 1, v0[j] + 1, v0[j - 1] + cost)
                v0, v1 = v1, v0
            lv = v0[n]
        else:
            lv = sum(1 for a, b in zip(got, v) if a != b)
        if best_lev is None or lv < best_lev:
            best_lev = lv
    max_len = max(len(got), len(exp))
    norm_lev_sum += (1.0 - best_lev / max_len) if max_len > 0 else 1.0

avg_dolgo = dolgo_sum / total if total else 0
avg_norm_lev = norm_lev_sum / total if total else 0
exact_pct = match_count / total * 100 if total else 0

print(f"\nDOLGO avg (1.0=perfect): {avg_dolgo:.4f}  (old results.csv: {old_avg:.4f})")
print(f"Exact: {match_count}/{total} ({exact_pct:.2f}%)  Norm Lev: {avg_norm_lev*100:.2f}%")
