#!/bin/bash
set -euo pipefail

DIR="$(dirname $0)"
source "${DIR}/utils.sh"

msg "Stop containers..."
docker-compose -f "${DIR}/docker-compose.yaml" down
