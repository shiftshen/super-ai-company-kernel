#!/bin/zsh
# 全员活体冒烟：逐个 runtime 真实执行一次，验证链路是否真能干活
cd /Users/shift/openclaw/company-kernel || exit 1
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$HOME/bin:$PATH"
python3 -m company_kernel.live_smoke
echo ""
echo "=== 完成，窗口可关闭。报告: state/live-smoke-report.txt ==="
