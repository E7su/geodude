#!/bin/bash
cat hadoop-hdfs-namenode-mrashadnn1.i.log-2018.02.07-15 | grep --colour -i "Inconsistent number of corrupt replicas" | awk -F "for " {'print $2'} | awk -F " " {'print $1'} | sort | uniq
