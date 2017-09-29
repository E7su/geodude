#!/bin/bash
ps aux | grep spark | awk {'print $2'} | xargs -I {} lsof -p {} | grep 'blas'
