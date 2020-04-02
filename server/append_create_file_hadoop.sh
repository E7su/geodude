exp=0
base=10
while [[ $exp -le 1000 ]]
do
  let "exp += 1"
  echo 1 | hadoop fs -appendToFile - /user/e7su/ololo
   hadoop fs -copyFromLocal ololo /user/e7su/ololo$exp
done
