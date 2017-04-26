#!/bin/bash
case "$1" in

 "start" )
 airflow webserver -p 8080 > ~/airflow/logs/server/server.log 2>&1 &
 ;;

 "stop" )
 kill `ps aux | grep airflow | grep master | awk '{print $2}'`
 ;;

esac
