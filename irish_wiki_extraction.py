# -*- coding: utf-8 -*-
"""
Created on Tue Mar 18 07:26:13 2025

@author: hellpanderrr
"""
import re
import pandas as pd
import json
import csv, json

path = r'C:\Users\hellpanderrr\Downloads\kaikki.org-dictionary-Irish.jsonl'
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

with open('irish_ss.csv','w', newline='', encoding='utf-8') as out:
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


df = pd.read_csv('irish_ss.csv')
df = df[['word','sounds','tags_']].drop_duplicates()
from numpy import nan

df['sounds'] = df.sounds.apply(lambda x:nan if not eval(x) else x)
df = df.dropna(subset='sounds')
df['tags_']=df.tags_.apply(eval).apply(lambda x:[i for i in x if i[0].isupper()])

df.to_csv('irish.csv')


final = pd.concat(df.apply(lambda x:  pd.DataFrame(eval(x.sounds)).assign(word=x.word,tags_=str(x.tags_)) ,axis=1).values)

final.tags = final.tags.apply(lambda x:'; '.join([dialect_mapping.get(i,'') for i in x]) if hasattr(x,'__iter__') else '')
final.tags_ = final.tags_.apply(eval).apply(lambda x:'; '.join([dialect_mapping.get(i,'') for i in x]) if hasattr(x,'__iter__') else '')

final.to_csv('final.csv')



dialect_mapping = {
    'Aran': 'Connacht Irish',
    'Cois-Fharraige': 'Connacht Irish',
    'Connacht': 'Connacht Irish',
    'Connemara': 'Connacht Irish',
    'Galway': 'Connacht Irish',
    'Mayo': 'Connacht Irish',
    'West': 'Connacht Irish',
    'Cork': 'Munster Irish',
    'Kerry': 'Munster Irish',
    'Munster': 'Munster Irish',
    'South': 'Munster Irish',
    'Waterford': 'Munster Irish',
    'West-Cork': 'Munster Irish',
    'West-Kerry': 'Munster Irish',
    'Ulster': 'Ulster Irish',
    'East': 'Unknown/Not Mapped',
    'General-American': 'Not Irish',
    'Standard': 'Standard Irish',
    'Greek': 'Not Irish',
    'Hinduism': 'Not Irish',
    'Internet': 'Not Irish',
    'Irish': 'General Irish',
    'Judaism': 'Not Irish',
    'Roman': 'Not Irish',
    'UK': 'Not Irish'
}
