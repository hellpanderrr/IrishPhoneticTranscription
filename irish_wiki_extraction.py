# -*- coding: utf-8 -*-
"""
Created on Tue Mar 18 07:26:13 2025

@author: hellpanderrr
"""
import re
import pandas as pd
import json
import csv, json


raise
path = r'F:\projects\transcription\wiktionary_ipa_phoneme_lexicons\kaikki.org-dictionary-Irish.jsonl'
jsons = []
with open(path, encoding='utf-8') as f:
    for n,line in enumerate(f):
        if n%10000==0:
            print(n,end=';')
        raw = json.loads(line)
        pos = raw.get('pos')
        forms = raw.get('forms',[])
        word = raw.get('word',{})
        sounds = raw.get('sounds',{})
        #if forms:
        senses = raw.get('senses',{})[0]
        glosses = senses.get('glosses',{})
        tags = senses.get('tags',{})
        form_of = senses.get('form_of',{})
        exp = raw.get('head_templates',[{}])[0].get('expansion','')
        head = raw.get('head_templates',[{}])[0].get('args',{}).get('head')
        pos_2 = raw.get('head_templates',[{}])[0].get('args',{}).get('2')

        jsons.append({'forms':forms, 'word':word, 'exp':exp, 'head':head, 'glosses':glosses,'tags_':tags, 'form_of':form_of, 'senses':senses, 'pos':pos,'pos_2':pos_2,'sounds':sounds})
    
# dfs = []
# for n,i in enumerate(jsons):
#     df = None
#     if n%10000==0:
#         print(n,end=';')
#     if i['forms']:
#         df = pd.DataFrame(i['forms'])

#         df['pos'] = i['pos']
#         df['pos_2'] = i['pos_2']
#         df['word'] = i['word']
#         df['exp'] = i['exp']
#         df['head'] = i['head']
#         df['glosses'] = str(i['glosses'])
#         df['tags_'] = str(i['tags_'])
#         df['form_of'] = str(i['form_of'])
#         dfs.append(df)
    
# final = pd.concat(dfs)
# final.to_csv('final_ss.csv')


all_keys = set()
for entry in jsons:
    for f in entry.get('forms', []):
        all_keys.update(f.keys())

# 2) Define your fixed parent fields:
fixed = ['pos','pos_2','word','exp','head','glosses','tags_','form_of','sounds']

# 3) Combine into a single list:
fieldnames = list(all_keys) + fixed

with open('irish_ss2.csv','w', newline='', encoding='utf-8') as out:
    writer = csv.DictWriter(
        out,
        fieldnames=fieldnames,
        extrasaction='ignore'      # drop any key not in fieldnames
    )
    writer.writeheader()

    for n, entry in enumerate(jsons):
        if n % 10000 == 0:
            print(f'Processed {n} entries…', end=';')
        base = {
            'pos':     entry.get('pos'),
            'pos_2':   entry.get('pos_2'),
            'word':    entry.get('word'),
            'exp':     entry.get('exp'),
            'head':    entry.get('head'),
            'glosses': json.dumps(entry.get('glosses', []), ensure_ascii=False),
            'tags_':   json.dumps(entry.get('tags_',   []), ensure_ascii=False),
            'form_of': json.dumps(entry.get('form_of', []), ensure_ascii=False),
            'sounds': json.dumps(entry.get('sounds', []), ensure_ascii=False)
        }
        for f in entry.get('forms', []):
            row = {**f, **base}
            writer.writerow(row)
        if not entry.get('forms', []):
            writer.writerow(base)

df = pd.read_csv('irish_ss2.csv')
df = df[['word','sounds','tags_']].drop_duplicates()
from numpy import nan

df['sounds'] = df.sounds.apply(lambda x:nan if not eval(x) else x)
df = df.dropna(subset='sounds')
df['tags_'] = df.tags_.apply(eval).apply(lambda x:[i for i in x if i[0].isupper()])

df.to_csv('irish.csv')

base = df
base = pd.read_csv('irish.csv')

final = pd.concat(base.drop_duplicates(['word','sounds']).apply(lambda x:  pd.DataFrame(eval(x.sounds)).assign(word=x.word,tags_=str(x.tags_)) ,axis=1).values)
final.ipa[final.ipa.isna() & ~final.other.isna() ] = final.other[final.ipa.isna() & ~final.other.isna() ]


final['region'] = final.tags.apply(lambda x:'; '.join([dialect_mapping.get(i,i) for i in x]) if hasattr(x,'__iter__') else '')

#final.tags_ = final.tags_.apply(eval).apply(lambda x:'; '.join([dialect_mapping.get(i,'') for i in x]) if hasattr(x,'__iter__') else '')

final = final[['tags', 'ipa', 'word', 'region']]

final.tags = final.tags.apply(lambda x:'; '.join(x) if type(x)==list else x)

g = final.fillna('').groupby(['ipa','word']).agg(list).reset_index()

g.tags = g.tags.apply(lambda x:'; '.join(filter(bool,x)) if type(x)==list  else '')



g = g.groupby(['word','tags']).agg(list).reset_index()

g.region = g.region.apply(lambda x:sum(x,[])).apply(lambda x:'; '.join(filter(bool,x)) if type(x)==list  else '')
g.ipa = g.ipa.apply(lambda x:', '.join(filter(bool,x)))
g.ipa = g.ipa.str.replace('/','').str.replace('[','').str.replace(']','')

g.tags = g.tags.apply(lambda x: '; '.join(set(x.split('; '))))


g.drop('region',axis=1).to_csv('group.csv',index=False)



final.to_csv('final.csv')



dialect_mapping = {
    'Aran': 'Connacht',
    'Cois-Fharraige': 'Connacht',
    'Connacht': 'Connacht',
    'Connemara': 'Connacht',
    'Galway': 'Connacht',
    'Mayo': 'Connacht',
    'West': 'Connacht',
    'Cork': 'Munster',
    'Kerry': 'Munster',
    'Munster': 'Munster',
    'South': 'Munster',
    'Waterford': 'Munster',
    'West-Cork': 'Munster',
    'West-Kerry': 'Munster',
    'Ulster': 'Ulster',
    'East': 'Unknown/Not Mapped',
    'General-American': 'Not',
    'Standard': 'Standard',
    'Greek': 'Not',
    'Hinduism': 'Not',
    'Internet': 'Not',
    'Irish': 'General',
    'Judaism': 'Not',
    'Roman': 'Not',
    'UK': 'Not'
}


words_to_test_focused_37AA = [
    "dubh", "samhradh", "cnámh", "nimhe", "aghaidh", "suidhe", "leabhar", "bóthar", 
    "cat", "fios", "coill", "gort", 
    "caol", "gaoth", "aoibhinn", "móin", 
    "bord", "poll", "fonn", "drochbhean", "ceann",
    "beannaigh" 
]


words_to_test_full_37AA = [
"fhéach", "fhág", "fhíor", "fhostaigh", "fhuair", "scríobh", "teach", "deartháir", "cat", "bord", "ceann", "poll", "balla", "leabhar", "samhradh", "beannacht", "fonn",
"leagan", "teanga", "seacht", "aghaidh", "suidhe", "nimhe", "bóthar", "oíche", "fear", "glaic", "muc", "fliuch", "fada", "beag", "séimhiú", "úrú", "bacach", 
"isteach", "baile", "duine", "Gaeltacht", "Conamara", "Gaeilge", "aoibhinn", "buí", "caol", "leathan", "drochbhean", "an-mhaith", "fuinneog", "oiliúint", 
"staighre", "fios", "athbhliain", "comhrá", "mícheart", "oícheanta", "codladh", "luigh", "fiche", "duchaise", "saibhir", "deacair", "sláinte", "ceart", "lae", 
"laoch", "aer", "ceo", "ceol", "coir", "coill", "faoi", "gaoth", "bádaí", "capaillí", "foclaí", "brógaí", "dearmad", "seomraí", "doras", "amhrán", "Banríon", 
"dearcadh", "dearfa", "mí-ádh", "droch-obair", "seanbhean", "bhean", "fíoruisce", "athchúrsáil", "an-fear", "an-oíche", "beart", "bean", "geal", "eagla", "muid", "duit", 
"fuil", "goil", "buil", "cuir", "druid", "luibh", "ceist", "ocht", "páiste", "sparán", "scéal", "bláth", "cnoc", "gnó", "dlí", "mná", "trá", "uisce", "obair", 
"imir", "eolas", "athair", "máthair", "deirfiúr", "imirt", "oibre", "ceacht", "ceistneoir", "ceistigh", "arm", "borb", "bolg", "garbh", "gorm", "gairm", "balbh", 
"seilbh", "dearg", "fearg", "colm", "ainm", "scrúdaigh", "cónaigh", "beannaigh",
"teann", "trom", "am", "cam", "gall", "tall", "dún", "dubh", "móin"
]

import subprocess
def get_transcription(greek_word):
    """
    Get transcription for a Greek word using the Lua script.

    This function calls the Lua script to get accurate IPA transcriptions.
    It also caches results to avoid repeated calls for the same word.
    """
    # Clean the word (remove punctuation)
    base = re.sub(r'[!?.,;:]', '', greek_word)
    print(f'Processing {greek_word} -> {base}')

    # Skip words without any alphabetic characters
    if not any(c.isalpha() for c in base):
        return ''

  
    try:
        # Call the Lua script to get the pronunciation
        proc = subprocess.run(            [r'f:\soft\lua\luajit.exe', r'F:\projects\transcription\wiktionary_ipa_phoneme_lexicons\irish\irish.lua'], input=base,                                    timeout=5,text=True,encoding='utf-8',capture_output=True)
        # Extract the pronunciation from the output
        pron = proc.stdout.strip()

        return pron
    except subprocess.TimeoutExpired:
        print(f"Timeout processing word: {base}")
        return "[Timeout]"
    except subprocess.CalledProcessError as e:
        print(f"Error processing word '{base}': {e.stderr.decode('utf8').strip()}")
        # Fall back to a simple transcription if the Lua script fails
        return base
    
def batch_transcribe(words):
    cmd = [
        r'f:\soft\lua\luajit.exe', 
        r'F:\projects\transcription\wiktionary_ipa_phoneme_lexicons\irish\irish.lua']

    
    with subprocess.Popen(
        cmd,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        text=True,
        encoding='utf-8',
        bufsize=1  # Line buffering
    ) as proc:
        for word in words:
            proc.stdin.write(word + "\n")
            proc.stdin.flush()
            yield proc.stdout.readline().strip()    
    
    
import json

df = pd.read_csv('connacht.csv')
df['results'] = df.word.apply(get_transcription)
print(df[df.ipa.str.replace(r"[ˠʲˈ']", '', regex=True).str[0] != df.results.str.replace(r"[ˠʲˈ']", '', regex=True).str[0]].shape)
df[df.ipa.str.replace(r"[ˠʲˈ']", '', regex=True).str[0] != df.results.str.replace(r"[ˠʲˈ']", '', regex=True).str[0]].sample(1000).sort_values('word').to_csv('errors_38.csv')

ws = df.word
results = []
for batch in [ws[i:i+50] for i in range(0,len(ws),50)]:
    with_spaces = batch[batch.str.split(' ').apply(len)>1]
    without_spaces = batch[batch.str.split(' ').apply(len)==1]
    results_no_spaces = get_transcription(' '.join(without_spaces)).split(' ')
    results_spaces = [get_transcription(i) for i in with_spaces]
    no_space = pd.concat([without_spaces,pd.Series(results_no_spaces,index=without_spaces.index,name='results')],axis=1)
    space = pd.concat([with_spaces,pd.Series(results_spaces,index=with_spaces.index,name='results')],axis=1)
    final = pd.concat([no_space,space])
    results.append(final)
df['results'] = pd.concat(results).results

cleaned_ipa = df['ipa'].str.replace(r'[ˠʲˈ]', '', regex=True)
cleaned_results = df['results'].str.replace(r'[ˠʲˈ]', '', regex=True)

# Create a mask: True only where cleaned_results is a non-empty substring of cleaned_ipa
df[[
    False if pd.isna(ipa) or pd.isna(res) or res == '' 
    else (res in ipa) 
    for ipa, res in zip(df['ipa'].str.replace(r'[ˠʲˈ]', '', regex=True),  df['results'].str.replace(r'[ˠʲˈ]', '', regex=True))
]]

366
793
1306
1049
1220
1496, #df['match'].mean() == 75.38749819128925 

1636, #75.38749819128925 #0.8988616991688039
from fuzzywuzzy import fuzz
import panphon.distance as D
x = D.Distance()
df['match']= [
    0 if pd.isna(ipa) or pd.isna(res) or res == '' 
    else (fuzz.partial_ratio(res ,  ipa) )
    for ipa, res in zip(df['ipa'],  df['results'])
]
df['match']= [
    0 if pd.isna(ipa) or pd.isna(res) or res == '' 
    else (1 - x.dolgo_prime_distance_div_maxlen(res ,  ipa) if len(ipa.split(', '))==1 else 
          1 - min([x.dolgo_prime_distance_div_maxlen(res ,  ipa_split) for ipa_split in ipa.split(', ')]))
    for ipa, res in zip(df['ipa'],  df['results'])
]


def dump_df(df, path='results.json'):
    json.dump(df.to_dict(orient='records'), open('results.json',encoding='utf-8',mode='w'),ensure_ascii=False)

json.dump(df[df.ipa.str.replace(r"[ˠʲˈ']", '', regex=True).str[0] != df.results.str.replace(r"[ˠʲˈ']", '', regex=True).str[0]].sample(200).sort_values('word').fillna('').to_dict(orient='records'), open('results.json',encoding='utf-8',mode='w'),ensure_ascii=False)

df[df.ipa.str.replace(r"[ˠʲˈ']", '', regex=True).str[0] != df.results.str.replace(r"[ˠʲˈ']", '', regex=True).str[0]].sample(1000).sort_values('word').to_csv('errors_42.csv')


idx=[  80,   81,  129,  138,  168,  181,  215,  261,  268,  271,  286,
        370,  409,  421,  422,  428,  432,  447,  486,  488,  490,  524,
        532,  558,  600,  666,  679,  707,  754,  767,  795,  940,  987,
        988,  998, 1002, 1024, 1040, 1059, 1398, 1410, 1415, 1460, 1461,
       1468, 1480, 1497, 1513, 1516, 1519, 1537, 1540, 1548, 1554, 1627,
       1690, 1696, 1700, 1704, 1706, 1709, 1792, 1800, 1897, 1904, 1978,
       1995, 1996, 2011, 2030, 2040, 2155, 2174, 2175, 2200, 2231, 2245,
       2249, 2250, 2256, 2258, 2319, 2321, 2323, 2348, 2364, 2366, 2545,
       2577, 2582, 2631, 2926, 3116, 3120, 3404, 3409, 3429, 3442, 3451,
       3457, 3460, 3465, 3489, 3503, 3522, 3536, 3546, 3561, 3577, 3611,
       3617, 3634, 3661, 3671, 3677, 3682, 3683, 3696, 3701, 3723, 3731,
       3743, 3745, 3759, 3761, 3763, 3764, 3773, 3784, 3801, 3831, 3846,
       3862, 3893, 3894, 3898, 3900, 3901, 3908, 3989, 4054, 4055, 4080,
       4128, 4131, 4135, 4137, 4345, 4455, 4634, 4636, 4644, 4645, 4648,
       4686, 4975, 4977, 5073, 5082, 5083, 5084, 5098, 5099, 5101, 5120,
       5122, 5618, 5641, 5656, 5663, 5669, 5680, 5689, 5692, 5693, 5707,
       5713, 5725, 5740, 5748, 5751, 5767, 5809, 5820, 5827, 5830, 5847,
       5897, 5905, 6103, 6112, 6260, 6266, 6651, 6690, 6701, 6713, 6761,
       6762, 6910]