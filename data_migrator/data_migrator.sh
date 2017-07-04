#!/bin/bash

# ===============================================================
#       Скрипт для переливки данных с прода на предпрод
# ===============================================================

# >>> ОПИСАНИЕ ФУНКЦИЙ 

# --/ While-menu dialog /----------------------------------------
# Выбор таблицы предпрода для обновления её содержимого
set -e

dialog_with_user () {
DIALOG_CANCEL=1
DIALOG_ESC=255
HEIGHT=0
WIDTH=0

display_result() {
  dialog --title "$1" \
    --no-collapse \
    --msgbox "$result" 0 0
}

while true; do
  exec 3>&1
  selection=$(dialog \
    --backtitle "Обновление данных предпрода" \
    --title "Menu" \
    --clear \
    --cancel-label "Exit" \
    --menu "Пожалуйста, выберите переливаемую таблицу: " $HEIGHT $WIDTH 4 \
    "1" "name1" \
    "2" "name2" \
    "3" "name3" \
    2>&1 1>&3)
  exit_status=$?
  exec 3>&-
  case $exit_status in
    $DIALOG_CANCEL)
      clear
      echo "Program terminated."
      exit
      ;;
    $DIALOG_ESC)
      clear
      echo "Program aborted." >&2
      exit 1
      ;;
  esac
  case $selection in
    0 )
      clear
      echo "Program terminated."
      ;;
    1 )
      result=name1
      display_result "NAME1"
      break
      ;;
    2 )
      result=name2
      display_result "NAME2"
      break
      ;;
    3 )
      result=name3
      display_result "NAME3"
      break
      ;;
  esac
done
}


# --/ Подготовка скрипта к работе /------------------------------
script_preparation () {
  echo ">>> Поиск мастер-ноды"
  master_url=$(./get_hdfs_master_url.py)
  echo "<<< Мастер-нода найдена: "$master_url

  echo ">>> Генерация адреса переливаемой таблицы:"
  table_url="hdfs://"$master_url":8020/data/database_name.db/"$table_name
  echo "<<< Таблица найдена. Адрес: "$table_url

  master_url="hdfs://"$master_url
}


# --/ Копирование данных на кластер предпрода /------------------
copy_data_to_predprod () {
  echo ">>> Копирование на кластер предпрода найденных партиций"
  # Флаг -skipcrccheck используется для перезаписи существующих файлов

  hadoop fs -ls $table_url | \
  awk  {'print $8'} | \
  grep 2017 | \
  awk -F '8020' {'print $2'} | \
  xargs -I {} -P 5 bash -c "echo '$(date +%F) $NAME: $TYPE\
-> Копирование партиции {} на кластер предпрода' \
&& sudo -u hdfs hadoop distcp -skipcrccheck \
-update $master_url{} hdfs://{}"

  echo "<<< Копированиe завершено" 
  }



# --/ Обновление таблицы в hive /----------------------------------
refresh_hive () {
  echo ">>> Добавление партиций в hive"

  hadoop fs -ls $table_url | \
  awk -F "dt=" {'print $2 '} | \
  grep 2017 | \
  xargs -I {} -P 5 bash -c "echo '$(date +%F) $NAME: $TYPE \
-> Добавление партиции {} в hive' \
&& hive -e \"ALTER TABLE database_name.$table_name \
ADD PARTITION (dt='{}')\
location '/data/database_name.db/$table_name/dt={}';\" \
-hiveconf hive.cli.errors.ignore=true"

echo "<<< Добавление партиций в hive завершено"
}

# --/ Удаление дубликатов в name2 /--------------------------------
#     Связано с исходными данными, а не с кривостью переливки
remove_duplicates () {
  echo ">>> Удаление дубликатов в таблице name2"


  for x in $(hadoop fs -ls /data/database_name.db/name2/ | \
      grep 2017 | \
      awk {'print $8'} | \
      grep 2017) ; \
    do hadoop fs -ls $x | \
      awk {'print $6$7 " " $8'} | \
      sort -r | \
      sed '1d' | \  # удаление строки
      awk {'print $2'} | \
      grep content | \
      xargs -I {} -P 10 bash -c "echo '$(date +%F) $NAME: $TYPE \
      -> Удаление дубликата {} в таблице name2' && \
      hadoop fs -rm -skipTrash {}";
    done

  echo "<<< Дубликаты удалены"
  }


# MAIN ==========================================================

NAME=`basename $0`
TYPE='<info>'
LOG_DIR=/tmp/data_migrator.log

echo "!!! Логи можно посмотреть в папке $LOG_DIR командой tail -f $LOG_DIR/название_таблицы"
echo "Вы запустили скрипт в screen? (y/n)"
read item

case "$item" in
    y|Y) echo "Ввели «y», продолжение работы программы"
        ;;
    n|N) echo "Введён «n», завершение работы программы"
        exit 1
        ;;
    *) echo "Ничего не введено. Выполняем действие по умолчанию - завершение программы"
        exit 1
        ;;
esac

# Диалог с пользователем для получения названия переливаемой таблицы
dialog_with_user
clear

table_name=$result
LOG_PATH=/tmp/data_migrator/"$table_name".log

# Удаление предыдущих логов по переливке данной таблицы,
# если они существуют
if test -f $LOG_PATH;
then
  rm $LOG_PATH
fi

echo $(date +%F) $NAME: $TYPE " \
-> Название таблицы: "$table_name &>> $LOG_PATH

# --/ Обработка введённых пользователем данных /-------------------
if [ $table_name == name1 ] || [ $table_name == name2 ] ;
  then

  script_preparation &>> $LOG_PATH
  copy_data_to_predprod &>> $LOG_PATH
  refresh_hive &>> $LOG_PATH

  if [ $table_name == name2 ] ; then
    remove_duplicates &>> $LOG_PATH
  fi

else

  if [ $table_name == name3 ] ; then
    cat ./dt | \
    xargs -I {} bash -c "echo '$(date +%F) $NAME: $TYPE \
-> Добавление партиции {} в таблицу name3 ' \
&& ./add_partition_for_name3.py {}" &>> $LOG_PATH
  fi

fi
