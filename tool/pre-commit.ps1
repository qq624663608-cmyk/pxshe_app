# pre-commit 钩子:改代码必带文档
# 防止 AI 改完代码忘改文档
# 启用: git config core.hooksPath tool

$ErrorActionPreference = 'Stop'

$repoRoot = (git rev-parse --show-toplevel).Trim()
Set-Location $repoRoot

Write-Host 'pre-commit: check doc sync...' -ForegroundColor Cyan
Write-Host "repo: $repoRoot"

$errors = 0

# 1. 暂存区改的 .dart
$changedDart = git diff --cached --name-only | Where-Object {
    $_ -match '^lib/.*\.dart$' -and $_ -notmatch '\.g\.dart$'
}

# 2. 暂存区改的文档
$changedDocs = @(git diff --cached --name-only | Where-Object {
    $_ -match '^(docs/|AGENTS\.md|ROADMAP\.md|README\.md)'
})

function Has-DocChange([string]$docPath) {
    # Compare against last commit (HEAD); treat untracked new files as
    # already added. Only the docs/ file that is *actually staged for
    # change* counts — existing-on-disk doesn't.
    $rel = $docPath -replace '\\', '/'
    $staged = git diff --cached --name-only | ForEach-Object { $_ -replace '\\', '/' }
    return $staged -contains $rel
}

if ($changedDart) {
    Write-Host 'Changed .dart:' -ForegroundColor Yellow
    $changedDart | Select-Object -First 10 | ForEach-Object { Write-Host "  $_" }
    Write-Host ''

    $changedModules = $changedDart | ForEach-Object {
        if ($_ -match '^lib/modules/([^/]+)/') { $Matches[1] }
    } | Sort-Object -Unique
    $changedLayers = $changedDart | ForEach-Object {
        if ($_ -match '^lib/([^/]+)/') { $Matches[1] }
    } | Sort-Object -Unique

    Write-Host "Changed module:$changedModules" -ForegroundColor Yellow
    Write-Host "Changed layer:$changedLayers" -ForegroundColor Yellow
    Write-Host ''

    # Hint: warn when code changed but no doc staged
    if (-not $changedDocs -or $changedDocs.Count -eq 0) {
        Write-Host 'HINT: code changed but no docs/ staged — did you forget to sync?' -ForegroundColor Yellow
    }

    # 3. 改 _core/ 或 app/ → docs/ARCHITECTURE.md 或 docs/KNOWLEDGE_GRAPH.md
    if ($changedLayers -contains '_core' -or $changedLayers -contains 'app') {
        $hasDoc = (Has-DocChange 'docs/ARCHITECTURE.md') -or `
                  (Has-DocChange 'docs/KNOWLEDGE_GRAPH.md')
        if (-not $hasDoc) {
            Write-Host 'FAIL: changed lib/_core/ or lib/app/ but neither docs/ARCHITECTURE.md nor docs/KNOWLEDGE_GRAPH.md is modified' -ForegroundColor Red
            $errors++
        }
    }

    # 4. 改 _shared/ → docs/BUILDING_BLOCKS.md
    if ($changedLayers -contains '_shared') {
        if (-not (Has-DocChange 'docs/BUILDING_BLOCKS.md')) {
            Write-Host 'FAIL: changed lib/_shared/ but docs/BUILDING_BLOCKS.md is NOT modified' -ForegroundColor Red
            $errors++
        }
    }

    # 5. 改 modules/<m>/data/ → docs/API.md
    if ($changedDart | Where-Object { $_ -match 'lib/modules/[^/]+/data/' }) {
        if (-not (Has-DocChange 'docs/API.md')) {
            Write-Host 'FAIL: changed lib/modules/*/data/ but docs/API.md is NOT modified' -ForegroundColor Red
            $errors++
        }
    }

    # 6. 改 modules/auth/data/ → docs/ERROR_HANDLING.md
    if ($changedDart | Where-Object { $_ -match 'lib/modules/auth/data/' }) {
        if (-not (Has-DocChange 'docs/ERROR_HANDLING.md')) {
            Write-Host 'FAIL: changed lib/modules/auth/data/ but docs/ERROR_HANDLING.md is NOT modified' -ForegroundColor Red
            $errors++
        }
    }

    # 7. 改 modules/<m>/ → docs/PAGE_CLASSIFICATION.md
    if ($changedModules.Count -gt 0) {
        if (-not (Has-DocChange 'docs/PAGE_CLASSIFICATION.md')) {
            Write-Host 'FAIL: changed lib/modules/*/ but docs/PAGE_CLASSIFICATION.md is NOT modified' -ForegroundColor Red
            $errors++
        }
    }
}

# 8. pubspec.yaml 改过 → 必备 docs/REFERENCE.md + docs/LICENSE_INFO.md
if ((git diff --cached --name-only) -contains 'pubspec.yaml') {
    if (-not (Has-DocChange 'docs/REFERENCE.md')) {
        Write-Host 'FAIL: pubspec.yaml changed but docs/REFERENCE.md is NOT modified' -ForegroundColor Red
        $errors++
    }
    if (-not (Has-DocChange 'docs/LICENSE_INFO.md')) {
        Write-Host 'FAIL: pubspec.yaml changed but docs/LICENSE_INFO.md is NOT modified' -ForegroundColor Red
        $errors++
    }
}

# 9. AGENTS.md 改过 → 必跑 check_official
if ((git diff --cached --name-only) -contains 'AGENTS.md') {
    Write-Host 'INFO: AGENTS.md changed, run check_official.ps1 manually' -ForegroundColor Yellow
}

Write-Host ''
if ($errors -gt 0) {
    Write-Host "FAIL: $errors violations (code change without doc sync)" -ForegroundColor Red
    Write-Host "Fix: edit the relevant docs/ file, stage it (git add), and retry"
    Write-Host "Bypass only when truly no doc update is needed: git commit --no-verify"
    exit 1
}
Write-Host 'OK: doc sync check pass' -ForegroundColor Green
