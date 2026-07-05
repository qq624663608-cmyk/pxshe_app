# setup_github_protection.ps1 - one-time setup after first git push
#
# 用途: 配置 GitHub 仓库的 Branch protection + 启用 Dependabot auto-merge
# 前置: 已 git push 到 GitHub, 已有 Personal Access Token (PAT)
# 用法: $env:GH_TOKEN = "ghp_xxx"; pwsh tool/setup_github_protection.ps1
#
# 这是 setup 脚本,不是常驻工具. 跑成功一次后可以删.

$ErrorActionPreference = 'Stop'
chcp 65001 > $null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Step($msg) { Write-Host ''; Write-Host ('== ' + $msg + ' ==') -ForegroundColor Cyan }
function Ok($msg)   { Write-Host ('  [ok] ' + $msg) -ForegroundColor Green }
function Warn($msg) { Write-Host ('  [warn] ' + $msg) -ForegroundColor Yellow }
function Fail($msg) { Write-Host ('  [fail] ' + $msg) -ForegroundColor Red; exit 1 }

# GitHub API 调用 helper (用 Invoke-WebRequest, 兼容 PowerShell 5.1)
function Gh-Api {
    param([string]$Method, [string]$Path, [string]$Body = $null)
    $headers = @{
        'Authorization' = "Bearer $env:GH_TOKEN"
        'Accept'        = 'application/vnd.github+json'
        'User-Agent'    = 'pxshe-setup-script'
    }
    $params = @{
        Method        = $Method
        Uri           = "https://api.github.com$Path"
        Headers       = $headers
        TimeoutSec    = 30
        UseBasicParsing = $true
    }
    if ($Body) {
        $params['Body'] = $Body
        $params['ContentType'] = 'application/json'
    }
    try {
        $resp = Invoke-WebRequest @params -ErrorAction Stop
        return $resp.StatusCode
    } catch {
        $code = 0
        if ($_.Exception.Response) { $code = [int]$_.Exception.Response.StatusCode }
        return $code
    }
}

# 1. 拿 token
Step '1. Read GH_TOKEN env var'
if (-not $env:GH_TOKEN) {
    Fail '$env:GH_TOKEN is empty. Set it first: $env:GH_TOKEN = "ghp_xxx"'
}
if ($env:GH_TOKEN -notmatch '^ghp_') {
    Fail 'token does not look like a PAT (expected prefix ghp_)'
}
Ok ('token prefix: ' + $env:GH_TOKEN.Substring(0, 8) + '...')

# 2. 解析 remote
Step '2. Detect repo from git remote'
$remoteUrl = git remote get-url origin 2>&1
if ($LASTEXITCODE -ne 0 -or -not $remoteUrl) {
    Fail "no remote 'origin' set"
}
$repo = $null
if ($remoteUrl -match 'github\.com[:/](.+?)/(.+?)(\.git)?$') {
    $repo = "$($Matches[1])/$($Matches[2])"
}
if (-not $repo) {
    Fail "cannot parse owner/repo from: $remoteUrl"
}
Ok ("repo: " + $repo)

# 3. 验证 token + repo
Step '3. Verify token + repo access'
$authCheck = Gh-Api -Method GET -Path "/repos/$repo"
if ($authCheck -ne 200) {
    Fail "token / repo check failed (HTTP $authCheck). Token scope may need `repo`."
}
Ok 'token + repo OK'

# 4. 验证 workflow 已 push
Step '4. Verify workflows pushed'
$ciExists = Gh-Api -Method GET -Path "/repos/$repo/contents/.github/workflows/ci.yml"
$amExists = Gh-Api -Method GET -Path "/repos/$repo/contents/.github/workflows/dependabot_auto_merge.yml"
if ($ciExists -ne 200 -or $amExists -ne 200) {
    Fail "workflows not pushed yet (ci.yml=$ciExists, dependabot_auto_merge.yml=$amExists)"
}
Ok 'ci.yml + dependabot_auto_merge.yml present'

# 5. 等 GitHub 注册新 check
Step '5. Wait 10s for GitHub to register the CI check'
Write-Host '  (CI check needs a few seconds to appear in branch protection UI)' -ForegroundColor DarkYellow
Start-Sleep -Seconds 10

# 6. PUT master branch protection
Step '6. Configure branch protection on master'
# Both `required_pull_request_reviews` and `restrictions` must be explicitly
# null in the body, otherwise GitHub returns 422. strict=true means "branch
# must be up-to-date with master before merge".
$protection = @{
    required_status_checks             = @{
        strict   = $true
        contexts = @('ci')
    }
    enforce_admins                     = $false
    required_pull_request_reviews      = $null
    restrictions                       = $null
    required_linear_history            = $false
    allow_force_pushes                 = $false
    allow_deletions                    = $false
    block_creations                    = $false
    required_conversation_resolution   = $false
} | ConvertTo-Json -Depth 10

$code = Gh-Api -Method PUT -Path "/repos/$repo/branches/master/protection" -Body $protection
if ($code -in @(200, 201, 204)) {
    Ok ('master branch protected (HTTP ' + $code + ')')
} else {
    Warn ('PUT failed with HTTP ' + $code + '. Manual config may be needed:')
    Write-Host ('    https://github.com/' + $repo + '/settings/branches') -ForegroundColor Yellow
}

# 7. 总结 (auto-merge 由 dependabot_auto_merge.yml workflow 处理, 不需要 repo-level toggle)
Step '7. Done'
Write-Host ''
Ok ('Setup complete for ' + $repo)
Write-Host ''
Write-Host 'Notes:' -ForegroundColor Cyan
Write-Host '  - auto-merge 由 .github/workflows/dependabot_auto_merge.yml 处理' -ForegroundColor Gray
Write-Host '  - 不用 repo-level auto-merge 开关 (Dependabot PR 会自动 enable)' -ForegroundColor Gray
Write-Host ''
Write-Host 'Next steps:' -ForegroundColor Cyan
Write-Host '  1. Verify branch protection:' -ForegroundColor Gray
Write-Host ('     https://github.com/' + $repo + '/settings/branches') -ForegroundColor Gray
Write-Host '  2. Wait for first Dependabot scan (up to 24h):' -ForegroundColor Gray
Write-Host ('     https://github.com/' + $repo + '/network/updates') -ForegroundColor Gray
Write-Host '  3. Delete this script after verifying.' -ForegroundColor Gray
Write-Host '  4. Revoke the GH_TOKEN you used here (it is a one-time secret).' -ForegroundColor Gray
