# 風險控制研究報告

> Spike Issue: #6
> 研究日期：2024-12-10

## 研究問題

1. 現有程式碼的安全性分析
2. 測試覆蓋是否足夠？
3. 安全防護機制選項

## 研究發現

### 問題 1：現有程式碼的安全性分析

**調查結果**：

#### 刪除邏輯分析

| 組件 | 檔案 | 安全性評估 |
|------|------|------------|
| `DesktopCleaner` | `DesktopCleaner.swift:26-41` | ✅ 良好 - 固定只清理 `~/Downloads` 和 `~/Desktop` |
| `FileScanner` | `FileScanner.swift:11-31` | ✅ 良好 - 使用 `contentsOfDirectory` 只掃描一層 |
| `FileTrash` | `FileTrash.swift:11-19` | ✅ 良好 - 使用 `trashItem` API 移到垃圾桶 |
| `FileInfo.isOlderThanThreeDays` | `Models.swift:18-20` | ✅ 良好 - 精確計算 72 小時 |

#### 安全保護機制現況

1. **路徑硬編碼**（`DesktopCleaner.swift:4-11`）
   - ✅ 優點：使用 `FileManager.default.urls()` 取得標準路徑
   - ✅ 優點：只處理 `downloadsDirectory` 和 `desktopDirectory`
   - ✅ 優點：無法透過外部輸入修改路徑

2. **非遞迴掃描**（`FileScanner.swift:14`）
   - ✅ 優點：只掃描第一層，不會進入子資料夾內部
   - ✅ 優點：子資料夾整體被處理，不會單獨刪除內部檔案

3. **隱藏檔案保護**（`FileScanner.swift:17`）
   - ✅ 優點：使用 `.skipsHiddenFiles` 忽略隱藏檔案
   - ✅ 優點：`.DS_Store`、`.config` 等系統檔案不會被刪除

4. **垃圾桶機制**（`FileTrash.swift:13`）
   - ✅ 優點：使用 `FileManager.trashItem()` 而非永久刪除
   - ✅ 優點：使用者可從垃圾桶救回檔案

#### 潛在風險點

| 風險 | 嚴重度 | 說明 |
|------|--------|------|
| 無操作預覽 | 中 | 使用者無法事先知道會刪除什麼 |
| 無執行紀錄 | 中 | 只有 stdout 輸出，無持久化日誌 |
| 無排除機制 | 低 | 無法保護特定重要檔案 |
| 無確認機制 | 低 | LaunchAgent 自動執行時無法確認 |

**結論**：

現有程式碼基礎安全性良好：
- 刪除範圍固定在 `~/Downloads` 和 `~/Desktop`
- 使用系統 API 取得路徑，無路徑注入風險
- 使用垃圾桶而非永久刪除，可救回檔案
- 跳過隱藏檔案，保護系統設定

主要改進空間在於：增加透明度（dry-run、日誌）和靈活性（排除清單）。

---

### 問題 2：測試覆蓋是否足夠？

**調查結果**：

#### 現有測試統計

| 測試檔案 | 測試數量 | 覆蓋範圍 |
|---------|---------|---------|
| `FileScannerTests.swift` | 7 個 | 掃描邏輯 |
| `FileTrashTests.swift` | 3 個 | 垃圾桶操作 |
| `DesktopCleanerTests.swift` | 5 個 | 清理邏輯 |
| `IntegrationTests.swift` | 3 個 | 端到端流程 |
| **總計** | **18 個** | |

#### 已覆蓋的場景

- ✅ 清理超過三天的檔案
- ✅ 保留三天內的檔案
- ✅ 處理空資料夾
- ✅ 混合新舊檔案
- ✅ 邊界條件（71h vs 73h）
- ✅ 隱藏檔案跳過
- ✅ 目錄清理
- ✅ 連續清理

#### 缺失的風險場景測試

| 場景 | 風險等級 | 說明 |
|------|---------|------|
| Symlink 處理 | 高 | symlink 可能指向範圍外的檔案 |
| 特殊檔名 | 中 | 空格、中文、emoji、特殊字元 |
| 大量檔案 | 低 | 效能和穩定性 |
| 權限問題 | 低 | 無法讀取/刪除的檔案 |

**結論**：

現有 18 個測試覆蓋了基本功能，但缺少：
1. **Symlink 測試**（最重要）- 需確認 symlink 不會導致刪除範圍外的檔案
2. **特殊檔名測試** - 確保各種檔名都能正確處理
3. **權限測試** - 確保錯誤處理機制正常運作

---

### 問題 3：安全防護機制選項

**調查結果**：

根據業界最佳實踐研究，以下是可選的安全機制：

#### 方案 A：Dry-Run 預覽模式

**說明**：執行時顯示「會刪除什麼」但不實際刪除

**實作方式**：
```swift
// Gather-Execute Pattern
func scan() -> [FileInfo]    // 蒐集要刪除的檔案
func execute([FileInfo])     // 實際執行刪除
```

**優點**：
- 使用者可事先確認
- 符合 Unix 工具 `--dry-run` 慣例
- 可整合到現有 clean() 方法

**缺點**：
- 自動排程時無人查看預覽
- 需修改 CLI 介面

#### 方案 B：執行日誌

**說明**：記錄每次執行的詳細資訊

**實作方式**：
```
~/.desktop-cleaner/logs/2024-12-10.log
```

日誌內容：
- 執行時間
- 掃描的資料夾
- 刪除的檔案清單
- 保留的檔案清單
- 錯誤訊息

**優點**：
- 可追溯歷史操作
- 出問題時可查詢
- 不需即時查看

**缺點**：
- 需管理日誌檔案大小
- 增加磁碟使用

#### 方案 C：排除清單（白名單）

**說明**：指定特定檔案/資料夾不被清理

**實作方式**：
```
~/.desktop-cleaner/exclude.txt
---
*.dmg           # 排除所有 DMG 檔案
important/      # 排除 important 資料夾
project.zip     # 排除特定檔案
```

**優點**：
- 保護重要檔案
- 靈活性高

**缺點**：
- 增加複雜度
- 需學習語法

#### 方案 D：組合方案（建議）

結合以上優點，分階段實作：

**第一階段（必要）**：
1. Dry-Run 模式 - CLI 加入 `--dry-run` 參數
2. 執行日誌 - 每次執行自動記錄

**第二階段（可選）**：
3. 排除清單 - 進階使用者可自訂

---

## 方案比較

| 方案 | 實作複雜度 | 使用者價值 | 風險降低 | 建議優先級 |
|------|-----------|-----------|---------|-----------|
| Dry-Run 模式 | 低 | 高 | 高 | ⭐ 第一 |
| 執行日誌 | 低 | 高 | 中 | ⭐ 第一 |
| Symlink 測試 | 低 | 無 | 高 | ⭐ 第一 |
| 排除清單 | 中 | 中 | 中 | 第二 |
| 特殊檔名測試 | 低 | 無 | 中 | 第二 |

---

## 建議方案

基於以上研究，建議採用**組合方案**，分兩個 Epic 實作：

### Epic 1：基礎安全機制（優先）

| Issue | 說明 |
|-------|------|
| Symlink 安全處理 | 新增測試 + 確認 symlink 行為 |
| Dry-Run 模式 | 新增 `--dry-run` CLI 參數 |
| 執行日誌 | 每次執行記錄到日誌檔 |

### Epic 2：進階功能（可選）

| Issue | 說明 |
|-------|------|
| 排除清單 | 支援 exclude.txt |
| 特殊檔名測試 | 加強邊界條件測試 |

---

## 待確認事項

- [ ] 使用者是否需要排除清單功能？
- [ ] 日誌保留期限？（建議 30 天）
- [ ] 是否需要通知功能？（如 macOS 通知中心）

---

## 下一步

研究完成後，可以執行 `/design #6` 進行技術設計

---

## 參考資料

- [Apple Developer - trashItem API](https://developer.apple.com/documentation/foundation/filemanager/1414306-trashitem)
- [In praise of --dry-run](https://www.gresearch.com/news/in-praise-of-dry-run/)
- [CLI Tools That Support Previews](https://nickjanetakis.com/blog/cli-tools-that-support-previews-dry-runs-or-non-destructive-actions)
- [macos-trash by sindresorhus](https://github.com/sindresorhus/macos-trash)
- [Audit Log Best Practices](https://www.digitalguardian.com/blog/audit-log-best-practices-security-compliance)
