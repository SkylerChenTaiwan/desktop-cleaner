# 當前任務

## Issue
#15 - 建立 App Bundle 打包基礎設施

## 引用的規格
STATE/developing/app-bundle-design.md

## Checkpoint
- [x] 建立 Resources/Info.plist
- [x] 建立 scripts/build.sh
- [x] 建立 scripts/install.sh
- [x] 建立 scripts/uninstall.sh
- [x] 更新 .gitignore（已有 dist/）
- [x] 移除 LaunchAgent/ 目錄
- [x] 測試 build.sh - 通過

## 驗證結果
- [x] build.sh 執行成功，產生 dist/DesktopCleaner.app
- [x] Bundle 結構正確（Contents/MacOS/DesktopCleaner 存在）
- [x] Info.plist 包含必要設定（CFBundleIdentifier, NS*UsageDescription）
- [x] codesign -v 驗證通過
- [x] --dry-run 可正常執行

## 狀態
實作完成，待 /check 驗證
