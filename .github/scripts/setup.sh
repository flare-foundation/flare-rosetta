#!/bin/bash

nohup ./scripts/rosetta-server.sh localflare &

sleep 45

curl -s --location --request POST 'http://localhost:8080/network/list' \
--header 'Content-Type: application/json' \
--data-raw '{
    "metadata" : {}
}'
