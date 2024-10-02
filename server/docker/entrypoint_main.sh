#!/bin/bash

set -eo pipefail
if [ "$DEBUG" = "true" ]; then set -o xtrace; fi

PID_ENTRYPOINT_ROSETTA=""
PID_ENTRYPOINT_FLARE=""

function cleanup ()
{
    if kill -0 "$PID_ENTRYPOINT_FLARE"; then
        echo "Flare process detected as exited"
    fi

    if kill -0 "$PID_ENTRYPOINT_ROSETTA"; then
        echo "Rosetta process detected as exited"
    fi

    if [ ! -z "${PID_ENTRYPOINT_ROSETTA}" ]; then echo "Sending KILL to ROSETTA entrypoint (pid:${PID_ENTRYPOINT_ROSETTA})..."; kill -SIGINT ${PID_ENTRYPOINT_ROSETTA}; fi
    if [ ! -z "${PID_ENTRYPOINT_FLARE}" ]; then echo "Sending KILL to FLARE entrypoint (pid:${PID_ENTRYPOINT_FLARE})..."; kill -SIGINT ${PID_ENTRYPOINT_FLARE}; fi
}

trap cleanup SIGINT

if [ "$MODE" != "online" ] && [ "$MODE" != "offline" ]; then
    echo "An invalid value ('${MODE}') was provided for MODE env variable! Exiting..."
    exit 1
fi


if [ "$MODE" = "online" ]; then
    echo "Starting flare node in ONLINE mode"
    ./entrypoint_flare.sh | sed -e 's/^/[go-flare]: /;' &
    PID_ENTRYPOINT_FLARE=$!
fi

echo "Starting rosetta server"
./entrypoint_rosetta.sh | sed -e 's/^/[rosetta]: /;' &
PID_ENTRYPOINT_ROSETTA=$!

# Wait for any process to exit
echo "Waiting for either process to exit"
wait -n
EXIT_CODE=$?

echo "Cleaning up and terminating processes due to exit code $EXIT_CODE"

# Attempt to gracefully stop the other process
cleanup

# Exit with status of process that exited first
exit $EXIT_CODE

