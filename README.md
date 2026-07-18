<p align="center">
  <a href="README_zh.md"><kbd>🇨🇳 中文</kbd></a> · <kbd>🇺🇸 English</kbd>
</p>

<h1 align="center">Dev-Log Tool V2.0</h1>
<p align="center"><b>Cross-workspace developer journal for Claude Code — with quantified data fusion</b></p>

<p align="center">
  <img src="https://img.shields.io/badge/version-2.0-blue" alt="Version">
  <img src="https://img.shields.io/badge/license-MIT-brightgreen" alt="License">
</p>

---

## What It Does

You work across multiple projects. You have deep conversations with Claude Code. When you start a new session, all that context is gone.

**Dev-Log Tool V2.0** solves this: say a trigger word, and your entire day's code changes, conversation highlights, **and quantified data** (time tracking, repo snapshot, git stats, terminal history) are automatically extracted, formatted, and saved to a persistent directory — accessible from any workspace.

## Quick Start

### 1. Add Rules

Copy the contents of `CLAUDE_snippet.md` to the end of `~/.claude/CLAUDE.md`.

### 2. Replace Path

Change `<YOUR_LOG_DIR>` to your actual log directory (absolute path recommended).

### 3. Use It

In Claude Code, say: `程序员日志` or `dev-log`

```
🔔 Journal request detected. Confirm?
> Confirm
```

Done. A new file `01_about_xxx_CC_20260622_1825.md` appears in your log directory.

### 4. (Optional) Enable Quantified Data

Install [ActivityWatch](https://activitywatch.net/) and configure a collection script:
```bash
pip install activitywatch  # or download from official site
# Then configure the script path to tools/collect_daily_data.ps1
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
├── README.md          ← English (you are here)
├── README_zh.md       ← 中文
└── CLAUDE_snippet.md  ← V2.0 rules to paste into your CLAUDE.md
```

## Changelog

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

## License

MIT
