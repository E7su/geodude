#!/bin/bash

again=yes
tmp_path=/tmp/zeppelin_script/latest_commit_tmsp
current_latest_commit_tmsp=`git log -n1 --format="%at"`

while [ "$again" == "yes" ]
do
  git push

  # if push was success or nothing to push:
  if [ $? -eq 0 ]; then

    # write latest commit timestamp on disc
    git log -n1 --format="%at" > $tmp_path

    # if last commit time on disk < current last commite time, then push
    # else - break
    if [ `cat $tmp_path` -eq `git log -n1 --format="%at"` ]; then
      let "again=false"
    fi

  fi
done
