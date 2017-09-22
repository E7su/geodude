#!/bin/bash

# ===============================================================
#          Скрипт для автоматической пересборки spark
# ===============================================================


set -e

# КОНСТАНТЫ ====================================================

SPARK_HOME=/usr/lib/spark2


# ОПИСАНИЕ ФУНКЦИЙ =============================================

# --/ Проверяет git репозиторий на актуальную версию 
#                                             и пуллит её /-----
update_git_repo () {
  cd $SPARK_HOME/spark-synchronizer/

  if [[ `git pull` != "Already up-to-date." ]]; then
    echo "rebuild" # > last_status
    whoami > debug
    echo `whoami` >> debug
    rebuild_new_spark &>> build_log
    copy_other_configs &>> build_log
  else
    echo "pass" > last_status
  fi
}


# --/ Пересобирает спарк с актуальной версией конфигов /--------
rebuild_new_spark () {
  cd $SPARK_HOME/spark-deb-builder/
  # TODO: remove hardcode
  ./spark_deb_builder.sh -v v2.2.0 -b default -c local
  cd $SPARK_HOME/spark-synchronizer
  update_date=`date`
  echo $update_date > last_rebuild_date
}


# --/ Раскладывает конфиги hadoop и hive по папочкам /---------
copy_other_configs () {
  cd $SPARK_HOME/spark-synchronizer
  
  echo ">>> Копирование hive-site.xml"
  if [ -n $HIVE_CONF_DIR ]; then
    echo "cp conf/hive-site.xml $HIVE_CONF_DIR/"
    cp conf/hive-site.xml $HIVE_CONF_DIR/
  fi
  echo "<<< Копирование hive-site.xml завершено"
  
  echo ">>> Копирование yarn-site.xml и core-site.xml"
  if [ -n $HADOOP_CONF_DIR ]; then
    echo "cp conf/yarn-site.xml $HADOOP_CONF_DIR/"
    cp conf/yarn-site.xml $HADOOP_CONF_DIR/
    echo "cp conf/core-site.xml $HADOOP_CONF_DIR/"
    cp conf/core-site.xml $HADOOP_CONF_DIR/
  fi
  echo "<<< Копирование yarn-site.xml и core-site.xml завершено"
}

update_git_repo

