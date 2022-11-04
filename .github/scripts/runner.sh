#!/usr/bin/env bash

git clone https://github.com/flare-foundation/go-flare.git
cd go-flare/avalanchego && ./scripts/build.sh
rm -rf db 
nohup ./build/avalanchego --public-ip=127.0.0.1 --http-port=9650 --staking-port=9651 --db-dir=db/node1 --network-id=localflare --staking-tls-cert-file=$(pwd)/staking/local/staker1.crt --staking-tls-key-file=$(pwd)/staking/local/staker1.key --chain-config-dir=$(pwd)/../config/localflare &
sleep 20
./scripts/test_pchain_import.sh
sleep 5
