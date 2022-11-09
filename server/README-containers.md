# flare-rosetta docker image

This image combines [go-flare](https://github.com/flare-foundation/go-flare) observer node with [rosetta-server](https://github.com/flare-foundation/flare-rosetta).

Dockerfile can be found [here](https://github.com/flare-foundation/flare-rosetta/blob/main/server/Dockerfile).

Dockerfile builds the components from source, uses multi-stage builds and is independent of local file copy.

# Running 

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