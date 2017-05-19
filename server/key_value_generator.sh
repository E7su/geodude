for x in {1..1000000} ; do echo $(shuf -i1-10 -n1):$(shuf -i1-10 -n1) >> /tmp/2 ; done
