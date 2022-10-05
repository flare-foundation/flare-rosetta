#!/usr/bin/env bash

rm -rf rosetta-data && ./scripts/build.sh && ./server/rosetta-server -config=./server/rosetta-cli-conf/$1/server-config.json
