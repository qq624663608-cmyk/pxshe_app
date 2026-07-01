# 官方优先检查(原 .sh,转 .ps1)
# AGENTS §52
chcp 65001 > $null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot\..

$errors = 0

Write-Host '--- Official first check ---' -ForegroundColor Cyan

# 1. pubspec.yaml 解析
if (-not (Test-Path 'pubspec.yaml')) {
    Write-Host 'WARN: pubspec.yaml missing, skip' -ForegroundColor Yellow
    exit 0
}

$packages = @()
$inDeps = $false
foreach ($line in Get-Content 'pubspec.yaml') {
    if ($line -match '^dependencies:') { $inDeps = $true; continue }
    if ($line -match '^dev_dependencies:') { $inDeps = $false }
    if ($inDeps -and $line -match '^[a-z_]+:') {
        $packages += ($line -split ':')[0]
    }
}

Write-Host "Packages: $($packages -join ', ')"
Write-Host ''

# 2. 禁止包检查 (pxshe_app 用 BLoC 栈, 不用 Riverpod)
$forbidden = @(
    'mobx',
    'riverpod',
    'flutter_riverpod',
    'provider',
    'get_it_mixin',
    'auto_route',
    'sentry_flutter',
    'firebase_core',
    'firebase_crashlytics',
    'firebase_analytics',
    'mockito',
    'shared_preferences',
    'hive'  # 用 hive_ce 替代
)
$pubspec = Get-Content 'pubspec.yaml' -Raw
Write-Host 'Forbidden packages:'
foreach ($pkg in $forbidden) {
    if ($pubspec -match "^  ${pkg}:") {
        Write-Host "FAIL: $pkg forbidden" -ForegroundColor Red
        $errors++
    }
}
if ($errors -eq 0) { Write-Host 'OK: no forbidden packages' -ForegroundColor Green }

# 3. Flutter @Deprecated API
$deprecated = Select-String -Path 'lib/**/*.dart' -Pattern 'withOpacity|WillPopScope|MaterialApp\([^)]*useMaterial3:\s*false' -ErrorAction SilentlyContinue
if ($deprecated) {
    Write-Host ''
    Write-Host 'FAIL: deprecated API:' -ForegroundColor Red
    $errors++
} else {
    Write-Host ''
    Write-Host 'OK: no deprecated API' -ForegroundColor Green
}

# 4. ADR 编号连续
$adrFiles = Get-ChildItem -Path 'docs/ADR' -Filter '*.md' -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch '^0000-' }
$adrCount = $adrFiles.Count
if ($adrCount -gt 0) {
    Write-Host ''
    Write-Host "ADR count: $adrCount"
    for ($i = 1; $i -le $adrCount; $i++) {
        $num = '{0:D4}' -f $i
        $found = $adrFiles | Where-Object { $_.Name -like "${num}-*" }
        if (-not $found) {
            Write-Host "FAIL: missing ADR-${num}" -ForegroundColor Red
            $errors++
        }
    }
}

# 5. AGENTS.md 必填
Write-Host ''
if (-not (Test-Path 'AGENTS.md')) {
    Write-Host 'FAIL: AGENTS.md missing' -ForegroundColor Red
    $errors++
} else {
    $agents = Get-Content 'AGENTS.md' -Raw
    if ($agents -notmatch '设计初心') {
        Write-Host 'FAIL: AGENTS.md missing design intent' -ForegroundColor Red
        $errors++
    } else { Write-Host 'OK: AGENTS.md has design intent' -ForegroundColor Green }
}

if ($errors -gt 0) {
    Write-Host "FAIL: $errors violations" -ForegroundColor Red
    exit 1
}
Write-Host 'OK: official check pass' -ForegroundColor Green
