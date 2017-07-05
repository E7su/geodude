#!/bin/bash

if [ x = x${2} ]; then
   BRANCH_NAME=$(git symbolic-ref --short HEAD)
   STORY_NUMBER=$(echo $BRANCH_NAME | sed -n 's/.*-\([0-9]\)/\1/p')
   if [ x != x${STORY_NUMBER} ]; then
      sed -i.back "1s/^/\n\n[#$STORY_NUMBER]/" "$1"
   fi
fi
