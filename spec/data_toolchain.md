# 📊 量化数据采集管线

> 数据采集脚本在 `collect/` 目录下，供日志模板的"变更记录"和"量化快照"字段使用。

## 数据源

| 数据源 | 用途 | 必需性 | 安装方式 |
|--------|------|:-----:|---------|
| **ActivityWatch** | 时间追踪分类（编码/浏览/终端等） | 可选 | [activitywatch.net](https://activitywatch.net/) 下载安装 |
| **onefetch** | 仓库语言统计、代码行数、作者数 | 可选 | `winget install onefetch` 或加入 PATH |
| **git** | 今日提交数、新增/修改/删除文件 | **必需** | 随 Git 安装自带 |
| **PSReadLine** | 终端命令历史采样（已脱敏） | 可选 | Windows PowerShell 内置 |

## 安装步骤

### 1. ActivityWatch（可选）

从 [activitywatch.net](https://activitywatch.net/) 下载安装包。启动后 `aw-watcher-window` 自动在后台运行。

验证：访问 `http://127.0.0.1:5600` 看是否显示 Web UI。

### 2. onefetch（可选）

```bash
winget install onefetch
# 或从 GitHub Releases 下载 exe 加入 PATH
```

验证：`onefetch --version`

### 3. 运行采集

```powershell
# 当前目录模式（单仓库）
.\collect\collect_daily_data.ps1

# 多仓库模式（需先编辑 $WORKSPACE_ROOTS 变量）
.\collect\collect_daily_data.ps1 -AllRepos

# 预览模式（不输出数据）
.\collect\collect_daily_data.ps1 -DryRun
```

## 输出

JSON 文件自动写入 `<日志根目录>\Josn\daily_data_YYYY-MM-DD_HHmm.json`（默认路径：`E:\AAA.Program\CC\程序员日志\Josn`）。

```json
{
  "date": "2026-07-18",
  "time_tracking": { "coding_minutes": 192, "browsing_minutes": 45, ... },
  "repo_snapshot": { "language": "PowerShell", "lines_of_code": 28450, ... },
  "git_stats": { "commits_today": 7, "files_added": 3, ... }
}
```

## 日志自动融合

数据采集完成后，下次触发 `程序员日志` 时，工作流会自动检测该 JSON 文件是否存在并读取量化字段。无需手动操作。若文件缺失，会询问是否要运行采集脚本。

## 定时自动采集（可选）

```powershell
# 创建定时任务，每日 23:00 自动采集
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File `"$(Get-Location)\collect\collect_daily_data.ps1`""
$trigger = New-ScheduledTaskTrigger -Daily -At 23:00
Register-ScheduledTask -TaskName "DevLogDailyCollect" -Action $action -Trigger $trigger -Force
```
