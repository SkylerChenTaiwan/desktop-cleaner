# 測試清單

> 最後更新：2025-12-10

## 測試策略

| 測試類型 | 目的 | 工具 |
|---------|------|------|
| 單元測試 | 測試獨立模組的邏輯 | TestRunner (自製框架) |
| 整合測試 | 測試模組間的協作 | TestRunner (自製框架) |

## 執行測試

```bash
# 編譯並執行所有測試
swift run TestRunner

# 只編譯測試執行器
swift build --product TestRunner
```

---

## 單元測試清單

### FileScanner 測試

| 測試案例 | 描述 | 狀態 |
|---------|------|------|
| scanEmptyDirectory | 掃描空目錄應該返回空陣列 | ✅ |
| scanDirectoryWithFiles | 掃描含檔案的目錄應該返回正確數量的 FileInfo | ✅ |
| scanDirectoryReturnsCorrectFileInfo | 掃描檔案應該返回正確的 FileInfo 資訊 | ✅ |
| scanDirectoryWithSubdirectory | 掃描子目錄應該正確識別為目錄 | ✅ |
| scanSkipsHiddenFiles | 掃描應該跳過隱藏檔案 | ✅ |
| scanNonExistentDirectory | 掃描不存在的目錄應該返回空陣列 | ✅ |
| scanMixedContent | 掃描混合內容目錄應該只返回可見項目 | ✅ |

### FileTrash 測試

| 測試案例 | 描述 | 狀態 |
|---------|------|------|
| trashFile | 成功將檔案移到垃圾桶 | ✅ |
| trashNonExistentFile | 處理不存在的檔案應該返回 false | ✅ |
| trashDirectory | 成功將目錄移到垃圾桶 | ✅ |

### Symlink 測試

| 測試案例 | 描述 | 狀態 |
|---------|------|------|
| symlinkMovesLinkNotTarget | Symlink 應該移動連結本身而非目標 | ✅ |
| symlinkTargetUnaffected | Symlink 指向的目標檔案內容不受影響 | ✅ |

### DesktopCleaner 測試

| 測試案例 | 描述 | 狀態 |
|---------|------|------|
| cleanOldFiles | 清理超過三天的檔案 | ✅ |
| keepNewFiles | 保留三天內的檔案 | ✅ |
| handleEmptyDirectory | 處理空資料夾應該返回空結果 | ✅ |
| cleanMixedFiles | 混合新舊檔案只清理舊的 | ✅ |
| isOlderThanThreeDaysCalculation | FileInfo.isOlderThanThreeDays 計算正確 | ✅ |

---

## 整合測試清單

| 測試案例 | 描述 | 狀態 |
|---------|------|------|
| completeCleaningFlow | 完整清理流程：建立測試目錄，放入新舊檔案，執行清理，驗證結果 | ✅ |
| borderCondition | 邊界條件：71 小時的檔案不應該被清理，73 小時的應該被清理 | ✅ |
| consecutiveCleaning | 連續清理：第二次清理不應該有任何動作 | ✅ |

---

## 測試統計

| 類別 | 測試數量 | 通過數量 |
|------|---------|---------|
| FileScanner | 7 | 7 |
| FileTrash | 3 | 3 |
| Symlink | 2 | 2 |
| DesktopCleaner | 5 | 5 |
| 整合測試 | 3 | 3 |
| **總計** | **20** | **20** |

> 註：總斷言數為 63 個

---

## 測試檔案結構

```
Sources/TestRunner/
├── main.swift              # 測試執行入口
├── TestFramework.swift     # 簡易測試框架
├── FileScannerTests.swift  # FileScanner 單元測試
├── FileTrashTests.swift    # FileTrash 單元測試
├── SymlinkTests.swift      # Symlink 安全測試
├── DesktopCleanerTests.swift # DesktopCleaner 單元測試
└── IntegrationTests.swift  # 整合測試
```

---

## 待新增測試

- [ ] 測試 URL 擴充方法 (.downloads, .desktop)
- [ ] 測試 CleanResult 結構
- [ ] 新增效能測試（處理大量檔案的情況）
