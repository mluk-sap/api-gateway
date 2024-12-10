#!/usr/bin/env bash

## Description: This script deletes a Gardener cluster
## It requires the following env variables:
## - CLUSTER_NAME - name of the cluster to be created
## - GARDENER_KUBECONFIG - kubeconfig path of the Gardener cluster
## - GARDENER_PROVIDER - provider name (cloud name) used to create cluster
## Other variables are loaded from set-${GARDENER_PROVIDER}-gardener.sh script

set -eo pipefail
script_dir="$(dirname "$(readlink -f "$0")")"

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

check_required_vars GARDENER_PROVIDER
if [ ! -f "${script_dir}/set-${GARDENER_PROVIDER}-gardener.sh" ]; then
    >&2 echo "File '${script_dir}/set-${GARDENER_PROVIDER}-gardener.sh' required but not found"
    exit 2
fi
set -a # autoexport variables in the sourced file
source "${script_dir}/set-${GARDENER_PROVIDER}-gardener.sh"
set +a

requiredVars=(
    CLUSTER_NAME
    GARDENER_PROJECT_NAME
    GARDENER_PROVIDER
)

requiredFiles=(
    GARDENER_KUBECONFIG
)

check_required_vars "${requiredVars[@]}"
check_required_files "${requiredFiles[@]}"

echo "Waiting before deprovisioning"
sleep 300

echo "Deprovisioning cluster: ${CLUSTER_NAME}"

kubectl annotate shoot "${CLUSTER_NAME}" confirmation.gardener.cloud/deletion=true \
    --overwrite \
    -n "garden-${GARDENER_PROJECT_NAME}" \
    --kubeconfig "${GARDENER_KUBECONFIG}"

kubectl delete shoot "${CLUSTER_NAME}" \
  --wait="false" \
  --kubeconfig "${GARDENER_KUBECONFIG}" \
  -n "garden-${GARDENER_PROJECT_NAME}"
