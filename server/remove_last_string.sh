#!/bin/bash
# удалить последнюю строку
sed -ne '$q;p'

# удалить последние две строки
sed -e 'N;$!P;$!D;$d'

# удалить последние 10 строк
sed -e :a -e '$d;N;2,10ba' -e 'P;D' 
