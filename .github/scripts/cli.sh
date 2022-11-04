#!/bin/bash

# downloading cli
curl -sSfL https://raw.githubusercontent.com/coinbase/rosetta-cli/master/scripts/install.sh | sh -s

echo "start check:construction"
./bin/rosetta-cli --configuration-file=server/rosetta-cli-conf/localflare/config.json check:construction
