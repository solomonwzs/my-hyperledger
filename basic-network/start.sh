#!/bin/bash
set -euo pipefail

DIR="$(dirname $0)"
ORDERER="orderer.example.com:7050"
CHANNEL_NAME="mychannel"

ca_dir="${DIR}/crypto-config/peerOrganizations/org1.example.com/ca"
docker_dir="\/etc\/hyperledger\/fabric-ca-server-config\/"
sk=`find "${ca_dir}" -iname "*_sk"`
sk=`printf $sk | sed -e 's/.*\/\(.*_sk\)/'${docker_dir}'\1/g'`

export DOCKER_CA_KEYFILE="$sk"

function msg() {
    echo -e "\033[0;32m$1\033[0m"
}

msg "Stop containers..."
docker-compose -f "${DIR}/docker-compose.yaml" down

msg "Start containers..."
docker-compose -f "${DIR}/docker-compose.yaml" up -d \
    ca.example.com \
    orderer.example.com \
    peer0.org1.example.com \
    peer0.org2.example.com \
    couchdb

sleep 10

function create_channel() {
    container=$1
    docker exec $container \
        peer channel create \
        -o "$ORDERER" \
        -c "$CHANNEL_NAME" \
        -f /etc/hyperledger/configtx/channel.tx
}

function fetch_channel() {
    container=$1
    docker exec $container \
        peer channel fetch newest "${CHANNEL_NAME}.block" \
        -o "$ORDERER" \
        -c "$CHANNEL_NAME"
}

function join_channel() {
    container=$1
    docker exec $container \
        peer channel join -b "${CHANNEL_NAME}.block"
}

msg "Create channel..."
create_channel peer0.org1.example.com

msg "peer0.org1.example.com join channel..."
join_channel peer0.org1.example.com

msg "Fetch channel..."
fetch_channel peer0.org2.example.com

msg "peer0.org1.example.com join channel..."
join_channel peer0.org2.example.com
