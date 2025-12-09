import Foundation
import DesktopCleanerLib

print("🧪 Desktop Cleaner 測試套件")
print("=" + String(repeating: "=", count: 49))
print("執行時間: \(Date())")
print("=" + String(repeating: "=", count: 49))

// 執行所有測試
FileScannerTests.runAll()
FileTrashTests.runAll()
SymlinkTests.runAll()
DesktopCleanerTests.runAll()
DryRunTests.runAll()
IntegrationTests.runAll()
NotifierTests.runAll()

// 輸出結果摘要
TestFramework.printSummary()

// 以適當的狀態碼退出
TestFramework.exitWithStatus()
