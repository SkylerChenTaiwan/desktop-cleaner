import Foundation
import DesktopCleanerLib

/// Symlink 安全處理測試
enum SymlinkTests {

    static func runAll() {
        TestFramework.runSuite("Symlink Tests") {
            // 測試 1: Symlink 應該移動連結本身而非目標
            TestFramework.runTest("Symlink 應該移動連結本身而非目標") {
                let testDir = try TestDirectory()
                defer { testDir.cleanup() }
                let trash = FileTrash()

                // 建立目標檔案（在測試目錄的子目錄中，模擬「目錄外」的情境）
                let targetDir = testDir.url.appendingPathComponent("target-dir")
                try FileManager.default.createDirectory(at: targetDir, withIntermediateDirectories: true)
                let targetFile = targetDir.appendingPathComponent("target.txt")
                let targetContent = "這是目標檔案的內容，不應該被刪除"
                try targetContent.write(to: targetFile, atomically: true, encoding: .utf8)

                // 建立掃描目錄（symlink 會放在這裡）
                let scanDir = testDir.url.appendingPathComponent("scan-dir")
                try FileManager.default.createDirectory(at: scanDir, withIntermediateDirectories: true)

                // 建立 symlink 指向目標檔案
                let symlink = scanDir.appendingPathComponent("link.txt")
                try FileManager.default.createSymbolicLink(at: symlink, withDestinationURL: targetFile)

                // 確認 symlink 和目標檔案都存在
                TestFramework.assert(FileManager.default.fileExists(atPath: symlink.path), "Symlink 應該存在")
                TestFramework.assert(FileManager.default.fileExists(atPath: targetFile.path), "目標檔案應該存在")

                // 執行移動到垃圾桶
                let result = trash.trash(at: symlink)

                // 驗證結果
                TestFramework.assert(result, "移動 symlink 到垃圾桶應該成功")
                TestFramework.assert(!FileManager.default.fileExists(atPath: symlink.path), "Symlink 應該被移除")
                TestFramework.assert(FileManager.default.fileExists(atPath: targetFile.path), "目標檔案應該仍然存在（未被刪除）")
            }

            // 測試 2: Symlink 指向的目標檔案不受影響（驗證內容完整性）
            TestFramework.runTest("Symlink 指向的目標檔案內容不受影響") {
                let testDir = try TestDirectory()
                defer { testDir.cleanup() }
                let trash = FileTrash()

                // 建立目標檔案
                let targetFile = testDir.url.appendingPathComponent("important-file.txt")
                let originalContent = "重要資料：這些內容必須完整保留！\n包含多行內容\n確保完全不受影響"
                try originalContent.write(to: targetFile, atomically: true, encoding: .utf8)

                // 建立 symlink
                let symlink = testDir.url.appendingPathComponent("shortcut.txt")
                try FileManager.default.createSymbolicLink(at: symlink, withDestinationURL: targetFile)

                // 移動 symlink 到垃圾桶
                let result = trash.trash(at: symlink)
                TestFramework.assert(result, "移動 symlink 到垃圾桶應該成功")

                // 讀取目標檔案內容並驗證
                let remainingContent = try String(contentsOf: targetFile, encoding: .utf8)
                TestFramework.assertEqual(remainingContent, originalContent, "目標檔案內容應該完全相同")
            }
        }
    }
}
