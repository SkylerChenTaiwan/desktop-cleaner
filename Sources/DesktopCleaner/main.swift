import Foundation
import DesktopCleanerLib

// 解析 CLI 參數
let arguments = CommandLine.arguments
let isDryRun = arguments.contains("--dry-run")

let cleaner = DesktopCleaner()

if isDryRun {
    // 預覽模式
    let preview = cleaner.preview()

    if preview.totalCount == 0 {
        print("[Dry-Run 模式] 沒有需要清理的檔案")
    } else {
        print("[Dry-Run 模式] 以下檔案將會被清理：")

        if !preview.downloads.isEmpty {
            print("\nDownloads:")
            for file in preview.downloads {
                print("  - \(file.url.lastPathComponent) (\(file.daysOld) 天前)")
            }
        }

        if !preview.desktop.isEmpty {
            print("\nDesktop:")
            for file in preview.desktop {
                print("  - \(file.url.lastPathComponent) (\(file.daysOld) 天前)")
            }
        }

        print("\n共 \(preview.totalCount) 個檔案將被移到垃圾桶")
        print("（使用 desktop-cleaner 實際執行清理）")
    }
} else {
    // 正常清理模式
    let result = cleaner.clean()

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
}
