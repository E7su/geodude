#!/bin/bash
df -h | grep tmp | grep vg | awk {'print $1'} | xargs -I {} lvextend -L +100G {}  # увеличит размер LV
df -h | grep tmp | grep vg | awk {'print $1'} | xargs -I {} resize2fs {}  # увеличит размер FS под LV
