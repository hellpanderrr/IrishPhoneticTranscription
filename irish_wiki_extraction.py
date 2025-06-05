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

