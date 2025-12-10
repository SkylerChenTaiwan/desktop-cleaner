# 系統總覽

> 最後更新：2025-12-10

## 專案簡介

**專案名稱**：Desktop Cleaner
**專案描述**：macOS 自動清理工具，每天定時將「下載」資料夾和「桌面」上超過三天的檔案移到垃圾桶。

## 技術棧

| 層級 | 技術 |
|------|------|
| 程式語言 | Swift |
| 打包格式 | macOS App Bundle (.app) |
| 排程機制 | macOS LaunchAgent |
| 目標平台 | macOS 13.0+ |

## 專案結構

```
desktop-cleaner/
├── Sources/                    # Swift 原始碼
│   └── DesktopCleaner/
├── Resources/                  # App Bundle 資源
│   └── Info.plist              # Bundle 設定檔
├── scripts/                    # 打包和安裝腳本
│   ├── build.sh                # 編譯並打包成 .app
│   ├── install.sh              # 安裝到 ~/Applications
│   └── uninstall.sh            # 卸載腳本
├── dist/                       # 打包輸出（git ignored）
│   └── DesktopCleaner.app/
├── STATE/                      # 專案狀態文件
├── .snapshots/                 # 程式碼結構快照
└── Package.swift               # Swift Package Manager 設定
```

## 安裝位置

| 項目 | 路徑 |
|------|------|
| App Bundle | `~/Applications/DesktopCleaner.app` |
| 執行檔 | `~/Applications/DesktopCleaner.app/Contents/MacOS/DesktopCleaner` |
| LaunchAgent | `~/Library/LaunchAgents/com.user.desktop-cleaner.plist` |
| 日誌檔案 | `/tmp/desktop-cleaner.log`, `/tmp/desktop-cleaner.error.log` |

## 核心功能

| 功能 | 說明 |
|------|------|
| 定時執行 | 每天 23:00 自動執行 |
| 掃描資料夾 | 檢查「下載」和「桌面」資料夾 |
| 時間判斷 | 找出超過 72 小時（三天）的檔案 |
| 安全刪除 | 將檔案移到垃圾桶（可救回） |

## 開發指引

### 環境需求

- macOS 13.0+
- Xcode 15.0+
- Swift 5.9+

### 開發流程

1. 閱讀 `CLAUDE.md` 了解開發規範
2. 使用 `/plan` 開始規劃任務
3. 使用 `/impl` 實作功能
4. 使用 `/check` 驗證實作
5. 使用 `/close` 完成 merge

### 打包流程

```bash
# 1. 開發時編譯測試
swift build

# 2. 打包成 App Bundle
./scripts/build.sh

# 3. 安裝到系統
./scripts/install.sh

# 4. 授權「完整磁碟取用權限」（手動）
```
