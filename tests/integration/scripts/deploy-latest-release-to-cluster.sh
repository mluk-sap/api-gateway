#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

echo "Installing APIGateway 3.4.0"
RELEASE_MANIFEST_URL="https://github.com/kyma-project/api-gateway/releases/download/3.4.0/api-gateway-manager.yaml"
curl -L "$RELEASE_MANIFEST_URL" | kubectl apply -f -
