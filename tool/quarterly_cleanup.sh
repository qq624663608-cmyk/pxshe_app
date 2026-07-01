#!/bin/bash
# 季度断舍离(AGENTS §51)
# 每 3 个月跑 1 次,清理不用的代码
set -e

ERRORS=0
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

QUARTER=$(date +%Y-Q$((($(date +%m)-1)/3+1)))
echo "🧳 季度断舍离 $QUARTER(AGENTS §51)"
echo ""

# 1. @Deprecated 超过 90 天的 → 必删
echo "=== 1. @Deprecated 标记 ==="
DEP_FILES=$(grep -rln "@Deprecated" lib/ 2>/dev/null | head -20)
DEP_COUNT=$(grep -rn "@Deprecated" lib/ 2>/dev/null | wc -l | tr -d ' ')

if [ "$DEP_COUNT" -gt 0 ]; then
  echo "📊 当前 @Deprecated 数量:$DEP_COUNT"
  if [ "$DEP_COUNT" -gt 5 ]; then
    echo "❌ > 5 个,建议清理"
    ERRORS=$((ERRORS+1))
  fi
  echo ""
  echo "详情:"
  grep -rn "@Deprecated" lib/ 2>/dev/null | head -20
else
  echo "✅ 无 @Deprecated"
fi

# 2. 90 天没改的文件(可能没用了)
echo ""
echo "=== 2. 90 天没改的文件(可能没用) ==="
if command -v git &> /dev/null; then
  git log --since="90 days ago" --name-only --pretty=format: 2>/dev/null | \
    sort -u | grep "^lib/" > /tmp/modified_90d.txt
  find lib -name "*.dart" -not -name "*.g.dart" | sort > /tmp/all_dart.txt
  comm -23 /tmp/all_dart.txt /tmp/modified_90d.txt > /tmp/unused_90d.txt
  
  UNUSED_COUNT=$(wc -l < /tmp/unused_90d.txt | tr -d ' ')
  echo "📊 90 天没改的文件:$UNUSED_COUNT"
  if [ "$UNUSED_COUNT" -gt 10 ]; then
    echo "⚠️  > 10 个文件 90 天没动,检查是否还需要"
    head -20 /tmp/unused_90d.txt
  else
    echo "✅ 数量正常(≤ 10)"
  fi
fi

# 3. 重复代码检测
echo ""
echo "=== 3. 重复代码检测 ==="
if command -v dart_code_metrics &> /dev/null; then
  dart_code_metrics check lib --fatal-duplicated-code --reporter=json 2>/dev/null | \
    grep -E '"duplicatedCode"|"lines":' | head -10 || true
else
  echo "⚠️  dart_code_metrics 未装,跳过"
fi

# 4. test/ 里指向不存在的 src
echo ""
echo "=== 4. test/ 指向不存在的 src ==="
MISSING_TARGETS=$(find test/ -name "*.dart" 2>/dev/null | while read test_file; do
  # 提取 import 'package:universe_app/...' 看是否在 lib/ 存在
  grep -oE "package:universe_app/[^']+\.dart" "$test_file" 2>/dev/null | while read pkg_path; do
    rel_path=$(echo "$pkg_path" | sed 's|package:universe_app/||')
    if [ ! -f "$rel_path" ]; then
      echo "$test_file -> $pkg_path (目标不存在)"
    fi
  done
done | head -20 || true)

if [ -n "$MISSING_TARGETS" ]; then
  echo "❌ 找到指向不存在 src 的测试:"
  echo "$MISSING_TARGETS"
  ERRORS=$((ERRORS+1))
else
  echo "✅ 所有 test 目标都存在"
fi

# 5. ARCHIVE 目录(应为空)
echo ""
echo "=== 5. ARCHIVE 目录检查 ==="
if [ -d "lib/_archive" ] || [ -d "lib/legacy" ]; then
  ARCH_SIZE=$(du -sh lib/_archive lib/legacy 2>/dev/null | tail -1)
  echo "⚠️  发现 _archive/legacy 目录:$ARCH_SIZE"
  echo "   建议:跑 git log 确认是否还需要,不需要就 git rm"
else
  echo "✅ 无 _archive/legacy 目录"
fi

# 6. 输出报告
echo ""
echo "================================"
echo "📋 断舍离报告"
echo "================================"
echo "运行时间:$(date)"
echo "项目:$REPO_ROOT"
echo ""
echo "待处理:"
echo "  - @Deprecated 数量:$DEP_COUNT"
echo "  - 90 天未改文件:$UNUSED_COUNT"
if [ "$ERRORS" -gt 0 ]; then
  echo ""
  echo "❌ $ERRORS 项需处理"
  exit 1
fi
echo ""
echo "✅ 季度断舍离完成,无紧急问题"
