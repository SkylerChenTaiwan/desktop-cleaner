import Foundation

/// URL 擴充 - 提供常用資料夾路徑
public extension URL {
    static var downloads: URL {
        FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
    }

    static var desktop: URL {
        FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0]
    }
}

/// 清理邏輯協調器 - 整合掃描和刪除流程
public class DesktopCleaner {
    private let scanner: FileScanner
    private let trash: FileTrash

    public init(scanner: FileScanner = FileScanner(), trash: FileTrash = FileTrash()) {
        self.scanner = scanner
        self.trash = trash
    }

    /// 執行清理作業（掃描下載和桌面資料夾）
    /// - Returns: 清理結果
    public func clean() -> CleanResult {
        var allTrashedFiles: [URL] = []
        var allErrors: [Error] = []

        // 清理下載資料夾
        let downloadsResult = cleanDirectory(at: .downloads)
        allTrashedFiles.append(contentsOf: downloadsResult.trashed)
        allErrors.append(contentsOf: downloadsResult.errors)

        // 清理桌面資料夾
        let desktopResult = cleanDirectory(at: .desktop)
        allTrashedFiles.append(contentsOf: desktopResult.trashed)
        allErrors.append(contentsOf: desktopResult.errors)

        return CleanResult(trashedFiles: allTrashedFiles, errors: allErrors)
    }

    /// 清理指定資料夾中超過三天的檔案
    /// - Parameter directory: 要清理的資料夾路徑
    /// - Returns: 已移到垃圾桶的檔案和錯誤
    public func cleanDirectory(at directory: URL) -> (trashed: [URL], errors: [Error]) {
        var trashedFiles: [URL] = []
        var errors: [Error] = []

        // 掃描資料夾
        let files = scanner.scan(at: directory)

        // 過濾超過三天的檔案並移到垃圾桶
        for file in files where file.isOlderThanThreeDays {
            if trash.trash(at: file.url) {
                trashedFiles.append(file.url)
            } else {
                let error = NSError(
                    domain: "DesktopCleaner",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to trash: \(file.url.lastPathComponent)"]
                )
                errors.append(error)
            }
        }

        return (trashedFiles, errors)
    }
}
