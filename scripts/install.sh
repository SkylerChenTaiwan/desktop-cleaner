#!/bin/bash
set -e

# 設定
APP_NAME="DesktopCleaner"
BUNDLE_NAME="${APP_NAME}.app"
SOURCE_DIR="dist"
INSTALL_DIR="${HOME}/Applications"
LAUNCH_AGENTS_DIR="${HOME}/Library/LaunchAgents"
PLIST_NAME="com.user.desktop-cleaner.plist"

echo "=== Desktop Cleaner 安裝腳本 ==="

# 檢查 App Bundle 是否存在
if [ ! -d "${SOURCE_DIR}/${BUNDLE_NAME}" ]; then
    echo "錯誤：找不到 ${SOURCE_DIR}/${BUNDLE_NAME}"
    echo "請先執行 ./scripts/build.sh"
    exit 1
fi

# 1. 卸載現有 LaunchAgent（如果存在）
echo "[1/5] 卸載現有 LaunchAgent..."
if launchctl list | grep -q "com.user.desktop-cleaner"; then
    launchctl unload "${LAUNCH_AGENTS_DIR}/${PLIST_NAME}" 2>/dev/null || true
fi

# 2. 移除舊版安裝
echo "[2/5] 移除舊版..."
rm -rf "${INSTALL_DIR}/${BUNDLE_NAME}"
rm -f "/usr/local/bin/desktop-cleaner" 2>/dev/null || true

# 3. 安裝 App Bundle
echo "[3/5] 安裝 App Bundle..."
mkdir -p "${INSTALL_DIR}"
cp -r "${SOURCE_DIR}/${BUNDLE_NAME}" "${INSTALL_DIR}/"

# 4. 安裝並設定 LaunchAgent
echo "[4/5] 設定 LaunchAgent..."
mkdir -p "${LAUNCH_AGENTS_DIR}"

# 動態生成 plist，替換 $HOME 為實際路徑
EXECUTABLE_PATH="${INSTALL_DIR}/${BUNDLE_NAME}/Contents/MacOS/${APP_NAME}"
cat > "${LAUNCH_AGENTS_DIR}/${PLIST_NAME}" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.desktop-cleaner</string>

    <key>ProgramArguments</key>
    <array>
        <string>${EXECUTABLE_PATH}</string>
    </array>

    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>23</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>

    <key>StandardOutPath</key>
    <string>/tmp/desktop-cleaner.log</string>

    <key>StandardErrorPath</key>
    <string>/tmp/desktop-cleaner.error.log</string>
</dict>
</plist>
EOF

# 5. 載入 LaunchAgent
echo "[5/5] 載入 LaunchAgent..."
launchctl load "${LAUNCH_AGENTS_DIR}/${PLIST_NAME}"

echo ""
echo "=== 安裝完成 ==="
echo ""
echo "重要：請手動授權檔案存取權限"
echo ""
echo "步驟："
echo "1. 開啟「系統設定」"
echo "2. 前往「隱私權與安全性 → 完整磁碟取用權限」"
echo "3. 點擊「+」按鈕"
echo "4. 選擇 ${INSTALL_DIR}/${BUNDLE_NAME}"
echo "5. 授權後重新載入 LaunchAgent："
echo "   launchctl unload ${LAUNCH_AGENTS_DIR}/${PLIST_NAME}"
echo "   launchctl load ${LAUNCH_AGENTS_DIR}/${PLIST_NAME}"
echo ""
echo "測試執行："
echo "  ${EXECUTABLE_PATH} --dry-run"
