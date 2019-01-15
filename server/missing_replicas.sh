#!/bin/bash
hdfs fsck / | egrep -v '^\.+$' | awk -F ':' {'print $1'}
