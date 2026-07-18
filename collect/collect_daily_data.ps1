<#
.SYNOPSIS
    采集今日量化数据：ActivityWatch 时间追踪 + onefetch 仓库快照 + git 提交统计 + 终端历史
.DESCRIPTION
    从三个数据源采集数据，脱敏聚合后输出 JSON，供程序员日志模板使用。
    幂等设计：每次运行覆盖 daily_data.json，保留前一版本为 daily_data_prev.json。
    📦 通用版 —— 适用于任何 Claude Code 项目，只需修改 $WORKSPACE_ROOTS 为你的工作区路径。
.NOTES
    版本:   v1.0 (通用版)
    依赖:   ActivityWatch（可选）、onefetch（可选）、git
    输出:   %USERPROFILE%\.claude\temp\daily_data_YYYYMMDD.json
.PARAMETER DryRun
    仅预览采集范围，不输出真实数据
.PARAMETER AllRepos
    多仓库模式：遍历 $WORKSPACE_ROOTS 中所有 git 仓库
#>
[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$AllRepos
)

# ═══════════════════════════════════════════════════════════
# 用 户 配 置 区 —— 按你的项目修改
# ═══════════════════════════════════════════════════════════

# 多仓库模式（ -AllRepos ）时遍历的工作区根目录
# 修改为你的实际项目路径，或保持空数组仅用单仓库模式
$WORKSPACE_ROOTS = @()

# ═══════════════════════════════════════════════════════════
# 内 部 配 置 （通常无需修改）
# ═══════════════════════════════════════════════════════════

$today      = (Get-Date).ToString("yyyy-MM-dd")
$outputDir  = "$env:USERPROFILE\.claude\temp"
$configDir  = Split-Path -Parent $PSCommandPath

$categoriesPath  = "$configDir\activity_categories.json"
$sensitivePath   = "$configDir\sensitive_patterns.json"
$schemaPath      = "$configDir\daily_data_schema.json"
$auditLogPath    = "$outputDir\collect_audit.log"
$outputPath      = "$outputDir\daily_data_$today.json"
$outputPrevPath  = "$outputDir\daily_data_prev.json"

# ─── 辅助函数 ──────────────────────────────────────────

function Write-Audit {
    param([string]$Message)
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
    Add-Content -Path $auditLogPath -Value $line -Encoding utf8
}

function Get-CategoryMap {
    $raw = Get-Content $categoriesPath -Raw -Encoding utf8 | ConvertFrom-Json
    $map = @{}
    $raw.categories | ForEach-Object { $map[$_.name] = @($_.match) }

    $regexRules = @()
    if ($raw.title_regex_rules) {
        $raw.title_regex_rules | ForEach-Object {
            $regexRules += @{ pattern = $_.pattern; category = $_.category }
        }
    }
    return @{ keywords = $map; regex_rules = $regexRules }
}

function Get-SensitivePatterns {
    $raw = Get-Content $sensitivePath -Raw -Encoding utf8 | ConvertFrom-Json
    return @{
        whitelist = @($raw.whitelist_prefixes)
        blacklist = @($raw.blacklist_patterns)
    }
}

# ─── 1. ActivityWatch 时间追踪 ────────────────────────

function Get-ActivityWatchData {
    param([switch]$DryRun)
    Write-Host "[1/4] ActivityWatch 时间追踪 ... " -NoNewline

    if ($DryRun) {
        Write-Host "PREVIEW (跳过)" -ForegroundColor Yellow
        return $null
    }

    try {
        $bucketsUrl  = "http://127.0.0.1:5600/api/0/buckets/"
        $buckets = Invoke-RestMethod -Uri $bucketsUrl -TimeoutSec 5 -ErrorAction Stop

        $windowBucket = $buckets.PSObject.Properties |
            Where-Object { $_.Name -like "aw-watcher-window_*" } |
            Select-Object -First 1

        if (-not $windowBucket) {
            Write-Host "MISS (no window bucket)" -ForegroundColor Red
            return $null
        }

        $eventsUrl = "http://127.0.0.1:5600/api/0/buckets/$($windowBucket.Name)/events"
        $startTime = (Get-Date).Date.ToString("yyyy-MM-dd")
        $events = Invoke-RestMethod -Uri "$($eventsUrl)?start=$startTime" -TimeoutSec 10 -ErrorAction Stop

        if (-not $events -or $events.Count -eq 0) {
            Write-Host "OK (0 events today)" -ForegroundColor Green
            return @{ coding_minutes=0; browsing_minutes=0; terminal_minutes=0; communication_minutes=0; document_minutes=0; design_minutes=0; music_minutes=0; other_minutes=0; total_active_minutes=0; overlap_detected=$false }
        }

        $catData = Get-CategoryMap
        $catMap = $catData.keywords
        $regexRules = $catData.regex_rules
        $catTimes = @{ "coding"=0; "browsing"=0; "terminal"=0; "communication"=0; "document"=0; "design"=0; "music"=0; "other"=0 }

        foreach ($evt in $events) {
            $dur = if ($evt.duration -and $evt.duration -gt 0) { $evt.duration } else { 0 }
            $title = if ($evt.data -and $evt.data.title) { $evt.data.title } else { "" }
            $app = if ($evt.data -and $evt.data.app) { $evt.data.app } else { "" }
            $matchText = "$title $app"

            $matched = $false

            # pass 1: regex rules (higher priority)
            foreach ($rule in $regexRules) {
                if ($matchText -match $rule.pattern) {
                    $catTimes[$rule.category] += $dur
                    $matched = $true
                    break
                }
            }
            if ($matched) { continue }

            # pass 2: keyword matching
            foreach ($cat in $catTimes.Keys) {
                $keywords = @($catMap[$cat])
                foreach ($kw in $keywords) {
                    if ($kw -eq "*") { continue }
                    if ($matchText -match [regex]::Escape($kw)) {
                        $catTimes[$cat] += $dur
                        $matched = $true
                        break
                    }
                }
                if ($matched) { break }
            }
            if (-not $matched) { $catTimes["other"] += $dur }
        }

        $total = ($catTimes.Values | Measure-Object -Sum).Sum
        $overlap = $false
        for ($i = 1; $i -lt $events.Count; $i++) {
            $prevEnd = if ($events[$i-1].timestamp) { [datetime]$events[$i-1].timestamp } else { [datetime]::MinValue }
            $currStart = if ($events[$i].timestamp) { [datetime]$events[$i].timestamp } else { [datetime]::MaxValue }
            $prevDur = if ($events[$i-1].duration) { $events[$i-1].duration } else { 0 }
            if ($prevEnd.AddSeconds($prevDur) -gt $currStart) { $overlap = $true; break }
        }

        Write-Host "OK ($([math]::Round($total/60))min)" -ForegroundColor Green
        Write-Audit "ActivityWatch: $($events.Count) events, $([math]::Round($total/60))min total"

        return @{
            coding_minutes          = [math]::Round($catTimes["coding"] / 60)
            browsing_minutes        = [math]::Round($catTimes["browsing"] / 60)
            terminal_minutes        = [math]::Round($catTimes["terminal"] / 60)
            communication_minutes   = [math]::Round($catTimes["communication"] / 60)
            document_minutes        = [math]::Round($catTimes["document"] / 60)
            design_minutes          = [math]::Round($catTimes["design"] / 60)
            music_minutes           = [math]::Round($catTimes["music"] / 60)
            other_minutes           = [math]::Round($catTimes["other"] / 60)
            total_active_minutes    = [math]::Round($total / 60)
            overlap_detected        = $overlap
        }
    }
    catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
        Write-Audit "ActivityWatch ERROR: $_"
        return $null
    }
}

# ─── 2. onefetch 仓库快照 ────────────────────────────

function Get-OnefetchSnapshot {
    param([switch]$DryRun)
    Write-Host "[2/4] onefetch 仓库快照 ... " -NoNewline

    if ($DryRun) {
        Write-Host "PREVIEW (跳过)" -ForegroundColor Yellow
        return $null
    }

    try {
        # 优先从 PATH 查找 onefetch，若不存在则跳过
        $exe = (Get-Command onefetch -ErrorAction SilentlyContinue).Source
        if (-not $exe) { Write-Host "MISS (not installed)" -ForegroundColor Red; return $null }

        $gitRemote = git remote -v 2>$null
        if (-not $gitRemote) {
            Write-Host "SKIP (no git remote)" -ForegroundColor Yellow
            return $null
        }

        $jsonText = & $exe --output json 2>$null
        if (-not $jsonText) { Write-Host "MISS (no output)" -ForegroundColor Red; return $null }

        $parsed = $jsonText | ConvertFrom-Json

        $langInfo   = $parsed.infoFields | Where-Object { $null -ne $_.LanguagesInfo } | Select-Object -First 1
        $locInfo    = $parsed.infoFields | Where-Object { $null -ne $_.LocInfo } | Select-Object -First 1
        $sizeInfo   = $parsed.infoFields | Where-Object { $null -ne $_.SizeInfo } | Select-Object -First 1
        $authorInfo = $parsed.infoFields | Where-Object { $null -ne $_.AuthorsInfo } | Select-Object -First 1

        $languages = if ($langInfo) { $langInfo.LanguagesInfo.languagesWithPercentage } else { @() }
        $topLang = if ($languages.Count -gt 0) {
            ($languages | Sort-Object -Property percentage -Descending | Select-Object -First 1).language
        } else { $null }

        $result = @{
            language      = $topLang
            lines_of_code = if ($locInfo) { $locInfo.LocInfo.linesOfCode } else { $null }
            files_count   = if ($sizeInfo) { $sizeInfo.SizeInfo.fileCount } else { $null }
            authors_count = if ($authorInfo) { @($authorInfo.AuthorsInfo.authors).Count } else { 0 }
        }

        Write-Host "OK ($($result.language) $($result.lines_of_code)行)" -ForegroundColor Green
        Write-Audit "onefetch: $($result.language) $($result.lines_of_code) lines"
        return $result
    }
    catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
        Write-Audit "onefetch ERROR: $_"
        return $null
    }
}

# ─── 3. Git 提交统计 ──────────────────────────────────

function Get-GitStats {
    param([switch]$DryRun, [switch]$AllRepos)
    Write-Host "[3/4] Git 提交统计 ... " -NoNewline

    if ($DryRun) {
        Write-Host "PREVIEW (跳过)" -ForegroundColor Yellow
        return $null
    }

    $reposToCheck = if ($AllRepos) { $WORKSPACE_ROOTS } else { @((Get-Location).Path) }
    if ($reposToCheck.Count -eq 0) { $reposToCheck = @((Get-Location).Path) }

    $merged = @{ commits_today=0; files_added=0; files_modified=0; files_deleted=0 }

    foreach ($repo in $reposToCheck) {
        if (-not (Test-Path "$repo\.git")) { continue }
        try {
            Push-Location $repo
            $since = (Get-Date -Format "yyyy-MM-dd 00:00:00")
            $numstat = git log --after="$since" --numstat --format="%H" 2>$null
            $commits = git log --after="$since" --oneline 2>$null | Measure-Object -Line

            if ($commits -and $commits.Lines -gt 0) {
                $merged.commits_today += $commits.Lines
                foreach ($line in ($numstat | Where-Object { $_ -match "^\d+\s+\d+\s+" })) {
                    $parts = $line -split "\s+"
                    $added = [int]$parts[0]
                    $deleted = [int]$parts[1]
                    if ($added -gt 0 -and $deleted -eq 0) { $merged.files_added += 1 }
                    elseif ($added -gt 0) { $merged.files_modified += 1 }
                    else { $merged.files_deleted += 1 }
                }
            }
            Pop-Location
        }
        catch {
            Write-Audit "git stats ERROR in $repo : $_"
            Pop-Location
        }
    }

    $allReposLabel = if ($AllRepos) { " ($($reposToCheck.Count) repos)" } else { "" }
    Write-Host "OK ($($merged.commits_today) commits$allReposLabel)" -ForegroundColor Green
    Write-Audit "git stats: $($merged.commits_today) commits$allReposLabel"
    return $merged
}

# ─── 4. 终端历史采样 ──────────────────────────────────

function Get-TerminalHistory {
    param([switch]$DryRun)
    Write-Host "[4/4] 终端历史采样 ... " -NoNewline

    if ($DryRun) {
        Write-Host "PREVIEW (跳过)" -ForegroundColor Yellow
        return $null
    }

    $historyPath = "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
    if (-not (Test-Path $historyPath)) {
        Write-Host "MISS (no history file)" -ForegroundColor Yellow
        return @{ sampled=@(); warning="未找到 PSReadLine 历史文件" }
    }

    try {
        $patterns = Get-SensitivePatterns
        $whitelist = $patterns.whitelist
        $blacklist = $patterns.blacklist

        $rawLines = Get-Content $historyPath -Encoding utf8
        $totalLines = $rawLines.Count
        if ($totalLines -eq 0) { Write-Host "OK (empty)" -ForegroundColor Green; return @{ sampled=@(); warning=$null } }

        $recentLines = $rawLines[-1440..-1]
        $samples = @()
        $step = 30
        $linesPerStep = 5
        for ($offset = 0; $offset -lt 1440; $offset += $step) {
            $start = $offset
            $end = [Math]::Min($offset + $linesPerStep - 1, $recentLines.Count - 1)
            for ($i = $start; $i -le $end; $i++) {
                $line = $recentLines[$i].Trim()
                if ([string]::IsNullOrEmpty($line)) { continue }
                $samples += $line
            }
        }

        $samples = $samples | Select-Object -Unique

        $filtered = @()
        foreach ($line in $samples) {
            $firstWord = ($line -split "\s+")[0].ToLower()
            $isWhitelisted = $false
            foreach ($prefix in $whitelist) {
                if ($firstWord -eq $prefix.ToLower()) { $isWhitelisted = $true; break }
            }
            if ($isWhitelisted) { $filtered += $line; continue }

            $isBlocked = $false
            foreach ($rule in $blacklist) {
                if ($line -match $rule.regex) { $isBlocked = $true; break }
            }
            if (-not $isBlocked) { $filtered += $line }
        }

        if ($filtered.Count -gt 50) { $filtered = $filtered[0..49] }

        Write-Host "OK ($($filtered.Count) samples)" -ForegroundColor Green
        Write-Audit "terminal history: $($filtered.Count) samples after filter"

        return @{
            sampled = $filtered
            warning = "终端历史经过敏感词过滤，仍可能存在残余敏感信息。建议定期检查 PSReadLine 历史文件。"
        }
    }
    catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
        Write-Audit "terminal history ERROR: $_"
        return @{ sampled=@(); warning="终端历史采集失败: $_" }
    }
}

# ─── 5. 聚合输出 ─────────────────────────────────────

function Out-DailyData {
    param(
        $TimeTracking, $RepoSnapshot, $GitStats, $TerminalHistory,
        [switch]$DryRun
    )

    if ($DryRun) {
        Write-Host "`n=== DryRun 预览 ===" -ForegroundColor Cyan
        Write-Host "输出路径: $outputPath"
        if ($AllRepos) { Write-Host "模式: 多仓库 ($($WORKSPACE_ROOTS.Count) 个工作区)" -ForegroundColor Yellow }
        else { Write-Host "模式: 单仓库 (当前目录)" }
        Write-Host "`n[数据源状态]"
        Write-Host "  ActivityWatch: $(if ($TimeTracking) { '可用' } else { '不可用/跳过' })"
        Write-Host "  onefetch:      $(if ($RepoSnapshot) { '可用' } else { '不可用/跳过' })"
        Write-Host "  git log:       $(if ($GitStats) { '可用' } else { '不可用/跳过' })"
        Write-Host "  终端历史:      $(if ($TerminalHistory) { '可用' } else { '不可用/跳过' })"
        Write-Host "`nDryRun 结束。未写入任何文件。" -ForegroundColor Green
        return
    }

    $qualityWarning = $false
    if ($TimeTracking -and $GitStats) {
        if ($TimeTracking.total_active_minutes -gt 0 -and $GitStats.commits_today -eq 0) {
            $qualityWarning = $true
        }
    }

    $data = @{
        date = $today
        time_tracking = $TimeTracking
        repo_snapshot = $RepoSnapshot
        git_stats = $GitStats
        terminal_history_sampled = if ($TerminalHistory) { $TerminalHistory.sampled } else { $null }
        terminal_warning = if ($TerminalHistory) { $TerminalHistory.warning } else { $null }
        quality_warning = $qualityWarning
        error = $null
    }

    if (-not (Test-Path $outputDir)) { New-Item -ItemType Directory -Path $outputDir -Force | Out-Null }

    if (Test-Path $outputPath) {
        Copy-Item $outputPath $outputPrevPath -Force
        Write-Audit "rotated previous output to $outputPrevPath"
    }

    $json = $data | ConvertTo-Json -Depth 10
    $json | Out-File -FilePath $outputPath -Encoding utf8

    Write-Host "`n✓ 数据已写入: $outputPath" -ForegroundColor Green
    Write-Audit "output written: $outputPath"

    Get-ChildItem "$outputDir\daily_data_*.json" -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) -and $_.Name -ne "daily_data_prev.json" } |
        ForEach-Object { Remove-Item $_.FullName -Force; Write-Audit "cleaned up old: $($_.Name)" }
}

# ─── 主流程 ───────────────────────────────────────────

Write-Host "=== 程序员日志数据采集 ===" -ForegroundColor Cyan
Write-Host "日期: $today`n"

if (-not (Test-Path $outputDir)) { New-Item -ItemType Directory -Path $outputDir -Force | Out-Null }

$awData    = Get-ActivityWatchData -DryRun:$DryRun
$repoSnap  = Get-OnefetchSnapshot -DryRun:$DryRun
$gitStats  = Get-GitStats -DryRun:$DryRun -AllRepos:$AllRepos
$termHist  = Get-TerminalHistory -DryRun:$DryRun

Write-Host ""
Out-DailyData -TimeTracking $awData -RepoSnapshot $repoSnap -GitStats $gitStats -TerminalHistory $termHist -DryRun:$DryRun

if (-not $DryRun) {
    Write-Host "`n=== 采集完成 ===" -ForegroundColor Cyan
    Write-Host "审计日志: $auditLogPath"
}
