#!/bin/bash

file="/tmp/tables_for_grant_select.txt"
tables=`echo $(cat $file | sed "s/\$/, /g")# | sed s/,\ #//g`

echo "> CREATE USER $1;"
sudo vsql -U admin -c "CREATE USER $1;"

echo "> GRANT SELECT ON ${tables} TO $1;"
sudo vsql -U admin -c "GRANT SELECT ON ${tables} TO $1;"

echo "> ALTER USER $1 IDENTIFIED BY '$1"1"';"
sudo vsql -U admin -c "ALTER USER $1 IDENTIFIED BY '$1"1"';"
