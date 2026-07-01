# AI 对话结束前清单(commit 前必跑)
chcp 65001 > $null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot\..

Write-Host '--- Session end checklist ---' -ForegroundColor Cyan
Write-Host ''
Write-Host '6 items:'
Write-Host ' [ ] All code changes synced to docs? (AGENTS section 51)'
Write-Host ' [ ] pre-commit hook passed?'
Write-Host ' [ ] Run 4 lints? (doc_lint + check_duplicates + check_official + doc_freshness)'
Write-Host ' [ ] pubspec.yaml -> docs/REFERENCE.md?'
Write-Host ' [ ] AGENTS.md new article?'
Write-Host ' [ ] New ADR?'
Write-Host ''
Write-Host 'If not done -> complete before commit'
Write-Host ''
Write-Host '================================' -ForegroundColor DarkGray
Write-Host 'Run 4 lints:'
Write-Host '================================' -ForegroundColor DarkGray
Write-Host ''

$errors = 0
$lintScripts = @(
    @{ sh = 'tool/doc_lint.sh'; ps1 = 'tool/doc_lint.ps1' },
    @{ sh = 'tool/check_duplicates.sh'; ps1 = 'tool/check_duplicates.ps1' },
    @{ sh = 'tool/check_official.sh'; ps1 = 'tool/check_official.ps1' },
    @{ sh = 'tool/doc_freshness.sh'; ps1 = 'tool/doc_freshness.ps1' }
)

foreach ($s in $lintScripts) {
    Write-Host "--- $($s.ps1) ---" -ForegroundColor DarkGray
    if (Test-Path $s.ps1) {
        try {
            & powershell -ExecutionPolicy Bypass -File $s.ps1
            if ($LASTEXITCODE -ne 0) { $errors++ }
        } catch {
            Write-Host "ERROR: $_" -ForegroundColor Red
            $errors++
        }
    } else {
        Write-Host "NOT FOUND: $($s.ps1)" -ForegroundColor Yellow
    }
    Write-Host ''
}

Write-Host '================================' -ForegroundColor DarkGray
if ($errors -gt 0) {
    Write-Host "FAIL: $errors lint warnings" -ForegroundColor Red
    Write-Host 'Fix warnings before commit'
    exit 1
}
Write-Host 'OK: session end ready, commit' -ForegroundColor Green
Write-Host '================================' -ForegroundColor DarkGray
