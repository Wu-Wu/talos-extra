# talos-extra

Extra tooling and deployment notes for a Talos Linux fleet.

## build-installer

Builds a Talos `nocloud` installer image bundled with system extensions
(util-linux-tools, iscsi-tools, qemu-guest-agent and a custom meminfo-service),
primarily for Proxmox VE nodes. Release images are published to
[ghcr.io/wu-wu/pve-iris](https://ghcr.io/wu-wu/pve-iris) on every `v*` tag
push. See [build-installer/README.md](build-installer/README.md) for the
script usage.

## discovery-service

Notes on running the self-hosted Talos discovery service
(`ghcr.io/siderolabs/discovery-service`) behind Nginx Proxy Manager.
See [discovery-service/README.md](discovery-service/README.md).

## License

MIT - see [LICENSE](LICENSE).
