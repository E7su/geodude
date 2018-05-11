#!/bin/bash

rpm -qa | grep zepp | xargs -I {} rpm -ql {}
