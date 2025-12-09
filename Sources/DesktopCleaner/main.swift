import Foundation
import DesktopCleanerLib

// 解析命令列參數
let arguments = CommandLine.arguments
let isDryRun = arguments.contains("--dry-run")

// 程式進入點
let cleaner = DesktopCleaner()
let result = cleaner.clean()

// 輸出結果
print("清理完成")
print("已移到垃圾桶：\(result.trashedFiles.count) 個檔案")

if !result.trashedFiles.isEmpty {
    print("\n已處理的檔案：")
    for file in result.trashedFiles {
        print("  - \(file.lastPathComponent)")
    }
}

if !result.errors.isEmpty {
    print("\n錯誤：\(result.errors.count) 個")
    for error in result.errors {
        print("  - \(error.localizedDescription)")
    }
}

// Dry-run 模式不發送通知
if !isDryRun {
    let notifier = Notifier()
    notifier.notify(result: result)
}
