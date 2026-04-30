# Install

[English](install.md) | [中文](install.zh-CN.md)

Build the local deb first:

```bash
./scripts/build-deb.sh
```

Do not run the build step with `sudo`. It downloads and extracts external
packages as an unprivileged user. Use `sudo` only for installing the generated
package.

Install it:

```bash
sudo dpkg -i dist/abb-agent-arm64-box64_3.2.0-5053_arm64.deb
sudo apt -f install
```

The package post-install step:

- Verifies Box64 exists at `/usr/local/bin/box64` or `/usr/bin/box64`.
- Runs `dkms add/build/install` for `synosnap/0.12.10`.
- Attempts `modprobe synosnap`.
- Runs `systemctl daemon-reload`.

The service is not enabled automatically.

Enable and start it manually:

```bash
sudo systemctl enable --now abb-box64.service
sudo systemctl status abb-box64.service --no-pager
```

Register with your NAS:

```bash
sudo abb-cli -c
```

Check status:

```bash
sudo abb-cli -s
```

Do not accept an Entire Device backup task during initial validation. Use a
small test scope and complete a restore/hash validation first.
