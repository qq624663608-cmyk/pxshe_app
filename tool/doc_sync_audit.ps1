# doc_sync_audit.ps1 - code vs docs content drift check
#
# Complements `tool/pre-commit.ps1` (file-existence only) and
# `tool/ai.ps1 all` (4 doc lints but not content-vs-code).
#
# Catches 3 categories of drift that ai.ps1 all misses:
#   1. Constants hardcoded in docs (e.g. 'im_token' instead of
#      Constants.cachedImTokenRef).
#   2. IM routes list (PAGE_CLASSIFICATION, IM_INTEGRATION).
#   3. pubspec dependencies in REFERENCE.md and LICENSE_INFO.md.
#
# Usage:  pwsh tool/doc_sync_audit.ps1
# Exit 0 = OK, 1 = drift detected
#
# Tested on PowerShell 5.1 (Windows PowerShell).
# Note: API-signature-vs-docs check was removed in this rev because
# markdown table rows and SDK-direct calls both contain method names
# with parenthesised parameter lists, making regex-based extraction
# unreliable without a proper Dart parser. Re-add it via `dart analyze`
# doc-linker tests if needed in the future.

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

Write-Host '--- doc sync audit (code vs docs content) ---' -ForegroundColor Cyan

# 1. Constants: scan lib/_core/constants.dart and ensure docs reference
#    the constant name (Constants.cachedImTokenRef), not raw legacy values.
Write-Host ''
Write-Host '[1/3] Constants in docs vs code ...' -ForegroundColor Yellow

$constantsFile = 'lib/_core/constants.dart'
if (Test-Path $constantsFile) {
    $constPattern = "static const String\s+(\w+)\s*=\s*'([A-Z_0-9]+)'"
    $regex = New-Object System.Text.RegularExpressions.Regex($constPattern)
    $m = $regex.Match((Get-Content $constantsFile -Raw))
    while ($m.Success) {
        $name = $m.Groups[1].Value
        $value = $m.Groups[2].Value
        $hits = Select-String -Path 'docs/*.md', 'docs/**/*.md' `
            -Pattern "'$value'" -ErrorAction SilentlyContinue
        foreach ($hit in $hits) {
            $lineText = (Get-Content $hit.Path)[$hit.LineNumber - 1]
            if ($lineText -match "Constants\.$name\b") { continue }
            Write-Fail ("MISMATCH: " + $constantsFile + " `Constants." + $name + " = '" + $value + "' but " + $hit.Path + ":" + $hit.LineNumber + ' uses raw value')
            Write-Host ('  hint: use Constants.' + $name + " instead of '" + $value + "'") -ForegroundColor DarkYellow
        }
        $m = $m.NextMatch()
    }
}

# 2. IM routes: scan im_routes.dart path constants vs documented routes.
Write-Host ''
Write-Host '[2/3] IM routes in docs ...' -ForegroundColor Yellow

$routesFile = 'lib/modules/im/im_routes.dart'
if (Test-Path $routesFile) {
    $routePattern = "static const String \w+ = '([/\w:{}]+)'"
    $regex = New-Object System.Text.RegularExpressions.Regex($routePattern)
    $m = $regex.Match((Get-Content $routesFile -Raw))
    while ($m.Success) {
        $route = $m.Groups[1].Value
        foreach ($doc in @('docs/PAGE_CLASSIFICATION.md', 'docs/IM_INTEGRATION.md')) {
            if (-not (Test-Path $doc)) {
                Write-Fail ($doc + ' missing - im_routes.dart declares `' + $route + '`')
                continue
            }
            $docText = Get-Content $doc -Raw
            if ($docText -notmatch [regex]::Escape($route)) {
                Write-Fail ($doc + ' does not list route `' + $route + '`')
            }
        }
        $m = $m.NextMatch()
    }
}

# 3. pubspec dependencies: new direct deps must appear in REFERENCE.md
#    and LICENSE_INFO.md.
Write-Host ''
Write-Host '[3/3] pubspec.yaml dependencies in docs ...' -ForegroundColor Yellow

$pubspecFile = 'pubspec.yaml'
if (Test-Path $pubspecFile) {
    $pubspecText = Get-Content $pubspecFile -Raw
    $depsMatch = [regex]::Match($pubspecText, '(?ms)^dependencies:\s*\n((?:\s+\w+:[^\n]+\n)+)')
    if ($depsMatch.Success) {
        $depsBlock = $depsMatch.Groups[1].Value
        $depPattern = '^\s+([a-z_]+):'
        $regex = New-Object System.Text.RegularExpressions.Regex($depPattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
        $matches = $regex.Matches($depsBlock)
        $skip = @('flutter', 'flutter_localizations', 'cupertino_icons', 'meta')
        foreach ($dm in $matches) {
            $dep = $dm.Groups[1].Value
            if ($skip -contains $dep) { continue }
            foreach ($doc in @('docs/REFERENCE.md', 'docs/LICENSE_INFO.md')) {
                if (-not (Test-Path $doc)) {
                    Write-Fail ($doc + ' missing - pubspec has `' + $dep + '`')
                    continue
                }
                $docText = Get-Content $doc -Raw
                if ($docText -notmatch [regex]::Escape($dep)) {
                    Write-Fail ($doc + ' does not mention dependency `' + $dep + '`')
                }
            }
        }
    }
}

Write-Host ''
if ($global:errCount -gt 0) {
    Write-Host ('FAIL: ' + $global:errCount + ' doc vs code drift(s)') -ForegroundColor Red
    Write-Host 'Fix the docs above so they reflect the current code (CONTRIBUTING sec 8).' -ForegroundColor DarkYellow
    exit 1
}
Write-Ok 'doc sync audit pass'