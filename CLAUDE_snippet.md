# CC 程序员日志配置（dev-log-tool 同源）

> **本文件仅包含程序员日志相关规则。其他规则见 CC 项目 `CLAUDE.md`。**
>
> **Gatekeeper**：详见 `_pipeline_architecture.md`
> Phase1 必须先输出 `[JIT] Read 对应spec... Done.` + `[JIT] 规则摘要`，未完成禁止进入 Phase2。

## 程序员日志（管线执行，禁止跳步）

> **JIT 前置**：触发后先输出 `[JIT] Read spec/log_templates.md + spec/data_toolchain.md... Done.`
> Token 计费格式参见主项目 CC 的 `billing_rules.md`（含会话累计表）
> 然后按以下顺序执行，每步输出状态块：

1. **[COLLECT]** `tools\collect_daily_data.ps1 -AllRepos`（自动前置，无需单独说"采集"）
2. **[ARCHIVE]** 新版入 `程序员日志\Josn\`，同天旧版移入 `Josn\Prev\`（自动前置）
3. **[HEADER]** 8 字段头部（日期/会话起止/模型/Token/花费/变更记录/文件状态/量化快照）
   - 时间分类全部展开：编码/浏览/通信/其他/终端/文档/设计（禁止合并）
4. **[MASK]** 密钥遮蔽：API Key/Token/密码必须 `***`

**兜底**：连续两次跳步 → 用户手动跑采集，AI 只负责填充日志正文。

## 相关 spec 索引

| 模块 | 位置 |
|------|------|
| 日志模板 | `spec/log_templates.md` |
| JSON 存档与采集 | `spec/data_toolchain.md` |
| 数据采集工具 | `tools/collect_daily_data.ps1` |

## JIT 路由（日志相关）

| 场景 | 前置读取 |
|------|---------|
| 程序员日志 | `spec/log_templates.md` + `spec/data_toolchain.md` |
| 数据采集 | `spec/data_toolchain.md` |
| JSON 存档 | `spec/data_toolchain.md` |

## 日志命名规范

- `NN_关于<概要>的日志_<工作区>_YYYYMMDD_HHmm.md`
- 同天多条日志合并为一条，用 `## 时段N：标题（HH:MM–HH:MM）` 分区

## Git

远程 `https://github.com/SpiralQWQ/Openl.git` · 默认 `master` · `http.postBuffer 524288000`
