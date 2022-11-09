# ------------------------------------------------------------------------------
# Build go-flare
# ------------------------------------------------------------------------------
FROM golang:1.18.5 AS flare

WORKDIR /app
ENV ROCKSDBALLOWED=1
ARG GO_FLARE_VERSION=v0.7.1

RUN git clone --branch "$GO_FLARE_VERSION" https://github.com/flare-foundation/go-flare .

RUN apt update && \
    apt -y install rsync
RUN cd avalanchego && \
    ./scripts/build.sh

# ------------------------------------------------------------------------------
# Build flare-rosetta
# ------------------------------------------------------------------------------
FROM golang:1.18.5 AS rosetta

ARG ROSETTA_VERSION=main

WORKDIR /app

ENV CGO_ENABLED=1 \
    GOARCH=amd64 \
    GOOS=linux

RUN git clone --branch "$ROSETTA_VERSION" https://github.com/flare-foundation/flare-rosetta .

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
FROM ubuntu:20.04

# Install dependencies
RUN apt-get update -y && \
    apt -y upgrade && \
    apt -y install curl jq netcat dnsutils

WORKDIR /app

# Install flare
ENV HTTP_PORT=9650 \
    STAKING_PORT=9651 \
    DB_DIR=/app/flare/db \
    DB_TYPE=leveldb \
    LOG_DIR=/app/flare/logs \
    LOG_LEVEL=info \
    MODE=online
      
COPY --from=flare /app/avalanchego/build /app/flare/build

# Install rosetta server
COPY --from=rosetta /app/server /app/rosetta-server

# Install node and rosetta configs
COPY --from=rosetta /app/server/rosetta-cli-conf /app/conf

# Install entrypoints
COPY --from=rosetta /app/server/docker/entrypoint_flare.sh /app/entrypoint_flare.sh
COPY --from=rosetta /app/server/docker/entrypoint_rosetta.sh /app/entrypoint_rosetta.sh
COPY --from=rosetta /app/server/docker/entrypoint_main.sh /app/entrypoint_main.sh

# For local dev only
#COPY ./docker/entrypoint_flare.sh /app/entrypoint_flare.sh
#COPY ./docker/entrypoint_rosetta.sh /app/entrypoint_rosetta.sh
#COPY ./docker/entrypoint_main.sh /app/entrypoint_main.sh

RUN chmod +x entrypoint_flare.sh entrypoint_rosetta.sh entrypoint_main.sh

EXPOSE 9650
EXPOSE 9651
EXPOSE 8080

ENTRYPOINT ["/app/entrypoint_main.sh"]