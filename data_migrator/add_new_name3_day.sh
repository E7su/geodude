#!/bin/bash

DT=$1

hadoop fs -rmr -skipTrash /data/database_name.db/name3/dt=$DT

hadoop distcp -skipcrccheck -update \
hdfs://master_name/data/database_name.db/name3/dt=$DT \
/data/database_name.db/name3/dt=$DT

/usr/bin/add_partition_for_name3.py $DT
