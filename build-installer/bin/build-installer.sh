#!/bin/bash
set -euo pipefail

# Build a Proxmox VE Talos installer image

TALOS_VERSION=${1:-"v1.13.12"}
REGISTRY="cr.v.zyxmasta.net"
REPOSITORY="talos/pve-iris"
INSTALLER_FILE="/tmp/out/installer-amd64.tar"
IMAGE_NAME="${REGISTRY}/${REPOSITORY}:${TALOS_VERSION}"
IMAGE_BASE="ghcr.io/siderolabs/installer-base:${TALOS_VERSION}"

EXTENSIONS=(
    "ghcr.io/siderolabs/util-linux-tools:2.42.2"
    "ghcr.io/siderolabs/iscsi-tools:v0.2.0"
    "ghcr.io/siderolabs/qemu-guest-agent:11.0.2"
    # custom extensions
    # "${REGISTRY}/talos/core-utils:9.11.0"
    "${REGISTRY}/talos/meminfo-service:v0.1.4"
)

echo "Building installer image for ${TALOS_VERSION}..."

if [ -e "$INSTALLER_FILE" ]; then
    sudo rm -f "$INSTALLER_FILE"
fi

imager_args=(installer --platform nocloud)
for ext in "${EXTENSIONS[@]}"; do
    imager_args+=(--system-extension-image "$ext")
done

docker run --rm -t -v /tmp/out:/out \
    "ghcr.io/siderolabs/imager:${TALOS_VERSION}" \
    "${imager_args[@]}"

if [ -e "$INSTALLER_FILE" ]; then
    echo "Pushing installer image to registry..."
    docker load -i "$INSTALLER_FILE"
    docker tag "$IMAGE_BASE" "$IMAGE_NAME"

    docker push "$IMAGE_NAME"
    echo "Image available at: ${IMAGE_NAME}"
    echo "Usage:"
    echo "$ talosctl -n node_name upgrade -i ${IMAGE_NAME}"
fi
