# 数据采集工具链 — 管线阶段

> **所属管线**：Phase 2（执行）→ Phase 3（质检）→ Phase 4（交付）
> **入口条件**：触发"程序员日志"场景（作为步骤 1 [COLLECT] 自动执行）
> **用途**：采集脚本参数、数据源说明和敏感词过滤规则
> **质量门禁**：Qwen + GLM 各自独立审查，均 ≥9.5 方通过

---

## 步骤 1：运行采集脚本

- **动作**：`tools\collect_daily_data.ps1 -AllRepos`
- **验证**：输出 JSON 文件存在且非空
- **状态输出**：`[COLLECT] 采集完成: <输出JSON文件名>`

## 步骤 2：验证采集完整性

- **检查**：采集产出包含 ActivityWatch/onefetch/git log 三个数据源
- **状态输出**：`[COLLECT] 数据源验证: 通过/缺XXX`

## 步骤 3：敏感词过滤

- **动作**：对 JSON 内容按 `tools/sensitive_patterns.json` 规则过滤
- **状态输出**：`[MASK] 敏感词过滤: 通过`

## 采集脚本

`tools\collect_daily_data.ps1`

**参数**：`-DryRun`（仅预览） | `-AllRepos`（遍历 CC/M.Unity/UEStudy）

**输出**：`%USERPROFILE%\.claude\temp\daily_data_YYYYMMDD.json`

**保留**：7 天自动清理

**验证脚本**：`tools\verify_data_tools.ps1`

## 数据源

| 数据源 | 采集方式 | 产出字段 |
|--------|---------|----------|
| ActivityWatch (localhost:5600) | API /buckets/ | 编码/浏览/终端等分类时长 |
| onefetch | `--output json` | 语言分布/代码行数/文件数/作者数 |
| git log | `--after --numstat` | 今日提交数/增减文件数 |
| PSReadLine 历史 | 时间段采样+双过滤 | 已脱敏命令列表 |

## 敏感词过滤

`tools/sensitive_patterns.json` — 白名单优先，黑名单阻断

覆盖：API Key / Token / 密码 / JWT / 环境变量

---
## 质检门禁（Phase 3 — Qwen + GLM 各自独立审查，均≥9.5 方通过）

### 检查项细则

| 检查项 | 具体判定标准 | Qwen 评分 | GLM 评分 |
|--------|------------|:---------:|:--------:|
| 采集已执行 | JSON 文件已生成且非空。未执行 → 扣 5 分 | /10 | /10 |
| 三数据源完整 | ActivityWatch + onefetch + git log 均有数据。缺源 → 扣 3 分 | /10 | /10 |
| 敏感词已过滤 | JSON 内无明文 API Key/Token/密码。发现明文 → 扣 5 分 | /10 | /10 |

### 通过条件

```
Qwen 评分 ≥ 9.5 AND GLM 评分 ≥ 9.5 → [质检] 裁决: 通过
Qwen 评分 < 9.5 OR GLM 评分 < 9.5 → [质检] 裁决: 返工（标注扣分项）
```
