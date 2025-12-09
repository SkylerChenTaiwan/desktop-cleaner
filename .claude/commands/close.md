# /close - 關閉 Issue

在 `/check` 驗證通過後，執行 merge、關閉 Issue、處理 Epic 的完整流程。

## 參數

```
Issue Number: $ARGUMENTS
```

## 步驟 1：確認狀態

```bash
# 確認在正確分支
git branch --show-current
# 應該是 issue/$ARGUMENTS-xxx

# 確認所有變更已 commit
git status
```

## 步驟 2：Merge 到 develop

```bash
# 取得專案名稱和主目錄
PROJECT_NAME=$(basename "$PWD")
MAIN_DIR=$(dirname "$PWD")/${PROJECT_NAME%-*}

# 回到主目錄
cd "$MAIN_DIR"

# Merge
git checkout develop
git pull origin develop
git merge issue/$ARGUMENTS-xxx --no-ff -m "Merge issue #$ARGUMENTS: 描述"
git push origin develop
```

## 步驟 3：E2E 覆蓋檢查（涉及 API 變更時）

**如果 Issue 涉及新增或修改 API，必須檢查以下項目：**

### 3a. 確認有對應的 E2E 測試

```bash
# 列出相關的 E2E 測試檔案
ls -la e2e/tests/
```

檢查是否有測試覆蓋此 API。

### 3b. 確認測試已加入測試配置

查看測試配置檔（如 `playwright.config.ts`）：

```bash
# 檢視測試列表
cat playwright.config.ts
```

確認新測試已加入列表。

### 3c. 確認 STATE/tests.md 已更新

```bash
cat STATE/tests.md
```

確認測試文件有記錄新增的測試。

**如果缺少任何一項，停止 close 流程，先補齊後再繼續。**

## 步驟 4：關閉 Issue

```bash
gh issue close $ARGUMENTS --comment "$(cat <<'EOF'
✅ 已完成並 merge 到 develop

完成內容：
- [x] 驗收條件 1
- [x] 驗收條件 2
EOF
)"
```

## 步驟 5：檢查並完成 Epic（如適用）

**主動檢查** Issue 是否屬於某個 Epic：

```bash
# 查詢此 Issue 的 Epic（從 Issue body 找 "Part of #XXX"）
gh issue view $ARGUMENTS

# 如果有 "Part of #XXX"，查詢該 Epic 的所有子 Issues
gh issue list --search "Part of #XXX" --state all
```

**如果所有子 Issues 都已關閉，執行以下完整流程：**

### 5a. 確認 STATE 文件已更新

檢查 `STATE/` 目錄的相關文件是否正確反映變更後的狀態：

```bash
# 檢查相關 STATE 文件
cat STATE/tests.md           # 測試相關
cat STATE/spec.md            # 功能規格
cat STATE/api-contract.yaml  # API 相關
cat STATE/decisions.md       # 決策記錄
```

如有遺漏，補充更新並 commit。

### 5b. 歸檔設計文件

```bash
# 移動開發中的設計文件到 archived
mv STATE/developing/xxx.md STATE/archived/
git add STATE/ && git commit -m "chore: 歸檔 xxx.md（Epic #XXX 完成）" && git push
```

### 5c. 關閉 Epic

```bash
gh issue close XXX --comment "✅ Epic 完成！所有子 Issues 已完成。"
```

## 步驟 6：清理

### 6a. 清理 Worktree

```bash
# 取得專案名稱
PROJECT_NAME=$(basename "$PWD")

# 刪除 worktree（用 --force 處理 node_modules 等 untracked files）
git worktree remove ../${PROJECT_NAME}-$ARGUMENTS --force
```

### 6b. 清空 current-task.md

```bash
echo "# 當前任務

（無進行中任務）" > .claude/current-task.md
```

### 6c. 刪除遠端分支（可選）

```bash
git push origin --delete issue/$ARGUMENTS-xxx
```

## 步驟 7：告知用戶

```
已完成 Issue #$ARGUMENTS！

✅ 已 merge 到 develop
✅ Issue 已關閉
✅ Worktree 已清理

（如果是 Epic 的最後一個子 Issue）
✅ Epic #XXX 已關閉
✅ 設計文件已歸檔
✅ STATE 文件已更新
```
