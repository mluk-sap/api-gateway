# This script is loaded by the provision-gardener.sh / deprovision-gardener.sh

MACHINE_TYPE="n2-standard-4"
DISK_SIZE=50
DISK_TYPE="pd-standard"
SCALER_MAX=3
SCALER_MIN=1
GARDENER_PROVIDER="gcp"
GARDENER_REGION="europe-west3"
GARDENER_PROVIDER_SECRET_NAME="goat"
GARDENER_PROJECT_NAME="goats"
GARDENER_CLUSTER_VERSION="1.29.9"
