# dev-log-tool — JIT 路由表配置 V2.2

> 适用于任何 Claude Code 项目的程序员日志归档系统。
> 量级约 30 行核心规则 + JIT 路由表，详细模板按需从 `spec/` 加载。

## 触发词

`程序员日志` `记录今天日志` `日志归档` `dev-log`

## ⚡ JIT 懒加载路由表

| 场景 | 触发条件 | 前置读取 | 文件 |
|------|---------|---------|------|
| 日志归档 | 触发词触发→确认后 | 完整流程 + 8 字段模板 | `spec/log_templates.md` |
| 数据采集 | 用户询问量化数据时 | 采集管线安装指南 | `spec/data_toolchain.md` |

**铁律**：匹配场景时必须先 Read 对应 spec 文件再执行，未读严禁输出。

## 核心规则

- **路径锁定**：日志写入 `<YOUR_LOG_DIR>`（绝对路径，首次用前替换）
- **自动采集**：每次确认后自动运行 `collect/collect_daily_data.ps1`，JSON 输出到 `<日志根目录>\Josn\daily_data_YYYY-MM-DD_HHmm.json`
- **同天检测**：先扫描 `<YOUR_LOG_DIR>` 下是否有今天（`YYYYMMDD`）的日志文件，有则合并追加、无则新建
- **8 字段必填**：日期、会话起止、模型、Token、花费、变更记录、文件状态、量化快照
  - 未知字段填「未记录」，禁止留空
- **同日合并**：同天多条日志合并为一条，内部用 `## 时段N：标题（HH:MM–HH:MM）` 分区
- **密钥打码铁律**：日志中任何 API Key / Token / 密码必须用 `***` 打码
- **提取不等同删除**：仅复制归档，不修改源文件

## 部署

```bash
# JIT 路由表模式（推荐）
cp CLAUDE.template.md <你的项目名>/.claude/CLAUDE.md
cp -r spec/ <你的项目名>/spec/

# 或直接粘贴模式
# 将 CLAUDE_snippet.md 内容追加到 ~/.claude/CLAUDE.md
```

## 数据采集

量化数据采集脚本在 `collect/` 目录下，详情见 `spec/data_toolchain.md`。

---

## 依赖

- **git**（必需）— 提交统计
- **ActivityWatch**（可选）— 时间追踪
- **onefetch**（可选）— 仓库快照
- **Windows PSReadLine**（可选）— 终端历史
