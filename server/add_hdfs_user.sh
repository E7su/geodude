#!/bin/bash

login=$1
comment=$2

# add user
useradd $login -c "$comment" -m  -b /team -g hdfs -N
echo "useradd $login -c \"$comment\" -m -b /team -g hdfs -N"

# create user's home
hadoop fs –mkdir /user/$login
echo "hadoop fs –mkdir /user/$login"

# chown && chmod
sudo su hdfs

hadoop fs –chown –R $login:hdfs /team/$login && \
hadoop fs -chmod -R g+w /team/$login/

echo "hadoop fs –chown –R $login:hdfs /team/$login && \
hadoop fs -chmod -R g+w /team/$login/"
