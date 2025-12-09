import Foundation
import DesktopCleanerLib

/// 整合測試
enum IntegrationTests {

    static func runAll() {
        TestFramework.runSuite("Integration Tests") {
            // 完整清理流程
            TestFramework.runTest("完整清理流程：建立測試目錄，放入新舊檔案，執行清理，驗證結果") {
                let testDir = try TestDirectory()
                defer { testDir.cleanup() }
                let cleaner = DesktopCleaner()

                // 設置測試環境
                // 1. 建立新檔案（應該保留）
                let keepFile1 = testDir.url.appendingPathComponent("keep1.txt")
                let keepFile2 = testDir.url.appendingPathComponent("keep2.pdf")
                try "keep this".write(to: keepFile1, atomically: true, encoding: .utf8)
                try "keep this too".write(to: keepFile2, atomically: true, encoding: .utf8)

                // 2. 建立舊檔案（應該清理）
                let oldFile1 = testDir.url.appendingPathComponent("old1.txt")
                let oldFile2 = testDir.url.appendingPathComponent("old2.doc")
                let oldFile3 = testDir.url.appendingPathComponent("old3.zip")
                try "delete me 1".write(to: oldFile1, atomically: true, encoding: .utf8)
                try "delete me 2".write(to: oldFile2, atomically: true, encoding: .utf8)
                try "delete me 3".write(to: oldFile3, atomically: true, encoding: .utf8)

                // 3. 建立舊目錄（應該清理）
                let oldDir = testDir.url.appendingPathComponent("old-folder")
                try FileManager.default.createDirectory(at: oldDir, withIntermediateDirectories: true)
                let fileInOldDir = oldDir.appendingPathComponent("file.txt")
                try "in old folder".write(to: fileInOldDir, atomically: true, encoding: .utf8)

                // 4. 建立隱藏檔案（不論新舊都應該忽略）
                let hiddenOld = testDir.url.appendingPathComponent(".hidden-old")
                try "hidden".write(to: hiddenOld, atomically: true, encoding: .utf8)

                // 設置舊檔案的修改時間（5 天前）
                let fiveDaysAgo = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
                try FileManager.default.setAttributes([.modificationDate: fiveDaysAgo], ofItemAtPath: oldFile1.path)
                try FileManager.default.setAttributes([.modificationDate: fiveDaysAgo], ofItemAtPath: oldFile2.path)
                try FileManager.default.setAttributes([.modificationDate: fiveDaysAgo], ofItemAtPath: oldFile3.path)
                try FileManager.default.setAttributes([.modificationDate: fiveDaysAgo], ofItemAtPath: oldDir.path)
                try FileManager.default.setAttributes([.modificationDate: fiveDaysAgo], ofItemAtPath: hiddenOld.path)

                // 執行清理
                let result = cleaner.cleanDirectory(at: testDir.url)

                // 驗證結果
                TestFramework.assertEqual(result.trashed.count, 4, "應該清理 3 個舊檔案 + 1 個舊目錄")
                TestFramework.assert(result.errors.isEmpty, "不應該有錯誤")

                // 驗證新檔案保留
                TestFramework.assert(FileManager.default.fileExists(atPath: keepFile1.path), "新檔案 1 應該保留")
                TestFramework.assert(FileManager.default.fileExists(atPath: keepFile2.path), "新檔案 2 應該保留")

                // 驗證舊檔案被清理
                TestFramework.assert(!FileManager.default.fileExists(atPath: oldFile1.path), "舊檔案 1 應該被清理")
                TestFramework.assert(!FileManager.default.fileExists(atPath: oldFile2.path), "舊檔案 2 應該被清理")
                TestFramework.assert(!FileManager.default.fileExists(atPath: oldFile3.path), "舊檔案 3 應該被清理")
                TestFramework.assert(!FileManager.default.fileExists(atPath: oldDir.path), "舊目錄應該被清理")

                // 驗證隱藏檔案被忽略（因為掃描器跳過隱藏檔案）
                TestFramework.assert(FileManager.default.fileExists(atPath: hiddenOld.path), "隱藏檔案應該被忽略")
            }

            // 邊界條件測試
            TestFramework.runTest("邊界條件：71 小時的檔案不應該被清理，73 小時的應該被清理") {
                let testDir = try TestDirectory()
                defer { testDir.cleanup() }
                let cleaner = DesktopCleaner()

                // 71 小時前的檔案（安全地小於 72 小時，不應該被清理）
                let safeFile = testDir.url.appendingPathComponent("safe-71h.txt")
                try "safe border case".write(to: safeFile, atomically: true, encoding: .utf8)
                let seventyOneHours = Calendar.current.date(byAdding: .hour, value: -71, to: Date())!
                try FileManager.default.setAttributes([.modificationDate: seventyOneHours], ofItemAtPath: safeFile.path)

                // 73 小時前的檔案（明確超過 72 小時，應該被清理）
                let oldFile = testDir.url.appendingPathComponent("old-73h.txt")
                try "old border case".write(to: oldFile, atomically: true, encoding: .utf8)
                let seventyThreeHours = Calendar.current.date(byAdding: .hour, value: -73, to: Date())!
                try FileManager.default.setAttributes([.modificationDate: seventyThreeHours], ofItemAtPath: oldFile.path)

                let result = cleaner.cleanDirectory(at: testDir.url)

                TestFramework.assertEqual(result.trashed.count, 1, "只有 73 小時的檔案應該被清理")
                TestFramework.assert(FileManager.default.fileExists(atPath: safeFile.path), "71 小時的檔案應該保留")
                TestFramework.assert(!FileManager.default.fileExists(atPath: oldFile.path), "73 小時的檔案應該被清理")
            }

            // 連續清理測試
            TestFramework.runTest("連續清理：第二次清理不應該有任何動作") {
                let testDir = try TestDirectory()
                defer { testDir.cleanup() }
                let cleaner = DesktopCleaner()

                // 建立舊檔案
                let oldFile = testDir.url.appendingPathComponent("old.txt")
                try "old".write(to: oldFile, atomically: true, encoding: .utf8)

                let fourDaysAgo = Calendar.current.date(byAdding: .day, value: -4, to: Date())!
                try FileManager.default.setAttributes([.modificationDate: fourDaysAgo], ofItemAtPath: oldFile.path)

                // 第一次清理
                let result1 = cleaner.cleanDirectory(at: testDir.url)
                TestFramework.assertEqual(result1.trashed.count, 1, "第一次清理應該清理 1 個檔案")

                // 第二次清理
                let result2 = cleaner.cleanDirectory(at: testDir.url)
                TestFramework.assert(result2.trashed.isEmpty, "第二次清理不應該有任何動作")
            }
        }
    }
}
