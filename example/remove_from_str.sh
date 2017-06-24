#!/bin/bash
cat ./1 | awk -F '.expect' {'print $2'}
