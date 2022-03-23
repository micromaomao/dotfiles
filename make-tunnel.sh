#!/usr/bin/env bash

if [ $# -ne 1 ]; then
  echo "Usage: $0 url"
  exit 1
fi

url=$1
set -e

script=$(cat <<EOF
apt update && apt install -y curl && \
cd /tmp && \
curl -sfL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cfbin && \
chmod +x cfbin && \
./cfbin --url $url
EOF
);

docker run -it --rm --network host debian sh -c "$script"
