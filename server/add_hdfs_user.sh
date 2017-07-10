#!/bin/bash

login=$1
comment=$2
useradd $login -c "$comment" -m  -b /team -g hdfs -N
echo "useradd $login -c \"$comment\" -m -b /team -g hdfs -N"
