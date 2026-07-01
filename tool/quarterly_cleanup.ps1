# 季度断舍离(AGENTS §51)PowerShell 版
# 每 3 月跑 1 次,清理不用的代码
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot\..

$warnings = 0

Write-Host "Quarterly cleanup (AGENTS section 51)" -ForegroundColor Cyan
Write-Host ""

# 1. @Deprecated 超过 90 天的 → 必删
Write-Host "--- @Deprecated check ---"
$depFiles = Get-ChildItem -Path 'lib' -Filter '*.dart' -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -notmatch '\.g\.dart$' }
$depCount = 0
foreach ($f in $depFiles) {
    $content = Get-Content $f.FullName -Raw
    if ($content -match '@Deprecated') {
        $depCount++
        Write-Host "  $($f.FullName -replace '\\','/')"
    }
}
Write-Host "@Deprecated count: $depCount"
if ($depCount -gt 5) {
    Write-Host "WARN: > 5, cleanup needed" -ForegroundColor Yellow
    $warnings++
}

# 2. 90 天没改的文件
Write-Host ""
Write-Host "--- 90 day unused files ---"
$cutoff = (Get-Date).AddDays(-90)
$oldFiles = Get-ChildItem -Path 'lib' -Filter '*.dart' -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt $cutoff -and $_.Name -notmatch '\.g\.dart$' }
if ($oldFiles) {
    Write-Host "Old files (> 90 days, $($oldFiles.Count) total):" -ForegroundColor Yellow
    $oldFiles | Select-Object -First 10 | ForEach-Object {
        Write-Host "  $($_.FullName -replace '\\','/')"
    }
    $warnings++
} else {
    Write-Host "OK: no old files" -ForegroundColor Green
}

# 3. test/ 指向不存在的 src
Write-Host ""
Write-Host "--- broken test imports ---"
$brokenTests = @()
Get-ChildItem -Path 'test' -Filter '*.dart' -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $matches = [regex]::Matches($content, 'package:pxshe_app/([^'']+)\.dart')
    foreach ($m in $matches) {
        $relPath = $m.Groups[1].Value -replace '/', '\'
        if (-not (Test-Path "lib\$relPath")) {
            $brokenTests += "$($_.FullName) -> $($m.Groups[1].Value)"
        }
    }
}
if ($brokenTests) {
    Write-Host "FAIL: broken test imports:" -ForegroundColor Red
    $brokenTests | ForEach-Object { Write-Host "  $_" }
    $warnings++
} else {
    Write-Host "OK: all test targets exist" -ForegroundColor Green
}

# 4. _archive 目录检查
Write-Host ""
Write-Host "--- archive dir check ---"
if ((Test-Path 'lib\_archive') -or (Test-Path 'lib\legacy')) {
    Write-Host "WARN: _archive/legacy dir exists, cleanup?" -ForegroundColor Yellow
    $warnings++
} else {
    Write-Host "OK: no archive dir" -ForegroundColor Green
}

# 报告
Write-Host ""
Write-Host "================================" -ForegroundColor DarkGray
Write-Host "Quarterly Report"
Write-Host "================================" -ForegroundColor DarkGray
Write-Host "Run time: $(Get-Date)"
Write-Host "@Deprecated count: $depCount"
Write-Host "90 day old files: $($oldFiles.Count)"
Write-Host "Warnings: $warnings"
Write-Host ""

if ($warnings -gt 0) {
    Write-Host "WARN: $warnings issues to address" -ForegroundColor Yellow
    exit 0
}
Write-Host "OK: quarterly cleanup pass" -ForegroundColor Green
