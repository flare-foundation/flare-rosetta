#!/bin/bash

NETWORK_ID=$1

if [ "$START_ROSETTA_SERVER_AFTER_BOOTSTRAP" != "true" ] && [ "$START_ROSETTA_SERVER_AFTER_BOOTSTRAP" != "false" ]; then
    echo "No valid argument was passed for START_ROSETTA_SERVER_AFTER_BOOTSTRAP, using default: false"
    START_ROSETTA_SERVER_AFTER_BOOTSTRAP=false
fi

if [ "$NETWORK_ID" = "flare" ]; then
cat <<EOF > /app/conf/flare/server-config.json
{
    "mode": "$MODE",
    "rpc_endpoint": "http://127.0.0.1:9650",
    "network_name": "Flare",
    "genesis_block_hash": "0xf501834f1cfce08939acb0feadb11ca0a94d806c5bedb6700a771fc27d2f1068",
    "chain_id": 14
}
EOF
elif [ "$NETWORK_ID" = "costwo" ]; then
cat <<EOF > /app/conf/costwo/server-config.json
{
    "mode": "$MODE",
    "rpc_endpoint": "http://127.0.0.1:9650",
    "network_name": "Costwo",
    "genesis_block_hash": "0xc47d9c5d19d9cde5316780d1b0896ce2f20a0bc09c9ce2c86fbfafc0742b1e63",
    "chain_id": 114
}
EOF
fi

if [ "$MODE" = "online" ]; then
    while true
    do
        STATUS=$(curl -m 10 -s -w %{http_code} http://127.0.0.1:9650/ext/health -o /dev/null)
        if [ $STATUS = "200" ]; then
            break
        elif [ "$START_ROSETTA_SERVER_AFTER_BOOTSTRAP" = "false" ] && [ $STATUS = "503" ]; then
            break     
        else
            echo "[rosetta-start-script] Node RPC not ready yet, got response status $STATUS"
            sleep 5
        fi
    done
fi

/app/rosetta-server/rosetta-server -config=/app/conf/$NETWORK_ID/server-config.json