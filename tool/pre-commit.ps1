# pre-commit 钩子:改代码必带文档
# 防止 AI 改完代码忘改文档
# 启用: git config core.hooksPath tool

$ErrorActionPreference = 'Stop'

$repoRoot = (git rev-parse --show-toplevel).Trim()
Set-Location $repoRoot

Write-Host 'pre-commit: check doc sync...' -ForegroundColor Cyan
Write-Host "repo: $repoRoot"

$errors = 0

# 1. 暂存区改的 .dart
$changedDart = git diff --cached --name-only | Where-Object { $_ -match '^lib/.*\.dart$' -and $_ -notmatch '\.g\.dart$' }

# 2. 暂存区改的文档
$changedDocs = git diff --cached --name-only | Where-Object { $_ -match '^(docs/|AGENTS\.md|ROADMAP\.md|README\.md)' }

if ($changedDart) {
    Write-Host 'Changed .dart:' -ForegroundColor Yellow
    $changedDart | Select-Object -First 10 | ForEach-Object { Write-Host "  $_" }
    Write-Host ''

    $changedModules = $changedDart | ForEach-Object { if ($_ -match '^lib/modules/([^/]+)/') { $Matches[1] } } | Sort-Object -Unique
    $changedLayers = $changedDart | ForEach-Object { if ($_ -match '^lib/([^/]+)/') { $Matches[1] } } | Sort-Object -Unique

    Write-Host "Changed module:$changedModules" -ForegroundColor Yellow
    Write-Host "Changed layer:$changedLayers" -ForegroundColor Yellow
    Write-Host ''

    # 3. 改 _core/ → 必须改 docs/ARCHITECTURE.md 或 docs/KNOWLEDGE_GRAPH.md
    if ($changedLayers -contains '_core' -or $changedLayers -contains 'app') {
        if (-not (Test-Path 'docs/ARCHITECTURE.md')) {
            Write-Host 'FAIL: changed lib/_core/ but not docs/ARCHITECTURE.md' -ForegroundColor Red
            $errors++
        }
    }

    # 4. 改 _shared/ → 必须改 docs/BUILDING_BLOCKS.md
    if ($changedLayers -contains '_shared') {
        if (-not (Test-Path 'docs/BUILDING_BLOCKS.md')) {
            Write-Host 'FAIL: changed lib/_shared/ but not docs/BUILDING_BLOCKS.md' -ForegroundColor Red
            $errors++
        }
    }

    # 5. 改 modules/<m>/data/ → 必须改 docs/API.md
    if ($changedDart | Where-Object { $_ -match 'lib/modules/[^/]+/data/' }) {
        if (-not (Test-Path 'docs/API.md')) {
            Write-Host 'FAIL: changed modules/*/data/ but not docs/API.md' -ForegroundColor Red
            $errors++
        }
    }

    # 6. 改 modules/auth/data/ → 必须改 docs/ERROR_HANDLING.md
    if ($changedDart | Where-Object { $_ -match 'lib/modules/auth/data/' }) {
        if (-not (Test-Path 'docs/ERROR_HANDLING.md')) {
            Write-Host 'FAIL: changed modules/auth/data/ but not docs/ERROR_HANDLING.md' -ForegroundColor Red
            $errors++
        }
    }

    # 7. 改 modules/<m>/ → 检查 PAGE_CLASSIFICATION.md 是否需要更新
    if ($changedModules.Count -gt 0) {
        if (-not (Test-Path 'docs/PAGE_CLASSIFICATION.md')) {
            Write-Host 'FAIL: changed modules/ but not docs/PAGE_CLASSIFICATION.md' -ForegroundColor Red
            $errors++
        }
    }
}

# 8. pubspec.yaml 改过 → 必备 REFERENCE.md + LICENSE_INFO.md
if ((git diff --cached --name-only) -contains 'pubspec.yaml') {
    if (-not (Test-Path 'docs/REFERENCE.md')) {
        Write-Host 'FAIL: pubspec.yaml changed but not docs/REFERENCE.md' -ForegroundColor Red
        $errors++
    }
    if (-not (Test-Path 'docs/LICENSE_INFO.md')) {
        Write-Host 'FAIL: pubspec.yaml changed but not docs/LICENSE_INFO.md' -ForegroundColor Red
        $errors++
    }
}

# 9. AGENTS.md / ROADMAP.md 改过 → 必跑 tool/check_official.ps1
if ((git diff --cached --name-only) -contains 'AGENTS.md') {
    Write-Host 'INFO: AGENTS.md changed, run check_official.ps1 manually' -ForegroundColor Yellow
}

Write-Host ''
if ($errors -gt 0) {
    Write-Host "FAIL: $errors violations (code change without doc)" -ForegroundColor Red
    Write-Host "Fix: sync docs or use 'git commit --no-verify'"
    exit 1
}
Write-Host 'OK: doc sync check pass' -ForegroundColor Green