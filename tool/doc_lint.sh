# tool/doc_lint.sh

> **本文件是文档质量检查器。**
> CI 跑这个,失败 PR 拒绝合并。

```bash
#!/bin/bash
# 文档 lint — 跑在 CI,失败 exit 1
set -e

ERRORS=0
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

echo "🔍 检查 docs/ 文档质量..."

# 1. 单文件 ≤ 300 行(AGENTS.md 除外,因为是宪法)
for f in docs/*.md docs/ADR/*.md; do
  LINES=$(wc -l < "$f")
  if [ "$LINES" -gt 300 ]; then
    echo "❌ $f: $LINES lines (> 300,需重构)"
    ERRORS=$((ERRORS+1))
  fi
done

# 2. DEPRECATED 段禁止
if grep -rn "DEPRECATED" docs/ 2>/dev/null; then
  echo "❌ DEPRECATED found in docs/(直接删,走 git log)"
  ERRORS=$((ERRORS+1))
fi

# 3. 修复史标记禁止
if grep -rEn "★ P[0-9] #|Stage [0-9]+|2026-06-2[0-9] (修复|修法|修订)" docs/ 2>/dev/null; then
  echo "❌ 修复史 found in docs/(只走 CHANGELOG.md)"
  ERRORS=$((ERRORS+1))
fi

# 4. SSOT 标头(每个 .md 顶部)
for f in docs/*.md; do
  FIRST_LINE=$(head -1 "$f")
  if ! echo "$FIRST_LINE" | grep -q "SSOT"; then
    echo "❌ $f: missing SSOT header"
    ERRORS=$((ERRORS+1))
  fi
done

# 5. 死链检查
if command -v markdown-link-check &> /dev/null; then
  npx markdown-link-check docs/**/*.md || {
    echo "❌ broken links found"
    ERRORS=$((ERRORS+1))
  }
fi

# 6. 必填 DESIGN.md 检查
for dir in lib/app lib/core lib/features lib/shared lib/design_system; do
  if [ ! -f "$dir/DESIGN.md" ]; then
    echo "❌ $dir/DESIGN.md missing"
    ERRORS=$((ERRORS+1))
  fi
done

if [ "$ERRORS" -gt 0 ]; then
  echo ""
  echo "❌ $ERRORS doc violations"
  exit 1
fi

echo "✅ docs/ OK"
```

---

*最后更新:2026-06-28*
