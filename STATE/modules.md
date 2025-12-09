# 模組清單

> 最後更新：YYYY-MM-DD

## 後端模組

### Controllers

| 名稱 | 路徑 | 職責 |
|------|------|------|
| <!-- ControllerName --> | <!-- src/app/xxx.controller.ts --> | <!-- 處理 XXX 相關請求 --> |

### Services

| 名稱 | 路徑 | 職責 |
|------|------|------|
| <!-- ServiceName --> | <!-- src/app/xxx.service.ts --> | <!-- 處理 XXX 業務邏輯 --> |

### Repositories

| 名稱 | 路徑 | 職責 |
|------|------|------|
| <!-- RepositoryName --> | <!-- src/infra/xxx.repository.ts --> | <!-- 存取 XXX 資料 --> |

---

## 前端模組

### Pages

| 名稱 | 路徑 | 職責 |
|------|------|------|
| <!-- PageName --> | <!-- src/app/xxx/page.tsx --> | <!-- XXX 頁面 --> |

### Components

| 名稱 | 路徑 | 職責 |
|------|------|------|
| <!-- ComponentName --> | <!-- src/components/xxx.tsx --> | <!-- XXX 元件 --> |

### Hooks

| 名稱 | 路徑 | 職責 |
|------|------|------|
| <!-- useHookName --> | <!-- src/hooks/useXxx.ts --> | <!-- XXX Hook --> |

---

## Domain 模組

### Policies

| 名稱 | 路徑 | 職責 |
|------|------|------|
| <!-- PolicyName --> | <!-- src/domain/xxx.policy.ts --> | <!-- XXX 規則 --> |

### Calculators

| 名稱 | 路徑 | 職責 |
|------|------|------|
| <!-- CalculatorName --> | <!-- src/domain/xxx.calculator.ts --> | <!-- XXX 計算邏輯 --> |

---

## 更新規則

### 新增模組時

1. 在對應的表格中新增一行
2. 確保路徑和職責描述正確
3. 執行 `npm run update-snapshots` 更新 snapshot

### 移動/重新命名模組時

1. 更新此文件中的路徑
2. 更新 `STATE/overview.md`（如有架構變更）
3. 執行 `npm run update-snapshots` 更新 snapshot
