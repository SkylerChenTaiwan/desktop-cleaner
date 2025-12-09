# Desktop Cleaner 研究報告

> Spike Issue: #1
> 研究日期：2025-12-10

## 研究問題

1. Swift 如何取得「下載」和「桌面」的標準路徑
2. Swift 如何判斷檔案的建立/修改時間
3. Swift 如何將檔案移到垃圾桶
4. LaunchAgent plist 如何配置每日定時執行
5. 程式如何安裝到系統中（LaunchAgent 放置位置）
6. 是否需要特殊權限（Full Disk Access）

## 研究發現

### 問題 1：Swift 如何取得「下載」和「桌面」的標準路徑

**調查結果**：

使用 `FileManager` 的 `urls(for:in:)` 方法取得系統標準目錄：

```swift
let fileManager = FileManager.default

// 取得下載資料夾
let downloadsURL = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask)[0]

// 取得桌面資料夾
let desktopURL = fileManager.urls(for: .desktopDirectory, in: .userDomainMask)[0]
```

可以建立便利的擴展：

```swift
extension URL {
    static var downloads: URL {
        return FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
    }

    static var desktop: URL {
        return FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0]
    }
}
```

**結論**：使用 `FileManager.urls(for:in:)` 是跨平台且安全的方式，不需要硬編碼路徑。

**參考來源**：
- [Swift by Sundell - Working with files and folders](https://www.swiftbysundell.com/articles/working-with-files-and-folders-in-swift/)
- [Apple Documentation - FileManager](https://developer.apple.com/documentation/foundation/filemanager)

---

### 問題 2：Swift 如何判斷檔案的建立/修改時間

**調查結果**：

使用 `FileManager.attributesOfItem(atPath:)` 取得檔案屬性：

```swift
func fileModificationDate(url: URL) -> Date? {
    do {
        let attr = try FileManager.default.attributesOfItem(atPath: url.path)
        return attr[FileAttributeKey.modificationDate] as? Date
    } catch {
        return nil
    }
}

func fileCreationDate(url: URL) -> Date? {
    do {
        let attr = try FileManager.default.attributesOfItem(atPath: url.path)
        return attr[FileAttributeKey.creationDate] as? Date
    } catch {
        return nil
    }
}
```

**重要的 FileAttributeKey**：
- `.creationDate` - 檔案建立日期
- `.modificationDate` - 檔案最後修改日期

**結論**：建議使用 `.modificationDate` 來判斷檔案是否超過三天，因為這反映檔案最後被使用的時間。

**參考來源**：
- [Apple Documentation - attributesOfItem(atPath:)](https://developer.apple.com/documentation/foundation/filemanager/1410452-attributesofitem)
- [Apple Documentation - creationDate](https://developer.apple.com/documentation/foundation/fileattributekey/creationdate)

---

### 問題 3：Swift 如何將檔案移到垃圾桶

**調查結果**：

有兩種方式可以將檔案移到垃圾桶：

**方案 A：FileManager.trashItem()** (推薦)

```swift
do {
    var resultingURL: NSURL?
    try FileManager.default.trashItem(at: fileURL, resultingItemURL: &resultingURL)
    print("Moved to trash: \(resultingURL?.path ?? "")")
} catch {
    print("Error moving to trash: \(error)")
}
```

**方案 B：NSWorkspace.recycle()**

```swift
import AppKit

NSWorkspace.shared.recycle([fileURL]) { trashedURLs, error in
    if let error = error {
        print("Error: \(error)")
    } else {
        print("Trashed: \(trashedURLs)")
    }
}
```

**比較**：

| 方案 | 優點 | 缺點 |
|------|------|------|
| FileManager.trashItem | 同步、簡單、不需 AppKit | 需要 Foundation |
| NSWorkspace.recycle | 非同步、可批次處理 | 需要 AppKit、較複雜 |

**已知問題**：
- `trashItem` 有一個已知問題：只有第一個被丟到垃圾桶的檔案可以使用「還原」功能

**結論**：建議使用 `FileManager.trashItem()`，因為它是同步操作且不需要額外的 AppKit 依賴。對於命令列工具來說更加簡潔。

**參考來源**：
- [Apple Documentation - trashItem(at:resultingItemURL:)](https://developer.apple.com/documentation/foundation/filemanager/1414306-trashitem)
- [NotTooBad Software - Move files to trash](https://nottoobadsoftware.com/blog/swiftshell/move-files-to-the-trash/)

---

### 問題 4：LaunchAgent plist 如何配置每日定時執行

**調查結果**：

使用 `StartCalendarInterval` 來設定每日定時執行：

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
        <integer>22</integer>
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

**重要特性**：
- 省略的時間欄位會被視為萬用字元
- 如果電腦在排程時間睡眠，`launchd` 會在喚醒後執行
- 可以使用陣列設定多個執行時間

**結論**：LaunchAgent 是 macOS 推薦的排程方式，比 cron 更可靠且會處理睡眠/喚醒情況。

**參考來源**：
- [alexwlchan - How to run a task on a schedule on macOS](https://alexwlchan.net/til/2025/macos-launchagent-examples/)
- [Apple Documentation - Creating Launch Daemons and Agents](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html)

---

### 問題 5：程式如何安裝到系統中

**調查結果**：

**LaunchAgent 放置位置**：

| 位置 | 用途 | 權限 |
|------|------|------|
| `~/Library/LaunchAgents/` | 只對當前使用者生效 | 使用者 |
| `/Library/LaunchAgents/` | 對所有使用者生效 | 需要 sudo |
| `/System/Library/LaunchAgents/` | 系統使用 | 不要修改 |

**建議安裝流程**：

1. 編譯程式：
```bash
swiftc -O -o desktop-cleaner Sources/main.swift
```

2. 安裝程式：
```bash
cp desktop-cleaner /usr/local/bin/
chmod +x /usr/local/bin/desktop-cleaner
```

3. 安裝 LaunchAgent：
```bash
cp com.user.desktop-cleaner.plist ~/Library/LaunchAgents/
```

4. 載入 LaunchAgent：
```bash
launchctl load ~/Library/LaunchAgents/com.user.desktop-cleaner.plist
```

**plist 檔案權限**：
- 權限應為 644 (`-rw-r--r--`)
- 擁有者應為當前使用者

**結論**：使用者級別的 LaunchAgent 放在 `~/Library/LaunchAgents/`，執行檔放在 `/usr/local/bin/` 或 `~/bin/`。

**參考來源**：
- [iBoysoft - ~/Library/LaunchAgents](https://iboysoft.com/wiki/library-launchagents.html)
- [launchd.info - A launchd Tutorial](https://www.launchd.info/)

---

### 問題 6：是否需要特殊權限（Full Disk Access）

**調查結果**：

**TCC (Transparency, Consent, and Control)**：
- macOS 10.14 (Mojave) 開始，Downloads 和 Desktop 資料夾受到 TCC 保護
- 未經授權的應用程式無法存取這些資料夾

**命令列工具的權限繼承**：
- 如果透過 Terminal 執行，工具會繼承 Terminal 的權限
- 如果透過 LaunchAgent 執行，工具需要自己的權限

**解決方案**：

**方案 A：授予 Full Disk Access 給執行檔**
1. 系統設定 > 隱私與安全性 > Full Disk Access
2. 點擊 + 號，選擇 `/usr/local/bin/desktop-cleaner`
3. 啟用該執行檔的存取權限

**方案 B：授予 Full Disk Access 給 Terminal**
- 這會讓所有透過 Terminal 執行的程式都有完整磁碟存取權限
- 安全性較低，不建議

**重要注意事項**：
- Full Disk Access 不會彈出提示請求權限，使用者必須手動授予
- 首次執行時如果沒有權限，程式會因為無法存取資料夾而失敗

**結論**：需要將編譯好的執行檔加入「Full Disk Access」權限清單，否則無法存取 Downloads 和 Desktop 資料夾。

**參考來源**：
- [lapcatsoftware - Full Disk Access](https://lapcatsoftware.com/articles/FullDiskAccess.html)
- [Apple Developer Forums - How to grant command line tools full disk access](https://developer.apple.com/forums/thread/756510)

---

## 方案比較

| 方案 | 優點 | 缺點 | 複雜度 |
|------|------|------|--------|
| 純命令列工具 + LaunchAgent | 簡單、輕量、不需要 GUI | 需要手動授予權限 | 低 |
| macOS App + LaunchAgent | 可以有 UI 設定、App Store 發布 | 開發複雜、需要簽名 | 高 |
| 使用現有工具 (如 Hazel) | 功能強大、GUI 設定 | 需要付費、非自製 | N/A |

## 建議方案

基於以上研究，建議採用 **純命令列工具 + LaunchAgent** 方案，原因：

1. **簡單直接**：符合專案目標，不需要複雜的 GUI
2. **輕量**：編譯後的執行檔很小，不佔用系統資源
3. **可靠**：LaunchAgent 是 Apple 推薦的排程方式
4. **易於維護**：程式碼簡單，容易除錯和修改

## 技術架構建議

```
desktop-cleaner/
├── Sources/
│   └── main.swift          # 主程式
├── LaunchAgent/
│   └── com.user.desktop-cleaner.plist
├── install.sh              # 安裝腳本
├── uninstall.sh            # 移除腳本
└── README.md               # 使用說明
```

## 待確認事項（已確認）

- [x] 確認使用者希望使用「修改時間」還是「建立時間」來判斷檔案年齡 → **使用修改時間**
- [x] 確認每日執行時間（目前設定 22:00）→ **23:00**
- [x] 是否需要記錄刪除的檔案清單 → **不需要**

## 下一步

研究完成後，可以執行 `/design #1` 進行技術設計
