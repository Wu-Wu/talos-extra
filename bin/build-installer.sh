#!/bin/bash

# Build a Proxmox VE Talos installer image

TALOS_VERSION=${1:-"v1.13.0"}
REGISTRY="cr.v.zyxmasta.net"
REPOSITORY="talos/pve-iris"
INSTALLER_FILE="/tmp/out/installer-amd64.tar"
IMAGE_NAME="${REGISTRY}/${REPOSITORY}:${TALOS_VERSION}"
IMAGE_BASE="ghcr.io/siderolabs/installer-base:${TALOS_VERSION}"

EXTENSIONS=(
    "--system-extension-image ghcr.io/siderolabs/util-linux-tools:2.41.4"
    "--system-extension-image ghcr.io/siderolabs/iscsi-tools:v0.2.0"
    "--system-extension-image ghcr.io/siderolabs/qemu-guest-agent:10.2.2"
    # custom extensions
    # "--system-extension-image ${REGISTRY}/talos/core-utils:9.11.0"
    "--system-extension-image ${REGISTRY}/talos/meminfo-service:v0.1.2"
)

echo "Building installer image for ${TALOS_VERSION}..."

if [ -e $INSTALLER_FILE ]; then
    sudo rm -f $INSTALLER_FILE
fi

docker run --rm -t -v /tmp/out:/out \
    "ghcr.io/siderolabs/imager:${TALOS_VERSION}" \
    installer --platform nocloud \
    ${EXTENSIONS[@]}

if [ -e $INSTALLER_FILE ]; then
    echo "Pushing installer image to registry..."
    docker load -i /tmp/out/installer-amd64.tar
    docker tag $IMAGE_BASE $IMAGE_NAME

    docker push $IMAGE_NAME
    echo "Image available at: ${IMAGE_NAME}"
    echo "Usage:"
    echo "$ talosctl -n node_name upgrade -i ${IMAGE_NAME}"
fi
