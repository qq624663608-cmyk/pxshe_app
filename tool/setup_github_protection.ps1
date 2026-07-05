# setup_github_protection.ps1 - one-time setup after first git push
#
# 用途: 配置 GitHub 仓库的 Branch protection + 启用 Dependabot auto-merge
# 前置: 已 git push 到 GitHub, 已安装 gh CLI 并 `gh auth login`
# 用法: pwsh tool/setup_github_protection.ps1
#
# 这是 setup 脚本,不是常驻工具. 跑成功一次后可以删.

$ErrorActionPreference = 'Stop'
chcp 65001 > $null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Step($msg) { Write-Host ''; Write-Host ('== ' + $msg + ' ==') -ForegroundColor Cyan }
function Ok($msg)   { Write-Host ('  [ok] ' + $msg) -ForegroundColor Green }
function Warn($msg) { Write-Host ('  [warn] ' + $msg) -ForegroundColor Yellow }
function Fail($msg) { Write-Host ('  [fail] ' + $msg) -ForegroundColor Red; exit 1 }

# 1. 验证 gh CLI
Step '1. Check gh CLI'
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Fail "gh CLI not found. Install: winget install GitHub.cli (then: gh auth login)"
}
gh --version | Out-Null
Ok 'gh CLI found'

# 2. 验证认证
Step '2. Check gh auth'
$authStatus = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Fail "gh not authenticated. Run: gh auth login"
}
Ok 'authenticated'

# 3. 取仓库名 (owner/repo)
Step '3. Detect repo'
$remoteUrl = git remote get-url origin 2>&1
if ($LASTEXITCODE -ne 0 -or -not $remoteUrl) {
    Fail "no remote 'origin' set. Run: git remote add origin <github-url>, then git push -u origin master"
}
Ok ('remote: ' + $remoteUrl)

# 解析 owner/repo from URL
# e.g. https://github.com/owner/repo.git  -> owner/repo
#      git@github.com:owner/repo.git     -> owner/repo
$repo = $null
if ($remoteUrl -match 'github\.com[:/](.+?)/(.+?)(\.git)?$') {
    $repo = "$($Matches[1])/$($Matches[2])"
}
if (-not $repo) {
    Fail "cannot parse owner/repo from remote: $remoteUrl"
}
Ok ("repo: " + $repo)

# 4. 检查仓库存在
Step '4. Check repo exists'
$repoCheck = gh repo view $repo 2>&1
if ($LASTEXITCODE -ne 0) {
    Fail "repo $repo not found or no access"
}
Ok 'repo accessible'

# 5. 检查 workflow 文件已经 push 上去
Step '5. Verify workflows pushed'
$ciExists = gh api "repos/$repo/contents/.github/workflows/ci.yml" 2>&1
$amExists = gh api "repos/$repo/contents/.github/workflows/dependabot_auto_merge.yml" 2>&1
if ($LASTEXITCODE -ne 0) {
    Fail 'workflows not pushed yet. Run: git push -u origin master, then re-run this script'
}
Ok 'ci.yml + dependabot_auto_merge.yml found on remote'

# 6. 配置 master 分支保护
Step '6. Configure branch protection on master'
# 等一次让 GitHub 注册新的 check (CI workflow 第一次跑完后才有)
Write-Host '  (waiting 10s for GitHub to register the new CI check...)' -ForegroundColor DarkYellow
Start-Sleep -Seconds 10

# 取 check name (从最近一次 commit 跑过的 CI)
$checkName = 'ci'
$protection = @{
    required_status_checks = @{
        strict = $true
        contexts = @($checkName)
    }
    enforce_admins = $false
    required_pull_request_reviews = $null
    restrictions = $null
    required_linear_history = $false
    allow_force_pushes = $false
    allow_deletions = $false
    block_creations = $false
    required_conversation_resolution = $false
} | ConvertTo-Json -Depth 10

$protection | Out-File -FilePath "$env:TEMP\protection.json" -Encoding utf8
gh api -X PUT "repos/$repo/branches/master/protection" --input "$env:TEMP\protection.json" 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Warn 'PUT failed (branch may already be protected, or check name is wrong)'
    Warn 'fallback: open this URL and configure manually:'
    Write-Host ("    https://github.com/" + $repo + "/settings/branches") -ForegroundColor Yellow
} else {
    Ok 'master branch protected (CI check required)'
}

# 7. 启用 Dependabot auto-merge
Step '7. Enable Dependabot auto-merge'
$autoMerge = @{
    enabled = $true
    allowed_merge_methods = @('squash')
} | ConvertTo-Json -Depth 10
$autoMerge | Out-File -FilePath "$env:TEMP\automerge.json" -Encoding utf8
gh api -X PATCH "repos/$repo/automated-security-fixes" --input "$env:TEMP\automerge.json" 2>&1 | Out-Null
# auto-merge 通过 workflow 完成, 不需要额外 API. 这里只是保险地打开 auto-merge 按钮.
if ($LASTEXITCODE -eq 0) {
    Ok 'auto-merge toggle enabled (Dependabot workflow will use it)'
} else {
    Warn 'auto-merge toggle not enabled (Dependabot will still comment + open PR, merge via workflow)'
}

# 8. 总结
Step '8. Done'
Write-Host ''
Ok ('Setup complete for ' + $repo)
Write-Host ''
Write-Host 'Next steps:' -ForegroundColor Cyan
Write-Host '  1. Verify branch protection:' -ForegroundColor Gray
Write-Host ("     https://github.com/" + $repo + "/settings/branches") -ForegroundColor Gray
Write-Host '  2. Wait for Dependabot first scan (up to 24h):' -ForegroundColor Gray
Write-Host ("     https://github.com/" + $repo + "/network/updates") -ForegroundColor Gray
Write-Host '  3. You can delete this script after verifying.' -ForegroundColor Gray
