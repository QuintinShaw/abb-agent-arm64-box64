# 恢复校验

[English](restore-validation.md) | 中文

备份成功本身不够。信任任何备份栈之前，必须验证恢复。

推荐最小流程：

1. 创建临时测试卷或测试目录。
2. 写入确定性文件和随机文件。
3. 保存源文件 hash：

   ```bash
   find /path/to/source/data -type f -exec sha256sum {} \; | sort > /tmp/source.sha256
   ```

4. 创建只选择测试范围的 NAS 任务。
5. 执行首次备份。
6. 修改文件并新增文件。
7. 保存变更后 hash：

   ```bash
   find /path/to/source/data -type f -exec sha256sum {} \; | sort > /tmp/source.after.sha256
   ```

8. 执行增量备份。
9. 将最新版本恢复到单独的临时路径。
10. 规范化路径并比较 hash：

   ```bash
   find /tmp/restore/data -type f -exec sha256sum {} \; \
     | sed -E 's#  /tmp/restore/#  #' \
     | sort > /tmp/restored.sha256

   sed -E 's#  /path/to/source/#  #' /tmp/source.after.sha256 \
     | sort > /tmp/source.normalized.sha256

   diff -u /tmp/source.normalized.sha256 /tmp/restored.sha256
   ```

只有 `diff` 退出状态为 0，才认为测试通过。

## 基于克隆的 Restore VM 注意事项

一次性验证时，可以通过复制已测试 VM 的磁盘创建 restore VM。如果复制出的
VM 启动同一个内核，并且已经包含匹配的 DKMS 构建产物，就可以避免重新构建
`synosnap`。

使用这种方式时：

- 复制磁盘前保持源 VM 关机。
- 把克隆出的 VM 视为新的、一次性验证目标。
- 恢复前确认 `modinfo synosnap`、`modprobe synosnap` 和
  `lsmod | grep synosnap`。
- 确认 `abb-box64.service` 为 `enabled` 且 `active`。
- 恢复到单独的临时路径，并比较 hash。
- 不要把克隆 VM 的首次备份当作增量备份验证。除非它已经作为同一个 ABB
  device 拥有有效备份链，否则那只是克隆 VM 自己的首次备份。

如果 ABB daemon 在内核模块加载前启动，请先加载 `synosnap` 再重启服务。打包
的 service 会在启动 daemon 前执行 `modprobe synosnap`，以降低这个风险。
