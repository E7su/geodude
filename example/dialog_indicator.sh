
#!/bin/sh
DIALOG=${DIALOG=dialog}

COUNT=10
(
while test $COUNT != 110
do
  echo $COUNT
  echo "XXX"
  echo "Новое сообщение ($COUNT процентов)"
  echo "Строка 2"
  echo "XXX"
  COUNT=`expr $COUNT + 10`
  sleep 1
done
) |
$DIALOG --title "Индикатор" --gauge "А вот пример простейшего индикатора" 20 70 0
