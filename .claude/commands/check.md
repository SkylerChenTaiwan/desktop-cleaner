# /check - 驗證實作

你需要驗證一個 Issue 的實作是否完成。

## 參數

```
Issue Number: $ARGUMENTS
```

## 步驟 1：讀取 Issue

```bash
gh issue view $ARGUMENTS
```

確認：
- 驗收條件清單
- 測試策略

## 步驟 2：切換到 Worktree

```bash
# 取得專案名稱
PROJECT_NAME=$(basename "$PWD")

# 切換到 /impl 創建的 worktree
cd ../${PROJECT_NAME}-$ARGUMENTS

# 確認在正確分支
git branch --show-current
# 應該是 issue/$ARGUMENTS-xxx
```

**後續所有測試都在 worktree 目錄執行！**

## 步驟 3：用 Snapshot 確認相關測試

**用 Snapshot 找到相關的測試檔案位置！**

```bash
# 讀取專案總覽
cat .snapshots/index.json
```

根據 Issue 涉及的模組，讀取相關 snapshot 找到對應測試。

從 snapshot 確認：
- 修改的模組對應哪些測試檔案
- 是否有遺漏的測試

## 步驟 4：執行測試

### 4a. 單元測試

根據 Issue 的測試策略，執行相關單元測試：

```bash
# 執行特定模組的測試
npm test -- --testPathPattern="XxxService" --coverage
```

### 4b. E2E 測試

根據 Issue 的「E2E 驗證」清單，執行相關 E2E：

```bash
# 執行指定的 E2E 測試
npx playwright test xxx.spec.ts

# 如果有新增 E2E，也要跑
npx playwright test xxx.spec.ts
```

### 4c. Contract 測試（如涉及 API）

```bash
# 確認 API 回傳格式符合 STATE/api-contract.yaml
npm run test:contract  # 如果有這個腳本
```

## 步驟 5：檢查驗收條件

逐一確認 Issue 中的驗收條件：

- [ ] 條件 1 - ✅ / ❌
- [ ] 條件 2 - ✅ / ❌
- ...

## 步驟 6：判斷結果

### 6a. 如果有測試失敗

```
❌ 驗證未通過

失敗項目：
- [ ] 條件 X：原因...

需要修復後重新執行 `/check #$ARGUMENTS`
```

繼續修復，然後重新執行 `/check`。

### 6b. 如果全部通過

```
✅ 驗證通過！

通過項目：
- [x] 單元測試全部通過
- [x] E2E 測試全部通過
- [x] 驗收條件 1
- [x] 驗收條件 2

下一步：執行 `/close #$ARGUMENTS` 完成 merge 並關閉 Issue
```
