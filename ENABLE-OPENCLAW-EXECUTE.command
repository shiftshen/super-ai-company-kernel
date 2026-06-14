#!/bin/zsh
# 让 OpenClaw 员工真正执行任务(而不是空跑假完成)。
# 改动:给所有 company-openclaw-adapter worker 的 args 加 --execute。
# 之后:OpenClaw 外发任务会进 Console 的 Approvals 审批页,你批准后真正提交到 OpenClaw 执行。
set -e
ROOT=/Users/shift/openclaw/company-kernel
cd "$ROOT"

echo "=== 1/3 给 OpenClaw worker 加 --execute ==="
python3 - <<'PY'
import json
p="/Users/shift/openclaw/company-kernel/config/daemon.json"
cfg=json.load(open(p)); changed=[]
for w in cfg.get("adapter_workers",[]):
    if w.get("command")=="company-openclaw-adapter":
        args=w.setdefault("args",[])
        if "--execute" not in args:
            args.insert(0,"--execute"); changed.append(w.get("agent"))
json.dump(cfg, open(p,"w"), ensure_ascii=False, indent=2)
print("  已加 --execute:", changed or "(都已有)")
for w in cfg["adapter_workers"]:
    if w.get("enabled"): print(f"   {w['agent']:16} {w.get('command')} args={w.get('args')}")
PY

echo "=== 2/3 重新派发刚才假完成的日报(走真流程)==="
bin/companyctl task reopen --task-id task-20260614-225858-bae45e --by owner-shift \
  --reason "上轮 adapter 空跑假完成;改 --execute 后重跑,走审批真发" >/dev/null 2>&1 \
  && echo "  已重开日报任务" || echo "  (日报任务重开跳过)"

echo "=== 3/3 重启守护 + 等一轮观察 ==="
launchctl kickstart -k "gui/$(id -u)/ai.openclaw.company-kernel.daemon" 2>/dev/null && echo "  daemon restarted" || true
sleep 25
echo "  --- 待审批(应出现 OpenClaw 外发审批项)---"
bin/companyctl approval list 2>/dev/null | python3 -c "import sys,json
try:
    d=json.load(sys.stdin); items=d.get('approvals',d if isinstance(d,list) else [])
    items=[a for a in (items or []) if str(a.get('status',''))=='pending']
    print('  待审批',len(items),'条:')
    for a in items[:10]: print('   -',a.get('id'),'|',a.get('action'),'|',a.get('source_agent'))
except Exception as e: print('  (用 Console 的 Approvals 页查看)')" || true
python3 -c "import sqlite3;print('  任务状态:',dict((r[0],r[1]) for r in sqlite3.connect('$ROOT/company.sqlite').execute(\"SELECT status,COUNT(*) FROM tasks GROUP BY status\").fetchall()))"

echo ""
echo "=== 完成。去 Console 的【Approvals】页批准 OpenClaw 外发任务,批准后会真正提交执行并发出。 ==="
echo "    若你希望某些 agent 免审批自动发,我可以单独调 policy(但外发无审批有风险)。"
