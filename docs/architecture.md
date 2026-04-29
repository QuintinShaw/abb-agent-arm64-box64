# Architecture

[English](architecture.md) | [中文](architecture.zh-CN.md)

`abb-agent-arm64-box64` packages a local compatibility stack for running the
Synology Active Backup for Business Linux x86_64 Agent on ARM64.

## Components

- ARM64 Linux kernel
- ARM64 native `synosnap` DKMS kernel module
- Box64 x86_64 userspace emulator
- Official Synology ABB x86_64 userspace files extracted locally from the official package
- Community wrapper scripts and systemd unit
- Community mount-enumeration compatibility shim

## Data Path

```text
ABB x86_64 userspace
  -> Box64
  -> x86_64 libsynosnap.so
  -> Linux syscall/ioctl boundary
  -> ARM64 native synosnap kernel module
  -> /dev/synosnap*
```

The key PoC result is that private snapshot ioctl calls from x86_64 ABB
userspace under Box64 reached the native ARM64 `synosnap` kernel module.

## Why Box64

The PoC found Box64 materially better than QEMU for this workload. Box64 could
run ABB tools and pass the private ioctl path needed by `sbdctl` and the ABB
daemon.

QEMU is not the primary route for this project.

## Mount Enumeration Shim

On the tested ARM64 host, x86_64 `libmount.so.1` under Box64 opened and read
`/proc/self/mountinfo` but produced an empty mount table. ABB then returned no
custom volumes to the NAS.

The package builds and installs an x86_64 preload shim:

```text
/usr/local/lib/abb-agent-arm64-box64/mount_shim.so
```

The wrapper loads this shim with `BOX64_LD_PRELOAD` when present. It implements
only the subset of libmount symbols ABB used during the PoC.

This is a compatibility workaround, not a general libmount replacement.
