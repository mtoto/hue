#!/usr/bin/python

import requests
import datetime
import json
from creds import url_hue

""" Get lights data """
def download_data():

    current_date = datetime.datetime.now().strftime('%Y-%m-%d')
    current_time = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    d_time = {'log_time' : current_time }
    
    filename = '/home/pi/home_iot/hue/json/lights_data_%s.json' % current_date
    
    url = url_hue
    response = requests.get(url)
    json_data = json.loads(response.text)

    hue_dict = dict(json_data, **d_time)

    with open(filename, 'a') as f:
        json.dump(hue_dict, f)
        f.write('\n')

download_data()
