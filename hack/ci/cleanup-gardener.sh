#!/usr/bin/env bash

# Description: This script deletes the Gardener cluster
# It requires the following env variables:
# - CLUSTER_NAME - Gardener cluster name
# - CLUSTER_KUBECONFIG - Gardener cluster kubeconfig path

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

requiredVars=(
    CLUSTER_NAME
)

requiredFiles=(
    CLUSTER_KUBECONFIG
)

check_required_vars "${requiredVars[@]}"
check_required_files "${requiredFiles[@]}"

echo "Cleaning up Gardener cluster cluster ${CLUSTER_NAME}, kubeconfig ${CLUSTER_KUBECONFIG}"
export KUBECONFIG="${CLUSTER_KUBECONFIG}"

LABEL="kyma-project.io/created-by-tests=true"

echo "Deleting namespaces created by tests"
for ns in $(kubectl get namespace -l "${LABEL}" -o jsonpath='{.items[*].metadata.name}' || true); do
  echo "Deleting namespace ${ns}"
	kubectl delete namespace "${ns}" --wait=false || true
done

echo "Deleting resources that are created by tests"
kubectl delete apirules -A --all --wait=false|| true
kubectl delete apigateway -A --all --wait=false || true
kubectl delete dnsentries -A --all --wait=false || true
kubectl delete certificate -A --all --wait=false || true
kubectl delete virtualservice -A --all --wait=false || true
kubectl delete istio -A --all --wait=false || true

sleep 60
