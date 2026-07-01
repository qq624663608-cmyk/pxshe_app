# AI 智能入口(一句话判断该跑哪个)
# 用法:pwsh tool/ai.ps1            (菜单选 1-5)
#      pwsh tool/ai.ps1 new      (对话开始)
#      pwsh tool/ai.ps1 check    (5 轮自检)
#      pwsh tool/ai.ps1 change   (大改动前)
#      pwsh tool/ai.ps1 done     (commit 前)
#      pwsh tool/ai.ps1 all      (全套)

chcp 65001 > $null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot\..

function Run-Script($name) {
    $path = "tool/$name.ps1"
    if (Test-Path $path) {
        Write-Host "--- Running $name ---" -ForegroundColor Cyan
        & powershell -ExecutionPolicy Bypass -File $path
    } else {
        Write-Host "FAIL: $path not found" -ForegroundColor Red
        exit 1
    }
}

function Show-Menu {
    Write-Host ''
    Write-Host '==========================================' -ForegroundColor DarkGray
    Write-Host ' AI Scripts Quick Menu' -ForegroundColor Cyan
    Write-Host '==========================================' -ForegroundColor DarkGray
    Write-Host ''
    Write-Host ' 1. NEW    = ai_recite (start of chat)' -ForegroundColor Green
    Write-Host ' 2. CHECK  = ai_self_check (every 5 rounds)' -ForegroundColor Yellow
    Write-Host ' 3. CHANGE = ai_pre_change (before big change)' -ForegroundColor Magenta
    Write-Host ' 4. DONE   = ai_session_end (before commit)' -ForegroundColor Red
    Write-Host ' 5. ALL    = run all 4 (~40s)' -ForegroundColor Blue
    Write-Host ''
    Write-Host '==========================================' -ForegroundColor DarkGray
}

function Run-All {
    Run-Script 'ai_recite'
    Run-Script 'ai_self_check'
    Run-Script 'ai_pre_change'
    Run-Script 'ai_session_end'
}

# 主逻辑
$arg = $args[0]

if (-not $arg) {
    Show-Menu
    $choice = Read-Host 'Choose 1-5 (or q to quit)'
    if ($choice -eq '1') { Run-Script 'ai_recite' }
    elseif ($choice -eq '2') { Run-Script 'ai_self_check' }
    elseif ($choice -eq '3') { Run-Script 'ai_pre_change' }
    elseif ($choice -eq '4') { Run-Script 'ai_session_end' }
    elseif ($choice -eq '5') { Run-All }
    elseif ($choice -eq 'q') { Write-Host 'Bye' -ForegroundColor Gray; exit 0 }
    else { Write-Host 'Invalid choice' -ForegroundColor Red; exit 1 }
} else {
    $argLower = $arg.ToLower()
    if ($argLower -eq 'new' -or $argLower -eq 'start' -or $argLower -eq 'begin') {
        Run-Script 'ai_recite'
    } elseif ($argLower -eq 'check' -or $argLower -eq 'self') {
        Run-Script 'ai_self_check'
    } elseif ($argLower -eq 'change' -or $argLower -eq 'pre' -or $argLower -eq 'big') {
        Run-Script 'ai_pre_change'
    } elseif ($argLower -eq 'done' -or $argLower -eq 'end' -or $argLower -eq 'commit') {
        Run-Script 'ai_session_end'
    } elseif ($argLower -eq 'all' -or $argLower -eq 'full') {
        Run-All
    } else {
        Write-Host "Unknown command: $arg" -ForegroundColor Red
        Show-Menu
        exit 1
    }
}

Write-Host ''
Write-Host '==========================================' -ForegroundColor DarkGray
Write-Host ' Done. AI can now proceed.' -ForegroundColor Green
Write-Host '==========================================' -ForegroundColor DarkGray
