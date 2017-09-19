#!/bin/bash

HOSTS="$(cat /opt/hadoop/etc/hadoop/slaves) master.local"

for host in ${HOSTS}; do
  echo === $host
  ssh $host -- $*;
done