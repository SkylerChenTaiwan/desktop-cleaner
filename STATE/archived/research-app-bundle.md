# macOS App Bundle 打包研究報告

> Spike Issue: #13
> 研究日期：2024-12-10

## 研究問題

1. Swift Package Manager 專案如何打包成 .app Bundle？
2. 需要哪些 Info.plist 設定（Bundle ID、隱私權描述等）？
3. 如何處理 code signing（是否需要開發者帳號）？
4. LaunchAgent 如何呼叫 .app 內的執行檔？
5. 是否需要建立 Xcode 專案，還是可以用 SPM 達成？
6. 安裝流程會如何改變？

## 研究發現

### 問題 1：SPM 專案如何打包成 .app Bundle？

**調查結果**：

有三種方式可以將 SPM 專案打包成 .app Bundle：

#### 方式 A：手動建立 Bundle 結構

App Bundle 本質上只是一個具有特定結構的目錄。最小結構為：

```
DesktopCleaner.app/
  Contents/
    Info.plist
    MacOS/
      DesktopCleaner    # 執行檔
    Resources/          # 可選，放置圖示等資源
```

可以用 shell script 或 Makefile 自動化：

```bash
# 1. 編譯
swift build -c release

# 2. 建立 bundle 結構
mkdir -p "DesktopCleaner.app/Contents/MacOS"
cp .build/release/DesktopCleaner "DesktopCleaner.app/Contents/MacOS/"
cp Info.plist "DesktopCleaner.app/Contents/"

# 3. Code signing
codesign -s - --force DesktopCleaner.app
```

#### 方式 B：使用 Swift Bundler 工具

[Swift Bundler](https://github.com/stackotter/swift-bundler) 是一個開源工具，可以直接從 SPM 專案建立 .app：

```bash
# 安裝
mint install stackotter/swift-bundler@main

# 建立專案
swift bundler create HelloWorld --template SwiftUI

# 執行
swift bundler run
```

優點：自動處理 bundle 結構和簽名
缺點：需要額外依賴，對純 CLI 工具可能過於複雜

#### 方式 C：建立 Xcode 專案

使用 Xcode 建立 macOS App 專案，將現有 SPM 程式碼作為 Package 依賴引入。

**結論**：

對於本專案（CLI 工具），**方式 A（手動建立）** 最為適合：
- 無需額外依賴
- 保持現有 SPM 結構
- 完全可控
- 容易自動化

---

### 問題 2：Info.plist 必要設定

**調查結果**：

根據 [Apple 官方文檔](https://developer.apple.com/documentation/bundleresources/information-property-list)，需要以下設定：

#### 必要欄位

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Bundle 基本資訊 -->
    <key>CFBundleIdentifier</key>
    <string>com.user.desktop-cleaner</string>

    <key>CFBundleName</key>
    <string>DesktopCleaner</string>

    <key>CFBundleDisplayName</key>
    <string>Desktop Cleaner</string>

    <key>CFBundleExecutable</key>
    <string>DesktopCleaner</string>

    <key>CFBundleVersion</key>
    <string>1.0.0</string>

    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>

    <key>CFBundlePackageType</key>
    <string>APPL</string>

    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>

    <!-- 隱私權描述（重要！） -->
    <key>NSDesktopFolderUsageDescription</key>
    <string>Desktop Cleaner 需要存取桌面資料夾以清理過期檔案。</string>

    <key>NSDownloadsFolderUsageDescription</key>
    <string>Desktop Cleaner 需要存取下載資料夾以清理過期檔案。</string>

    <!-- 背景執行（無 GUI） -->
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
```

#### 關於 Full Disk Access

根據 [Apple Developer Forums](https://developer.apple.com/forums/thread/107546) 的討論：

- **Full Disk Access 無法透過 API 請求**，使用者必須手動在「系統設定 → 隱私權與安全性」中授權
- `NSDesktopFolderUsageDescription` 和 `NSDownloadsFolderUsageDescription` 可能足夠，不一定需要 Full Disk Access
- 但如果要存取更多受保護目錄，Full Disk Access 是必需的

**結論**：

建議先嘗試使用 `NSDesktopFolderUsageDescription` 和 `NSDownloadsFolderUsageDescription`，如果不足再引導使用者授權 Full Disk Access。

---

### 問題 3：Code Signing 需求

**調查結果**：

根據 [Ad-Hoc Code Signing 指南](https://stories.miln.eu/graham/2024-06-25-ad-hoc-code-signing-a-mac-app/)：

#### Ad-Hoc Signing（無需開發者帳號）

```bash
codesign -s - --force DesktopCleaner.app
```

特點：
- 完全免費，無需 Apple Developer Program
- 在本機執行正常
- 複製到其他電腦時，使用者需要手動允許執行（右鍵 → 打開）
- 無法 notarize，會顯示「無法驗證開發者」警告

#### Apple Silicon 注意事項

Apple Silicon Mac **必須**對所有執行檔進行簽名，ad-hoc signing 符合此要求。

#### 正式發布選項

| 方案 | 成本 | 特點 |
|------|------|------|
| Ad-hoc signing | 免費 | 本機使用，其他電腦需手動允許 |
| Developer ID | $99/年 | 可 notarize，無警告 |

**結論**：

**Ad-hoc signing 足以滿足個人使用需求**。如果未來要分享給其他人，可考慮加入 Apple Developer Program。

---

### 問題 4：LaunchAgent 如何呼叫 .app 內執行檔

**調查結果**：

根據 [Apple launchd 文檔](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html)，有兩種方式：

#### 方式 A：直接呼叫 Contents/MacOS 內的執行檔（推薦）

```xml
<key>ProgramArguments</key>
<array>
    <string>/Applications/DesktopCleaner.app/Contents/MacOS/DesktopCleaner</string>
</array>
```

這是最直接的方式，與現有 LaunchAgent 設定差異最小。

#### 方式 B：使用 open 命令

```xml
<key>ProgramArguments</key>
<array>
    <string>/usr/bin/open</string>
    <string>-W</string>
    <string>/Applications/DesktopCleaner.app</string>
</array>
```

`-W` 參數讓 open 等待程式結束。

**結論**：

**方式 A 最適合本專案**，因為：
- 與現有設定結構一致
- 直接執行，無額外開銷
- 執行檔會繼承 app bundle 的權限

---

### 問題 5：是否需要 Xcode 專案

**調查結果**：

根據 [The Swift Dev 文章](https://theswiftdev.com/how-to-build-macos-apps-using-only-the-swift-package-manager/)：

| 場景 | 是否需要 Xcode 專案 |
|------|---------------------|
| 本機開發和使用 | 否 |
| 使用 SPM 編譯 | 否 |
| 手動建立 bundle | 否 |
| 提交 Mac App Store | 是 |
| 使用 Xcode 簽名/notarize | 是 |

**結論**：

**不需要 Xcode 專案**。可以：
1. 保持現有 SPM 結構
2. 使用 `swift build` 編譯
3. 用 shell script 建立 .app bundle
4. 用 `codesign` 進行 ad-hoc 簽名

---

### 問題 6：安裝流程變更

**現有流程**：

```bash
# 編譯
swift build -c release

# 複製執行檔
cp .build/release/DesktopCleaner /usr/local/bin/desktop-cleaner

# 安裝 LaunchAgent
cp LaunchAgent/com.user.desktop-cleaner.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.user.desktop-cleaner.plist
```

**新流程**：

```bash
# 編譯
swift build -c release

# 建立 app bundle
./scripts/create-app-bundle.sh

# 複製到 Applications
cp -r DesktopCleaner.app /Applications/

# 簽名
codesign -s - --force /Applications/DesktopCleaner.app

# 更新 LaunchAgent（指向新路徑）
cp LaunchAgent/com.user.desktop-cleaner.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.user.desktop-cleaner.plist

# 手動授權（使用者需操作）
echo "請在「系統設定 → 隱私權與安全性 → Full Disk Access」中加入 DesktopCleaner"
```

**結論**：

安裝流程會稍微複雜，但可以透過 shell script 自動化大部分步驟。

---

## 方案比較

| 方案 | 優點 | 缺點 | 成本估算 |
|------|------|------|----------|
| A. 手動建立 Bundle | 簡單、無依賴、完全可控 | 需要維護 script | 低（新增 1-2 個 script） |
| B. Swift Bundler | 自動化程度高 | 額外依賴、過於複雜 | 中（學習曲線） |
| C. Xcode 專案 | 官方支援 | 破壞現有結構、繁瑣 | 高（重構專案） |

---

## 建議方案

基於以上研究，建議採用 **方案 A：手動建立 Bundle**，原因：

1. **最小改動**：保持現有 SPM 結構，僅新增打包腳本
2. **無依賴**：不引入新工具或框架
3. **完全可控**：可精確控制 bundle 內容
4. **容易維護**：腳本簡單易懂

### 實作項目

1. 建立 `Resources/Info.plist` 範本
2. 建立 `scripts/create-app-bundle.sh` 打包腳本
3. 更新 `LaunchAgent/com.user.desktop-cleaner.plist` 路徑
4. 更新安裝說明文件

---

## 待確認事項

- [ ] 安裝位置：`/Applications/` 還是 `~/Applications/`？
- [ ] 是否需要製作安裝腳本（install.sh）自動化整個流程？
- [ ] 是否需要卸載腳本（uninstall.sh）？

---

## 下一步

研究完成後，可以執行 `/design #13` 進行技術設計
