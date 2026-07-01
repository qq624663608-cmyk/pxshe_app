# 文档质量 lint(原 .sh,转 .ps1,简化版)
chcp 65001 > $null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot\..

$global:errCount = 0

function Write-Fail($msg) {
    Write-Host $msg -ForegroundColor Red
    $global:errCount = $global:errCount + 1
}

function Write-Ok($msg) {
    Write-Host $msg -ForegroundColor Green
}

Write-Host '--- Doc lint check ---' -ForegroundColor Cyan

# 1. 单文件行数
$mdFiles = Get-ChildItem -Path 'docs' -Filter '*.md' -Recurse -ErrorAction SilentlyContinue
foreach ($f in $mdFiles) {
    $lines = (Get-Content $f.FullName).Count
    if ($lines -gt 500) {
        $relPath = $f.FullName.Replace((Get-Location).Path + '\', '')
        Write-Fail("$relPath has $lines lines (> 500, refactor)")
    }
}

# 2. DEPRECATED 段禁止(只查 markdown 标题行)
$depHeaders = Select-String -Path 'docs/*.md', 'docs/ADR/*.md' -Pattern '^#+\s+.*DEPRECATED' -ErrorAction SilentlyContinue
if ($depHeaders) {
    Write-Fail('DEPRECATED header found in docs/ (delete, use git log)')
}

# 3. 修复史标记
$stage = Select-String -Path 'docs/*.md', 'docs/ADR/*.md' -Pattern 'P[0-9] #|Stage [0-9]+' -ErrorAction SilentlyContinue
if ($stage) {
    Write-Fail('Fix history in docs/ (only CHANGELOG.md)')
}

# 4. SSOT 标头(检查前 5 行,允许不在第一行)
$topMd = Get-ChildItem -Path 'docs/*.md' -ErrorAction SilentlyContinue
foreach ($f in $topMd) {
    $head = Get-Content $f.FullName -TotalCount 5
    $hasSSOT = $false
    foreach ($line in $head) {
        if ($line -match 'SSOT') { $hasSSOT = $true; break }
    }
    if (-not $hasSSOT) {
        Write-Fail("$($f.Name) missing SSOT header (top 5 lines)")
    }
}

# 5. DESIGN.md 检查 (pxshe_app 用 docs/ 集中, 不需要每目录 DESIGN.md)
# 跳过: 文档集中在 docs/ (SSOT)

if ($global:errCount -gt 0) {
    Write-Host "FAIL: $global:errCount doc violations" -ForegroundColor Red
    exit 1
}
Write-Ok('docs/ lint pass')
