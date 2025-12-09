import Foundation

/// 檔案資訊結構
public struct FileInfo {
    public let url: URL           // 檔案路徑
    public let modificationDate: Date  // 最後修改時間
    public let isDirectory: Bool  // 是否為資料夾

    public init(url: URL, modificationDate: Date, isDirectory: Bool) {
        self.url = url
        self.modificationDate = modificationDate
        self.isDirectory = isDirectory
    }
}

extension FileInfo {
    /// 判斷檔案是否超過三天（72 小時）
    public var isOlderThanThreeDays: Bool {
        let threeDaysAgo = Calendar.current.date(byAdding: .hour, value: -72, to: Date()) ?? Date()
        return modificationDate < threeDaysAgo
    }

    /// 判斷檔案是否超過指定時間
    /// - Parameter date: 比較的時間點
    /// - Returns: 如果檔案修改時間早於指定時間，返回 true
    public func isOlderThan(_ date: Date) -> Bool {
        return modificationDate < date
    }

    /// 計算檔案距今多少天
    public var daysOld: Int {
        let components = Calendar.current.dateComponents([.day], from: modificationDate, to: Date())
        return components.day ?? 0
    }
}

/// 清理結果結構
public struct CleanResult {
    public let trashedFiles: [URL]   // 已移到垃圾桶的檔案
    public let errors: [Error]       // 處理過程中的錯誤

    public init(trashedFiles: [URL], errors: [Error]) {
        self.trashedFiles = trashedFiles
        self.errors = errors
    }
}

/// 預覽結果結構 - 用於 Dry-Run 模式
public struct PreviewResult {
    public let downloads: [FileInfo]  // Downloads 目錄中將被清理的檔案
    public let desktop: [FileInfo]    // Desktop 目錄中將被清理的檔案

    public init(downloads: [FileInfo], desktop: [FileInfo]) {
        self.downloads = downloads
        self.desktop = desktop
    }

    /// 所有將被清理的檔案
    public var allFiles: [FileInfo] {
        return downloads + desktop
    }

    /// 總共將被清理的檔案數量
    public var totalCount: Int {
        return downloads.count + desktop.count
    }
}
