# 面向生产的测试计划

[English](production-test-plan.md) | 中文

本项目仍是实验性质。是否可进入生产，必须在与目标部署一致的硬件和内核上跑完整矩阵后再判断。

## 发布门禁

除非以下门禁全部通过，否则不要把构建视为生产可用：

- 构建可从已校验 SHA256 的 Synology 官方包复现。
- 软件包可在每个目标发行版上干净安装和卸载。
- `synosnap` DKMS 可构建、加载、卸载，并可在内核升级后重建。
- `abb-box64.service` 可启动、停止、重启，并能处理 daemon fork 行为。
- NAS 注册只使用显式限定范围的测试任务。
- 首次备份、增量备份、中断备份和恢复全部通过。
- 恢复数据按相对路径比较 SHA256，与源数据一致。
- 断电或强制重启后没有遗留 stale snapshot device。
- 日志不包含 NAS 凭据、token、证书材料或私有主机名。

## 构建与安装矩阵

| 项目 | Debian/Ubuntu deb | RPM family rpm |
| --- | --- | --- |
| 构建主机 | Ubuntu 22.04/24.04 ARM64 | Rocky/Alma/Fedora ARM64 |
| 包输入 | 官方 x64 deb zip | 官方 x64 rpm zip |
| 构建命令 | `./scripts/build-deb.sh` | `./scripts/build-rpm.sh` |
| 包输出 | `dist/*_arm64.deb` | `dist/*.aarch64.rpm` |
| 构建工具 | `dpkg-deb`, `unzip`, `gcc-x86-64-linux-gnu` | `rpmbuild`, `rpm2cpio`, `cpio`, `gcc-x86-64-linux-gnu` |
| 内核 headers | `linux-headers-$(uname -r)` | `kernel-devel-$(uname -r)` |
| 运行服务 | systemd | systemd |
| MAC 策略 | AppArmor 如启用 | SELinux 如 enforcing |

每次运行记录：

```bash
uname -a
uname -m
cat /etc/os-release
box64 --version
dkms status synosnap || true
systemctl status abb-box64.service --no-pager || true
```

## 容器或虚拟机策略

容器只用于源码解包、包组装和脚本 lint。容器结果不能作为 DKMS 或备份验证结果，因为容器通常共享宿主机内核，也可能不运行 systemd。

以下内容必须使用一次性 VM 或备用物理机：

- DKMS 构建和加载测试。
- `systemctl start/stop/restart abb-box64.service`。
- NAS 注册。
- 备份、恢复、中断和重启测试。
- RPM 发行版上的 SELinux enforcing 模式测试。

## 备份与恢复矩阵

| 测试 | 必须结果 |
| --- | --- |
| 首次备份 | NAS 显示成功，journal 无 daemon crash |
| 增量备份 | 变更文件被包含，未变更文件仍可恢复 |
| Hash 恢复 | 恢复文件按相对路径与源文件 SHA256 一致 |
| 中断备份 | kill daemon 或断网后，下一次备份可成功 |
| 强制重启 | idle 和 backup 中重启后没有 stale `/dev/synosnap*` |
| NAS 断连 | 临时断网后服务可恢复且无凭据泄漏 |
| Snapshot 清理 | `sbdctl destroy` 或 daemon 清理测试 snapshot |
| 卸载 | 软件包移除会停止服务，且不删除用户/NAS 数据 |

只使用临时测试盘、loop 设备或专用 scratch volume。不要用真实生产根文件系统验证。

## 内核升级测试

对每个目标发行版：

1. 安装软件包并确认 `synosnap` 已加载。
2. 升级到新的受支持内核和匹配 headers。
3. 重启。
4. 确认 DKMS 已重建模块。
5. 确认 `modprobe synosnap` 成功。
6. 重新执行首次备份和增量备份。
7. 恢复并比较 SHA256。

## RPM 专项验证

能构建 `.rpm` 不代表 RPM 兼容已经成立。每个目标 RPM 发行版都要验证：

- 官方 rpm zip 布局仍包含 ABB agent rpm 和 synosnap rpm。
- `rpm2cpio` 解包后文件位于预期路径。
- 生成的 rpm 拥有 `/opt/Synology/ActiveBackupforBusiness`、`/usr/src/synosnap-0.12.10`、`/usr/lib/synosnap`、wrapper 和 service。
- `%post` DKMS 构建在已安装 `kernel-devel` 时成功。
- systemd 能识别 `Type=forking` 和 PID 跟踪。
- SELinux enforcing 不阻止 Box64、ABB、DKMS、`/dev/synosnap*` 或 ABB 日志/socket 路径。
- 卸载会移除 DKMS 注册，但不删除 NAS 端状态。

收集 SELinux denial：

```bash
sudo ausearch -m avc,user_avc -ts recent || true
sudo journalctl -t setroubleshoot --no-pager || true
```

## 证据包

每次测试保留打码证据包：

- 系统信息。
- 包构建日志。
- 安装/移除日志。
- `dkms status` 和 `modinfo synosnap`。
- `systemctl status` 和 `journalctl -u abb-box64.service`。
- 已打码的 NAS 任务名。
- 源和恢复 SHA256 文件。
- `lsblk`、`findmnt` 和测试卷详情。
- SELinux/AppArmor denial 如有。

不要发布生成的软件包、Synology 官方包、解包后的 Synology 文件、NAS 凭据、未打码日志或真实磁盘标识。
