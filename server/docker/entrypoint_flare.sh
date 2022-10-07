#!/bin/bash

set -eo pipefail
set -o xtrace

NETWORK_ID=$1

echo "Autoconfiguring bootstrap IPs and IDs"

if [ "$NETWORK_ID" = "flare" ]; then
	BOOTSTRAP_ENDPOINT="https://flare.flare.network/ext/info"
elif [ "$NETWORK_ID" = "costwo" ]; then
	BOOTSTRAP_ENDPOINT="https://coston2.flare.network/ext/info"
fi

echo "Using bootstrap endpoint: $BOOTSTRAP_ENDPOINT"

# Check if we can connect to the bootstrap endpoint (whitelisting)
BOOTSTRAP_STATUS=$(curl -m 10 -s -w %{http_code} -X POST --data '{ "jsonrpc":"2.0", "id":1, "method":"info.getNodeIP" }' -H 'content-type:application/json;' "$BOOTSTRAP_ENDPOINT" -o /dev/null)
if [ "$BOOTSTRAP_STATUS" = "403" ]; then
	echo "Could not connect to bootstrap endpoint. Is your IP whitelisted?"
	exit 1
fi

CHAIN_CONFIG_DIR="/app/conf/$NETWORK_ID/"

echo "Using chain config dir: $CHAIN_CONFIG_DIR"

BOOTSTRAP_IPS=$(curl -m 10 -sX POST --data '{ "jsonrpc":"2.0", "id":1, "method":"info.getNodeIP" }' -H 'content-type:application/json;' "$BOOTSTRAP_ENDPOINT" | jq -r ".result.ip")
BOOTSTRAP_IDS=$(curl -m 10 -sX POST --data '{ "jsonrpc":"2.0", "id":1, "method":"info.getNodeID" }' -H 'content-type:application/json;' "$BOOTSTRAP_ENDPOINT" | jq -r ".result.nodeID")

echo "C chain config:"
cat $CHAIN_CONFIG_DIR/C/config.json

/app/flare/build/avalanchego \
	--http-host= \
	--http-port=$HTTP_PORT \
	--staking-port=$STAKING_PORT \
	--db-dir=$DB_DIR \
	--db-type=$DB_TYPE \
	--bootstrap-ips=$BOOTSTRAP_IPS \
	--bootstrap-ids=$BOOTSTRAP_IDS \
	--chain-config-dir=$CHAIN_CONFIG_DIR \
	--log-dir=$LOG_DIR \
	--log-level=$LOG_LEVEL \
	--network-id=$NETWORK_ID