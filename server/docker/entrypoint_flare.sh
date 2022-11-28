#!/bin/bash

set -eo pipefail
if [ "$DEBUG" = "true" ]; then
	set -o xtrace
	export LOG_LEVEL=${LOG_LEVEL:-debug}
fi
sleep 1


export NETWORK_ID=${NETWORK_ID:?'Env var NETWORK_ID is required! Exiting...'}
export CHAIN_CONFIG_DIR=${CHAIN_CONFIG_DIR:-/app/conf/${NETWORK_ID}}
export LOG_LEVEL=${LOG_LEVEL:-warn}

if [ "$NETWORK_ID" != "flare" ] && [ "$NETWORK_ID" != "costwo" ] && [ "$NETWORK_ID" != "localflare" ]; then
    echo "NETWORK_ID value '${NETWORK_ID}' is not a valid network ID! Exiting..."
    exit 1
fi

if [ "$NETWORK_ID" = "flare" ]; then
	export AUTOCONFIGURE_BOOTSTRAP_ENDPOINT=${AUTOCONFIGURE_BOOTSTRAP_ENDPOINT:-'https://flare.flare.network/ext/info'}
elif [ "$NETWORK_ID" = "costwo" ]; then
	export AUTOCONFIGURE_BOOTSTRAP_ENDPOINT=${AUTOCONFIGURE_BOOTSTRAP_ENDPOINT:-'https://coston2.flare.network/ext/info'}
fi

if [ "$STAKING_ENABLED" = "false" ] && [ "$YES_I_REALLY_KNOW_WHAT_I_AM_DOING" != "i-have-read-the-documentation" ]; then
	echo "<ERROR>"
	echo "  STAKING_ENABLED env var is set to 'false'"
	echo "  but you have not confirmed that you ACTUALLY know what you are doing,"
	echo "  that you have read the documentation and are aware of the dangers of this mode"
	echo "</ERROR>"
	exit 1
fi

if [ "$FLARE_LOCAL_TXS_ENABLED" = "true" ]; then
	jq --argjson var "true" '."local-txs-enabled"=$var' "${CHAIN_CONFIG_DIR}/C/config.json" | sponge "${CHAIN_CONFIG_DIR}/C/config.json"
fi

if [ ! -z "$AUTOCONFIGURE_BOOTSTRAP_ENDPOINT" ];
then
	echo "Autoconfiguring bootstrap IPs and IDs with endpoint '${AUTOCONFIGURE_BOOTSTRAP_ENDPOINT}'"

	# Check if we can connect to the bootstrap endpoint (whitelisting)
	BOOTSTRAP_STATUS=$(curl -m 10 -s -w %{http_code} -X POST  --data '{ "jsonrpc":"2.0", "id":1, "method":"info.getNodeIP" }' -H 'content-type:application/json;' "$AUTOCONFIGURE_BOOTSTRAP_ENDPOINT" -o /dev/null)
	if [ "$BOOTSTRAP_STATUS" != "200" ]; then
		echo "Could not connect to bootstrap endpoint. Is your IP whitelisted?"
		exit 1
	fi

	if [ ! -z "$BOOTSTRAP_IPS" ]; then echo "BOOTSTRAP_IPS is defined ('${BOOTSTRAP_IPS}'), skipping autoconfigure";
	else BOOTSTRAP_IPS=$(curl -m 10 -sX POST --data '{ "jsonrpc":"2.0", "id":1, "method":"info.getNodeIP" }' -H 'content-type:application/json;' "$AUTOCONFIGURE_BOOTSTRAP_ENDPOINT" | jq -r ".result.ip")
	fi

	if [ ! -z "$BOOTSTRAP_IDS" ]; then echo "BOOTSTRAP_IDS is defined ('${BOOTSTRAP_IDS}'), skipping autoconfigure";
	else BOOTSTRAP_IDS=$(curl -m 10 -sX POST --data '{ "jsonrpc":"2.0", "id":1, "method":"info.getNodeID" }' -H 'content-type:application/json;' "$AUTOCONFIGURE_BOOTSTRAP_ENDPOINT" | jq -r ".result.nodeID")
	fi
fi

/app/flare/build/avalanchego \
	--http-host=$HTTP_HOST \
	--http-port=$HTTP_PORT \
	--staking-port=$STAKING_PORT \
	--staking-enabled=$STAKING_ENABLED \
	--public-ip=$PUBLIC_IP \
	--db-dir=$DB_DIR \
	--db-type=$DB_TYPE \
	--bootstrap-ips=$BOOTSTRAP_IPS \
	--bootstrap-ids=$BOOTSTRAP_IDS \
	--chain-config-dir=$CHAIN_CONFIG_DIR \
	--log-dir=$LOG_DIR \
	--log-level=$LOG_LEVEL \
	--network-id=$NETWORK_ID \
	$FLARE_EXTRA_ARGUMENTS
