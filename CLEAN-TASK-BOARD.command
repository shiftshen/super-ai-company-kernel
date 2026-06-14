#!/bin/zsh
# 清理任务看板:取消"测试/冒烟/已归档员工"等垃圾任务,正规清掉过期锁,
# 保留并报告 codex 真实受阻任务(需环境修复)。双击运行。
set -e
ROOT=/Users/shift/openclaw/company-kernel
cd "$ROOT"

echo "=== 1/3 正规清理过期锁/认领 ==="
bin/companyctl repair reset-stale-claims 2>&1 | python3 -c "import sys,json
try: d=json.load(sys.stdin); print('  unlocked:',len(d.get('unlocked_locks',[])),' reset_tasks:',len(d.get('reset_tasks',[])))
except: print('  (done)')" || true

echo "=== 2/3 取消测试/冒烟/归档 垃圾任务 ==="
python3 - <<'PY'
import sqlite3, json, datetime
db="/Users/shift/openclaw/company-kernel/company.sqlite"
c=sqlite3.connect(db); c.row_factory=sqlite3.Row
ts=datetime.datetime.now().astimezone().isoformat(timespec="seconds")

# 判据(精准,避免误杀 codex 真实受阻的产品任务):
#  - target=antigravity(已归档,无 GUI worker)-> 取消
#  - submitted 且是 smoke/test -> 取消(发错给无 worker 的对象)
#  - blocked 且 blocker 以 "codex verdict" 开头 -> 保留(codex 真实尝试,被环境挡住)
#  - blocked 且 blocker 不是 codex verdict -> 取消(框架测试/冒烟遗留)
def classify(status, blocker, title, target):
    b=(blocker or "").strip().lower(); t=(title or "").lower()
    if target=="antigravity":
        return True, "archived target (no GUI worker); smoke task closed"
    if status=="submitted":
        if "smoke" in (b+t) or "test" in t:
            return True, "unclaimed smoke/test routed to a no-worker agent"
        return False, ""
    # blocked
    if b.startswith("codex verdict"):
        return False, ""   # 真实受阻,保留
    return True, "framework test/smoke leftover closed during board cleanup"

cancelled=[]; kept=[]
rows=c.execute("SELECT id,status,target_agent,blocker,title FROM tasks WHERE status IN ('blocked','submitted','claimed')").fetchall()
for r in rows:
    # 不要碰正在被 codex 跑的 claimed 任务
    if r["status"]=="claimed":
        kept.append((r["id"], r["target_agent"], "active claimed - left running"))
        continue
    debris, reason = classify(r["status"], r["blocker"], r["title"], r["target_agent"])
    if debris:
        c.execute("UPDATE tasks SET status='cancelled', blocker=?, updated_at=? WHERE id=?", (reason, ts, r["id"]))
        c.execute("DELETE FROM locks WHERE resource_key=?", (f"task:{r['id']}",))
        try:
            c.execute("INSERT INTO audit_logs(actor,action,target,detail_json,created_at) VALUES(?,?,?,?,?)",
                      ("owner-shift","task.cancel.board_cleanup",r["id"],json.dumps({"reason":reason},ensure_ascii=False),ts))
        except Exception: pass
        cancelled.append((r["id"], r["status"], r["target_agent"]))
    elif r["status"]=="blocked":
        kept.append((r["id"], r["target_agent"], (r["blocker"] or "")[:90]))
c.commit()

print(f"  已取消 {len(cancelled)} 条垃圾任务")
for tid,st,tg in cancelled: print(f"    - {tid} ({st} -> cancelled, target={tg})")
print(f"\n  ★ 保留的真实受阻任务 {sum(1 for k in kept if 'claimed' not in k[2])} 条(需你定夺/修环境):")
for tid,tg,b in kept:
    if "active claimed" in b: continue
    print(f"    ! {tid}  target={tg}  blocker={b}")
print(f"\n  正在运行(未动)的 claimed 任务:")
for tid,tg,b in kept:
    if "active claimed" in b: print(f"    ~ {tid} target={tg}")
c.close()
PY

echo "=== 3/3 复检任务状态分布 + 体检 ==="
python3 -c "import sqlite3;c=sqlite3.connect('$ROOT/company.sqlite');
import collections;print('  ',dict((r[0],r[1]) for r in c.execute(\"SELECT status,COUNT(*) FROM tasks GROUP BY status\").fetchall()));c.close()"
bin/companyctl doctor --summary 2>&1 | python3 -c "import sys,json
try: d=json.load(sys.stdin); print('  内核 ok =',d.get('ok'),' issues =',d.get('issues'))
except: print('  (doctor 输出见上)')" || true

echo ""
echo "=== 完成。回 Console 刷新:受阻数应大幅下降,待领取应清零。 ==="
echo "    保留的 codex 真实受阻任务若要重试:修好对应环境后 bin/companyctl task reopen --task-id <id> ..."
