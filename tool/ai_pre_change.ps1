# AI 大改动前自检
chcp 65001 > $null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot\..

Write-Host '--- Big change pre-check ---' -ForegroundColor Cyan
Write-Host ''
Write-Host 'Adding X:'
Write-Host ' 1. Overlap with existing Y? (AGENTS section 50)'
Write-Host ' 2. Need new widget? Have recipe? (RECIPES section 1)'
Write-Host ' 3. Need new Provider? new or merge?'
Write-Host ' 4. Which docs change? (PR template "Synced docs")'
Write-Host ' 5. User confirm -> start coding'
Write-Host ''
Write-Host 'Big change = new feature / widget / page / architecture / package / AGENTS / ADR'
Write-Host ''
Write-Host '--- No start coding before answering 5 questions ---' -ForegroundColor Yellow
