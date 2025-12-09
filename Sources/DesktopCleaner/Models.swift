import Foundation

/// 檔案資訊結構
struct FileInfo {
    let url: URL           // 檔案路徑
    let modificationDate: Date  // 最後修改時間
    let isDirectory: Bool  // 是否為資料夾
}

extension FileInfo {
    /// 判斷檔案是否超過三天（72 小時）
    var isOlderThanThreeDays: Bool {
        let threeDaysAgo = Calendar.current.date(byAdding: .hour, value: -72, to: Date()) ?? Date()
        return modificationDate < threeDaysAgo
    }
}

/// 清理結果結構
struct CleanResult {
    let trashedFiles: [URL]   // 已移到垃圾桶的檔案
    let errors: [Error]       // 處理過程中的錯誤
}
