#!/bin/bash

# ===============================================================
#       Скрипт для обновления hadoop'овых конфигов в git
# ===============================================================


set -e

# --/ Обновление конфигов в локальном репозитории /-------------
update_configs () {
  echo ">>> Обновление конфигов в локальном репозитории \
  в соответствии с настройками кластера"

  cd /usr/bin/spark-synchronizer/conf

  cp /etc/hadoop/conf/core-site.xml .
  cp /etc/hadoop/conf/yarn-site.xml .
  cp /usr/lib/spark2/conf/spark-defaults.conf .
  cp /usr/lib/spark2/conf/metrics.properties .
  cp /etc/hive/conf/hive-site.xml .

  echo "<<< Обновление конфигов в локальном репозитории \
  в соответствии с настройками кластера завершено"
}


# --/ Диалог о добавлении в git новой версии конфига /----------
dialog_for_git_add () {
  cd /usr/bin/spark-synchronizer

  DIALOG=${DIALOG=dialog}
  tempfile=`mktemp 2>/dev/null` || tempfile=/tmp/test$$
  trap "rm -f $tempfile" 0 1 2 5 15

  $DIALOG \
    --backtitle "Файл для коммита" \
    --title "git add ..." \
    --clear \
    --checklist "Выберите список файлов, которые необходимо закоммитить:" 20 61 5 \
    "core-site.xml"       "/etc/hadoop/conf/core-site.xml" off \
    "yarn-site.xml"       "/etc/hadoop/conf/yarn-site.xml" off \
    "spark-defaults.conf" "/usr/lib/spark2/conf/spark-defaults.conf" ON \
    "metrics.properties"  "/usr/lib/spark2/conf/metrics.properties" off \
    "hive-site.xml"       "/etc/hive/conf/hive-site.xml" off 2> $tempfile

  retval=$?

  choice=`cat $tempfile`
  case $retval in
    0)
      add_to_remote_repo;;
    1)
      echo "Отказ от ввода.";;
    255)
      echo "Нажата клавиша ESC.";;
  esac
}


# --/ Добавление новых конфигов в удалённый репозиторий /-------
add_to_remote_repo () {
  
  cd /usr/bin/spark-synchronizer/conf

  echo ">>> git add $choice"
  git add $choice
  echo ">>> git commit -m 'Update $choice'"
  git commit -m "Update $choice"
  echo ">>> git push"
  git push
}



# MAIN =========================================================
update_configs
dialog_for_git_add

