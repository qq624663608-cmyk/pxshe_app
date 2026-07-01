# AI 5 段复述(对话开始)
chcp 65001 > $null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot\..

Write-Host '--- AI recite (对话开始) ---' -ForegroundColor Cyan

$required = 'AGENTS.md', 'docs/README.md', 'docs/AI_GUIDE.md', 'docs/RECIPES.md', 'docs/BUILDING_BLOCKS.md', 'tool/pre-commit'
$missing = @()
foreach ($f in $required) {
    if (-not (Test-Path $f)) { $missing += $f }
}

if ($missing.Count -gt 0) {
    Write-Host 'FAIL: missing files' -ForegroundColor Red
    foreach ($f in $missing) { Write-Host ('  - ' + $f) }
    exit 1
}

Write-Host 'OK: 6 key files exist' -ForegroundColor Green
Write-Host ''

Write-Host 'Copy this to chat first message:' -ForegroundColor Cyan
Write-Host ''
Write-Host 'I read AGENTS.md (chat start required):'
Write-Host ' 1. Design intent: simplify / isolation / readable / addable / testable'
Write-Host ' 2. 5 anti-patterns: mega Bloc / god notifier / cross-feature / setState-call-API / business-in-build'
Write-Host ' 3. Task docs: [list specific files]'
Write-Host ' 4. 23 hard rules: read BUILDING_BLOCKS section 5'
Write-Host ' 5. 4 step anti-pit: read / change / sync / self-check'
Write-Host ''
Write-Host 'Done. Start working.'
Write-Host ''
Write-Host '--- End ---' -ForegroundColor Cyan
Write-Host ''
Write-Host 'Tip: did AI recite the 5 items? If not -> ask again'
