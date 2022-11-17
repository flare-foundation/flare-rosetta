#!/bin/bash

NETWORK_ID=$1

if [ "$1" != "flare" ] && [ "$1" != "costwo" ]; then
    echo "No valid argument was passed for the network id, using default: flare"
    NETWORK_ID="flare"
fi

if [ "$MODE" != "online" ] && [ "$MODE" != "offline" ]; then
    echo "No valid argument was passed for MODE, using default: online"
    MODE="online"
fi

if [ "$MODE" = "online" ]; then
    /app/entrypoint_flare.sh $NETWORK_ID &
fi
  
/app/entrypoint_rosetta.sh $NETWORK_ID &
  
# Wait for any process to exit
wait -n
  
# Exit with status of process that exited first
exit $?

