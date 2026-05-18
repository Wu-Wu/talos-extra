# Build Talos Linux installer image

## Prerequisites

- Private Docker Registry at `$REGISTRY` exists;
- Registry allows anonymous push or user authenticated with `docker login` before run this build script;
- Current user has `sudo` privileges;


## Run script

```bash
bin/build-installer.sh
```

or

```bash
bin/build-installer.sh v1.13.1
```

## Script output

```shell
Building Talos installer image for v1.13.2...
skipped pulling overlay (no overlay)
profile ready:
arch: amd64
platform: nocloud
secureboot: false
name: Talos
version: v1.13.2
input:
  kernel:
    path: /usr/install/amd64/vmlinuz
  initramfs:
    path: /usr/install/amd64/initramfs.xz
  sdStub:
    path: /usr/install/amd64/systemd-stub.efi
  sdBoot:
    path: /usr/install/amd64/systemd-boot.efi
  baseInstaller:
    imageRef: ghcr.io/siderolabs/installer-base:v1.13.2
  systemExtensions:
    - imageRef: ghcr.io/siderolabs/util-linux-tools:2.42.0
    - imageRef: ghcr.io/siderolabs/iscsi-tools:v0.2.0
    - imageRef: ghcr.io/siderolabs/qemu-guest-agent:11.0.0
    - imageRef: cr.v.zyxmasta.net/talos/meminfo-service:v0.1.2
output:
  kind: installer
  outFormat: raw
initramfs ready
kernel command line: talos.platform=nocloud console=tty1 console=ttyS0 net.ifnames=0 init_on_alloc=1 slab_nomerge pti=on consoleblank=0 nvme_core.io_timeout=4294967295 printk.devkmsg=on selinux=1 module.sig_enforce=1 proc_mem.force_override=never
UKI ready
installer container image ready
output asset path: /out/installer-amd64.tar
Pushing Talos installer image to registry...
490ea03d7019: Loading layer [==================================================>]  28.35MB/28.35MB
6cd40686f96f: Loading layer [==================================================>]  111.9MB/111.9MB
Loaded image: ghcr.io/siderolabs/installer-base:v1.13.2
The push refers to repository [cr.v.zyxmasta.net/talos/pve-iris]
6cd40686f96f: Pushed
490ea03d7019: Pushed
v1.13.2: digest: sha256:f3e719f8e5a912562d662d61aa9a71641b9534bb6a7946fd8ed894c4190a0173 size: 741
Image available at: cr.v.zyxmasta.net/talos/pve-iris:v1.13.2
Usage:
$ talosctl -n node_name upgrade -i cr.v.zyxmasta.net/talos/pve-iris:v1.13.2
```
