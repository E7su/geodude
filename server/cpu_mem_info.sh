#!/bin/bash
cat /proc/cpuinfo  | grep "model name" | uniq -c
echo 
echo Memory ` free -m | grep Mem | awk '{print $2'}` Mb
