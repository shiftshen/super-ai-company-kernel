#!/bin/zsh
# 给空闲的 OpenClaw 业务员工开启"自动执行 worker",让它们的排队任务被桥接到 OpenClaw 执行。
# 机制:每个 worker 每轮跑 company-openclaw-adapter --agent <id>,认领该员工的 submitted 任务并推到 OpenClaw 总线。
set -e
ROOT=/Users/shift/openclaw/company-kernel
cd "$ROOT"

echo "=== 1/3 给 OpenClaw 业务员工补 worker(daemon.json)==="
python3 - <<'PY'
import json
p="/Users/shift/openclaw/company-kernel/config/daemon.json"
cfg=json.load(open(p))
workers=cfg.setdefault("adapter_workers",[])
have={w.get("agent") for w in workers}
add=["chindahotpot","krothong","invest","video-creator","video-ops","video-publisher"]
added=[]
for a in add:
    if a in have:
        # 确保启用
        for w in workers:
            if w.get("agent")==a and not w.get("enabled"): w["enabled"]=True; added.append(a+"(re-enabled)")
        continue
    workers.append({
        "agent": a, "enabled": True, "command": "company-openclaw-adapter", "args": [],
        "max_tasks_per_tick": 1,
        "retry_policy": {"max_attempts": 3, "base_delay_seconds": 60, "max_delay_seconds": 900},
    })
    added.append(a)
json.dump(cfg, open(p,"w"), ensure_ascii=False, indent=2)
print("  新增/启用 worker:", added or "(都已存在)")
print("  当前启用的 workers:", [w["agent"] for w in workers if w.get("enabled")])
PY

echo "=== 2/3 重启守护进程加载新配置 ==="
launchctl kickstart -k "gui/$(id -u)/ai.openclaw.company-kernel.daemon" 2>/dev/null && echo "  daemon restarted" || echo "  (守护每轮会自动重读配置)"
sleep 3

echo "=== 3/3 观察:接下来几轮 OpenClaw 员工的 adapter 运行 ==="
sleep 20
python3 -c "import sqlite3;c=sqlite3.connect('$ROOT/company.sqlite');c.row_factory=sqlite3.Row;rows=c.execute(\"SELECT agent_id,ok,processed,created_at FROM adapter_runs WHERE agent_id IN ('chindahotpot','krothong','invest','video-creator','video-ops','video-publisher') ORDER BY created_at DESC LIMIT 8\").fetchall();print('  最近 OpenClaw 员工执行记录:');[print('   ',dict(r)) for r in rows] or print('   (暂无,下一轮会出现)')"
python3 -c "import sqlite3;print('  任务状态:',dict((r[0],r[1]) for r in sqlite3.connect('$ROOT/company.sqlite').execute(\"SELECT status,COUNT(*) FROM tasks GROUP BY status\").fetchall()))"

echo ""
echo "=== 完成。这些员工现在会自动认领并把任务桥接到 OpenClaw 执行。 ==="
echo "    注意:实际能否完成取决于 OpenClaw 运行时在线 + 对应能力/通知渠道配置。"
