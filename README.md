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

### 1. 編譯與打包

```bash
# 下載專案
git clone https://github.com/SkylerChenTaiwan/desktop-cleaner.git
cd desktop-cleaner

# 編譯並打包成 App Bundle
./scripts/build.sh
```

### 2. 安裝

```bash
./scripts/install.sh
```

安裝腳本會：
1. 複製 App Bundle 到 `~/Applications/DesktopCleaner.app`
2. 設定 LaunchAgent（每天 23:00 執行）
3. 載入 LaunchAgent

### 3. 授權完整磁碟取用權限

程式需要「完整磁碟取用權限」才能存取「下載」和「桌面」資料夾：

1. 開啟「系統設定」
2. 前往「隱私權與安全性」→「完整磁碟取用權限」
3. 點擊「+」按鈕
4. 選擇 `~/Applications/DesktopCleaner.app`
5. 確認已啟用

授權後，重新載入 LaunchAgent：

```bash
launchctl unload ~/Library/LaunchAgents/com.user.desktop-cleaner.plist
launchctl load ~/Library/LaunchAgents/com.user.desktop-cleaner.plist
```

## 手動執行

```bash
# 測試模式（只顯示會刪除的檔案，不實際刪除）
~/Applications/DesktopCleaner.app/Contents/MacOS/DesktopCleaner --dry-run

# 實際執行
~/Applications/DesktopCleaner.app/Contents/MacOS/DesktopCleaner
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
./scripts/uninstall.sh
```

移除腳本會：
1. 卸載 LaunchAgent
2. 刪除 LaunchAgent 設定檔
3. 刪除 App Bundle

## 故障排除

### 權限錯誤：無法存取資料夾

**症狀**：執行時顯示「Operation not permitted」或類似錯誤。

**解決方法**：
1. 確認已在「系統設定」→「隱私權與安全性」→「完整磁碟取用權限」中授權 DesktopCleaner.app
2. 重新載入 LaunchAgent：
   ```bash
   launchctl unload ~/Library/LaunchAgents/com.user.desktop-cleaner.plist
   launchctl load ~/Library/LaunchAgents/com.user.desktop-cleaner.plist
   ```

### 程式無法執行：被 macOS 阻擋

**症狀**：顯示「無法打開『DesktopCleaner』，因為無法驗證開發者」。

**解決方法**：
1. 開啟「系統設定」→「隱私權與安全性」
2. 在下方找到被阻擋的應用程式訊息
3. 點擊「強制開啟」

### LaunchAgent 未執行

**症狀**：程式沒有在排定時間自動執行。

**檢查步驟**：
```bash
# 確認 LaunchAgent 已載入
launchctl list | grep desktop-cleaner

# 如果沒有顯示，重新載入
launchctl load ~/Library/LaunchAgents/com.user.desktop-cleaner.plist
```

### 查看詳細錯誤

```bash
# 檢查錯誤日誌
cat /tmp/desktop-cleaner.error.log

# 手動執行測試
~/Applications/DesktopCleaner.app/Contents/MacOS/DesktopCleaner --dry-run
```

## 授權

MIT
