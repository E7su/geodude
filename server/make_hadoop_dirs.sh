#!/bin/bash

for i in `seq 1 12`; do
        mkdir -m755 -p /mnt/disk${i}/mapred
        chown -R mapred:hadoop /mnt/disk${i}/mapred
        mkdir -m700 -p /mnt/disk${i}/hdfs_data
        chown -R hdfs:hadoop /mnt/disk${i}/hdfs_data
        mkdir -p /mnt/disk${i}/yarn/{logs,local}
        chown -R yarn:yarn /mnt/disk${i}/yarn/{logs,local}
done
