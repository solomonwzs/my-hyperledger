#!/bin/bash
set -euo pipefail

DIR="$(dirname $0)"
CHANNEL_NAME="mychannel"
CRYPTO_CONFIG="${DIR}/crypto-config.yaml"

function generate_cert() {
    output="${DIR}/crypto-config"
    if [ -d "$output" ]; then
        rm -rf "$output"
    fi
    cryptogen generate --config="${DIR}/crypto-config.yaml" \
        --output="$output"
}

function generate_channel_artifacts() {
    cd "${DIR}"

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

generate_cert
generate_channel_artifacts
