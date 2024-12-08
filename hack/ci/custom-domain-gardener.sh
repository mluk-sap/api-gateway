#!/usr/bin/env bash

#
##Description: This scripts installs and tests api-gateway custom domain test as well as gateway test using the CLI on a real Gardener GCP cluster.
## exit on error, and raise error when variable is not set when used
## IMG env variable expected (for make deploy), which points to the image in the registry

set -eo pipefail

if [ $# -lt 1 ]; then
    >&2 echo "Make target is required as parameter"
    exit 2
fi

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
    CLIENT_ID
    CLIENT_SECRET
    OIDC_CONFIG_URL
    TEST_SA_ACCESS_KEY_PATH
)

requiredFiles=(
    TEST_SA_ACCESS_KEY_PATH
)

check_required_vars "${requiredVars[@]}"
check_required_files "${requiredFiles[@]}"

echo "executing custom domain tests in cluster ${CLUSTER_NAME}, kubeconfig ${CLUSTER_KUBECONFIG}"
export KUBECONFIG="${CLUSTER_KUBECONFIG}"

export CLUSTER_DOMAIN=$(kubectl get configmap -n kube-system shoot-info -o jsonpath="{.data.domain}")
echo "cluster domain: ${CLUSTER_DOMAIN}"

export GARDENER_PROVIDER=$(kubectl get configmap -n kube-system shoot-info -o jsonpath="{.data.provider}")
echo "gardener provider: ${CLUSTER_DOMAIN}"

export TEST_DOMAIN="${CLUSTER_DOMAIN}"
export KYMA_DOMAIN="${CLUSTER_DOMAIN}" # it is required by env_vars.sh
export TEST_CUSTOM_DOMAIN="goat.build.kyma-project.io"
export IS_GARDENER=true

# Add pwd to path to be able to use binaries downloaded in scripts
export PATH="${PATH}:${PWD}"

echo "installing istio"
make install-istio

echo "deploying api-gateway"
make deploy

echo "waiting for the ingress gateway external address"
[ "$GARDENER_PROVIDER" == "aws" ] && address_field="{.status.loadBalancer.ingress[0].hostname}" || address_field="{.status.loadBalancer.ingress[0].ip}"
kubectl wait --timeout=300s --namespace istio-system services/istio-ingressgateway --for=jsonpath="${address_field}"
ingress_external_address=$(kubectl get services --namespace istio-system istio-ingressgateway --output jsonpath="${address_field}")
ingress_external_status_port=$(kubectl get services --namespace istio-system istio-ingressgateway --output jsonpath='{.spec.ports[?(@.name=="status-port")].targetPort}')

echo "determined ingress external address: ${ingress_external_address} and external status port: ${ingress_external_status_port}"

echo "waiting until it is possible to connect to the ingress gateway"
trial=1
# check if it is possible to establish connection to the ingress gateway (the exact http status code doesn't matter)
until curl --silent --output /dev/null "http://${ingress_external_address}:${ingress_external_status_port}"
do
  if (( trial >= 60 ))
  then
     echo "exceeded number of trials while waiting for the ingress gateway, giving up..."
     exit 4
  fi
  echo "ingress gateway does not respond, trying again..."
  sleep 10
  trial=$((trial + 1))
done
echo "ingress gateway responded"

for make_target in "$@"
do
    echo "executing make target $make_target"
    make $make_target
done
