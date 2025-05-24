import pandas as pd

df = pd.read_csv('final_connacht.csv')
df = df.sample(2000)
df.to_csv('final_connacht_sample.csv', index=False)
