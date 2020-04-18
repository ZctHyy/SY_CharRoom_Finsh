#!/bin/bash
cd /data/practice.dev/zone/study_1 
erl -pa /data/practice.dev/server/ebin  -name study_1@localhost -s main -setcookie abdoc3
