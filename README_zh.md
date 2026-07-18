<p align="center">
  <kbd>🇨🇳 中文</kbd> · <a href="README.md"><kbd>🇺🇸 English</kbd></a>
</p>

<h1 align="center">Dev-Log Tool V2.2</h1>
<p align="center"><b>跨工作区的 Claude Code 开发者日志归档工具 — 含量化数据集成</b></p>

<p align="center">
  <img src="https://img.shields.io/badge/version-2.2-blue" alt="Version">
  <img src="https://img.shields.io/badge/license-MIT-brightgreen" alt="License">
</p>

---

## 它做什么

你在多个项目中工作。你和 Claude Code 进行深度对话。每次开新会话，所有上下文都没了。

**Dev-Log Tool V2.0** 解决这个问题：说一个触发词，你一天的所有代码变更、对话精华、**量化数据**（时间追踪、仓库快照、Git 统计、终端历史）自动提取、格式化、保存到一个持久化目录——从任何工作区都能访问。

## 快速开始

### 方案 A：JIT 路由表模式（推荐）

适合已使用或准备使用 model-federation 架构的项目：

```bash
cp CLAUDE.template.md <你的项目>/.claude/CLAUDE.md
cp -r spec/ <你的项目>/spec/
```

### 方案 B：直接粘贴模式

适合简单项目，无需 spec/ 目录：

1. 将 `CLAUDE_snippet.md` 内容追加到 `~/.claude/CLAUDE.md`
2. 将 `<YOUR_LOG_DIR>` 替换为你的实际日志目录
3. 将 `<YOUR_COLLECT_DIR>` 替换为 collect/ 的实际路径

### 使用

在 Claude Code 中说：`程序员日志` 或 `dev-log`

```
🔔 检测到日志归档请求。是否确认？
> 确认
```

完成。日志目录下会生成 `01_关于xxx的日志_CC_20260622_1825.md`。

### 启用量化数据（可选）

```powershell
# 安装 ActivityWatch（https://activitywatch.net/）
# 确认 onefetch 在 PATH 中
# 然后运行：
.\collect\collect_daily_data.ps1
```

## 功能特性

| 特性 | 说明 |
|------|------|
| 防误触握手 | 先询问确认再执行，不会意外触发 |
| 跨工作区 | 绝对路径，从任何目录都能写入 |
| 自动编号 | 扫描已有文件，自动分配下一个顺延序号 |
| 降噪过滤 | 自动过滤报错和重试过程，仅保留关键 Prompt 和最终方案 |
| **量化数据集成** | ⭐ **V2.0 新增** — 自动嵌入时间分类、仓库快照、Git 统计 |
| **三方变体模板** | ⭐ **V2.0 新增** — 根据量化数据完整性自动选用完整态/部分态/传统态 |
| **密钥遮蔽** | ⭐ **V2.0 新增** — 日志输出时自动打码 API Key 等敏感信息 |
| 折叠排版 | 长回答用 `<details>` 标签包裹，阅读清爽 |

## 文件树

```
dev-log-tool/
├── README.md                     ← English
├── README_zh.md                  ← 中文（你在这里）
├── CLAUDE.template.md            (~50行) JIT 路由表 + 核心规则（V2.2）
├── CLAUDE_snippet.md             V2.2 独立规则片段（直接粘贴到 CLAUDE.md）
├── collect/                      ⬅ V2.2 量化数据采集管线
│   ├── collect_daily_data.ps1    通用数据采集脚本（V2.1 起；V2.2 新增 HHmm+Prev 旋转）
│   ├── activity_categories.json  ActivityWatch 窗口分类映射（静态配置）
│   ├── sensitive_patterns.json   终端历史敏感词过滤规则（静态配置）
│   └── daily_data_schema.json    JSON 输出 Schema（静态配置）
└── spec/                         ⬅ V2.2 模块化规范，JIT 路由表按需加载
    ├── log_templates.md          V2.2 日志模板 + 8 字段必填规则
    └── data_toolchain.md         V2.2 量化数据管线安装与使用指南
```

## 更新日志

### V2.2 (2026-07-18)
- **一步到位自动采集**：每次「程序员日志」自动运行 `collect_daily_data.ps1`，不再询问是否采集
- **HHmm JSON 命名**：JSON 文件名从 `daily_data_YYYY-MM-DD.json` → `daily_data_YYYY-MM-DD_HHmm.json`
- **Prev 备份机制**：同天旧 JSON 自动移入 `Josn\Prev\` 目录，保留 7 天
- **同天日志检测合并**：先扫描日志目录是否有今天文件，有则合并追加、无则新建
- **四方质检验证**：QwenMax + GLM-4.5-Air + Gemini 3.5 Flash + Claude 全线通过（GLM 9.8/10）
- **安全补漏**：新增 `.gitignore`（忽略 `模型协同日志/` 本地审计目录）
- **UTF-8 BOM 编码**：修复 PowerShell 5.1 中文乱码问题

### V2.1 (2026-07-18)
- **JIT 路由表架构**：新增 `CLAUDE.template.md`（~40 行） + `spec/` 目录模块化
- **数据采集管线**：新增 `collect/` 目录，包含通用采集脚本 + 3 个配置文件
- **双模部署**：支持 JIT 路由表模式（适合 model-federation 用户）和直接粘贴模式
- **spec/data_toolchain.md**：量化数据管线的完整安装指南 + Windows 定时任务示例
- **[联动] model-federation**：两仓库 README 互相引用，配套使用

### V2.0 (2026-07-18)
- **量化数据集成**：ActivityWatch 时间分类 + onefetch 仓库快照 + git 提交统计 + 终端历史
- **三方变体模板**：完整态（量化数据完整）/ 部分态（部分数据）/ 传统态（无数据）自动选择
- **密钥遮蔽铁律**：日志中 API Key / Token / 密码自动 `***` 打码
- **8 字段强制头**：顺序固定，未知填「未记录」
- **同日合并**：同一天多条日志自动合并为一条，内部按时间段分区展示
- **HHmm 强制**：文件名时间戳必须 24 小时制数字

### V1.0 (2026-06-22)
- 初始版本：触发词 → 确认 → 提取 → 日志文件
- 防误触握手、跨工作区、自动编号、降噪过滤、折叠排版

## 配套项目

量化数据采集管线与 [model-federation](https://github.com/SpiralQWQ/model-federation)（[Gitee 镜像](https://gitee.com/Spiral_QWQ/model-federation)）配套使用。后者提供多模型路由、通行证锁和 spec/ 架构规范。

## 开源协议

MIT
