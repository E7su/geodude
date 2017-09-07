#!/bin/bash

FIRST_PATH=$1
SECOND_PATH=$2

if [[ -z $FIRST_PATH || -z $SECOND_PATH ]]; then
  echo "Введите пути до сравниваемых директорий через пробел"
  exit 1
fi

ls -la $FIRST_PATH | \
awk {'print $9'} | \
xargs -P 15 -I {} bash -c "diff $FIRST_PATH/{}  $SECOND_PATH/{}"
