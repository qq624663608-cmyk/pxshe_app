#!/bin/bash
# 检查 widget 重复(AGENTS §50)
# 同层出现相似命名的 widget → 警告
set -e

ERRORS=0
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

echo "🔍 检查 widget 重复(AGENTS §50)..."

# 1. 同 base 名字出现多次(avatar.dart, avatar2.dart)
echo ""
echo "--- 同 base 名字 ---"
DUPES=$(find lib/features/*/presentation/widgets lib/shared/widgets -name "*.dart" 2>/dev/null | \
  awk -F'/' '{print $NF}' | \
  sed -E 's/_[0-9]+\.dart//; s/_new\.dart//; s/_v[0-9]+\.dart//' | \
  sort | uniq -c | awk '$1 > 1' || true)

if [ -n "$DUPES" ]; then
  echo "❌ 同 base 名字出现多次(违反 AGENTS §50):"
  echo "$DUPES"
  ERRORS=$((ERRORS+1))
else
  echo "✅ 无重复"
fi

# 2. 老 v1 风格命名(avatar2, my_avatar, avatar_v2, avatar_new)
echo ""
echo "--- 老 v1 风格命名 ---"
BAD_NAMES=$(find lib -name "*.dart" 2>/dev/null | \
  grep -E "(^|/)[^/]*(_[0-9]+|_v[0-9]+|_new|2\.dart)\.dart$" | \
  grep -v "test/" | grep -v ".g.dart" || true)

if [ -n "$BAD_NAMES" ]; then
  echo "❌ 发现老 v1 风格命名(违反 AGENTS §50):"
  echo "$BAD_NAMES"
  ERRORS=$((ERRORS+1))
else
  echo "✅ 无老 v1 风格命名"
fi

# 3. @Deprecated 检查(超过 5 个 → 警告,该清理)
echo ""
echo "--- @Deprecated 数量 ---"
DEP_COUNT=$(grep -rn "@Deprecated" lib/ 2>/dev/null | wc -l | tr -d ' ')
if [ "$DEP_COUNT" -gt 5 ]; then
  echo "⚠️  @Deprecated 数量:$DEP_COUNT(> 5,考虑清理)"
else
  echo "✅ @Deprecated 数量:$DEP_COUNT(≤ 5)"
fi

# 4. 强制 @Deprecated 必须带 'will remove in vX.Y'
echo ""
echo "--- @Deprecated 格式检查 ---"
BAD_DEP=$(grep -rn "@Deprecated" lib/ 2>/dev/null | grep -v "will remove in v" || true)
if [ -n "$BAD_DEP" ]; then
  echo "❌ @Deprecated 缺少 'will remove in vX.Y' 标记:"
  echo "$BAD_DEP"
  ERRORS=$((ERRORS+1))
else
  echo "✅ @Deprecated 格式正确"
fi

echo ""
if [ "$ERRORS" -gt 0 ]; then
  echo "❌ $ERRORS violations(违反 AGENTS §50)"
  exit 1
fi
echo "✅ widget 命名检查通过"
