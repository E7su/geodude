#!/bin/bash

# ==============================================================
#   Скрипт для сборки deb-пакета spark из исходников с github
# ==============================================================

set -e

# КОНСТАНТЫ ====================================================
PACKAGE_PWD=`pwd`
DEBIAN_PATH=$PACKAGE_PWD"/spark2/pack_source/debian"
USR_PATH=$PACKAGE_PWD"/spark2/pack_source/usr/lib"
SCRIPT_NAME=`basename $0`

# ОПИСАНИЕ ФУНКЦИЙ =============================================

print_help() {
  echo "Сборка deb-пакета spark из исходников с github"
  echo
  echo "Использование: $SCRIPT_NAME options..."
  echo "Параметры:"
  echo "  -v version  Выбор версии Spark (вида v2.2.0)"
  echo "              или current (в случае, если не нужна пересборка tar)."
  echo "  -b blas     Выбор реализации LA (default/native)."
  echo "  -c config   Выбор конфигов Spark (default/local)."
  echo "  -h          Справка."
  echo
}


# --/ Получение значений опций /--------------------------------
get_options () {
  # Если скрипт запущен без аргументов, открываем справку.
  if [ $# == 1 ]; then
    print_help
  fi

  while getopts ":v:b:c:" opt ;
  do
      case $opt in
          v) VERSION=$OPTARG;
              echo "Version:              $VERSION"
              ;;
          b) BLAS=$OPTARG;
              echo "BLAS Implementation:  $BLAS"
              ;;
          c) CONFIG=$OPTARG;
              echo "Config:               $CONFIG" 
              ;;
          *) echo "Неправильный параметр";
              echo "Для вызова справки запустите $SCRIPT_NAME -h";
              exit 1
              ;;
          esac
  done
get_version
}


# --/ Получение параметров /------------------------------------
get_params () {
  get_version
  get_blas
  get_config
}


# --/ Проверка на непустую версию /-----------------------------
get_version () {
  if [[ -z $VERSION ]]; then
    dialog_version
  elif [[ $VERSION == current ]] 
  then
    cd $PACKAGE_PWD/spark_original
    VERSION=`git status | awk {'print $4'} | head -n 1`
    REBUILD="false"
  fi
}


# --/ Обработка выбора введённой имплементации BLAS /-----------
get_blas () {
  if [[ -z $BLAS ]]; then
    dialog_blas
  elif [[ $BLAS == default ]]
  then
    BLAS=""
  elif [[ $BLAS != native ]]
  then
    echo "Неверен аргумент опции -b. Аргумент может иметь значение native или default"
    echo "Введено значение $BLAS"
    exit 1
  fi
}


# --/ Обработка выбора введённой версии конфигов /--------------
get_config () {
  if [[ -z $CONFIG ]]; then
    dialog_config
  elif [ $CONFIG != local ] && [ $CONFIG != default ]
  then
    echo "Неверен аргумент опции -c. Аргумент может иметь значение local или default"
    echo "Введено значение $CONFIG"
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
          --menu "Оставить BLAS по умолчанию или добавить Native BLAS:" 20 51 4 \
          "Default"  "Use Default BLAS" \
          "Native" "Install Native BLAS" 2> $tempfile

  RETVAL=$?

  BLAS=`cat $tempfile`

  clear
  case $RETVAL in
    0)
      echo "Да вы эстет! $BLAS -- это лучшее, что вы собирали в своей жизни!";;
    1)
      echo "Отказ от ввода.";;
    255)
      echo "Нажата клавиша ESC.";;
  esac
}


# --/ Диалог о config/--------------------------------------------
dialog_config () {
  DIALOG=${DIALOG=dialog}
  tempfile=`mktemp 2>/dev/null` || tempfile=/tmp/test$$
  trap "rm -f $tempfile" 0 1 2 5 15

  $DIALOG --clear --title "Выбор конфигов" \
          --menu "Оставить конфиги по умолчанию или добавить локальные конфиги:" 20 51 4 \
          "Default"  "Use default configs" \
          "Local" "Add local configs" 2> $tempfile

  RETVAL=$?

  CONFIG=`cat $tempfile`

  clear
  case $RETVAL in
    0)
      echo "Выбраны $CONFIG конфиги";;
    1)
      echo "Отказ от ввода.";;
    255)
      echo "Нажата клавиша ESC.";;
  esac
}

# --/ Приведение значений параметров к нижнему регистру /-------
lower_params () {
  CONFIG=`echo $CONFIG | tr '[A-Z]' '[a-z]'`
  BLAS=`echo $BLAS | tr '[A-Z]' '[a-z]'`

  echo "Config: $CONFIG"
  echo "BLAS: $BLAS"
}


# --/ Удаление папки spark2, оставшейся от предыдущей сборки /--
remove_spark2_directory () {
  if [ -d $PACKAGE_PWD/spark2 ]; then
    cd $PACKAGE_PWD/spark2/
    PREVIOUS_VERSION=`find *.deb | awk -F "spark" {'print $2'} | cut -c -5`
    rm -rf $PACKAGE_PWD/spark2
    echo "<<< Удалена папка spark2"
  else
    echo "<<< Папка spark2 не обнаружена"
  fi
}


# --/ Удаление предыдущей папки spark_original с исходниками /--
remove_spark_original_directory () {
  if [ -d $PACKAGE_PWD/spark_original ]; then
    rm -rf $PACKAGE_PWD/spark_original
    echo "<<< Удалена папка spark_original"
  else
    echo "<<< Предыдущая папка spark_original не обнаружена"
  fi
}


# --/ Удаление предыдущей папки spark_synchronizer 
#                              с предыдущей версией конфигов /--
remove_spark_synchronizer_directory () {
  if [ -d $PACKAGE_PWD/spark-synchronizer ]; then
    rm -rf $PACKAGE_PWD/spark-synchronizer
    echo "<<< Удалена папка spark-synchronizer"
  else
    echo "<<< Предыдущая папка spark-synchronizer не обнаружена"
  fi
}


# --/ Клонирование исходников /---------------------------------
clone_source () {
  cd $PACKAGE_PWD
  echo ">>> Клонирование исходников"
  git clone https://github.com/apache/spark.git
  mv spark spark_original
  echo "<<< Клонирование исходников завершено"
}


# --/ Выбор собираемой версии Spark /---------------------------
get_version_from_source () {
  # заходим в папку с репозиторием
  cd $PACKAGE_PWD/spark_original
  echo ">>> Список найденных тегов"
  # смотрим релизные теги
  git tag

  if [[ -z $VERSION ]] ; then
    VERSION=`git tag | tail -n 1`
    echo "<<< Версия не введена, будет собрана последняя стабильная $VERSION"
  elif [[ $VERSION == current ]]; then
    VERSION=$PREVIOUS_VERSION
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

  if [ $BLAS == "native" ] ; then
    FLAG="-Pnetlib-lgpl"
    echo "Добавлен флаг $FLAG"
  fi

  cd $PACKAGE_PWD/spark_original


  echo './dev/make-distribution.sh --tgz --name custom-spark -Phive -Phive-thriftserver -Pyarn -DskipTests $FLAG'  
  ./dev/make-distribution.sh --tgz --name custom-spark -Phive -Phive-thriftserver -Pyarn -DskipTests $FLAG 
 
  echo "Version: $VERSION"
  NUMBER=`echo $VERSION | cut -c 2-`
  echo "Number: $NUMBER"
  TGZ_NAME=`echo "spark-$NUMBER-bin-custom-spark"`
  tar zxvf $TGZ_NAME.tgz

  echo "<<< Сборка tar Spark $VERSION для Hadoop 2.6 завершена"
  echo "<<< Название tar: $TGZ_NAME"
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
  create_spark2_install

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
 --   Etsu <etsu4296@gmail.com> $DATE_FOR_CHANGELOG +0400
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


# --/ Создание файла spark2.install /---------------------
create_spark2_install () {
  echo ">>> Создание файла spark2.install"

  echo 'usr/lib/python3/dist-packages/py4j /usr/lib/python3/dist-packages/
usr/lib/python3/dist-packages/pyspark /usr/lib/python3/dist-packages/
usr/lib/spark2 /usr/lib/' > spark2.install

  echo "<<< Создание файла spark2.install завершено"
  cat spark2.install
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
  echo "<<< Cоздание папок для библиотек завершено"

  echo ">>> Копирование собранного maven'ом проекта в директорию для deb-пакета"
  cp -r $PACKAGE_PWD/spark_original/$TGZ_NAME/* spark2/
  echo "<<< Копирование собранного maven'ом проекта в директорию для deb-пакета"

  echo ">>> Поиск всех zip файлов с библиотеками и копирование в директорию для сборки"
  cd $USR_PATH/python3/dist-packages
  find $PACKAGE_PWD/spark_original/$TGZ_NAME/python/lib/*.zip | xargs -I {} cp {} .
  echo "<<< Копирование zip файлов в директорию для сборки завершено"

  echo ">>> Распаковка и удаление zip файлов"
  find *.zip |  xargs -I {} bash -c "unzip {} && rm {}"
  echo "<<< Zip файлы распакованы"

  echo ">>> Получение названия архива py4j для записи в конфиг"
  PY4J_VERSION=`find /usr/lib/spark2/python/lib/py4j*.zip -type f -printf "%f\n"`
  echo "<<< Название получено: $PY4J_VERSION"

  chmod_libs
}


# --/ Добавление прав на исполнение в скрипты libs /------------
chmod_libs () {
  echo ">>> Добавление прав на исполнение в скрипты библиотек"
  chmod g+w -R *
  chmod +x -R *

  DIST_PACKAGES=`pwd`
  cd $DIST_PACKAGES/pyspark
  chmod +x find_spark_home.py

  cd $DIST_PACKAGES/py4j
  chmod +x *
  echo "<<< Добавление прав на исполнение в скрипты библиотек завершено"
}


# --/ Вызов создания конфигов Spark 
#       в зависимости от параметров, введённых пользователем /--
create_spark_configs_according_choice () {
  echo ">>> Вызов функций создания конфигов $CONFIG"

  if [[ $CONFIG == default ]]; then
    create_file_spark-defaults_conf
  elif [[ $CONFIG == local ]]; then
    remove_spark_synchronizer_directory
    create_local_configs
  fi
  
  echo "<<< Конфиги $CONFIG созданы"
}


# --/ Создание файла с дефолтной конфигурацией Spark /----------
create_file_spark-defaults_conf () {
  echo ">>> Создание файла conf/spark-defaults.conf"

  cd $USR_PATH/spark2/conf
  echo "spark.pyspark.python                      python3
spark.pyspark.driver.python               python3
spark.executorEnv.PYSPARK_PYTHON          python3
spark.executorEnv.PYSPARK_DRIVER_PYTHON   python3

spark.executorEnv.PYTHONPATH              \$SPARK_HOME/python/lib/$PY4J_VERSION:\$SPARK_HOME/python/lib/pyspark.zip:\$SPARK_HOME/python/:

spark.sql.catalogImplementation           hive
spark.sql.orc.filterPushdown              true
spark.ui.enabled                          true
" > spark-defaults.conf
 
  echo "<<< Создание файла conf/spark-defaults.conf завершено"
  cat spark-defaults.conf
}


# --/ Создание файлов с локальными конфигами Spark /------------
create_local_configs () {
  clone_predprod_configs
  
  cd $USR_PATH/spark2/conf/
  echo ">>> Создание копий конфигов предпрода из папки SPARK_HOME"
  cp $PACKAGE_PWD/spark-synchronizer/conf/* .
  cp -r $PACKAGE_PWD/spark-synchronizer/ $USR_PATH/spark2
  ls
  echo "<<< Создание копий конфигов предпрода из папки SPARK_HOME завершено"
}


# --/ Клонирование предпродовых конфигов /----------------------
clone_predprod_configs () {
  echo ">>> Клонирование предпродовых конфигов"
  cd $PACKAGE_PWD 
  git clone #git@.../spark-synchronizer.git  # TODO add your repo name with configs
  echo "<<< Клонирование предпродовых конфигов завершено"
}


# --/ Запуск сборки deb-пакета /--------------------------------
build_deb_package () {
  echo ">>> Запуск сборки deb-пакета"
  
  cd $PACKAGE_PWD/spark2/pack_source
  tar -cz ./* -f ../spark2_$MINOR_VERSION.orig.tar.gz
  debuild -us -uc
  
  echo "<<< Сборка deb-пакета завершена"
}



# MAIN =========================================================
main () {
  # Обработка введённых ключей
  get_options "$@"

  # Обработка пустых значений
  get_params
  lower_params 

  # Для пересборки Spark:
  remove_spark2_directory
 
  if [[ $REBUILD == "" ]]; then
    # Для скачивания исходников (можно закомментировать, если исходники уже есть):
    remove_spark_original_directory
    clone_source
  fi

  # Получение версии Spark для дальнейшей сборки
  get_version_from_source

  if [[ $REBUILD == "" ]]; then
    # Для сборки tar maven'ом, а также для пересборки tar с другой версией BLAS
    # (можно не перезапускать, если сборка нужна той же версии и с тем же флагом,
    # но обычно такое никому не надо :] )
    build_for_hadoop 
  fi

  # Подготовка файлов для создания deb-пакета
  prepare_template_for_deb_package

  # Копирование и распаковка библиотек для Spark
  copy_spark_and_libs

  # Создание конфигов Spark в соответствии с выбором
  create_spark_configs_according_choice
  
  # Сборка deb-пакета
  build_deb_package
}

main "$@"
