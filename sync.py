#!/usr/bin/env python

import requests
import json
import time
from shutil import copyfile

class Sync:
    def unixtime(self):
        return int(time.time())

    def __init__(self, data=None):
        self.headers = {'X-api-client': 'de4927d9-a099-4ec8-bb99-4f69888acb34', 'X-api-key': 'somekey'}
        self.url = "http://10.0.0.175:4000/api/v1/documents"

    def get_documents(self):
        r = requests.get(self.url, headers=self.headers)
        return r.json()

    def upload(self, filename):
        files = {'file': open(filename, 'rb')}
        r=requests.post(self.url, headers=self.headers, files=files )
        return r.json()

    def download(self, id):
        r=requests.get(self.url + "/" + id , headers=self.headers )
        #r=requests.get(self.url + "/" + id + "?add_id=false", headers=self.headers )
        return r.json()

    # make a backup and write the file
    def sync(self, filename):
        upload_result = self.upload(filename)
        id = upload_result["id"]
        print "Result of upload of " + filename
        print upload_result

        # check if any conflicts and resolve
        if len(upload_result["conflicts"]) > 0:
            print "Conflicts on upload - stopping:"
            print len(upload_result["conflicts"])
            return 1

        download_result = self.download(id)
        copyfile(filename, filename + "." + str(self.unixtime()))
        with open(filename, "w") as f:
            f.write(download_result["text"])

# #text = json.dumps(output["text"])
# text = output["text"]
# f.write(text)


#    http DELETE http://10.0.0.175:4000/api/v1/documents/3e9d2eb9-8fde-49a7-9372-5fe40af57b6f X-api-client:de4927d9-a099-4ec8-bb99-4f69888acb34 X-api-key:somekey
# url = "http://10.0.0.175:4000/api/v1/documents"
# headers = {'X-api-client': 'de4927d9-a099-4ec8-bb99-4f69888acb34', 'X-api-key': 'somekey'}
# files = {'file': open('README.org', 'rb')}
# r = requests.post(url, headers=headers, files=files )
# id = r.json()["data"]["id"]
#r = requests.get(url, headers=headers)
# r.json()["data"][0]["id"]

sync = Sync()
filename = "tmp.org"
sync.sync(filename)
# result = sync.upload(filename)
# id = result["id"]
# #id = "47de3858-965e-485e-8df6-dae81e7e4d14"
# output = sync.download(id)
# f = open(filename + ".synced", "w")
# #text = json.dumps(output["text"])
# text = output["text"]
# f.write(text)
#print text
#print result
