#!/bin/bash

# ===============================================================
#  Скрипт для настройки локальных машин на автообновление spark
# ===============================================================


set -e

# ОПИСАНИЕ ФУНКЦИЙ =============================================

# --/ Диалог о переменных окружения /---------------------------
dialog_env_variables () {
  dialog_hive_conf_dir
  dialog_hadoop_conf_dir
}


# --/ Диалог о пути с конфигами hive /-------------------------
dialog_hive_conf_dir () {
  DIALOG=${DIALOG=dialog}
  tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/test$$
  trap "rm -f $tempfile" 0 1 2 5 15

  $DIALOG --title "HIVE_CONF_DIR" --clear \
          --inputbox "Введите путь до папки с конфигами Hive \
                      \n\nПример:  /usr/lib/hive/conf" 16 51 2> $tempfile

  RETVAL=$?

  case $RETVAL in
    0)
      HIVE_CONF_DIR=`cat $tempfile`
      echo "Вы ввели $HIVE_CONF_DIR"
      if ! [ -d $HIVE_CONF_DIR ]; then
        echo 'No directory $HIVE_CONF_DIR '
        exit 255
      fi
      ;;
    1)
      echo "Отказ от ввода.";;
    255)
      if test -s $tempfile ; then
        echo "Путь не введён"
        exit 255
      else
        echo "Нажата клавиша ESC."
        exit 1
      fi
      ;;
  esac
}


# --/ Диалог о пути с конфигами hadoop /------------------------
dialog_hadoop_conf_dir () {
  DIALOG=${DIALOG=dialog}
  tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/test$$
  trap "rm -f $tempfile" 0 1 2 5 15

  $DIALOG --title "HADOOP_CONF_DIR" --clear \
          --inputbox "Введите путь до папки с конфигами Hadoop \
                      \n\nПример:  /etc/hadoop/conf" 16 51 2> $tempfile

  RETVAL=$?

  case $RETVAL in
    0)
      HADOOP_CONF_DIR=`cat $tempfile`
      echo "Вы ввели $HADOOP_CONF_DIR"
      if ! [ -d $HADOOP_CONF_DIR ]; then
        echo 'No directory $HADOOP_CONF_DIR '
        exit 255
      fi
      ;;
    1)
      echo "Отказ от ввода.";;
    255)
      if test -s $tempfile ; then
        echo "Путь не введён"
        exit 255
      else
        echo "Нажата клавиша ESC."
        exit 1
      fi
      ;;
  esac
}


# --/ Создание необходимых переменных окружения /---------------
create_env_variables () {
  echo "export HIVE_CONF_DIR=$HIVE_CONF_DIR
export SPARK_HOME=/usr/lib/spark2 
export YARN_CONF_DIR=$HADOOP_CONF_DIR
export HADOOP_CONF_DIR=$HADOOP_CONF_DIR
" > ~/.profile
}


# --/ Добавит автообновление конфигов в cron /------------------
add_pull_to_cron () {
  echo "* * * * *  /usr/lib/spark2/spark-synchronizer/rebuilder.sh" > cronfile
  crontab cronfile
  crontab -l
}


# MAIN =========================================================
dialog_env_variables
create_env_variables

add_pull_to_cron
