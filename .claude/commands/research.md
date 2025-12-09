# /research - 研究探索

你需要為一個 Spike Issue 進行研究，探索可能的解決方案並產出研究報告。

## 參數

```
Issue Number: $ARGUMENTS
```

## 步驟 1：讀取 Spike Issue

```bash
gh issue view $ARGUMENTS
```

確認 Issue 有 `spike` label，並了解「需要研究的問題」。

## 步驟 2：研究探索

根據 Spike Issue 列出的「需要研究的問題」，逐一進行研究：

### 研究方法

| 類型 | 方法 |
|------|------|
| 技術選型 | WebSearch 查詢最新方案、比較 pros/cons |
| 現有架構 | 讀取 `.snapshots/` 和相關程式碼 |
| 第三方服務 | WebFetch 讀取官方文檔 |
| 成本估算 | 查詢定價頁面、計算使用量 |

### 研究重點

- **可行性**：這個方案在我們的架構下可行嗎？
- **成本**：實作成本、運行成本、維護成本
- **權衡**：不同方案的 trade-offs
- **風險**：可能遇到的問題

## 步驟 3：產出研究報告

將研究結果寫入 `STATE/developing/research-xxx.md`：

```markdown
# [主題] 研究報告

> Spike Issue: #123
> 研究日期：YYYY-MM-DD

## 研究問題

1. 問題 1
2. 問題 2
...

## 研究發現

### 問題 1：[問題描述]

**調查結果**：
...

**結論**：
...

### 問題 2：[問題描述]

**調查結果**：
...

**結論**：
...

## 方案比較

| 方案 | 優點 | 缺點 | 成本估算 |
|------|------|------|----------|
| 方案 A | ... | ... | ... |
| 方案 B | ... | ... | ... |

## 建議方案

基於以上研究，建議採用 **方案 X**，原因：
1. ...
2. ...

## 待確認事項

- [ ] 需要用戶確認的事項 1
- [ ] 需要用戶確認的事項 2

## 下一步

研究完成後，可以執行 `/design #<issue-number>` 進行技術設計
```

## 步驟 4：更新 Spike Issue

```bash
gh issue comment $ARGUMENTS --body "$(cat <<'EOF'
研究完成！

📊 研究報告：STATE/developing/research-xxx.md

主要發現：
- [發現 1]
- [發現 2]

建議方案：[簡述建議]

下一步：執行 `/design #$ARGUMENTS` 進行技術設計
EOF
)"
```

## 步驟 5：詢問用戶

如果有「待確認事項」，使用 AskUserQuestion 詢問用戶：

- 方案選擇
- 預算/成本考量
- 優先級取捨

## 步驟 6：告知用戶

```
研究完成！

📊 研究報告：STATE/developing/research-xxx.md

建議方案：[簡述]

下一步：
- 如果同意建議方案：執行 `/design #<issue-number>` 進行技術設計
- 如果需要調整：請告訴我你的想法
```
