import json
import os
import time
import requests
from collections import Counter, defaultdict
from creds import url_hue

s = 0

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

def get_prediction(timestamp):
    
    url = 'http://127.0.0.1:8080/predict-hue'
    headers ={'content-type':'application/json'}
    data = {"timestamp": str(timestamp)}

    response = requests.post(url, headers = headers,
                            params = data)
    
    return int(response.content)

def api_comms(timestamp):
    
    urls = [url_hue + "/1/state",url_hue + "/2/state"]
    n = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    n1 = datetime.datetime.now().strftime("%Y-%m-%d")

    
    filename = 'pred_log_%s.json' % n1

    pred = get_prediction(timestamp)
    
    if (pred == 0):
        on = False
        bri = 0
    else:
        on = True
        bri = pred
        
    data = {'on': on, 'bri' : bri}

    def response(url):
        response = requests.put(url,data = json.dumps(data))
        return response.content

    l = [response(i) for i in urls]
    l.append(n)
    
    with open(filename, 'a') as f:
        json.dump(l, f)
        f.write('\n')
