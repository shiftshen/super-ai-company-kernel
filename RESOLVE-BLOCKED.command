#!/bin/zsh
# 处理 2 条受阻任务:
#  A) 取消测试任务 c80dc3(描述=test,无真实仓库)
#  B) 给 B5 契约 fixture 任务追加"解阻指令"并重新派给 codex(全权重跑)
set -e
ROOT=/Users/shift/openclaw/company-kernel
cd "$ROOT"

echo "=== A) 取消测试任务 + 给 B5 追加解阻指令 ==="
python3 - <<'PY'
import sqlite3, datetime
db="/Users/shift/openclaw/company-kernel/company.sqlite"
c=sqlite3.connect(db); ts=datetime.datetime.now().astimezone().isoformat(timespec="seconds")

# A) 取消测试任务
tid="task-20260613-085611-c80dc3"
c.execute("UPDATE tasks SET status='cancelled', blocker='测试任务(描述=test),无真实仓库,人工关闭', updated_at=? WHERE id=?",(ts,tid))
c.execute("DELETE FROM locks WHERE resource_key=?", (f"task:{tid}",))
try: c.execute("INSERT INTO audit_logs(actor,action,target,detail_json,created_at) VALUES(?,?,?,?,?)",("owner-shift","task.cancel.manual",tid,"{}",ts))
except Exception: pass
print("  已取消测试任务:", tid)

# B) 追加解阻指令到 B5
b5="task-20260614-035101-147048"
row=c.execute("SELECT description FROM tasks WHERE id=?",(b5,)).fetchone()
guide=("\n\n【补充指令 / 解阻规则】B5 目标=录制旧 damov3 store-sync 契约 fixture 并纳入契约测试。"
       "按以下规则完成,严禁因契约不一致而整体阻塞:\n"
       "1) 以 damov3 (https://damov3.xmanx.com) 真实响应为准录制 fixture(含 config.data.delta 等所有旧字段),脱敏后入库;\n"
       "2) 若 php artisan test 因『新实现缺 config.data.delta』失败——这是本任务预期要发现的真实回归:把相关用例标记为 xfail/已知失败,"
       "并在报告里单列一节『新实现待补字段: config.data.delta(后续单独修复)』,不要因此 block 整个任务;\n"
       "3) 必须产出:fixture 文件路径、契约测试改动文件、验证命令与结果、以及回归清单。完成即 STATUS: completed。")
c.execute("UPDATE tasks SET description=? WHERE id=?", ((row[0] or "")+guide, b5))
c.commit(); c.close()
print("  已给 B5 追加解阻指令:", b5)
PY

echo "=== B) 重新派发 B5(codex 全权按新指令重跑)==="
bin/companyctl task reopen --task-id task-20260614-035101-147048 --by codex \
  --reason "已补解阻规则:以 damov3 为准录 fixture,新实现缺字段记为已知回归不阻塞" >/dev/null \
  && echo "  已重新派发 B5"

echo "=== 当前任务状态 ==="
python3 -c "import sqlite3;print('  ',dict((r[0],r[1]) for r in sqlite3.connect('$ROOT/company.sqlite').execute(\"SELECT status,COUNT(*) FROM tasks GROUP BY status\").fetchall()))"
echo ""
echo "=== 完成:测试任务已删除;B5 已带明确指令重新交给 codex(~30s 内自动认领重跑)。Console 刷新 Blocked 应降为 0。 ==="
