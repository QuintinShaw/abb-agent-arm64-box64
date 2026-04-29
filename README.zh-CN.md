# abb-agent-arm64-box64

[English](README.md) | 中文

在 ARM64 Linux 上，通过 ARM64 原生 `synosnap` DKMS 内核模块 + Box64 运行 Synology Active Backup for Business Linux x86_64 Agent。

状态：Experimental / PoC / 不建议生产使用。

本仓库不包含、也不再分发 Synology 官方二进制文件。

## 风险声明

本项目不是 Synology 官方项目，也不受 Synology 支持。它仅用于学习、研究和兼容性实验。

备份软件必须经过恢复验证才能被信任。你需要自行承担数据、NAS、服务器、内核模块和恢复方案的风险。

除非你已经完成完整恢复验证、长时间压力测试、备份中断测试、断电恢复测试、内核升级测试和裸机恢复测试，否则不要用于生产环境。

## 本仓库不包含什么

不要向本仓库上传：

- Synology 官方 zip/deb 文件
- 本地生成的、包含 Synology 二进制文件的 deb
- 解包后的 Synology 文件
- NAS 账号、证书、token 或未打码日志

构建脚本会在用户本机下载官方 Synology 包，或者使用用户通过 `ABB_OFFICIAL_ZIP` 提供的官方 zip。

## 安装依赖

```bash
sudo apt update
sudo apt install -y git dkms build-essential "linux-headers-$(uname -r)" kmod systemd unzip wget dpkg-dev gcc-x86-64-linux-gnu
```

安装 Box64：

```bash
sudo ./scripts/install-box64.sh
```

该脚本固定默认 `BOX64_REF=v0.4.2`。也可以自行安装 Box64。

## 构建本地 deb

不要用 `sudo` 运行构建脚本。构建阶段会下载并解包外部包，应以普通用户执行。

```bash
./scripts/build-deb.sh
```

使用手动下载的官方 zip：

```bash
ABB_OFFICIAL_ZIP=/path/to/official.zip ABB_OFFICIAL_SHA256=<sha256> ./scripts/build-deb.sh
```

默认官方 zip 会使用脚本内置 SHA256 校验。自定义 zip 默认要求提供 `ABB_OFFICIAL_SHA256`。

输出：

```text
dist/abb-agent-arm64-box64_3.2.0-5053_arm64.deb
```

该 deb 仅供本机私有测试使用，不要上传到 GitHub Release。

## 安装本地 deb

```bash
sudo dpkg -i dist/abb-agent-arm64-box64_3.2.0-5053_arm64.deb
sudo apt -f install
sudo systemctl start abb-box64.service
sudo abb-cli -c
```

服务不会默认开机自启。

## 验证

```bash
lsmod | grep synosnap
systemctl status abb-box64.service --no-pager
abb-cli -s
```

然后在 NAS 端确认 Agent 在线。

初次测试时不要选择“整台设备”，也不要选择真实根分区 `/`。请只使用测试卷或测试目录，并完成恢复校验。

## 恢复校验

最小安全流程：

1. 创建临时测试卷或测试目录。
2. 写入测试文件。
3. 保存源文件 `sha256sum`。
4. NAS 任务只选择测试范围。
5. 执行首次备份。
6. 修改测试数据并新增文件。
7. 执行增量备份。
8. 恢复到另一个临时目录。
9. 用相对路径对比恢复文件和源文件 hash。

只有 hash 完全一致，才认为最小恢复闭环通过。

## PoC 结果摘要

已验证：

- ARM64 原生 `synosnap` DKMS 编译并加载。
- Box64 可运行 ABB x86_64 用户态工具。
- x86_64 `sbdctl` 经 Box64 可创建和销毁 `/dev/synosnap0`。
- ABB daemon 可连接 NAS。
- 安全自定义卷 `/mnt/abb-scsi-test` 完成首次备份。
- 第二次备份使用 CBT/增量路径，传输约 8.5 MB。
- 恢复到临时目录后，业务文件 sha256 完全一致。

详见 [docs/test-report.md](docs/test-report.md)。

## 兼容性 shim

PoC 中发现：x86_64 `libmount.so.1` 在 Box64 下能读取 `/proc/self/mountinfo`，但返回空 mount table，导致 NAS 自定义卷列表为空。

本项目包含一个小型 x86_64 preload shim，只实现 ABB 枚举挂载点时用到的 libmount 符号。它在本地构建并安装到：

```text
/usr/local/lib/abb-agent-arm64-box64/mount_shim.so
```

这是兼容性 workaround，不是通用 libmount 替代品，也是本项目不建议生产使用的原因之一。

## 发布规则

GitHub Release 只能发布源码。不要附加：

- 生成的 `.deb`
- Synology 官方 zip/deb
- 解包后的 Synology 文件
- NAS 日志
- 凭据或 token

## 法律说明

Synology 和 Active Backup for Business 是 Synology Inc. 的商标或注册商标。

本项目不隶属于 Synology Inc.，也未获得 Synology 官方支持。

本项目不分发 Synology 专有二进制文件。用户必须从 Synology 官方渠道获取相关软件包。

如认为本项目侵犯你的权利，请联系：`github@xyt.email`

