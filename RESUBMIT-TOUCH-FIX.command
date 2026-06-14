#!/bin/bash
# 由 Claude 生成：带 owner 已批准的 approval-id 重新提交触控修复任务给 codex。
set -euo pipefail
cd "$(dirname "$0")"

DESC='damov4 批次 C 多端设计系统契约回归。webclients 三个顾客端把可点击元素 min-height 改到了 <48px，违反共享 token --vdamo-touch-min:48px，node design-system-contract.test.mjs 现在是红的。

工作区: /Users/shift/Documents/vdamo/damov4

需要修改(绝对路径):
- /Users/shift/Documents/vdamo/damov4/webclients/customer-order/index.html (现 min-height:44px)
- /Users/shift/Documents/vdamo/damov4/webclients/takeout/index.html (现 46px)
- /Users/shift/Documents/vdamo/damov4/webclients/reserve/index.html (现 46px)

目标: 把这三页所有可点击/可交互元素触控尺寸提到 >=48px，真满足无障碍底线(不是骗正则)。低于48px的 min-height 提到48px；交互元素(数量加减、提交、菜单可点区)的 width/height 低于48px也提到>=48px(纯展示图标/缩略图不动)。优先复用 --vdamo-touch-min。

红线: 只动这三个 index.html 的样式尺寸；不改 fetch/接口路径/业务逻辑/红金CHINDA品牌视觉；不加依赖；不重写结构。

验收(必须全绿,真实输出贴进报告):
cd /Users/shift/Documents/vdamo/damov4 && node webclients/design-system-contract.test.mjs && node webclients/i18n-contract.test.mjs
两条都 exit 0，第一条要打印 design-system-contract PASS。

完成且验收通过输出 STATUS: completed；卡住输出 STATUS: blocked - 原因。证据可打开。'

echo "重新提交(带已批准 approval-id)..."
bin/companyctl task submit \
  --from claude --to codex \
  --title "webclients 三顾客端触控目标提升到48px(设计系统契约回归)" \
  --description "$DESC" \
  --priority P1 \
  --approval-id "approval-route-route-webclients-三个顾客端触控目标提升到48px-设计系统契约回归-secret_change"

echo
echo "=== codex 任务队列(最近) ==="
bin/companyctl task list --agent codex | tail -20
echo
echo "提交完成。守护进程约 30 秒内自动认领并执行。窗口可关闭。"
