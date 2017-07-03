#!/usr/bin/python
import subprocess
import sys

dt = sys.argv[1]

res = subprocess.check_output("hadoop fs -ls /data/database_name.db/name3/dt=%s/" % (dt), shell=True)
res = res.split('\n')[1:-1]
for line in res:
    dt = line.split()[7].split('/')[4].split('=')[1]
    subsite = line.split()[7].split('/')[5].split('=')[1]
    subprocess.call(
        """hive -e " ALTER TABLE database_name.name3 ADD PARTITION (dt='%s', subsite = %s ) location '/data/database_name.db/name3/dt=%s/subsite=%s';"  -hiveconf hive.cli.errors.ignore=true""" % (
        dt, subsite, dt, subsite), shell=True)
