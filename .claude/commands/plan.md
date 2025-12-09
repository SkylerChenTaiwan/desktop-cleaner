# /plan - 開始規劃任務

你收到了一個新的任務需求。請按照以下流程處理：

## 步驟 1：用 Snapshot 了解架構

**先讀取 Snapshot 了解專案結構，不要直接搜尋！**

```bash
# 1. 讀取專案總覽
cat .snapshots/index.json
```

根據任務類型，查看 `quickNav` 找到相關 snapshot。

然後讀取 quickNav 指示的 snapshot 檔案，了解：
- 相關模組位置
- 現有實作方式
- 應該修改哪些檔案

## 步驟 2：了解現況

讀取 STATE 文件了解系統規格：

```bash
# 必讀
cat STATE/overview.md

# 如果涉及 API
cat STATE/api-contract.yaml

# 了解現有測試
cat STATE/tests.md
```

## 步驟 3：分析任務

根據任務描述，判斷任務的明確程度：

| 情況 | 特徵 | 下一步 |
|------|------|--------|
| **很明確** | 知道要改哪些檔案、做什麼 | 直接創建 Issue |
| **有點模糊** | 大方向清楚，細節不確定 | 問 1-3 個問題後創建 Issue |
| **很模糊/很大** | 需要研究設計才知道怎麼做 | 創建 Spike Issue |

## 步驟 4：創建 Issue

### 4a. 如果是小任務（可直接執行）

```bash
# 先查看可用的 labels
gh label list

# 創建 Issue
gh issue create --title "清楚的任務描述" --label "type:xxx,scope:xxx" --body "$(cat <<'EOF'
## 背景
為什麼要做這個？

## 目標
做完後系統會變成什麼樣？

## 相關 STATE
- STATE/api-contract.yaml（第 X-Y 行）

## 驗收條件
- [ ] 條件 1
- [ ] 條件 2

## 測試策略

**單元測試**（新增/修改）：
- [ ] `XxxService.test.ts` - 新增 "should xxx" 測試

**E2E 驗證**（必須跑的現有 E2E，確保不 break）：
- [ ] `xxx.spec.ts` - 全部場景

**手動驗證**（如有）：
- [ ] 在本地確認 xxx

## 狀態
🆕 待開始
EOF
)"
```

### 4b. 如果是大任務（需要設計）

```bash
gh issue create --title "[Spike] 任務描述" --label "spike" --body "$(cat <<'EOF'
## 背景
為什麼要做這個？

## 目標
做完後系統會變成什麼樣？

## 需要研究的問題
- [ ] 問題 1
- [ ] 問題 2

## 下一步
執行 /design #<issue-number> 進行設計

## 狀態
🔍 待設計
EOF
)"
```

## 步驟 5：告知用戶

創建 Issue 後，告訴用戶：

```
已創建 Issue #123：<標題>

下一步：
- 小任務：執行 `/impl #123` 開始實作
- Spike：執行 `/design #123` 開始設計
```

---

## 任務描述

$ARGUMENTS
