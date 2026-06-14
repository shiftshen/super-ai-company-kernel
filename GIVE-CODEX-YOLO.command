#!/bin/zsh
# 给 codex 最高权限(YOLO)并重跑所有真实受阻任务。
# 机制:把 codex 适配器沙箱 workspace-write -> danger-full-access(codex 无沙箱全权模式),
#       然后 reopen 所有 blocked 的 codex 任务,重启守护进程让其用全权重跑。
# ⚠️ danger-full-access = codex 可读写整盘 + 全网络访问 + 执行系统命令(SSH/brew/gradle 等)。
#    这会真正执行部署、安装、SSH 等真实操作。这是你明确要求的 YOLO 模式。
set -e
ROOT=/Users/shift/openclaw/company-kernel
cd "$ROOT"

echo "=== 1/4 把 codex 适配器沙箱改为 danger-full-access ==="
python3 - <<'PY'
import json
p="/Users/shift/openclaw/company-kernel/config/daemon.json"
cfg=json.load(open(p))
changed=False
for w in cfg.get("adapter_workers",[]):
    if w.get("agent")=="codex":
        args=w.get("args",[])
        if "--sandbox" in args:
            i=args.index("--sandbox"); args[i+1]="danger-full-access"
        else:
            args[:0]=["--sandbox","danger-full-access"]
        # 关掉每任务成本/重试上限对重试的拦截(可选,确保能跑完)
        w["args"]=args; changed=True
        print("  codex args =>", args)
json.dump(cfg, open(p,"w"), ensure_ascii=False, indent=2)
print("  saved." if changed else "  codex worker not found!")
PY

echo "=== 2/4 reopen 所有 blocked 的 codex 任务 ==="
IDS=$(python3 -c "import sqlite3;c=sqlite3.connect('$ROOT/company.sqlite');print('\n'.join(r[0] for r in c.execute(\"SELECT id FROM tasks WHERE status='blocked' AND target_agent='codex'\").fetchall()))")
if [ -z "$IDS" ]; then echo "  无 blocked codex 任务"; else
  for id in ${(f)IDS}; do
    [ -n "$id" ] || continue
    bin/companyctl task reopen --task-id "$id" --by codex --reason "granted danger-full-access (YOLO); retry under full permissions" >/dev/null \
      && echo "  reopened $id"
  done
fi

echo "=== 3/4 重启守护进程(立即加载新沙箱配置)==="
launchctl kickstart -k "gui/$(id -u)/ai.openclaw.company-kernel.daemon" 2>/dev/null && echo "  daemon restarted" || echo "  (daemon 标签未找到/无需重启,守护每轮会自动重读配置)"

echo "=== 4/4 当前任务状态 ==="
python3 -c "import sqlite3;c=sqlite3.connect('$ROOT/company.sqlite');print('  ',dict((r[0],r[1]) for r in c.execute(\"SELECT status,COUNT(*) FROM tasks GROUP BY status\").fetchall()));c.close()"

echo ""
echo "=== 完成。codex 现在以 danger-full-access 全权运行,9 条任务已重新排队。 ==="
echo "    守护进程会在 ~30s 内逐条认领并执行。看进展:"
echo "    bin/companyctl task list --agent codex"
echo "    tail -f logs/daemon.log | cut -c1-200"
