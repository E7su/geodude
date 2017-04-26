#!/bin/bash

while [[ True ]]
do
  read a b c
  if [[ $a == "exit" ]]
  then
    echo "bye"
    break
  elif [[ "$a" =~ "^[0-9]+$" && "$c" =~ "^[0-9]+$" ]]
  then
    echo "error"
    break
  else
    case $amal in
"+") let "result = a + c";;
"-") let "result = a - c";;
"/") let "result = a / c";;
"*") let "result = a * c";;
"%") let "result = a % c";;
"**") let "result = a ** c";;
*) echo "error" ; break ;;
    esac
    echo "$result"
  fi
done
