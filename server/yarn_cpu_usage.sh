#!/bin/bash
while true ; do ps axfu | grep java | grep yarn | awk '{ sum += $3 } END { print sum }' ; sleep 1 ; done
