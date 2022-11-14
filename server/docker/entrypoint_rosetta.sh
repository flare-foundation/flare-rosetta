#!/bin/bash

set -eo pipefail
if [ "$DEBUG" = "true" ]; then set -o xtrace; fi
sleep 1 # REQUIRED! So the entrypoint_main.sh registers the wait -n before this one fails.

export NETWORK_ID=${NETWORK_ID:?'Env var NETWORK_ID is required! Exiting...'}
export ROSETTA_FLARE_ENDPOINT=${ROSETTA_FLARE_ENDPOINT:?'Env var ROSETTA_FLARE_ENDPOINT is required! Exiting...'}
export ROSETTA_CONFIG_PATH=${ROSETTA_CONFIG_PATH:-/app/conf/$NETWORK_ID/server-config.json}


if [ "$MODE" != "online" ] && [ "$MODE" != "offline" ]; then
    echo "No valid argument was passed for MODE! Exiting..."
    exit 1
fi

if [ "$START_ROSETTA_SERVER_AFTER_BOOTSTRAP" != "true" ] && [ "$START_ROSETTA_SERVER_AFTER_BOOTSTRAP" != "false" ]; then
    echo "No valid argument was passed for START_ROSETTA_SERVER_AFTER_BOOTSTRAP, using default: false"
    START_ROSETTA_SERVER_AFTER_BOOTSTRAP=false
fi

while true
do
    STATUS=$(curl -m 10 -s -w %{http_code} ${ROSETTA_FLARE_ENDPOINT}/ext/health -o /dev/null)
    if [ $STATUS = "200" ]; then
        echo "[rosetta-start-script] Got status '$STATUS' on network id '$NETWORK_ID', OK!"
        break
    elif [ $STATUS = "503" ] && [ $NETWORK_ID = "localflare" ]; then
        echo "[rosetta-start-script] Got status '$STATUS' on network id '$NETWORK_ID', checking if because of no peers"
        is_because_of_no_peers=$(curl -s ${ROSETTA_FLARE_ENDPOINT}/ext/health | grep "network layer is unhealthy reason: not connected to a minimum of 1 peer")

        if [ ! -z is_because_of_no_peers ]; then
            echo "[rosetta-start-script] it is because there are no peers. This is okay on localflare. OK!"
            break
        fi
    fi
    echo "[rosetta-start-script] Node RPC not ready yet, got response status $STATUS on network id '$NETWORK_ID', retrying..."
    sleep 1
done


jq --arg c "${ROSETTA_FLARE_ENDPOINT}" '.rpc_endpoint=$c' "${ROSETTA_CONFIG_PATH}" | sponge "${ROSETTA_CONFIG_PATH}"
jq --arg m "${MODE}" '.mode=$m' "${ROSETTA_CONFIG_PATH}" | sponge "${ROSETTA_CONFIG_PATH}"


/app/rosetta-server/rosetta-server -config=${ROSETTA_CONFIG_PATH}
