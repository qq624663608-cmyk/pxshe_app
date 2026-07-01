# 文档陈旧度(原 .sh,转 .ps1)
# CI 每周跑
chcp 65001 > $null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot\..

$warnings = 0

Write-Host '--- Doc freshness check ---' -ForegroundColor Cyan

# 1. 7 天内改的代码
$cutoff = (Get-Date).AddDays(-7)
$recentCode = Get-ChildItem -Path 'lib' -Filter '*.dart' -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -gt $cutoff -and $_.Name -notmatch '\.g\.dart$' }

if (-not $recentCode) {
    Write-Host 'OK: no code changes in 7 days' -ForegroundColor Green
    exit 0
}

$codeCount = $recentCode.Count
Write-Host "Code changed in 7 days: $codeCount"

# 2. 7 天内改的 docs
$recentDocs = Get-ChildItem -Path 'lib' -Filter 'DESIGN.md' -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -gt $cutoff }
$recentDocs += Get-ChildItem -Path 'docs' -Filter '*.md' -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -gt $cutoff }
$docCount = $recentDocs.Count
Write-Host "Docs changed in 7 days: $docCount"

# 3. 缺失文档检查
$changedFeatures = $recentCode | ForEach-Object { ($_.FullName -replace '\\','/') -replace '^lib/features/([^/]+)/.*', '$1' } | Sort-Object -Unique
foreach ($feature in $changedFeatures) {
    if ($feature -and $feature -ne 'lib') {
        $designMd = "lib/features/$feature/DESIGN.md"
        if ((Test-Path $designMd) -and ((Get-Item $designMd).LastWriteTime -lt $cutoff)) {
            Write-Host "WARN: changed features/$feature/ but DESIGN.md > 7 days old" -ForegroundColor Yellow
            $warnings++
        }
    }
}

# 4. 90 天没更新的文档
$oldCutoff = (Get-Date).AddDays(-90)
$oldDocs = Get-ChildItem -Path 'docs' -Filter '*.md' -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt $oldCutoff }
if ($oldDocs) {
    Write-Host ''
    Write-Host "Old docs (> 90 days):"
    foreach ($f in $oldDocs) {
        Write-Host "  WARN: $($f.FullName -replace '\\','/')" -ForegroundColor Yellow
    }
}

if ($warnings -gt 0) {
    Write-Host ""
    Write-Host "WARN: $warnings freshness issues" -ForegroundColor Yellow
    exit 0
}
Write-Host ''
Write-Host 'OK: doc freshness pass' -ForegroundColor Green
