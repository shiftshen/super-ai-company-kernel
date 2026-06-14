#!/bin/zsh
# 让"内核"徽章稳定转绿:
#  1) 排空当前事件队列(正常运营事件)
#  2) 重启网关/守护,加载新的 doctor 逻辑(pending_events 加了 10 分钟宽限期)
# 之后即使 codex 正在产生事件,只要不滞留超过 10 分钟就不再判为异常。双击运行。
set -e
ROOT=/Users/shift/openclaw/company-kernel
cd "$ROOT"

echo "=== 1/3 排空事件队列 ==="
bin/companyctl scheduler run --limit 500 >/dev/null 2>&1 || true
bin/companyctl supervisor delivery-loop >/dev/null 2>&1 || true
python3 -c "import sqlite3;print('  剩余 pending:',sqlite3.connect('$ROOT/company.sqlite').execute(\"SELECT COUNT(*) FROM company_events WHERE processed_at=''\").fetchone()[0])"

echo "=== 2/3 重启网关/守护(加载新 doctor 代码)==="
for L in console api daemon; do
  launchctl kickstart -k "gui/$(id -u)/ai.openclaw.company-kernel.$L" 2>/dev/null && echo "  restarted $L" || echo "  skip $L (未加载)"
done
sleep 3

echo "=== 3/3 体检 ==="
bin/companyctl doctor --summary 2>&1 | python3 -c "import sys,json
try: d=json.load(sys.stdin); print('  内核 ok =',d.get('ok'),'  issues =',d.get('issues'))
except: print('  (doctor 原始输出见上)')" || true

echo ""
echo "=== 完成。回 Console 刷新:徽章应转绿,并在 codex 正常干活时保持绿。 ==="
echo "    (只有事件滞留>10分钟才会再判异常——那才是真需要人工介入的情况)"
