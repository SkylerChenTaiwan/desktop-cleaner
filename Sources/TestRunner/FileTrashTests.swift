import Foundation
import DesktopCleanerLib

/// FileTrash 單元測試
enum FileTrashTests {

    static func runAll() {
        TestFramework.runSuite("FileTrash Tests") {
            // 成功移到垃圾桶
            TestFramework.runTest("成功將檔案移到垃圾桶") {
                let testDir = try TestDirectory()
                defer { testDir.cleanup() }
                let trash = FileTrash()

                let testFile = testDir.url.appendingPathComponent("to-trash.txt")
                try "trash me".write(to: testFile, atomically: true, encoding: .utf8)

                // 確認檔案存在
                TestFramework.assert(FileManager.default.fileExists(atPath: testFile.path), "測試檔案應該存在")

                let result = trash.trash(at: testFile)

                TestFramework.assert(result, "移到垃圾桶應該成功")
                TestFramework.assert(!FileManager.default.fileExists(atPath: testFile.path), "原始檔案應該不存在")
            }

            // 處理不存在的檔案
            TestFramework.runTest("處理不存在的檔案應該返回 false") {
                let testDir = try TestDirectory()
                defer { testDir.cleanup() }
                let trash = FileTrash()

                let nonExistent = testDir.url.appendingPathComponent("non-existent.txt")

                let result = trash.trash(at: nonExistent)

                TestFramework.assert(!result, "移動不存在的檔案應該返回 false")
            }

            // 移動目錄到垃圾桶
            TestFramework.runTest("成功將目錄移到垃圾桶") {
                let testDir = try TestDirectory()
                defer { testDir.cleanup() }
                let trash = FileTrash()

                let subDir = testDir.url.appendingPathComponent("folder-to-trash")
                try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)

                // 在目錄中放置檔案
                let fileInDir = subDir.appendingPathComponent("file.txt")
                try "content".write(to: fileInDir, atomically: true, encoding: .utf8)

                // 確認目錄存在
                TestFramework.assert(FileManager.default.fileExists(atPath: subDir.path), "測試目錄應該存在")

                let result = trash.trash(at: subDir)

                TestFramework.assert(result, "移動目錄到垃圾桶應該成功")
                TestFramework.assert(!FileManager.default.fileExists(atPath: subDir.path), "原始目錄應該不存在")
            }
        }
    }
}
