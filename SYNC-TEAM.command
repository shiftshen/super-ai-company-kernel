#!/bin/zsh
# 安全地把本地 v1.0 同步到团队远程 public（整合团队已有提交，冲突则中止不破坏）
cd /Users/shift/openclaw/company-kernel || exit 1
LOG=state/sync-team.log
exec > >(tee "$LOG") 2>&1
set -x

git fetch public main
echo "--- 团队远程领先本地的提交（本地没有的）:"
git log --oneline HEAD..public/main || true

echo "--- 尝试 rebase 到 public/main 之上（整合团队提交）"
if git rebase public/main; then
  echo "rebase 成功，推送 main + tag 到 public 和 origin"
  git push public main
  git push -f public v1.0.0
  git push origin main
  git push -f origin v1.0.0
  echo "=== 同步完成 ==="
else
  echo "!!! rebase 有冲突，已自动中止，未做任何破坏。请人工处理或改用 merge。"
  git rebase --abort
fi
set +x
echo "=== 窗口可关闭，日志 state/sync-team.log ==="
