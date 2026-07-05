-- Phonotactic impossibility scanner for Irish G2P engine output
-- Checks benchmark transcriptions for sequences that violate Irish phonotactics
local engine = require('irish_engine_new')
local bench = require('_benchmark')

-- UTF-8 helpers
local function char_at(s, i)
  local b = s:byte(i)
  if not b then return '', i + 1 end
  if b >= 0xF8 then return s:sub(i, i+3), i+4
  elseif b >= 0xF0 then return s:sub(i, i+3), i+4
  elseif b >= 0xE0 then return s:sub(i, i+2), i+3
  elseif b >= 0xC0 then return s:sub(i, i+1), i+2
  else return s:sub(i, i), i+1 end
end

local function get_char(s, start)
  local ch, next_i = char_at(s, start)
  while next_i <= #s do
    local c, ni = char_at(s, next_i)
    if c:byte() and c:byte() >= 0xCC and c:byte() <= 0xCD then
      ch = ch .. c; next_i = ni
    else break end
  end
  return ch, next_i
end

-- Precomputed multisets for O(1) lookup
local CEDILLA = string.char(0xC3, 0xA7)  -- ç
local GAMMA = string.char(0xC9, 0xA3)    -- ɣ

local VOWEL_SET = {}
for _, c in ipairs({'i','e','a','o','u', 'ɪ','ɛ','ɔ','ʊ','ə','ɤ','æ'}) do VOWEL_SET[c] = true end
for _, c in ipairs({'iː','eː','aː','oː','uː', 'ɐ'}) do VOWEL_SET[c] = true end

local function is_v(s)
  local base = s:sub(1,1)
  if base == 'i' or base == 'e' or base == 'a' or base == 'o' or base == 'u' then
    -- check it's not an obstruent like 'c' or 'd' or 'g'
    if base ~= s or VOWEL_SET[base] then return true end
    -- single ASCII vowel char, need to check it's the full char
    return VOWEL_SET[s] or false
  end
  return VOWEL_SET[s] or false
end

local OBSTRUENT_SET = {
  p=true, b=true, t=true, d=true, k=true, g=true, c=true,
  [string.char(0xC9,0x9F)]=true,  -- ɟ
  f=true, v=true, s=true, z=true,
  [string.char(0xCA,0x83)]=true,  -- ʃ
  [string.char(0x92,0x92)]=true,  -- ʒ
  [CEDILLA]=true, x=true, [string.char(0xC9,0xA1)]=true,  -- ɡ
  h=true, [string.char(0xC9,0xA6)]=true,  -- ɦ
}
local function is_obstruent(s) return OBSTRUENT_SET[s] or false end

local SONORANT_SET = {m=true, n=true, l=true, r=true, j=true, w=true}
for _, c in ipairs({string.char(0xC9,0xB2), string.char(0xC5,0x8B),  -- ɲ, ŋ
  string.char(0xCA,0x8E), string(char(0xCA,0xBE)), -- ʎ, ɾ
  string.char(0xC9,0xBE),  -- ɾ alt encoding?
}) do SONORANT_SET[c] = true end
local function is_sonorant(s) return SONORANT_SET[s] or false end

local VOICED_STOP_SET = {b=true, d=true, g=true, [string.char(0xC9,0x9F)]=true,  -- ɟ
  [string(char(0xC9,0xA1))]=true}  -- ɡ
local function is_voiced_stop(s)
  return s == 'b' or s == 'd' or s == 'g' or s == string.char(0xC9,0x9F) or s == string.char(0xC9,0xA1)
end

-- Check categories
local function scan(ipa, word)
  local issues = {}
  local tokens = {}
  local i = 1
  while i <= #ipa do
    local ch, ni = get_char(ipa, i)
    table.insert(tokens, {ch=ch, pos=i})
    i = ni
  end

  for idx = 1, #tokens do
    local tok = tokens[idx]
    local ch = tok.ch
    local nxt_ch = (idx < #tokens) and tokens[idx+1].ch or ''
    local nxt_nxt = (idx+1 < #tokens) and tokens[idx+2].ch or ''
    local prev_ch = (idx > 1) and tokens[idx-1].ch or ''

    -- 1. voiced stop + h (bh dh gh sequences would be lenited, not stop+h)
    if is_voiced_stop(ch) and nxt_ch == 'h' then
      table.insert(issues, {sev=5, cat='voiced_stop+h', msg=ch..'h', idx=idx, ctx=tok.pos})
    end

    -- 2. ɣ before obstruent (ɣ only occurs before vowels or word-finally in Connacht)
    if ch == GAMMA and nxt_ch ~= '' and is_obstruent(nxt_ch) then
      table.insert(issues, {sev=3, cat='ɣ_before_obstruent', msg='ɣ'..nxt_ch, idx=idx, ctx=tok.pos})
    end

    -- 3. ç before obstruent (except r/l/ɾ — chreid→çɾʲɛdʲ, chlé→çlʲeː)
    if ch == CEDILLA and nxt_ch ~= '' and is_obstruent(nxt_ch) and nxt_ch ~= 'r' and nxt_ch ~= 'l'
       and nxt_ch ~= string.char(0xCA,0xBE) and nxt_ch ~= string.char(0xC9,0xBE)
       and nxt_ch ~= 'ɾ' then
      table.insert(issues, {sev=2, cat='ç_before_obstruent', msg='ç'..nxt_ch, idx=idx, ctx=tok.pos})
    end

    -- 4. h between two obstruents (impossible in Irish)
    if ch == 'h' and prev_ch ~= '' and is_obstruent(prev_ch) and nxt_ch ~= '' and is_obstruent(nxt_ch) then
      table.insert(issues, {sev=1, cat='h_between_obstruents', msg=prev_ch..'h'..nxt_ch, idx=idx, ctx=tok.pos})
    end

    -- 5. Sequence of 3+ obstruents without intervening sonorant or vowel
    if is_obstruent(ch) and nxt_ch ~= '' and is_obstruent(nxt_ch) then
      local nxt3 = (idx+2 < #tokens) and tokens[idx+3].ch or ''
      if nxt_nxt ~= '' and is_obstruent(nxt_nxt) and nxt3 ~= '' and is_obstruent(nxt3) then
        table.insert(issues, {sev=2, cat='4_obstruents', msg=ch..nxt_ch..nxt_nxt..nxt3, idx=idx, ctx=tok.pos})
      end
    end

    -- 6. Word-initial voiced stop word-medially after obstruent coda (foris lenition)
    -- This is more context-dependent, skip for now

    -- 7. Aspirated stop before obstruent (pʰt, tʰk etc. — Irish doesn't have aspirated stops)
    -- Actually we don't produce ʰ in our system, so this won't trigger
  end

  return issues
end

local all_issues = {}
for word, entry in pairs(bench) do
  local got = engine.transcribe(word, 'connacht')
  local issues = scan(got, word)
  if #issues > 0 then
    table.insert(all_issues, {word=word, ipa=got, issues=issues})
  end
end

table.sort(all_issues, function(a,b)
  local max_sev_a, max_sev_b = 0, 0
  for _, iss in ipairs(a.issues) do max_sev_a = math.max(max_sev_a, iss.sev) end
  for _, iss in ipairs(b.issues) do max_sev_b = math.max(max_sev_b, iss.sev) end
  if max_sev_a ~= max_sev_b then return max_sev_a > max_sev_b end
  return #a.issues > #b.issues
end)

print('=== PHONOTACTIC IMPOSSIBILITY SCAN ===')
print('Benchmark words: ' .. #all_issues .. ' with issues\n')
for _, wi in ipairs(all_issues) do
  print(wi.word .. ': ' .. wi.ipa)
  for _, iss in ipairs(wi.issues) do
    local ctx_start = math.max(1, iss.ctx - 8)
    local ctx = wi.ipa:sub(ctx_start, iss.ctx + 6)
    print(string.format('  [sev=%d] %s — context: ...%s...', iss.sev, iss.msg, ctx))
  end
  print()
end
