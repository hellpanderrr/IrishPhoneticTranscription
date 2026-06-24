# -*- coding: utf-8 -*-
import sys
sys.stdout.reconfigure(encoding='utf-8')

def add_ref(filepath, old_text, new_text):
    with open(filepath, 'r', encoding='utf-8') as fh:
        content = fh.read()
    if old_text in content:
        content = content.replace(old_text, new_text, 1)
        with open(filepath, 'w', encoding='utf-8') as fh:
            fh.write(content)
        print(f'  OK: {filepath}')
    else:
        print(f'  WARN: not found in {filepath}')

# ========== pass 09b_vowel_adjunct.lua ==========
f = 'passes/09b_vowel_adjunct.lua'
with open(f, 'r', encoding='utf-8') as fh:
    lines = fh.readlines()
old = ''.join(lines[:5])
new = ('-- Pass 9b: Resolve vowel + mutated fricative adjuncts.\n'
    '-- Runs after consonants (#9) but before vowels (#10).\n'
    '-- Hickey §2.6.3: In certain vowel + bh/mh sequences, the fricative\n'
    '-- vocalizes and appends an offglide to the vowel: e.g. -ámh -> [ɑːiː],\n'
    '-- -éimh -> [eːiː]. The fricative is silenced.\n'
    '-- Fuaimeanna na Gaeilge §4.3: Labial fricative vocalization in codas.\n'
    '-- This must run AFTER consonants resolve so that silhouette consonants\n'
    '-- (like mh->vʲ) are detected, then silenced with their iː appended.')
add_ref(f, old, new)

# ========== pass 10_vowels.lua ==========
f = 'passes/10_vowels.lua'
with open(f, 'r', encoding='utf-8') as fh:
    lines = fh.readlines()
old = ''.join(lines[:4])
new = ('-- Pass #10: Resolve vowel tokens to IPA.\n'
    '-- Dialect-aware via context.dialect.\n'
    '-- Hickey §1.3: Irish vowel system has 5 short vowels /a, e, i, o, u/\n'
    '-- and 5 long vowels /aː, eː, iː, oː, uː/, plus diphthongs.\n'
    '-- Hickey §1.4: Diphthong system: ai, oi, ui, ea, eo, io, ua, ia.\n'
    '-- Fuaimeanna na Gaeilge Ch.5: Detailed vowel descriptions per dialect.\n'
    '-- Handles short/long/diphthong mappings plus contextual allophony.')
add_ref(f, old, new)

# ========== pass 11_unstressed_reduction.lua ==========
f = 'passes/11_unstressed_reduction.lua'
with open(f, 'r', encoding='utf-8') as fh:
    lines = fh.readlines()
old = ''.join(lines[:3])
new = ('-- Pass #11: Reduce unstressed short vowels to schwa.\n'
    '-- Hickey §3.2: Unstressed short vowels reduce to [ə] in Irish.\n'
    '-- Long vowels (with ː) are never reduced. This is a fundamental\n'
    '-- feature of Irish prosody: only stressed syllables retain full vowel\n'
    '-- quality. Fuaimeanna na Gaeilge §5.4: Vowel reduction in unstressed\n'
    '-- syllables. Reduces all short vowels to [ə] in unstressed positions.')
add_ref(f, old, new)

# ========== pass 12_epenthesis.lua ==========
f = 'passes/12_epenthesis.lua'
with open(f, 'r', encoding='utf-8') as fh:
    lines = fh.readlines()
old = ''.join(lines[:4])
new = ('-- Pass #12: Epenthesis (Svarabhakti vowel insertion).\n'
    '-- Hickey §2.9: Svarabhakti (epenthesis) inserts a short vowel [ə]\n'
    '-- between heterorganic sonorant + voiced obstruent clusters when the\n'
    '-- preceding vowel is short and stressed. Examples: fearb -> [fʲɛɾˠəbˠ],\n'
    '-- doras -> [d̪ˠɔɾˠəsˠ]. Fuaimeanna na Gaeilge §5.6: Vowel insertion\n'
    '-- in consonant clusters. NOT restricted to monosyllables.')
add_ref(f, old, new)

# ========== pass 13_sonorants.lua ==========
f = 'passes/13_sonorants.lua'
with open(f, 'r', encoding='utf-8') as fh:
    lines = fh.readlines()
old = ''.join(lines[:9])
new = ('-- Pass #13: Sonorant diacritics and geminates.\n'
    '-- Hickey §2.7: Sonorant allophony in Irish.\n'
    '-- Hickey §2.7.1: l and n have 4 allophones each based on position:\n'
    '--   broad + before_cons -> dental [l̪ˠ, n̪ˠ]\n'
    '--   broad + before_vowel/end -> velarized [lˠ, nˠ]\n'
    '--   slender + before_cons -> postalveolar [l̠ʲ, n̠ʲ]\n'
    '--   slender + before_vowel/end -> palatalized [lʲ, nʲ]\n'
    '-- Hickey §2.7.2: Geminate sonorants (ll, nn, rr) are lengthened and\n'
    '-- take the dental/postalveolar allophone. The second element is silenced.\n'
    '-- Fuaimeanna na Gaeilge §5.5: Detailed sonorant allophony with examples.\n'
    '-- 2. Handle geminate sonorants (ll, nn, rr, mm): silence second, adjust first.\n'
    '-- 3. Vowel lengthening before geminate sonorants in monosyllables.\n'
    '-- Runs after vowel resolution (#12) so vowel phonemes are final.')
add_ref(f, old, new)

# ========== pass 14_final_cleanup.lua ==========
f = 'passes/14_final_cleanup.lua'
with open(f, 'r', encoding='utf-8') as fh:
    lines = fh.readlines()
old = ''.join(lines[:5])
new = ('-- Pass #14: Final cleanup and diacritics.\n'
    '-- Hickey §2.6.2: Final lenited fricatives th, dh, gh are silent.\n'
    '-- Hickey §2.6.3: Devoicing rules in coda position.\n'
    '-- 1. Remove final silent mutated fricatives (th, dh, gh)\n'
    '-- 2. Strip trailing ç/ɣ/h from vowels that have a long phon\n'
    '-- 3. Unstressed final devoicing: slender g [ɟ] -> [c] (Hickey §2.6.3)\n'
    '-- 4. ch + s -> tʃ sandhi (assimilation, Hickey §2.4)\n'
    '-- 5. Devoice b/d/g before th: b+th->p, d+th->t, g+th->k (Hickey §2.6.3)\n'
    '-- 6. Palatal C before back rounded vowel -> j-glide insertion (Hickey §2.6.3)')
add_ref(f, old, new)

print('Passes 09b, 10, 11, 12, 13, 14 done')
