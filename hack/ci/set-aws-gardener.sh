# This script is loaded by the provision-gardener.sh / deprovision-gardener.sh

MACHINE_TYPE="m5.xlarge"
DISK_SIZE=50
DISK_TYPE="gp2"
SCALER_MAX=3
SCALER_MIN=1
GARDENER_PROVIDER="aws"
GARDENER_REGION="eu-west-1"
GARDENER_PROVIDER_SECRET_NAME="aws-gardener-access"
GARDENER_PROJECT_NAME="goats"
GARDENER_CLUSTER_VERSION="1.29.9"
