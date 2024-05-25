# -*- coding: utf-8 -*-
'''
Function: This file fetches data from FRED and calculates the share of corporate in corporate and noncorporate assets 
Source: https://fred.stlouisfed.org/ 
'''

# fetch FRED's data

import pandas as pd
import json
from datetime import datetime
from datetime import timedelta
import requests
import time
import numpy as np

def convert_sec(timestamp):
    if timestamp < 0:
        return datetime(1970, 1, 1) + timedelta(seconds=timestamp)
    else:
        return datetime.utcfromtimestamp(timestamp)

# cd to Concentration_USA/programs_aer/code/clean

output_path = "../../output/other"    
    
# fetch TABSNNCB TABSNNB BOGZ1LM115035023A NNBEMVA027N BOGZ1FL235035005A BOGZ1FL105035023A BOGZ1LM105035005A BOGZ1LM115035005A BOGZ1FL185035005A

var_code_list = ["TABSNNCB", "TABSNNB", "BOGZ1LM115035023A", "NNBEMVA027N", "BOGZ1FL235035005A", "BOGZ1FL105035023A", "BOGZ1LM105035005A", "BOGZ1LM115035005A", "BOGZ1FL185035005A"]

df_list = []

for var_code in var_code_list:
    print(var_code)
    response = requests.get(f'https://fred.stlouisfed.org/graph/api/series/?id={var_code}&obs=true') 
    
    df_lst = response.json()['observations'][0]
    df = pd.DataFrame(df_lst)
    df.columns = ['Timestamp',var_code]
    # to seconds
    df['Timestamp'] = df['Timestamp']/1e3
    
    df['date'] = df['Timestamp'].apply(lambda x: convert_sec(x))
    df['year'] = df['date'].apply(lambda x: x.year)
    df = df[['year',var_code]]
    
    # groupby year mean
    df = df.groupby('year')[var_code].mean().reset_index()
    df_list.append(df)
    # sleep to avoid request error
    time.sleep(1)


# concat
for i in range(len(df_list)):
    if i == 0:
        all_df = df_list[i]
    else:
        all_df = all_df.merge(df_list[i], on = 'year', how = 'outer')


# rename
all_df = all_df.rename({"BOGZ1FL235035005A":"noncorp_farm_re","BOGZ1FL185035005A":"corp_farm_re","BOGZ1FL105035023A":"corp_resre","BOGZ1LM115035023A":"noncorp_resre","BOGZ1LM105035005A":"corp_re","BOGZ1LM115035005A":"noncorp_re","TABSNNCB":"corp_at","TABSNNB":"noncorp_at"}, axis = 1)


# rescale
all_df['corp_at'] = all_df['corp_at']*1e3
all_df['noncorp_at'] = all_df['noncorp_at']*1e3

all_df['corp_at_shr'] = (all_df['corp_at'] - all_df['corp_farm_re'] - all_df['corp_resre'])/(all_df['corp_at'] + all_df['noncorp_at'] - all_df['corp_farm_re'] - all_df['noncorp_farm_re'] - all_df['corp_resre'] - all_df['noncorp_resre'])


# output

# Define variable labels
variable_labels = {
    'corp_at_shr': 'Corporate Asset Share (No Farm No Residential RE)'
}


all_df = all_df[['year','corp_at_shr']]
all_df.to_stata(f"{output_path}/fof.dta", write_index = False, variable_labels=variable_labels)
 

