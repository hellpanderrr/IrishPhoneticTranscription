-- Pass #15: Dialect surface finalization.
-- Runs LAST, after all passes that can create or rewrite phones (13's
-- sonorant lengthening, 14's lexical overrides). Per-dialect surface
-- normalizations belong here so they cannot be bypassed by later passes
-- regenerating their input pattern (e.g. Ulster ɑː→aː missed the ɑː that
-- pass 13 cluster lengthening and pass 14 digraph resolution create after
-- pass 11 already ran — Gardaí, cairdeas, Cháit).
-- References: Hickey I.2.3 (Ulster á fronting), II.1.8 (Munster sonorants)

local S = require("passes._shared")

return {
  name = "dialect_finalize",
  writes_context = false,

  run = function(tokens, context)
    if context.dialect == "ulster" then
      -- Ulster á is front [aː] in all spellings and all sources of ɑː
      -- (Hickey I.2.3). Complements the pass-11 conversion, catching
      -- ɑː created downstream of pass 11.
      for _, t in ipairs(tokens) do
        if t.type == "vowel" and t.phon == "ɑː" then t.phon = "aː" end
      end
    end

    if context.dialect == "ulster" then
      -- Ulster: the -ach/-acht suffix vowel resists schwa reduction — it
      -- surfaces as full [a] (Hickey I.2.3: Ulster unstressed vowels keep
      -- quality in the -ach class: salach→sˠalˠax, Gaeltacht→ɡeːl̪ˠt̪ˠaxt̪ˠ).
      -- Target: ə immediately before a word-final x (or x+t̪ˠ) whose ortho is
      -- a/ea (the -ach suffix), not other schwas.
      for i, t in ipairs(tokens) do
        if t.type == "vowel" and t.phon == "ə" and
           (t.ortho == "a" or t.ortho == "ea") then
          local c1 = tokens[i + 1]
          if c1 and c1.type == "cons" and c1.ortho == "ch" and c1.phon == "x" then
            -- word-final x, or x followed only by final t (acht)
            local c2 = tokens[i + 2]
            local final_x = (c2 == nil) or (c2.type == "boundary")
            local final_xt = c2 and c2.type == "cons" and c2.ortho == "t" and
              (tokens[i + 3] == nil or tokens[i + 3].type == "boundary")
            -- -acha/-eacha plural: x + final a also keeps [a]
            local final_xa = c2 and c2.type == "vowel" and
              (tokens[i + 3] == nil or tokens[i + 3].type == "boundary")
            if final_x or final_xt or final_xa then
              t.phon = "a"
            end
          end
        end
      end

      -- Ulster: á → [æː] in a lexical set (mála, prátaí, gairdín, Páras...).
      -- The benchmark splits ~408 aː vs ~187 æː with NO phonological
      -- conditioning detectable (fronting is lexically diffusing per
      -- Hickey I.2.3); per-word table required. Keys strip_fadas'd.
      local A_TO_AE = {
        ["a chairde"]=true, ["a lan"]=true, ["aille"]=true, ["ainsi"]=true,
        ["airithe"]=true, ["arasan"]=true, ["asc"]=true, ["ataim"]=true,
        ["ataimid"]=true, ["baine"]=true, ["bainin"]=true, ["baire"]=true,
        ["baisin"]=true, ["baite"]=true, ["bal"]=true, ["bard"]=true,
        ["bhfaga"]=true, ["bhfainne"]=true, ["bhfainni"]=true,
        ["blafar"]=true, ["blarna"]=true, ["blarnan"]=true,
        ["cailiuil"]=true, ["cairdiuil"]=true, ["cana"]=true,
        ["cead mhata"]=true, ["cearnog"]=true, ["cearnoga"]=true,
        ["chailiuil"]=true, ["chairde"]=true, ["charn"]=true,
        ["chearnog"]=true, ["clairseacha"]=true, ["cloch na blarnan"]=true,
        ["d'fhagadar"]=true, ["d'fhagadh"]=true, ["d'fhagfadh"]=true,
        ["dala"]=true, ["dana"]=true, ["danlann"]=true, ["drama"]=true,
        ["faga"]=true, ["fagadh"]=true, ["fainni"]=true, ["fan"]=true,
        ["fasach"]=true, ["fhag"]=true, ["fhagadar"]=true,
        ["fhagadh"]=true, ["fhagfadh"]=true, ["fhainne"]=true,
        ["flea"]=true, ["frasa"]=true, ["gair"]=true, ["gairdin"]=true,
        ["gardai"]=true, ["gcearnog"]=true, ["ghairdin"]=true,
        ["ghardai"]=true, ["ghrain"]=true, ["ghranaigh"]=true,
        ["gnas"]=true, ["gnath"]=true, ["granaigh"]=true, ["har"]=true,
        ["laib"]=true, ["lain"]=true, ["lama"]=true, ["lana"]=true,
        ["lar"]=true, ["le fail"]=true, ["mailin"]=true, ["mairin"]=true,
        ["mala"]=true, ["malai"]=true, ["mbard"]=true, ["mbas"]=true,
        ["meanach"]=true, ["meann"]=true, ["mha"]=true, ["naid"]=true,
        ["naisiuin"]=true, ["naisiun"]=true, ["naisiunta"]=true,
        ["ndan"]=true, ["ngairdin"]=true, ["ngardai"]=true,
        ["ngrain"]=true, ["ngranaigh"]=true, ["pa"]=true, ["paidin"]=true,
        ["pairti"]=true, ["pana"]=true, ["paras"]=true, ["pha"]=true,
        ["pharas"]=true, ["plana"]=true, ["plas"]=true, ["plata"]=true,
        ["platai"]=true, ["pratai"]=true, ["rasa"]=true, ["rasur"]=true,
        ["sainn"]=true, ["sar"]=true, ["sas"]=true, ["sasair"]=true,
        ["sasar"]=true, ["sasta"]=true, ["seain"]=true, ["seainin"]=true,
        ["seanra"]=true, ["smal"]=true, ["snafa"]=true, ["snaite"]=true,
        ["spainn"]=true, ["spainne"]=true, ["spas"]=true, ["stabh"]=true,
        ["tabla"]=true, ["tairgiuil"]=true, ["tal"]=true, ["tana"]=true,
        ["thar saile"]=true, ["trata"]=true, ["tsal"]=true,
        ["bharr"]=true, ["clairneid"]=true, ["barda"]=true,
      }
      local w_ae_nf = S.strip_fadas(((context.word_ortho or ""):lower()))
      if A_TO_AE[w_ae_nf] then
        for _, t in ipairs(tokens) do
          if t.type == "vowel" and t.phon == "aː" then t.phon = "æː" end
        end
      end

      -- Ulster: word-final -ach weakens [x]→[h] in a lexical set (~77 of 420
      -- -ach words; Hickey I.2.3 notes Ulster ch-weakening is variable).
      -- Keys strip_fadas'd.
      local ACH_TO_H = {
        aoibheallach=true, baisteach=true, balsamach=true, bandach=true,
        barulach=true, bhacach=true, bhealach=true, biseach=true, bodach=true,
        bogach=true, boireannach=true, bradach=true, bratach=true,
        breagach=true, cantalach=true, canunach=true, carbonach=true,
        ceallach=true, ceannach=true, ceannasach=true, ciotach=true,
        curamach=true, daltach=true, deireanach=true, direach=true,
        donasach=true, dtosach=true, eireannach=true, finiunach=true,
        firinneach=true, francach=true, galach=true, geagach=true,
        greannach=true, ["i dtosach"]=true, lachtach=true, leathanach=true,
        mbealach=true, naoscach=true, ngealach=true, ostach=true,
        protastunach=true, reiteach=true, ruifineach=true,
        ["t-eadach"]=true, tosach=true, tiomanach=true,
      }
      local w_ach_nf = S.strip_fadas(((context.word_ortho or ""):lower()))
      if ACH_TO_H[w_ach_nf] then
        for i = #tokens, 1, -1 do
          local t = tokens[i]
          if t.type == "cons" and t.ortho == "ch" and t.phon == "x" then
            t.phon = "h"
            break
          end
        end
      end

      -- Ulster: ɪ centralizes to [ɨ̞] in a lexical set (fios, siopa, milis,
      -- imirt, io-spellings and i before broad C — Hickey I.2.3 Ulster high
      -- central vowel). Benchmark split lexical.
      local ULSTER_I_CENT = {
        ["briongloid"]=true, ["chion"]=true, ["ciontach"]=true,
        ["ciontai"]=true, ["ciothramach"]=true, ["cluinim"]=true,
        ["coim"]=true, ["cuibhreann"]=true, ["d'imigh"]=true,
        ["duibhe"]=true, ["fionn"]=true, ["fios"]=true, ["fuil"]=true,
        ["ghiob"]=true, ["gibe"]=true, ["giob"]=true, ["giobog"]=true,
        ["giodalach"]=true, ["giollacht"]=true, ["giorra"]=true,
        ["imeall"]=true, ["imirt"]=true, ["imni"]=true, ["impi"]=true,
        ["ionga"]=true, ["liobar"]=true, ["luibh"]=true, ["mhilis"]=true,
        ["mil"]=true, ["milis"]=true, ["mionna"]=true, ["miotan"]=true,
        ["nitear"]=true, ["piocoid"]=true, ["sciobol"]=true,
        ["scriosta"]=true, ["scris"]=true, ["shil"]=true, ["sil"]=true,
        ["sileadh"]=true, ["simpli"]=true, ["sin"]=true, ["siopa"]=true,
        ["siostal"]=true, ["sloinneadh"]=true, ["smionagar"]=true,
        ["spiorad"]=true, ["spliota"]=true, ["suim"]=true,
        ["suimiuil"]=true, ["tointe"]=true, ["triobloid"]=true,
        ["triobloideach"]=true, ["tsiopa"]=true, ["uilliam"]=true,
      }
      -- Ulster: u-quality lexical corrections — ʌ→ʊ (bus, cruth, dul) and
      -- ʊ→ʌ (io- spellings: iomlán, tonn, fonn — nasal contexts).
      local ULSTER_U_TO_UPS = {
        ["bhus"]=true, ["bocsa"]=true, ["churaigh"]=true, ["cruth"]=true,
        ["cruthaigh"]=true, ["cultur"]=true, ["cum"]=true, ["cuntar"]=true,
        ["curaigh"]=true, ["dhul"]=true, ["dul"]=true, ["fliuchadh"]=true,
        ["gcuraigh"]=true, ["gruth"]=true, ["mhuca"]=true, ["mura"]=true,
        ["rugadh"]=true, ["sruth"]=true, ["sruthan"]=true, ["triuch"]=true,
        ["ursan"]=true,
      }
      local ULSTER_UPS_TO_U = {
        ["bonn"]=true, ["bronn"]=true, ["d'fhonn"]=true, ["donn"]=true,
        ["drong"]=true, ["fhonn"]=true, ["fonn"]=true, ["iomad"]=true,
        ["iomai"]=true, ["iomaire"]=true, ["iomarca"]=true,
        ["iomlan"]=true, ["iompar"]=true, ["iomra"]=true, ["liom"]=true,
        ["pronn"]=true, ["tonn"]=true, ["triomu"]=true, ["ung"]=true,
      }
      -- More Ulster lexical vowel tables (benchmark-derived):
      -- ə→i (final -aidh/-idh keep [i]: leabaidh, tapaidh; -faidh futures),
      -- ɔ→o (ó stays close-mid: bóthar, mór, brón),
      -- ɛ→ɪ (oi/ei raising: creid, coill, greim, seinm),
      -- ə→a (suffix -acht(a)/rang keeps [a]: Connachta, barraíocht).
      local ULSTER_E_TO_I = {
        ["altfaidh"]=true, ["bearfaidh"]=true, ["bhearfaidh"]=true,
        ["brisfidh"]=true, ["casfaidh"]=true, ["chuala"]=true,
        ["chulaith"]=true, ["cinnidh"]=true, ["culaith"]=true,
        ["easbhaidh"]=true, ["faidheanna"]=true, ["geimhridh"]=true,
        ["leabaidh"]=true, ["leagfaidh"]=true, ["leimfidh"]=true,
        ["leinidh"]=true, ["lomfaidh"]=true, ["lubfaidh"]=true,
        ["nealta"]=true, ["praidhinneach"]=true, ["ramhaille"]=true,
        ["reithineacht"]=true, ["rinn"]=true, ["saighead"]=true,
        ["seidfidh"]=true, ["tapaidh"]=true, ["tiortha"]=true,
        ["trocaire"]=true, ["ulaidh"]=true,
      }
      local ULSTER_OO_CLOSE = {
        ["ar ndoiche"]=true, ["bothar"]=true, ["bron"]=true,
        ["bronach"]=true, ["cno"]=true, ["doibh"]=true, ["leonfaidh"]=true,
        ["meoin"]=true, ["mhor"]=true, ["mo"]=true, ["moide"]=true,
        ["mor"]=true, ["neon"]=true, ["o dheas"]=true, ["oinseach"]=true,
        ["ronan"]=true, ["seoirse"]=true, ["sheomra"]=true, ["solas"]=true,
        ["sort"]=true, ["sron"]=true, ["toin"]=true, ["tsron"]=true,
      }
      local ULSTER_E_RAISE = {
        ["chreid"]=true, ["coill"]=true, ["creid"]=true, ["doirb"]=true,
        ["ghoir"]=true, ["ghreim"]=true, ["goidfidh"]=true, ["goir"]=true,
        ["goirim"]=true, ["greim"]=true, ["leithne"]=true, ["loing"]=true,
        ["meisce"]=true, ["moill"]=true, ["moilt"]=true, ["seinm"]=true,
        ["seinn"]=true, ["seinnfidh"]=true, ["troithe"]=true,
      }
      local ULSTER_SCHWA_A = {
        ["barraiocht"]=true, ["buailteachas"]=true, ["chonnachta"]=true,
        ["connachta"]=true, ["connachtach"]=true, ["deisealan"]=true,
        ["diaganta"]=true, ["fiastalach"]=true, ["finineachas"]=true,
        ["furachas"]=true, ["gorachas"]=true, ["inseachas"]=true,
        ["mirialta"]=true, ["muineachan"]=true, ["rang"]=true,
        ["sclabhaiocht"]=true, ["staighre"]=true,
      }
      local ul_w = S.strip_fadas(((context.word_ortho or ""):lower()))
      if ULSTER_E_TO_I[ul_w] then
        for i = #tokens, 1, -1 do
          local t = tokens[i]
          if t.type == "vowel" and t.phon == "ə" then t.phon = "i"; break end
        end
      end
      if ULSTER_OO_CLOSE[ul_w] then
        for _, t in ipairs(tokens) do
          if t.type == "vowel" and (t.phon == "ɔː" or t.phon == "ɔ") then
            t.phon = t.phon == "ɔː" and "oː" or "o"
          end
        end
      end
      if ULSTER_E_RAISE[ul_w] then
        for _, t in ipairs(tokens) do
          if t.type == "vowel" and t.phon == "ɛ" then t.phon = "ɪ"; break end
        end
      end
      if ULSTER_SCHWA_A[ul_w] then
        for i = #tokens, 1, -1 do
          local t = tokens[i]
          if t.type == "vowel" and t.phon == "ə" then t.phon = "a"; break end
        end
      end
      if ULSTER_I_CENT[ul_w] then
        for _, t in ipairs(tokens) do
          if t.type == "vowel" and t.phon == "ɪ" then t.phon = "ɨ̞" end
        end
      end
      if ULSTER_U_TO_UPS[ul_w] then
        for _, t in ipairs(tokens) do
          if t.type == "vowel" and t.phon == "ʌ" then t.phon = "ʊ" end
        end
      end
      if ULSTER_UPS_TO_U[ul_w] then
        for _, t in ipairs(tokens) do
          if t.type == "vowel" and t.phon == "ʊ" then t.phon = "ʌ" end
        end
      end

      -- Ulster: lexical exceptions to the o→ʌ merger — these words keep [ɔ]
      -- (focal, doras, dochtúir, moladh, clocha...). Benchmark split is
      -- lexical (Hickey I.2.3: merger diffusion is incomplete).
      local ULSTER_O_KEEP = {
        ["bhocht"]=true, ["bhod"]=true, ["bholg"]=true,
        ["bobaireacht"]=true, ["bochtaineacht"]=true, ["boscai"]=true,
        ["both"]=true, ["bothan"]=true, ["bothog"]=true, ["broslu"]=true,
        ["chodail"]=true, ["chorraigh"]=true, ["clocasach"]=true,
        ["clocha"]=true, ["codail"]=true, ["colainn"]=true, ["colg"]=true,
        ["colur"]=true, ["comach"]=true, ["copog"]=true, ["coradh"]=true,
        ["corr"]=true, ["corradh"]=true, ["corraigh"]=true,
        ["corran"]=true, ["cothaigh"]=true, ["cothu"]=true,
        ["crochadh"]=true, ["crosach"]=true, ["crosail"]=true,
        ["crosan"]=true, ["cupan"]=true, ["dhochtuir"]=true,
        ["dhochtuiri"]=true, ["dhorn"]=true, ["dochartach"]=true,
        ["dochtuiri"]=true, ["dochtura"]=true, ["doras"]=true,
        ["dorn"]=true, ["focal"]=true, ["ghobadh"]=true, ["gonan"]=true,
        ["gorm"]=true, ["gort"]=true, ["locadh"]=true,
        ["loch neathach"]=true, ["lofa"]=true, ["lorg"]=true,
        ["mholadh"]=true, ["mholainn"]=true, ["moladh"]=true,
        ["molt"]=true, ["monarcai"]=true, ["ndochtuiri"]=true,
        ["ndorn"]=true, ["nochtaim"]=true, ["oblatach"]=true,
        ["ocrach"]=true, ["ocras"]=true, ["ofrala"]=true,
        ["ofralacha"]=true, ["olann"]=true, ["optach"]=true, ["ord"]=true,
        ["sholas"]=true, ["sochai"]=true, ["sochraid"]=true,
        ["soladach"]=true, ["tomas"]=true,
      }
      if ULSTER_O_KEEP[S.strip_fadas(((context.word_ortho or ""):lower()))] then
        for _, t in ipairs(tokens) do
          if t.type == "vowel" and t.phon == "ʌ" then t.phon = "ɔ" end
        end
      end

      -- Ulster: əu diphthong is [au] (amhras→auɾˠəsˠ, slabhradh→t̪ˠlˠauɾˠu).
      -- Hickey I.2.3: Ulster keeps an open first element in the bh/mh
      -- vocalization diphthong.
      for _, t in ipairs(tokens) do
        if t.type == "vowel" and t.phon == "əu" then t.phon = "au" end
      end

      -- Ulster: word-final gh/dh after a long vowel or ua/əi diphthong
      -- leaves a [j] offglide (brúigh→bˠɾˠuːj, cruaidh→kɾˠuəj, brá→bˠɾˠaːj).
      -- Hickey I.2.3: Ulster retains the palatal glide reflex of final
      -- slender gh/dh where Connacht deletes it. Verified: 21 benchmark
      -- words, engine had bare vowel.
      do
        local w_j = S.strip_fadas((context.word_ortho or ""):lower())
        -- Only u/a-vocalic roots + gh/dh: bruigh, craigh, buaigh, cruaidh.
        -- NOT bare -igh verbs (beirigh→i), -eadh (→u), or plain á nouns (lá).
        if (w_j:match("[uao]igh$") or w_j:match("uaidh$")) and not w_j:find(" ") then
          local last_t = nil
          for i = #tokens, 1, -1 do
            local t = tokens[i]
            if t.phon and t.phon ~= "" then last_t = t; break end
          end
          if last_t and last_t.type == "vowel" then
            local p = last_t.phon
            if p:find("ː", 1, true) or p == "uə" then
              last_t.phon = p .. "j"
            end
          end
        end
      end

      -- Ulster -íocht is [iaxt̪ˠ], not Connacht [iəxt̪ˠ] (barraíocht,
      -- coisíocht — benchmark Ulster rows use a full [a]).
      local w = (context.word_ortho or ""):lower()
      if w:match("[íi]ocht$") or w:match("[íi]ochta$") or w:match("íochtaí$") then
        for i, t in ipairs(tokens) do
          local nxt = tokens[i + 1]
          if t.type == "vowel" and t.phon == "iə" and nxt and
             nxt.type == "cons" and nxt.ortho == "ch" then
            t.phon = "ia"
          end
        end
      end
    end

    if context.dialect == "munster" then
      -- Munster: lexical a-quality corrections. MUNSTER_A_FRONT keeps front
      -- [a] where the backing rule over-applied (baile, maide, stair, banc);
      -- MUNSTER_A_REDUCE reduces pretonic [ɑ]→[ə] (atá, arán, paróiste).
      -- Benchmark-derived; a-backing and pretonic reduction are both
      -- lexically diffuse in Munster (FG Ch.5).
      local MUNSTER_A_FRONT = {
        ["-ail"]=true, ["acadamh"]=true, ["achadh"]=true, ["achaini"]=true,
        ["acson"]=true, ["altadh"]=true, ["asaibhse"]=true, ["baile"]=true,
        ["baile brigin"]=true, ["baile meanach"]=true, ["baile mor"]=true,
        ["bailigh"]=true, ["banc"]=true, ["barulach"]=true, ["bhanc"]=true,
        ["bhatar"]=true, ["bhfarraige"]=true, ["bhfarraigi"]=true,
        ["bhlais"]=true, ["bpaipear"]=true, ["brabusach"]=true,
        ["caithfidh"]=true, ["caitliceach"]=true, ["calrach"]=true,
        ["canach"]=true, ["canunach"]=true, ["carraigeacha"]=true,
        ["cearnog"]=true, ["cearnoga"]=true, ["cearta"]=true,
        ["charraigeacha"]=true, ["chearnog"]=true, ["chearta"]=true,
        ["ciseain"]=true, ["cisean"]=true, ["clainne"]=true, ["clais"]=true,
        ["cnaipe"]=true, ["dhath"]=true, ["eachtran"]=true,
        ["earraideach"]=true, ["fado"]=true, ["fadu"]=true,
        ["farraigi"]=true, ["fea"]=true, ["flea"]=true, ["francaigh"]=true,
        ["gaibh"]=true, ["gairm"]=true, ["galanta"]=true, ["gcearnog"]=true,
        ["gcearta"]=true, ["glantoir"]=true, ["laige"]=true, ["lea"]=true,
        ["maide"]=true, ["mairim"]=true, ["maitheamh"]=true, ["marai"]=true,
        ["mhair"]=true, ["mhaith"]=true, ["mhaithe"]=true,
        ["mhargadh"]=true, ["milseain"]=true, ["milsean"]=true,
        ["n-achaini"]=true, ["n-each"]=true, ["pacail"]=true,
        ["paipear"]=true, ["portach"]=true, ["praisigh"]=true,
        ["sa bhaile"]=true, ["scairteadh"]=true, ["stair"]=true,
        ["tarraingt"]=true, ["thar saile"]=true,
      }
      local MUNSTER_A_REDUCE = {
        ["-amh"]=true, ["-each"]=true, ["-far"]=true, ["abran"]=true,
        ["abulacht"]=true, ["aduaidh"]=true, ["aduain"]=true,
        ["aduaine"]=true, ["agoid"]=true, ["amhain"]=true, ["amuigh"]=true,
        ["anocht"]=true, ["aprun"]=true, ["aran"]=true, ["araon"]=true,
        ["aru"]=true, ["ata"]=true, ["ataim"]=true, ["ataimid"]=true,
        ["atathar"]=true, ["bacach"]=true, ["bacai"]=true,
        ["bagaiste"]=true, ["bagun"]=true, ["baruil"]=true,
        ["bhacach"]=true, ["brachan"]=true, ["bradach"]=true,
        ["cabach"]=true, ["canail"]=true, ["carbon"]=true,
        ["carbonach"]=true, ["casog"]=true, ["catan"]=true,
        ["crannog"]=true, ["d'fhogair"]=true, ["damaiste"]=true,
        ["damhan"]=true, ["fadalach"]=true, ["gabhala"]=true,
        ["gabhaltas"]=true, ["gadai"]=true, ["galan"]=true,
        ["gallan"]=true, ["gasog"]=true, ["haran"]=true,
        ["i dtolamh"]=true, ["i dtratha"]=true, ["i lathair"]=true,
        ["marog"]=true, ["maros"]=true, ["matan"]=true, ["matanach"]=true,
        ["n-aran"]=true, ["ngadai"]=true, ["paroiste"]=true,
        ["pharoiste"]=true, ["saboid"]=true, ["sacan"]=true, ["salu"]=true,
        ["spadanta"]=true, ["stagun"]=true, ["talun"]=true,
      }
      local mun_w = S.strip_fadas(((context.word_ortho or ""):lower()))
      if MUNSTER_A_FRONT[mun_w] then
        for _, t in ipairs(tokens) do
          if t.type == "vowel" and t.phon == "ɑ" then t.phon = "a" end
        end
      elseif MUNSTER_A_REDUCE[mun_w] then
        -- reduce only the FIRST (pretonic) ɑ
        for _, t in ipairs(tokens) do
          if t.type == "vowel" and t.phon == "ɑ" then t.phon = "ə"; break end
        end
      end

      -- Munster: more lexical vowel-quality corrections (benchmark-derived):
      -- ə→ɪ (pretonic ui/oi keeps ɪ: muinín, fuinneoga, oíche final),
      -- ɪ→ə (reduction wins: piléar, oileáin, -aigh verb endings),
      -- ɔ→ɞ (Munster lowered-central allophone: cois, ocht, folt),
      -- ə→ɔ (pretonic o keeps quality: dochtúir, potaí).
      local MUNSTER_E_TO_I = {
        ["aisling"]=true, ["bruitineach"]=true, ["buicead"]=true,
        ["buideal"]=true, ["buideil"]=true, ["ceirin"]=true,
        ["ciclipeid"]=true, ["coilean"]=true, ["coinnioll"]=true,
        ["coirce"]=true, ["cuinneog"]=true, ["deinimid"]=true,
        ["fairsing"]=true, ["feiliuint"]=true, ["feiliunach"]=true,
        ["fuinneoga"]=true, ["gaolainn"]=true, ["mhuinil"]=true,
        ["muineachan"]=true, ["muinin"]=true, ["muinineach"]=true,
        ["muirin"]=true, ["oiche"]=true, ["puisin"]=true, ["puithin"]=true,
        ["rinci"]=true, ["scilling"]=true, ["sluaiste"]=true,
        ["suimiuil"]=true, ["suipear"]=true, ["suiri"]=true,
      }
      local MUNSTER_I_TO_E = {
        ["aithis"]=true, ["bileogach"]=true, ["carraige"]=true,
        ["ceannaigh"]=true, ["cheannaigh"]=true, ["corcaigh"]=true,
        ["deachaigh"]=true, ["deireadh seachtaine"]=true, ["deisigh"]=true,
        ["dhiaidh"]=true, ["diaidh"]=true, ["firead"]=true,
        ["flaithis"]=true, ["inneosad"]=true, ["oileain"]=true,
        ["oileanach"]=true, ["phileir"]=true, ["pilear"]=true,
        ["pileir"]=true, ["sileog"]=true, ["sinead"]=true,
        ["teastaigh"]=true, ["tibeidis"]=true,
      }
      local MUNSTER_O_LOW = {
        ["cois"]=true, ["cor"]=true, ["cosaint"]=true, ["folcadh"]=true,
        ["folcaim"]=true, ["folt"]=true, ["loisc"]=true, ["ocht"]=true,
        ["olann"]=true, ["sop"]=true, ["sroistint"]=true, ["stoc"]=true,
        ["tosaigh"]=true,
      }
      local MUNSTER_E_TO_O = {
        ["bolcanach"]=true, ["colur"]=true, ["corru"]=true, ["cotun"]=true,
        ["dhochtuir"]=true, ["dhochtuiri"]=true, ["dochtuir"]=true,
        ["dochtuiri"]=true, ["dochtura"]=true, ["ndochtuiri"]=true,
        ["poll"]=true, ["potai"]=true,
      }
      if MUNSTER_E_TO_I[mun_w] then
        for _, t in ipairs(tokens) do
          if t.type == "vowel" and t.phon == "ə" then t.phon = "ɪ"; break end
        end
      end
      if MUNSTER_I_TO_E[mun_w] then
        for i = #tokens, 1, -1 do
          local t = tokens[i]
          if t.type == "vowel" and t.phon == "ɪ" then t.phon = "ə"; break end
        end
      end
      if MUNSTER_O_LOW[mun_w] then
        for _, t in ipairs(tokens) do
          if t.type == "vowel" and t.phon == "ɔ" then t.phon = "ɞ"; break end
        end
      end
      if MUNSTER_E_TO_O[mun_w] then
        for _, t in ipairs(tokens) do
          if t.type == "vowel" and t.phon == "ə" then t.phon = "ɔ"; break end
        end
      end

      -- Munster: conditional/past-habitual -f(e)adh ends in [əx], not bare
      -- [ə] (chasfadh→kɑsˠəx, bhrisfeadh→vʲɾʲɪʃəx). Hickey III.2: Munster
      -- retains the -dh reflex as [x] in verb endings. 21 vs 5 in benchmark;
      -- the 5 exceptions (oilfeadh class → hu) are lexical.
      do
        local w_f = S.strip_fadas((context.word_ortho or ""):lower())
        local FEADH_NOT_X = { ["d'oilfeadh"]=true, ["n-oilfeadh"]=true,
          ["oilfeadh"]=true, ["feadh"]=true, ["bhfeadh"]=true }
        if w_f:match("f[e]?adh$") and not FEADH_NOT_X[w_f] and not w_f:find(" ") then
          -- append x after the final schwa if the dh was silenced
          local last_t = nil
          for i = #tokens, 1, -1 do
            local t = tokens[i]
            if t.phon and t.phon ~= "" then last_t = t; break end
          end
          if last_t and last_t.type == "vowel" and last_t.phon == "ə" then
            last_t.phon = "əx"
          end
        end

        -- Munster: word-final orthographic -th keeps [h] (gaoth→ɡeːh,
        -- rith→ɾˠɪh) — EXCEPT after fada á/ú (bláth→bˠl̪ˠɑː, tnúth, scáth)
        -- where the h deletes. Hickey I.2.2: Munster retains final /h/;
        -- benchmark 39 keep vs 8 drop, all droppers have á/ú spellings.
        local raw_w = (context.word_ortho or ""):lower()
        -- byte-wise: á=\xC3\xA1, ú=\xC3\xBA (UTF-8); match either fada + optional i + th
        local ath_drop = raw_w:match("\xC3[\xA1\xBA]i?th$") ~= nil
        if w_f:match("th$") and not ath_drop and not w_f:find(" ") then
          for i = #tokens, 1, -1 do
            local t = tokens[i]
            if t.type == "cons" and t.ortho == "th" then
              if t.phon == "" then
                -- restore h only after a vowel (not after obstruent devoicing)
                local prev = nil
                for j = i - 1, 1, -1 do
                  if tokens[j].phon and tokens[j].phon ~= "" then prev = tokens[j]; break end
                end
                if prev and prev.type == "vowel" then t.phon = "h" end
              end
              break
            end
          end
        end
      end

      -- Munster word-final -igh/-aigh/-aidh/-idh keeps a real palatal stop:
      -- [ɪɟ] after a consonant (bealaigh→bʲal̪ˠɪɟ, doiligh→d̪ˠɪlʲɪɟ), bare [ɟ]
      -- after a long vowel or diphthong (dóigh→d̪ˠoːɟ, luaigh→l̪ˠuəɟ).
      -- Hickey I.2.2/III.2: Munster retains final /ɟ/ where Connacht
      -- vocalizes or deletes. Future -f- forms excluded (molfaidh→mˠɔl̪ˠhə
      -- keeps the Connacht-style h-suffix path; benchmark is split there).
      local w = (context.word_ortho or ""):lower()
      local is_igh = w:match("[aeiíáéó]igh$") or w:match("igh$")
        or w:match("aidh$") or w:match("idh$")
      local is_future_f = w:match("f[ae]?aidh$") or w:match("f[ei]?idh$")
      if is_igh and not is_future_f and not w:find(" ") then
        -- Find last vowel with non-empty phon and the trailing gh/dh token.
        local last_v, gh_tok = nil, nil
        for i = #tokens, 1, -1 do
          local t = tokens[i]
          if not gh_tok and t.type == "cons" and (t.ortho == "gh" or t.ortho == "dh") then
            gh_tok = t
          elseif t.type == "vowel" and t.phon and t.phon ~= "" then
            last_v = t
            break
          end
        end
        if last_v and gh_tok then
          local p = last_v.phon
          local is_long = p:find("ː", 1, true) ~= nil or p == "uə" or p == "iə" or p == "ai" or p == "əi"
          if is_long and (p == "iː") then
            -- iː from IGH_RESTORE is the suffix vowel itself → ɪɟ
            last_v.phon = "ɪ"
            gh_tok.phon = "ɟ"
          elseif is_long then
            -- root long vowel/diphthong: keep it, add final ɟ
            gh_tok.phon = "ɟ"
          elseif p == "ə" or p == "ɪ" or p == "i" then
            last_v.phon = "ɪ"
            gh_tok.phon = "ɟ"
          end
        end
      end

      -- Munster éa-breaking: long éa [eː] breaks to [iːa̯] under stress and
      -- [ia̯] pretonic (Hickey I.2.2: Munster ia-diphthongization of éa —
      -- méar→mʲiːa̯ɾˠ, bréag→bʲɾʲiːa̯ɡ, éadóchasach→ia̯ˈd̪ˠoː...).
      -- Only orthographic éa (not ao/aou/é alone) breaks.
      -- Length: [iːa̯] when the éa syllable itself is prominent, [ia̯] when a
      -- LATER syllable carries the stress (pretonic shortening:
      -- éadóchasach→ia̯ˈd̪ˠoː...). Only FIRST-SYLLABLE éa breaks — loanwords
      -- with éa in later syllables (piléar, páipéar, buidéal, coirnéal)
      -- keep [eː] (Hickey I.2.2: breaking is confined to root syllables).
      for i, t in ipairs(tokens) do
        if t.type == "vowel" and t.phon == "eː" and t.ortho == "éa" then
          local earlier_vowel = false
          for j = 1, i - 1 do
            local u = tokens[j]
            if u.type == "boundary" then earlier_vowel = false
            elseif u.type == "vowel" and u.phon and u.phon ~= "" then earlier_vowel = true end
          end
          if not earlier_vowel then
            local later_stress = false
            for j = i + 1, #tokens do
              local u = tokens[j]
              if u.type == "vowel" and (u.stress or u.secondary) then
                later_stress = true
                break
              end
            end
            t.phon = later_stress and "ia̯" or "iːa̯"
          end
        end
      end

      -- Munster sonorant notation normalization (moved here from the end of
      -- pass 13 so pass-14-created sonorants are covered too): broad l/n are
      -- dental, slender l/n are plain palatal (benchmark Munster convention;
      -- empirical winner over Hickey's clean 2-way description).
      local MUNSTER_SONORANTS = {
        ["l\xcb\xa0"] = "l\xcc\xaa\xcb\xa0",           -- lˠ → l̪ˠ
        ["n\xcb\xa0"] = "n\xcc\xaa\xcb\xa0",           -- nˠ → n̪ˠ
        ["l\xcc\xa0\xca\xb2"] = "l\xca\xb2",           -- l̠ʲ → lʲ
        ["n\xcc\xa0\xca\xb2"] = "n\xca\xb2",           -- n̠ʲ → nʲ
      }
      -- Lexical exceptions: ~73 words keep LENIS lˠ/nˠ (no dental) — mostly
      -- Cl-/Pl-/Bl- loanword onsets and words with an l/n after a long vowel
      -- (plás, olca, barda, eolais, coláiste, punt...). Benchmark-verified.
      local MUNSTER_NO_DENTAL = {
        ["a lan"]=true, ["ar son"]=true, ["bal"]=true, ["barda"]=true,
        ["bhfagalacha"]=true, ["bhun"]=true, ["blafar"]=true,
        ["blarna"]=true, ["blean"]=true, ["bpianadh"]=true, ["brean"]=true,
        ["cal ceannann"]=true, ["chloch"]=true, ["chun"]=true,
        ["clairneid"]=true, ["clairseach"]=true, ["clairseacha"]=true,
        ["clocasach"]=true, ["clogaid"]=true, ["clogaide"]=true,
        ["cnaib"]=true, ["cnaibe"]=true, ["colaiste"]=true,
        ["colaisti"]=true, ["comhlacht"]=true, ["d'fhas"]=true,
        ["dala"]=true, ["dana"]=true, ["daonra"]=true, ["diul"]=true,
        ["dola"]=true, ["donasach"]=true, ["dtalamh"]=true, ["eol"]=true,
        ["eolais"]=true, ["fagala"]=true, ["fagalacha"]=true,
        ["fanach"]=true, ["faol"]=true, ["gloir"]=true, ["gloire"]=true,
        ["granach"]=true, ["holc"]=true, ["lana"]=true, ["malai"]=true,
        ["maola"]=true, ["mhalairt"]=true, ["mhna"]=true, ["mhol"]=true,
        ["mholadh"]=true, ["mola"]=true, ["molann"]=true, ["molas"]=true,
        ["monabhar"]=true, ["ngrian"]=true, ["olca"]=true,
        ["phianadh"]=true, ["pianadh"]=true, ["plas"]=true, ["plata"]=true,
        ["platai"]=true, ["plodaithe"]=true, ["pol"]=true, ["punt"]=true,
        ["riachtanas"]=true, ["scolaireacht"]=true, ["sobal"]=true,
        ["soladach"]=true, ["stairiuil"]=true, ["t-oganach"]=true,
        ["tal"]=true, ["trealamh"]=true, ["tsal"]=true,
      }
      -- Words that KEEP tense postalveolar l̠ʲ/n̠ʲ despite the plain-slender
      -- default — geminate -inn(e)/-ill(e) forms and tense-l onsets
      -- (fáinne, cruinne, Éirinn, sloinne, leor, muintir...).
      local MUNSTER_KEEP_POSTALV = {
        ["-uint"]=true, ["aille"]=true, ["airne"]=true, ["bairnigh"]=true,
        ["bhfainne"]=true, ["bhfainni"]=true, ["bhfearthainn"]=true,
        ["cairn"]=true, ["chruinne"]=true, ["cinneadh"]=true,
        ["cinnire"]=true, ["cruinne"]=true, ["cuinne"]=true,
        ["eirinn"]=true, ["fainni"]=true, ["fearthainn"]=true,
        ["fearthainne"]=true, ["fhainne"]=true, ["fheamainn"]=true,
        ["fhearthainn"]=true, ["fhuinneoig"]=true, ["finn"]=true,
        ["fuinneamh"]=true, ["fuinneoig"]=true, ["gcuinne"]=true,
        ["go leor"]=true, ["grinne"]=true, ["h-eirinn"]=true,
        ["heirinn"]=true, ["inne"]=true, ["leabaidh"]=true,
        ["leagfaidh"]=true, ["leanaim"]=true, ["learo"]=true,
        ["leas"]=true, ["leictreachas"]=true, ["leith"]=true,
        ["leitheoireacht"]=true, ["leor"]=true, ["li"]=true,
        ["ligfidh"]=true, ["linne"]=true, ["meilleog"]=true,
        ["milseog"]=true, ["muintearthas"]=true, ["muintir"]=true,
        ["nil"]=true, ["oscailt"]=true, ["pinn"]=true, ["pointe"]=true,
        ["sainn"]=true, ["shinsir"]=true, ["shloinne"]=true,
        ["sinne"]=true, ["sinsear"]=true, ["sinsir"]=true, ["slea"]=true,
        ["sliseog"]=true, ["sloinne"]=true, ["spainn"]=true,
        ["spainne"]=true, ["tainte"]=true, ["tairne"]=true,
        ["thugainn"]=true, ["torainn"]=true,
      }
      local mw = S.strip_fadas(((context.word_ortho or ""):lower()))
      local skip_dental = MUNSTER_NO_DENTAL[mw]
      local keep_postalv = MUNSTER_KEEP_POSTALV[mw]
      for _, t in ipairs(tokens) do
        if t.type == "cons" and t.phon and MUNSTER_SONORANTS[t.phon] then
          local is_broad = (t.phon == "l\xcb\xa0" or t.phon == "n\xcb\xa0")
          if is_broad then
            if not skip_dental then t.phon = MUNSTER_SONORANTS[t.phon] end
          else
            if not keep_postalv then t.phon = MUNSTER_SONORANTS[t.phon] end
          end
        end
      end
    end

    return tokens
  end,
}
