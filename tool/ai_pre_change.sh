#!/bin/bash
# AI 大改动前自检(加新 feature / 改架构 / 加包前)
# 列 5 问,必答才动手
set -e

echo "🔍 大改动前自检模板"
echo ""
cat <<'EOF'
"🔍 我要加 <X 功能>:
 1. 跟现有 <Y> 重合度?<AGENTS §50 旅行箱)
 2. 需要新 widget?有 recipe 吗?(RECIPES.md §1)
 3. 需要新 Provider?新加还是合并?
 4. 改了哪些 docs?(PR 模板"## 同步了哪些文档")
 5. 用户确认 → 动手(没确认不许写代码)"

大改动定义:
- 加新 feature / widget / page
- 改架构(分层 / 状态管理 / 依赖)
- 加 third-party 包
- 改 AGENTS.md(新宪法)
- 加新 ADR
EOF
echo ""
echo "================================"
echo "⚠️  回答上面 5 个问题前不许动手"
echo "================================"

# 检查 AGENTS.md 第 50/51/52 条
if [ -f "AGENTS.md" ]; then
  echo ""
  echo "📋 必读 AGENTS 章节:"
  echo "  - 第 50 条:扩展优于新建(重合度检查)"
  echo "  - 第 51 条:防堆砌(加新挤掉旧)"
  echo "  - 第 52 条:官方优先(菜谱原则)"
fi

# 检查 RECIPES.md
if [ -f "docs/RECIPES.md" ]; then
  echo ""
  echo "📋 必读 docs:"
  echo "  - docs/RECIPES.md(5 个'加新 X'步骤)"
  echo "  - docs/REFERENCE.md(官方资源 + 必备/禁止包)"
fi
