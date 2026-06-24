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
        print(f'  WARN: {filepath} - {repr(old_text[:50])}')

# ========== Specific rules in pass 10_vowels.lua ==========
f = 'passes/10_vowels.lua'

# io collapse rule
add_ref(f,
    '      -- Stressed \'io\' collapses to [ʊ] before certain consonants (Summary',
    '      -- Hickey §1.4: Stressed /io/ collapses to [ʊ] before certain consonants.')

# ae digraph resolution
add_ref(f,
    '      -- Handle ae digraph (split as a + e) BEFORE need_resolve guard.\n      -- Resolve a+e -> eː, silence the e token.',
    '      -- Hickey §1.4: ae digraph -> [eː] in all dialects. The first element\n      -- (a) is elided; the second (e) lengthens. Fuaimeanna na Gaeilge §5.2.\n      -- Resolve a+e -> eː, silence the e token.')

# ae digraph as vowel
add_ref(f,
    '      elseif ortho == \"ae\" then token.phon = \"eː\"',
    '      elseif ortho == \"ae\" then token.phon = \"eː\"  -- Hickey §1.4: ae -> /eː/')

# Contextual: consonant polarity affects vowel quality
add_ref(f,
    '      -- Contextual: consonant polarity affects vowel quality\n      if next and next.type == \"cons\" and not has_x_block and not is_digraph_first then',
    '      -- Hickey §2.8.1: Consonant polarity affects vowel quality.\n'
    '      -- Slender consonants front/back vowels: o/u -> [ɪ] before slender (e.g. mil, col).\n'
    '      -- Broad consonants back vowels: i -> [ə] before broad (e.g. fiar).\n'
    '      -- Fuaimeanna na Gaeilge §5.4: Vowel-consonant interaction.\n'
    '      -- Contextual: consonant polarity affects vowel quality\n'
    '      if next and next.type == \"cons\" and not has_x_block and not is_digraph_first then')

# /x/ palatal non-assimilation
add_ref(f,
    '      -- /x/ palatal non-assimilation: blocks vowel fronting\n      -- bocht -> bˠɔxt̪ˠ, NOT *bˠɪxʲtʲə',
    '      -- Hickey §2.6.2: /x/ (ch) blocks palatal assimilation of vowels.\n'
    '      -- bocht -> bˠɔxt̪ˠ, NOT *bˠɪxʲtʲə')

# oi before palatal consonant: fronting
add_ref(f,
    '      -- oi before palatal consonant: front to ɛ (not back ɔ)\n      -- goilim -> ɡɛlʲəmʲ, foide -> fˠɛdʲə, coire -> kɛɾʲə',
    '      -- Hickey §2.8.1: oi/fronting before palatal consonants: front to [ɛ] (not back [ɔ]).\n'
    '      -- goilim -> ɡɛlʲəmʲ, foide -> fˠɛdʲə, coire -> kɛɾʲə.')

# ui before palatal consonant: fronting
add_ref(f,
    '      -- ui before palatal consonant: front to ɪ (not back ʊ)\n      -- muiníneach -> mˠɪnʲiːnʲəx, cuireann -> kɪɾʲən̪ˠ',
    '      -- Hickey §2.8.1: ui/fronting before palatal consonants: front to [ɪ] (not back [ʊ]).\n'
    '      -- muiníneach -> mˠɪnʲiːnʲəx, cuireann -> kɪɾʲən̪ˠ.')

# Previous consonant polarity affects preceding vowel
add_ref(f,
    '      -- Previous consonant polarity affects preceding vowel quality\n      if prev and prev.type == \"cons\" then',
    '      -- Hickey §2.8.1: Previous consonant polarity affects preceding vowel quality.\n'
    '      -- Slender onset raises vowel: ə -> ɪ. Broad onset lowers: ɪ -> ə.\n'
    '      -- Fuaimeanna na Gaeilge §5.4: Vowel assimilation to consonant context.\n'
    '      -- Previous consonant polarity affects preceding vowel quality\n'
    '      if prev and prev.type == \"cons\" then')

# Hickey 3.2.1: stressed /i/ reference
add_ref(f,
    '      -- Hickey §3.2.1: stressed /i/ does NOT lower to [ɪ] in closed\n      -- syllables before geminate sonorants or in specific lexical items.',
    '      -- Hickey §3.2.1: stressed /i/ does NOT lower to [ɪ] in closed\n      -- syllables before geminate sonorants or in specific lexical items.\n'
    '      -- (already referenced above; this is the lexical exception list)')

print('Pass 10 specific rules done')
