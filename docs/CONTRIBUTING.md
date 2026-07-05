# docs/CONTRIBUTING.md — PR / commit / 分支 / 命名

> **本文件是协作流程 SSOT。**

---

## 1. 分支策略 (Git Flow 简化版)

```
main                     # 生产, 只接受 PR
  └─ develop             # 集成, 只接受 PR
       ├─ feat/<scope>   # 新功能
       ├─ fix/<scope>    # BUG
       ├─ refactor/<scope>  # 重构
       ├─ docs/<scope>   # 文档
       ├─ perf/<scope>   # 性能
       ├─ test/<scope>   # 测试
       └─ chore/<scope>  # 杂项
```

---

## 2. commit 规范 (Conventional Commits)

```
<type>(<scope>): <subject>
<BLANK LINE>
<body>
<BLANK LINE>
<footer>
```

### type

- `feat`: 新功能
- `fix`: BUG 修复
- `refactor`: 重构 (无新功能无 BUG 修复)
- `docs`: 文档
- `test`: 测试
- `chore`: 杂项 (依赖 / 构建 / CI)
- `perf`: 性能优化
- `style`: 格式化 (无逻辑变更)
- `ci`: CI 配置

### scope

`<module>` 或 `<layer>`, 如:
- `auth` / `im` / `registration` / `universe` / `core` / `docs` / `ci` / `deps`

### 例子

```
feat(auth): add biometric login

- Add local_auth package
- Add BiometricService in modules/auth/biometric/
- Add toggle in /me/security page

Refs: ADR-0001, Recipe 1
```

```
fix(im): fix chat scroll bug when sending rapid messages
```

```
chore(deps): bump flutter_bloc to 9.2.1
```

---

## 3. PR 模板 (强制)

`.github/PULL_REQUEST_TEMPLATE.md`:

```markdown
## 改动类型
- [ ] 新功能
- [ ] BUG 修复
- [ ] 重构
- [ ] 文档
- [ ] 测试
- [ ] 性能
- [ ] 杂项

## 涉及
<!-- 必填, 空 CI 拒绝 -->
- [ ] ADR-NNNN: <哪个决策被实现>
- [ ] Recipe X: <哪个步骤被遵循>
- [ ] AGENTS §N: <哪条宪法被遵守>
- [ ] <module>/DESIGN.md: <对应 module 的设计意图>

## 改动描述
<!-- 简述改了什么 -->

## 设计自检
- [ ] 没引入 mega Bloc
- [ ] 没跨 module 互相 import
- [ ] 没在 widget build 写业务
- [ ] 1 个新功能只动 1 个目录
- [ ] 颜色用 AppColors (没硬编码)
- [ ] 间距用 AppSpacing (没硬编码)
- [ ] 圆角用 AppRadius (没硬编码)

## 测试
- [ ] 单测通过
- [ ] Widget test 通过
- [ ] 集成 test 通过 (如有)
- [ ] 真机验证 (如有 UI 改动)
- [ ] Screenshot/gif (UI 改动)

## Checklist
- [ ] flutter analyze 0/0
- [ ] flutter test 全过
- [ ] 用了 BLoC 没用 ChangeNotifier
- [ ] 没用 Colors.X / Color(0xFF...)

## 截图
<!-- UI 改动附图 -->
```

---

## 4. 命名规范

| 类别 | 规范 | 例 |
|---|---|---|
| 文件 | snake_case | `auth_repository_impl.dart` |
| 类 | PascalCase | `AuthRepositoryImpl` |
| 方法/变量 | camelCase | `currentUser` / `login()` |
| 私有成员 | _ 前缀 | `_cached` / `_onKickedOffline` |
| 常量 | lowerCamelCase + k 前缀 | `kWalkthroughSeenKey` |
| 路由 | kebab-case | `/me/settings` |
| 资源 | snake_case | `app_icon.png` |
| 提交 | Conventional Commits | `feat: add login page` |

---

## 5. PR 合并流程

```
1. 提交 PR (填模板所有必填项)
2. CI 跑 (8 个 job)
3. 全部 ✅ → reviewer 介入
4. 1 个 reviewer 必审
5. 涉及多个 module → 多个 reviewer
6. 涉及 AGENTS.md → 必须 tech-lead 审
7. approve + merge → develop
8. nightly → main (release)
```

---

## 6. Branch 保护 (GitHub)

**在 GitHub repo → Settings → Branches → Branch protection rules 配置:**

### `main` 分支

- ✅ Require a pull request before merging
  - ✅ Require approvals: 1 (至少 1 个 reviewer)
  - ✅ Dismiss stale pull request approvals when new commits are pushed
- ✅ Require status checks to pass before merging
  - ✅ Require branches to be up to date before merging
  - ✅ Status checks: format-check / analyze / unit-test / build (8 job 全过)
- ✅ Require conversation resolution before merging
- ✅ Require linear history (可选)
- ❌ Allow force pushes: 不允许
- ❌ Allow deletions: 不允许

### `develop` 分支

- ✅ Require approvals: 1
- ✅ Require status checks: format-check / analyze / unit-test (轻量)
- ❌ Allow force pushes: 允许 (只限 maintainer)

### CODEOWNERS (.github/CODEOWNERS)

```
# 全局默认 1 个 reviewer
*                           @team-mobile

# 关键文件需 2 个
/AGENTS.md                  @team-mobile @team-lead
/docs/                      @team-mobile @team-lead
/lib/_core/                 @team-mobile @team-architect
/android/                   @team-android
/ios/                       @team-ios
```

---

## 7. 签名管理 (AGENTS §16)

### Android Keystore

keystore 文件: `android/upload-keystore.jks` (在 `.gitignore`)
配置: `android/key.properties` (在 `.gitignore`)
模板: `android/key.properties.example` (已提供)

---

## 8. 启用 pre-commit 钩子 (重要!)

`tool/pre-commit.ps1` 会在每次 `git commit` 时自动跑, 检查代码改动是否同步了文档。

### 启用

```bash
# 一次性配置 (每个 clone 的 repo 跑一次)
git config core.hooksPath tool
```

### 工作原理

- 改 `lib/_core/` → 检查 `docs/ARCHITECTURE.md` 是否同步
- 改 `lib/_shared/` → 检查 `docs/BUILDING_BLOCKS.md`
- 改 `lib/modules/<m>/data/` → 检查 `docs/API.md`
- 改 `lib/modules/auth/data/` → 检查 `docs/ERROR_HANDLING.md`
- 改 `lib/modules/<m>/` → 检查 `docs/PAGE_CLASSIFICATION.md`
- 改 `pubspec.yaml` → 检查 `docs/REFERENCE.md` + `docs/LICENSE_INFO.md`

违反时**拒绝 commit**, 提示:
```
FAIL: 3 violations (code change without doc)
Fix: sync docs or use 'git commit --no-verify'
```

### 跳过 (紧急情况)

```bash
git commit --no-verify -m "hotfix: ..."
```

⚠️ 跳过必须 PR 描述里说明原因。

### 关闭

```bash
git config --unset core.hooksPath
```

---

## 9. 自动依赖更新 (Dependabot + auto-merge)

项目用 **Dependabot** 每天检查 `pub` 和 `github-actions` 依赖,配 **auto-merge workflow** 在 CI 通过后自动合并 patch + minor 升级。

### 流程

```
Dependabot 每天扫依赖
  ↓
开 PR (按 groups 合并, 不会洪水)
  ↓
CI workflow (.github/workflows/ci.yml) 跑 flutter test + analyze + ai.ps1 all
  ↓
patch + minor:  auto-merge workflow 自动 squash-merge
major:          留 PR 评论提醒人工 review
```

### 配置

- **Dependabot 规则**: `.github/dependabot.yaml`
  - `pub` 生态: daily, open-PR-limit 10, patch+minor 合并成 1 个 PR, major 忽略
  - `github-actions` 生态: daily, open-PR-limit 5, 同上
- **CI 检查**: `.github/workflows/ci.yml` — PR 触发 `flutter test` + `analyze` + `ai.ps1 all` + `doc_sync_audit`
- **自动合并**: `.github/workflows/dependabot_auto_merge.yml` — patch/minor 走 `--auto --squash`

### Major 版本升级怎么办

Dependabot 默认不报 major,需要手动:

```bash
# 1. 本地手动升级 (会更新 pubspec.yaml + pubspec.lock)
flutter pub upgrade --major-versions <package_name>

# 2. 跑全套本地检查
flutter analyze
flutter test
pwsh tool/ai.ps1 all
pwsh tool/doc_sync_audit.ps1

# 3. 同步 docs
#     - docs/REFERENCE.md §1-12 (如新增/删除)
#     - docs/LICENSE_INFO.md §2 (如新增/删除)

# 4. 提交
git add pubspec.yaml pubspec.lock docs/
git commit -m "chore(deps): bump <package_name> to <new_version>"
```

⚠️ Major bump 必查 breaking change,跑全量测试。

### 关闭自动合并

如果某个 PR 不能自动合并,只要在 PR 评论里 `@dependabot cancel` 或关闭 PR 即可。

### 关闭整个 Dependabot

仓库 Settings → Code security and analysis → 关闭 Dependabot (不推荐)。

---

## 10. AI 协作工具 (tool/)

pxshe_app 提供 11 个 AI 协作脚本 (见 `docs/AI_GUIDE.md §0`), 强制使用:

- 对话开始: `pwsh tool/ai.ps1 new`
- 大改动前: `pwsh tool/ai.ps1 change`
- 5 轮自检: `pwsh tool/ai.ps1 check`
- commit 前: `pwsh tool/ai.ps1 done`

详见 [docs/AI_GUIDE.md §0](./AI_GUIDE.md)。

---

*最后更新: 2026-07-06 — 加 §9 自动依赖更新 (Dependabot + auto-merge workflow)*