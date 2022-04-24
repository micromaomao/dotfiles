#!/usr/bin/env bash

if [ $# -ne 1 ]; then
  echo "Usage: $0 url"
  exit 1
fi

cd "$(dirname "$0")"
url=$1
set -e
docker build . -f tunnel.Dockerfile -t tunnel
docker run -it --rm --network host tunnel "$url"
