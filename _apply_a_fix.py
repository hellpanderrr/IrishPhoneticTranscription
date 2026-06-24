# Apply a/á vowel quality fix for Connacht dialect.
import sys

A_BACK = b'\xc9\x91'          # ɑ
C = b'\xcb\x90'               # ː
A_LONG_BACK = A_BACK + C      # a-back + colon
A_LONG_FRONT = b'a' + C       # a + colon

def esc(s):
    """Replace literal ː with byte escape."""
    return s.replace('ː', '\\xcb\\x90').encode('ascii')

changes = []

# 1. _shared.lua: Connacht long.a = a:
with open('passes/_shared.lua', 'rb') as f:
    shared = f.read()

pattern_shared = b'        long  = { a = "' + A_LONG_BACK + b'", o = "o' + C + b'", u = "u' + C + b'", i = "i' + C + b'", e = "e' + C + b'" },'
replacement_shared = b'        long  = { a = "' + A_LONG_FRONT + b'", o = "o' + C + b'", u = "u' + C + b'", i = "i' + C + b'", e = "e' + C + b'" },'
if pattern_shared in shared:
    shared = shared.replace(pattern_shared, replacement_shared, 1)
    changes.append('_shared.lua: long.a = a:')
else:
    print('WARN: _shared.lua pattern not found', file=sys.stderr)

with open('passes/_shared.lua', 'wb') as f:
    f.write(shared)

# 2. 10_vowels.lua
with open('passes/10_vowels.lua', 'rb') as f:
    v10 = f.read()

# 2a: a+dh stressed
old = b'          elseif token.stress then token.phon = "' + A_LONG_BACK + b'" end'
new = b'          elseif token.stress then token.phon = (dv.long and dv.long.a) or "' + A_LONG_FRONT + b'" end'
if old in v10:
    v10 = v10.replace(old, new, 1)
    changes.append('10_v: a+dh stressed -> dv.long.a')
else:
    print('WARN: a+dh stressed not found', file=sys.stderr)

# 2b: ai medial
old = b'token.phon = "' + A_LONG_BACK + b'"  -- medial: sr\xc3\xa1id'
new = b'token.phon = (dv.long and dv.long.a) or "' + A_LONG_FRONT + b'"  -- medial'
if old in v10:
    v10 = v10.replace(old, new, 1)
    changes.append('10_v: ai medial -> dv.long.a')
else:
    print('WARN: ai medial not found', file=sys.stderr)

# 2c: a fallback (ortho == "a")
old = b'elseif ortho == "\xc3\xa1" then token.phon = (dv.long and dv.long.a) or "' + A_LONG_BACK + b'"'
new = b'elseif ortho == "\xc3\xa1" then token.phon = (dv.long and dv.long.a) or "' + A_LONG_FRONT + b'"'
if old in v10:
    v10 = v10.replace(old, new, 1)
    changes.append('10_v: a fallback a:')
else:
    print('WARN: a fallback not found', file=sys.stderr)

# 2d: stressed short a -> a (Connacht only)
indent8 = b'        '
old_short = indent8 + b'elseif ortho == "a" then token.phon = (dv.short and dv.short.a) or "a"'
new_lines = [
    indent8 + b'elseif ortho == "a" then',
    indent8 + b'  if token.stress and context.dialect == "connacht" then',
    indent8 + b'    token.phon = "' + A_BACK + b'"',
    indent8 + b'  else',
    indent8 + b'    token.phon = (dv.short and dv.short.a) or "a"',
    indent8 + b'  end',
]
new_short = b'\r\n'.join(new_lines)

if old_short in v10:
    v10 = v10.replace(old_short, new_short, 1)
    changes.append('10_v: stressed short a -> a (Connacht)')
else:
    print('WARN: short a not found', file=sys.stderr)
    # Diagnostic
    part = b'elseif ortho == "a" then token.phon'
    if part in v10:
        pos = v10.find(part)
        ctx = v10[max(0,pos-10):pos+80]
        print(f'  Found at pos {pos}', file=sys.stderr)

with open('passes/10_vowels.lua', 'wb') as f:
    f.write(v10)

# Verify
remaining = v10.count(A_LONG_BACK)
print(f'\n{len(changes)} changes:')
for c in changes:
    print(f'  + {c}')
print(f'Remaining a: in 10_vowels.lua: {remaining}')
