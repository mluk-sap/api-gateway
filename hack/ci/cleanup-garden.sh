#!/usr/bin/env bash

# Description: This script deletes the Gardener cluster
# It requires the following env variables:
# - GARDENER_KUBECONFIG - Gardener kubeconfig path
# - GARDENER_PROJECT_NAME - name of the Gardener project

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
    GARDENER_PROJECT_NAME
)

requiredFiles=(
    GARDENER_KUBECONFIG
)

LABEL="kyma-project.io/created-by-tests=true"
PREFIX="ag-"
MAX_AGE_IN_SEC=7200

check_required_vars "${requiredVars[@]}"
check_required_files "${requiredFiles[@]}"

echo "Cleaning garden: ${GARDENER_PROJECT_NAME}"
current_ts=$(date +%s)
threshold_ts=$(($current_ts-$MAX_AGE_IN_SEC))
echo "Current timestamp: ${current_ts}, threshold timestamp: ${threshold_ts}"

for cluster_name in $(kubectl get shoot --kubeconfig="${GARDENER_KUBECONFIG}" -l "${LABEL}" -o jsonpath="{.items[*].metadata.name}"); do
  echo "Analyzing cluster ${cluster_name}"

  if [[ "$cluster_name" == "$PREFIX"* ]]; then
    echo "Cluster name starts with $PREFIX, checking creation timestamp"
    creation_ts=$(kubectl get shoot --kubeconfig="${GARDENER_KUBECONFIG}" "${cluster_name}" -o json | jq -r '.metadata.creationTimestamp | fromdateiso8601')

    if [ "${creation_ts}" -lt "${threshold_ts}" ]; then
      echo "Cluster ${cluster_name} with creation timestamp ${creation_ts} is older than the threshold timestamp ${threshold_ts}, deleting..."

      echo "Cleaning up cluster ${cluster_name}"
      export CLUSTER_NAME="${cluster_name}"
      export CLUSTER_KUBECONFIG="kubeconfig-${cluster_name}.yaml"
      exit_code=0
      kubectl create --kubeconfig "${GARDENER_KUBECONFIG}" \
          -f <(printf '{"spec":{"expirationSeconds":86400}}') \
          --raw "/apis/core.gardener.cloud/v1beta1/namespaces/garden-${GARDENER_PROJECT_NAME}/shoots/${cluster_name}/adminkubeconfig" | \
          jq -r ".status.kubeconfig" | \
          base64 -d > "${CLUSTER_KUBECONFIG}" || exit_code=$?
      if [ "${exit_code}" -ne 0 ]; then
        echo "Can't get kubeconfig for cluster ${cluster_name}, exit code=${exit_code}, skipping cleanup"
      else
        exit_code=0
        "${script_dir}/cleanup-gardener.sh" || exit_code=$?
        if [ "${exit_code}" -ne 0 ]; then
          echo "Can't clean cluster ${cluster_name}, exit code=${exit_code}"
        fi
      fi

      echo "Deleting cluster ${cluster_name}"
      "${script_dir}/deprovision-gardener.sh" || exit_code=$?
      if [ "${exit_code}" -ne 0 ]; then
        echo "Can't delete cluster ${cluster_name}, exit code=${exit_code}"
      fi
    else
      echo "Cluster ${cluster_name} with creation timestamp ${creation_ts} is younger than the threshold timestamp ${threshold_ts}, skipping deletion"
    fi
  else
    echo "Cluster name ${cluster_name} doesn't start with $PREFIX, skipping deletion";
  fi

done
