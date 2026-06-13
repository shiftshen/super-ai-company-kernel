#!/bin/zsh
# 员工真实状态校正：逐个探测，只有真能干活的保留 active，其余降级并写明原因
cd /Users/shift/openclaw/company-kernel || exit 1
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$HOME/bin:$PATH"
python3 -m company_kernel.reconcile_status
echo ""
echo "=== 完成，窗口可关闭。报告: state/status-reconcile-report.txt ==="
