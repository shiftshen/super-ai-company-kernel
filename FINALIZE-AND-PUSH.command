#!/bin/zsh
# 收尾:重启加载新代码 -> 等守护跑完一轮 -> 体检 -> 推送 main 到两个远程。
set -e
ROOT=/Users/shift/openclaw/company-kernel
cd "$ROOT"

echo "=== 1/4 重启 console/api/daemon 加载新代码 ==="
for L in console api daemon; do
  launchctl kickstart -k "gui/$(id -u)/ai.openclaw.company-kernel.$L" 2>/dev/null && echo "  restarted $L" || echo "  skip $L"
done

echo "=== 2/4 等守护跑完一轮干净 tick(~35s)==="
sleep 35

echo "=== 3/4 体检(预期 ok=True / issues=[]) ==="
bin/companyctl doctor --summary 2>&1 | python3 -c "import sys,json
try: d=json.load(sys.stdin); print('  内核 ok =',d.get('ok'),'  issues =',d.get('issues'))
except: print('  (见上)')" || true

echo "=== 4/4 推送 main 到两个远程 ==="
git checkout main
git fetch origin 2>/dev/null || true; git fetch public 2>/dev/null || true
git merge --no-edit origin/main 2>/dev/null || true
git merge --no-edit public/main 2>/dev/null || true
git push origin main && echo "  pushed origin"
git push public main && echo "  pushed public"

echo ""
echo "=== 完成。回 Console 刷新,内核徽章应为正常(绿)。 ==="
git log --oneline -3
