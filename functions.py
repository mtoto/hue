import json
import os
from collections import Counter, defaultdict

# Convert json to a list of dicts
def json_parser(file):
    
    result =[]
    cols = ['name','type','modelid']
    state_cols = ['on','reachable','bri','alert']
    
    for line in file:

        data = json.loads(line)
        gen = (x for x in data.keys() if x in ["1","2"])
        lamp_log = {'log_time': data['log_time']}

        lamp_name = []
        lamp_state = []

        for key in gen:

            state = data[key]['state']

            lamp_name.append( { k+'.'+str(key): data[key][k] for k in cols} )
            lamp_state.append( { k+'.'+str(key): state[k] for k in state_cols } )

            res = lamp_name + lamp_state
            d = { k: v for d in res for k, v in d.items() }

            d = dict(d, **lamp_log)
            d.update(lamp_log)
            result.append(d)
        
    return result
