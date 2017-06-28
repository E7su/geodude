#!/usr/bin/python2.7

import json
import urllib2

hdfs_master_urls_list = ['node_1', 'node_2']
hdfs_master_url = ''

for url in hdfs_master_urls_list:
    try:
        response = urllib2.urlopen('http://%s:50070/jmx?qry=Hadoop:service=NameNode,name=NameNodeStatus' % (url))
        text_res = response.read()
        if json.loads(text_res)['beans'][0]['State'] == 'active':
            hdfs_master_url = json.loads(text_res)['beans'][0]['HostAndPort'].split(":")[0]
    except:
        pass

if hdfs_master_url == '':
    exit(1)
else:
    print(hdfs_master_url)
