#!/bin/bash
# 文档陈旧度自动检测
# 跑频率:每周 1 次(CI 定时)
# 目的:文档 > 7 天没更新 + 代码最近改 → 警告

set -e

WARNINGS=0
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

echo "📅 文档陈旧度检测"
echo ""

if ! command -v git &> /dev/null; then
  echo "❌ 不是 git 仓库"
  exit 1
fi

# 1. 找出最近改的代码(过去 7 天)
echo "--- 过去 7 天改的代码 ---"
RECENT_CODE=$(git log --since="7 days ago" --name-only --pretty=format: 2>/dev/null | \
  grep "^lib/.*\.dart$" | grep -v "\.g\.dart$" | sort -u)

if [ -z "$RECENT_CODE" ]; then
  echo "✅ 过去 7 天没改代码"
  exit 0
fi

CODE_COUNT=$(echo "$RECENT_CODE" | wc -l | tr -d ' ')
echo "📊 改了 $CODE_COUNT 个 .dart 文件"
echo ""

# 2. 找出最近改的文档
echo "--- 过去 7 天改的文档 ---"
RECENT_DOCS=$(git log --since="7 days ago" --name-only --pretty=format: 2>/dev/null | \
  grep -E "^(lib/[^/]+/DESIGN\.md|lib/[^/]+/[^/]+/DESIGN\.md|^docs/|^AGENTS\.md)" | sort -u)

DOC_COUNT=$(echo "$RECENT_DOCS" | wc -l | tr -d ' ')
echo "📊 改了 $DOC_COUNT 个文档"
echo ""

# 3. 检测:改代码但没改对应文档
echo "--- 缺失文档检查 ---"

# 提取改的 feature
CHANGED_FEATURES=$(echo "$RECENT_CODE" | sed -E 's|^lib/features/([^/]+)/.*|\1|' | sort -u)
CHANGED_LAYERS=$(echo "$RECENT_CODE" | sed -E 's|^lib/([^/]+)/.*|\1|' | sort -u)

for feature in $CHANGED_FEATURES; do
  if [ -n "$feature" ] && [ "$feature" != "lib" ]; then
    if ! echo "$RECENT_DOCS" | grep -q "lib/features/$feature/DESIGN.md"; then
      echo "⚠️  改了 features/$feature/ 但没改 DESIGN.md(过去 7 天)"
      echo "    推荐:git log --since=\"7 days ago\" -- lib/features/$feature/ 看看改了什么"
      WARNINGS=$((WARNINGS+1))
    fi
  fi
done

for layer in $CHANGED_LAYERS; do
  case $layer in
    core|shared|design_system|app)
      if ! echo "$RECENT_DOCS" | grep -qE "lib/${layer}/DESIGN\.md"; then
        echo "⚠️  改了 lib/$layer/ 但没改 DESIGN.md(过去 7 天)"
        WARNINGS=$((WARNINGS+1))
      fi
      ;;
  esac
done

# 4. 改 widgetLocator 没改 BUILDING_BLOCKS
if echo "$RECENT_CODE" | grep -qE "(widget_locator|widgetLocator)"; then
  if ! echo "$RECENT_DOCS" | grep -q "docs/BUILDING_BLOCKS.md"; then
    echo "⚠️  改了 widgetLocator 但没改 BUILDING_BLOCKS.md"
    WARNINGS=$((WARNINGS+1))
  fi
fi

# 5. 改 ApiClient 没改 API.md
if echo "$RECENT_CODE" | grep -qE "lib/core/network/api_client"; then
  if ! echo "$RECENT_DOCS" | grep -q "docs/API.md"; then
    echo "⚠️  改了 ApiClient 但没改 docs/API.md"
    WARNINGS=$((WARNINGS+1))
  fi
fi

# 6. 文档自身多久没更新(超过 90 天)
echo ""
echo "--- 90 天没更新的文档 ---"
OLD_DOCS=$(find docs/ -name "*.md" -mtime +90 2>/dev/null)
if [ -n "$OLD_DOCS" ]; then
  echo "$OLD_DOCS" | while read f; do
    if [ -f "$f" ]; then
      echo "⚠️  $f(> 90 天没更新,可能过期)"
    fi
  done
fi

echo ""
echo "================================"
echo "📊 检测结果"
echo "================================"
echo "最近 7 天改的代码:$CODE_COUNT 个"
echo "最近 7 天改的文档:$DOC_COUNT 个"
echo "警告:$WARNINGS"
echo ""

if [ "$WARNINGS" -gt 0 ]; then
  echo "⚠️  有警告,建议同步文档"
  exit 0
fi

echo "✅ 文档新鲜度 OK"
