#!/bin/bash
set -euo pipefail

_DIR="$(dirname $0)"

ORDERER="orderer.example.com:7050"
CHANNEL_NAME="mychannel"
CRYPTO_CONFIG="${_DIR}/crypto-config.yaml"

_ca_dir="${_DIR}/crypto-config/peerOrganizations/org1.example.com/ca"
_docker_dir="\/etc\/hyperledger\/fabric-ca-server-config\/"
_sk=`find "${_ca_dir}" -iname "*_sk"`
_sk=`printf $_sk | sed -e 's/.*\/\(.*_sk\)/'${_docker_dir}'\1/g'`

export DOCKER_CA_KEYFILE="$_sk"

function msg() {
    echo -e "\033[0;32m$1\033[0m"
}

function generate_cert() {
    output="${_DIR}/crypto-config"
    if [ -d "$output" ]; then
        rm -rf "$output"
    fi
    cryptogen generate --config="${_DIR}/crypto-config.yaml" \
        --output="$output"
}

function generate_channel_artifacts() {
    cd "${_DIR}"

    output="channel-artifacts"
    if [ -d "$output" ]; then
        rm -rf "$output"
    fi
    mkdir -p "$output"


    configtxgen -profile TwoOrgsOrdererGenesis \
        -outputBlock "${output}/genesis.block"

    configtxgen -profile TwoOrgsChannel \
        -outputCreateChannelTx "${output}/channel.tx" \
        -channelID "$CHANNEL_NAME"

    configtxgen -profile TwoOrgsChannel \
        -outputAnchorPeersUpdate "${output}/Org1MSPanchors.tx" \
        -channelID "$CHANNEL_NAME" \
        -asOrg Org1MSP

    configtxgen -profile TwoOrgsChannel \
        -outputAnchorPeersUpdate "${output}/Org2MSPanchors.tx" \
        -channelID "$CHANNEL_NAME" \
        -asOrg Org2MSP
}

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
