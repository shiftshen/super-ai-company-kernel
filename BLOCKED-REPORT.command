#!/bin/zsh
# 生成"待人工处理"任务报告(纯中文,看得懂):每条受阻任务 = 是什么 / 为什么卡 / 你该怎么办。
# 输出到 reports/needs-human.md 并在终端打印。双击运行。
set -e
ROOT=/Users/shift/openclaw/company-kernel
cd "$ROOT"
python3 - <<'PY'
import sqlite3, os, datetime, re
ROOT="/Users/shift/openclaw/company-kernel"
db=os.path.join(ROOT,"company.sqlite")
c=sqlite3.connect(db); c.row_factory=sqlite3.Row

def humanize(blocker, title, desc):
    b=(blocker or "").lower()
    # 返回 (人话原因, 建议动作)
    if "not a git repo" in b or "no ci" in b or "no project" in b or "为空" in b or "is empty" in b:
        return ("codex 在指定目录没找到真实代码仓库/项目,无法执行。",
                "若只是测试→取消;否则改派时在【描述】里写清楚要操作的仓库**绝对路径**,例如 /Users/shift/openclaw/你的项目。")
    if "ssh" in b:
        return ("codex 无法 SSH 到目标服务器(网络不通或没配密钥)。",
                "确认目标机开机可达、已在本机配好 SSH 免密;或你先手动连上,再让它接着做。")
    if "homebrew" in b or "brew" in b or "cellar" in b:
        return ("codex 无法用 Homebrew 安装依赖(权限/网络问题)。",
                "你手动装好所需依赖(或修好 brew 权限)后,改派重跑。")
    if "gradle" in b or "socket" in b or "android" in title.lower():
        return ("Android 构建环境在当前机器起不来(Gradle/本地端口受限)。",
                "在装好 Android SDK/可联网的环境里跑;或确认需要的本地服务已启动。")
    if "config" in b and ("缺" in b or "missing" in b or "field" in b):
        return ("数据/配置缺字段,codex 不敢猜着改。",
                "你确认正确的配置值,写进任务描述后改派;或先把配置补好。")
    if "php" in b or "composer" in b:
        return ("缺 PHP/Composer 运行时,装不上。",
                "手动装好 PHP+Composer 后改派重跑。")
    # 兜底:截取 codex 结论
    m=re.search(r"blocked\s*[—-]\s*(.+)", blocker or "")
    reason = (m.group(1)[:120] if m else (blocker or "")[:120]) or "未知原因"
    return (f"codex 报阻塞:{reason}", "看是否为真实需求;真要做就在描述里补足前置条件后改派,否则取消。")

rows=c.execute("SELECT id,source_agent,target_agent,title,description,blocker,created_at FROM tasks WHERE status='blocked' ORDER BY created_at").fetchall()
lines=[f"# 待人工处理的受阻任务  ({datetime.datetime.now().strftime('%Y-%m-%d %H:%M')})",
       f"\n共 {len(rows)} 条需要你定夺。\n"]
for i,r in enumerate(rows,1):
    why,act=humanize(r["blocker"], r["title"] or "", r["description"] or "")
    lines += [
        f"## {i}. {r['title']}  ",
        f"- 任务号:`{r['id']}`（{r['source_agent']} → {r['target_agent']}）  ",
        f"- 为什么卡:{why}  ",
        f"- 你可以怎么办:{act}  ",
        f"- 命令(取消):`bin/companyctl task cancel ...`  或 在 Console 点改派后按上面提示补信息\n",
    ]
out=os.path.join(ROOT,"reports","needs-human.md")
os.makedirs(os.path.dirname(out),exist_ok=True)
open(out,"w").write("\n".join(lines))
print("\n".join(lines))
print(f"\n已写入:{out}")
c.close()
PY
echo ""
echo "报告已生成:reports/needs-human.md"
