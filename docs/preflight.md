# Preflight Checks

[English](preflight.md) | [中文](preflight.zh-CN.md)

Use the preflight checker before opening an issue or starting backup testing:

```bash
./scripts/preflight-check.sh
```

The script is read-only. It prints system information and checks for common
requirements:

- ARM64 architecture.
- Matching kernel build directory under `/lib/modules/$(uname -r)/build`.
- DKMS, compiler, make, kmod, systemd, and package tools.
- Box64 version and location.
- Common x86_64 runtime libraries required by official ABB binaries.
- Installed `abb-agent-arm64-box64` package state, if present.
- `synosnap` DKMS and loaded kernel module state.
- `abb-box64.service` enablement and runtime state.
- SELinux/AppArmor status when tools are available.

The checker does not register to NAS, create tasks, start backups, install
packages, or change systemd state.

For issue reports, redact private fields before sharing output:

- NAS hostnames and private IPs.
- Account names.
- Tokens and certificates.
- Device identifiers and UUIDs.
- Internal domains.
