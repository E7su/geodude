#!/bin/bash
# down
for x in {1..500}; do ls /mnt/maillogs/hadoop$x/yarn-yarn-nodemanager-hadoop$x.i.log | grep access ; done; 

# error
for x in {1..500}; do echo "hadoop$x: " && fgrep --colour -i error /mnt/maillogs/hadoop$x/yarn-yarn-nodemanager-hadoop$x.i.log | wc -l ; done; 
