#!/bin/bash
# AI 智能入口(Git Bash 版,镜像 ai.ps1)
# 用法:./tool/ai.sh new      (对话开始)
#      ./tool/ai.sh check    (5 轮自检)
#      ./tool/ai.sh change   (大改动前)
#      ./tool/ai.sh done     (commit 前)
#      ./tool/ai.sh all      (全套)

set -e
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

run_script() {
    echo "--- Running $1 ---"
    if [ -f "tool/$1.sh" ]; then
        bash "tool/$1.sh"
    else
        echo "FAIL: tool/$1.sh not found" >&2
        exit 1
    fi
}

case "${1:-}" in
    new|start|begin)
        run_script ai_recite
        ;;
    check|self)
        run_script ai_self_check
        ;;
    change|pre|big)
        run_script ai_pre_change
        ;;
    done|end|commit)
        run_script ai_session_end
        ;;
    all|full)
        run_script ai_recite
        run_script ai_self_check
        run_script ai_pre_change
        run_script ai_session_end
        ;;
    ""|help|-h|--help)
        echo "Usage: $0 {new|check|change|done|all}"
        echo "  new      = ai_recite (start of chat)"
        echo "  check    = ai_self_check (every 5 rounds)"
        echo "  change   = ai_pre_change (before big change)"
        echo "  done     = ai_session_end (before commit)"
        echo "  all      = run all 4"
        exit 0
        ;;
    *)
        echo "Unknown command: $1" >&2
        echo "Run '$0 help' for usage" >&2
        exit 1
        ;;
esac

echo ""
echo "=========================================="
echo " Done. AI can now proceed."
echo "=========================================="
