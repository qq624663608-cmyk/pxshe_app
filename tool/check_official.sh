#!/bin/bash
# 官方优先检查(AGENTS §52)
# 验证 pubspec.yaml 里的包都是主流 + 没在用 deprecated API
set -e

ERRORS=0
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

echo "🔍 官方优先检查(AGENTS §52)..."

# 1. 解析 pubspec.yaml 里的所有 third-party 包
echo ""
echo "--- pubspec.yaml 包列表 ---"
if [ ! -f "pubspec.yaml" ]; then
  echo "⚠️  pubspec.yaml 不存在,跳过"
  exit 0
fi

# 提取 dependencies: 段下的包名
PACKAGES=$(awk '/^dependencies:/{flag=1; next} /^dev_dependencies:/{flag=0} flag && /^[a-z_]+:/{print $1}' pubspec.yaml | sed 's/://')
if [ -z "$PACKAGES" ]; then
  echo "⚠️  未解析到包,跳过"
  exit 0
fi
echo "$PACKAGES"

# 2. 禁止包检查 (pxshe_app 用 BLoC 栈, 不用 Riverpod)
echo ""
echo "--- 禁止包检查 ---"
FORBIDDEN=("mobx" "riverpod" "flutter_riverpod" "provider" "get_it_mixin" "auto_route" "sentry_flutter" "firebase_core" "firebase_crashlytics" "firebase_analytics" "mockito" "shared_preferences" "hive")

for pkg in "${FORBIDDEN[@]}"; do
  if grep -q "^  $pkg:" pubspec.yaml 2>/dev/null; then
    echo "❌ 禁止包:$pkg(见 docs/REFERENCE.md §4)"
    ERRORS=$((ERRORS+1))
  fi
done

if [ "$ERRORS" -eq 0 ]; then
  echo "✅ 无禁止包"
fi

# 3. Flutter @Deprecated API 检查
echo ""
echo "--- Flutter @Deprecated API 检查 ---"
DEP_USED=$(grep -rE "withOpacity|WillPopScope|MaterialApp\([^)]*useMaterial3:\s*false" lib/ 2>/dev/null | head -10 || true)

if [ -n "$DEP_USED" ]; then
  echo "❌ 发现 deprecated API:"
  echo "$DEP_USED"
  ERRORS=$((ERRORS+1))
else
  echo "✅ 无 deprecated API"
fi

# 4. ADR 编号连续性
echo ""
echo "--- ADR 编号检查 ---"
ADR_COUNT=$(find docs/ADR -name "*.md" -not -name "0000-*" 2>/dev/null | wc -l | tr -d ' ')
if [ "$ADR_COUNT" -gt 0 ]; then
  echo "📊 ADR 数量:$ADR_COUNT(应连续编号)"
  for i in $(seq 1 $ADR_COUNT); do
    NUM=$(printf "%04d" $i)
    if [ ! -f "docs/ADR/${NUM}-"*.md ]; then
      echo "❌ 缺失 ADR-${NUM}"
      ERRORS=$((ERRORS+1))
    fi
  done
else
  echo "⚠️  无 ADR 文件,可能还没建"
fi

# 5. REFERENCE.md 同步检查
echo ""
echo "--- docs/REFERENCE.md 同步检查 ---"
if [ ! -f "docs/REFERENCE.md" ]; then
  echo "❌ docs/REFERENCE.md 缺失"
  ERRORS=$((ERRORS+1))
else
  echo "✅ docs/REFERENCE.md 存在"
fi

# 6. AGENTS.md 必填章节检查
echo ""
echo "--- AGENTS.md 必填章节检查 ---"
if [ ! -f "AGENTS.md" ]; then
  echo "❌ AGENTS.md 缺失"
  ERRORS=$((ERRORS+1))
else
  if ! grep -q "设计初心" AGENTS.md; then
    echo "❌ AGENTS.md 缺'设计初心'章节"
    ERRORS=$((ERRORS+1))
  else
    echo "✅ AGENTS.md 含'设计初心'章节"
  fi
  if ! grep -q "★ 5 大反模式" AGENTS.md; then
    echo "❌ AGENTS.md 缺'5 大反模式'章节"
    ERRORS=$((ERRORS+1))
  else
    echo "✅ AGENTS.md 含'5 大反模式'章节"
  fi
fi

echo ""
if [ "$ERRORS" -gt 0 ]; then
  echo "❌ $ERRORS violations(违反 AGENTS §52)"
  exit 1
fi
echo "✅ 官方优先检查通过"
