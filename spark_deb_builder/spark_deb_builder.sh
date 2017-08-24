#!/bin/bash

# ==============================================================
#   Скрипт для сборки deb-пакета spark из исходников с github
# ==============================================================

set -e

# КОНСТАНТЫ ====================================================
PACKAGE_PWD=`pwd`
DEBIAN_PATH=$PACKAGE_PWD"/spark2/pack_source/debian"
USR_PATH=$PACKAGE_PWD"/spark2/pack_source/usr/lib"
VERSION=$1
CHOICE=$2

# ОПИСАНИЕ ФУНКЦИЙ =============================================

# --/ Вызов диалога, если аргументы не введены /----------------
get_params () {
  get_version
  get_blas
}

# --/ Проверка на непустую версию /-----------------------------
get_version () {
  if [[ -z $VERSION ]]; then
    dialog_version
  fi
}


# --/ Обработка введённого пакета BLAS /------------------------
get_blas () {
  if [[ -z $CHOICE ]]; then
    dialog_blas
  elif [[ $CHOICE == MLLib || $CHOICE == mllib ]]
  then
    CHOICE="MLLib"
  else
    echo "Неверен второй аргумент. Аргумент должен отсутствовать или быть равным MLLib"
    exit 1
  fi
}


# --/ Диалог о собираемой версии Spark /-------------------------
dialog_version () {
  DIALOG=${DIALOG=dialog}
  tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/test$$
  trap "rm -f $tempfile" 0 1 2 5 15

  $DIALOG --title "Ввод версии Spark" --clear \
          --inputbox "Введите версию Spark для сборки deb-пакета, начиная с буквы \
                                            \n\nПример:  v2.0.2" 16 51 2> $tempfile

  RETVAL=$?

  case $RETVAL in
    0)
      echo "Вы ввели `cat $tempfile`"
      ;;
    1)
      echo "Отказ от ввода.";;
    255)
      if test -s $tempfile ; then
        echo "Версия не введена"
        exit 255
      else
        echo "Нажата клавиша ESC."
        exit 1
      fi
      ;;
  esac

  # введённая пользователем версия, например, v2.0.2
  VERSION=`cat $tempfile`
}


# --/ Диалог о BLAS/--------------------------------------------
dialog_blas () {
  DIALOG=${DIALOG=dialog}
  tempfile=`mktemp 2>/dev/null` || tempfile=/tmp/test$$
  trap "rm -f $tempfile" 0 1 2 5 15

  $DIALOG --clear --title "Выбор BLAS" \
          --menu "Оставить BLAS по умолчанию или добавить MLLib:" 20 51 4 \
          "BLAS"  "Use Default BLAS" \
          "MLLib" "Install MLLib" 2> $tempfile

  RETVAL=$?

  CHOICE=`cat $tempfile`

  case $RETVAL in
    0)
      echo "Да вы эстет! $CHOICE -- это лучшее, что вы собирали в своей жизни!";;
    1)
      echo "Отказ от ввода.";;
    255)
      echo "Нажата клавиша ESC.";;
  esac
}


# --/ Удаление существующих папок spark2 и spark_original /-----
remove_previos_spark_dirs () {
  echo ">>> Удаление папок предыдущей сборки spark"
	
  if [ -d $PACKAGE_PWD/spark2 ]; then
    rm -rf $PACKAGE_PWD/spark2
    echo ">>> Удалена папка spark2"
  else
    echo '<<< Предыдущие сборки spark не обнаружены '
  fi

  if [ -d $PACKAGE_PWD/spark_original ]; then
    rm -rf $PACKAGE_PWD/spark_original
    echo ">>> Удалена папка spark_original"
  else
    echo ">>> Предыдущая папка с исходниками spark не обнаружена"
  fi

  echo "<<< Удаление папок предыдущей сборки spark завершено"
}


# --/ Клонирование исходников и выбор версии /------------------
clone_and_checkout () {
  echo ">>> Клонирование исходников"
  git clone https://github.com/apache/spark.git spark_original
  echo "<<< Клонирование исходников завершено"

  # заходим в папку с репозиторием
  cd $PACKAGE_PWD/spark_original
  echo ">>> Список найденных тегов"
  # смотрим релизные теги
  git tag

  if [[ -z $VERSION ]] ; then
    VERSION=`git tag | tail -n 1`
    echo "<<< Версия не введена, будет собрана последняя стабильная $VERSION"
  fi

  echo ">>> Выбрана версия $VERSION для создания пакета"
  git checkout $VERSION

  # минорная версия (последние две цифры), из примера - 0.2
  MINOR_VERSION=`echo $VERSION | cut -c 4-`

  echo "<<< Открыты исходные коды версии $VERSION"
}


# --/ Сборка под Hadoop 2.6 /-----------------------------------
build_for_hadoop () {
  echo ">>> Сборка tar Spark $VERSION для Hadoop 2.6"

  if [ $CHOICE == MLLib ] ; then
    FLAG="-Pnetlib-lgpl"
    echo "Добавлен флаг $FLAG"
  fi

  cd $PACKAGE_PWD/spark_original
  echo "./build/mvn -Pyarn -Phive -Phive-thriftserver -DskipTests $FLAG clean package"
  ./build/mvn -Pyarn -Phive -Phive-thriftserver -DskipTests $FLAG clean package

  echo "<<< Сборка tar Spark $VERSION для Hadoop 2.6 завершена"
}


# --/ Создание файлов, управляющих генерацией пакета /----------
prepare_template_for_deb_package () {
  # возвращаемся из репозитория
  cd $PACKAGE_PWD
  # создаём папки для сборки deb-пакета
  mkdir -p $DEBIAN_PATH
  # переходим в папку debian
  cd $DEBIAN_PATH

  echo ">>> Создание файлов, управляющих генерацией пакета"
  create_compat
  create_changelog
  create_control
  create_copyright
  create_files
  create_postinst
  create_postrm
  create_rules

  echo ">>> Добавление битов на исполнение для скриптов сборки"
  chmod +x postinst
  chmod +x postrm
  chmod +x rules
  echo "<<< Добавление битов на исполнение для скриптов сборки завершено"

  # создаём папочку source и файл format
  create_source_format
  echo "<<< Создание файлов, управляющих генерацией пакета, завершено"
}


# --/ Создание файла compat /-----------------------------------
create_compat () {
  echo ">>> Создание файла compat"
  echo "7" > compat
  echo "<<< Создание файла compat завершено"
  cat compat
}


# --/ Создание файла changelog /--------------------------------
create_changelog () {
  echo ">>> Создание файла changelog"

  # получаем день недели (например, Wed)
  DAY=`date +%a`

  # получаем дату без дня недели и часового пояса
  # (например, 23 Aug 2017 11:15:56)
  DATE=`date +%c | cut -c 5-24`

  # конкатинируем день недели и дату через запятую
  # получаем строку вида Wed, 3 Aug 2017 11:15:56
  DATE_FOR_CHANGELOG=`echo $DAY, $DATE`

  echo "spark2 ($MINOR_VERSION-1) unstable; urgency=low

  * Initial package

 -- Etsu <etsu4296@gmail.com>  $DATE_FOR_CHANGELOG +0400
" > changelog

  echo "<<< Создание файла changelog завершено"
  cat changelog
}


# --/ Создание файла control /----------------------------------
create_control () {
  echo ">>> Создание файла control"

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

  echo "<<< Создание файла control завершено"
  cat control
}


# --/ Создание файла copyright /--------------------------------
create_copyright () {
  echo ">>> Создание файла copyright"

  echo "Format: http://dep.debian.net/deps/dep5
Upstream-Name: spark2
Source: https://github.com/E7su

Files: *
Copyright: 2017 SixSquadron. All rights reserved
License: other
 This is a commercial software.
" > copyright

  echo "<<< Создание файла copyright завершено"
  cat copyright
}


# --/ Создание файла files /------------------------------------
create_files () {
  echo ">>> Создание файла files"

  echo "spark2_$MINOR_VERSION-1_all.deb non-free/admin extra" > files

  echo "<<< Создание файла files завершено"
  cat files
}


# --/ Создание файла postinst /---------------------------------
create_postinst () {
  echo ">>> Создание файла postinst"
  
  echo "#!/bin/bash

sudo rm -rf /usr/bin/pyspark2
sudo rm -rf /usr/bin/spark2-submit
sudo ln -s /usr/lib/spark2/bin/pyspark /usr/bin/pyspark2
sudo ln -s /usr/lib/spark2/bin/spark-submit /usr/bin/spark2-submit
" > postinst

  echo "<<< Создание файла postinst завершено"
  cat postinst
}


# --/ Создание файла postrm /-----------------------------------
create_postrm () {
  echo ">>> Создание файла postrm"
 
  echo "#!/bin/sh

sudo rm -rf /usr/bin/pyspark2
sudo rm -rf /usr/bin/spark2-submit
" > postrm

  echo "<<< Создание файла postrm завершено"
  cat postrm
}


# --/ Создание файла rules /------------------------------------
create_rules () {
  echo ">>> Создание файла rules"

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


  echo "<<< Создание файла rules завершено"
  cat rules
}


# --/ Создание папки source и файла format /--------------------
create_source_format () {
  echo ">>> Создание папки source и файла format"
 
  mkdir $DEBIAN_PATH/source
  cd $DEBIAN_PATH/source

  echo "3.0 (quilt)" > format

  echo ">>> Создание папки source и файла format завершено"
  cat format
}


# --/ Копирование и распаковка архивов библиотек /--------------
copy_spark_and_libs () {
  echo ">>> Cоздание папок для библиотек"

  mkdir -p $USR_PATH
  cd $USR_PATH
  mkdir -p $USR_PATH/python3/dist-packages
  mkdir $USR_PATH/spark2

  echo "<<< Cоздание папок для библиотек"


  echo ">>> Копирование собранного maven'ом проекта в директорию для deb-пакета"
  cp -r $PACKAGE_PWD/spark_original/* spark2/
  echo "<<< Копирование собранного maven'ом проекта в директорию для deb-пакета"

  echo ">>> Поиск всех zip файлов с библиотеками и копирование в директорию для сборки"
  cd $USR_PATH/python3/dist-packages
  find $PACKAGE_PWD/spark_original/python/lib/*.zip | xargs -I {} cp {} .
  echo "<<< Копирование zip файлов в директорию для сборки завершено"

  echo ">>> Распаковка и удаление zip файлов"
  find *.zip |  xargs -I {} bash -c "unzip {} && rm {}"
  echo "<<< Zip файлы распакованы"
}


# --/ Запуск сборки deb-пакета /--------------------------------
build () {
  echo ">>> Запуск сборки deb-пакета"
  
  cd $PACKAGE_PWD/spark2/pack_source
  tar -cz ./* -f ../spark2_$MINOR_VERSION.orig.tar.gz
  debuild -us -uc
  
  echo "<<< Сборка deb-пакета завершена"
}



# MAIN =========================================================
get_params
remove_previos_spark_dirs
clone_and_checkout
build_for_hadoop
prepare_template_for_deb_package
copy_spark_and_libs
build
