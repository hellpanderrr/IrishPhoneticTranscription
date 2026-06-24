# -*- coding: utf-8 -*-
import sys
sys.stdout.reconfigure(encoding='utf-8')

def add_ref(filepath, old_text, new_text):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    if old_text in content:
        content = content.replace(old_text, new_text, 1)
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f'  OK: {filepath}')
    else:
        print(f'  WARN: not found in {filepath}')

# ========== pass 09_consonants.lua ==========
f = 'passes/09_consonants.lua'
with open(f, 'r', encoding='utf-8') as fh:
    c = fh.read()

# Add header reference
old_h = '-- Pass #9: Resolve consonant tokens to IPA.\n-- Handles broad/slender alternation and voiceless sonorants.'
new_h = ('-- Pass #9: Resolve consonant tokens to IPA.\n'
    '-- Handles broad/slender alternation and voiceless sonorants.\n'
    '-- Hickey §2.2: Irish has a 2-way consonant system: broad (velarized [ˠ])\n'
    '-- vs slender (palatalized [ʲ]) for all places of articulation.\n'
    '-- Fuaimeanna na Gaeilge Ch.2: Full consonant inventory with IPA symbols.\n'
    '-- Hickey §2.5: Voiceless sonorants (l̥, n̥, r̥, m̥) occur after voiceless\n'
    '-- stops and fricatives (e.g. after p, t, c, s, f).')
add_ref(f, old_h, new_h)

# bh/mh resolution
old_bh = '      if token.ortho == "bh" or token.ortho == "mh" then\n        if token.palatal == true then\n          token.phon = "vʲ"'
new_bh = ('      -- Hickey §2.6.2: Lenited b/m -> [v] in all positions. Broad bh/mh -> [vˠ] or [w],\n'
    '      -- slender -> [vʲ]. Word-initial broad bh/mh: [vˠ] only before broad r/l + short a.\n'
    '      -- Fuaimeanna na Gaeilge §4.3: Lenited labial realizations.\n'
    '      if token.ortho == "bh" or token.ortho == "mh" then\n'
    '        if token.palatal == true then\n'
    '          token.phon = "vʲ"')
add_ref(f, old_bh, new_bh)

# ch resolution
old_ch = '      elseif token.ortho == "ch" then\n        if token.palatal == true then\n          -- Hickey: slender ch after front vowel ortho'
new_ch = ('      elseif token.ortho == "ch" then\n'
    '        -- Hickey §2.6.2: Lenited c -> [x] (broad) or [ç] (slender).\n'
    '        -- Slender ch before back rounded vowels -> ç (Hickey §2.6.3).\n'
    '        -- Fuaimeanna na Gaeilge §4.4: Lenited velar/uvular fricatives.\n'
    '        if token.palatal == true then\n'
    '          -- Slender ch: ç after front vowels, h after back vowels.\n')
add_ref(f, old_ch, new_ch)

# sh resolution
old_sh = '      elseif token.ortho == "sh" then\n        -- Connacht: slender sh before back rounded vowel'
new_sh = ('      elseif token.ortho == "sh" then\n'
    '        -- Hickey §2.6.2: Lenited s -> [h] in all positions.\n'
    '        -- Connacht: slender sh before back rounded vowel -> ç.\n'
    '        -- Fuaimeanna na Gaeilge §4.4: Lenited sibilant realizations.\n')
add_ref(f, old_sh, new_sh)

# th resolution
old_th = '      elseif token.ortho == "th" then\n        if i == #tokens then\n          token.phon = ""'
new_th = ('      elseif token.ortho == "th" then\n'
    '        -- Hickey §2.6.2: Lenited t -> [h] in all positions.\n'
    '        -- Final th is silent. Medial th -> [h].\n'
    '        -- Fuaimeanna na Gaeilge §4.4: Lenited dental fricatives.\n'
    '        if i == #tokens then\n'
    '          token.phon = ""')
add_ref(f, old_th, new_th)

# dh/gh resolution
old_dh = '      elseif token.ortho == "dh" or token.ortho == "gh" then\n        local next = tokens[i + 1]\n        if i == #tokens then\n          -- Word-final dh/gh: silent'
new_dh = ('      elseif token.ortho == "dh" or token.ortho == "gh" then\n'
    '        -- Hickey §2.6.2: Lenited d/g -> [ɣ] (broad) or [j] (slender).\n'
    '        -- Word-final dh/gh is silent. Fuaimeanna na Gaeilge §4.3.\n'
    '        local next = tokens[i + 1]\n'
    '        if i == #tokens then\n'
    '          -- Word-final dh/gh: silent')
add_ref(f, old_dh, new_dh)

# ph resolution
old_ph = '      elseif token.ortho == "ph" then\n        token.phon = S.palatal_consonant(token, "fʲ", "fˠ")'
new_ph = ('      elseif token.ortho == "ph" then\n'
    '        -- Hickey §2.6.2: Lenited p -> [fˠ] (broad) or [fʲ] (slender).\n'
    '        -- Fuaimeanna na Gaeilge §4.3: Lenited labiodental fricatives.\n'
    '        token.phon = S.palatal_consonant(token, "fʲ", "fˠ")')
add_ref(f, old_ph, new_ph)

# s before p/t/k
old_s = '      elseif token.ortho == "s" then\n        -- s before p/t/k/m: check polarity.'
new_s = ('      elseif token.ortho == "s" then\n'
    '        -- Hickey §2.2.3: s before p/t/k: broad following -> [sˠ],\n'
    '        -- slender following -> [ʃ]. Before m: always [sˠ].\n'
    '        -- Fuaimeanna na Gaeilge §2.5: Sibilant assimilation.\n'
    '        -- s before p/t/k/m: check polarity.')
add_ref(f, old_s, new_s)

# c resolution
old_c = '      elseif token.ortho == "c" then\n        token.phon = S.palatal_consonant(token, "c", "k")'
new_c = ('      elseif token.ortho == "c" then\n'
    '        -- Hickey §2.2.1: c -> [k] (broad) or [c] (slender).\n'
    '        -- Fuaimeanna na Gaeilge §2.1: Plosive inventory.\n'
    '        token.phon = S.palatal_consonant(token, "c", "k")')
add_ref(f, old_c, new_c)

# g resolution
old_g = '      elseif token.ortho == "g" then\n        token.phon = S.palatal_consonant(token, "ɟ", "ɡ")'
new_g = ('      elseif token.ortho == "g" then\n'
    '        -- Hickey §2.2.1: g -> [ɡ] (broad) or [ɟ] (slender).\n'
    '        -- Fuaimeanna na Gaeilge §2.1: Plosive inventory.\n'
    '        token.phon = S.palatal_consonant(token, "ɟ", "ɡ")')
add_ref(f, old_g, new_g)

# t resolution
old_t = '      elseif token.ortho == "t" then\n        token.phon = S.palatal_consonant(token, "tʲ", "t̪ˠ")'
new_t = ('      elseif token.ortho == "t" then\n'
    '        -- Hickey §2.2.2: t -> [t̪ˠ] (broad/dental) or [tʲ] (slender).\n'
    '        -- Fuaimeanna na Gaeilge §2.1: Dental vs alveolar distinction.\n'
    '        token.phon = S.palatal_consonant(token, "tʲ", "t̪ˠ")')
add_ref(f, old_t, new_t)

# d resolution
old_d = '      elseif token.ortho == "d" then\n        token.phon = S.palatal_consonant(token, "dʲ", "d̪ˠ")'
new_d = ('      elseif token.ortho == "d" then\n'
    '        -- Hickey §2.2.2: d -> [d̪ˠ] (broad/dental) or [dʲ] (slender).\n'
    '        -- Fuaimeanna na Gaeilge §2.1: Dental vs alveolar distinction.\n'
    '        token.phon = S.palatal_consonant(token, "dʲ", "d̪ˠ")')
add_ref(f, old_d, new_d)

# n resolution
old_n = '      elseif token.ortho == "n" then\n        if token.is_voiceless then'
new_n = ('      elseif token.ortho == "n" then\n'
    '        -- Hickey §2.2.4: n -> [n̪ˠ] (broad/dental) or [nʲ] (slender).\n'
    '        -- Voiceless n̥ after voiceless stops (Hickey §2.5).\n'
    '        -- Fuaimeanna na Gaeilge §2.3: Nasal inventory.\n'
    '        if token.is_voiceless then')
add_ref(f, old_n, new_n)

# ng resolution
old_ng = '      elseif token.ortho == "ng" then\n        token.phon = S.palatal_consonant(token, "ɲ", "ŋ")'
new_ng = ('      elseif token.ortho == "ng" then\n'
    '        -- Hickey §2.3: ng -> [ŋ] (broad) or [ɲ] (slender).\n'
    '        -- Fuaimeanna na Gaeilge §2.3: Velar/palatal nasal distinction.\n'
    '        token.phon = S.palatal_consonant(token, "ɲ", "ŋ")')
add_ref(f, old_ng, new_ng)

# l resolution
old_l = '      elseif token.ortho == "l" then\n        if token.is_voiceless then\n          token.phon = S.palatal_consonant(token, "l̥", "lˠ")\n        else\n          token.phon = S.palatal_consonant(token, "lʲ", "lˠ")'
new_l = ('      elseif token.ortho == "l" then\n'
    '        -- Hickey §2.7.1: l -> [lˠ] (broad/velarized) or [lʲ] (slender).\n'
    '        -- Voiceless l̥ after voiceless stops (Hickey §2.5).\n'
    '        -- Fuaimeanna na Gaeilge §5.5: Lateral approximant allophony.\n'
    '        if token.is_voiceless then\n'
    '          token.phon = S.palatal_consonant(token, "l̥", "lˠ")\n'
    '        else\n'
    '          token.phon = S.palatal_consonant(token, "lʲ", "lˠ")')
add_ref(f, old_l, new_l)

# r resolution
old_r = '      elseif token.ortho == "r" then\n        -- Connacht: r before dental consonants'
new_r = ('      elseif token.ortho == "r" then\n'
    '        -- Hickey §2.7.3: r -> [ɾˠ] (broad/tap) or [ɾʲ] (slender/tap).\n'
    '        -- Connacht: r before dental consonants stays broad.\n'
    '        -- Fuaimeanna na Gaeilge §5.5: Rhotic allophony.\n')
add_ref(f, old_r, new_r)

# f resolution
old_f = '      elseif token.ortho == "f" then\n        -- Future-tense suffix'
new_f = ('      elseif token.ortho == "f" then\n'
    '        -- Hickey §2.2.5: f -> [fˠ] (broad) or [fʲ] (slender).\n'
    '        -- Future-tense suffix')
add_ref(f, old_f, new_f)

# b resolution
old_b = '      elseif token.ortho == "b" then\n        token.phon = S.palatal_consonant(token, "bʲ", "bˠ")'
new_b = ('      elseif token.ortho == "b" then\n'
    '        -- Hickey §2.2.1: b -> [bˠ] (broad) or [bʲ] (slender).\n'
    '        -- Fuaimeanna na Gaeilge §2.1: Plosive inventory.\n'
    '        token.phon = S.palatal_consonant(token, "bʲ", "bˠ")')
add_ref(f, old_b, new_b)

# m resolution
old_m = '      elseif token.ortho == "m" then\n        if token.is_voiceless then\n          token.phon = S.palatal_consonant(token, "m̥", "mˠ")\n        else\n          token.phon = S.palatal_consonant(token, "mʲ", "mˠ")'
new_m = ('      elseif token.ortho == "m" then\n'
    '        -- Hickey §2.2.4: m -> [mˠ] (broad) or [mʲ] (slender).\n'
    '        -- Voiceless m̥ after voiceless stops (Hickey §2.5).\n'
    '        -- Fuaimeanna na Gaeilge §2.3: Nasal inventory.\n'
    '        if token.is_voiceless then\n'
    '          token.phon = S.palatal_consonant(token, "m̥", "mˠ")\n'
    '        else\n'
    '          token.phon = S.palatal_consonant(token, "mʲ", "mˠ")')
add_ref(f, old_m, new_m)

# p resolution
old_p = '      elseif token.ortho == "p" then\n        token.phon = S.palatal_consonant(token, "pʲ", "pˠ")'
new_p = ('      elseif token.ortho == "p" then\n'
    '        -- Hickey §2.2.1: p -> [pˠ] (broad) or [pʲ] (slender).\n'
    '        -- Fuaimeanna na Gaeilge §2.1: Plosive inventory.\n'
    '        token.phon = S.palatal_consonant(token, "pʲ", "pˠ")')
add_ref(f, old_p, new_p)

# bhf resolution
old_bhf = '      elseif token.ortho == "bhf" then\n        token.phon = "w"'
new_bhf = ('      elseif token.ortho == "bhf" then\n'
    '        -- Hickey §2.6.1: Eclipsis bhf -> [w] in all positions.\n'
    '        token.phon = "w"')
add_ref(f, old_bhf, new_bhf)

# fh resolution
old_fh = '      elseif token.ortho == "fh" then\n        token.phon = ""'
new_fh = ('      elseif token.ortho == "fh" then\n'
    '        -- Hickey §2.6.2: Lenited f (fh) is always silent.\n'
    '        token.phon = ""')
add_ref(f, old_fh, new_fh)

print('Pass 09 done')
