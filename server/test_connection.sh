test1=`sed -i "/:@/c connection.url=jdbc:oracle:thin:@$ip:1521:$dataBase" $search`
valid $test1

function valid () {
  if $test -eq 1; then
    echo "OK"
    else echo "ERROR" 
  fi
}
