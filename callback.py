import datetime
import time
from functions import *

def callback():
    #now1=datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    starttime=time.time()
    if s == 0:
        while True:
            now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            api_comms(now)
            print(now)
            time.sleep(300.0 - ((time.time() - starttime) % 300.0))
            
callback()