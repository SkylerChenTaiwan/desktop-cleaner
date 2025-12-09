import Foundation
import DesktopCleanerLib

/// 日誌功能測試
struct LoggerTests {
    static func runAll() {
        TestFramework.runSuite("LoggerTests") {
            testLogDirectoryCreation()
            testLogFileNaming()
            testLogEntryFormat()
            testLogCleanup()
        }
    }

    /// 測試日誌目錄自動建立
    static func testLogDirectoryCreation() {
        TestFramework.runTest("日誌目錄自動建立") {
            // Arrange: 建立測試用的 Logger（使用臨時目錄）
            let testDir = try TestDirectory()
            defer { testDir.cleanup() }

            let logDir = testDir.url.appendingPathComponent("logs")
            let logger = Logger(logDirectory: logDir)

            // Act: 寫入一筆日誌
            logger.log(.start(version: "1.0.0"))

            // Assert: 目錄應該被建立
            TestFramework.assert(
                FileManager.default.fileExists(atPath: logDir.path),
                "日誌目錄應該被自動建立"
            )
        }
    }

    /// 測試日誌檔案正確命名（當天日期）
    static func testLogFileNaming() {
        TestFramework.runTest("日誌檔案正確命名（當天日期）") {
            // Arrange
            let testDir = try TestDirectory()
            defer { testDir.cleanup() }

            let logDir = testDir.url.appendingPathComponent("logs")
            let logger = Logger(logDirectory: logDir)

            // Act: 寫入日誌
            logger.log(.start(version: "1.0.0"))

            // Assert: 檔案名稱應該是當天日期
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let expectedFileName = dateFormatter.string(from: Date()) + ".log"
            let expectedFile = logDir.appendingPathComponent(expectedFileName)

            TestFramework.assert(
                FileManager.default.fileExists(atPath: expectedFile.path),
                "日誌檔案應該以當天日期命名：\(expectedFileName)"
            )
        }
    }

    /// 測試 JSON 格式正確可解析
    static func testLogEntryFormat() {
        TestFramework.runTest("JSON 格式正確可解析") {
            // Arrange
            let testDir = try TestDirectory()
            defer { testDir.cleanup() }

            let logDir = testDir.url.appendingPathComponent("logs")
            let logger = Logger(logDirectory: logDir)

            // Act: 寫入多種類型的日誌
            logger.log(.start(version: "1.0.0"))
            logger.log(.scan(directory: "Downloads", found: 15, old: 3))
            logger.log(.trash(file: "old-file.zip", directory: "Downloads", ageHours: 120))
            logger.log(.error(file: "locked.txt", errorMessage: "Permission denied"))
            logger.log(.complete(trashed: 5, errors: 1, durationMs: 1523))

            // Assert: 讀取檔案並解析每一行
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let logFile = logDir.appendingPathComponent(dateFormatter.string(from: Date()) + ".log")
            let content = try String(contentsOf: logFile, encoding: .utf8)
            let lines = content.components(separatedBy: "\n").filter { !$0.isEmpty }

            TestFramework.assertEqual(lines.count, 5, "應該有 5 行日誌")

            // 驗證每行都是有效的 JSON
            let decoder = JSONDecoder()
            var allValid = true
            for line in lines {
                if let data = line.data(using: .utf8) {
                    do {
                        _ = try decoder.decode(LogEntryData.self, from: data)
                    } catch {
                        allValid = false
                        break
                    }
                } else {
                    allValid = false
                    break
                }
            }

            TestFramework.assert(allValid, "所有日誌行應該是有效的 JSON 格式")
        }
    }

    /// 測試超過 30 天的日誌被清理
    static func testLogCleanup() {
        TestFramework.runTest("超過 30 天的日誌被清理") {
            // Arrange
            let testDir = try TestDirectory()
            defer { testDir.cleanup() }

            let logDir = testDir.url.appendingPathComponent("logs")
            try FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true)

            // 建立一個 40 天前的日誌檔案
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let oldDate = Calendar.current.date(byAdding: .day, value: -40, to: Date())!
            let oldFileName = dateFormatter.string(from: oldDate) + ".log"
            let oldFile = logDir.appendingPathComponent(oldFileName)
            try "old log".write(to: oldFile, atomically: true, encoding: .utf8)

            // 建立一個 10 天前的日誌檔案（應該保留）
            let recentDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
            let recentFileName = dateFormatter.string(from: recentDate) + ".log"
            let recentFile = logDir.appendingPathComponent(recentFileName)
            try "recent log".write(to: recentFile, atomically: true, encoding: .utf8)

            let logger = Logger(logDirectory: logDir)

            // Act: 執行清理
            logger.cleanup(retentionDays: 30)

            // Assert
            TestFramework.assert(
                !FileManager.default.fileExists(atPath: oldFile.path),
                "超過 30 天的日誌應該被刪除"
            )
            TestFramework.assert(
                FileManager.default.fileExists(atPath: recentFile.path),
                "未超過 30 天的日誌應該保留"
            )
        }
    }
}

/// 用於解析日誌 JSON 的結構（僅用於測試驗證）
private struct LogEntryData: Decodable {
    let timestamp: String
    let action: String
}
