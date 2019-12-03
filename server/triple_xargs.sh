#!/bin/bash
echo {1..8} | xargs -n2 | xargs -I v1 -I v2 echo the number v1 comes before v2
# the number v1 comes before 1 2
# the number v1 comes before 3 4
# the number v1 comes before 5 6
# the number v1 comes before 7 8
