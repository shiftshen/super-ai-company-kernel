#!/bin/zsh
# 应用本轮修复:
#  1) 补批 owner-shift 发起的旧待审批(owner 免审批,清掉残留)
#  2) 重启网关/守护,加载新代码(doctor 不再因待审批报异常;审批带任务标题)
set -e
ROOT=/Users/shift/openclaw/company-kernel
cd "$ROOT"

echo "=== 1/3 补批 owner-shift 的旧待审批 ==="
IDS=$(bin/companyctl approval list --status pending 2>/dev/null | python3 -c "import sys,json
try:
    d=json.load(sys.stdin)
    for a in d.get('approvals',[]):
        if a.get('source_agent')=='owner-shift' and a.get('status')=='pending': print(a.get('id'))
except Exception: pass")
if [ -z "$IDS" ]; then echo "  无 owner 待审批"; else
  for id in ${(f)IDS}; do
    [ -n "$id" ] || continue
    bin/companyctl approval approve --approval-id "$id" --by owner-shift --reason "管理员免审批,补批" >/dev/null && echo "  已批准 $id"
  done
fi

echo "=== 2/3 重启 console/api/daemon 加载新代码 ==="
for L in console api daemon; do
  launchctl kickstart -k "gui/$(id -u)/ai.openclaw.company-kernel.$L" 2>/dev/null && echo "  restarted $L" || echo "  skip $L"
done
sleep 3

echo "=== 3/3 体检 ==="
bin/companyctl doctor --summary 2>&1 | python3 -c "import sys,json
try: d=json.load(sys.stdin); print('  内核 ok =',d.get('ok'),'  issues =',d.get('issues'))
except: print('  (见上)')" || true
bin/companyctl approval list --status pending 2>/dev/null | python3 -c "import sys,json
try: d=json.load(sys.stdin); print('  待审批剩余:',len([a for a in d.get('approvals',[]) if a.get('status')=='pending']))
except: pass" || true

echo ""
echo "=== 完成。内核异常应消除;以后管理员发的任务免审批直达执行,审批卡会显示任务标题。 ==="
