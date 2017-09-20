#!/bin/bash

# ===============================================================
#  Скрипт для автоматической пересборки spark
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
    git pull
    echo "rebuild" > last_status #| tee > last_status
    rebuild_new_spark #| tee &>> build_log
    copy_other_configs #| tee &>> build_log
  else
    echo "pass" > last_status #| tee > last_status
  fi
}


# --/ Пересобирает спарк с актуальной версией конфигов /--------
rebuild_new_spark () {
  cd $SPARK_HOME/spark-deb-builder/
  # TODO: remove hardcode
  sudo ./spark_deb_builder.sh -v v2.2.0 -b default -c local
  cd $SPARK_HOME/spark-synchronizer
  update_date=`date`
  echo $update_date > last_rebuild_date
}


# --/ Раскладывает конфиги hadoop и hive по папочкам /---------
copy_other_configs () {
  cd $SPARK_HOME/spark-synchronizer

  echo ">>> Копирование hive-site.xml в $HIVE_CONF_DIR"
  if [ -n $HIVE_CONF_DIR ]; then
    echo "cp conf/hive-site.xml $HIVE_CONF_DIR/"
    cp conf/hive-site.xml $HIVE_CONF_DIR/
  fi
  echo "<<< Копирование hive-site.xml в $HIVE_CONF_DIR"

  echo ">>> Копирование yarn-site.xml и core-site.xml в $HADOOP_CONF_DIR"
  if [ -n $HADOOP_CONF_DIR ]; then
    echo "cp conf/yarn-site.xml $HADOOP_CONF_DIR/"
    cp conf/yarn-site.xml $HADOOP_CONF_DIR/
    echo "cp conf/core-site.xml $HADOOP_CONF_DIR/"
    cp conf/core-site.xml $HADOOP_CONF_DIR/
  fi
  echo "<<< Копирование yarn-site.xml и core-site.xml в $HADOOP_CONF_DIR завершено"
}

update_git_repo
