#!/bin/bash

set -e

# Configuration
NETWORK_ID=localflare
ROSETTA_IMAGE="${ROSETTA_IMAGE:-rosetta-local}"
START_ROSETTA_SERVER_AFTER_BOOTSTRAP=${START_ROSETTA_SERVER_AFTER_BOOTSTRAP:-false}
MODE="${MODE:-online}"
ROSETTA_PORT=8080
CI="${CI:-false}"

if ! command -v npx &> /dev/null; then
    log_error "npx command not found. Please install Node.js v20, yarn and npm first."
    exit 1
fi

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo -e "${BLUE}$1${NC}"
}

cleanup() {
    log_info "Cleaning up..."
    ROSETTA_IMAGE=$ROSETTA_IMAGE START_ROSETTA_SERVER_AFTER_BOOTSTRAP=$START_ROSETTA_SERVER_AFTER_BOOTSTRAP MODE=$MODE docker compose -f server/docker/docker-compose.yml down
}

trap cleanup EXIT INT TERM

# Build Docker image
log_header "Localflare 5-Node Deployment with Rosetta"

if [ "$CI" != "true" ]; then
  docker build \
      --progress=plain \
      --build-arg ROSETTA_SRC=. \
      --build-arg ROSETTA_BRANCH=$(git rev-parse --abbrev-ref HEAD) \
      --tag ${ROSETTA_IMAGE} \
      -f ./server/Dockerfile \
      .
fi

ROSETTA_IMAGE=$ROSETTA_IMAGE START_ROSETTA_SERVER_AFTER_BOOTSTRAP=$START_ROSETTA_SERVER_AFTER_BOOTSTRAP MODE=$MODE docker compose -f server/docker/docker-compose.yml up -d

while true; do
    HEALTHY="$(curl -m 10 -s "http://localhost:9650/ext/health" | jq -r ".healthy")"
    if [ "$HEALTHY" != "true" ]; then
        echo "Node1 still not healthy"
        sleep 10
    else
        break
    fi
done

log_info "Localflare cluster is healthy"

# Bootstrap P-chain using go-flare test scripts
log_info "Bootstrapping P-chain using go-flare test scripts..."

# Download the test scripts from go-flare repository
rm -rf tmp && mkdir tmp
git clone --depth=1 --branch=v1.13.0 https://github.com/flare-foundation/go-flare.git tmp/go-flare
npm install -g ts-node
yarn --cwd "tmp/go-flare/test-scripts"
yarn --cwd "tmp/go-flare/test-scripts" run p-chain-import
yarn --cwd "tmp/go-flare/test-scripts" run p-chain-export

while [[ "$(curl -X POST --data '{ "jsonrpc": "2.0", "method": "platform.getHeight", "params": {}, "id": 1 }' -H 'content-type:application/json;' 127.0.0.1:9650/ext/bc/P | jq -r .result.height)" -lt "2" ]]
do
  echo "Block height not reached.. Block Height:" $(curl -X POST --data '{ "jsonrpc": "2.0", "method": "platform.getHeight", "params": {}, "id": 1 }' -H 'content-type:application/json;' 127.0.0.1:9650/ext/bc/P | jq -r .result.height)
  sleep 1
done

# Wait for rosetta to bind to port
while [[ "$(curl -X POST --data '{"metadata": {}}' -H 'content-type:application/json;' 127.0.0.1:8080/network/list | jq -r .network_identifiers[0].network)" != "localflare" ]]
do
  echo "Rosetta API not ready yet.."
  sleep 5
done

log_info "✓ Rosetta is ready!"

# Test network list endpoint
log_info "Testing /network/list endpoint..."
NETWORK_LIST_RESPONSE=$(curl -s --location --request POST "http://127.0.0.1:${ROSETTA_PORT}/network/list" \
    --header 'Content-Type: application/json' \
    --data-raw '{"metadata":{}}')

if echo "$NETWORK_LIST_RESPONSE" | jq empty 2>/dev/null; then
    log_info "✓ Network list endpoint working"
    log_info "Response: $NETWORK_LIST_RESPONSE"
else
    log_error "Invalid JSON response from /network/list"
    log_error "Response: $NETWORK_LIST_RESPONSE"
    exit 1
fi

# Install rosetta-cli
log_info "Installing rosetta-cli..."
mkdir -p tmp/rosetta
if ! curl -o tmp/rosetta/install.sh -sSfL https://raw.githubusercontent.com/coinbase/mesh-cli/refs/tags/v0.10.4/scripts/install.sh; then
    log_error "Failed to download rosetta-cli installer"
    exit 1
fi
sed -i 's/REPO="rosetta-cli"/REPO="mesh-cli"/g' tmp/rosetta/install.sh
if ! bash tmp/rosetta/install.sh -b tmp/rosetta/ v0.10.4; then
    log_error "Failed to install rosetta-cli"
    exit 1
fi
log_info "✓ rosetta-cli installed successfully"

# Run rosetta-cli check:construction
log_info "Running rosetta-cli check:construction..."

# Update config.json to use correct port
cat server/rosetta-cli-conf/localflare/config.json | jq ".online_url = \"http://127.0.0.1:${ROSETTA_PORT}\"" > tmp/config-localflare.json
cp server/rosetta-cli-conf/localflare/localflare.ros tmp

if cd tmp && timeout 5m ./rosetta/rosetta-cli --configuration-file=config-localflare.json check:construction; then
    log_info "✓ rosetta-cli check:construction passed"
else
    log_error "rosetta-cli check:construction failed"
    exit 1
fi

cd ..
ROSETTA_IMAGE=$ROSETTA_IMAGE START_ROSETTA_SERVER_AFTER_BOOTSTRAP=$START_ROSETTA_SERVER_AFTER_BOOTSTRAP MODE=$MODE docker compose -f server/docker/docker-compose.yml down

echo ""
log_info "✅ All tests passed!"
