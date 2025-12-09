import Foundation
import DesktopCleanerLib

/// DesktopCleaner 單元測試
enum DesktopCleanerTests {

    static func runAll() {
        TestFramework.runSuite("DesktopCleaner Tests") {
            // 清理超過三天的檔案
            TestFramework.runTest("清理超過三天的檔案") {
                let testDir = try TestDirectory()
                defer { testDir.cleanup() }
                let cleaner = DesktopCleaner()

                // 建立舊檔案（模擬超過三天）
                let oldFile = testDir.url.appendingPathComponent("old-file.txt")
                try "old content".write(to: oldFile, atomically: true, encoding: .utf8)

                // 修改檔案時間為 4 天前
                let fourDaysAgo = Calendar.current.date(byAdding: .day, value: -4, to: Date())!
                try FileManager.default.setAttributes([.modificationDate: fourDaysAgo], ofItemAtPath: oldFile.path)

                // 確認檔案存在
                TestFramework.assert(FileManager.default.fileExists(atPath: oldFile.path), "舊檔案應該存在")

                let result = cleaner.cleanDirectory(at: testDir.url)

                TestFramework.assertEqual(result.trashed.count, 1, "應該移動 1 個舊檔案到垃圾桶")
                TestFramework.assert(result.errors.isEmpty, "不應該有錯誤")
                TestFramework.assert(!FileManager.default.fileExists(atPath: oldFile.path), "舊檔案應該被移除")
            }

            // 保留三天內的檔案
            TestFramework.runTest("保留三天內的檔案") {
                let testDir = try TestDirectory()
                defer { testDir.cleanup() }
                let cleaner = DesktopCleaner()

                // 建立新檔案（剛建立的）
                let newFile = testDir.url.appendingPathComponent("new-file.txt")
                try "new content".write(to: newFile, atomically: true, encoding: .utf8)

                // 確認檔案存在
                TestFramework.assert(FileManager.default.fileExists(atPath: newFile.path), "新檔案應該存在")

                let result = cleaner.cleanDirectory(at: testDir.url)

                TestFramework.assert(result.trashed.isEmpty, "不應該移動新檔案")
                TestFramework.assert(result.errors.isEmpty, "不應該有錯誤")
                TestFramework.assert(FileManager.default.fileExists(atPath: newFile.path), "新檔案應該保留")
            }

            // 處理空資料夾
            TestFramework.runTest("處理空資料夾應該返回空結果") {
                let testDir = try TestDirectory()
                defer { testDir.cleanup() }
                let cleaner = DesktopCleaner()

                let result = cleaner.cleanDirectory(at: testDir.url)

                TestFramework.assert(result.trashed.isEmpty, "空目錄不應該有任何移動")
                TestFramework.assert(result.errors.isEmpty, "不應該有錯誤")
            }

            // 混合新舊檔案
            TestFramework.runTest("混合新舊檔案只清理舊的") {
                let testDir = try TestDirectory()
                defer { testDir.cleanup() }
                let cleaner = DesktopCleaner()

                // 建立新檔案
                let newFile = testDir.url.appendingPathComponent("new.txt")
                try "new".write(to: newFile, atomically: true, encoding: .utf8)

                // 建立舊檔案
                let oldFile1 = testDir.url.appendingPathComponent("old1.txt")
                let oldFile2 = testDir.url.appendingPathComponent("old2.txt")
                try "old1".write(to: oldFile1, atomically: true, encoding: .utf8)
                try "old2".write(to: oldFile2, atomically: true, encoding: .utf8)

                // 修改舊檔案時間
                let fiveDaysAgo = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
                try FileManager.default.setAttributes([.modificationDate: fiveDaysAgo], ofItemAtPath: oldFile1.path)
                try FileManager.default.setAttributes([.modificationDate: fiveDaysAgo], ofItemAtPath: oldFile2.path)

                let result = cleaner.cleanDirectory(at: testDir.url)

                TestFramework.assertEqual(result.trashed.count, 2, "應該移動 2 個舊檔案")
                TestFramework.assert(result.errors.isEmpty, "不應該有錯誤")
                TestFramework.assert(FileManager.default.fileExists(atPath: newFile.path), "新檔案應該保留")
                TestFramework.assert(!FileManager.default.fileExists(atPath: oldFile1.path), "舊檔案 1 應該被移除")
                TestFramework.assert(!FileManager.default.fileExists(atPath: oldFile2.path), "舊檔案 2 應該被移除")
            }

            // 測試 FileInfo.isOlderThanThreeDays
            TestFramework.runTest("FileInfo.isOlderThanThreeDays 計算正確") {
                let now = Date()

                // 2 天前的檔案（明確小於 72 小時）
                let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: now)!
                let recentFile = FileInfo(
                    url: URL(fileURLWithPath: "/tmp/recent.txt"),
                    modificationDate: twoDaysAgo,
                    isDirectory: false
                )
                TestFramework.assert(!recentFile.isOlderThanThreeDays, "2 天前的檔案不應該被標記為超過三天")

                // 4 天前的檔案（明確超過 72 小時）
                let fourDaysAgo = Calendar.current.date(byAdding: .day, value: -4, to: now)!
                let oldFile = FileInfo(
                    url: URL(fileURLWithPath: "/tmp/old.txt"),
                    modificationDate: fourDaysAgo,
                    isDirectory: false
                )
                TestFramework.assert(oldFile.isOlderThanThreeDays, "4 天前的檔案應該被標記為超過三天")

                // 71 小時前的檔案（安全地小於 72 小時）
                let seventyOneHours = Calendar.current.date(byAdding: .hour, value: -71, to: now)!
                let safeBorderFile = FileInfo(
                    url: URL(fileURLWithPath: "/tmp/safe-border.txt"),
                    modificationDate: seventyOneHours,
                    isDirectory: false
                )
                TestFramework.assert(!safeBorderFile.isOlderThanThreeDays, "71 小時前的檔案不應該被標記為超過三天")

                // 73 小時前的檔案（明確超過 72 小時）
                let seventyThreeHours = Calendar.current.date(byAdding: .hour, value: -73, to: now)!
                let oldBorderFile = FileInfo(
                    url: URL(fileURLWithPath: "/tmp/old-border.txt"),
                    modificationDate: seventyThreeHours,
                    isDirectory: false
                )
                TestFramework.assert(oldBorderFile.isOlderThanThreeDays, "73 小時前的檔案應該被標記為超過三天")
            }
        }
    }
}
