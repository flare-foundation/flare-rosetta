# ------------------------------------------------------------------------------
# Build go-flare
# ------------------------------------------------------------------------------
FROM golang:1.21 AS flare

WORKDIR /app

ARG GO_FLARE_VERSION=v1.7.1807
ARG GO_FLARE_REPO=https://github.com/flare-foundation/go-flare

RUN git clone --branch "$GO_FLARE_VERSION" "${GO_FLARE_REPO}" .

RUN apt update && \
    apt -y install rsync
RUN cd avalanchego && \
    ./scripts/build.sh

# ------------------------------------------------------------------------------
# Build flare-rosetta
# ------------------------------------------------------------------------------
FROM golang:1.21 AS rosetta

ARG ROSETTA_SRC=https://github.com/flare-foundation/flare-rosetta/archive/refs/heads/main.zip
ARG ROSETTA_SRC_ZIP_SUBFOLDER=flare-rosetta-main

WORKDIR /tmp

ENV CGO_ENABLED=1 \
    GOARCH=amd64 \
    GOOS=linux

RUN apt update -y && apt install unzip -y
ADD ${ROSETTA_SRC} /tmp/rosetta-source
RUN if [ ! -d "/tmp/rosetta-source" ]; then \
        unzip "/tmp/rosetta-source" && \
        mv /tmp/${ROSETTA_SRC_ZIP_SUBFOLDER} /app; \
    else \
        mv /tmp/rosetta-source /app; \
    fi

WORKDIR /app/server

RUN \
  GO_VERSION=$(go version | awk {'print $3'}) \
  GIT_COMMIT=main \
  go mod download && \
  make setup && \
  make build

# ------------------------------------------------------------------------------
# Target container for running the rosetta server
# ------------------------------------------------------------------------------
FROM ubuntu@sha256:340d9b015b194dc6e2a13938944e0d016e57b9679963fdeb9ce021daac430221

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update -y && \
    apt -y upgrade && \
    apt -y install curl jq netcat dnsutils moreutils

WORKDIR /app

ENV HTTP_HOST=0.0.0.0 \
    HTTP_PORT=9650 \
    STAKING_PORT=9651 \
    DB_DIR=/data \
    DB_TYPE=leveldb \
    LOG_DIR=/app/flare/logs \
    MODE=online \
    START_ROSETTA_SERVER_AFTER_BOOTSTRAP=false \
    AUTOCONFIGURE_BOOTSTRAP_ENDPOINT="" \
    AUTOCONFIGURE_BOOTSTRAP_ENDPOINT_RETRY=0 \
    STAKING_ENABLED="true" \
    YES_I_REALLY_KNOW_WHAT_I_AM_DOING="false"



# Intentionally empty, so env vars are evalueted at runtime (script entrypoint_flare.sh) instead of build time
# Default: /app/conf/$NETWORK_ID
ENV CHAIN_CONFIG_DIR=""
# Default: warn
ENV LOG_LEVEL=""

# ROSETTA ENV VARS
ENV ROSETTA_FLARE_ENDPOINT=http://127.0.0.1:9650
# Intentionally empty, so env vars are evalueted at runtime (script entrypoint_rosetta.sh) instead of build time
# Default: /app/conf/$NETWORK_ID/server-config.json
ENV ROSETTA_CONFIG_PATH=""

# Install flare
COPY --from=flare /app/avalanchego/build /app/flare/build

# Install rosetta server
COPY --from=rosetta /app/server /app/rosetta-server

# Install node and rosetta configs
COPY --from=rosetta /app/server/rosetta-cli-conf /app/conf

# Install entrypoints
COPY --from=rosetta /app/server/docker/entrypoint_flare.sh /app/entrypoint_flare.sh
COPY --from=rosetta /app/server/docker/entrypoint_rosetta.sh /app/entrypoint_rosetta.sh
COPY --from=rosetta /app/server/docker/entrypoint_main.sh /app/entrypoint_main.sh
COPY --from=rosetta /app/server/docker/healthcheck.sh /app/healthcheck.sh

# Copy testnet configs
COPY --from=flare /app/avalanchego/staking/local /app/flare/staking/local
COPY --from=flare /app/config/localflare /app/flare/config/localflare

RUN chmod +x entrypoint_flare.sh entrypoint_rosetta.sh entrypoint_main.sh

EXPOSE ${HTTP_PORT}
EXPOSE ${STAKING_PORT}
EXPOSE 8080

HEALTHCHECK --interval=5s --timeout=5s --retries=5 --start-period=15s CMD bash /app/healthcheck.sh

ENTRYPOINT ["/bin/bash"]
CMD ["/app/entrypoint_main.sh"]
