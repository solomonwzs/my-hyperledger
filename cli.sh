#!/bin/bash
set -euo pipefail

DIR="$(dirname $0)/basic-network"
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
    output="${DIR}/channel-artifacts"
    if [ -d "$output" ]; then
        rm -rf "$output"
    fi
    mkdir -p "$output"

    configtxgen -profile OneOrgOrdererGenesis \
        -outputBlock "${output}/genesis.block"

    configtxgen -profile OneOrgChannel \
        -outputCreateChannelTx "${output}/channel.tx" \
        -channelID "$CHANNEL_NAME"

    configtxgen -profile OneOrgChannel \
        -outputAnchorPeersUpdate "${output}/Org1MSPanchors.tx" \
        -channelID "$CHANNEL_NAME" \
        -asOrg Org1MSP
}

getopts "m:" OPT
case "$OPT" in
    m)
        MODE="$OPTARG"
        ;;
esac

case "$MODE" in
    generate)
        generate_cert
        generate_channel_artifacts
        ;;
    *)
        ca_dir="${DIR}/crypto-config/peerOrganizations/org1.example.com/ca"
        docker_dir="\/etc\/hyperledger\/fabric-ca-server-config\/"
        sk=`find "${ca_dir}" -iname "*_sk"`
        printf $sk | sed -e 's/.*\/\(.*_sk\)/'${docker_dir}'\1/g'
        ;;
esac
