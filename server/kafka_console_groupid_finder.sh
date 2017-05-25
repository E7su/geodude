#!/bin/bash
./bin/zookeeper-shell.sh localhost:2181 ls /consumers | tr ',' ' \n' | tr '[' '\n' | tr ']' ' ' > tmp

sleep 10

./bin/zookeeper-shell.sh localhost:2181 ls /consumers | tr ',' ' \n' | tr '[' '\n' | tr ']' ' ' > tmp2

diff tmp tmp2 | tail -n 1 | tr '>' ' '
