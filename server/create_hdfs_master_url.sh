#!/bin/bash

master_url=$(./get_hdfs_master_url.py)
master_url="hdfs://"$master_url":8020/data/database_name.db/table_name/"

echo $master_url
