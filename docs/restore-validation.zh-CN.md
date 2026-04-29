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
