#!/bin/bash
PASSWORD1=`cat /dev/urandom | tr -d -c 'a-zA-Z0-9' | fold -w 10 | head -1`
echo Password=$PASSWORD1
