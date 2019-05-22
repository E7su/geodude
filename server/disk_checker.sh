#!/bin/bash
for i in `seq 1 $1` ; do
(echo $i >  /disk$i/data/touch.file) 2>/dev/null
        if [ -s /disk$i/data/touch.file   ]
        then
                echo ok  $i >/dev/null
        else
                echo "disk$i POTRACHEN :("
                let ecode=2
        fi
done
if [ "$ecode" -eq "2" 2>/dev/null ]
        then
        exit $ecode
else
        exit 0
fi
