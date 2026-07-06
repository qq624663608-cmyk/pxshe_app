# AI 对话结束前清单(commit 前必跑)
chcp 65001 > $null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot\..

Write-Host '--- Session end checklist ---' -ForegroundColor Cyan
Write-Host ''
Write-Host '强制清单 (commit 前必做):'
Write-Host ''
Write-Host ' 1. [ ] docs/ 改了哪些文件? 主动列出 (不能只靠 pre-commit hook):'
Write-Host '        - 改 lib/_core/        → docs/ARCHITECTURE.md 或 docs/KNOWLEDGE_GRAPH.md'
Write-Host '        - 改 lib/_shared/      → docs/BUILDING_BLOCKS.md'
Write-Host '        - 改 lib/modules/<m>/  → docs/PAGE_CLASSIFICATION.md'
Write-Host '        - 改 lib/modules/<m>/data/ → docs/API.md'
Write-Host '        - 改 lib/modules/auth/data/ → docs/ERROR_HANDLING.md'
Write-Host '        - 改 pubspec.yaml      → docs/REFERENCE.md + docs/LICENSE_INFO.md'
Write-Host '        - 改 lib/<x>/<y>.dart 引入新机制 (新 widget / 新 guard / 新事件) → 在对应 § 加说明'
Write-Host ''
Write-Host ' 2. [ ] pre-commit hook 跑了? (用真检查的版本, 不是 Test-Path 假检查)'
Write-Host ' 3. [ ] 跑 4 lints? (doc_lint + check_duplicates + check_official + doc_freshness)'
Write-Host ' 4. [ ] tool/doc_sync_audit.ps1 内容对齐?'
Write-Host ' 5. [ ] AGENTS.md 需要加新规则?'
Write-Host ' 6. [ ] New ADR? (大改动 / 架构变化 / 选型)'
Write-Host ''
Write-Host '警告: pre-commit 钩子即使显示 "OK: doc sync check pass"'
Write-Host '       也只代表文件存在, 不代表内容已更新。必须主动对照上面 1.'
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
