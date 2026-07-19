<p align="center">
  <a href="README_zh.md"><kbd>🇨🇳 中文</kbd></a> · <kbd>🇺🇸 English</kbd>
</p>

<h1 align="center">Dev-Log Tool V2.3</h1>
<p align="center"><b>Cross-workspace developer journal for Claude Code — with quantified data fusion</b></p>

<p align="center">
  <img src="https://img.shields.io/badge/version-2.3-blue" alt="Version">
  <img src="https://img.shields.io/badge/license-MIT-brightgreen" alt="License">
</p>

---

## What It Does

You work across multiple projects. You have deep conversations with Claude Code. When you start a new session, all that context is gone.

**Dev-Log Tool V2.0** solves this: say a trigger word, and your entire day's code changes, conversation highlights, **and quantified data** (time tracking, repo snapshot, git stats, terminal history) are automatically extracted, formatted, and saved to a persistent directory — accessible from any workspace.

## Quick Start

### Option A: JIT Routing Table Mode (Recommended)

For projects already using or planning to use the model-federation architecture:

```bash
cp CLAUDE.template.md <your-project>/.claude/CLAUDE.md
cp -r spec/ <your-project>/spec/
```

### Option B: Direct Paste Mode

For simple projects without spec/ directory:

1. Append `CLAUDE_snippet.md` contents to `~/.claude/CLAUDE.md`
2. Replace `<YOUR_LOG_DIR>` with your actual log directory
3. Replace `<YOUR_COLLECT_DIR>` with the actual path to `collect/`

### Use It

In Claude Code, say: `程序员日志` or `dev-log`

```
🔔 Journal request detected. Confirm?
> Confirm
```

Done. A new file `01_about_xxx_CC_20260622_1825.md` appears in your log directory.

### Enable Quantified Data (Optional)

```powershell
# Install ActivityWatch (https://activitywatch.net/)
# Make sure onefetch is in PATH
# Then run:
.\collect\collect_daily_data.ps1
```

## Features

| Feature | Detail |
|---------|---------|
| Handshake Protocol | Prevents accidental triggers |
| Cross-workspace | Absolute path — works from any directory |
| Auto-numbering | Scans existing logs, assigns next sequential number |
| Noise Filter | Strips errors and retries, keeps only key prompts + solutions |
| **Quantified Data** | ⭐ **V2.0 NEW** — auto-embed time tracking, repo stats, git changes |
| **3 Template Variants** | ⭐ **V2.0 NEW** — full/partial/legacy based on data availability |
| **Key Masking** | ⭐ **V2.0 NEW** — auto-redact API Keys, Tokens, passwords in logs |
| Collapsible Output | Long answers wrapped in `<details>` for clean reading |

## File Tree

```
dev-log-tool/
├── README.md                     ← English (you are here)
├── README_zh.md                  ← 中文
├── CLAUDE.template.md            (~50 lines) JIT routing table + core rules (V2.2)
├── CLAUDE_snippet.md             V2.2 standalone rules (direct paste into CLAUDE.md)
├── collect/                      ⬅ V2.2 Quantified data collection pipeline
│   ├── collect_daily_data.ps1    Universal collection script (since V2.1; HHmm+Prev in V2.2)
│   ├── activity_categories.json  ActivityWatch window title mapping (static config)
│   ├── sensitive_patterns.json   Terminal history filter rules (static config)
│   └── daily_data_schema.json    JSON output schema (static config)
└── spec/                         ⬅ V2.2 Modular specs, loaded by JIT routing table
    ├── log_templates.md          V2.2 log templates + 8-field mandatory header
    └── data_toolchain.md         V2.2 quantified data pipeline installation guide
```

## Changelog

### V2.3 (2026-07-19)
- **spec/data_toolchain.md pipelined**: Descriptive → 3-step executable pipeline with quality gate (≥9.5)
- **spec/log_templates.md pre-read fix**: `json_archive` → `data_toolchain` (resolved missing file reference)
- **CLAUDE_snippet.md cross-repo pointer**: Added billing_rules.md reference (points to CC main / model-federation)
- **[Link] model-federation**: Both repos now share unified Phase 2→3→4 pipeline format

### V2.2 (2026-07-18)
- **One-shot auto collect**: `程序员日志` trigger auto-runs `collect_daily_data.ps1` every time
- **HHmm JSON naming**: `daily_data_YYYY-MM-DD.json` → `daily_data_YYYY-MM-DD_HHmm.json`
- **Prev backup**: Old same-day JSON auto-moved to `Josn\Prev\` dir, 7-day retention
- **Same-day log merge**: Scans log dir for today's file — merges if exists, creates if not
- **Four-way quality check**: QwenMax + GLM-4.5-Air + Gemini 3.5 Flash + Claude all passed (GLM 9.8/10)
- **Security patch**: Added `.gitignore` (ignores `模型协同日志/` local audit dir)
- **UTF-8 BOM fix**: Resolved PowerShell 5.1 Chinese character encoding

### V2.1 (2026-07-18)
- **JIT routing table architecture**: New `CLAUDE.template.md` (~40 lines) + modular `spec/` directory
- **Data pipeline**: New `collect/` directory with generic script + 3 config files
- **Dual deployment**: JIT routing table mode (model-federation compatible) and direct paste mode
- **spec/data_toolchain.md**: Full installation guide for ActivityWatch, onefetch, and Windows scheduled tasks
- **[Link] model-federation**: README cross-references between the two companion repos

### V2.0 (2026-07-18)
- **Quantified data fusion**: ActivityWatch time categories + onefetch repo snapshot + git commit stats + terminal history
- **3 template variants**: Full (all data available) / Partial (some data) / Legacy (no data) — auto-select
- **Key masking mandate**: API Keys / Tokens / passwords auto-redacted with `***`
- **8-field mandatory header**: Fixed order, unknown fields use "N/A"
- **Same-day merge**: Multiple logs on same day auto-merged with time-section headers
- **24h timestamp enforced**: Filename timestamps must use HHmm 24-hour format

### V1.0 (2026-06-22)
- Initial release: trigger → confirm → extract → log file
- Handshake protocol, cross-workspace, auto-numbering, noise filter, collapsible output

## Companion Project

The quantified data pipeline complements [model-federation](https://github.com/SpiralQWQ/model-federation) ([Gitee mirror](https://gitee.com/Spiral_QWQ/model-federation)), which provides multi-model routing, ticket lock, and the spec/ architecture.

## License

MIT
