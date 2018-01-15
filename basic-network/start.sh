#!/bin/bash
set -euo pipefail

DIR="$(dirname $0)"
source "${DIR}/utils.sh"

msg "Stop containers..."
docker-compose -f "${DIR}/docker-compose.yaml" down

msg "Start containers..."
docker-compose -f "${DIR}/docker-compose.yaml" up -d \
    ca.example.com \
    orderer.example.com \
    couchdb

docker-compose -f "${DIR}/docker-compose.yaml" up -d \
    peer0.org1.example.com \
    peer1.org1.example.com

docker-compose -f "${DIR}/docker-compose.yaml" up -d \
    peer0.org2.example.com \
    peer1.org2.example.com

sleep 10

msg "Create channel..."
create_channel peer0.org1.example.com
msg "peer0.org1.example.com join channel..."
join_channel peer0.org1.example.com

msg "Fetch channel..."
fetch_channel peer1.org1.example.com
msg "peer1.org1.example.com join channel..."
join_channel peer1.org1.example.com

msg "Fetch channel..."
fetch_channel peer0.org2.example.com
msg "peer0.org2.example.com join channel..."
join_channel peer0.org2.example.com

msg "Fetch channel..."
fetch_channel peer1.org2.example.com
msg "peer1.org2.example.com join channel..."
join_channel peer1.org2.example.com
