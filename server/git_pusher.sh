#!/bin/bash

ntb_path=/usr/lib/zeppelin/notebook
tmp_path=/usr/lib/zeppelin/git_pusher/latest_commit_tmsp

# go to local git repository with notebooks
cd $ntb_path

# if last commit time on disk < current last commit time, then push:
if [ `cat $tmp_path` -lt `git log -n1 --format="%at"` ]; then
  pwd > /usr/lib/zeppelin/git_pusher/tmp
  git push

  # if push was success or nothing to push:
  if [ $? -eq 0 ]; then
    # write latest commit timestamp on disc
    git log -n1 --format="%at" > $tmp_path
  fi

fi
