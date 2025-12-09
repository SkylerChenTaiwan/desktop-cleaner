#!/bin/bash
set -e

# 設定
APP_NAME="DesktopCleaner"
BUNDLE_NAME="${APP_NAME}.app"
INSTALL_DIR="${HOME}/Applications"
LAUNCH_AGENTS_DIR="${HOME}/Library/LaunchAgents"
PLIST_NAME="com.user.desktop-cleaner.plist"

echo "=== Desktop Cleaner 卸載腳本 ==="

# 1. 卸載 LaunchAgent
echo "[1/3] 卸載 LaunchAgent..."
if launchctl list | grep -q "com.user.desktop-cleaner"; then
    launchctl unload "${LAUNCH_AGENTS_DIR}/${PLIST_NAME}" 2>/dev/null || true
fi
rm -f "${LAUNCH_AGENTS_DIR}/${PLIST_NAME}"

# 2. 移除 App Bundle
echo "[2/3] 移除 App Bundle..."
rm -rf "${INSTALL_DIR}/${BUNDLE_NAME}"

# 3. 移除舊版 CLI（如果存在）
echo "[3/3] 清理舊版安裝..."
rm -f "/usr/local/bin/desktop-cleaner" 2>/dev/null || true

echo ""
echo "=== 卸載完成 ==="
echo ""
echo "注意：日誌檔案保留在 /tmp/desktop-cleaner*.log"
echo "如需移除，請執行：rm /tmp/desktop-cleaner*.log"
