======================================================================
IRISH G2P ENGINE — FULL ERROR ANALYSIS
======================================================================

Total: 6593 words
Correct: 3351 (50.83%)
Wrong: 3242 (49.17%)
Avg Levenshtein: 1.15
Normalized Lev: 94.27%

======================================================================
LEV-1 SAME-LENGTH SUBSTITUTION BUCKETS (86 total)
======================================================================
Count  Substitution     Examples
----------------------------------------------------------------------
12     ɾ → r            treascair, car, greannach, Sprantais
3      a → ə            fadhbanna, adhairc, mba
2      ɪ → e            beidh, tirim
2      ə → ː            riaráiste, carria
2      ː → ə            beithíoch, cíoch
2      ʲ → ˠ            facabhair, Dé Sathairn
2      ɛ → ə            le déanaí, le chéile
2      ʲ → ̠            leic, cinnigí
2      v → w            vác, Baváir
2      ə → ɑ            beathaisnéisí, gabhlóg
2      ˠ → ʲ            fuiltear, bhfuiltear
2      ˈ → ʲ            éineacht, Vicipéid
2      ɪ → a            fheadh, bhfeadh
2      ˠ → ̪            focla, díolaim
2      ɔ → ɛ            coisreac, coisric
2      ɔ → ɪ            ois, hois
1      n → ɾ            imní
1      ˈ → j            ghrian
1      ɪ → ɯ            gliogaire
1      ɛ → ʌ            ghoirid
1      ʊ → ɞ            gruth
1      ɪ → i            smig
1      ɑ → a            Áine
1      k → c            bricfásta
1      - → ˌ            broc-chú
1      ɔ → u            domlas
1      i → e            aonraic
1      v → f            bhfreastalaí
1      a → ʊ            scadán
1      a → ã            mhaithe
1      ə → æ            athair
1      ɛ → e            ar gcúl
1      ə → ʌ            anrud
1      i → ɪ            buile
1      ç → x            teachín
1      ç → h            cheana
1      ə → ɔ            gabháil
1      ə → i            diagaire
1      ə → ʊ            dubhach
1      k → ɡ            tagtar
1      y → j            yé
1      ʊ → ʌ            punta
1      w → u            gabha
1      ɔ → ə            cosán
1      ɔ → ʌ            coisc
1      a → ɑ            beir bua agus beannacht
1      h → ː            cathú
1      ʊ → u            bonnán
1      ʊ → ɪ            cuirtear
1      ɔ → a            dorú
1      u → o            Odhrán
1      o → ɔ            sheol
1      a → u            bacán
1      ɪ → ʊ            Tiobraid Árann
1      ɪ → o            bogearraí
1      ɛ → ɞ            coirce
1      ə → u            boladh
1      ú → u            créatúir
1      ə → ɛ            eitpheil

======================================================================
ERROR CATEGORIES
======================================================================

Other                                1367 (42.2%)
  líneach              got=ˈlʲiːnʲəx            exp=ˈl̠ʲiːnʲəx
  triall               got=ˈtʲɾʲiəlˠ            exp=tʲɾʲiəl̪ˠ
  -ígí                 got=-ˈiːɟiː              exp=iːɟiː
  daichead             got=ˈd̪ˠaçəd̪ˠ           exp=ˈd̪ˠa.çəd̪ˠ
  i gceist             got=əˈɟɛʃtʲ              exp=ə ˈɟɛʃtʲ

i/ɪ/e/ɛ quality                       311 (9.6%)
  bpingin              got=ˈbʲɪɲənʲ             exp=bʲiːn̠ʲ
  doiligh              got=ˈd̪ˠɛlʲə             exp=ˈd̪ˠɛlʲiː
  deimhin              got=ˈdʲeiiːənʲ           exp=ˈdʲɪvʲənʲ
  dligh                got=dʲlʲɪ                exp=dʲlʲiː
  feirg                got=fʲɛɾʲɟ               exp=ˈfʲɛɾʲɪɟ

schwa vs full vowel                   287 (8.9%)
  comhair              got=ˈkəwəɾʲ              exp=kuːɾʲ
  daonchairdiúil       got=ˈd̪ˠiːn̪ˠxəɾʲdʲúlʲ   exp=ˈd̪iːn̪xɑːɾˠdʲuːlʲ
  crúbchrois           got=ˈkɾˠuːbˠxɾˠəʃ        exp=ˈkɾˠuːbˠˌxɾˠʌʃ
  triuch               got=ˈtʲɾʲəx              exp=tʲɾʲʊx
  cúinge               got=ˈkúɲə                exp=ˈkuːɲɪ

Length (ː)                            277 (8.5%)
  sagart               got=ˈsˠaɡəɾˠt̪ˠ          exp=ˈsˠaːɡəɾˠt̪ˠ
  sagartúil            got=ˈsˠaɡəɾˠt̪ˠúlʲ       exp=ˈsˠaɡəɾˠt̪ˠuːlʲ
  draíochta            got=ˈd̪ˠɾˠiːəxt̪ˠə       exp=ˈd̪ˠɾˠiəxt̪ˠə
  suaimhneas           got=ˈsˠuənʲəsˠ           exp=ˈsˠiːmʲnʲəsˠ
  chiúin               got=ˈçúnʲ                exp=çuːnʲ

Consonant quality (ç/h/x/ɣ/v/w/j)     256 (7.9%)
  faoi dhó             got=fˠiːˈɣoː             exp=fˠiː ˈɣoː
  sléibh               got=ʃlʲeːvʲ              exp=ʃl̠ʲeːvʲ
  scríobh              got=ʃcɾʲiːvʲ             exp=ʃcɾʲiːw
  bhínn                got=vʲiːnʲ               exp=vʲiːn̠ʲ
  ríomhaire            got=ˈɾˠiːəɾʲə            exp=ˈɾˠiːvˠəɾʲə

Stress only                           225 (6.9%)
  bhfuair              got=ˈwuəɾʲ               exp=wuəɾʲ
  uair                 got=ˈuəɾʲ                exp=uəɾʲ
  cíb                  got=ciːbʲ                exp=ˈciːbʲ
  ruaig                got=ˈɾˠuəɟ               exp=ɾˠuəɟ
  chluais              got=ˈxlˠuəʃ              exp=xlˠuəʃ

a/ɑ quality                           216 (6.7%)
  airneán              got=ˈaɾʲnʲeɑːnˠ          exp=ˈaːɾˠn̠ʲaːnˠ
  neamhspleách         got=ˈnʲəuʃpʲlʲeɑːx       exp=ˈn̠ʲəusˠpʲlʲaːx
  n-ard                got=n̪ˠ-aɾˠd̪ˠ           exp=n̪ˠɑːɾˠd̪ˠ
  t-ard                got=t̪ˠ-aɾˠd̪ˠ           exp=t̪ˠɑːɾˠd̪ˠ
  bansár               got=ˈbˠan̪ˠsˠɑːɾˠ        exp=ˈbˠanˠˌsˠɑːɾˠ

o/u/ɔ/ʊ quality                       148 (4.6%)
  proifisiúnta         got=ˈpˠɾˠɛfʲəʃuːn̪ˠt̪ˠə  exp=pˠɾˠɔˈfʲɛʃun̪ˠt̪ˠə
  cnoga                got=ˈkɾˠɔɡə              exp=ˈknˠuɡə
  rud beag             got=ɾˠʊd̪ˠ ˈbʲaɡ         exp=ˈɾˠʊd̪ˠ ˈbʲɔɡ
  crua-ae              got=ˈkɾˠuə-eː            exp=ˈkɾˠuəiju
  iógart               got=ˈioːɡəɾˠt̪ˠ          exp=ˈjoː.ɡˠʊɾˠt̪ˠ

Consonant broad/slender               106 (3.3%)
  Cincís               got=ˈcɪn̠ʲciːʃ           exp=ˈcɪɲciːʃ
  Fraincis             got=ˈfˠɾˠan̠ʲcɪʃ         exp=ˈfˠɾˠaɲcɪʃ
  id                   got=ɪdʲ                  exp=ɪd̪ˠ
  nc                   got=n̪ˠk                 exp=ŋk
  Nc                   got=n̪ˠk                 exp=ŋk

r vs ɾ                                 38 (1.2%)
  treascair            got=ˈtʲɾʲasˠkəɾʲ         exp=ˈtʲrʲasˠkəɾʲ
  foshruth             got=ˈfˠɔhɾˠə             exp=ˈfˠɔ(h)rˠʊ(h)
  gearrthacha          got=ˈɟaɾˠəxə             exp=ˈɟaːrˠhəxə
  crosta               got=ˈkɾˠɔsˠt̪ˠə          exp=ˈkrˠɔs̪ˠt̪ˠə
  eascracha            got=ˈasˠkɾˠəxə           exp=ˈaskrəxə

Devoicing (voiced↔voiceless)           11 (0.3%)
  céadta               got=ˈceːd̪ˠt̪ˠə          exp=ˈceːt̪ˠə
  stadta               got=ˈsˠt̪ˠad̪ˠt̪ˠə       exp=ˈsˠt̪ˠat̪ˠə
  goidtear             got=ˈɡɛdʲtʲəɾˠ           exp=ˈɡɞtʲəɾˠ
  gcéadta              got=ˈɟeːd̪ˠt̪ˠə          exp=ˈɟeːt̪ˠə
  goidte               got=ˈɡɛdʲtʲə             exp=ˈɡɞtʲə

======================================================================
WORD ANALYSIS
======================================================================

Single-letter words wrong: 1
  h     got=h               exp=95

Prefix/hyphenated words wrong: 142

Multi-word phrases wrong: 255
  faoi dhó                  got=fˠiːˈɣoː                       exp=fˠiː ˈɣoː
  i gceist                  got=əˈɟɛʃtʲ                        exp=ə ˈɟɛʃtʲ
  Oíche Inide               got=ˌoiːçə ˈɪnʲədʲə                exp=ˈiːç ˈɪnʲədʲə
  rud beag                  got=ɾˠʊd̪ˠ ˈbʲaɡ                   exp=ˈɾˠʊd̪ˠ ˈbʲɔɡ
  go fóill                  got=ɡəˈfˠólʲ                       exp=ɡəˈfˠoːl̠ʲ
  loch salainn              got=lˠɔx ˈsˠalˠənʲ                 exp=l̪ˠɔx ˈsˠalˠən̠ʲ
  suíomh gréasáin           got=ˌsˠuíoiː ˈɟɾʲeːsˠɑːnʲ          exp=ˌsˠiːw ˈɟɾʲeːsˠɑːnʲ
  madra alla                got=ˌmˠad̪ˠɾˠə ˈalˠə               exp=ˈmˠad̪ˠɾˠə ˈal̪ˠə
  cál ceannann              got=kɑːlˠ ˈcan̪ˠən̪ˠ               exp=ˌkɑːlˠ ˈcan̪ˠən̪ˠ
  Cúil Raithin              got=ˌkúlʲ ˈɾˠahənʲ                 exp=ˌkuːlʲ ˈɾˠahənʲ

Error distribution by Levenshtein distance:
  Lev-1: 1176 words
  Lev-2: 913 words
  Lev-3: 586 words
  Lev-4: 312 words
  Lev-5: 139 words
  Lev-6: 63 words
  Lev-7: 27 words
  Lev-8: 12 words
  Lev-9: 4 words
  Lev-10: 3 words
  Lev-13: 1 words
  Lev-14: 2 words
  Lev-15: 1 words
  Lev-17: 1 words
  Lev-19: 1 words
  Lev-31: 1 words
