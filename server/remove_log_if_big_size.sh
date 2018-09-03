#!/bin/bash
LOG=/tmp/old.log
SIZE=`du -s $LOG | awk {'print $1'}`
if [[ $SIZE -gt 5000 ]];
  then
  echo "Delete log file $LOG with size $SIZE"
  rm -f $LOG
else
  echo "Size for log $LOG is $SIZE"
fi
