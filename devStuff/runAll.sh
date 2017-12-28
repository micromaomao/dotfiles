#!/bin/bash

mongod_data=/tmp/maowtmdev_mongodbdata
redis_data=/tmp/maowtmdev_redisdata
elasticsearch_data=/tmp/maowtmdev_esdata

ulimit -Sv unlimited 2>/dev/null
ulimit -n unlimited 2>/dev/null
cd "$(dirname "$0")"
ensure_data_dir () {
  dir=$1
  if [ -d $dir ]; then
    echo "Deleting $dir"
    rm -rf $dir
    if [ $? -ne 0 ]; then
      echo "Failed to delete $dir. Not starting."
      exit 1
    fi
  fi
  echo "Mkdiring $dir"
  mkdir $dir
  if [ $? -ne 0 ]; then
    echo "Failed to mkdir $dir. Not starting."
    exit 1
  fi
}
stopall () {
  for pid in $(jobs -p); do
    echo "Killing $pid"
    kill -s SIGTERM $pid
    if [ $? -ne 0 ]; then
      echo "Unable to kill $pid"
      ps -Af | grep $pid
    fi
    wait $pid
  done
  exit 0
}
ensure_data_dir $mongod_data
ensure_data_dir $redis_data
ensure_data_dir $elasticsearch_data
trap stopall 0 2 14
mongod --bind_ip 127.6.0.233 --dbpath $mongod_data --nojournal --noauth &
redis-server ./redis.conf &
ES_JAVA_OPTS="-Dlog4j2.disable.jmx=true" ES_PATH_CONF="./elastic" elasticsearch &
wait
