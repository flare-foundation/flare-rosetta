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

# Build and run the Docker image

Env variables:

| Name          | Type    | Default | Description
|---------------|---------|---------|-------------------------------------------
| MODE          | string  | `online` | Mode of operations. One of: `online`, `offline`

**Flare**
```
docker run -d -p 8080:8080 -p 9650:9650 -p 9651:9651 -v /my/host/dir/flare/db:/app/flare/db flarefoundation/flare-rosetta:latest
```

**Coston2**
```
docker run -d -p 8080:8080 -p 9650:9650 -p 9651:9651 -e MODE=offline -v /my/host/dir/costwo/db:/app/flare/db flarefoundation/flare-rosetta:latest costwo
```

You can override the default configuration files by mounting to `/app/conf`. See `server/rosetta-cli-conf` in flare-rosetta repo for the expected folder structure.

`server-config.json` is generated at runtime and will be overwritten if mounted.

You can find more information on running a node in our [official documentation](https://docs.flare.network/infra/observation/deploying/).

**Offline and online node**

```
docker run -d -p 8080:8080 -p 9650:9650 -p 9651:9651 -e MODE=online -v /my/host/dir/costwo/db_online:/app/flare/db flarefoundation/flare-rosetta:latest costwo
docker run -d -p 8081:8080 -p 19650:9650 -p 19651:9651 -e MODE=offline -v /my/host/dir/costwo/db_offline:/app/flare/db flarefoundation/flare-rosetta:latest costwo
```

Modify `server/rosetta-cli-conf/config.json -> construction.offline_url` to point to the offline node.
