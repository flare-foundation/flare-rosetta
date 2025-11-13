#!/bin/bash

set -eo pipefail
if [ "$DEBUG" = "true" ]; then set -o xtrace; fi
sleep 1 # REQUIRED! So the entrypoint_main.sh registers the wait -n before this one fails.

export NETWORK_ID=${NETWORK_ID:?'Env var NETWORK_ID is required! Exiting...'}
export ROSETTA_FLARE_ENDPOINT=${ROSETTA_FLARE_ENDPOINT:?'Env var ROSETTA_FLARE_ENDPOINT is required! Exiting...'}
export ROSETTA_CONFIG_PATH=${ROSETTA_CONFIG_PATH:-/app/conf/$NETWORK_ID/server-config.json}


if [ "$START_ROSETTA_SERVER_AFTER_BOOTSTRAP" != "true" ] && [ "$START_ROSETTA_SERVER_AFTER_BOOTSTRAP" != "false" ]; then
    echo "No valid argument was passed for START_ROSETTA_SERVER_AFTER_BOOTSTRAP, using default: false"
    START_ROSETTA_SERVER_AFTER_BOOTSTRAP=false
fi

if [ "$MODE" = "online" ]; then

    # Wait for go-flare port to bind
    sleep 30
    curl ${ROSETTA_FLARE_ENDPOINT} --retry 6 --retry-connrefused --retry-all-errors --connect-timeout 5 --retry-delay 10 --silent --output /dev/null

    if [ "$START_ROSETTA_SERVER_AFTER_BOOTSTRAP" == "true" ]; then
        while true; do
            result=$(curl -X POST --data '{"jsonrpc": "2.0","method": "info.isBootstrapped","params":{"chain":"C"},"id":1}' -H 'Content-Type: application/json' -H 'cache-control: no-cache' -s ${ROSETTA_FLARE_ENDPOINT}/ext/info)
            is_bootstrapped=$(echo $result | jq '.result.isBootstrapped')
            if [ "$is_bootstrapped" = "true" ]; then
                echo "[rosetta-start-script] Network '$NETWORK_ID' is bootstrapped, OK!"
                break
            fi
            echo "[rosetta-start-script] Network '$NETWORK_ID' NOT bootstrapped, retrying..."
            sleep 1
        done
    fi


    while true
    do
        STATUS=$(curl -m 10 -s -w %{http_code} ${ROSETTA_FLARE_ENDPOINT}/ext/health -o /dev/null)
        if [ $STATUS = "200" ]; then
            echo "[rosetta-start-script] Got status '$STATUS' on network id '$NETWORK_ID', OK!"
            break
        elif [ "$START_ROSETTA_SERVER_AFTER_BOOTSTRAP" = "false" ] && [ $STATUS = "503" ]; then
            echo "[rosetta-start-script] Got status '$STATUS' but we are not waiting for flare to fully bootstrap, OK!"
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

    jq --arg c "${ROSETTA_FLARE_ENDPOINT}" '.rpc_base_url=$c' "${ROSETTA_CONFIG_PATH}" | sponge "${ROSETTA_CONFIG_PATH}"

    # Fetch and update genesis block hash dynamically for localflare only
    if [ "$NETWORK_ID" = "localflare" ]; then
        echo "[rosetta-start-script] Fetching genesis block hash from RPC for localflare network..."
        GENESIS_HASH=$(curl -s -X POST --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["0x0",false],"id":1}' \
            -H 'content-type:application/json;' \
            "${ROSETTA_FLARE_ENDPOINT}/ext/bc/C/rpc" | jq -r '.result.hash')

        if [ ! -z "$GENESIS_HASH" ] && [ "$GENESIS_HASH" != "null" ]; then
            echo "[rosetta-start-script] Updating genesis_block_hash to: $GENESIS_HASH"
            jq --arg g "${GENESIS_HASH}" '.genesis_block_hash=$g' "${ROSETTA_CONFIG_PATH}" | sponge "${ROSETTA_CONFIG_PATH}"
        else
            echo "[rosetta-start-script] WARNING: Could not fetch genesis block hash, using existing value"
        fi
    fi

fi


jq --arg m "${MODE}" '.mode=$m' "${ROSETTA_CONFIG_PATH}" | sponge "${ROSETTA_CONFIG_PATH}"


/app/rosetta-server/rosetta-server -config="${ROSETTA_CONFIG_PATH}"
