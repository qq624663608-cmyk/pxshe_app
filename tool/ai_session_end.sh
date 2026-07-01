#!/bin/bash
# AI 对话结束前清单(commit 前必跑)
# 6 项 + 跑全套 lint
set -e

echo "📋 对话结束前清单"
echo ""
cat <<'EOF'
"📋 对话结束前清单:
 □ 所有改动同步了 docs?(AGENTS §51 旅行箱)
 □ pre-commit 钩子检查通过?
 □ 跑全套 lint 4 个(doc_lint + check_duplicates + check_official + doc_freshness)?
 □ 改了 pubspec.yaml 同步 docs/REFERENCE.md?
 □ 改了 AGENTS.md 加新宪法了?
 □ 加新 ADR 记录决策了?

如有未完成,先补完再 commit。"
EOF
echo ""
echo "================================"
echo "🔍 跑全套 lint 检查..."
echo "================================"

ERRORS=0

for script in tool/doc_lint.sh tool/check_duplicates.sh tool/check_official.sh tool/doc_freshness.sh; do
  if [ -f "$script" ]; then
    echo ""
    echo "--- $script ---"
    bash "$script" || ERRORS=$((ERRORS+1))
  fi
done

echo ""
echo "================================"
if [ "$ERRORS" -gt 0 ]; then
  echo "❌ $ERRORS 个 lint 警告"
  echo "建议:先修警告再 commit"
  exit 1
fi
echo "✅ 对话结束清单完毕,准备 commit"
echo "================================"
