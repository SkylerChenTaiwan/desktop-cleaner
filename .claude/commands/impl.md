# /impl - 實作任務

你需要實作一個 GitHub Issue。

## 參數

```
Issue Number: $ARGUMENTS
```

## 步驟 1：讀取 Issue

```bash
gh issue view $ARGUMENTS
```

## 步驟 2：檢查 current-task.md

```bash
# 檢查是否有上次的進度
cat .claude/current-task.md 2>/dev/null || echo "無上次進度"
```

## 步驟 3：用 Snapshot 定位要修改的檔案

**先讀取 Snapshot 了解架構，不要直接搜尋！**

```bash
# 1. 讀取專案總覽
cat .snapshots/index.json
```

根據 Issue 內容，查看 `quickNav` 找到相關 snapshot。

從 snapshot 確認：
- **要修改哪些檔案**（從 snapshot 的 `path` 欄位）
- **相關檔案的職責**（從 snapshot 的 `description` 欄位）
- **不要修改錯誤的檔案**

## 步驟 4：讀取相關規格

根據 Issue 內容，讀取相關的 STATE 文件：

```bash
# 如果涉及 API
cat STATE/api-contract.yaml

# 如果是大功能的子任務，讀取規劃文件
cat STATE/developing/xxx.md
```

## 步驟 5：創建 Worktree

**重要：必須使用 git worktree 來隔離工作環境，避免多個 AI 同時工作時互相干擾！**

```bash
# 取得專案名稱
PROJECT_NAME=$(basename "$PWD")

# 1. 確保 develop 是最新的
git fetch origin develop

# 2. 創建 worktree + 新分支（一個命令完成兩件事）
#    - 創建 worktree 目錄：../${PROJECT_NAME}-$ARGUMENTS
#    - 創建新分支：issue/$ARGUMENTS-簡短描述（基於 origin/develop）
git worktree add ../${PROJECT_NAME}-$ARGUMENTS -b issue/$ARGUMENTS-簡短描述 origin/develop

# 3. 切換到 worktree 目錄
cd ../${PROJECT_NAME}-$ARGUMENTS

# 4. 立即更新 Issue 狀態
gh issue edit $ARGUMENTS --remove-label "status:ready" --add-label "status:in-progress"
```

**後續所有操作都在 worktree 目錄進行！**

## 步驟 6：更新 current-task.md

```bash
cat > .claude/current-task.md << 'EOF'
# 當前任務

## Issue
#123 - Issue 標題

## 引用的規格
STATE/api-contract.yaml 第 X-Y 行
STATE/developing/xxx.md

## Checkpoint
- [ ] 步驟 1
- [ ] 步驟 2
- [ ] 步驟 3

## 上次停在
（新任務）

## 下次繼續
開始實作
EOF
```

## 步驟 7：TDD 實作循環（頻繁 Commit！）

**重要：每完成一個邏輯單元就 commit + push，不要累積！**

### 循環流程

```
┌─────────────────────────────────────────────────────┐
│  1. 寫測試 → commit "test: 新增 xxx 測試"           │
│                    ↓                                │
│  2. 跑測試（確認紅燈）                               │
│                    ↓                                │
│  3. 實作程式碼                                       │
│                    ↓                                │
│  4. 跑測試（確認綠燈）→ commit "feat: 實作 xxx"      │
│                    ↓                                │
│  5. 重構（如需要）→ commit "refactor: 重構 xxx"     │
│                    ↓                                │
│  6. 回到步驟 1，處理下一個功能                       │
└─────────────────────────────────────────────────────┘
```

### Commit 時機（強制）

| 時機 | Commit 類型 | 範例 |
|------|------------|------|
| 寫完測試後 | `test:` | `test: 新增 XxxService 篩選測試 (#123)` |
| 功能實作完成 | `feat:` | `feat: 實作故事篩選功能 (#123)` |
| 修復 bug | `fix:` | `fix: 修正分頁邏輯 (#123)` |
| 重構後 | `refactor:` | `refactor: 抽取共用邏輯 (#123)` |
| 任何有意義的進度 | 適當類型 | 確保不丟失工作 |

### Commit 格式

```bash
git add .
git commit -m "<type>: <描述> (#$ARGUMENTS)

- 變更項目 1
- 變更項目 2

🤖 Generated with [Claude Code](https://claude.com/claude-code)
Co-Authored-By: Claude <noreply@anthropic.com>"

# 每次 commit 後都要 push！
git push origin issue/$ARGUMENTS-簡短描述
```

## 步驟 8：持續更新 current-task.md

每完成一個步驟，更新 checkpoint，記錄：
- 已完成的項目
- 目前進度
- 下次從哪裡繼續

## 步驟 9：實作完成

所有功能都實作完成後，告訴用戶：

```
實作完成！

📝 Worktree：../${PROJECT_NAME}-$ARGUMENTS
📝 分支：issue/$ARGUMENTS-xxx
📋 Commits：
  - test: 新增 xxx 測試 (#$ARGUMENTS)
  - feat: 實作 xxx (#$ARGUMENTS)
  - ...

下一步：在主目錄執行 `/check #$ARGUMENTS` 驗證實作
（Worktree 會在 /check 完成後清理）
```

**注意：不要刪除 worktree，留給 /check 使用！**

---

## Commit 原則

1. **小而頻繁** - 每 15-30 分鐘至少 commit 一次
2. **有意義的單位** - 每個 commit 是一個完整的邏輯變更
3. **立即 push** - commit 後立即 push，避免本地丟失
4. **不要累積** - 絕對不要等到 /check 才 commit

---

## 如果需要 /clear

在 /clear 之前：
1. **先 commit + push 目前的進度**
2. 更新 current-task.md，記錄：
   - 目前進度
   - 下次要從哪裡繼續
