# 贡献指南

[English](CONTRIBUTING.md) | 中文

感谢你帮助测试 `abb-agent-arm64-box64`。目前最有价值的贡献是可复现的安装结果、备份/恢复验证记录、发行版兼容性发现，以及范围清晰的小修复。

## 提交 issue 前

不要上传或粘贴：

- Synology 官方 zip/deb/rpm 文件。
- 包含 Synology 二进制文件的本地生成 deb/rpm 包。
- 解包后的 Synology 专有文件。
- NAS 凭据、token、证书、私有主机名或未打码日志。

遇到安装或运行问题时，优先运行只读预检脚本，并在需要时附上打码后的输出：

```bash
./scripts/preflight-check.sh
```

如果问题和软件包安装有关，也可以运行：

```bash
./scripts/verify-install.sh
./scripts/verify-rpm-vm.sh
```

## 什么样的反馈最有用

高质量反馈通常包括：

- 发行版名称和版本。
- 内核版本和架构。
- 软件包类型：DEB 或 RPM。
- Box64 版本和安装方式。
- `synosnap` DKMS 是否构建并加载成功。
- `abb-box64.service` 是否已启用并处于 active。
- 是否测试了 NAS 注册、备份和恢复。
- 已打码的 `journalctl -u abb-box64.service` 输出。
- 必要时提供已打码的 ABB 日志。

## 开发约定

- 不要把生成的软件包、官方下载包、解包后的官方文件或含隐私的日志提交进 git。
- 英文和中文文档要保持含义一致，但不需要逐句直译。
- Pull request 尽量小，每次只解决一个明确问题。
- 不要用单次小范围测试改变项目状态口径。保持 beta 表述，并把详细证据链接到 `docs/test-report.zh-CN.md`。
- 脚本应保持检查逻辑清晰直观。只读验证命令不要隐藏网络访问或包管理器副作用。

## Pull Request 检查项

提交 PR 前：

- 运行 `git status --short --ignored`，确认只有源码和文档变更被跟踪。
- 对修改过的 shell 脚本执行语法检查。
- 运行 `git diff --check`。
- 修改面向用户的文档时，同步更新对应的中文或英文文档。
- 行为有变化时，同步补充验证说明。
