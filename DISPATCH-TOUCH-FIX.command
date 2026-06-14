#!/bin/bash
# 由 Claude 生成：经 company-kernel 派 codex 修复 webclients 触控目标回归。
# 在 Mac 上原生执行（沙箱挂载无法做 SQLite 写）。
set -euo pipefail
cd "$(dirname "$0")"

DESC='damov4 批次 C 多端设计系统的契约回归。webclients 顾客端三个页面把可点击元素的 min-height 改到了低于 48px，违反共享设计 token --vdamo-touch-min:48px，导致 node 契约测试 design-system-contract.test.mjs 现在是红的。

需要修改的文件（绝对路径）：
- /Users/shift/Documents/vdamo/damov4/webclients/customer-order/index.html（当前 min-height:44px）
- /Users/shift/Documents/vdamo/damov4/webclients/takeout/index.html（当前 min-height:46px）
- /Users/shift/Documents/vdamo/damov4/webclients/reserve/index.html（当前 min-height:46px）

目标：把这三页里所有可点击/可交互元素的触控尺寸提到 >=48px，真正满足无障碍触控底线，不是只为骗过正则。凡是低于 48px 的 min-height 提到 48px；同时检查交互元素（数量加减按钮、提交按钮、菜单可点区等）的 width/height，凡用于点击且低于 48px 的也提到 >=48px（纯展示的图标/缩略图可不动）。优先复用 --vdamo-touch-min 变量。

硬约束：只动这三个 index.html 的样式尺寸；不要改 fetch 调用、不要改接口路径、不要改业务逻辑、不要改红金 CHINDA 品牌视觉；不新增依赖；不重写结构。

验收（必须全绿，把真实输出贴进报告）：
cd /Users/shift/Documents/vdamo/damov4 && node webclients/design-system-contract.test.mjs && node webclients/i18n-contract.test.mjs
两条都要 exit 0，第一条要打印 design-system-contract PASS。

完成且验收通过输出 STATUS: completed；卡住输出 STATUS: blocked - 原因。证据要可打开。'

echo "提交任务给 codex ..."
bin/companyctl task submit \
  --from claude \
  --to codex \
  --title "webclients 三个顾客端触控目标提升到48px(设计系统契约回归)" \
  --description "$DESC" \
  --priority P1

echo
echo "=== codex 当前任务队列(取最近一条) ==="
bin/companyctl task list --agent codex | tail -25
echo
echo "提交完成。守护进程约 30 秒内自动认领并执行。"
