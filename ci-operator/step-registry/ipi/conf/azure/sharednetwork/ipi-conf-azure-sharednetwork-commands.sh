#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail

# TODO: move to image
curl -L https://github.com/mikefarah/yq/releases/download/3.3.0/yq_linux_amd64 -o /tmp/yq && chmod +x /tmp/yq

CONFIG="${SHARED_DIR}/install-config.yaml"

if [ -f "${SHARED_DIR}/customer_vnet_subnets.yaml" ]; then
  VNET_FILE="${SHARED_DIR}/customer_vnet_subnets.yaml"
  RESOURCE_GROUP=$(cat ${SHARED_DIR}/resouregroup)
  vnet_name=$(/tmp/yq r ${VNET_FILE} 'platform.azure.virtualNetwork')
  controlPlaneSubnet=$(/tmp/yq r ${VNET_FILE} 'platform.azure.controlPlaneSubnet')
  computeSubnet=$(/tmp/yq r ${VNET_FILE} 'platform.azure.computeSubnet')

  PATCH="${SHARED_DIR}/install-config-provisioned-sharednetwork.yaml.patch"

  cat >> "${PATCH}" << EOF
platform:
  azure:
    networkResourceGroupName: ${RESOURCE_GROUP}
    virtualNetwork: ${vnet_name}
    controlPlaneSubnet: ${controlPlaneSubnet}
    computeSubnet: ${computeSubnet}
EOF
else
  PATCH=/tmp/install-config-sharednetwork.yaml.patch

  azure_region=$(/tmp/yq r "${CONFIG}" 'platform.azure.region')

  cat > "${PATCH}" << EOF
platform:
  azure:
    networkResourceGroupName: os4-common
    virtualNetwork: do-not-delete-shared-vnet-${azure_region}
    controlPlaneSubnet: subnet-1
    computeSubnet: subnet-2
EOF
fi
/tmp/yq m -x -i "${CONFIG}" "${PATCH}"
