#!/bin/bash

set -eo pipefail
if [ "$DEBUG" = "true" ]; then set -o xtrace; fi

export NETWORK_NAME=${NETWORK_NAME:?"Env var NETWORK_NAME is required!"}

if [ "$MODE" = "online" ]; then

    export ROSETTA_FLARE_ENDPOINT=${ROSETTA_FLARE_ENDPOINT:?"Env var ROSETTA_FLARE_ENDPOINT is required!"}

    STATUS=$(curl -m 10 -s -w %{http_code} ${ROSETTA_FLARE_ENDPOINT}/ext/health -o /dev/null)
    if [ $STATUS = "200" ]; then
        echo "go-flare :: /ext/health :: ok"
    elif [ $STATUS = "503" ] && [ $NETWORK_NAME = "localflare" ]; then
        echo "go-flare :: /ext/health :: 503-localflare" 
        is_because_of_no_peers=$(curl -s ${ROSETTA_FLARE_ENDPOINT}/ext/health | grep "network layer is unhealthy reason: not connected to a minimum of 1 peer")
        if [ -z is_because_of_no_peers ]; then
            exit 1
        fi
        echo "go-flare :: /ext/health :: ok"
    else
        echo "go-flare :: /ext/health :: FAIL"
        exit 1
    fi

    DONE_BOOTSTRAPPING=$(curl -X POST --data '{"jsonrpc": "2.0","method": "info.isBootstrapped","params":{"chain":"C"},"id":1}' -H 'Content-Type: application/json' -s ${ROSETTA_FLARE_ENDPOINT}/ext/info | jq '.result.isBootstrapped')
    if [ "$DONE_BOOTSTRAPPING" != "true" ]; then
        echo "go-flare :: bootstrapping :: FAIL"
        exit 1
    fi
    echo "go-flare :: bootstrapping :: ok"
else
    echo "go-flare :: mode!=online - healthcheck disabled :: skipped"
fi


if [ "${VALIDATE_ROSETTA_HEALTH}" != "false" ]; then
    if [ ! "$(curl -s http://localhost:8080/)" ]; then
        echo "rosetta :: bound to port :: FAIL"
        exit 1
    fi
    echo "rosetta :: bound to port :: ok"
else
    echo "rosetta :: healthcheck disabled :: skipped"
fi
echo "system :: ok"
exit 0
