#!/bin/bash

cd /home/webiva/current/script
for file in ../log/mongrel.*.pid; do
   kill -s USR2 `cat $file`
   sleep 2
done
