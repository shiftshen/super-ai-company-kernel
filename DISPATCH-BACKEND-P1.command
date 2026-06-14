#!/bin/bash
# 由 Claude 生成：升 claude 为 active 受信员工 + 派云端 P1 后端首批给 codex。
set -euo pipefail
cd "$(dirname "$0")"

echo "== 1) 升 claude 为 active =="
bin/companyctl employee update --id claude --status active | tail -3 || true

DESC='工作区: /Users/shift/Documents/vdamo/damov4/vdamo-cloud

目标(云端 P1 后端, 本批不接真实外部账号):
1. 会员储值中心账本: member_wallets + wallet_transactions 完整账本语义(开户/充值/消费/退款/分账事务), 余额不变量校验。钱包复核 requires_review 语义不许改; 储值证据不全一律 requires_review, 禁止自动批准。
2. 钱包复核后端: 待复核队列模型 + 审核动作(approve/reject 留痕) + 配套 Filament 页可操作。
3. 通知中心: Notifier 接口 + 三 driver(line / email-SMTP / log); 外部凭证缺失时自动降级为 log 并在后台标"未配置"(本批不接真实账号)。notification_subscriptions 模型 + Filament 管理。日报(T+1 Asia/Bangkok 泰中双语, 无数据发"昨日无数据") + shift.closed 即时交班推送 + 告警(待复核钱包新增 / 单笔退款≥阈值 / 设备失联≥N分钟 / 同步积压, 30 分钟去重)。渲染单测 + 发送失败重试 3 次落 dead letter。

红线: 数据库迁移只 ADD 不 DROP; 不改 store-sync 幂等与 wallet requires_review 语义; 不碰正式站 www.vdamo.com。

验收(必须全绿, 真实输出贴报告):
cd /Users/shift/Documents/vdamo/damov4/vdamo-cloud && vendor/bin/pint --test && php artisan test && php artisan store-sync:smoke --fresh

成本闸: 超出合理预算即停手转人工。完成输出 STATUS: completed + 改了哪些文件 + 测试数字; 卡住输出 STATUS: blocked - 原因。'

echo "== 2) 派 B3 云端P1后端 给 codex =="
bin/companyctl task submit \
  --from claude --to codex \
  --title "云端P1 后端: 会员储值账本+钱包复核+通知中心" \
  --description "$DESC" \
  --priority P1

echo
echo "== codex 队列(最近) =="
bin/companyctl task list --agent codex | tail -15
echo
echo "完成。守护进程将自动认领执行。窗口可关闭。"
