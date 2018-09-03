#!/bin/bash
CHECK=`su hbase -c '_JAVA_OPTIONS="-Xms128m -Xmx128m" hbase hbck' -s /bin/bash | grep -i INCONSISTENT`
echo ">>> $CHECK" 2&>> /tmp/repair.log

if [[ -n $CHECK ]];
  then
  echo "fix-fix-fix"
  su hbase -c '_JAVA_OPTIONS="-Xms128m -Xmx128m" hbase hbck -repair' -s /bin/bash 2&>> /tmp/repair.log
fi
