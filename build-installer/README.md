# Build Talos Linux installer image

Builds a `nocloud` Talos installer image with the system extensions listed
in `bin/build-installer.sh` (util-linux-tools, iscsi-tools, qemu-guest-agent
and the custom meminfo-service) and pushes it to the private registry as
`cr.v.zyxmasta.net/talos/pve-iris:<VERSION>`.

## Prerequisites

- Docker daemon running (the imager and extension images are pulled on
  demand);
- for the push step: `docker login cr.v.zyxmasta.net` first (or anonymous
  push allowed); skip pushing entirely with `--no-push`;
- no sudo required; the build runs on both Linux and macOS (amd64 builds on
  Apple Silicon run the amd64 imager under emulation).

## Usage

```bash
bin/build-installer.sh                  # build v1.13.12 and push
bin/build-installer.sh v1.13.12         # explicit Talos version
bin/build-installer.sh --no-push        # build only, do not touch the registry
bin/build-installer.sh --arch arm64     # arm64 installer
bin/build-installer.sh --help           # all flags
```

Flags: `--arch amd64|arm64`, `--no-push`, `--force` (overwrite an existing
target tag), `--out-dir DIR` (default `/tmp/out`), `-h/--help`.
`REGISTRY` and `REPOSITORY` can be overridden via environment.
Pushing to an existing tag is refused unless `--force` is given.

## Updating versions

- Talos version: pass it as the script argument; pick the newest release from
  <https://github.com/siderolabs/talos/releases>.
- Extensions: edit the `EXTENSIONS` array. Versions must match the
  `extensions` tag of the same Talos release
  (<https://github.com/siderolabs/extensions>): e.g. `util-linux-tools` from
  the top-level `Pkgfile`, `qemu-guest-agent` from `guest-agents/vars.yaml`,
  iscsi-tools from `storage/iscsi-tools/vars.yaml`.

## Example output

```text
$ bin/build-installer.sh
Building installer image cr.v.zyxmasta.net/talos/pve-iris:v1.13.12 (arch: amd64)...
...
    NAME               VERSION   AUTHOR
    util-linux-tools   2.42.2    Sidero Labs
    iscsi-tools        v0.2.0    Sidero Labs
    qemu-guest-agent   11.0.2    Markus Reiter
    meminfo-service    v0.1.4    Wu-Wu
...
installer container image ready
output asset path: /out/installer-amd64.tar
Installer tar ready: /tmp/out/installer-amd64.tar
Pushing installer image to registry...
Loaded image tag in tar: ghcr.io/siderolabs/installer-base:v1.13.12
...
Pushed digest: cr.v.zyxmasta.net/talos/pve-iris@sha256:...
Image available at: cr.v.zyxmasta.net/talos/pve-iris:v1.13.12
Usage:
$ talosctl -n node_name upgrade -i cr.v.zyxmasta.net/talos/pve-iris:v1.13.12
```
