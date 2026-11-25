#!/bin/bash
set -euo pipefail

# Build a Proxmox VE Talos installer image

TALOS_VERSION=${1:-"v1.13.12"}
REGISTRY="cr.v.zyxmasta.net"
REPOSITORY="talos/pve-iris"
OUT_DIR="${OUT_DIR:-/tmp/out}"
INSTALLER_FILE="${OUT_DIR}/installer-amd64.tar"
IMAGE_NAME="${REGISTRY}/${REPOSITORY}:${TALOS_VERSION}"

EXTENSIONS=(
    "ghcr.io/siderolabs/util-linux-tools:2.42.2"
    "ghcr.io/siderolabs/iscsi-tools:v0.2.0"
    "ghcr.io/siderolabs/qemu-guest-agent:11.0.2"
    # custom extensions
    # "${REGISTRY}/talos/core-utils:9.11.0"
    "${REGISTRY}/talos/meminfo-service:v0.1.4"
)

echo "Building installer image for ${TALOS_VERSION}..."

# --- preflight: fail before the multi-gigabyte pull ---
if ! docker info >/dev/null 2>&1; then
    echo "ERROR: docker daemon is not available" >&2
    exit 1
fi

if ! [[ "$TALOS_VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "ERROR: version '${TALOS_VERSION}' does not match vX.Y.Z" >&2
    exit 1
fi

for image in "ghcr.io/siderolabs/imager:${TALOS_VERSION}" "${EXTENSIONS[@]}"; do
    if ! docker manifest inspect "$image" >/dev/null 2>&1; then
        echo "ERROR: image not found or not pullable: $image" >&2
        exit 1
    fi
done

mkdir -p "$OUT_DIR"
# Previous runs leave a root-owned tar behind; clean it from a root
# container instead of requiring sudo on the host
if [ -e "$INSTALLER_FILE" ]; then
    docker run --rm -v "${OUT_DIR}:/out" alpine:3.20 \
        rm -f "/out/$(basename "$INSTALLER_FILE")"
fi

imager_args=(installer --platform nocloud)
for ext in "${EXTENSIONS[@]}"; do
    imager_args+=(--system-extension-image "$ext")
done

docker run --rm -t -v "${OUT_DIR}:/out" \
    "ghcr.io/siderolabs/imager:${TALOS_VERSION}" \
    "${imager_args[@]}"

if [ -e "$INSTALLER_FILE" ]; then
    echo "Pushing installer image to registry..."
    loaded=$(tar -xOf "$INSTALLER_FILE" manifest.json |
        python3 -c 'import json,sys;print(json.load(sys.stdin)[0]["RepoTags"][0])')
    echo "Loaded image tag in tar: ${loaded}"
    docker load -i "$INSTALLER_FILE"
    docker tag "$loaded" "$IMAGE_NAME"

    docker push "$IMAGE_NAME"
    echo "Image available at: ${IMAGE_NAME}"
    echo "Usage:"
    echo "$ talosctl -n node_name upgrade -i ${IMAGE_NAME}"
fi
