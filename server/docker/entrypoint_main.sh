#!/bin/bash

set -eo pipefail
if [ "$DEBUG" = "true" ]; then set -o xtrace; fi

PID_ENTRYPOINT_ROSETTA=""
PID_ENTRYPOINT_FLARE=""

function cleanup ()
{
    if [ ! -z "${PID_ENTRYPOINT_ROSETTA}" ]; then echo "Sending KILL to ROSETTA entrypoint (pid:${PID_ENTRYPOINT_ROSETTA})..."; kill -SIGINT ${PID_ENTRYPOINT_ROSETTA}; fi
    if [ ! -z "${PID_ENTRYPOINT_FLARE}" ]; then echo "Sending KILL to FLARE entrypoint (pid:${PID_ENTRYPOINT_FLARE})..."; kill -SIGINT ${PID_ENTRYPOINT_FLARE}; fi
}

trap cleanup SIGINT


if [ "$MODE" != "online" ] && [ "$MODE" != "offline" ]; then
    echo "An invalid value ('${MODE}') was provided for MODE env variable! Exiting..."
    exit 1
fi


if [ "$MODE" = "online" ]; then
    ./entrypoint_flare.sh | sed -e 's/^/[go-flare]: /;' &
    PID_ENTRYPOINT_FLARE=$!
fi

./entrypoint_rosetta.sh | sed -e 's/^/[rosetta]: /;' &
PID_ENTRYPOINT_ROSETTA=$!

# Wait for any process to exit
wait -n
EXIT_CODE=$?

# Attempt to gracefully stop the other process
cleanup

# Exit with status of process that exited first
exit $EXIT_CODE

