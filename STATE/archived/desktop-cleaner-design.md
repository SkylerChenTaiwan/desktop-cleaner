# Desktop Cleaner 設計規格

> Spike Issue: #1
> 建立日期：2025-12-10
> 最後更新：2025-12-10

## 功能概述

### 目標

做完後系統會有一個 macOS 命令列工具，具備以下功能：

1. **自動掃描**：檢查「下載」和「桌面」資料夾中的所有檔案
2. **時間判斷**：識別修改時間超過 72 小時（三天）的檔案
3. **安全刪除**：將符合條件的檔案移到垃圾桶（可救回）
4. **定時執行**：透過 LaunchAgent 每天 23:00 自動執行

### 非目標

這次不做：
- GUI 介面
- 設定檔（執行時間、清理天數等）
- 排除規則（所有超過三天的檔案都會清理）
- 日誌記錄系統
- 通知功能

---

## 資料結構

### FileInfo 結構

```swift
struct FileInfo {
    let url: URL           // 檔案路徑
    let modificationDate: Date  // 最後修改時間
    let isDirectory: Bool  // 是否為資料夾
}
```

### CleanResult 結構

```swift
struct CleanResult {
    let trashedFiles: [URL]   // 已移到垃圾桶的檔案
    let errors: [Error]       // 處理過程中的錯誤
}
```

---

## 模組設計

### 模組架構圖

```
┌─────────────────────────────────────────────┐
│                   main.swift                 │
│            (程式進入點、執行流程)              │
└─────────────────────┬───────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────┐
│               DesktopCleaner                 │
│           (清理邏輯協調器)                    │
├─────────────────────────────────────────────┤
│ + clean() -> CleanResult                     │
│ + cleanDirectory(at: URL) -> [URL]           │
└─────────────────────┬───────────────────────┘
                      │
        ┌─────────────┴─────────────┐
        ▼                           ▼
┌───────────────────┐     ┌───────────────────┐
│   FileScanner     │     │    FileTrash      │
│  (檔案掃描)        │     │   (垃圾桶操作)     │
├───────────────────┤     ├───────────────────┤
│ + scan(at: URL)   │     │ + trash(at: URL)  │
│   -> [FileInfo]   │     │   -> Bool         │
└───────────────────┘     └───────────────────┘
```

### 模組說明

| 模組 | 職責 | 檔案 |
|------|------|------|
| main | 程式進入點，執行清理流程 | `Sources/DesktopCleaner/main.swift` |
| DesktopCleaner | 協調清理邏輯，整合掃描和刪除 | `Sources/DesktopCleaner/DesktopCleaner.swift` |
| FileScanner | 掃描資料夾，取得檔案資訊 | `Sources/DesktopCleaner/FileScanner.swift` |
| FileTrash | 將檔案移到垃圾桶 | `Sources/DesktopCleaner/FileTrash.swift` |

---

## 流程說明

### 主要流程

```
1. 程式啟動
   │
2. 取得「下載」和「桌面」資料夾路徑
   │
3. ┌─────────────────────────────────────┐
   │ 對每個資料夾執行：                   │
   │ 3.1 掃描資料夾內所有檔案              │
   │ 3.2 過濾出修改時間超過 72 小時的檔案  │
   │ 3.3 將符合條件的檔案移到垃圾桶        │
   └─────────────────────────────────────┘
   │
4. 輸出處理結果
   │
5. 程式結束
```

### 詳細流程

```swift
// main.swift 執行流程
func main() {
    let cleaner = DesktopCleaner()
    let result = cleaner.clean()

    // 輸出結果
    print("清理完成")
    print("已移到垃圾桶：\(result.trashedFiles.count) 個檔案")

    if !result.errors.isEmpty {
        print("錯誤：\(result.errors.count) 個")
    }
}
```

---

## 核心邏輯

### 1. 取得目標資料夾

```swift
extension URL {
    static var downloads: URL {
        FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
    }

    static var desktop: URL {
        FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0]
    }
}
```

### 2. 掃描檔案

```swift
class FileScanner {
    func scan(at directory: URL) -> [FileInfo] {
        let fileManager = FileManager.default

        guard let contents = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return contents.compactMap { url in
            guard let attributes = try? url.resourceValues(forKeys: [.contentModificationDateKey, .isDirectoryKey]),
                  let modificationDate = attributes.contentModificationDate,
                  let isDirectory = attributes.isDirectory else {
                return nil
            }

            return FileInfo(url: url, modificationDate: modificationDate, isDirectory: isDirectory)
        }
    }
}
```

### 3. 判斷是否超過三天

```swift
extension FileInfo {
    var isOlderThanThreeDays: Bool {
        let threeDaysAgo = Calendar.current.date(byAdding: .hour, value: -72, to: Date()) ?? Date()
        return modificationDate < threeDaysAgo
    }
}
```

### 4. 移到垃圾桶

```swift
class FileTrash {
    func trash(at url: URL) -> Bool {
        do {
            try FileManager.default.trashItem(at: url, resultingItemURL: nil)
            return true
        } catch {
            print("Error trashing \(url.lastPathComponent): \(error)")
            return false
        }
    }
}
```

---

## LaunchAgent 設定

### plist 檔案

**檔案位置**：`LaunchAgent/com.user.desktop-cleaner.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.desktop-cleaner</string>

    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/desktop-cleaner</string>
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

---

## 安裝與設定

### 安裝腳本

**檔案位置**：`install.sh`

```bash
#!/bin/bash
set -e

echo "Building desktop-cleaner..."
swiftc -O -o desktop-cleaner Sources/DesktopCleaner/*.swift

echo "Installing to /usr/local/bin..."
sudo cp desktop-cleaner /usr/local/bin/
sudo chmod +x /usr/local/bin/desktop-cleaner

echo "Installing LaunchAgent..."
cp LaunchAgent/com.user.desktop-cleaner.plist ~/Library/LaunchAgents/

echo "Loading LaunchAgent..."
launchctl load ~/Library/LaunchAgents/com.user.desktop-cleaner.plist

echo ""
echo "Installation complete!"
echo ""
echo "IMPORTANT: You need to grant Full Disk Access to /usr/local/bin/desktop-cleaner"
echo "1. Open System Settings > Privacy & Security > Full Disk Access"
echo "2. Click '+' and add /usr/local/bin/desktop-cleaner"
echo "3. Enable the toggle"
```

### 移除腳本

**檔案位置**：`uninstall.sh`

```bash
#!/bin/bash
set -e

echo "Unloading LaunchAgent..."
launchctl unload ~/Library/LaunchAgents/com.user.desktop-cleaner.plist 2>/dev/null || true

echo "Removing LaunchAgent..."
rm -f ~/Library/LaunchAgents/com.user.desktop-cleaner.plist

echo "Removing executable..."
sudo rm -f /usr/local/bin/desktop-cleaner

echo "Uninstallation complete!"
```

---

## 測試策略

### 單元測試

| 測試檔案 | 測試內容 |
|---------|---------|
| `Tests/FileScannerTests.swift` | 測試檔案掃描功能 |
| `Tests/FileTrashTests.swift` | 測試垃圾桶功能 |
| `Tests/DesktopCleanerTests.swift` | 測試整體清理邏輯 |

### 單元測試案例

#### FileScannerTests

| 測試案例 | 輸入 | 預期輸出 |
|---------|------|---------|
| 掃描空資料夾 | 空目錄 | 空陣列 |
| 掃描有檔案的資料夾 | 含 3 個檔案的目錄 | 3 個 FileInfo |
| 跳過隱藏檔案 | 含 `.DS_Store` 的目錄 | 不包含隱藏檔案 |
| 處理不存在的資料夾 | 不存在的路徑 | 空陣列 |

#### FileTrashTests

| 測試案例 | 輸入 | 預期輸出 |
|---------|------|---------|
| 成功移到垃圾桶 | 存在的檔案 | true，檔案不存在原位置 |
| 處理不存在的檔案 | 不存在的檔案 | false |

#### DesktopCleanerTests

| 測試案例 | 輸入 | 預期輸出 |
|---------|------|---------|
| 清理超過三天的檔案 | 含舊檔案的目錄 | 舊檔案被移到垃圾桶 |
| 保留三天內的檔案 | 含新檔案的目錄 | 新檔案保持不動 |
| 處理空資料夾 | 空目錄 | 空的 CleanResult |

### 整合測試

| 測試案例 | 描述 |
|---------|------|
| 完整清理流程 | 建立測試目錄，放入新舊檔案，執行清理，驗證結果 |

---

## 實作分工建議

這個功能可以拆成以下獨立任務：

| # | 任務 | 範圍 | 依賴 | 估計大小 |
|---|------|------|------|---------|
| 1 | 建立專案結構與 FileScanner | scope:backend | 無 | 小 |
| 2 | 實作 FileTrash | scope:backend | 無 | 小 |
| 3 | 實作 DesktopCleaner | scope:backend | #1, #2 | 小 |
| 4 | 實作 main 進入點 | scope:backend | #3 | 小 |
| 5 | 建立 LaunchAgent 和安裝腳本 | scope:chore | #4 | 小 |
| 6 | 撰寫單元測試 | type:test | #1, #2, #3 | 中 |

### 依賴關係圖

```
#1 FileScanner ──┐
                 ├──▶ #3 DesktopCleaner ──▶ #4 main ──▶ #5 LaunchAgent
#2 FileTrash ────┘                            │
                                              ▼
                                         #6 Tests
```

### 可平行開發

- **可平行**：#1 和 #2 可以同時進行
- **序列**：#3 需要等 #1、#2 完成；#4 需要等 #3 完成
- **最後**：#5、#6 在核心功能完成後進行

---

## 驗收條件

### 功能驗收

- [ ] 程式可以正確識別「下載」和「桌面」資料夾
- [ ] 程式可以找出修改時間超過 72 小時的檔案
- [ ] 程式可以將檔案移到垃圾桶
- [ ] 程式執行後輸出處理結果

### 安裝驗收

- [ ] install.sh 可以成功編譯和安裝程式
- [ ] LaunchAgent 可以成功載入
- [ ] 程式在 23:00 自動執行
- [ ] 授予 Full Disk Access 後程式可以正常運作

### 測試驗收

- [ ] 所有單元測試通過
- [ ] 整合測試通過

---

## 權限需求

| 權限 | 原因 | 如何授予 |
|------|------|---------|
| Full Disk Access | 存取「下載」和「桌面」資料夾 | 系統設定 > 隱私與安全性 > Full Disk Access |

---

## 相關文件

| 文件 | 說明 |
|------|------|
| `STATE/developing/research-desktop-cleaner.md` | 技術研究報告 |
| `STATE/overview.md` | 系統總覽 |
