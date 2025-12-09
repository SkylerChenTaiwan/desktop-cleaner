import Foundation

/// 檔案掃描器 - 負責掃描資料夾並取得檔案資訊
class FileScanner {

    /// 掃描指定資料夾中的所有檔案
    /// - Parameter directory: 要掃描的資料夾路徑
    /// - Returns: 檔案資訊陣列（不含隱藏檔案）
    func scan(at directory: URL) -> [FileInfo] {
        let fileManager = FileManager.default

        guard let contents = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return contents.compactMap { url in
            guard let attributes = try? url.resourceValues(forKeys: [.contentModificationDateKey, .isDirectoryKey]),
                  let modificationDate = attributes.contentModificationDate,
                  let isDirectory = attributes.isDirectory else {
                return nil
            }

            return FileInfo(url: url, modificationDate: modificationDate, isDirectory: isDirectory)
        }
    }
}
