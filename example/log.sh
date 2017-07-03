#!/bin/bash

NAME=`basename $0`
TIME=`date +%F\ %H:%M:%S`
TYPE='<info>'

echo "$TIME $NAME: $TYPE Operation completed successfully" >> /tmp/log
