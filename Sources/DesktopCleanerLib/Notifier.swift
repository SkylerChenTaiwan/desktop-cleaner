import Foundation

/// macOS 通知功能
public struct Notifier {
    public static let defaultTitle = "Desktop Cleaner"

    public init() {}

    /// 根據清理結果產生通知訊息
    /// - Parameters:
    ///   - trashedCount: 已清理的檔案數量
    ///   - errorCount: 錯誤數量
    /// - Returns: 通知訊息
    public func buildMessage(trashedCount: Int, errorCount: Int) -> String {
        var message: String

        if trashedCount > 0 {
            message = "已清理 \(trashedCount) 個檔案"
        } else {
            message = "沒有需要清理的檔案"
        }

        if errorCount > 0 {
            message += "，\(errorCount) 個錯誤"
        }

        return message
    }

    /// 發送 macOS 通知
    /// - Parameters:
    ///   - title: 通知標題
    ///   - message: 通知內容
    /// - Returns: 是否成功發送
    @discardableResult
    public func send(title: String, message: String) -> Bool {
        // 使用 osascript 呼叫 AppleScript 顯示通知
        let escapedMessage = message.replacingOccurrences(of: "\"", with: "\\\"")
        let escapedTitle = title.replacingOccurrences(of: "\"", with: "\\\"")

        let script = "display notification \"\(escapedMessage)\" with title \"\(escapedTitle)\""

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]

        // 靜音 stdout/stderr
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    /// 根據清理結果發送通知
    /// - Parameter result: 清理結果
    /// - Returns: 是否成功發送
    @discardableResult
    public func notify(result: CleanResult) -> Bool {
        let message = buildMessage(
            trashedCount: result.trashedFiles.count,
            errorCount: result.errors.count
        )
        return send(title: Self.defaultTitle, message: message)
    }
}
