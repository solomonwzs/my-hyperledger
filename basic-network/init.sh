#!/bin/bash
set -euo pipefail

DIR="$(dirname $0)"
source "${DIR}/utils.sh"

generate_cert
generate_channel_artifacts
