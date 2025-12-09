import Foundation

/// 日誌事件類型
public enum LogEvent {
    case start(version: String)
    case scan(directory: String, found: Int, old: Int)
    case trash(file: String, directory: String, ageHours: Int)
    case error(file: String, errorMessage: String)
    case complete(trashed: Int, errors: Int, durationMs: Int)
}

/// 日誌記錄器 - 記錄每次執行的詳細資訊
public class Logger {
    private let logDirectory: URL
    private let dateFormatter: DateFormatter
    private let timestampFormatter: ISO8601DateFormatter

    /// 初始化日誌記錄器
    /// - Parameter logDirectory: 日誌目錄路徑（預設為 ~/.desktop-cleaner/logs/）
    public init(logDirectory: URL? = nil) {
        if let dir = logDirectory {
            self.logDirectory = dir
        } else {
            self.logDirectory = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".desktop-cleaner/logs")
        }

        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "yyyy-MM-dd"

        self.timestampFormatter = ISO8601DateFormatter()
        self.timestampFormatter.formatOptions = [.withInternetDateTime]
    }

    /// 記錄日誌事件
    /// - Parameter event: 日誌事件
    public func log(_ event: LogEvent) {
        ensureDirectoryExists()

        let entry = createEntry(for: event)
        let logFile = getLogFile(for: Date())

        appendToFile(entry: entry, file: logFile)
    }

    /// 清理超過指定天數的日誌
    /// - Parameter retentionDays: 保留天數（預設 30 天）
    public func cleanup(retentionDays: Int = 30) {
        guard FileManager.default.fileExists(atPath: logDirectory.path) else { return }

        let cutoffDate = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date()) ?? Date()

        do {
            let files = try FileManager.default.contentsOfDirectory(at: logDirectory, includingPropertiesForKeys: nil)

            for file in files {
                guard file.pathExtension == "log" else { continue }

                // 從檔名解析日期
                let fileName = file.deletingPathExtension().lastPathComponent
                if let fileDate = dateFormatter.date(from: fileName),
                   fileDate < cutoffDate {
                    try FileManager.default.removeItem(at: file)
                }
            }
        } catch {
            // 清理失敗不影響主流程，靜默處理
        }
    }

    // MARK: - Private Methods

    private func ensureDirectoryExists() {
        if !FileManager.default.fileExists(atPath: logDirectory.path) {
            try? FileManager.default.createDirectory(at: logDirectory, withIntermediateDirectories: true)
        }
    }

    private func getLogFile(for date: Date) -> URL {
        let fileName = dateFormatter.string(from: date) + ".log"
        return logDirectory.appendingPathComponent(fileName)
    }

    private func createEntry(for event: LogEvent) -> [String: Any] {
        var entry: [String: Any] = [
            "timestamp": timestampFormatter.string(from: Date())
        ]

        switch event {
        case .start(let version):
            entry["action"] = "start"
            entry["version"] = version

        case .scan(let directory, let found, let old):
            entry["action"] = "scan"
            entry["directory"] = directory
            entry["found"] = found
            entry["old"] = old

        case .trash(let file, let directory, let ageHours):
            entry["action"] = "trash"
            entry["file"] = file
            entry["directory"] = directory
            entry["age_hours"] = ageHours

        case .error(let file, let errorMessage):
            entry["action"] = "error"
            entry["file"] = file
            entry["error"] = errorMessage

        case .complete(let trashed, let errors, let durationMs):
            entry["action"] = "complete"
            entry["trashed"] = trashed
            entry["errors"] = errors
            entry["duration_ms"] = durationMs
        }

        return entry
    }

    private func appendToFile(entry: [String: Any], file: URL) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: entry, options: []),
              var jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }

        jsonString += "\n"

        if FileManager.default.fileExists(atPath: file.path) {
            // 追加到現有檔案
            if let handle = try? FileHandle(forWritingTo: file) {
                handle.seekToEndOfFile()
                if let data = jsonString.data(using: .utf8) {
                    handle.write(data)
                }
                try? handle.close()
            }
        } else {
            // 建立新檔案
            try? jsonString.write(to: file, atomically: true, encoding: .utf8)
        }
    }
}
