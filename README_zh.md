<p align="center">
  <kbd>🇨🇳 中文</kbd> · <a href="README.md"><kbd>🇺🇸 English</kbd></a>
</p>

<h1 align="center">Dev-Log Tool V2.0</h1>
<p align="center"><b>跨工作区的 Claude Code 开发者日志归档工具 — 含量化数据集成</b></p>

<p align="center">
  <img src="https://img.shields.io/badge/version-2.0-blue" alt="Version">
  <img src="https://img.shields.io/badge/license-MIT-brightgreen" alt="License">
</p>

---

## 它做什么

你在多个项目中工作。你和 Claude Code 进行深度对话。每次开新会话，所有上下文都没了。

**Dev-Log Tool V2.0** 解决这个问题：说一个触发词，你一天的所有代码变更、对话精华、**量化数据**（时间追踪、仓库快照、Git 统计、终端历史）自动提取、格式化、保存到一个持久化目录——从任何工作区都能访问。

## 快速开始

### 第一步：添加规则

将 `CLAUDE_snippet.md` 的内容复制到 `~/.claude/CLAUDE.md` 末尾。

### 第二步：替换路径

将 `<YOUR_LOG_DIR>` 替换为你的实际日志目录（建议使用绝对路径）。

### 第三步：使用

在 Claude Code 中说：`程序员日志` 或 `dev-log`

```
🔔 检测到日志归档请求。是否确认？
> 确认
```

完成。你的日志目录下会生成 `01_关于xxx的日志_CC_20260622_1825.md`。

### 第四步（可选）：启用量化数据

安装 [ActivityWatch](https://activitywatch.net/) 后运行数据采集脚本：
```bash
pip install activitywatch  # 或从官网下载
# 然后配置采集脚本路径到 tools/collect_daily_data.ps1
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
├── README.md          ← English
├── README_zh.md       ← 中文（你在这里）
└── CLAUDE_snippet.md  ← V2.0 规则片段（粘贴到你的 CLAUDE.md）
```

## 更新日志

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

## 开源协议

MIT
