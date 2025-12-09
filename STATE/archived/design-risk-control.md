# 風險控制機制設計規格

> Spike Issue: #6
> 建立日期：2024-12-10
> 最後更新：2024-12-10

## 功能概述

### 目標

為 Desktop Cleaner 增加風險控制機制，提升安全性和透明度：

1. **Symlink 安全處理** - 確保不會透過 symlink 刪除範圍外的檔案
2. **Dry-Run 預覽模式** - 執行前可預覽會刪除什麼
3. **執行日誌** - 記錄每次執行的詳細資訊
4. **macOS 通知** - 每次執行後顯示通知

### 非目標

- ~~排除清單功能~~ - 暫不實作，使用者可將重要檔案移到其他位置
- ~~自訂執行時間~~ - 保持簡單，固定 23:00 執行
- ~~自訂保留天數~~ - 保持簡單，固定 72 小時

---

## 功能詳細設計

### 功能 1：Symlink 安全處理

**目標**：確保 symlink 的處理方式安全

**現況分析**：

根據 Apple 文件，`FileManager.trashItem()` 對 symlink 的行為是：
- 移動 symlink 本身到垃圾桶
- **不會**跟隨 symlink 刪除目標檔案

**設計決策**：

現有行為已經安全，只需新增測試確認：

```swift
// 新增測試確認 symlink 行為
TestFramework.runTest("Symlink 應該移動連結本身而非目標") {
    // 建立目標檔案（在測試目錄外）
    let targetFile = tempDir.appendingPathComponent("target.txt")
    // 建立 symlink（在掃描目錄內，指向目標）
    let symlink = testDir.appendingPathComponent("link.txt")

    // 清理後：
    // - symlink 應該被移除
    // - 目標檔案應該保留
}
```

**驗收條件**：
- [ ] 新增 symlink 測試案例
- [ ] 測試通過，確認 symlink 本身被移動而非目標

---

### 功能 2：Dry-Run 預覽模式

**目標**：讓使用者在執行前預覽會刪除什麼檔案

**CLI 介面**：

```bash
# 正常執行（現有行為）
desktop-cleaner

# 預覽模式（只顯示，不刪除）
desktop-cleaner --dry-run
```

**輸出格式**：

```
[Dry-Run 模式] 以下檔案將會被清理：

Downloads:
  - old-file.zip (5 天前)
  - document.pdf (4 天前)

Desktop:
  - screenshot.png (3 天前)

共 3 個檔案將被移到垃圾桶
（使用 desktop-cleaner 實際執行清理）
```

**程式架構變更**：

```swift
// main.swift
let arguments = CommandLine.arguments
let isDryRun = arguments.contains("--dry-run")

let cleaner = DesktopCleaner()

if isDryRun {
    let preview = cleaner.preview()  // 新增方法
    // 顯示預覽結果
} else {
    let result = cleaner.clean()
    // 現有邏輯
}
```

```swift
// DesktopCleaner.swift
public struct PreviewResult {
    public let filesToTrash: [FileInfo]
    public let downloads: [FileInfo]
    public let desktop: [FileInfo]
}

public func preview() -> PreviewResult {
    let downloadFiles = scanner.scan(at: .downloads)
        .filter { $0.isOlderThanThreeDays }
    let desktopFiles = scanner.scan(at: .desktop)
        .filter { $0.isOlderThanThreeDays }

    return PreviewResult(
        filesToTrash: downloadFiles + desktopFiles,
        downloads: downloadFiles,
        desktop: desktopFiles
    )
}
```

**驗收條件**：
- [ ] `--dry-run` 參數正確解析
- [ ] 預覽模式不會實際刪除檔案
- [ ] 輸出格式清晰易讀
- [ ] 顯示每個檔案的檔齡

---

### 功能 3：執行日誌

**目標**：記錄每次執行的詳細資訊，方便追溯

**日誌位置**：

```
~/.desktop-cleaner/logs/
├── 2024-12-10.log
├── 2024-12-11.log
└── ...
```

**日誌格式**（JSON Lines）：

```json
{"timestamp":"2024-12-10T23:00:05+08:00","action":"start","version":"1.0.0"}
{"timestamp":"2024-12-10T23:00:05+08:00","action":"scan","directory":"Downloads","found":15,"old":3}
{"timestamp":"2024-12-10T23:00:05+08:00","action":"scan","directory":"Desktop","found":8,"old":2}
{"timestamp":"2024-12-10T23:00:06+08:00","action":"trash","file":"old-file.zip","directory":"Downloads","age_hours":120}
{"timestamp":"2024-12-10T23:00:06+08:00","action":"trash","file":"document.pdf","directory":"Downloads","age_hours":96}
{"timestamp":"2024-12-10T23:00:06+08:00","action":"error","file":"locked.txt","error":"Permission denied"}
{"timestamp":"2024-12-10T23:00:07+08:00","action":"complete","trashed":5,"errors":1,"duration_ms":1523}
```

**程式架構**：

```swift
// Logger.swift（新增）
public class Logger {
    private let logDirectory: URL

    public init() {
        logDirectory = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".desktop-cleaner/logs")
    }

    public func log(_ entry: LogEntry) { ... }
    public func cleanup(retentionDays: Int = 30) { ... }
}

public struct LogEntry: Encodable {
    let timestamp: Date
    let action: String
    // ... 其他欄位
}
```

**日誌清理**：

- 每次執行時自動清理超過 30 天的日誌
- 在程式結束前執行

**驗收條件**：
- [ ] 日誌目錄自動建立
- [ ] 每次執行產生正確的日誌
- [ ] 超過 30 天的日誌自動清理
- [ ] JSON 格式正確可解析

---

### 功能 4：macOS 通知

**目標**：每次執行後透過 macOS 通知中心顯示結果

**通知內容**：

| 情況 | 標題 | 內容 |
|------|------|------|
| 有清理 | Desktop Cleaner | 已清理 5 個檔案 |
| 無清理 | Desktop Cleaner | 沒有需要清理的檔案 |
| 有錯誤 | Desktop Cleaner | 已清理 3 個檔案，1 個錯誤 |

**實作方式**：

使用 `osascript` 呼叫 AppleScript 顯示通知：

```swift
// Notifier.swift（新增）
public class Notifier {
    public func notify(title: String, message: String) {
        let script = """
        display notification "\(message)" with title "\(title)"
        """
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        try? process.run()
        process.waitUntilExit()
    }
}
```

**驗收條件**：
- [ ] 每次執行後顯示通知
- [ ] 通知內容正確反映執行結果
- [ ] Dry-run 模式不顯示通知

---

## 測試策略

### 新增單元測試

| 測試檔案 | 測試案例 |
|---------|---------|
| `SymlinkTests.swift` | Symlink 移動本身而非目標 |
| `DryRunTests.swift` | preview() 不會刪除檔案 |
| `LoggerTests.swift` | 日誌格式正確、清理邏輯正確 |
| `NotifierTests.swift` | 通知訊息格式正確 |

### 新增整合測試

| 測試案例 | 驗證內容 |
|---------|---------|
| Dry-run 完整流程 | CLI --dry-run 參數到輸出 |
| 日誌完整流程 | 執行後日誌檔案正確產生 |

---

## 實作分工建議

這個功能可以拆成以下獨立任務：

| Issue | 任務 | 依賴 | 估計測試數 |
|-------|------|------|-----------|
| #7 | Symlink 安全測試 | 無 | 2 |
| #8 | Dry-Run 預覽模式 | 無 | 4 |
| #9 | 執行日誌功能 | 無 | 4 |
| #10 | macOS 通知功能 | 無 | 2 |

所有任務可平行開發，最後整合到 main.swift。

---

## 檔案變更摘要

### 新增檔案

| 檔案 | 說明 |
|------|------|
| `Sources/DesktopCleanerLib/Logger.swift` | 日誌功能 |
| `Sources/DesktopCleanerLib/Notifier.swift` | 通知功能 |
| `Sources/TestRunner/SymlinkTests.swift` | Symlink 測試 |
| `Sources/TestRunner/DryRunTests.swift` | Dry-run 測試 |
| `Sources/TestRunner/LoggerTests.swift` | 日誌測試 |

### 修改檔案

| 檔案 | 變更 |
|------|------|
| `Sources/DesktopCleaner/main.swift` | 新增 CLI 參數解析、整合日誌和通知 |
| `Sources/DesktopCleanerLib/DesktopCleaner.swift` | 新增 preview() 方法 |
| `Sources/DesktopCleanerLib/Models.swift` | 新增 PreviewResult 結構 |
| `Sources/TestRunner/main.swift` | 載入新測試套件 |

---

## 風險評估

| 風險 | 影響 | 緩解措施 |
|------|------|---------|
| osascript 不可用 | 通知無法顯示 | 捕捉錯誤，不影響主流程 |
| 日誌目錄無權限 | 日誌無法寫入 | 捕捉錯誤，輸出到 stderr |
| symlink 指向敏感目錄 | 已確認安全 | trashItem 只移動 symlink 本身 |
