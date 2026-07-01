# widget 重复检查(原 .sh,转 .ps1)
# AGENTS §50
chcp 65001 > $null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot\..

$errors = 0

Write-Host '--- Widget duplicates check ---' -ForegroundColor Cyan

# 1. 同 base 名字出现多次
Write-Host 'Same base name:'
$widgets = Get-ChildItem -Path 'lib/features/*/presentation/widgets', 'lib/shared/widgets' -Filter '*.dart' -ErrorAction SilentlyContinue
$names = $widgets | ForEach-Object { $_.Name -replace '_[0-9]+\.dart$','' -replace '_new\.dart$','' -replace '_v[0-9]+\.dart$','' }
$groups = $names | Group-Object | Where-Object { $_.Count -gt 1 }
if ($groups) {
    foreach ($g in $groups) {
        Write-Host "FAIL: $($g.Name) appears $($g.Count) times" -ForegroundColor Red
        $errors++
    }
} else {
    Write-Host 'OK: no duplicates' -ForegroundColor Green
}

# 2. 老 v1 风格命名
Write-Host ''
Write-Host 'Old v1 naming:'
$badPattern = '(_[0-9]+|_v[0-9]+|_new|2)\.dart$'
$bad = Get-ChildItem -Path 'lib' -Filter '*.dart' -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -match $badPattern -and $_.Name -notmatch '\.g\.dart$' }
if ($bad) {
    foreach ($b in $bad) {
        Write-Host "FAIL: $($b.Name)" -ForegroundColor Red
        $errors++
    }
} else {
    Write-Host 'OK: no old v1 naming' -ForegroundColor Green
}

# 3. @Deprecated 数量
$depCount = (Select-String -Path 'lib/**/*.dart' -Pattern '@Deprecated' -ErrorAction SilentlyContinue).Count
Write-Host ''
Write-Host "@Deprecated count: $depCount"
if ($depCount -gt 5) {
    Write-Host 'WARN: > 5, cleanup needed' -ForegroundColor Yellow
}

# 4. @Deprecated 格式
$badDep = Select-String -Path 'lib/**/*.dart' -Pattern '@Deprecated' -ErrorAction SilentlyContinue | Where-Object { $_.Line -notmatch 'will remove in v' }
if ($badDep) {
    Write-Host "FAIL: @Deprecated missing 'will remove in vX.Y'" -ForegroundColor Red
    $errors++
}

if ($errors -gt 0) {
    Write-Host "FAIL: $errors violations" -ForegroundColor Red
    exit 1
}
Write-Host 'OK: widget naming pass' -ForegroundColor Green
