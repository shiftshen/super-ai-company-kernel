#!/bin/zsh
set -e
cd /Users/shift/openclaw/company-kernel
git checkout main
echo "=== 同步远程(避免分叉被拒)==="
git fetch origin 2>/dev/null || true
git fetch public 2>/dev/null || true
git merge --no-edit origin/main 2>/dev/null || true
git merge --no-edit public/main 2>/dev/null || true
echo "=== 推送 main 到 origin ==="
git push origin main
echo "=== 推送 main 到 public ==="
git push public main
echo ""
echo "=== 完成。两个远程 main 已更新。 ==="
git log --oneline -3
