# macOS App Bundle 打包設計規格

> Spike Issue: #13
> 建立日期：2025-12-10
> 最後更新：2025-12-10

## 功能概述

### 目標

將 Desktop Cleaner 從 CLI 工具打包成標準 macOS App Bundle（.app），讓：
1. 使用者可以在「系統設定 → 隱私權與安全性」中授予權限
2. 程式能夠存取 ~/Desktop 和 ~/Downloads 資料夾
3. LaunchAgent 可以正常呼叫 .app 內的執行檔

### 非目標

- 不建立 GUI 介面（保持 CLI 運作模式）
- 不提交 Mac App Store
- 不使用付費 Developer ID 簽名
- 不使用 Xcode 專案（保持 SPM 結構）

## 技術方案

根據研究報告，採用 **手動建立 Bundle** 方案：

| 項目 | 決策 |
|------|------|
| 打包方式 | Shell script 手動建立 |
| 簽名方式 | Ad-hoc signing（免費） |
| 安裝位置 | `~/Applications/`（使用者層級） |
| 執行方式 | LaunchAgent 呼叫 .app/Contents/MacOS/DesktopCleaner |

## App Bundle 結構

```
DesktopCleaner.app/
└── Contents/
    ├── Info.plist              # Bundle 設定
    ├── MacOS/
    │   └── DesktopCleaner      # 執行檔
    └── Resources/              # （保留，未來放圖示）
        └── .gitkeep
```

## Info.plist 設定

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Bundle 識別 -->
    <key>CFBundleIdentifier</key>
    <string>com.user.desktop-cleaner</string>

    <key>CFBundleName</key>
    <string>DesktopCleaner</string>

    <key>CFBundleDisplayName</key>
    <string>Desktop Cleaner</string>

    <!-- 執行檔名稱 -->
    <key>CFBundleExecutable</key>
    <string>DesktopCleaner</string>

    <!-- 版本資訊 -->
    <key>CFBundleVersion</key>
    <string>1.0.0</string>

    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>

    <!-- Bundle 類型 -->
    <key>CFBundlePackageType</key>
    <string>APPL</string>

    <!-- 最低系統版本 -->
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>

    <!-- 隱私權描述（觸發權限請求對話框） -->
    <key>NSDesktopFolderUsageDescription</key>
    <string>Desktop Cleaner 需要存取桌面資料夾以清理超過三天的檔案。</string>

    <key>NSDownloadsFolderUsageDescription</key>
    <string>Desktop Cleaner 需要存取下載資料夾以清理超過三天的檔案。</string>

    <!-- 背景執行（無 Dock 圖示、無選單列） -->
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
```

## LaunchAgent 更新

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.desktop-cleaner</string>

    <key>ProgramArguments</key>
    <array>
        <!-- 指向 App Bundle 內的執行檔 -->
        <string>$HOME/Applications/DesktopCleaner.app/Contents/MacOS/DesktopCleaner</string>
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
```

**注意**：LaunchAgent plist 不支援 `$HOME` 環境變數展開，需要在安裝腳本中動態替換為實際路徑。

## 新增檔案

### 1. Resources/Info.plist

Info.plist 範本檔案（見上方）。

### 2. scripts/build.sh

打包腳本：

```bash
#!/bin/bash
set -e

# 設定
APP_NAME="DesktopCleaner"
BUNDLE_NAME="${APP_NAME}.app"
BUILD_DIR=".build/release"
OUTPUT_DIR="dist"

echo "=== Desktop Cleaner 打包腳本 ==="

# 1. 編譯 Release 版本
echo "[1/4] 編譯中..."
swift build -c release

# 2. 建立 Bundle 結構
echo "[2/4] 建立 App Bundle..."
rm -rf "${OUTPUT_DIR}/${BUNDLE_NAME}"
mkdir -p "${OUTPUT_DIR}/${BUNDLE_NAME}/Contents/MacOS"
mkdir -p "${OUTPUT_DIR}/${BUNDLE_NAME}/Contents/Resources"

# 3. 複製檔案
echo "[3/4] 複製檔案..."
cp "${BUILD_DIR}/${APP_NAME}" "${OUTPUT_DIR}/${BUNDLE_NAME}/Contents/MacOS/"
cp "Resources/Info.plist" "${OUTPUT_DIR}/${BUNDLE_NAME}/Contents/"

# 4. 簽名
echo "[4/4] 簽名中..."
codesign --sign - --force --deep "${OUTPUT_DIR}/${BUNDLE_NAME}"

echo ""
echo "=== 打包完成 ==="
echo "App Bundle: ${OUTPUT_DIR}/${BUNDLE_NAME}"
echo ""
echo "下一步：執行 ./scripts/install.sh 安裝"
```

### 3. scripts/install.sh

安裝腳本：

```bash
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
```

### 4. scripts/uninstall.sh

卸載腳本：

```bash
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
```

## 目錄結構變更

```
desktop-cleaner/
├── Sources/                    # （不變）Swift 原始碼
├── LaunchAgent/                # （移除）不再需要
├── Resources/                  # （新增）App Bundle 資源
│   └── Info.plist
├── scripts/                    # （新增）打包和安裝腳本
│   ├── build.sh
│   ├── install.sh
│   └── uninstall.sh
├── dist/                       # （新增，git ignore）打包輸出
│   └── DesktopCleaner.app/
├── STATE/                      # （不變）
└── Package.swift               # （不變）
```

## 流程說明

### 開發流程

```
1. 修改程式碼
2. swift build               # 開發時測試
3. ./scripts/build.sh        # 打包成 .app
4. ./scripts/install.sh      # 安裝到 ~/Applications
```

### 使用者安裝流程

```
1. 下載專案
2. 執行 ./scripts/build.sh
3. 執行 ./scripts/install.sh
4. 手動授權「完整磁碟取用權限」
5. 測試：~/Applications/DesktopCleaner.app/Contents/MacOS/DesktopCleaner --dry-run
```

## 測試策略

### 單元測試

現有測試不受影響，持續使用 `swift build && .build/debug/TestRunner`。

### 整合測試

新增打包流程測試：

| 測試案例 | 驗收條件 |
|----------|----------|
| build.sh 執行成功 | 產生 dist/DesktopCleaner.app |
| Bundle 結構正確 | Contents/MacOS/DesktopCleaner 存在且可執行 |
| Info.plist 有效 | 包含必要 key（CFBundleIdentifier 等） |
| 簽名有效 | `codesign -v` 驗證通過 |
| install.sh 執行成功 | ~/Applications/DesktopCleaner.app 存在 |
| LaunchAgent 載入成功 | `launchctl list` 包含 com.user.desktop-cleaner |
| --dry-run 可執行 | 程式正常輸出，無權限錯誤 |
| uninstall.sh 執行成功 | App 和 LaunchAgent 移除 |

### E2E 測試

手動測試流程：

1. 執行完整安裝流程
2. 授權「完整磁碟取用權限」
3. 在 ~/Downloads 建立測試檔案（修改日期超過 3 天）
4. 執行 `--dry-run` 確認檔案被偵測
5. 執行實際清理
6. 確認檔案移至垃圾桶

## 實作分工建議

| 任務 | 範圍 | 依賴 | 可平行 |
|------|------|------|--------|
| 建立 Resources/Info.plist | 設定檔 | 無 | 是 |
| 建立 scripts/build.sh | 腳本 | 無 | 是 |
| 建立 scripts/install.sh | 腳本 | 無 | 是 |
| 建立 scripts/uninstall.sh | 腳本 | 無 | 是 |
| 更新 .gitignore | 設定 | 無 | 是 |
| 移除 LaunchAgent/ 目錄 | 清理 | scripts 完成後 | 否 |
| 更新 README 安裝說明 | 文件 | scripts 完成後 | 否 |
| 整合測試 | 測試 | 全部完成後 | 否 |

## 風險與緩解

| 風險 | 影響 | 緩解措施 |
|------|------|----------|
| 權限授權後仍無法存取 | 功能失效 | 提供故障排除文件，建議重新載入 LaunchAgent |
| Ad-hoc 簽名在其他 Mac 警告 | 使用者體驗差 | README 說明如何允許執行 |
| ~/Applications 不存在 | 安裝失敗 | 腳本自動建立目錄 |

## 待確認事項

已解決：
- [x] 安裝位置：`~/Applications/`（使用者層級，無需 sudo）
- [x] 是否需要安裝/卸載腳本：是，提供完整腳本

## 下一步

執行 `/breakdown #13` 將此設計拆分為實作任務。
