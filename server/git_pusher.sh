#!/bin/bash

tmp_path=/tmp/zeppelin_script/latest_commit_tmsp

# if last commit time on disk < current last commit time, then push:
if [ `cat $tmp_path` -lt `git log -n1 --format="%at"` ]; then
  git push

  # if push was success or nothing to push:
  if [ $? -eq 0 ]; then
    # write latest commit timestamp on disc
    git log -n1 --format="%at" > $tmp_path
  fi

fi
