#!/bin/bash
ps axu | grep hbase | awk {'print $2'} | xargs -I {} bash -c "netstat -tlpn | grep {}"
