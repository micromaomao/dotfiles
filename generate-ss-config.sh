#!/usr/bin/env zsh

if [ ! -f ./template.json ]; then
  echo 'Error: no ./template.json .'
  exit 1
fi

for host in $@; do
  ip=$(host -t A $host | awk '/has address/ {print $4}')
  if [ $? -ne 0 ]; then
    echo 'Failed to resolve host '$host
    continue
  fi
  provider=$(echo $host | grep -o '[^\.]\+\.[^\.]\+$')
  if [ ! -d $provider ]; then
    mkdir $provider -v
  fi
  filename="$provider"/"$host".json
  sed -e 's/<ipaddress>/'$ip'/g' ./template.json > $filename
  if [ $? -ne 0 ]; then
    exit $?
  fi
  echo 'File created: '$filename' '$host' -> '$ip' ( '$provider' )'
done
