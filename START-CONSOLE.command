#!/bin/zsh
# 启动 Company Kernel 控制台（端口 8788，独立于旧 8765 网关）
LOG=/Users/shift/openclaw/company-kernel/state/start-console.log
exec > >(tee "$LOG") 2>&1
set -x
cd /Users/shift/openclaw/company-kernel || exit 1

LABEL="ai.openclaw.company-kernel.console"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

# 写 launchd plist（KeepAlive，开机自启）
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/Users/shift/openclaw/company-kernel/bin/company-api-gateway</string>
    <string>--host</string><string>0.0.0.0</string>
    <string>--port</string><string>8788</string>
    <string>--quiet</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>OPENCLAW_COMPANY_KERNEL_ROOT</key><string>/Users/shift/openclaw/company-kernel</string>
    <key>PATH</key><string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
  </dict>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>/Users/shift/openclaw/company-kernel/logs/console.launchd.out.log</string>
  <key>StandardErrorPath</key><string>/Users/shift/openclaw/company-kernel/logs/console.launchd.err.log</string>
</dict>
</plist>
EOF

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
sleep 1
launchctl bootstrap "gui/$(id -u)" "$PLIST"
sleep 2

echo "--- 验收（应输出 <!DOCTYPE html）:"
curl -s http://127.0.0.1:8788/ | head -c 60; echo
set +x
echo ""
echo "=== 完成。控制台地址: http://127.0.0.1:8788/ 或 http://192.168.3.88:8788/  日志: $LOG ==="
