# Desktop Cleaner

macOS 自動清理工具，定時將「下載」和「桌面」資料夾中超過三天的檔案移到垃圾桶。

## 功能

- 每天 23:00 自動執行
- 掃描「下載」和「桌面」資料夾
- 將修改時間超過 72 小時（三天）的檔案移到垃圾桶
- 檔案可從垃圾桶復原

## 系統需求

- macOS 13.0 或更高版本
- Xcode Command Line Tools

## 安裝

```bash
./install.sh
```

安裝腳本會：
1. 編譯 Swift 程式
2. 安裝執行檔到 `/usr/local/bin/desktop-cleaner`
3. 安裝 LaunchAgent 設定
4. 載入 LaunchAgent（每天 23:00 執行）

### 授權 Full Disk Access

程式需要 Full Disk Access 權限才能存取「下載」和「桌面」資料夾：

1. 開啟「系統設定」>「隱私與安全性」>「Full Disk Access」
2. 點擊「+」新增 `/usr/local/bin/desktop-cleaner`
3. 啟用開關

## 手動執行

```bash
/usr/local/bin/desktop-cleaner
```

## 查看日誌

```bash
# 標準輸出
cat /tmp/desktop-cleaner.log

# 錯誤訊息
cat /tmp/desktop-cleaner.error.log
```

## 移除

```bash
./uninstall.sh
```

移除腳本會：
1. 卸載 LaunchAgent
2. 刪除 plist 設定檔
3. 刪除執行檔

## 授權

MIT
