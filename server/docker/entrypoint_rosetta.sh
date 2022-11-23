#!/bin/bash

set -eo pipefail
if [ "$DEBUG" = "true" ]; then set -o xtrace; fi
sleep 1 # REQUIRED! So the entrypoint_main.sh registers the wait -n before this one fails.

export NETWORK_NAME=${NETWORK_NAME:?'Env var NETWORK_NAME is required! Exiting...'}
export ROSETTA_FLARE_ENDPOINT=${ROSETTA_FLARE_ENDPOINT:?'Env var ROSETTA_FLARE_ENDPOINT is required! Exiting...'}
export ROSETTA_CONFIG_PATH=${ROSETTA_CONFIG_PATH:-/app/conf/$NETWORK_NAME/server-config.json}


if [ "$START_ROSETTA_SERVER_AFTER_BOOTSTRAP" != "true" ] && [ "$START_ROSETTA_SERVER_AFTER_BOOTSTRAP" != "false" ]; then
    echo "No valid argument was passed for START_ROSETTA_SERVER_AFTER_BOOTSTRAP, using default: false"
    START_ROSETTA_SERVER_AFTER_BOOTSTRAP=false
fi

if [ "$MODE" = "online" ]; then

    # Wait for go-flare port to bind
    curl ${ROSETTA_FLARE_ENDPOINT} --retry 6 --retry-connrefused --connect-timeout 5 --retry-delay 10 --silent --output /dev/null

    if [ "$START_ROSETTA_SERVER_AFTER_BOOTSTRAP" == "true" ]; then
        while true; do
            result=$(curl -X POST --data '{"jsonrpc": "2.0","method": "info.isBootstrapped","params":{"chain":"C"},"id":1}' -H 'Content-Type: application/json' -H 'cache-control: no-cache' -s ${ROSETTA_FLARE_ENDPOINT}/ext/info)
            is_bootstrapped=$(echo $result | jq '.result.isBootstrapped')
            if [ "$is_bootstrapped" = "true" ]; then
                echo "[rosetta-start-script] Network '$NETWORK_NAME' is bootstrapped, OK!"
                break
            fi
            echo "[rosetta-start-script] Network '$NETWORK_NAME' NOT bootstrapped, retrying..."
            sleep 1
        done
    fi


    while true
    do
        STATUS=$(curl -m 10 -s -w %{http_code} ${ROSETTA_FLARE_ENDPOINT}/ext/health -o /dev/null)
        if [ $STATUS = "200" ]; then
            echo "[rosetta-start-script] Got status '$STATUS' on network id '$NETWORK_NAME', OK!"
            break
        elif [ "$START_ROSETTA_SERVER_AFTER_BOOTSTRAP" = "false" ] && [ $STATUS = "503" ]; then
            echo "[rosetta-start-script] Got status '$STATUS' but we are not waiting for flare to fully bootstrap, OK!"
            break     
        elif [ $STATUS = "503" ] && [ $NETWORK_NAME = "localflare" ]; then
            echo "[rosetta-start-script] Got status '$STATUS' on network id '$NETWORK_NAME', checking if because of no peers"
            is_because_of_no_peers=$(curl -s ${ROSETTA_FLARE_ENDPOINT}/ext/health | grep "network layer is unhealthy reason: not connected to a minimum of 1 peer")

            if [ ! -z is_because_of_no_peers ]; then
                echo "[rosetta-start-script] it is because there are no peers. This is okay on localflare. OK!"
                break
            fi
        fi
        echo "[rosetta-start-script] Node RPC not ready yet, got response status $STATUS on network id '$NETWORK_NAME', retrying..."
        sleep 1
    done

    jq --arg c "${ROSETTA_FLARE_ENDPOINT}" '.rpc_endpoint=$c' "${ROSETTA_CONFIG_PATH}" | sponge "${ROSETTA_CONFIG_PATH}"

fi


jq --arg m "${MODE}" '.mode=$m' "${ROSETTA_CONFIG_PATH}" | sponge "${ROSETTA_CONFIG_PATH}"


/app/rosetta-server/rosetta-server -config=${ROSETTA_CONFIG_PATH}
