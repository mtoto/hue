# Luigi task to write clean files to aws
import luigi
import json
from luigi.s3 import S3Target, S3Client
from datetime import date, timedelta
from functions import *

class hue_raw_json(luigi.ExternalTask):
    date = luigi.DateParameter(default = date.today()-timedelta(1)) 

    def output(self):
        return luigi.LocalTarget('json/lights_data_%s.json' % 
                                 self.date.strftime('%Y-%m-%d'))
    
# Luigi task to write clean files to aws
class hue_copy_aws(luigi.Task):
    date = luigi.DateParameter(default = date.today()-timedelta(1)) 
    
    def requires(self):
        return self.clone(hue_raw_json)

    def output(self):
        client = S3Client(host = 's3.us-east-2.amazonaws.com')
        return S3Target('s3://ams-hue-data/lights_data_%s.json' % 
                        self.date.strftime('%Y-%m-%d'), 
                        client=client)

    def run(self):  
        with self.input().open('r') as i, self.output().open('w') as o:
            o.write(i.read())
            
# Task to parse relevant fields and merge a week of data
class hue_merge_weekly_aws(luigi.Task):
    date1 = luigi.DateParameter(default = date(2017, 5, 12))
    date2 = luigi.DateParameter(default = date.today())
    daterange = luigi.IntParameter((date.today()-date(2017, 5, 12)).days)

    def requires(self):
        return [hue_copy_aws(i) for i in [self.date1 + timedelta(x) for x in range(self.daterange)]]
        
    def output(self):
        client = S3Client(host = 's3.us-east-2.amazonaws.com')
        return S3Target('s3://ams-hue-data/hue_full_%s.json' % 
                        self.date2.strftime('%Y-%m-%d'), client=client)
    
    def run(self):
        results = []
        for file in self.input():
            
            with file.open('r') as in_file:
                parsed = json_parser(in_file)
                
            results.extend(parsed)
                    
        with self.output().open('w') as out_file:
            json.dump(results, out_file)

if __name__ == '__main__':
    luigi.run()
