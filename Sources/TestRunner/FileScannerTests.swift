import Foundation
import DesktopCleanerLib

/// FileScanner 單元測試
enum FileScannerTests {

    static func runAll() {
        TestFramework.runSuite("FileScanner Tests") {
            // 掃描空資料夾
            TestFramework.runTest("掃描空目錄應該返回空陣列") {
                let testDir = try TestDirectory()
                defer { testDir.cleanup() }
                let scanner = FileScanner()

                let result = scanner.scan(at: testDir.url)

                TestFramework.assert(result.isEmpty, "掃描空目錄應該返回空陣列")
            }

            // 掃描有檔案的資料夾
            TestFramework.runTest("掃描含檔案的目錄應該返回正確數量的 FileInfo") {
                let testDir = try TestDirectory()
                defer { testDir.cleanup() }
                let scanner = FileScanner()

                let file1 = testDir.url.appendingPathComponent("file1.txt")
                let file2 = testDir.url.appendingPathComponent("file2.txt")
                let file3 = testDir.url.appendingPathComponent("file3.txt")

                try "content1".write(to: file1, atomically: true, encoding: .utf8)
                try "content2".write(to: file2, atomically: true, encoding: .utf8)
                try "content3".write(to: file3, atomically: true, encoding: .utf8)

                let result = scanner.scan(at: testDir.url)

                TestFramework.assertEqual(result.count, 3, "應該掃描到 3 個檔案")

                let fileNames = result.map { $0.url.lastPathComponent }.sorted()
                TestFramework.assertEqual(fileNames, ["file1.txt", "file2.txt", "file3.txt"], "檔案名稱應該正確")
            }

            // 掃描檔案返回正確的 FileInfo 資訊
            TestFramework.runTest("掃描檔案應該返回正確的 FileInfo 資訊") {
                let testDir = try TestDirectory()
                defer { testDir.cleanup() }
                let scanner = FileScanner()

                let testFile = testDir.url.appendingPathComponent("test.txt")
                try "test content".write(to: testFile, atomically: true, encoding: .utf8)

                let result = scanner.scan(at: testDir.url)

                TestFramework.assertEqual(result.count, 1, "應該掃描到 1 個檔案")
                let fileInfo = result[0]
                TestFramework.assertEqual(fileInfo.url.lastPathComponent, "test.txt", "檔案名稱應該正確")
                TestFramework.assert(!fileInfo.isDirectory, "應該不是目錄")
                TestFramework.assert(fileInfo.modificationDate.timeIntervalSinceNow > -60, "修改時間應該接近現在")
            }

            // 掃描子目錄應該正確識別
            TestFramework.runTest("掃描子目錄應該正確識別為目錄") {
                let testDir = try TestDirectory()
                defer { testDir.cleanup() }
                let scanner = FileScanner()

                let subDir = testDir.url.appendingPathComponent("subdir")
                try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)

                let result = scanner.scan(at: testDir.url)

                TestFramework.assertEqual(result.count, 1, "應該掃描到 1 個項目")
                TestFramework.assert(result[0].isDirectory, "應該識別為目錄")
            }

            // 跳過隱藏檔案
            TestFramework.runTest("掃描應該跳過隱藏檔案") {
                let testDir = try TestDirectory()
                defer { testDir.cleanup() }
                let scanner = FileScanner()

                let normalFile = testDir.url.appendingPathComponent("visible.txt")
                let hiddenFile = testDir.url.appendingPathComponent(".hidden")
                let dsStore = testDir.url.appendingPathComponent(".DS_Store")

                try "visible".write(to: normalFile, atomically: true, encoding: .utf8)
                try "hidden".write(to: hiddenFile, atomically: true, encoding: .utf8)
                try "dsstore".write(to: dsStore, atomically: true, encoding: .utf8)

                let result = scanner.scan(at: testDir.url)

                TestFramework.assertEqual(result.count, 1, "應該只掃描到 1 個可見檔案")
                TestFramework.assertEqual(result[0].url.lastPathComponent, "visible.txt", "應該是可見檔案")
            }

            // 處理不存在的資料夾
            TestFramework.runTest("掃描不存在的目錄應該返回空陣列") {
                let testDir = try TestDirectory()
                defer { testDir.cleanup() }
                let scanner = FileScanner()

                let nonExistent = testDir.url.appendingPathComponent("does-not-exist")

                let result = scanner.scan(at: nonExistent)

                TestFramework.assert(result.isEmpty, "掃描不存在的目錄應該返回空陣列")
            }

            // 混合場景
            TestFramework.runTest("掃描混合內容目錄應該只返回可見項目") {
                let testDir = try TestDirectory()
                defer { testDir.cleanup() }
                let scanner = FileScanner()

                let file1 = testDir.url.appendingPathComponent("document.pdf")
                let file2 = testDir.url.appendingPathComponent("image.png")
                let subDir = testDir.url.appendingPathComponent("folder")
                let hidden = testDir.url.appendingPathComponent(".config")

                try "pdf".write(to: file1, atomically: true, encoding: .utf8)
                try "png".write(to: file2, atomically: true, encoding: .utf8)
                try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)
                try "config".write(to: hidden, atomically: true, encoding: .utf8)

                let result = scanner.scan(at: testDir.url)

                TestFramework.assertEqual(result.count, 3, "應該掃描到 2 個檔案和 1 個目錄")

                let fileCount = result.filter { !$0.isDirectory }.count
                let dirCount = result.filter { $0.isDirectory }.count
                TestFramework.assertEqual(fileCount, 2, "應該有 2 個檔案")
                TestFramework.assertEqual(dirCount, 1, "應該有 1 個目錄")
            }
        }
    }
}
