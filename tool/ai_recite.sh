#!/bin/bash
# AI 5 段复述(对话开始必跑,优化版 < 3 秒)
# 戴工牌原则:每个新对话第 1 步必跑
# 优化:不全套 lint(留给 ai_session_end.sh),只检查关键文件存在
set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# 1. 关键文件存在检查(< 1 秒)
echo "🔍 检查关键文件存在..."
MISSING=()
for f in AGENTS.md docs/README.md docs/AI_GUIDE.md docs/RECIPES.md docs/BUILDING_BLOCKS.md tool/pre-commit; do
  if [ ! -f "$f" ]; then
    MISSING+=("$f")
  fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "❌ 缺失关键文件:"
  for f in "${MISSING[@]}"; do
    echo "   - $f"
  done
  echo "无法开始对话"
  exit 1
fi

echo "✅ 关键文件齐全"
echo ""

# 2. 打印 5 段复述(让 AI 复制到对话第 1 条消息)
echo "📚 AI 5 段复述(请复制到对话第一条消息)"
echo ""
cat <<'EOF'
"📚 复习 AGENTS.md(对话开始必做):
 1. 设计初心:简化 / 隔离 / 可读 / 可加 / 可测
 2. 5 大反模式:mega Bloc / god notifier / 跨 feature import / setState 调 API / widget build 写业务
 3. 任务相关 docs:[填具体文件,例:lib/features/auth/DESIGN.md + docs/API.md]
 4. 23 条硬规则:已读 docs/BUILDING_BLOCKS.md §5
 5. 4 步防挖坑:已记(读 / 改 / 同步 / 自检)

我读完。开始干活。"
EOF
echo ""
echo "================================"
echo "✅ 5 段复述打印完毕"
echo "================================"
echo ""
echo "💡 提示:你看到上面 5 段了吗?没看到 → 让 AI 复读"
echo "💡 对话中跑 5 轮自检:bash tool/ai_self_check.sh"
echo "💡 对话结束跑全套:bash tool/ai_session_end.sh"
