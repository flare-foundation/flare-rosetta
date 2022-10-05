# go-flare-rosetta

## System Requirements
- go version 1.18.5
- gcc, g++ and jq
- CPU: Equivalent of 8 AWS vCPU
- RAM: 16 GiB
- Storage: 1TB
- OS: Ubuntu 18.04/20.04 or macOS >= 10.15 (Catalina)

# Launch a Costwo testnet or Flare mainnet Node

From the `flare-rosetta/` repo, run:
```
git clone https://github.com/flare-foundation/go-flare.git
```

Build the node:
```
cd go-flare/avalanchego && ./scripts/build.sh && cd -
```

## Costwo Testnet
```
./go-flare/avalanchego/build/avalanchego --network-id=costwo --http-host= \
  --bootstrap-ips="$(curl -m 10 -sX POST \
    --data '{ "jsonrpc":"2.0", "id":1, "method":"info.getNodeIP" }' \
    -H 'content-type:application/json;' https://coston2.flare.network/ext/info \
    | jq -r ".result.ip")" \
  --bootstrap-ids="$(curl -m 10 -sX POST \
    --data '{ "jsonrpc":"2.0", "id":1, "method":"info.getNodeID" }' \
    -H 'content-type:application/json;' https://coston2.flare.network/ext/info \
    | jq -r ".result.nodeID")" \
    --chain-config-dir=$(pwd)/server/rosetta-cli-conf/costwo/
```

## Flare Mainnet
```
./go-flare/avalanchego/build/avalanchego --network-id=flare --http-host= \
  --bootstrap-ips="$(curl -m 10 -sX POST \
    --data '{ "jsonrpc":"2.0", "id":1, "method":"info.getNodeIP" }' \
    -H 'content-type:application/json;' https://flare.flare.network/ext/info \
    | jq -r ".result.ip")" \
  --bootstrap-ids="$(curl -m 10 -sX POST \
    --data '{ "jsonrpc":"2.0", "id":1, "method":"info.getNodeID" }' \
    -H 'content-type:application/json;' https://flare.flare.network/ext/info \
    | jq -r ".result.nodeID")" \
    --chain-config-dir=$(pwd)/server/rosetta-cli-conf/flare/
```

# Launch Rosetta

The following scripts use local RPC endpoints for the Flare and Costwo networks, these can be changed by editing the `"rpc_endpoint"` field in `server/rosetta-cli-conf/flare/server-config.json` and `server/rosetta-cli-conf/costwo/server-config.json`. 

## Costwo Testnet
```
./scripts/rosetta-server.sh costwo
```

## Flare Mainnet
```
./scripts/rosetta-server.sh flare
```

# Testing

Install the rosetta-cli: https://github.com/coinbase/rosetta-cli#installation

Test requirements: a fully-synced Costwo or Flare node using the above config, and a connected Flare Rosetta server.

## Costwo Testnet

check:data
```
./scripts/rosetta-cli.sh costwo data
```

The pre-funded account's private key required for the following test will be provided separately.

check:construction
```
./scripts/rosetta-cli.sh costwo construction
```

## Flare Mainnet

check:data
```
./scripts/rosetta-cli.sh flare data
```