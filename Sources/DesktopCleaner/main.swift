import Foundation
import DesktopCleanerLib

// 解析命令列參數
let arguments = CommandLine.arguments
let isDryRun = arguments.contains("--dry-run")

// 初始化日誌記錄器
let logger = Logger()
let startTime = Date()

// 記錄開始
logger.log(.start(version: "1.0.0"))

// 程式進入點
let cleaner = DesktopCleaner()

// 掃描並記錄各目錄狀態
let scanner = FileScanner()

// 掃描下載資料夾
let downloadFiles = scanner.scan(at: .downloads)
let oldDownloadFiles = downloadFiles.filter { $0.isOlderThanThreeDays }
logger.log(.scan(directory: "Downloads", found: downloadFiles.count, old: oldDownloadFiles.count))

// 掃描桌面資料夾
let desktopFiles = scanner.scan(at: .desktop)
let oldDesktopFiles = desktopFiles.filter { $0.isOlderThanThreeDays }
logger.log(.scan(directory: "Desktop", found: desktopFiles.count, old: oldDesktopFiles.count))

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

    // 記錄完成（dry-run 模式，沒有實際刪除）
    let durationMs = Int(Date().timeIntervalSince(startTime) * 1000)
    logger.log(.complete(trashed: 0, errors: 0, durationMs: durationMs))
} else {
    // 正常清理模式
    let result = cleaner.clean()

    // 記錄每個被刪除的檔案
    for file in result.trashedFiles {
        // 判斷檔案來源目錄
        let directory = file.path.contains("/Downloads/") ? "Downloads" : "Desktop"

        // 計算檔案年齡（小時）
        let ageHours: Int
        if let fileInfo = (downloadFiles + desktopFiles).first(where: { $0.url == file }) {
            ageHours = Int(Date().timeIntervalSince(fileInfo.modificationDate) / 3600)
        } else {
            ageHours = 72  // 預設值
        }

        logger.log(.trash(file: file.lastPathComponent, directory: directory, ageHours: ageHours))
    }

    // 記錄錯誤
    for error in result.errors {
        logger.log(.error(file: "unknown", errorMessage: error.localizedDescription))
    }

    // 計算執行時間並記錄完成
    let durationMs = Int(Date().timeIntervalSince(startTime) * 1000)
    logger.log(.complete(trashed: result.trashedFiles.count, errors: result.errors.count, durationMs: durationMs))

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

    // 正常模式發送通知
    let notifier = Notifier()
    notifier.notify(result: result)
}

// 清理超過 30 天的日誌
logger.cleanup(retentionDays: 30)
