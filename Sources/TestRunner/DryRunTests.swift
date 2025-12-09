import Foundation
import DesktopCleanerLib

/// Dry-Run 預覽模式測試
enum DryRunTests {

    static func runAll() {
        TestFramework.runSuite("Dry-Run Tests") {
            // preview() 返回正確的檔案列表
            TestFramework.runTest("preview() 返回正確的檔案列表") {
                let testDir = try TestDirectory()
                defer { testDir.cleanup() }

                let scanner = FileScanner()
                let trash = FileTrash()
                let cleaner = DesktopCleaner(scanner: scanner, trash: trash)

                // 建立舊檔案（超過三天）
                let oldFile1 = testDir.url.appendingPathComponent("old1.txt")
                let oldFile2 = testDir.url.appendingPathComponent("old2.txt")
                try "old1".write(to: oldFile1, atomically: true, encoding: .utf8)
                try "old2".write(to: oldFile2, atomically: true, encoding: .utf8)

                // 修改檔案時間為 4 天前
                let fourDaysAgo = Calendar.current.date(byAdding: .day, value: -4, to: Date())!
                try FileManager.default.setAttributes([.modificationDate: fourDaysAgo], ofItemAtPath: oldFile1.path)
                try FileManager.default.setAttributes([.modificationDate: fourDaysAgo], ofItemAtPath: oldFile2.path)

                // 建立新檔案（不到三天）
                let newFile = testDir.url.appendingPathComponent("new.txt")
                try "new".write(to: newFile, atomically: true, encoding: .utf8)

                let result = cleaner.previewDirectory(at: testDir.url)

                TestFramework.assertEqual(result.count, 2, "應該返回 2 個舊檔案")
                let fileNames = result.map { $0.url.lastPathComponent }.sorted()
                TestFramework.assertEqual(fileNames, ["old1.txt", "old2.txt"], "檔案名稱應該正確")
            }

            // preview() 不會刪除任何檔案
            TestFramework.runTest("preview() 不會刪除任何檔案") {
                let testDir = try TestDirectory()
                defer { testDir.cleanup() }

                let scanner = FileScanner()
                let trash = FileTrash()
                let cleaner = DesktopCleaner(scanner: scanner, trash: trash)

                // 建立舊檔案
                let oldFile = testDir.url.appendingPathComponent("old.txt")
                try "old".write(to: oldFile, atomically: true, encoding: .utf8)

                let fourDaysAgo = Calendar.current.date(byAdding: .day, value: -4, to: Date())!
                try FileManager.default.setAttributes([.modificationDate: fourDaysAgo], ofItemAtPath: oldFile.path)

                // 執行 preview
                _ = cleaner.previewDirectory(at: testDir.url)

                // 檔案應該還存在
                TestFramework.assert(FileManager.default.fileExists(atPath: oldFile.path), "preview() 不應該刪除檔案")
            }

            // PreviewResult 正確分類 Downloads 和 Desktop 檔案
            TestFramework.runTest("PreviewResult 正確分類檔案") {
                // 建立兩個測試目錄模擬 Downloads 和 Desktop
                let downloadsDir = try TestDirectory()
                let desktopDir = try TestDirectory()
                defer {
                    downloadsDir.cleanup()
                    desktopDir.cleanup()
                }

                // 在 Downloads 建立舊檔案
                let downloadFile = downloadsDir.url.appendingPathComponent("download.zip")
                try "download".write(to: downloadFile, atomically: true, encoding: .utf8)
                let fourDaysAgo = Calendar.current.date(byAdding: .day, value: -4, to: Date())!
                try FileManager.default.setAttributes([.modificationDate: fourDaysAgo], ofItemAtPath: downloadFile.path)

                // 在 Desktop 建立舊檔案
                let desktopFile = desktopDir.url.appendingPathComponent("screenshot.png")
                try "screenshot".write(to: desktopFile, atomically: true, encoding: .utf8)
                try FileManager.default.setAttributes([.modificationDate: fourDaysAgo], ofItemAtPath: desktopFile.path)

                let scanner = FileScanner()
                let downloadFiles = scanner.scan(at: downloadsDir.url).filter { $0.isOlderThanThreeDays }
                let desktopFiles = scanner.scan(at: desktopDir.url).filter { $0.isOlderThanThreeDays }

                let result = PreviewResult(downloads: downloadFiles, desktop: desktopFiles)

                TestFramework.assertEqual(result.downloads.count, 1, "Downloads 應該有 1 個檔案")
                TestFramework.assertEqual(result.desktop.count, 1, "Desktop 應該有 1 個檔案")
                TestFramework.assertEqual(result.totalCount, 2, "總共應該有 2 個檔案")
                TestFramework.assertEqual(result.downloads[0].url.lastPathComponent, "download.zip", "Downloads 檔案名稱正確")
                TestFramework.assertEqual(result.desktop[0].url.lastPathComponent, "screenshot.png", "Desktop 檔案名稱正確")
            }

            // 檔齡計算正確
            TestFramework.runTest("檔齡計算正確") {
                let now = Date()

                // 5 天前的檔案
                let fiveDaysAgo = Calendar.current.date(byAdding: .day, value: -5, to: now)!
                let fileInfo = FileInfo(
                    url: URL(fileURLWithPath: "/tmp/old.txt"),
                    modificationDate: fiveDaysAgo,
                    isDirectory: false
                )

                let days = fileInfo.daysOld
                TestFramework.assert(days >= 4 && days <= 5, "5 天前的檔案應該顯示 4-5 天前")

                // 3 天前的檔案
                let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: now)!
                let fileInfo2 = FileInfo(
                    url: URL(fileURLWithPath: "/tmp/recent.txt"),
                    modificationDate: threeDaysAgo,
                    isDirectory: false
                )

                let days2 = fileInfo2.daysOld
                TestFramework.assert(days2 >= 2 && days2 <= 3, "3 天前的檔案應該顯示 2-3 天前")
            }
        }
    }
}
