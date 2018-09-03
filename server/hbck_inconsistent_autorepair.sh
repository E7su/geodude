#!/bin/bash
LOG=/tmp/repair.log
CHECK=`su hbase -c '_JAVA_OPTIONS="-Xms128m -Xmx128m" hbase hbck' -s /bin/bash | grep -i INCONSISTENT`
echo ">>> $CHECK" &>> $LOG

if [[ -n $CHECK ]];
  then
  echo "fix-fix-fix"
  su hbase -c '_JAVA_OPTIONS="-Xms128m -Xmx128m" hbase hbck -repair' -s /bin/bash &>> $LOG
fi
