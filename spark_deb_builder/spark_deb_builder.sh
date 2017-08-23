#!/bin/bash

# ===============================================================
#    Скрипт для сборки deb-пакета spark из исходников с github
# ===============================================================

# КОНСТАНТЫ ====================================================
VERSION="v2.0.2"
MINOR_VERSION=`echo $VERSION | cut -c 4-`
HOME_PACKAGE=`pwd`
DEBIAN_PATH="spark2/pack_source/debian/"
USR_PATH="spark2/pack_source/usr/lib/"


# ОПИСАНИЕ ФУНКЦИЙ =============================================

# --/ Клонирование исходников и выбор версии /------------------
clone_and_checkout () {
  # клонируем репозиторий
  git clone https://github.com/apache/spark.git spark_original
  # заходим в папку с репозиторием
  cd spark_original
  # смотрим релизные теги
  git tag
  # выбираем релиз
  git checkout $VERSION
}


# --/ Сборка под Hadoop 2.6 /-----------------------------------
build_for_hadoop () {
  ./build/mvn -Pyarn -Phive -Phive-thriftserver -DskipTests clean package
}


# --/ Создание файлов, управляющих генерацией пакета /----------
prepare_template_for_deb_package () {
  # возвращаемся из репозитория
  cd ..
  # создаём папки для сборки deb-пакета
  mkdir -p $DEBIAN_PATH
  # переходим в папку debian
  cd $DEBIAN_PATH

  # создаём необходимые файлы
  create_compat
  create_changelog
  create_control
  create_copyright
  create_files
  create_postinst
  create_postrm
  create_rules

  # добавляем биты на исполнение
  chmod +x postinst
  chmod +x postrm
  chmod +x rules

  # создаём папочку source и файл format
  create_source_format
}


# --/ Создание файла compat /-----------------------------------
create_compat () {
  echo "7" > compat
}


# --/ Создание файла changelog /--------------------------------
create_changelog () {
  # получаем день недели (например, Wed)
  DAY=`date +%a`

  # получаем дату без дня недели и часового пояса
  # (например, 3 Aug 2017 11:15:56)
  DATE=`date +%c | cut -c 6-24`

  # конкатинируем день недели и дату через запятую
  # получаем строку вида Wed, 3 Aug 2017 11:15:56
  DATE_FOR_CHANGELOG=`echo $DAY, $DATE`

  echo "spark2 ($MINOR_VERSION-1) unstable; urgency=low

  * Initial package

 -- Etsu <etsu4296@gmail.com>  $DATE_FOR_CHANGELOG +0400
" > changelog
}


# --/ Создание файла control /----------------------------------
create_control () {
  echo 'Source: spark2
Section: non-free/admin
Priority: extra
Maintainer: Etsu <etsu4296@gmail.com>
Build-Depends: debhelper (>= 7.0.50~)
Standards-Version: 3.9.1
Homepage: https://github.com/E7su
Vcs-Git:
Vcs-Browser:

Package: spark2
Architecture: all
Depends: ${misc:Depends},
    python3
Description: Spark2 in deb package with added python modules
' > control
}


# --/ Создание файла copyright /--------------------------------
create_copyright () {
  echo "Format: http://dep.debian.net/deps/dep5
Upstream-Name: spark2
Source: git@github:E7su

Files: *
Copyright: 2017 SixSquadron. All rights reserved
License: other
 This is a commercial software.
" > copyright
}


# --/ Создание файла files /------------------------------------
create_files () {
  echo "spark2_$MINOR_VERSION-1_all.deb non-free/admin extra" > files
}


# --/ Создание файла postinst /---------------------------------
create_postinst () {
  echo "#!/bin/bash

sudo rm -rf /usr/bin/pyspark2
sudo rm -rf /usr/bin/spark2-submit
sudo ln -s /usr/lib/spark2/bin/pyspark /usr/bin/pyspark2
sudo ln -s /usr/lib/spark2/bin/spark-submit /usr/bin/spark2-submit
" > postinst
}


# --/ Создание файла postrm /-----------------------------------
create_postrm () {
  echo "#!/bin/sh

sudo rm -rf /usr/bin/pyspark2
sudo rm -rf /usr/bin/spark2-submit
" > postrm
}


# --/ Создание файла rules /------------------------------------
create_rules () {
  echo '#!/usr/bin/make -f
# -*- makefile -*-
# Sample debian/rules that uses debhelper.
# This file was originally written by Joey Hess and Craig Small.
# As a special exception, when this file is copied by dh-make into a
# dh-make output file, you may use that output file without restriction.
# This special exception was added by Craig Small in version 0.37 of dh-make.

# Uncomment this to turn on verbose mode.
#export DH_VERBOSE=1

%:
        dh $@
' > rules
}


# --/ Создание папки source и файла format /--------------------
create_source_format () {
  mkdir source
  cd source
  echo "3.0 (quilt)" > format
}


# --/ Копирование и распаковка архивов библиотек /--------------
copy_spark_and_libs () {
  # создание папок для библиотек
  cd ../../../..
  mkdir -p $USR_PATH
  cd $USR_PATH
  mkdir -p python3/dist-packages
  mkdir spark2

  # копирование собранного maven'ом проекта в директорию для deb-пакета
  cp -r $HOME_PACKAGE/spark_original/* spark2/

  # поиск всех zip файлов с библиотеками и копирование в директорию для сборки
  cd python3/dist-packages
  find $HOME_PACKAGE/spark_original/python/lib/*.zip | xargs -I {} cp {} .
  # распаковка и удаление zip файлов
  find *.zip |  xargs -I {} bash -c " unzip {} && rm {}"
}


# --/ Запуск сборки деб-пакета /--------------------------------
build () {
  cd $HOME_PACKAGE/spark2/pack_source
  tar -cz ./* -f ../spark2_$MINOR_VERSION.orig.tar.gz
  debuild -us -uc
}



# MAIN =========================================================
clone_and_checkout
build_for_hadoop
prepare_template_for_deb_package
copy_spark_and_libs
build
