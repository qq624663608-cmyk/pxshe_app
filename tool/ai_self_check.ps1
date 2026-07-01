# AI 5 轮自检(每 5 轮对话跑 1 次)
chcp 65001 > $null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot\..

Write-Host '--- 5-round self-check ---' -ForegroundColor Cyan
Write-Host ''
Write-Host 'Round N self-check:'
Write-Host ' [ ] AppColors + AppSpacing? -> yes/no'
Write-Host ' [ ] BLoC Bloc/Cubit (not ChangeNotifier)? -> yes/no'
Write-Host ' [ ] <module>_module.dart facade for cross-module? -> yes/no'
Write-Host ' [ ] Business only in Repository/UseCase (not in widget)? -> yes/no'
Write-Host ' [ ] Code changes synced to docs/? -> [list]'
Write-Host ''
Write-Host 'If any violation -> fix immediately.'
Write-Host ''
Write-Host 'Run doc_freshness check:'
Write-Host '(doc_freshness.sh needs Git Bash; .ps1 version pending)'
Write-Host ''
Write-Host '--- End ---' -ForegroundColor Cyan
