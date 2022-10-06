#!/bin/bash

NETWORK_ID=$1

while true
do
    STATUS=$(curl -m 10 -s -w %{http_code} http://127.0.0.1:9650/ext/health -o /dev/null)
    if [ $STATUS = "200" ]; then
        break
    else
        echo "[rosetta-start-script] Node RPC not ready yet, got response status $STATUS"
        sleep 5
    fi
done

/app/rosetta-server/rosetta-server -config=/app/conf/$NETWORK_ID/server-config.json