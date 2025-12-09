# /breakdown - 拆分任務

你需要將一個 Spike Issue 拆分成可執行的子任務。

## 參數

```
Spike Issue Number: $ARGUMENTS
```

## 步驟 1：讀取規劃文件

```bash
# 讀取 Spike Issue
gh issue view $ARGUMENTS

# 讀取規劃文件（從 Spike Issue 找到路徑）
cat STATE/developing/xxx.md
```

## 步驟 2：用 Snapshot 了解模組邊界

**先讀取 Snapshot 了解架構，才能正確拆分！**

```bash
# 讀取專案總覽
cat .snapshots/index.json
```

重點查看：
- 後端模組（controllers, services, repositories）
- 前端模組（pages, components, hooks）
- `namingConventions` - 命名慣例，了解模組職責

根據規劃文件涉及的範圍，讀取相關 snapshot。

從 snapshot 確認：
- 哪些模組/檔案會被修改
- 模組之間的邊界在哪裡
- 如何拆分才不會改同一個檔案

## 步驟 3：分析可平行的工作

根據規劃文件的「實作分工建議」，確認：

1. **哪些任務可以平行**：不同檔案、不同模組
2. **哪些任務有依賴**：例如前端需要等 API 完成
3. **每個任務的範圍**：明確的驗收條件

### 分工判斷標準

| 條件 | 說明 |
|------|------|
| 真正獨立 | 可以各自完成，不用互相等待 |
| 不會衝突 | 不會改同一個檔案 |
| 有時間效益 | 分了之後總時間更短 |

**不值得分的情況**：
- 任務很小（< 30 分鐘）
- 強依賴關係
- 會改同一個檔案

## 步驟 4：創建 Epic Issue

```bash
gh issue create --title "[Epic] 功能名稱" --label "epic" --body "$(cat <<'EOF'
## 摘要
這個功能要做什麼

## 規劃文件
STATE/developing/xxx.md

## 子 Issues
（待創建）

## 完成紀錄
（完成時更新）
EOF
)"
```

記下 Epic Issue 號碼（例如 #200）

## 步驟 5：創建子 Issues

為每個可獨立執行的任務創建 Issue：

```bash
# 子 Issue 1: 後端 API
gh issue create --title "後端：實作 xxx API" --label "type:feature,scope:backend" --body "$(cat <<'EOF'
Part of #200

## 目標
實作 STATE/developing/xxx.md 中定義的 API

## 相關規格
STATE/developing/xxx.md - API Contract 段落

## 驗收條件
- [ ] POST /api/xxx 可正常運作
- [ ] 回傳格式符合 contract

## 測試策略

**單元測試**：
- [ ] `XxxService.test.ts` - 新增 "should xxx" 測試

**E2E 驗證**：
- [ ] （等前端完成後整合測試）

## 狀態
🆕 待開始
EOF
)"

# 子 Issue 2: 前端 UI
gh issue create --title "前端：實作 xxx UI" --label "type:feature,scope:frontend" --body "$(cat <<'EOF'
Part of #200

## 目標
實作 STATE/developing/xxx.md 中定義的 UI

## 相關規格
STATE/developing/xxx.md - UI 設計段落

## 依賴
Blocked by #201（後端 API）

## 驗收條件
- [ ] 頁面可正常顯示
- [ ] 可呼叫 API 並顯示結果

## 測試策略

**E2E 測試**：
- [ ] 新增 `xxx.spec.ts` - 測試完整流程
- [ ] 完成後更新 STATE/tests.md

## 狀態
🆕 待開始（等 API 完成）
EOF
)"
```

## 步驟 6：更新 Epic Issue

```bash
gh issue comment 200 --body "$(cat <<'EOF'
## 子 Issues 已創建

- [ ] #201 後端：實作 xxx API
- [ ] #202 前端：實作 xxx UI

### 依賴關係
#202 blocked by #201

### 分工建議
- AI-1: `/impl #201`（後端）
- AI-2: 等 #201 完成後 `/impl #202`（前端）
EOF
)"
```

## 步驟 7：關閉 Spike Issue

```bash
gh issue close $ARGUMENTS --comment "已拆分為 Epic #200 + 子 Issues #201, #202"
```

## 步驟 8：告知用戶

```
拆分完成！

📋 Epic Issue: #200
📝 子 Issues:
  - #201 後端：實作 xxx API [可開始]
  - #202 前端：實作 xxx UI [等 #201]

下一步：
- 執行 `/impl #201` 開始實作後端
- #201 完成後執行 `/impl #202` 實作前端
- 或開兩個 worktree 平行開發（前端可先 mock API）
```
