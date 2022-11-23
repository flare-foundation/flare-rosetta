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

# Run via Container

# Build and run the Docker image

The Docker image contains the node and rosetta-server.

```
docker build --progress=plain -t my-local-flare-rosetta-image .
```

Run for Flare network:
```
docker run -p 8080:8080 -p 9650:9650 -p 9651:9651 -e NETWORK_ID=flare -v /my/flare/db:/app/flare/db my-local-flare-rosetta-image
```

Run for Costwo network:
```
docker run -p 18080:8080 -p 19650:9650 -p 19651:9651 -e NETWORK_ID=costwo -v /my/costwo/db:/app/flare/db my-local-flare-rosetta-image
```

Specify network id as first docker run argument. If you want to preserve the node database, mount a local host directory to `/app/flare/db`.

### Environment variables

| Name | Default | Description |
|:--|:--|:--|
| `DEBUG` | `false` | Set to `true` to enable debug mode. Prints every executed command, sets [--log-level=debug](https://docs.avax.network/nodes/maintain/avalanchego-config-flags#--log-level-string-verbo-debug-trace-info-warn-error-fatal-off) |
| `HTTP_HOST` | `0.0.0.0` | The bind address of the service |
| `HTTP_PORT` | `9650` | The port on which the API is served |
| `STAKING_PORT` | `9651` | The staking port for bootstrapping nodes |
| `PUBLIC_IP` | _(empty)_ | The public IP of the service |
| `DB_DIR` | `/data` | The database directory location |
| `DB_TYPE` | `leveldb` | The database type to be used |
| `BOOTSTRAP_IPS` | _(empty)_ | A list of bootstrap server ips; ref [--bootstrap-ips-string](https://docs.avax.network/nodes/maintain/avalanchego-config-flags#--bootstrap-ips-string) |
| `BOOTSTRAP_IDS` | _(empty)_ | A list of bootstrap server ids; ref [--bootstrap-ids-string](https://docs.avax.network/nodes/maintain/avalanchego-config-flags#--bootstrap-ids-string) |
| `CHAIN_CONFIG_DIR` | `/app/flare/config/${NETWORK_ID}` | Chain configuration directory for flare |
| `LOG_DIR` | `/app/logs` | Logging directory |
| `LOG_LEVEL` | `warn` | [Logging level](https://docs.avax.network/nodes/maintain/avalanchego-config-flags#--log-level-string-verbo-debug-trace-info-warn-error-fatal-off). If explicitly set (not default) also overwrites `DEBUG` setting it to `debug`. |
| `NETWORK_ID` | `costwo` | The network id. The common ids are `flare` and `costwo` |
| `AUTOCONFIGURE_BOOTSTRAP_ENDPOINT_RETRY` | `0` | How many times, with delay of 10 seconds, should we retry contacting the bootstrap node. Handy when a node will bootstrap from another parallel-start node. |
| `AUTOCONFIGURE_BOOTSTRAP_ENDPOINT` | _(empty)_ | Endpoint used for [bootstrapping](https://docs.avax.network/nodes/maintain/avalanchego-config-flags#bootstrapping). Ex. `https://coston2.flare.network/ext/info`, `https://flare.flare.network/ext/info` |
| `FLARE_LOCAL_TXS_ENABLED` | `false` | Set to `true` when running a one-node setup (ex. localflare). Docs about [local-txs-enabled-boolean](https://docs.avax.network/nodes/maintain/chain-config-flags#local-txs-enabled-boolean). |
| `FLARE_EXTRA_ARGUMENTS` | | Extra arguments passed to flare binary |
| `ROSETTA_FLARE_ENDPOINT` | `http://127.0.0.1:9650` | go-flare HTTP endpoint used by rosetta |
| `ROSETTA_CONFIG_PATH` | `/app/conf/${NETWORK_ID}/server-config.json` | Configuration path used by rosetta |
| `STAKING_ENABLED` | `true` | set it to `false` to make avalanchego sample all nodes, not just validators. Read [Disabling staking](#disabling-staking)! Avalanchego docs: [--staking-enabled](https://docs.avax.network/nodes/maintain/avalanchego-config-flags#--staking-enabled-boolean). |
| `MODE` | `online` | Run rosetta in [`online`](https://www.rosetta-api.org/docs/node_deployment.html#online-mode-endpoints) or [`offline`](https://www.rosetta-api.org/docs/node_deployment.html#offline-mode-endpoints) mode |
| `START_ROSETTA_SERVER_AFTER_BOOTSTRAP` | `false` | Waits for go-flare to fully bootstrap before launching rosetta-server |


#### Disabling staking

Disabling Proof od Stake is **dangerous**! Read the [avalanchego documentation](https://docs.avax.network/nodes/maintain/avalanchego-config-flags#--staking-enabled-boolean).

#### Confirming dangerous settings

To confirm dangrous settings set the environment variable `YES_I_REALLY_KNOW_WHAT_I_AM_DOING` to "i have read the documentation" with spaces replaced with minuses.




**Flare**
```
docker run -d -p 8080:8080 -p 9650:9650 -p 9651:9651 -v /my/host/dir/flare/db:/data flarefoundation/flare-rosetta:latest
```

**Coston2**
```
docker run -d -p 8080:8080 -p 9650:9650 -p 9651:9651 -e MODE=offline -v /my/host/dir/costwo/db:/data flarefoundation/flare-rosetta:latest costwo
```

You can override the default configuration files by mounting to `/app/conf`. See `server/rosetta-cli-conf` for the expected folder structure.

`server-config.json` is generated at runtime and will be overwritten if mounted.

You can find more information on running a go-flare node in our [official documentation](https://docs.flare.network/infra/observation/deploying/).

**Offline and online node**

```
docker run -d -p 8080:8080 -p 9650:9650 -p 9651:9651 -e MODE=online -v /my/host/dir/costwo/db_online:/data flarefoundation/flare-rosetta:latest costwo
docker run -d -p 8081:8080 -p 19650:9650 -p 19651:9651 -e MODE=offline -v /my/host/dir/costwo/db_offline:/data flarefoundation/flare-rosetta:latest costwo
```

Modify cli config in `server/rosetta-cli-conf/config.json -> construction.offline_url` to point to the offline node.
