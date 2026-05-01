# Contributing

[English](CONTRIBUTING.md) | [中文](CONTRIBUTING.zh-CN.md)

Thanks for helping test `abb-agent-arm64-box64`. The most useful contributions
are reproducible install results, backup/restore validation notes, distro
compatibility findings, and narrowly scoped fixes.

## Before You Open An Issue

Do not upload or paste:

- Official Synology zip/deb/rpm files.
- Generated deb/rpm packages containing Synology binaries.
- Extracted Synology proprietary files.
- NAS credentials, tokens, certificates, private hostnames, or unredacted logs.

Run the preflight checker and include the redacted output when relevant:

```bash
./scripts/preflight-check.sh
```

For package-specific checks, also run:

```bash
./scripts/verify-install.sh
./scripts/verify-rpm-vm.sh
```

## Useful Reports

High-signal reports include:

- Distribution name and version.
- Kernel version and architecture.
- Package type: DEB or RPM.
- Box64 version and install method.
- Whether `synosnap` DKMS built and loaded.
- Whether `abb-box64.service` is enabled and active.
- Whether NAS registration, backup, and restore were tested.
- Redacted `journalctl -u abb-box64.service` output.
- Redacted ABB logs, only if they are needed to reproduce the issue.

## Development Rules

- Keep generated packages, official downloads, extracted official files, and
  logs with private data out of git.
- Keep English and Chinese docs aligned in meaning.
- Prefer small pull requests with one purpose.
- Do not claim production readiness from a narrow test. Use the beta wording
  and link detailed evidence to `docs/test-report.md`.
- For scripts, keep checks explicit and readable. Avoid hidden network or
  package-manager side effects in read-only verification commands.

## Pull Request Checklist

Before opening a PR:

- Run `git status --short --ignored` and confirm only source/doc changes are
  tracked.
- Run shell syntax checks for modified shell scripts.
- Run `git diff --check`.
- Update the matching Chinese or English doc when changing user-facing docs.
- Add or update validation notes when behavior changes.
