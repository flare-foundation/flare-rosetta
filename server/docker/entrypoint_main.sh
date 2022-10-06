#!/bin/bash

NETWORK_ID=$1

if [ "$1" != "flare" ] && [ "$1" != "costwo" ]; then
    echo "No valid argument was passed for the network id, using default: flare"
    NETWORK_ID="flare"
fi

/app/entrypoint_flare.sh $NETWORK_ID &
  
/app/entrypoint_rosetta.sh $NETWORK_ID &
  
# Wait for any process to exit
wait -n
  
# Exit with status of process that exited first
exit $?

