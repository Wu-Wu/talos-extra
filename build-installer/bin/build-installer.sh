#!/bin/bash
set -euo pipefail

# Build a Proxmox VE Talos installer image

TALOS_VERSION=""
ARCH="amd64"
PUSH=1
OUT_DIR="${OUT_DIR:-/tmp/out}"
REGISTRY="${REGISTRY:-cr.v.zyxmasta.net}"
REPOSITORY="${REPOSITORY:-talos/pve-iris}"

EXTENSIONS=(
    "ghcr.io/siderolabs/util-linux-tools:2.42.2"
    "ghcr.io/siderolabs/iscsi-tools:v0.2.0"
    "ghcr.io/siderolabs/qemu-guest-agent:11.0.2"
    # custom extensions
    # "${REGISTRY}/talos/core-utils:9.11.0"
    "${REGISTRY}/talos/meminfo-service:v0.1.4"
)

usage() {
    cat <<EOF
Usage: $(basename "$0") [VERSION] [options]

Build a Talos installer image (nocloud platform) with the system
extensions listed in the script, then push it to the registry.

Arguments:
  VERSION            Talos version to build (default: v1.13.12)

Options:
  --arch ARCH        Target architecture: amd64|arm64 (default: amd64)
  --no-push          Build only, skip the registry push
  --force            Overwrite the target tag if it already exists
  --out-dir DIR      Directory for the installer tar (default: /tmp/out)
  -h, --help         Show this help

Environment overrides: REGISTRY, REPOSITORY
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --arch)
            ARCH="${2:?--arch requires a value}"
            shift 2
            ;;
        --arch=*)
            ARCH="${1#*=}"
            shift
            ;;
        --no-push)
            PUSH=0
            shift
            ;;
        --force)
            FORCE=1
            shift
            ;;
        --out-dir)
            OUT_DIR="${2:?--out-dir requires a value}"
            shift 2
            ;;
        --out-dir=*)
            OUT_DIR="${1#*=}"
            shift
            ;;
        -*)
            echo "ERROR: unknown flag: $1" >&2
            usage >&2
            exit 2
            ;;
        *)
            TALOS_VERSION="$1"
            shift
            ;;
    esac
done

TALOS_VERSION="${TALOS_VERSION:-v1.13.12}"
INSTALLER_FILE="${OUT_DIR}/installer-${ARCH}.tar"
IMAGE_NAME="${REGISTRY}/${REPOSITORY}:${TALOS_VERSION}"

echo "Building installer image ${IMAGE_NAME} (arch: ${ARCH})..."

# --- preflight: fail before the multi-gigabyte pull ---
if ! docker info >/dev/null 2>&1; then
    echo "ERROR: docker daemon is not available" >&2
    exit 1
fi

if ! [[ "$TALOS_VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "ERROR: version '${TALOS_VERSION}' does not match vX.Y.Z" >&2
    exit 1
fi

if ! [[ "$ARCH" =~ ^(amd64|arm64)$ ]]; then
    echo "ERROR: arch '${ARCH}' must be amd64 or arm64" >&2
    exit 1
fi

for image in "ghcr.io/siderolabs/imager:${TALOS_VERSION}" "${EXTENSIONS[@]}"; do
    if ! docker manifest inspect "$image" >/dev/null 2>&1; then
        echo "ERROR: image not found or not pullable: $image" >&2
        exit 1
    fi
done

if [ "$PUSH" = "1" ] && docker manifest inspect "$IMAGE_NAME" >/dev/null 2>&1 \
        && [ "${FORCE:-0}" != "1" ]; then
    echo "ERROR: ${IMAGE_NAME} already exists in ${REGISTRY}." >&2
    echo "       Bump the version or re-run with --force to overwrite." >&2
    exit 1
fi

mkdir -p "$OUT_DIR"
# Previous runs leave a root-owned tar behind; clean it from a root
# container instead of requiring sudo on the host
if [ -e "$INSTALLER_FILE" ]; then
    docker run --rm -v "${OUT_DIR}:/out" alpine:3.20 \
        rm -f "/out/installer-${ARCH}.tar"
fi

imager_args=(installer --platform nocloud --arch "$ARCH")
for ext in "${EXTENSIONS[@]}"; do
    imager_args+=(--system-extension-image "$ext")
done

docker run --rm -t --platform "linux/${ARCH}" -v "${OUT_DIR}:/out" \
    "ghcr.io/siderolabs/imager:${TALOS_VERSION}" \
    "${imager_args[@]}"

if [ ! -e "$INSTALLER_FILE" ]; then
    echo "ERROR: imager finished but ${INSTALLER_FILE} is missing" >&2
    exit 1
fi
echo "Installer tar ready: ${INSTALLER_FILE}"

if [ "$PUSH" != "1" ]; then
    echo "--no-push given, skipping registry push."
    exit 0
fi

echo "Pushing installer image to registry..."
loaded=$(docker load -i "$INSTALLER_FILE" | sed -n 's/^Loaded image: //p')
if [ -z "$loaded" ]; then
    echo "ERROR: could not determine the loaded image tag" >&2
    exit 1
fi
echo "Loaded image: ${loaded}"
docker tag "$loaded" "$IMAGE_NAME"

docker push "$IMAGE_NAME"
docker inspect --format='Pushed digest: {{index .RepoDigests 0}}' "$IMAGE_NAME"
echo "Image available at: ${IMAGE_NAME}"
echo "Usage:"
echo "$ talosctl -n node_name upgrade -i ${IMAGE_NAME}"
