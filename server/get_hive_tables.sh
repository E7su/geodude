#!/bin/bash
hadoop fs -ls /data/database_name.db | awk {'print $8'} | sed 's|.*/||'
