#!/bin/bash


echo CPU:
cat /proc/cpuinfo  | grep "model name" | uniq -c
echo 

echo Memory ` free -m | grep Mem | awk '{print $2'}` Mb


echo 

 /usr/sbin/alternatives --display java

echo 
echo rpm -qa | grep -i java
rpm -qa | grep -i java
