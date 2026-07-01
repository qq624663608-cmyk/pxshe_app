#!/bin/bash
# AI 5 轮自检(每 5 轮对话跑 1 次)
# 5 项自检 + 跑 doc_freshness 检查
set -e

echo "🔄 5 轮自检(每 5 轮对话跑 1 次)"
echo ""
cat <<'EOF'
"🔄 第 N 轮自检:
 □ 颜色用 AppColors?间距用 AppSpacing? → [是/否]
 □ 异步数据用 Riverpod Provider? → [是/否]
 □ 跨 feature 走 Feature.instance? → [是/否]
 □ 业务判断只住 Repo/Provider/UseCase? → [是/否]
 □ 改了的代码同步了 docs? → [列出同步了哪些]

如有违反,立刻修,不允许带病继续。"
EOF
echo ""
echo "================================"
echo "🔍 跑文档陈旧度检查..."
echo "================================"

if [ -f "tool/doc_freshness.sh" ]; then
  bash tool/doc_freshness.sh
else
  echo "⚠️  tool/doc_freshness.sh 不存在,跳过"
fi

echo ""
echo "================================"
echo "✅ 5 轮自检模板打印完毕,陈旧度检查完毕"
echo "================================"
