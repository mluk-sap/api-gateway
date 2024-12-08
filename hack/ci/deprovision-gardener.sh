#!/usr/bin/env bash

#
##Description: This script deprovisions a Gardener cluster with config specified in environmental variables

set -eo pipefail

function check_required_vars() {
  local requiredVarMissing=false
  for var in "$@"; do
    if [ -z "${!var}" ]; then
      >&2 echo "Environment variable ${var} is required but not set"
      requiredVarMissing=true
    fi
  done
  if [ "${requiredVarMissing}" = true ] ; then
    exit 2
  fi
}

function check_required_files() {
  local requiredFileMissing=false
  for file in "$@"; do
    path=$(eval echo "\$$file")
    if [ ! -f "${path}" ]; then
        >&2 echo "File '${path}' required but not found"
        requiredFileMissing=true
    fi
  done
  if [ "${requiredFileMissing}" = true ] ; then
    exit 2
  fi
}

requiredVars=(
    CLUSTER_NAME
    CLUSTER_KUBECONFIG
    GARDENER_PROJECT_NAME
)

requiredFiles=(
    GARDENER_KUBECONFIG
)

check_required_vars "${requiredVars[@]}"
check_required_files "${requiredFiles[@]}"

echo "deprovisioning cluster: ${CLUSTER_NAME}"

kubectl annotate shoot "${CLUSTER_NAME}" confirmation.gardener.cloud/deletion=true \
    --overwrite \
    -n "garden-${GARDENER_PROJECT_NAME}" \
    --kubeconfig "${GARDENER_KUBECONFIG}"

kubectl delete shoot "${CLUSTER_NAME}" \
  --wait="false" \
  --kubeconfig "${GARDENER_KUBECONFIG}" \
  -n "garden-${GARDENER_PROJECT_NAME}"
