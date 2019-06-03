#!/bin/bash

ssIp=$(host $SS_HOST | awk '{print $NF}')

obfsproxy --proxy socks5://$ssIp:$SS_PORT obfs3 client --dest $DEST $LISTEN
